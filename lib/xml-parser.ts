import { parseStringPromise } from 'xml2js'
import fs from 'fs/promises'
import path from 'path'

export interface Chapter {
    id: string
    title: string
    number: string
}

export interface ParsedContent {
    title: string
    chapters: any[]
}

export async function parseDocBookXML(filePath: string): Promise<ParsedContent> {
    const xmlContent = await fs.readFile(filePath, 'utf-8')

    // Parse with preserveChildrenOrder to maintain mixed content order
    const result = await parseStringPromise(xmlContent, {
        preserveChildrenOrder: true,
        explicitChildren: true,
        charsAsChildren: true
    })
    
    // Collect top-level content in reading order. Some chapters (like the
    // introduction) use a DocBook <preface> element that should be rendered
    // before the first <chapter>. Treat prefaces as chapter-like sections so
    // the renderer can display them (e.g. opening quotes) alongside chapters.
    const chapters: any[] = []

    if (result.book?.preface) {
        chapters.push(...result.book.preface)
    }

    if (result.book?.chapter) {
        chapters.push(...result.book.chapter)
    }

    return {
        title: result.book?.info?.[0]?.title?.[0] || 'Untitled',
        chapters,
    }
}

export async function getAllChapters(): Promise<Chapter[]> {
    const pagesDir = path.join(process.cwd(), 'pages')
    const files = await fs.readdir(pagesDir)

    const adocFiles = files
        .filter(f => f.endsWith('.adoc') && f.match(/^\d{2}__/))
        .sort()

    return adocFiles.map(file => {
        const match = file.match(/^(\d{2})__(.+)\.adoc$/)
        if (!match) return null

        const [, number, slug] = match
        const title = slug.replace(/-/g, ' ').replace(/\b\w/g, l => l.toUpperCase())

        return {
            id: file.replace('.adoc', ''),
            title,
            number
        }
    }).filter(Boolean) as Chapter[]
}

const fallbackTitleFromSlug = (slug?: string): string => {
    if (typeof slug === 'string' && slug.length > 0) {
        return slug.replace(/^\d{2}__/, '').replace(/-/g, ' ')
    }
    return 'Untitled'
}

export async function getChapterContent(chapterId?: string) {
    const fallbackTitle = fallbackTitleFromSlug(chapterId)

    if (!chapterId) {
        return {
            title: fallbackTitle,
            chapters: [],
        }
    }

    const xmlPath = path.join(process.cwd(), 'pages', `${chapterId}.xml`)

    try {
        await fs.access(xmlPath)
        return await parseDocBookXML(xmlPath)
    } catch {
        // XML doesn't exist yet, return placeholder
        return {
            title: fallbackTitle,
            chapters: [],
        }
    }
}
