export const ZIG_ASSET_BASE = '/zig'
export const ZIG_WASM_URL = `${ZIG_ASSET_BASE}/zig.wasm`
export const ZLS_WASM_URL = `${ZIG_ASSET_BASE}/zls.wasm`
export const ZIG_STDLIB_ARCHIVE_URL = `${ZIG_ASSET_BASE}/zig.tar.gz`

const PROTOCOL_REGEX = /^[a-zA-Z][a-zA-Z\d+\-.]*:\/\//

export function assertHttpsAsset(url: string) {
    const normalized = url?.trim()
    if (!normalized) {
        throw new Error('Asset URL is empty')
    }

    if (normalized.startsWith('//')) {
        throw new Error(`Asset URL must not use protocol-relative schemes: ${normalized}`)
    }

    if (PROTOCOL_REGEX.test(normalized)) {
        if (!normalized.toLowerCase().startsWith('https://')) {
            throw new Error(`Asset URL must use HTTPS or be relative: ${normalized}`)
        }
        return
    }
    // Relative (/, ./, ../, or bare filenames) are allowed implicitly
}

let cachedOrigin: string | null | undefined

export function resolveAssetUrl(url: string): string {
    const normalized = url?.trim()
    if (!normalized) {
        return url
    }

    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
        return normalized
    }

    if (!normalized.startsWith('/')) {
        return normalized
    }

    const origin = getExecutionOrigin()
    if (!origin) {
        return normalized
    }
    return `${origin}${normalized}`
}

function getExecutionOrigin(): string | null {
    if (cachedOrigin !== undefined) {
        return cachedOrigin
    }

    cachedOrigin = null

    if (typeof globalThis !== 'undefined') {
        const globalOrigin = (globalThis as { origin?: string }).origin
        if (typeof globalOrigin === 'string' && globalOrigin !== 'null') {
            cachedOrigin = globalOrigin
            return cachedOrigin
        }

        const location = (globalThis as { location?: { origin?: string; protocol?: string; host?: string } }).location
        if (location) {
            if (typeof location.origin === 'string' && location.origin !== 'null') {
                cachedOrigin = location.origin
                return cachedOrigin
            }
            if (location.protocol && location.host) {
                cachedOrigin = `${location.protocol}//${location.host}`
                return cachedOrigin
            }
        }
    }

    return cachedOrigin
}
