'use client'

import Link from 'next/link'
import { useMemo, useState } from 'react'
import { useRouter } from 'next/navigation'
import ThemeToggle from './ThemeToggle'
import { useCommandPalette } from './CommandPaletteContext'

interface NavbarProps {
  chapters?: Array<{ id: string; title: string; number: string }>
  currentChapterId?: string
}

export default function Navbar({ chapters = [], currentChapterId }: NavbarProps) {
  const [chapterQuery, setChapterQuery] = useState('')
  const router = useRouter()
  const { open: openCommandPalette } = useCommandPalette()
  
  const currentChapter = chapters.find(c => c.id === currentChapterId)

  const normalizedQuery = chapterQuery.trim().toLowerCase()

  const filteredChapters = useMemo(() => {
    if (!normalizedQuery) return chapters
    return chapters.filter(chapter => {
      const haystack = `${chapter.number} ${chapter.title}`.toLowerCase()
      return haystack.includes(normalizedQuery)
    })
  }, [chapters, normalizedQuery])

  const handleRandomChapter = () => {
    if (!chapters.length) return
    const index = Math.floor(Math.random() * chapters.length)
    const chapter = chapters[index]
    if (!chapter) return
    router.push(`/chapters/${chapter.id}`)
  }

  return (
    <>
      {/* Main Navbar */}
      <div className="navbar bg-base-100 shadow-lg sticky top-0 z-50">
        <div className="flex-none lg:hidden">
          <label 
            htmlFor="nav-drawer" 
            className="btn btn-ghost btn-circle"
            aria-label="Open menu"
          >
            <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </label>
        </div>
        
        <div className="flex-1">
          <Link href="/" className="btn btn-ghost text-xl font-bold">
            Zigbook
          </Link>
          {currentChapter && (
            <div className="hidden md:flex items-center gap-2 ml-4">
              <div
                className="tooltip tooltip-bottom"
                data-tip={currentChapter.title}
              >
                <div className="inline-flex max-w-xs items-center gap-2 rounded-full border border-base-300/60 bg-base-100/40 px-3 py-1 text-xs text-base-content/80">
                  <span className="badge badge-xs badge-primary">
                    {currentChapter.number}
                  </span>
                  <span className="truncate">
                    {currentChapter.title}
                  </span>
                </div>
              </div>
            </div>
          )}
        </div>
        
        <div className="flex-none flex items-center gap-2">
          {/* Command palette trigger */}
          <button
            type="button"
            onClick={openCommandPalette}
            className="btn btn-ghost btn-sm gap-2 hidden sm:inline-flex"
            aria-label="Open command palette"
          >
            <svg
              className="h-4 w-4 text-base-content/70"
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
            <span className="text-xs text-base-content/70">Search</span>
            <span className="hidden md:inline-flex items-center gap-1 rounded border border-base-300/80 px-1.5 py-0.5 text-[0.65rem] text-base-content/60">
              <span>Ctrl</span>
              <span>/</span>
              <span>⌘</span>
              <span>K</span>
            </span>
          </button>
          <button
            type="button"
            onClick={openCommandPalette}
            className="btn btn-ghost btn-circle sm:hidden"
            aria-label="Open command palette"
          >
            <svg
              className="h-5 w-5 text-base-content/70"
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
          </button>

          <ThemeToggle />
          <div className="dropdown dropdown-end">
            <label tabIndex={0} className="btn btn-ghost btn-circle" aria-label="Quick navigation">
              <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" />
              </svg>
            </label>
            <ul tabIndex={0} className="dropdown-content menu bg-base-100 rounded-box z-[1] w-52 p-2 shadow-lg border border-base-300">
              <li>
                <Link href="/">Home</Link>
              </li>
              <li>
                <Link href="/chapters/00__zigbook_introduction">Chapters (Table of Contents)</Link>
              </li>
              <li>
                <Link href="/contribute">Contribute</Link>
              </li>
              {chapters.length > 0 && (
                <li>
                  <button type="button" onClick={handleRandomChapter}>
                    Random chapter
                  </button>
                </li>
              )}
              <li className="menu-title mt-1">
                <span>Links</span>
              </li>
              <li>
                <a
                  href="https://github.com/zigbook/zigbook"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  GitHub
                </a>
              </li>
            </ul>
          </div>
        </div>
      </div>

      {/* Mobile Drawer */}
      <div className="drawer lg:hidden">
        <input id="nav-drawer" type="checkbox" className="drawer-toggle" />
        <div className="drawer-side z-40">
          <label htmlFor="nav-drawer" aria-label="close sidebar" className="drawer-overlay"></label>
          <aside className="menu bg-base-100 min-h-full w-80 p-4">
            <div className="mb-4 flex justify-between items-center">
              <Link href="/" className="text-xl font-bold">Zigbook</Link>
              <label htmlFor="nav-drawer" className="btn btn-ghost btn-sm btn-circle">✕</label>
            </div>
            
            <div className="mb-2">
              <div className="mb-2 flex items-center justify-between">
                <span className="text-xs uppercase tracking-wider text-base-content/70">
                  Chapters
                </span>
                <span className="text-[0.65rem] text-base-content/50">
                  {chapters.length} total
                </span>
              </div>
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
                  value={chapterQuery}
                  onChange={(e) => setChapterQuery(e.target.value)}
                />
              </label>
            </div>

            <ul className="menu-md gap-1 mt-2">
              {filteredChapters.map((chapter) => {
                const isActive = currentChapterId === chapter.id
                const baseItem =
                  'flex items-center gap-3 rounded-lg px-2 py-2 text-sm transition-all duration-150 ease-out border'
                const activeItem =
                  'bg-base-100/20 border-accent/60 shadow-[0_6px_18px_rgba(0,0,0,0.3)]'
                const inactiveItem =
                  'border-transparent hover:bg-base-100/70 hover:shadow-[0_4px_12px_rgba(0,0,0,0.18)]'

                return (
                  <li key={chapter.id} className="mt-0.5">
                    <Link
                      href={`/chapters/${chapter.id}`}
                      className={`${baseItem} ${isActive ? activeItem : inactiveItem}`}
                      onClick={() => {
                        const drawer = document.getElementById('nav-drawer') as HTMLInputElement
                        if (drawer) drawer.checked = false
                      }}
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

              {normalizedQuery && filteredChapters.length === 0 && (
                <li className="mt-2 text-xs text-base-content/60">
                  No chapters match your search.
                </li>
              )}
            </ul>
          </aside>
        </div>
      </div>
    </>
  )
}
