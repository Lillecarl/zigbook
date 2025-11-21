export type PlaygroundFilePayload = { path: string; contents: string; readOnly?: boolean }

export interface ZigCompileRequest {
    type: 'compile'
    entryPath: string
    files: PlaygroundFilePayload[]
    optimize?: 'Debug' | 'ReleaseFast' | 'ReleaseSafe' | 'ReleaseSmall'
}

export interface ZigCompileSuccess {
    type: 'compile-success'
    wasm: ArrayBuffer
    stdout: string
    stderr: string
    durationMs: number
}

export interface ZigCompileFailure {
    type: 'compile-error'
    stdout: string
    stderr: string
    durationMs: number
    message: string
}

export interface ZigFatalError {
    type: 'fatal-error'
    message: string
}

export type ZigWorkerResponse = ZigCompileSuccess | ZigCompileFailure | ZigFatalError

export interface RunnerRequest {
    type: 'run'
    wasm: ArrayBuffer
    args?: string[]
    files?: PlaygroundFilePayload[]
}

export interface RunnerSuccess {
    type: 'run-success'
    stdout: string
    stderr: string
    exitCode: number
    durationMs: number
}

export interface RunnerFailure {
    type: 'run-error'
    message: string
    stderr?: string
    durationMs?: number
}

export type RunnerResponse = RunnerSuccess | RunnerFailure
