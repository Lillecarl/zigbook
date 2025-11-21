/// <reference lib="webworker" />

import { WASI, Directory, File, OpenFile, PreopenDirectory, ConsoleStdout } from '@bjorn3/browser_wasi_shim'

import type { PlaygroundFilePayload, RunnerRequest, RunnerResponse } from '@/lib/zig/worker-types'

const ctx: DedicatedWorkerGlobalScope = self as DedicatedWorkerGlobalScope

// Global error handler for stack overflow during execution
ctx.addEventListener('error', (event: ErrorEvent) => {
    const error = event.error
    const isStackOverflow = error instanceof Error && (
        error.message.includes('recursion') ||
        error.message.includes('call stack') ||
        error.name === 'RangeError' ||
        error.name === 'InternalError'
    )
    
    if (isStackOverflow) {
        console.error('Stack overflow during program execution:', error)
        event.preventDefault()
        
        postRunError('Program caused stack overflow - likely infinite recursion in your code')
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
        
        postRunError('Program caused stack overflow during async operation')
    }
})

async function run(wasmBuffer: ArrayBuffer) {
    function stderrOutput(): ConsoleStdout {
        const dec = new TextDecoder("utf-8", { fatal: false });
        return new ConsoleStdout((buffer) => {
            postMessage({ stderr: dec.decode(buffer, { stream: true }) });
        });
    }

    let args = ["main.wasm"];
    let env: string[] = [];
    let fds = [
        new OpenFile(new File([])), // stdin
        stderrOutput(), // stdout
        stderrOutput(), // stderr
        new PreopenDirectory(".", new Map([])),
    ];

    let wasi = new WASI(args, env, fds);

    let { instance } = await WebAssembly.instantiate(wasmBuffer, {
        "wasi_snapshot_preview1": wasi.wasiImport,
    });

    try {
        // @ts-ignore
        const exitCode = wasi.start(instance);

        postMessage({
            stderr: `\n\n---\nexit with exit code ${exitCode}\n---\n`,
        });
    } catch (err) {
        postMessage({ stderr: `${err}` });
    }

    postMessage({
        done: true,
    });

    onmessage = (event) => {
        if (event.data.run) {
            run(event.data.run);
        }
    };
}

let isRunning = false
let runQueue: RunnerRequest[] = []
const WORKSPACE_MOUNT = '.'
const DEFAULT_ENTRY_FILENAME = 'main.zig'
const LEGACY_APP_PREFIX = '/app'
const textEncoder = new TextEncoder()

ctx.addEventListener('message', (event: MessageEvent) => {
    const payload = event.data
    if (!isRunnerRequest(payload)) {
        postRunError('Invalid runner request payload')
        return
    }

    // Add to queue and process
    runQueue.push(payload)
    void processQueue()
})

ctx.addEventListener('messageerror', () => postRunError('runner-worker failed to parse incoming message'))

async function processQueue() {
    // If already running, the queue will be processed when current execution finishes
    if (isRunning) {
        return
    }

    // Get the most recent request and discard older ones (user only cares about latest)
    const request = runQueue.pop()
    if (!request) {
        return
    }

    // Clear any pending requests - only run the latest
    runQueue = []

    await handleRun(request)

    // Process next item if queue has grown while we were running
    if (runQueue.length > 0) {
        void processQueue()
    }
}

async function handleRun(request: RunnerRequest) {
    isRunning = true
    try {
        const response = await executeProgram(request)
        ctx.postMessage(response)
    } catch (error) {
        const message = error instanceof Error ? error.message : String(error)
        postRunError(message)
    } finally {
        isRunning = false
    }
}

async function executeProgram(request: RunnerRequest): Promise<RunnerResponse> {
    const startedAt = performance.now()
    const stdout = new BufferingConsole()
    const stderr = new BufferingConsole()

    try {
        const args = buildArgs(request.args)
        const appDirectory = hydrateAppDirectory(request.files ?? [])
        const fds = buildFds(stdout, stderr, appDirectory)
        const env: string[] = []
        const wasi = new WASI(args, env, fds, { debug: false })

        const instance = await instantiateProgram(request.wasm, wasi)
        const exitCode = wasi.start(instance)

        const durationMs = elapsedSince(startedAt)
        return {
            type: 'run-success',
            stdout: stdout.read(),
            stderr: stderr.read(),
            exitCode,
            durationMs,
        }
    } catch (error) {
        const durationMs = elapsedSince(startedAt)
        const message = error instanceof Error ? `${error.message}\n${error.stack}` : String(error)
        return {
            type: 'run-error',
            message,
            stderr: stderr.read(),
            durationMs,
        }
    }
}

type RunnerInstance = WebAssembly.Instance & {
    exports: WebAssembly.Exports & { memory: WebAssembly.Memory; _start: () => unknown }
}

async function instantiateProgram(wasm: ArrayBuffer, wasi: WASI): Promise<RunnerInstance> {
    const wasmModule = await WebAssembly.compile(wasm)
    return WebAssembly.instantiate(wasmModule, {
        wasi_snapshot_preview1: wasi.wasiImport,
    }) as Promise<RunnerInstance>
}

function buildArgs(args: string[] | undefined): string[] {
    const normalized = Array.isArray(args) ? args.filter((arg) => typeof arg === 'string') : []
    return ['main.wasm', ...normalized]
}

function buildFds(
    stdout: BufferingConsole,
    stderr: BufferingConsole,
    appDirectory: Directory,
) {
    const stdinFile = new File(new ArrayBuffer(0), { readonly: true })
    const stdin = new OpenFile(stdinFile)
    return [
        stdin,
        stdout,
        stderr,
        new PreopenDirectory(WORKSPACE_MOUNT, appDirectory.contents),
    ]
}

function hydrateAppDirectory(files: PlaygroundFilePayload[]): Directory {
    const root = new Directory(new Map())
    for (const file of files) {
        const relativePath = normalizeEntryPath(file.path || '')
        if (!relativePath) {
            continue
        }
        writeFile(root, relativePath, file.contents ?? '', Boolean(file.readOnly))
    }
    return root
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

function elapsedSince(startedAt: number): number {
    return Math.max(0, Math.round(performance.now() - startedAt))
}

function isRunnerRequest(input: unknown): input is RunnerRequest {
    if (!input || typeof input !== 'object') {
        return false
    }
    const candidate = input as Partial<RunnerRequest>
    return candidate.type === 'run' && candidate.wasm instanceof ArrayBuffer
}

function postRunError(message: string) {
    const response: RunnerResponse = {
        type: 'run-error',
        message,
        stderr: '',
    }
    ctx.postMessage(response)
}

