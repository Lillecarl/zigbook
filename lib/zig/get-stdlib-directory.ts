import { Directory, File } from '@bjorn3/browser_wasi_shim'
import { untar, type TarLocalFile } from '@andrewbranch/untar.js'
import { gunzipSync } from 'fflate'

import { fetchZigStdlibArchive } from './fetch-assets'
import { PLAYGROUND_ZIG_VERSION } from './toolchain-info'

export type DirectoryTree = Directory

type TreeNode = Map<string, TreeNode | Uint8Array>

const textDecoder = new TextDecoder()
const STDLIB_VERSION_PATH = ['std', 'builtin.zig']
const VERSION_REGEX = /pub\s+const\s+Version\s*=\s*"([^"]+)"/
let stdlibVersionWarningIssued = false

let stdlibTreePromise: Promise<TreeNode> | null = null
let cachedStdlibTree: TreeNode | null = null

export async function getZigStdlibDirectory(): Promise<Directory> {
    const tree = await loadStdlibTree()
    return convertTreeToDirectory(tree)
}

async function loadStdlibTree(): Promise<TreeNode> {
    if (cachedStdlibTree) {
        return cachedStdlibTree
    }

    if (!stdlibTreePromise) {
        stdlibTreePromise = hydrateStdlibTree()
            .then((tree) => {
                cachedStdlibTree = tree
                return tree
            })
            .catch((error) => {
                stdlibTreePromise = null
                cachedStdlibTree = null
                throw error
            })
    }

    return stdlibTreePromise
}

async function hydrateStdlibTree(): Promise<TreeNode> {
    const archiveBytes = await fetchZigStdlibArchive()
    const tarBytes = await gunzipBytes(archiveBytes)
    const entries = untar(toArrayBuffer(tarBytes))

    const tree: TreeNode = new Map()

    for (const entry of entries) {
        const normalizedPath = normalizeEntryPath(entry)
        if (!normalizedPath || !normalizedPath.startsWith('lib/')) {
            continue
        }

        const relativePath = normalizedPath.slice('lib/'.length)
        if (!relativePath) {
            continue
        }

        const segments = relativePath
            .split('/')
            .map((segment) => segment.trim())
            .filter((segment) => segment.length > 0 && segment !== '.')

        if (segments.length === 0) {
            continue
        }

        if (isDirectoryEntry(entry)) {
            ensureTreeNode(tree, segments)
            continue
        }

        const parent = ensureTreeNode(tree, segments.slice(0, -1))
        const filename = segments[segments.length - 1]
        parent.set(filename, toUint8Array(entry.fileData))
    }

    if (tree.size === 0) {
        throw new Error('Zig stdlib archive did not contain any lib/ entries')
    }

    assertStdlibVersion(tree)

    return tree
}

function normalizeEntryPath(entry: TarLocalFile): string {
    return (entry.name || entry.filename || '').replace(/\\/g, '/').replace(/^\.\//, '')
}

function ensureTreeNode(root: TreeNode, segments: string[]): TreeNode {
    let current = root
    for (const segment of segments) {
        const existing = current.get(segment)
        if (existing instanceof Map) {
            current = existing
            continue
        }
        const next: TreeNode = new Map()
        current.set(segment, next)
        current = next
    }
    return current
}

function convertTreeToDirectory(node: TreeNode): Directory {
    const entries = new Map<string, Directory | File>()
    for (const [name, value] of node.entries()) {
        if (value instanceof Map) {
            entries.set(name, convertTreeToDirectory(value))
        } else {
            entries.set(name, new File(value, { readonly: true }))
        }
    }
    return new Directory(entries)
}

function assertStdlibVersion(tree: TreeNode) {
    const version = extractStdlibVersion(tree)
    if (!version) {
        warnOnce(
            'Unable to determine Zig stdlib version from zig.tar.gz. Continuing without strict version verification.',
        )
        return
    }
    if (version !== PLAYGROUND_ZIG_VERSION) {
        throw new Error(
            `Zig stdlib archive version mismatch: expected ${PLAYGROUND_ZIG_VERSION} but found ${version}. ` +
                'Please replace public/zig/zig.tar.gz with the matching toolchain assets (e.g., download zig.tar.gz from the same build as zig.wasm).',
        )
    }
}

function warnOnce(message: string) {
    if (stdlibVersionWarningIssued) {
        return
    }
    stdlibVersionWarningIssued = true
    if (typeof console !== 'undefined' && typeof console.warn === 'function') {
        console.warn(message)
    }
}

function extractStdlibVersion(tree: TreeNode): string | null {
    const entry = getTreeEntry(tree, STDLIB_VERSION_PATH)
    if (!(entry instanceof Uint8Array)) {
        return null
    }
    const source = textDecoder.decode(entry)
    const match = VERSION_REGEX.exec(source)
    return match?.[1] ?? null
}

function getTreeEntry(node: TreeNode, segments: string[]): TreeNode | Uint8Array | undefined {
    let current: TreeNode | Uint8Array = node
    for (const segment of segments) {
        if (!(current instanceof Map)) {
            return undefined
        }
        const next = current.get(segment)
        if (!next) {
            return undefined
        }
        current = next
    }
    return current
}

function isDirectoryEntry(entry: TarLocalFile): boolean {
    return entry.typeflag === '5' || entry.name.endsWith('/')
}

function toUint8Array(data: ArrayBuffer | Uint8Array): Uint8Array {
    return data instanceof Uint8Array ? data : new Uint8Array(data)
}

function toArrayBuffer(view: Uint8Array): ArrayBuffer {
    const buffer = view.buffer as ArrayBuffer
    if (view.byteOffset === 0 && view.byteLength === buffer.byteLength) {
        return buffer
    }
    return buffer.slice(view.byteOffset, view.byteOffset + view.byteLength)
}

async function gunzipBytes(bytes: Uint8Array): Promise<Uint8Array> {
    if (typeof DecompressionStream === 'function') {
        const stream = new Blob([toArrayBuffer(bytes)])
            .stream()
            .pipeThrough(new DecompressionStream('gzip'))
        const decompressed = await new Response(stream).arrayBuffer()
        return new Uint8Array(decompressed)
    }
    return gunzipSync(bytes)
}
