import { ZIG_WASM_URL, ZLS_WASM_URL, ZIG_STDLIB_ARCHIVE_URL, assertHttpsAsset, resolveAssetUrl } from './asset-paths'

export type WasmAssetKind = 'zig' | 'zls'

export interface WasmAsset {
    kind: WasmAssetKind
    url: string
    bytes: ArrayBuffer
}

const wasmAssetUrls: Record<WasmAssetKind, string> = {
    zig: ZIG_WASM_URL,
    zls: ZLS_WASM_URL,
}

const wasmAssetPromises: Partial<Record<WasmAssetKind, Promise<WasmAsset>>> = {}
let stdlibArchivePromise: Promise<Uint8Array> | null = null

export async function fetchWasmAsset(kind: WasmAssetKind): Promise<WasmAsset> {
    if (!wasmAssetPromises[kind]) {
        wasmAssetPromises[kind] = loadWasmAsset(kind).catch((error) => {
            delete wasmAssetPromises[kind]
            throw error
        })
    }
    return wasmAssetPromises[kind]!
}

async function loadWasmAsset(kind: WasmAssetKind): Promise<WasmAsset> {
    const url = wasmAssetUrls[kind]
    assertHttpsAsset(url)
    const requestUrl = resolveAssetUrl(url)
    const response = await fetch(requestUrl, { cache: 'force-cache' })
    if (!response.ok) {
        throw new Error(`Failed to fetch ${kind.toUpperCase()} WASM (${response.status} ${response.statusText}) from ${url}`)
    }
    const bytes = await response.arrayBuffer()
    return { kind, url, bytes }
}

export async function fetchZigStdlibArchive(): Promise<Uint8Array> {
    if (!stdlibArchivePromise) {
        stdlibArchivePromise = loadStdlibArchive().catch((error) => {
            stdlibArchivePromise = null
            throw error
        })
    }
    return stdlibArchivePromise
}

async function loadStdlibArchive(): Promise<Uint8Array> {
    assertHttpsAsset(ZIG_STDLIB_ARCHIVE_URL)
    const requestUrl = resolveAssetUrl(ZIG_STDLIB_ARCHIVE_URL)
    const response = await fetch(requestUrl, { cache: 'force-cache' })
    if (!response.ok) {
        throw new Error(
            `Failed to fetch Zig standard library archive (${response.status} ${response.statusText}) from ${ZIG_STDLIB_ARCHIVE_URL}`,
        )
    }
    const buffer = await response.arrayBuffer()
    return new Uint8Array(buffer)
}
