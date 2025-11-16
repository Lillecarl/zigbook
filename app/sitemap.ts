import type { MetadataRoute } from 'next'
import { getAllChapters } from '@/lib/xml-parser'

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
    const baseUrl = 'https://zigbook.net'
    const chapters = await getAllChapters()

    const routes: MetadataRoute.Sitemap = [
        {
            url: `${baseUrl}/`,
            lastModified: new Date(),
            changeFrequency: 'weekly',
            priority: 1,
        },
        {
            url: `${baseUrl}/contribute`,
            lastModified: new Date(),
            changeFrequency: 'monthly',
            priority: 0.6,
        },
    ]

    const chapterRoutes: MetadataRoute.Sitemap = chapters.map((chapter) => ({
        url: `${baseUrl}/chapters/${chapter.id}`,
        lastModified: new Date(),
        changeFrequency: 'monthly',
        priority: 0.8,
    }))

    return [...routes, ...chapterRoutes]
}
