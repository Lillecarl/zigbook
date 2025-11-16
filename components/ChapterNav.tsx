import Link from 'next/link'

interface ChapterNavProps {
  currentChapterId: string
  chapters: Array<{ id: string; title: string; number: string }>
}

export default function ChapterNav({ currentChapterId, chapters }: ChapterNavProps) {
  const currentIndex = chapters.findIndex(c => c.id === currentChapterId)
  const prevChapter = currentIndex > 0 ? chapters[currentIndex - 1] : null
  const nextChapter = currentIndex < chapters.length - 1 ? chapters[currentIndex + 1] : null

  return (
    <nav className="mt-12 border-t border-base-300/70 pt-6">
      <div className="grid gap-4 md:grid-cols-2">
        {prevChapter ? (
          <Link
            href={`/chapters/${prevChapter.id}`}
            className="group flex items-center justify-between gap-3 rounded-xl border border-base-300/60 bg-base-100/10 px-4 py-3 text-left shadow-sm transition-all duration-150 hover:-translate-x-[2px] hover:border-accent/70 hover:shadow-[0_10px_30px_rgba(0,0,0,0.25)]"
          >
            <div className="flex items-center gap-3">
              <span className="inline-flex h-8 w-8 items-center justify-center rounded-full bg-base-300/70 text-base-content/80">
                <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                </svg>
              </span>
              <div>
                <div className="text-xs text-base-content/60">Previous chapter</div>
                <div className="mt-1 flex flex-wrap items-center gap-2 text-sm font-medium">
                  <span className="badge badge-xs badge-neutral">{prevChapter.number}</span>
                  <span className="line-clamp-2">{prevChapter.title}</span>
                </div>
              </div>
            </div>
          </Link>
        ) : (
          <div className="hidden md:block" />
        )}

        {nextChapter ? (
          <Link
            href={`/chapters/${nextChapter.id}`}
            className="group flex items-center justify-between gap-3 rounded-xl border border-base-300/60 bg-base-100/10 px-4 py-3 text-right shadow-sm transition-all duration-150 hover:translate-x-[2px] hover:border-accent/70 hover:shadow-[0_10px_30px_rgba(0,0,0,0.25)]"
          >
            <div className="flex flex-1 flex-col items-end gap-1">
              <div className="text-xs text-base-content/60">Next chapter</div>
              <div className="mt-1 flex flex-wrap items-center justify-end gap-2 text-sm font-medium">
                <span className="line-clamp-2">{nextChapter.title}</span>
                <span className="badge badge-xs badge-primary-content bg-primary/80">
                  {nextChapter.number}
                </span>
              </div>
            </div>
            <span className="inline-flex h-8 w-8 items-center justify-center rounded-full bg-base-300/70 text-base-content/80">
              <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </span>
          </Link>
        ) : (
          <div className="hidden md:block" />
        )}
      </div>
    </nav>
  )
}
