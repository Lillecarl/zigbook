'use client'

import Link from 'next/link'
import { useMemo, useState } from 'react'

interface SidebarClientProps {
  chapters: Array<{ id: string; title: string; number: string }>
  currentChapterId?: string
}

export default function SidebarClient({ chapters, currentChapterId }: SidebarClientProps) {
  const [query, setQuery] = useState('')

  const normalizedQuery = query.trim().toLowerCase()

  const filteredChapters = useMemo(() => {
    if (!normalizedQuery) return chapters

    return chapters.filter((chapter) => {
      const haystack = `${chapter.number} ${chapter.title}`.toLowerCase()
      return haystack.includes(normalizedQuery)
    })
  }, [chapters, normalizedQuery])

  const hasQuery = normalizedQuery.length > 0

  return (
    <aside className="hidden lg:flex lg:h-full lg:w-80 lg:shrink-0 lg:flex-col lg:overflow-y-auto border-r border-base-300 bg-base-100">
      <div className="p-4">
        <Link href="/" className="btn btn-ghost btn-block justify-start mb-6">
          <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
          Back to Home
        </Link>

        <div className="mb-3 flex items-center justify-between">
          <span className="text-xs font-semibold uppercase tracking-wider text-base-content/70">
            Table of Contents
          </span>
          <span className="text-[0.65rem] text-base-content/50">{chapters.length} chapters</span>
        </div>

        {/* Search */}
        <div className="mb-4">
          <label className="input input-sm input-bordered flex items-center gap-2 w-full">
            <svg
              className="h-4 w-4 opacity-60"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M21 21l-4.35-4.35M17 10a7 7 0 11-14 0 7 7 0 0114 0z"
              />
            </svg>
            <input
              type="text"
              className="grow bg-transparent text-xs outline-none"
              placeholder="Filter chapters…"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
            />
          </label>
        </div>

        <ul className="menu menu-md gap-1">
          {filteredChapters.map((chapter) => {
            const isActive = currentChapterId === chapter.id
            const baseItem =
              'flex items-center gap-3 rounded-lg px-2 py-2 text-sm transition-all duration-150 ease-out border'
            const activeItem =
              'bg-base-100/15 border-accent/60 shadow-[0_6px_20px_rgba(0,0,0,0.35)]'
            const inactiveItem = 'border-transparent hover:-translate-x-[1px] hover:shadow-[0_4px_14px_rgba(0,0,0,0.22)] hover:bg-base-100/40'

            return (
              <li key={chapter.id} className="mt-0.5">
                <Link
                  href={`/chapters/${chapter.id}`}
                  className={`${baseItem} ${isActive ? activeItem : inactiveItem}`}
                >
                  <span
                    className={`badge badge-sm ${
                      isActive ? 'badge-primary' : 'badge-neutral'
                    }`}
                  >
                    {chapter.number}
                  </span>
                  <span className="flex-1 truncate text-sm text-base-content">
                    {chapter.title}
                  </span>
                </Link>
              </li>
            )
          })}

          {hasQuery && filteredChapters.length === 0 && (
            <li className="mt-2 text-xs text-base-content/60">
              No chapters match your search.
            </li>
          )}
        </ul>
      </div>
    </aside>
  )
}
