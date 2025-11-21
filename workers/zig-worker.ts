/// <reference lib="webworker" />

import {
    WASI,
    PreopenDirectory,
    Directory,
    File,
    OpenFile,
    ConsoleStdout,
} from '@bjorn3/browser_wasi_shim'

import { fetchWasmAsset } from '@/lib/zig/fetch-assets'
import { getZigStdlibDirectory } from '@/lib/zig/get-stdlib-directory'
import type { PlaygroundFilePayload, ZigCompileRequest, ZigWorkerResponse } from '@/lib/zig/worker-types'

const ctx: DedicatedWorkerGlobalScope = self as DedicatedWorkerGlobalScope

const WORKSPACE_MOUNT = '.'
const STDLIB_MOUNT = '/lib'
const CACHE_MOUNT = '/cache'
const EMIT_WASM_PATH = 'main.wasm'
const DEFAULT_ENTRY_FILENAME = 'main.zig'
const LEGACY_APP_PREFIX = '/app'
const textEncoder = new TextEncoder()

let zigModulePromise: Promise<WebAssembly.Module> | null = null
let isCompiling = false
let compilationQueue: ZigCompileRequest[] = []
let compilationCount = 0
const MAX_COMPILATIONS_BEFORE_REFRESH = 50 // Refresh WASM module more frequently to prevent state buildup

ctx.addEventListener('message', (event: MessageEvent) => {
    const payload = event.data
    if (!isCompileRequest(payload)) {
        postCompileError('Invalid message for zig-worker (expected compile request)')
        return
    }

    // Add to queue and process
    compilationQueue.push(payload)
    void processQueue()
})

ctx.addEventListener('messageerror', () => {
    postCompileError('zig-worker failed to deserialize the incoming message payload')
})

// Global error handler to catch stack overflows that escape try-catch
ctx.addEventListener('error', (event: ErrorEvent) => {
    const error = event.error
    const isStackOverflow = error instanceof Error && (
        error.message.includes('recursion') ||
        error.message.includes('call stack') ||
        error.name === 'RangeError' ||
        error.name === 'InternalError'
    )
    
    if (isStackOverflow) {
        console.error('Stack overflow caught at global level:', error)
        event.preventDefault() // Prevent default error logging
        
        const message = '⚠️ WASM Compiler Stack Overflow\n\n' +
            'The Zig compiler running in your browser hit a stack limit during semantic analysis.\n\n' +
            '**This is a known limitation of the browser playground.**\n\n' +
            'Possible causes:\n' +
            '• Standard library code triggering deep analysis (not your fault!)\n' +
            '• Complex comptime recursion or generic types\n' +
            '• Circular type dependencies\n\n' +
            'Technical: The WASM Zig compiler binary has a fixed stack size that cannot be increased at runtime.'
        
        postCompileError(message)
        
        // Force module refresh
        zigModulePromise = null
        compilationCount = 0
        isCompiling = false
        
        // Notify main thread
        ctx.postMessage({ type: 'fatal-error', message: 'stack-overflow' })
    }
})

ctx.addEventListener('unhandledrejection', (event: PromiseRejectionEvent) => {
    const error = event.reason
    const isStackOverflow = error instanceof Error && (
        error.message.includes('recursion') ||
        error.message.includes('call stack') ||
        error.name === 'RangeError' ||
        error.name === 'InternalError'
    )
    
    if (isStackOverflow) {
        console.error('Unhandled promise rejection with stack overflow:', error)
        event.preventDefault()
        
        postCompileError('Compiler encountered a recursion error during async operation')
        
        zigModulePromise = null
        compilationCount = 0
        isCompiling = false
        
        ctx.postMessage({ type: 'fatal-error', message: 'stack-overflow' })
    }
})

async function processQueue() {
    // If already compiling, the queue will be processed when current compilation finishes
    if (isCompiling) {
        return
    }

    // Get the most recent request and discard older ones (user only cares about latest)
    const request = compilationQueue.pop()
    if (!request) {
        return
    }

    // Clear any pending requests - only compile the latest
    compilationQueue = []

    await handleCompile(request)

    // Process next item if queue has grown while we were compiling
    if (compilationQueue.length > 0) {
        void processQueue()
    }
}

async function handleCompile(request: ZigCompileRequest) {
    isCompiling = true
    try {
        // Periodically refresh the WASM module to prevent state accumulation
        compilationCount++
        if (compilationCount >= MAX_COMPILATIONS_BEFORE_REFRESH) {
            console.log('Refreshing Zig WASM module after', compilationCount, 'compilations')
            zigModulePromise = null
            compilationCount = 0
        }
        
        const response = await runCompilation(request)
        if (response.type === 'compile-success') {
            ctx.postMessage(response, [response.wasm])
        } else {
            ctx.postMessage(response)
        }
    } catch (error) {
        let message = error instanceof Error ? error.message : 'Unknown compile failure'
        
        // On stack overflow, provide actionable error message
        const isStackOverflow = error instanceof Error && (
            error.message.includes('recursion') ||
            error.message.includes('call stack') ||
            error.name === 'RangeError' ||
            error.name === 'InternalError'
        )
        
        if (isStackOverflow) {
            console.error('Stack overflow in Zig compiler:', error)
            message = 'Compiler stack overflow. This usually means:\n' +
                '1. Your code has deep comptime recursion or circular type dependencies\n' +
                '2. Try simplifying generic types or reducing comptime complexity\n' +
                '3. If this persists, try refreshing the page to reset the compiler'
            
            // Force module refresh for next compilation
            zigModulePromise = null
            compilationCount = 0
            
            // Notify main thread to restart worker
            ctx.postMessage({ type: 'fatal-error', message: 'stack-overflow' })
        }
        
        postCompileError(message)
    } finally {
        isCompiling = false
    }
}

async function runCompilation(request: ZigCompileRequest): Promise<ZigWorkerResponse> {
    const startedAt = performance.now()
    const stdout = new BufferingConsole()
    const stderr = new BufferingConsole()

    try {
        const entryPath = normalizeEntryPath(request.entryPath)
        const appDirectory = hydrateAppDirectory(request.files)
        const cacheDirectory = new Directory(new Map())
        const stdlibDirectory = await getZigStdlibDirectory()

        const args = buildZigArgs(entryPath, request.optimize)
        console.log('Zig args:', args)
        const env: string[] = []
        const fds = buildFds(stdout, stderr, appDirectory, stdlibDirectory, cacheDirectory)

        const wasi = new WASI(args, env, fds, { debug: false })
        const zigInstance = await instantiateZig(wasi)
        const exitCode = wasi.start(zigInstance)

        const durationMs = elapsedSince(startedAt)
        const stdoutText = stdout.read()
        const stderrText = stderr.read()

        if (exitCode !== 0) {
            return createCompileErrorResponse(`Zig exited with code ${exitCode}`, stdoutText, stderrText, durationMs)
        }

        const wasmBuffer = extractWasmArtifact(appDirectory)
        if (!wasmBuffer) {
            return createCompileErrorResponse('Compiled artifact missing at main.wasm', stdoutText, stderrText, durationMs)
        }

        return {
            type: 'compile-success',
            wasm: wasmBuffer,
            stdout: stdoutText,
            stderr: stderrText,
            durationMs,
        }
    } catch (error) {
        const durationMs = elapsedSince(startedAt)
        const stdoutText = stdout.read()
        const stderrText = stderr.read()
        const message = error instanceof Error ? `${error.message}\n${error.stack}` : String(error)
        return createCompileErrorResponse(message, stdoutText, stderrText, durationMs)
    }
}

function createCompileErrorResponse(message: string, stdout: string, stderr: string, durationMs: number) {
    return {
        type: 'compile-error',
        stdout,
        stderr,
        durationMs,
        message,
    } as const
}

type ZigWasmInstance = WebAssembly.Instance & {
    exports: WebAssembly.Exports & { memory: WebAssembly.Memory; _start: () => unknown }
}

async function instantiateZig(wasi: WASI): Promise<ZigWasmInstance> {
    const wasmModule = await loadZigModule()
    
    // Note: WASM stack size is baked into the module, we can't change it at instantiation
    // The stack overflow is happening in the Zig compiler's semantic analysis which
    // is deeply recursive by design. This is a known limitation of running Zig in browser WASM.
    
    return (await WebAssembly.instantiate(wasmModule, {
        wasi_snapshot_preview1: wasi.wasiImport,
    })) as ZigWasmInstance
}

async function loadZigModule(): Promise<WebAssembly.Module> {
    if (!zigModulePromise) {
        zigModulePromise = fetchWasmAsset('zig')
            .then(({ bytes }) => WebAssembly.compile(bytes))
            .catch((error) => {
                zigModulePromise = null
                throw error
            })
    }
    return zigModulePromise
}

function buildZigArgs(entryPath: string, optimize?: ZigCompileRequest['optimize']): string[] {
    return [
        'zig.wasm',
        'build-exe',
        entryPath,
        '-fno-llvm',
        '-fno-lld',
        '-fno-ubsan-rt',
        '-fno-entry',
    ]
}

function buildFds(
    stdout: BufferingConsole,
    stderr: BufferingConsole,
    appDirectory: Directory,
    stdlibDirectory: Directory,
    cacheDirectory: Directory,
) {
    const stdinFile = new File(new ArrayBuffer(0), { readonly: true })
    const stdin = new OpenFile(stdinFile)
    return [
        stdin,
        stdout,
        stderr,
        new PreopenDirectory(WORKSPACE_MOUNT, appDirectory.contents),
        new PreopenDirectory(STDLIB_MOUNT, stdlibDirectory.contents),
        new PreopenDirectory(CACHE_MOUNT, cacheDirectory.contents),
    ]
}

function hydrateAppDirectory(files: PlaygroundFilePayload[]): Directory {
    const directory = new Directory(new Map())

    for (const file of files) {
        const relativePath = normalizeEntryPath(file.path || '')
        if (!relativePath) {
            continue
        }
        writeFile(directory, relativePath, file.contents ?? '', Boolean(file.readOnly))
    }

    return directory
}

function writeFile(root: Directory, relativePath: string, contents: string, readOnly: boolean) {
    const segments = toSegments(relativePath)
    if (segments.length === 0) {
        return
    }
    const filename = segments.pop() as string
    const parent = ensureDirectory(root, segments)
    parent.contents.set(filename, new File(textEncoder.encode(contents), { readonly: readOnly }))
}

function ensureDirectory(root: Directory, path: string | string[]): Directory {
    const segments = Array.isArray(path) ? path : toSegments(path)
    let current = root
    for (const segment of segments) {
        const existing = current.contents.get(segment)
        if (existing instanceof Directory) {
            current = existing
            continue
        }
        if (existing instanceof File) {
            current.contents.delete(segment)
        }
        const next = new Directory(new Map())
        current.contents.set(segment, next)
        current = next
    }
    return current
}

function extractWasmArtifact(appDirectory: Directory): ArrayBuffer | null {
    const file = getFileAtPath(appDirectory, EMIT_WASM_PATH)
    if (!file) {
        return null
    }
    const cloned = file.data.slice()
    return cloned.buffer
}

function getFileAtPath(root: Directory, relativePath: string): File | null {
    const segments = toSegments(relativePath)
    let current: Directory = root
    for (let index = 0; index < segments.length; index += 1) {
        const segment = segments[index]
        const entry = current.contents.get(segment)
        if (!entry) {
            return null
        }
        const isLast = index === segments.length - 1
        if (isLast) {
            return entry instanceof File ? entry : null
        }
        if (!(entry instanceof Directory)) {
            return null
        }
        current = entry
    }
    return null
}

function normalizeEntryPath(path: string | undefined): string {
    const trimmed = (path ?? '').trim().replace(/\\/g, '/')
    const withoutLegacyPrefix = trimmed.startsWith(`${LEGACY_APP_PREFIX}/`)
        ? trimmed.slice(LEGACY_APP_PREFIX.length + 1)
        : trimmed.startsWith(LEGACY_APP_PREFIX)
            ? trimmed.slice(LEGACY_APP_PREFIX.length)
            : trimmed
    const cleaned = withoutLegacyPrefix.replace(/^\/+/, '')
    const segments = cleaned
        .split('/')
        .map((segment) => segment.trim())
        .filter((segment) => segment.length > 0 && segment !== '.' && segment !== '..')
    const normalized = segments.join('/')
    return normalized.length > 0 ? normalized : DEFAULT_ENTRY_FILENAME
}

function toSegments(path: string): string[] {
    return path
        .split('/')
        .map((segment) => segment.trim())
        .filter((segment) => segment.length > 0 && segment !== '.')
}

function elapsedSince(startedAt: number): number {
    return Math.max(0, Math.round(performance.now() - startedAt))
}

class BufferingConsole extends ConsoleStdout {
    private readonly state: { decoder: TextDecoder; buffer: string; flushed: boolean }

    constructor() {
        const state = { decoder: new TextDecoder(), buffer: '', flushed: false }
        super((data) => {
            state.buffer += state.decoder.decode(data, { stream: true })
        })
        this.state = state
    }

    read(): string {
        if (!this.state.flushed) {
            this.state.buffer += this.state.decoder.decode()
            this.state.flushed = true
        }
        return this.state.buffer
    }
}

function isCompileRequest(input: unknown): input is ZigCompileRequest {
    if (!input || typeof input !== 'object') {
        return false
    }
    const candidate = input as Partial<ZigCompileRequest>
    return candidate.type === 'compile' && Array.isArray(candidate.files) && typeof candidate.entryPath === 'string'
}

function postCompileError(message: string) {
    const response = createCompileErrorResponse(message, '', '', 0)
    ctx.postMessage(response)
}

export type { }
