import { fetchWasmAsset } from './fetch-assets'
import { getZigStdlibDirectory } from './get-stdlib-directory'

export type AssetStatus = 'idle' | 'warming' | 'ready' | 'error'

export interface ZigAssetSnapshot {
    zig: AssetStatus
    zls: AssetStatus
    stdlib: AssetStatus
    error?: string
}

type AssetKey = 'zig' | 'zls' | 'stdlib'

type SnapshotListener = (snapshot: ZigAssetSnapshot) => void

let snapshot: ZigAssetSnapshot = {
    zig: 'idle',
    zls: 'idle',
    stdlib: 'idle',
}

let warmPromise: Promise<void> | null = null
const listeners = new Set<SnapshotListener>()

export function getCachedAssetSnapshot(): ZigAssetSnapshot {
    const { zig, zls, stdlib, error } = snapshot
    return typeof error === 'string' ? { zig, zls, stdlib, error } : { zig, zls, stdlib }
}

export async function warmZigAssets(onUpdate?: SnapshotListener): Promise<void> {
    const ready = areAllAssetsReady()

    if (onUpdate) {
        if (!ready) {
            listeners.add(onUpdate)
        }
        onUpdate(getCachedAssetSnapshot())
    }

    if (ready) {
        if (onUpdate) {
            listeners.delete(onUpdate)
        }
        return
    }

    if (!warmPromise) {
        const runner = runWarmSequence()
        warmPromise = runner.finally(() => {
            warmPromise = null
        })
    }

    try {
        await warmPromise
    } finally {
        if (onUpdate) {
            listeners.delete(onUpdate)
        }
    }
}

function areAllAssetsReady(): boolean {
    return snapshot.zig === 'ready' && snapshot.zls === 'ready' && snapshot.stdlib === 'ready'
}

async function runWarmSequence(): Promise<void> {
    clearSnapshotError()

    await warmAsset('zig', () => fetchWasmAsset('zig'))
    await warmAsset('zls', () => fetchWasmAsset('zls'))
    await warmAsset('stdlib', () => getZigStdlibDirectory())
}

async function warmAsset(key: AssetKey, action: () => Promise<unknown>) {
    if (snapshot[key] === 'ready') {
        return
    }

    setAssetStatus(key, 'warming')

    try {
        await action()
        setAssetStatus(key, 'ready')
        if (!hasErroredAsset()) {
            clearSnapshotError()
        }
    } catch (error) {
        const message = formatAssetError(key, error)
        setAssetStatus(key, 'error')
        setSnapshotError(message)
        throw new Error(message, { cause: error instanceof Error ? error : undefined })
    }
}

function setAssetStatus(key: AssetKey, status: AssetStatus) {
    if (snapshot[key] === status) {
        return
    }
    snapshot = { ...snapshot, [key]: status }
    emitSnapshot()
}

function setSnapshotError(message?: string) {
    if (!message) {
        clearSnapshotError()
        return
    }
    if (snapshot.error === message) {
        return
    }
    snapshot = { ...snapshot, error: message }
    emitSnapshot()
}

function clearSnapshotError() {
    if (typeof snapshot.error === 'string') {
        const { zig, zls, stdlib } = snapshot
        snapshot = { zig, zls, stdlib }
        emitSnapshot()
    }
}

function hasErroredAsset() {
    return snapshot.zig === 'error' || snapshot.zls === 'error' || snapshot.stdlib === 'error'
}

function emitSnapshot() {
    if (listeners.size === 0) {
        return
    }
    const payload = getCachedAssetSnapshot()
    for (const listener of [...listeners]) {
        try {
            listener(payload)
        } catch (error) {
            console.error('Failed to notify zig asset listener', error)
        }
    }
}

function formatAssetError(key: AssetKey, error: unknown): string {
    const label =
        key === 'zig'
            ? 'Zig compiler'
            : key === 'zls'
                ? 'Zig language server'
                : 'Zig standard library'
    const detail = error instanceof Error ? error.message : String(error)
    return `${label} assets failed to warm: ${detail}`
}
