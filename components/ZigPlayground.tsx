'use client'

import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import CodeMirror from '@uiw/react-codemirror'
import { cpp } from '@codemirror/lang-cpp'
import { EditorView } from '@codemirror/view'
import { HighlightStyle, syntaxHighlighting } from '@codemirror/language'
import { tags as t } from '@lezer/highlight'
import { getCachedAssetSnapshot, warmZigAssets, type ZigAssetSnapshot, type AssetStatus } from '@/lib/zig/asset-registry'
import type {
    PlaygroundFilePayload,
    RunnerResponse,
    ZigCompileRequest,
    ZigWorkerResponse,
} from '@/lib/zig/worker-types'

export type PlaygroundFile = {
    id: string
    name: string
    path: string
    contents: string
    readOnly?: boolean
}

interface ZigPlaygroundProps {
    initialFiles?: PlaygroundFile[]
}

type LogType = 'info' | 'success' | 'warning' | 'error'

interface LogEntry {
    id: string
    timestamp: string
    message: string
    type: LogType
}

const FALLBACK_TEMPLATE = `const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
  print("Hello Zigbook!", .{});
    
}
`

const DARK_THEMES = new Set(['business', 'night', 'forest', 'dracula', 'dim', 'sunset', 'coffee', 'black'])
const EDITOR_HEIGHT_CLAMP = 'clamp(460px, 60vh, 720px)'

type RuntimeAssetKey = 'zig' | 'zls' | 'stdlib'

const RUNTIME_ASSET_ROWS: Array<{ key: RuntimeAssetKey; label: string; hint: string }> = [
    { key: 'zig', label: 'Zig compiler', hint: 'zig.wasm' },
    { key: 'zls', label: 'Zig language server', hint: 'zls.wasm' },
    { key: 'stdlib', label: 'Standard library', hint: 'zig.tar.gz' },
]

const RUNTIME_LABEL_BY_KEY: Record<RuntimeAssetKey, string> = {
    zig: 'Zig compiler',
    zls: 'Zig language server',
    stdlib: 'Zig standard library',
}

const RUNTIME_BADGE_BY_STATUS: Record<AssetStatus, string> = {
    idle: 'badge-neutral',
    warming: 'badge-warning',
    ready: 'badge-success',
    error: 'badge-error',
}

const RUNTIME_BADGE_TEXT_BY_STATUS: Record<AssetStatus, string> = {
    idle: 'Idle',
    warming: 'Warming',
    ready: 'Ready',
    error: 'Error',
}

const RUNTIME_TEXT_BY_STATUS: Record<AssetStatus, string> = {
    idle: 'Idle — awaiting warmup',
    warming: 'Warming…',
    ready: 'Ready',
    error: 'Error — tap “Retry warmup”',
}

type CompileState = 'idle' | 'compiling' | 'succeeded' | 'failed'
type RunState = 'idle' | 'running' | 'succeeded' | 'failed'

const COMPILE_BADGE_BY_STATE: Record<CompileState, string> = {
    idle: 'badge-ghost',
    compiling: 'badge-warning',
    succeeded: 'badge-success',
    failed: 'badge-error',
}

const RUN_BADGE_BY_STATE: Record<RunState, string> = {
    idle: 'badge-ghost',
    running: 'badge-warning',
    succeeded: 'badge-success',
    failed: 'badge-error',
}

const COMPILE_LABEL_BY_STATE: Record<CompileState, string> = {
    idle: 'Idle',
    compiling: 'Compiling…',
    succeeded: 'Succeeded',
    failed: 'Failed',
}

const RUN_LABEL_BY_STATE: Record<RunState, string> = {
    idle: 'Idle',
    running: 'Running…',
    succeeded: 'Finished',
    failed: 'Failed',
}

const DEFAULT_ENTRY_FILENAME = 'main.zig'
const LEGACY_APP_PREFIX = '/app'

const zigbookEditorChrome = EditorView.theme(
    {
        '&': {
            backgroundColor: 'transparent',
            color: 'hsl(var(--bc) / 0.96)',
            fontSize: '0.92rem',
            fontFamily:
                'var(--font-mono, "JetBrains Mono", "Fira Code", "SFMono-Regular", "Menlo", "Consolas", "Liberation Mono", "Courier New", monospace)',
        },
        '.cm-content': {
            caretColor: 'hsl(var(--a) / 0.95)',
        },
        '.cm-content, .cm-gutters': {
            fontFamily:
                'var(--font-mono, "JetBrains Mono", "Fira Code", "SFMono-Regular", "Menlo", "Consolas", "Liberation Mono", "Courier New", monospace)',
        },
        '.cm-gutters': {
            backgroundColor: 'transparent',
            border: 'none',
            color: 'hsl(var(--bc) / 0.45)',
        },
        '.cm-lineNumbers': {
            color: 'hsl(var(--bc) / 0.45)',
        },
        '.cm-activeLine': {
            backgroundColor: 'hsl(var(--b2) / 0.35)',
        },
        '.cm-activeLineGutter': {
            color: 'hsl(var(--a))',
            fontWeight: '600',
        },
        '.cm-selectionBackground, &.cm-focused .cm-selectionBackground': {
            backgroundColor: 'hsl(var(--a) / 0.25)',
        },
        '&.cm-focused ::selection': {
            backgroundColor: 'hsl(var(--a) / 0.25)',
        },
        '&.cm-focused .cm-cursor': {
            borderLeftColor: 'hsl(var(--a) / 0.95)',
        },
        '.cm-matchingBracket, .cm-nonmatchingBracket': {
            backgroundColor: 'hsl(var(--a) / 0.18)',
            border: '1px solid hsl(var(--a) / 0.5)',
        },
        '.cm-foldPlaceholder': {
            background: 'transparent',
            border: '1px solid hsl(var(--a) / 0.4)',
            borderRadius: '999px',
            color: 'hsl(var(--a))',
            padding: '0 0.5rem',
        },
        '.cm-tooltip': {
            border: '1px solid hsl(var(--b3) / 0.4)',
            backgroundColor: 'hsl(var(--b1) / 0.95)',
            color: 'hsl(var(--bc) / 0.95)',
        },
    },
)

const zigbookHighlightStyle = HighlightStyle.define([
    { tag: [t.comment, t.blockComment, t.lineComment], color: 'hsl(var(--bc) / 0.55)', fontStyle: 'italic' },
    { tag: [t.keyword, t.operatorKeyword, t.controlKeyword, t.moduleKeyword], color: 'hsl(var(--p))', fontWeight: 600 },
    { tag: [t.string, t.special(t.string), t.regexp, t.attributeName], color: 'hsl(var(--su))' },
    { tag: [t.number, t.bool, t.literal, t.integer, t.float], color: 'hsl(var(--wa))', fontWeight: 500 },
    { tag: [t.function(t.variableName), t.function(t.propertyName), t.labelName], color: 'hsl(var(--a))', fontWeight: 600 },
    { tag: [t.definition(t.variableName), t.variableName], color: 'hsl(var(--a) / 0.9)' },
    { tag: [t.typeName, t.className, t.tagName], color: 'hsl(var(--in))' },
    { tag: [t.punctuation, t.operator, t.separator], color: 'hsl(var(--bc) / 0.7)' },
])

const zigbookHighlighting = syntaxHighlighting(zigbookHighlightStyle, { fallback: true })

const createId = () => {
    if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
        return crypto.randomUUID()
    }
    return Math.random().toString(36).slice(2)
}

const detectIsDarkTheme = (): boolean => {
    if (typeof document === 'undefined') return false
    const theme = document.documentElement.getAttribute('data-theme') || ''
    if (theme) {
        return DARK_THEMES.has(theme)
    }
    if (typeof window !== 'undefined' && typeof window.matchMedia === 'function') {
        return window.matchMedia('(prefers-color-scheme: dark)').matches
    }
    return false
}

const formatDurationLabel = (durationMs: number | null): string => {
    if (durationMs == null) return '—'
    if (durationMs >= 1000) {
        return `${(durationMs / 1000).toFixed(2)}s`
    }
    return `${durationMs}ms`
}

const normalizeWorkerPath = (path?: string): string => {
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

const makeFilePayload = (file: PlaygroundFile): PlaygroundFilePayload => ({
    path: normalizeWorkerPath(file.path || file.name),
    contents: file.contents ?? '',
    readOnly: file.readOnly,
})

const downloadBlob = (buffer: ArrayBuffer, filename: string) => {
    if (typeof window === 'undefined') return
    const blob = new Blob([buffer], { type: 'application/wasm' })
    const url = URL.createObjectURL(blob)
    const anchor = document.createElement('a')
    anchor.href = url
    anchor.download = filename
    document.body.appendChild(anchor)
    anchor.click()
    anchor.remove()
    URL.revokeObjectURL(url)
}

const enrichFiles = (files: PlaygroundFile[]): PlaygroundFile[] =>
    files.map((file) => ({
        ...file,
        id: file.id || createId(),
        name: file.name || file.path || 'untitled.zig',
        path: file.path || file.name || 'untitled.zig',
        contents: file.contents ?? '',
    }))

const logBadgeClass = (type: LogType): string => {
    switch (type) {
        case 'success':
            return 'badge-success'
        case 'warning':
            return 'badge-warning'
        case 'error':
            return 'badge-error'
        default:
            return 'badge-info'
    }
}

export default function ZigPlayground({ initialFiles = [] }: ZigPlaygroundProps) {
    const normalizedInitialFiles = useMemo(() => enrichFiles(initialFiles).slice(0, 1), [initialFiles])
    const initialEntry = normalizedInitialFiles[0] ?? null

    const [defaultTemplate, setDefaultTemplate] = useState<string>(initialEntry?.contents ?? FALLBACK_TEMPLATE)
    const templateRef = useRef(defaultTemplate)
    const initialSourceRef = useRef(defaultTemplate)
    useEffect(() => {
        templateRef.current = defaultTemplate
    }, [defaultTemplate])

    const [source, setSource] = useState<string>(initialEntry?.contents ?? templateRef.current)
    const userEditedRef = useRef(false)

    useEffect(() => {
        fetch('/templates/main.zig')
            .then((res) => {
                if (res.ok) return res.text()
                throw new Error('Failed to load template')
            })
            .then((text) => {
                setDefaultTemplate(text)
                if (!initialEntry) {
                    initialSourceRef.current = text
                    if (!userEditedRef.current) {
                        setSource(text)
                    }
                }
            })
            .catch((err) => console.error('Failed to load default template:', err))
    }, [initialEntry])

    useEffect(() => {
        if (!initialEntry) return
        const nextSeed = initialEntry.contents ?? templateRef.current
        initialSourceRef.current = nextSeed
        setSource(nextSeed)
        userEditedRef.current = false
    }, [initialEntry])

    const [logs, setLogs] = useState<LogEntry[]>([])
    const [isDarkTheme, setIsDarkTheme] = useState(false)
    const [isConsoleOpen, setIsConsoleOpen] = useState(false)
    const [assetSnapshot, setAssetSnapshot] = useState<ZigAssetSnapshot>(() => getCachedAssetSnapshot())
    const [assetError, setAssetError] = useState<string | null>(() => assetSnapshot.error ?? null)
    const [isWarmingAssets, setIsWarmingAssets] = useState(false)
    const [compileState, setCompileState] = useState<CompileState>('idle')
    const [runState, setRunState] = useState<RunState>('idle')
    const [compileStdout, setCompileStdout] = useState('')
    const [compileStderr, setCompileStderr] = useState('')
    const [runStdout, setRunStdout] = useState('')
    const [runStderr, setRunStderr] = useState('')
    const [runExitCode, setRunExitCode] = useState<number | null>(null)
    const [compileDurationMs, setCompileDurationMs] = useState<number | null>(null)
    const [runDurationMs, setRunDurationMs] = useState<number | null>(null)
    const [lastWasm, setLastWasm] = useState<ArrayBuffer | null>(null)
    const [workerGeneration, setWorkerGeneration] = useState(0)
    const assetSnapshotRef = useRef<ZigAssetSnapshot>(assetSnapshot)
    const isMountedRef = useRef(true)
    const zigWorkerRef = useRef<Worker | null>(null)
    const runnerWorkerRef = useRef<Worker | null>(null)
    const lastCompileFilesRef = useRef<PlaygroundFilePayload[]>([])
    const [prefersReducedMotion, setPrefersReducedMotion] = useState(false)

    const entryName = initialEntry?.name ?? 'main.zig'
    const entryPath = useMemo(() => normalizeWorkerPath(initialEntry?.path || initialEntry?.name || DEFAULT_ENTRY_FILENAME), [initialEntry])
    const entryDisplayPath = initialEntry?.path ?? entryName
    const hasRunnableSource = source.trim().length > 0
    const runtimeAssetsReady = assetSnapshot.zig === 'ready' && assetSnapshot.zls === 'ready' && assetSnapshot.stdlib === 'ready'
    const isExecuting = compileState === 'compiling' || runState === 'running'

    useEffect(() => {
        return () => {
            isMountedRef.current = false
        }
    }, [])
    useEffect(() => {
        if (typeof document === 'undefined') return
        const updateTheme = () => setIsDarkTheme(detectIsDarkTheme())
        updateTheme()

        const observer = new MutationObserver(() => updateTheme())
        observer.observe(document.documentElement, { attributes: true, attributeFilter: ['data-theme'] })

        const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
        if (typeof mediaQuery.addEventListener === 'function') {
            mediaQuery.addEventListener('change', updateTheme)
        } else if (typeof mediaQuery.addListener === 'function') {
            mediaQuery.addListener(updateTheme)
        }

        return () => {
            observer.disconnect()
            if (typeof mediaQuery.removeEventListener === 'function') {
                mediaQuery.removeEventListener('change', updateTheme)
            } else if (typeof mediaQuery.removeListener === 'function') {
                mediaQuery.removeListener(updateTheme)
            }
        }
    }, [])

    useEffect(() => {
        if (typeof window === 'undefined' || typeof window.matchMedia !== 'function') {
            return
        }
        const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)')
        const update = () => setPrefersReducedMotion(mediaQuery.matches)
        update()
        if (typeof mediaQuery.addEventListener === 'function') {
            mediaQuery.addEventListener('change', update)
        } else if (typeof mediaQuery.addListener === 'function') {
            mediaQuery.addListener(update)
        }
        return () => {
            if (typeof mediaQuery.removeEventListener === 'function') {
                mediaQuery.removeEventListener('change', update)
            } else if (typeof mediaQuery.removeListener === 'function') {
                mediaQuery.removeListener(update)
            }
        }
    }, [])

    const logEvent = useCallback((message: string, type: LogType = 'info') => {
        setLogs((prev) => {
            const next = [...prev, { id: createId(), timestamp: new Date().toISOString(), message, type }]
            return next.slice(-200)
        })
    }, [])

    const resetExecutionState = useCallback(() => {
        setCompileState('idle')
        setCompileStdout('')
        setCompileStderr('')
        setCompileDurationMs(null)
        setRunState('idle')
        setRunStdout('')
        setRunStderr('')
        setRunExitCode(null)
        setRunDurationMs(null)
        setLastWasm(null)
    }, [])

    const restartWorkers = useCallback(() => {
        setWorkerGeneration((previous) => previous + 1)
    }, [])

    const updateRuntimeSnapshot = useCallback(
        (nextSnapshot: ZigAssetSnapshot) => {
            if (!isMountedRef.current) return

            const previousSnapshot = assetSnapshotRef.current
            for (const { key } of RUNTIME_ASSET_ROWS) {
                const prevStatus = previousSnapshot[key]
                const nextStatus = nextSnapshot[key]
                if (prevStatus === nextStatus) continue
                if (nextStatus === 'ready') {
                    logEvent(`${RUNTIME_LABEL_BY_KEY[key]} assets ready`, 'success')
                } else if (nextStatus === 'error') {
                    const detail = nextSnapshot.error ?? 'See runtime asset panel for details.'
                    logEvent(`${RUNTIME_LABEL_BY_KEY[key]} assets failed: ${detail}`, 'error')
                }
            }

            assetSnapshotRef.current = nextSnapshot
            setAssetSnapshot(nextSnapshot)
            setAssetError(nextSnapshot.error ?? null)
        },
        [logEvent],
    )

    const runWarmup = useCallback(async () => {
        if (!isMountedRef.current) return
        setIsWarmingAssets(true)
        setAssetError(null)
        try {
            await warmZigAssets(updateRuntimeSnapshot)
        } catch (error) {
            if (!isMountedRef.current) return
            const detail = error instanceof Error ? error.message : String(error)
            setAssetError(detail)
            logEvent(detail, 'error')
        } finally {
            if (isMountedRef.current) {
                setIsWarmingAssets(false)
            }
        }
    }, [logEvent, updateRuntimeSnapshot])

    useEffect(() => {
        void runWarmup()
    }, [runWarmup])

    useEffect(() => {
        if (typeof window === 'undefined') return

        let zig: Worker | null = null
        let runner: Worker | null = null

        try {
            zig = new Worker(new URL('../workers/zig-worker.ts', import.meta.url), { type: 'module' })
            runner = new Worker(new URL('../workers/runner-worker.ts', import.meta.url), { type: 'module' })
        } catch (error) {
            const detail = error instanceof Error ? error.message : String(error)
            logEvent(`Failed to initialize Zig workers: ${detail}`, 'error')
            return
        }

        zigWorkerRef.current = zig
        runnerWorkerRef.current = runner

        const handleCompileMessage = (event: MessageEvent<ZigWorkerResponse>) => {
            const response = event.data
            if (!response || typeof response !== 'object') {
                return
            }
            if (response.type === 'compile-success') {
                setCompileState('succeeded')
                setCompileStdout(response.stdout ?? '')
                setCompileStderr(response.stderr ?? '')
                setCompileDurationMs(response.durationMs ?? null)
                logEvent(`Compile succeeded in ${formatDurationLabel(response.durationMs ?? null)}`, 'success')

                const runnerWorker = runnerWorkerRef.current
                if (!runnerWorker) {
                    logEvent('Runner worker unavailable after compilation. Please retry.', 'error')
                    return
                }

                const downloadCopy = response.wasm.slice(0)
                setLastWasm(downloadCopy)
                setRunState('running')
                setRunStdout('')
                setRunStderr('')
                setRunExitCode(null)
                setRunDurationMs(null)
                logEvent('Executing compiled program…', 'info')
                const runnerRequest = {
                    type: 'run' as const,
                    wasm: response.wasm,
                    files: lastCompileFilesRef.current,
                }
                runnerWorker.postMessage(runnerRequest, [response.wasm])
            } else if (response.type === 'compile-error') {
                setCompileState('failed')
                setCompileStdout(response.stdout ?? '')
                setCompileStderr(response.stderr ?? '')
                setCompileDurationMs(response.durationMs ?? null)
                setRunState('idle')
                setRunStdout('')
                setRunStderr('')
                setRunExitCode(null)
                setRunDurationMs(null)
                setLastWasm(null)
                logEvent(response.message || 'Compilation failed', 'error')
            } else if (response.type === 'fatal-error') {
                // Handle fatal errors that require worker restart
                if (response.message === 'stack-overflow') {
                    logEvent('Compiler encountered a stack overflow - restarting worker...', 'error')
                    restartWorkers()
                }
            }
        }

        const handleRunnerMessage = (event: MessageEvent<RunnerResponse>) => {
            const response = event.data
            if (!response || typeof response !== 'object') {
                return
            }
            if (response.type === 'run-success') {
                setRunState('succeeded')
                setRunStdout(response.stdout ?? '')
                setRunStderr(response.stderr ?? '')
                setRunExitCode(response.exitCode)
                setRunDurationMs(response.durationMs ?? null)
                const tone: LogType = response.exitCode === 0 ? 'success' : 'warning'
                logEvent(`Program exited with code ${response.exitCode}`, tone)
            } else if (response.type === 'run-error') {
                setRunState('failed')
                setRunStdout('')
                setRunStderr(response.stderr ?? '')
                setRunExitCode(null)
                setRunDurationMs(response.durationMs ?? null)
                logEvent(response.message || 'Program run failed', 'error')
            }
        }

        const handleCompileFault = (event: ErrorEvent | MessageEvent) => {
            const detail = event instanceof ErrorEvent ? event.message : 'Malformed compiler payload'
            logEvent(`Compiler worker error: ${detail}`, 'error')
            resetExecutionState()
            restartWorkers()
        }

        const handleRunnerFault = (event: ErrorEvent | MessageEvent) => {
            const detail = event instanceof ErrorEvent ? event.message : 'Malformed runner payload'
            logEvent(`Runner worker error: ${detail}`, 'error')
            resetExecutionState()
            restartWorkers()
        }

        zig.addEventListener('message', handleCompileMessage)
        zig.addEventListener('error', handleCompileFault)
        zig.addEventListener('messageerror', handleCompileFault)
        runner.addEventListener('message', handleRunnerMessage)
        runner.addEventListener('error', handleRunnerFault)
        runner.addEventListener('messageerror', handleRunnerFault)

        return () => {
            zig.removeEventListener('message', handleCompileMessage)
            zig.removeEventListener('error', handleCompileFault)
            zig.removeEventListener('messageerror', handleCompileFault)
            runner.removeEventListener('message', handleRunnerMessage)
            runner.removeEventListener('error', handleRunnerFault)
            runner.removeEventListener('messageerror', handleRunnerFault)
            zig.terminate()
            runner.terminate()
            if (zigWorkerRef.current === zig) {
                zigWorkerRef.current = null
            }
            if (runnerWorkerRef.current === runner) {
                runnerWorkerRef.current = null
            }
        }
    }, [workerGeneration, logEvent, resetExecutionState, restartWorkers])

    useEffect(() => {
        if (typeof window === 'undefined') return
        const handler = (event: KeyboardEvent) => {
            if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 's') {
                event.preventDefault()
                logEvent(`Saved ${entryName} snapshot`, 'success')
            }
        }
        window.addEventListener('keydown', handler)
        return () => window.removeEventListener('keydown', handler)
    }, [entryName, logEvent])

    const handleRetryWarmup = useCallback(() => {
        logEvent('Retrying runtime asset warmup', 'info')
        void runWarmup()
    }, [logEvent, runWarmup])

    const handleContentChange = useCallback((value: string) => {
        setSource(value)
        userEditedRef.current = true
    }, [])

    const handleRun = () => {
        if (!hasRunnableSource) {
            logEvent('Add Zig code before running the playground.', 'warning')
            return
        }
        if (isExecuting) {
            logEvent('A compile/run request is already in flight. Please wait for it to finish.', 'warning')
            return
        }
        if (!runtimeAssetsReady) {
            const pendingAssets = RUNTIME_ASSET_ROWS.filter(({ key }) => assetSnapshot[key] !== 'ready').map(({ label }) => label)
            const pendingLabel = pendingAssets.length > 0 ? pendingAssets.join(', ') : 'assets'
            logEvent(`Runtime assets still warming: ${pendingLabel}. Please retry after warmup finishes.`, 'error')
            return
        }

        const zigWorker = zigWorkerRef.current
        if (!zigWorker || !runnerWorkerRef.current) {
            logEvent('Workers are still initializing. Retrying shortly…', 'warning')
            restartWorkers()
            return
        }

        const filePayload: PlaygroundFilePayload = {
            path: entryPath,
            contents: source,
            readOnly: false,
        }
        lastCompileFilesRef.current = [filePayload]
        const request: ZigCompileRequest = {
            type: 'compile',
            entryPath,
            files: [filePayload],
            optimize: 'ReleaseSmall',
        }

        setCompileState('compiling')
        setCompileStdout('')
        setCompileStderr('')
        setCompileDurationMs(null)
        setRunState('idle')
        setRunStdout('')
        setRunStderr('')
        setRunExitCode(null)
        setRunDurationMs(null)
        setLastWasm(null)
        logEvent(`Compiling ${entryName}`, 'info')
        zigWorker.postMessage(request)
    }

    const handleFormat = () => {
        if (!hasRunnableSource) return
        setSource((prev) =>
            prev
                .split('\n')
                .map((line) => line.replace(/\s+$/g, ''))
                .join('\n')
                .trimEnd() + '\n',
        )
        logEvent(`Formatted ${entryName}`, 'success')
    }

    const handleClearConsole = () => setLogs([])

    const handleResetWorkspace = () => {
        setSource(initialSourceRef.current)
        userEditedRef.current = false
        setLogs([])
        resetExecutionState()
        logEvent('Workspace reset to starter snippet', 'info')
    }

    const handleStop = useCallback(() => {
        logEvent('Stopping current compile/run request', 'warning')
        resetExecutionState()
        restartWorkers()
    }, [logEvent, resetExecutionState, restartWorkers])

    const handleDownloadWasm = useCallback(() => {
        if (!lastWasm) return
        const basename = entryName.replace(/\.zig$/i, '') || 'program'
        const filename = `${basename}.wasm`
        downloadBlob(lastWasm, filename)
        logEvent(`Downloaded ${filename}`, 'success')
    }, [entryName, lastWasm, logEvent])

    const handleClearOutputs = useCallback(() => {
        setCompileStdout('')
        setCompileStderr('')
        setRunStdout('')
        setRunStderr('')
    }, [])

    const editorExtensions = useMemo(
        () => [cpp(), EditorView.lineWrapping, zigbookEditorChrome, zigbookHighlighting],
        [],
    )

    const editorHeightStyle = useMemo(
        () => ({
            height: EDITOR_HEIGHT_CLAMP,
        }),
        [],
    )

    const editorTheme = isDarkTheme ? 'dark' : 'light'
    const interactiveCardClass = 'transition-all duration-200 motion-safe:hover:-translate-y-0.5 motion-safe:focus-within:-translate-y-0.5 hover:border-accent/50 focus-within:border-accent/60'
    const compileBadgePulse = !prefersReducedMotion && compileState === 'compiling' ? 'animate-pulse' : ''
    const runBadgePulse = !prefersReducedMotion && runState === 'running' ? 'animate-pulse' : ''
    const runButtonPulse = !prefersReducedMotion && isExecuting ? 'animate-pulse' : ''

    return (
        <div className="space-y-6">
            <section className="relative flex flex-col gap-5 rounded-3xl border border-base-300/60 bg-base-100/85 p-4 shadow-[0_18px_60px_rgba(0,0,0,0.35)] sm:p-6">
                <div className="flex flex-wrap items-start justify-between gap-3">
                    <div>
                        <p className="text-sm font-semibold text-base-content">Entry file</p>
                        <p className="flex items-center gap-2 text-xs text-base-content/60">
                            <span className="badge badge-ghost badge-xs uppercase tracking-[0.3em] text-[0.55rem]">MAIN</span>
                            {entryDisplayPath}
                        </p>
                    </div>
                    <div className="flex flex-wrap items-center gap-2">
                        <button
                            type="button"
                            className="btn btn-sm btn-ghost transition-all duration-200 hover:-translate-y-0.5 active:scale-95 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
                            onClick={handleResetWorkspace}
                        >
                            Reset snippet
                        </button>
                        <button
                            type="button"
                            className={`btn btn-sm transition-all duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary ${hasRunnableSource ? 'btn-ghost hover:-translate-y-0.5 active:scale-95' : 'btn-disabled'}`}
                            onClick={handleFormat}
                            disabled={!hasRunnableSource}
                        >
                            <svg className="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.5}>
                                <path strokeLinecap="round" strokeLinejoin="round" d="M6 8h4M6 12h8M6 16h6" />
                            </svg>
                            <span>Format</span>
                        </button>
                        <button
                            type="button"
                            className={`btn btn-sm gap-1 transition-all duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary ${hasRunnableSource && !isExecuting ? 'btn-primary hover:-translate-y-0.5 active:scale-95 shadow-lg shadow-primary/40' : 'btn-disabled'} ${runButtonPulse}`}
                            onClick={handleRun}
                            disabled={!hasRunnableSource || isExecuting}
                        >
                            {isExecuting ? (
                                <span className="loading loading-xs" aria-hidden="true" />
                            ) : (
                                <svg className="h-4 w-4" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                                    <path d="M8 5v14l11-7z" />
                                </svg>
                            )}
                            <span>{isExecuting ? 'Running' : 'Run'}</span>
                        </button>
                    </div>
                </div>

                <div className="rounded-2xl border border-warning/40 bg-warning/10 px-4 py-3 text-xs text-warning">
                    Sessions reset on refresh. Export the compiled WASM if you need to keep work between visits.
                </div>

                <div className="grid gap-3 md:grid-cols-2">
                            <div className="rounded-2xl border border-base-300/50 bg-gradient-to-br from-base-200/70 to-base-100/40 p-4 text-xs backdrop-blur-sm">
                                <div className="flex items-center justify-between gap-3">
                                    <span className="font-semibold text-base-content/70">Runtime assets</span>
                                    <button
                                        type="button"
                                        className="btn btn-ghost btn-xs transition-all duration-200 hover:-translate-y-0.5 active:scale-95 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
                                        onClick={handleRetryWarmup}
                                        disabled={isWarmingAssets}
                                        title="Retry warmup"
                                    >
                                        {isWarmingAssets ? 'Warming…' : '↻ Retry'}
                                    </button>
                                </div>
                                <div className="mt-3 space-y-2">
                                    {RUNTIME_ASSET_ROWS.map(({ key, label, hint }) => {
                                        const status = assetSnapshot[key]
                                        return (
                                            <div
                                                key={key}
                                                className={`flex items-center justify-between gap-3 rounded-xl border border-base-300/30 bg-base-100/50 px-3 py-2 ${interactiveCardClass}`}
                                            >
                                                <div>
                                                    <p className="text-[0.65rem] font-semibold uppercase tracking-[0.25em] text-base-content/60">
                                                        {label}
                                                    </p>
                                                    <p className="text-[0.7rem] text-base-content/50">{hint}</p>
                                                </div>
                                                <span className={`badge ${RUNTIME_BADGE_BY_STATUS[status]} badge-sm`}>
                                                    {RUNTIME_BADGE_TEXT_BY_STATUS[status]}
                                                </span>
                                            </div>
                                        )
                                    })}
                                </div>
                            </div>

                            <div className="rounded-2xl border border-base-300/50 bg-gradient-to-br from-base-200/70 to-base-100/40 p-4 text-xs backdrop-blur-sm">
                                <div className="flex items-center justify-between gap-3">
                                    <span className="font-semibold text-base-content/70">Build & run</span>
                                    <div className="flex items-center gap-1.5">
                                        {lastWasm && (
                                            <button
                                                type="button"
                                                className="btn btn-ghost btn-xs transition-all duration-200 hover:-translate-y-0.5 active:scale-95 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
                                                onClick={handleDownloadWasm}
                                                title="Download WASM"
                                            >
                                                <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                                                </svg>
                                                <span className="hidden sm:inline">Download</span>
                                            </button>
                                        )}
                                        {isExecuting && (
                                            <button
                                                type="button"
                                                className="btn btn-xs btn-error transition-all duration-200 hover:-translate-y-0.5 active:scale-95 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-error"
                                                onClick={handleStop}
                                                title="Stop execution"
                                            >
                                                Stop
                                            </button>
                                        )}
                                    </div>
                                </div>
                                <div className="mt-3 space-y-3">
                                    <div className={`flex items-center justify-between gap-3 rounded-xl border border-base-300/30 bg-base-100/50 px-3 py-2 ${interactiveCardClass}`}>
                                        <div>
                                            <p className="text-[0.65rem] uppercase tracking-[0.25em] text-base-content/60">Compile</p>
                                            {compileDurationMs !== null && (
                                                <p className="text-[0.7rem] text-base-content/50">{formatDurationLabel(compileDurationMs)}</p>
                                            )}
                                        </div>
                                        <span className={`badge ${COMPILE_BADGE_BY_STATE[compileState]} badge-sm ${compileBadgePulse}`}>
                                            {COMPILE_LABEL_BY_STATE[compileState]}
                                        </span>
                                    </div>
                                    <div className={`flex items-center justify-between gap-3 rounded-xl border border-base-300/30 bg-base-100/50 px-3 py-2 ${interactiveCardClass}`}>
                                        <div>
                                            <p className="text-[0.65rem] uppercase tracking-[0.25em] text-base-content/60">Run</p>
                                            <div className="text-[0.7rem] text-base-content/50">
                                                {runExitCode !== null && <span className="mr-2">exit {runExitCode}</span>}
                                                {runDurationMs !== null && <span>{formatDurationLabel(runDurationMs)}</span>}
                                            </div>
                                        </div>
                                        <span className={`badge ${RUN_BADGE_BY_STATE[runState]} badge-sm ${runBadgePulse}`}>
                                            {RUN_LABEL_BY_STATE[runState]}
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </div>

                        {assetError && (
                            <div role="alert" className="alert alert-warning flex items-start gap-3 py-2 text-xs">
                                <svg className="h-4 w-4 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                                </svg>
                                <span className="flex-1">{assetError}</span>
                                <button
                                    type="button"
                                    className="btn btn-xs btn-ghost text-warning-content transition-all duration-200 hover:-translate-y-0.5 active:scale-95 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-warning"
                                    onClick={() => setAssetError(null)}
                                >
                                    Dismiss
                                </button>
                            </div>
                        )}

                        <div className="w-full" style={editorHeightStyle}>
                            <div
                                className="zigbook-editor-shell group relative flex h-full flex-col overflow-hidden rounded-2xl border border-base-300/70 bg-base-300/40 bg-gradient-to-b from-base-300/60 via-base-300/15 to-base-100/5 shadow-[0_18px_60px_rgba(0,0,0,0.45)] backdrop-blur transition-all duration-300 hover:border-accent/80 hover:shadow-[0_24px_70px_rgba(0,0,0,0.55)] focus-within:border-accent/80 focus-within:shadow-[0_24px_70px_rgba(0,0,0,0.55)] motion-safe:hover:-translate-y-1 motion-safe:focus-within:-translate-y-1"
                            >
                                <div
                                    aria-hidden="true"
                                    className="pointer-events-none absolute inset-0 z-0 opacity-0 transition-opacity duration-300 group-hover:opacity-80 group-focus-within:opacity-80"
                                    style={{
                                        background:
                                            'radial-gradient(circle at 20% 20%, hsl(var(--a) / 0.28), transparent 60%), radial-gradient(circle at 85% 0%, hsl(var(--p) / 0.22), transparent 55%)',
                                    }}
                                />
                                <div className="relative z-10 flex h-full w-full">
                                    <CodeMirror
                                        value={source}
                                        height="100%"
                                        theme={editorTheme}
                                        extensions={editorExtensions}
                                        onChange={handleContentChange}
                                        editable
                                        basicSetup={{ lineNumbers: true }}
                                        style={{ height: '100%', width: '100%' }}
                                        aria-label={`Editor for ${entryName}`}
                                    />
                                </div>
                            </div>
                        </div>

                        <details className="group rounded-2xl border border-base-300/50 bg-base-100/70 backdrop-blur-sm" open>
                            <summary className="flex cursor-pointer items-center justify-between gap-3 px-3 py-2 text-xs transition-colors hover:bg-base-200/30">
                                <div className="flex items-center gap-2">
                                    <svg
                                        className="h-3 w-3 transition-transform group-open:rotate-90"
                                        fill="none"
                                        viewBox="0 0 24 24"
                                        stroke="currentColor"
                                    >
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                                    </svg>
                                    <span className="font-semibold text-base-content">Program Output</span>
                                    {(compileStdout || compileStderr || runStdout || runStderr) && (
                                        <span className="badge badge-ghost badge-xs">updated</span>
                                    )}
                                </div>
                                <button
                                    type="button"
                                    className="btn btn-xs btn-ghost transition-all duration-200 hover:-translate-y-0.5 active:scale-95 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
                                    onClick={(e) => {
                                        e.preventDefault()
                                        handleClearOutputs()
                                    }}
                                >
                                    Clear
                                </button>
                            </summary>
                            <div className="space-y-2 p-3 pt-2">
                                <div className="grid gap-2 sm:grid-cols-2">
                                    <div className="space-y-1.5">
                                        <div className="flex items-center justify-between text-[0.65rem] font-semibold uppercase tracking-wide text-base-content/60">
                                            <span>Compile stdout</span>
                                            {compileStdout && <span className="badge badge-ghost badge-xs">live</span>}
                                        </div>
                                        <pre
                                            className="max-h-32 min-h-[4rem] overflow-auto rounded-lg border border-base-300/30 bg-base-200/40 p-2 font-mono text-[0.7rem] leading-relaxed text-base-content/90 whitespace-pre-wrap break-words"
                                            aria-live="polite"
                                        >
                                            {compileStdout || 'No compiler stdout yet.'}
                                        </pre>
                                    </div>
                                    <div className="space-y-1.5">
                                        <div className="flex items-center justify-between text-[0.65rem] font-semibold uppercase tracking-wide text-base-content/60">
                                            <span>Compile stderr</span>
                                            {compileState === 'failed' && <span className="badge badge-error badge-xs">error</span>}
                                        </div>
                                        <pre
                                            className={`max-h-32 min-h-[4rem] overflow-auto rounded-lg border border-base-300/30 bg-base-200/40 p-2 font-mono text-[0.7rem] leading-relaxed whitespace-pre-wrap break-words ${compileState === 'failed' ? 'text-error' : 'text-base-content/90'}`}
                                            aria-live="polite"
                                        >
                                            {compileStderr || 'No compiler stderr yet.'}
                                        </pre>
                                    </div>
                                    <div className="space-y-1.5">
                                        <div className="flex items-center justify-between text-[0.65rem] font-semibold uppercase tracking-wide text-base-content/60">
                                            <span>Run stdout</span>
                                            {runExitCode !== null && (
                                                <span className={`badge badge-xs ${runExitCode === 0 ? 'badge-success' : 'badge-warning'}`}>
                                                    exit {runExitCode}
                                                </span>
                                            )}
                                        </div>
                                        <pre
                                            className="max-h-32 min-h-[4rem] overflow-auto rounded-lg border border-base-300/30 bg-base-200/40 p-2 font-mono text-[0.7rem] leading-relaxed text-base-content/90 whitespace-pre-wrap break-words"
                                            aria-live="polite"
                                        >
                                            {runStdout || 'No runtime stdout yet.'}
                                        </pre>
                                    </div>
                                    <div className="space-y-1.5">
                                        <div className="flex items-center justify-between text-[0.65rem] font-semibold uppercase tracking-wide text-base-content/60">
                                            <span>Run stderr</span>
                                            {runState === 'failed' && <span className="badge badge-error badge-xs">error</span>}
                                        </div>
                                        <pre
                                            className={`max-h-32 min-h-[4rem] overflow-auto rounded-lg border border-base-300/30 bg-base-200/40 p-2 font-mono text-[0.7rem] leading-relaxed whitespace-pre-wrap break-words ${runState === 'failed' ? 'text-error' : 'text-base-content/90'}`}
                                            aria-live="polite"
                                        >
                                            {runStderr || 'No runtime stderr yet.'}
                                        </pre>
                                    </div>
                                </div>
                            </div>
                        </details>

                        <div className="rounded-2xl border border-dashed border-base-300/60 bg-base-100/70 px-4 py-3 text-[0.75rem] text-base-content/80">
                            <span className="font-semibold">Pro tip:</span> Press Ctrl/Cmd + S to log a manual save in this session.
                        </div>
                    </section>

            <details className="group rounded-2xl border border-base-300/50 bg-base-100/70 backdrop-blur-sm" open={isConsoleOpen} aria-label="Session console">
                <summary
                    className="flex cursor-pointer items-center justify-between gap-3 px-3 py-2 text-xs transition-colors hover:bg-base-200/30"
                    onClick={(e) => {
                        e.preventDefault()
                        setIsConsoleOpen((prev) => !prev)
                    }}
                >
                    <div className="flex flex-wrap items-center gap-2">
                        <svg
                            className="h-3 w-3 transition-transform group-open:rotate-90"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                        >
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                        </svg>
                        <span className="font-semibold text-base-content">Session Console</span>
                        <span className="badge badge-ghost badge-xs">{logs.length} events</span>
                        {logs.length > 0 && (
                            <span className="hidden text-base-content/50 sm:inline">
                                Latest: {logs[logs.length - 1]?.message.slice(0, 32)}
                                {logs[logs.length - 1]?.message.length > 32 ? '…' : ''}
                            </span>
                        )}
                    </div>
                    <button
                        type="button"
                        className="btn btn-xs btn-ghost transition-all duration-200 hover:-translate-y-0.5 active:scale-95 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
                        onClick={(e) => {
                            e.stopPropagation()
                            handleClearConsole()
                        }}
                    >
                        Clear
                    </button>
                </summary>
                <div className="space-y-2 p-3 pt-2">
                    <div className="max-h-56 space-y-1.5 overflow-y-auto pr-1 scrollbar-thin" role="log" aria-live="polite">
                        {logs.length === 0 ? (
                            <p className="py-4 text-center text-[0.7rem] text-base-content/60">
                                No activity yet. Editor actions will appear here.
                            </p>
                        ) : (
                            logs
                                .slice()
                                .reverse()
                                .map((log) => (
                                    <div
                                        key={log.id}
                                        className="flex items-start gap-2 rounded-lg border border-base-300/30 bg-base-200/30 px-2.5 py-1.5 transition-all duration-200 hover:bg-base-200/50 motion-safe:hover:-translate-y-0.5"
                                    >
                                        <span className={`badge ${logBadgeClass(log.type)} badge-xs mt-0.5 shrink-0`}>
                                            {log.type}
                                        </span>
                                        <div className="min-w-0 flex-1">
                                            <p className="break-words text-[0.7rem] leading-relaxed text-base-content/80">{log.message}</p>
                                            <p className="mt-0.5 text-[0.65rem] text-base-content/40">
                                                {new Date(log.timestamp).toLocaleTimeString()}
                                            </p>
                                        </div>
                                    </div>
                                ))
                        )}
                    </div>
                </div>
            </details>
        </div>
    )
}
