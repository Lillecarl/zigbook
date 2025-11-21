export type PlaygroundFile = {
    id: string
    name: string
    path: string
    contents: string
    readOnly?: boolean
}

export interface PlaygroundState {
    files: PlaygroundFile[]
    activeFileId: string | null
}

export const PLAYGROUND_STORAGE_KEY = 'zigbook-playground'

const isBrowser = typeof window !== 'undefined'

const normalizeFiles = (files: PlaygroundFile[] = []): PlaygroundFile[] => {
    return files
        .filter((file) => file && typeof file.id === 'string')
        .map((file) => ({
            ...file,
            name: file.name || file.path || 'untitled.zig',
            path: file.path || file.name || 'untitled.zig',
            contents: typeof file.contents === 'string' ? file.contents : '',
        }))
}

export const loadPlaygroundState = (): PlaygroundState | null => {
    if (!isBrowser) return null

    try {
        const raw = window.localStorage.getItem(PLAYGROUND_STORAGE_KEY)
        if (!raw) return null

        const parsed = JSON.parse(raw)
        if (!parsed || typeof parsed !== 'object') return null

        const normalizedFiles = normalizeFiles(parsed.files)

        return {
            files: normalizedFiles,
            activeFileId: typeof parsed.activeFileId === 'string' ? parsed.activeFileId : normalizedFiles[0]?.id ?? null,
        }
    } catch (error) {
        console.warn('Unable to load Zigbook playground state:', error)
        return null
    }
}

export const savePlaygroundState = (state: PlaygroundState): void => {
    if (!isBrowser) return
    try {
        const payload: PlaygroundState = {
            files: state.files,
            activeFileId: state.activeFileId ?? null,
        }
        window.localStorage.setItem(PLAYGROUND_STORAGE_KEY, JSON.stringify(payload))
    } catch (error) {
        console.warn('Unable to persist Zigbook playground state:', error)
    }
}

export const clearPlaygroundState = (): void => {
    if (!isBrowser) return
    try {
        window.localStorage.removeItem(PLAYGROUND_STORAGE_KEY)
    } catch (error) {
        console.warn('Unable to clear Zigbook playground state:', error)
    }
}

export const formatZigFilename = (name: string): string => {
    const trimmed = name?.trim() || 'untitled'
    const sanitized = trimmed
        .toLowerCase()
        .replace(/\s+/g, '_')
        .replace(/[^a-z0-9._/\-]/g, '-')
        .replace(/_{2,}/g, '_')
        .replace(/^_+|_+$/g, '') || 'untitled'
    if (sanitized.endsWith('.zig')) {
        return sanitized
    }
    return `${sanitized.replace(/\.+$/, '')}.zig`
}
