import { getChapterContent, getAllChapters } from '@/lib/xml-parser'
import Sidebar from '@/components/Sidebar'
import Navbar from '@/components/Navbar'
import ChapterRenderer from '@/components/ChapterRenderer'
import ChapterNav from '@/components/ChapterNav'
import MermaidInit from '@/components/MermaidInit'
import ReadingProgress from '@/components/ReadingProgress'
import ContributeCallout from '@/components/ContributeCallout'
import ChapterOutline from '@/components/ChapterOutline'

export async function generateStaticParams() {
  const chapters = await getAllChapters()
  return chapters.map((chapter) => ({
    slug: chapter.id,
  }))
}

export default async function ChapterPage({ 
  params 
}: { 
  params: { slug: string } 
}) {
  const content = await getChapterContent(params.slug)
  const chapters = await getAllChapters()
  const currentChapter = chapters.find(c => c.id === params.slug)
  
  // Extract title text from parsed structure
  const title = typeof content.title === 'string' 
    ? content.title 
    : (content.title as any)?._ || currentChapter?.title || 'Untitled'

  return (
    <div className="min-h-screen h-screen bg-base-200 w-full flex flex-col">
      <Navbar chapters={chapters} currentChapterId={params.slug} />
      <ReadingProgress targetId="chapter-article" />
      
      <div className="flex w-full flex-1 min-h-0 overflow-hidden">
        <Sidebar currentChapterId={params.slug} />

        <div className="flex flex-1 w-full min-h-0 overflow-hidden">
          <main className="flex-1 min-h-0 px-4 sm:px-6 lg:px-10 py-6 lg:py-10 w-full overflow-y-auto">
            <div className="mx-auto w-full max-w-4xl space-y-6 lg:space-y-8">
            {/* Breadcrumbs */}
            <nav className="text-xs sm:text-sm text-base-content/70">
              <ol className="flex flex-wrap items-center gap-1.5">
                <li>
                  <a href="/" className="hover:text-base-content transition-colors">Home</a>
                  <span className="mx-1 text-base-content/40">/</span>
                </li>
                <li>
                  <a
                    href="/chapters/00__zigbook_introduction"
                    className="hover:text-base-content transition-colors"
                  >
                    Chapters
                  </a>
                  {currentChapter && <span className="mx-1 text-base-content/40">/</span>}
                </li>
                {currentChapter && (
                  <li className="inline-flex items-center gap-2 font-medium text-base-content/80">
                    <span className="badge badge-xs sm:badge-sm badge-neutral">
                      {currentChapter.number}
                    </span>
                    <span className="truncate max-w-[14rem] sm:max-w-none">
                      {currentChapter.title}
                    </span>
                  </li>
                )}
              </ol>
            </nav>

            {/* Chapter card */}
            <section
              id="chapter-article"
              className="rounded-2xl border border-base-300/40 bg-base-100/80 px-5 py-6 shadow-[0_18px_60px_rgba(0,0,0,0.25)] backdrop-blur sm:px-8 sm:py-8 lg:px-10 lg:py-10"
            >
              {/* Chapter Title */}
              <header className="mb-10">
                <div className="mb-4 flex flex-wrap items-center gap-3">
                  <span className="badge badge-primary badge-lg">
                    Chapter {currentChapter?.number}
                  </span>
                  {currentChapter?.title && (
                    <span className="text-xs sm:text-sm text-base-content/60">
                      {currentChapter.title}
                    </span>
                  )}
                </div>
                <h1 className="text-3xl sm:text-4xl md:text-5xl font-bold leading-tight tracking-tight text-base-content">
                  {title}
                </h1>
              </header>

              {/* Chapter Content */}
              <article className="prose-zigbook">
                <ChapterRenderer content={content} />
              </article>
            </section>

            {/* Contribute callout */}
            <ContributeCallout chapterId={params.slug} />

              {/* Chapter Navigation */}
              <ChapterNav currentChapterId={params.slug} chapters={chapters} />

              {/* Mermaid Diagrams Initialization */}
              <MermaidInit />
            </div>
          </main>

          <ChapterOutline targetId="chapter-article" />
        </div>
      </div>
    </div>
  )
}
