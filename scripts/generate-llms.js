'use strict'

const fs = require('fs/promises')
const path = require('path')
const { parseStringPromise } = require('xml2js')

/**
 * Mirror of getAllChapters() from lib/xml-parser.ts
 */
async function getAllChapters() {
    const pagesDir = path.join(process.cwd(), 'pages')
    const files = await fs.readdir(pagesDir)

    const adocFiles = files
        .filter((f) => f.endsWith('.adoc') && /^\d{2}__/.test(f))
        .sort()

    return adocFiles
        .map((file) => {
            const match = file.match(/^(\d{2})__(.+)\.adoc$/)
            if (!match) return null

            const [, number, slug] = match
            const title = slug
                .replace(/-/g, ' ')
                .replace(/\b\w/g, (l) => l.toUpperCase())

            return {
                id: file.replace('.adoc', ''),
                title,
                number,
            }
        })
        .filter(Boolean)
}

/**
 * Mirror of parseDocBookXML() from lib/xml-parser.ts
 */
async function parseDocBookXML(filePath) {
    const xmlContent = await fs.readFile(filePath, 'utf-8')

    const result = await parseStringPromise(xmlContent, {
        preserveChildrenOrder: true,
        explicitChildren: true,
        charsAsChildren: true,
    })

    const book = result.book || {}
    const info = book.info && book.info[0]
    const rawTitle = info && info.title && info.title[0]
    const title =
        typeof rawTitle === 'string'
            ? rawTitle
            : (rawTitle && rawTitle._) || 'Untitled'
    const chapters = book.chapter || []

    return { title, chapters }
}

function extractMixedText(children) {
    if (!children || !Array.isArray(children)) return ''

    let result = ''

    for (const child of children) {
        const name = child['#name']

        if (name === '__text__') {
            result += child._ || ''
            continue
        }

        if (name === 'literal') {
            const text = child._ || ''
            result += '`' + text + '`'
            continue
        }

        if (name === 'emphasis') {
            if (typeof child._ === 'string') {
                result += child._
            } else if (child.$$) {
                result += extractMixedText(child.$$)
            }
            continue
        }

        if (name === 'link') {
            const attrs = child.$ || {}
            const href = attrs['xl:href'] || attrs.href
            const text = child._ || ''
            if (href) {
                if (text) {
                    result += `${text} (${href})`
                } else {
                    result += href
                }
            } else {
                result += text
            }
            continue
        }

        if (child.$$) {
            result += extractMixedText(child.$$)
        }
    }

    // Normalize internal whitespace a bit without destroying code formatting
    return result.replace(/[ \t]+/g, ' ').replace(/\s+\n/g, '\n').trim()
}

function trimTrailingBlankLines(lines) {
    let end = lines.length
    while (end > 0 && lines[end - 1] === '') end--
    return lines.slice(0, end)
}

async function renderProgramListing(node, rootDir) {
    let codeText = node._ || ''
    const language = (node.$ && node.$.language) || 'text'

    if (codeText.includes('Unresolved directive') && codeText.includes('include::')) {
        const match = codeText.match(/include::example\$chapters-data\/code\/([^\[]+)/)
        if (match) {
            const filePath = match[1]
            const fullPath = path.join(rootDir, 'chapters-data', 'code', filePath)
            try {
                codeText = await fs.readFile(fullPath, 'utf-8')
            } catch {
                // fall back to original unresolved text
            }
        }
    }

    const lang = (() => {
        const normalized = (language || '').toLowerCase()
        if (['sh', 'bash', 'shell', 'zsh'].includes(normalized)) return 'shell'
        if (!normalized) return 'text'
        return normalized
    })()

    const lines = []
    lines.push('```' + lang)
    if (codeText) {
        const codeLines = codeText.replace(/\r\n/g, '\n').split('\n')
        lines.push(...codeLines)
    }
    lines.push('```')
    lines.push('')
    return lines
}

async function renderBlock(node, rootDir, indentLevel = 0) {
    const name = node['#name']
    const children = node.$$ || []
    const lines = []

    const indent = '' // keep flat; indentLevel reserved if needed later

    if (name === 'simpara') {
        const text = extractMixedText(children.length ? children : [{ '#name': '__text__', _: node._ }])
        if (text) {
            lines.push(indent + text)
            lines.push('')
        }
        return lines
    }

    if (name === 'programlisting') {
        return renderProgramListing(node, rootDir)
    }

    if (name === 'itemizedlist') {
        const items = children.filter((c) => c['#name'] === 'listitem')
        for (const item of items) {
            const paras = (item.$$ || []).filter((c) => c['#name'] === 'simpara')
            const itemText = paras
                .map((p) => extractMixedText(p.$$ || [{ '#name': '__text__', _: p._ }]))
                .filter(Boolean)
                .join(' ')
            if (itemText) {
                lines.push(indent + '- ' + itemText)
            }
        }
        if (lines.length) lines.push('')
        return lines
    }

    if (name === 'orderedlist') {
        const items = children.filter((c) => c['#name'] === 'listitem')
        let index = 1
        for (const item of items) {
            const paras = (item.$$ || []).filter((c) => c['#name'] === 'simpara')
            const itemText = paras
                .map((p) => extractMixedText(p.$$ || [{ '#name': '__text__', _: p._ }]))
                .filter(Boolean)
                .join(' ')
            if (itemText) {
                lines.push(indent + `${index}. ` + itemText)
            }
            index++
        }
        if (lines.length) lines.push('')
        return lines
    }

    if (name === 'variablelist') {
        const entries = children.filter((c) => c['#name'] === 'varlistentry')
        for (const entry of entries) {
            const termNode = (entry.$$ || []).find((c) => c['#name'] === 'term')
            const listitemNode = (entry.$$ || []).find((c) => c['#name'] === 'listitem')
            const term = (termNode && termNode._) || ''
            const defLines = []
            if (listitemNode && listitemNode.$$) {
                for (const child of listitemNode.$$) {
                    defLines.push(...(await renderBlock(child, rootDir, indentLevel + 1)))
                }
            }
            if (term) {
                lines.push(indent + '- ' + term + (defLines.length ? ':' : ''))
            }
            lines.push(...defLines.map((l) => (l ? indent + '  ' + l : l)))
        }
        if (lines.length) lines.push('')
        return lines
    }

    if (name === 'blockquote') {
        const paras = children.filter((c) => c['#name'] === 'simpara')
        const attributionNode = children.find((c) => c['#name'] === 'attribution')
        const attr = attributionNode && attributionNode._ ? ` (${attributionNode._})` : ''
        lines.push(indent + `QUOTE${attr}:`)
        for (const p of paras) {
            const text = extractMixedText(p.$$ || [{ '#name': '__text__', _: p._ }])
            if (text) lines.push(indent + text)
        }
        lines.push('')
        return lines
    }

    if (name === 'formalpara') {
        const titleNode = children.find((c) => c['#name'] === 'title')
        const title = (titleNode && titleNode._) || ''
        if (title) {
            lines.push(indent + title + ':')
        }
        const paraNode = children.find((c) => c['#name'] === 'para')
        if (paraNode && paraNode.$$) {
            for (const child of paraNode.$$) {
                lines.push(...(await renderBlock(child, rootDir, indentLevel + 1)))
            }
        }
        return lines
    }

    if (['note', 'warning', 'tip', 'caution', 'important'].includes(name)) {
        const label = name.toUpperCase()
        lines.push(indent + label + ':')
        for (const child of children) {
            lines.push(...(await renderBlock(child, rootDir, indentLevel + 1)))
        }
        return lines
    }

    if (name === 'informaltable' || name === 'table') {
        const tgroup = children.find((c) => c['#name'] === 'tgroup')
        if (!tgroup || !tgroup.$$) return lines

        const thead = tgroup.$$.find((c) => c['#name'] === 'thead')
        const tbody = tgroup.$$.find((c) => c['#name'] === 'tbody')
        const headerRows = (thead && thead.$$) ? thead.$$.filter((c) => c['#name'] === 'row') : []
        const bodyRows = (tbody && tbody.$$) ? tbody.$$.filter((c) => c['#name'] === 'row') : []

        const renderRow = (row) => {
            const entries = (row.$$ || []).filter((c) => c['#name'] === 'entry')
            return entries.map((entry) => {
                const simpara = (entry.$$ || []).find((c) => c['#name'] === 'simpara')
                if (simpara) {
                    return extractMixedText(simpara.$$ || [{ '#name': '__text__', _: simpara._ }])
                }
                return extractMixedText(entry.$$ || [{ '#name': '__text__', _: entry._ }])
            })
        }

        if (headerRows.length) {
            const header = renderRow(headerRows[0])
            lines.push('| ' + header.join(' | ') + ' |')
            lines.push('| ' + header.map(() => '---').join(' | ') + ' |')
        }

        for (const row of bodyRows) {
            const cells = renderRow(row)
            lines.push('| ' + cells.join(' | ') + ' |')
        }

        if (lines.length) lines.push('')
        return lines
    }

    if (name === 'screen' || name === 'literallayout') {
        const text = node._ || ''
        const norm = text.replace(/\r\n/g, '\n')
        const block = []
        block.push('```text')
        block.push(...norm.split('\n'))
        block.push('```')
        block.push('')
        return block
    }

    if (name === 'sidebar') {
        // Treat sidebar as a NOTE-like block
        lines.push(indent + 'NOTE:')
        for (const child of children) {
            lines.push(...(await renderBlock(child, rootDir, indentLevel + 1)))
        }
        return lines
    }

    // Fallback: render children
    for (const child of children) {
        lines.push(...(await renderBlock(child, rootDir, indentLevel)))
    }

    return lines
}

async function renderSection(section, chapterId, rootDir, depth) {
    const lines = []
    const children = section.$$ || []
    const attrs = section.$ || {}
    const id = attrs['xml:id'] || ''
    const titleNode = children.find((c) => c['#name'] === 'title')
    const title = (titleNode && titleNode._) || ''

    const isTop = depth === 0
    const headingLabel = isTop ? '## Section' : '### Subsection'

    lines.push(`${headingLabel}: ${title || '(untitled)'}`)
    if (id) {
        lines.push(`[section_id: ${id}]`)
        lines.push(`[section_url: https://zigbook.net/chapters/${chapterId}#${id}]`)
    }
    lines.push('')

    for (const child of children) {
        const name = child['#name']
        if (name === 'title') continue
        if (name === 'section') {
            lines.push(...(await renderSection(child, chapterId, rootDir, depth + 1)))
            lines.push('')
        } else {
            lines.push(...(await renderBlock(child, rootDir, depth)))
        }
    }

    return trimTrailingBlankLines(lines)
}

async function generateLlms() {
    const rootDir = process.cwd()
    const chaptersMeta = await getAllChapters()

    const nowIso = new Date().toISOString()

    const outLines = []

    outLines.push('# Zigbook LLM Dataset')
    outLines.push('')
    outLines.push('project: Zigbook – The Zig Programming Language Book')
    outLines.push('url: https://zigbook.net')
    outLines.push('repository: https://github.com/zigbook/zigbook')
    outLines.push('license: MIT (see LICENSE in repository)')
    outLines.push(`generated_at: ${nowIso}`)
    outLines.push('zig_version: 0.15.2')
    outLines.push('')
    outLines.push('notes:')
    outLines.push('  - This file is a human-written dataset export for LLMs and tools.')
    outLines.push('  - See llms.txt and LLM.md/README for usage guidelines and citation expectations.')
    outLines.push('')

    for (const chapter of chaptersMeta) {
        const chapterId = chapter.id
        const xmlPath = path.join(rootDir, 'pages', `${chapterId}.xml`)

        let parsed = null
        try {
            await fs.access(xmlPath)
            parsed = await parseDocBookXML(xmlPath)
        } catch {
            parsed = null
        }

        const chapterTitle = (parsed && parsed.title) || chapter.title
        const slug = chapterId.replace(/^\d{2}__/, '')

        outLines.push(`# Chapter ${chapter.number} — ${chapterTitle}`)
        outLines.push(`[chapter_id: ${chapterId}]`)
        outLines.push(`[chapter_slug: ${slug}]`)
        outLines.push(`[chapter_number: ${chapter.number}]`)
        outLines.push(`[chapter_url: https://zigbook.net/chapters/${chapterId}]`)
        outLines.push('')

        if (parsed && parsed.chapters && parsed.chapters.length > 0) {
            for (const section of parsed.chapters) {
                outLines.push(...(await renderSection(section, chapterId, rootDir, 0)))
                outLines.push('')
            }
        } else {
            outLines.push('(This chapter is not yet available in XML format for export.)')
            outLines.push('')
        }

        outLines.push('')
    }

    const content = outLines.join('\n').replace(/\r\n/g, '\n')

    const rootOutputPath = path.join(rootDir, 'llms.txt')
    const publicOutputPath = path.join(rootDir, 'public', 'llms.txt')

    await fs.writeFile(rootOutputPath, content, 'utf8')
    await fs.writeFile(publicOutputPath, content, 'utf8')

    // eslint-disable-next-line no-console
    console.log(`llms.txt generated at ${rootOutputPath} and ${publicOutputPath}`)
}

generateLlms().catch((err) => {
    // eslint-disable-next-line no-console
    console.error('Failed to generate llms.txt', err)
    process.exit(1)
})
