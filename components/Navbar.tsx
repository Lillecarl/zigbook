'use client'

import Link from 'next/link'
import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { useRouter } from 'next/navigation'
import ThemeToggle from './ThemeToggle'
import { useCommandPalette } from './CommandPaletteContext'
import NewLaunchPopover from './NewLaunchPopover'

interface NavbarProps {
  chapters?: Array<{ id: string; title: string; number: string }>
  currentChapterId?: string
}

const PLAYGROUND_VISITED_KEY = 'zigbook-playground-visited'
const FORUMS_VISITED_KEY = 'zigbook-forums-visited'

export default function Navbar({ chapters = [], currentChapterId }: NavbarProps) {
  const [chapterQuery, setChapterQuery] = useState('')
  const [prefersReducedMotion, setPrefersReducedMotion] = useState(false)
  const [hasPlaygroundAcknowledged, setHasPlaygroundAcknowledged] = useState<boolean | null>(null)
  const [hasForumsAcknowledged, setHasForumsAcknowledged] = useState<boolean | null>(null)
  const [isCtaClusterVisible, setIsCtaClusterVisible] = useState(false)
  const ctaClusterRef = useRef<HTMLDivElement | null>(null)
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

  useEffect(() => {
    if (typeof window === 'undefined') return
    setHasPlaygroundAcknowledged(window.localStorage.getItem(PLAYGROUND_VISITED_KEY) === '1')
    setHasForumsAcknowledged(window.localStorage.getItem(FORUMS_VISITED_KEY) === '1')
  }, [])

  useEffect(() => {
    if (typeof window === 'undefined' || typeof window.matchMedia !== 'function') return
    const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)')
    const updateMotionPreference = () => setPrefersReducedMotion(mediaQuery.matches)
    updateMotionPreference()
    if (typeof mediaQuery.addEventListener === 'function') {
      mediaQuery.addEventListener('change', updateMotionPreference)
    } else if (typeof mediaQuery.addListener === 'function') {
      mediaQuery.addListener(updateMotionPreference)
    }
    return () => {
      if (typeof mediaQuery.removeEventListener === 'function') {
        mediaQuery.removeEventListener('change', updateMotionPreference)
      } else if (typeof mediaQuery.removeListener === 'function') {
        mediaQuery.removeListener(updateMotionPreference)
      }
    }
  }, [])

  useEffect(() => {
    if (!ctaClusterRef.current) {
      setIsCtaClusterVisible(true)
      return
    }
    if (typeof IntersectionObserver === 'undefined') {
      setIsCtaClusterVisible(true)
      return
    }
    const observer = new IntersectionObserver(([entry]) => {
      setIsCtaClusterVisible(entry.isIntersecting)
    }, { threshold: 0.25 })
    observer.observe(ctaClusterRef.current)
    return () => observer.disconnect()
  }, [])

  useEffect(() => {
    if (typeof window === 'undefined') return
    const handleStorage = (event: StorageEvent) => {
      if (event.key === PLAYGROUND_VISITED_KEY) {
        setHasPlaygroundAcknowledged(event.newValue === '1')
      }
      if (event.key === FORUMS_VISITED_KEY) {
        setHasForumsAcknowledged(event.newValue === '1')
      }
    }
    window.addEventListener('storage', handleStorage)
    return () => window.removeEventListener('storage', handleStorage)
  }, [])

  const handleRandomChapter = () => {
    if (!chapters.length) return
    const index = Math.floor(Math.random() * chapters.length)
    const chapter = chapters[index]
    if (!chapter) return
    router.push(`/chapters/${chapter.id}`)
  }

  const closeDrawer = () => {
    const drawer = document.getElementById('nav-drawer') as HTMLInputElement | null
    if (drawer) drawer.checked = false
  }

  const markPlaygroundAcknowledged = useCallback(() => {
    if (typeof window !== 'undefined') {
      window.localStorage.setItem(PLAYGROUND_VISITED_KEY, '1')
    }
    setHasPlaygroundAcknowledged(true)
  }, [])

  const markForumsAcknowledged = useCallback(() => {
    if (typeof window !== 'undefined') {
      window.localStorage.setItem(FORUMS_VISITED_KEY, '1')
    }
    setHasForumsAcknowledged(true)
  }, [])

  const navCtaBase =
    'relative btn btn-sm font-semibold uppercase tracking-[0.25em] transition-all duration-200 hover:-translate-y-0.5 active:scale-95 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 shadow-[0_6px_18px_rgba(0,0,0,0.15)]'
  const shouldHighlightPlayground = hasPlaygroundAcknowledged === false
  const shouldHighlightForums = hasForumsAcknowledged === false
  const ctaAnimationEnabled = isCtaClusterVisible && !prefersReducedMotion
  const getHighlightClass = (isActive: boolean) =>
    isActive
      ? 'ring-1 ring-accent/60 ring-offset-2 ring-offset-base-100 shadow-[0_0_22px_rgba(248,169,73,0.45)]'
      : ''
  const getBadgePulseClass = (isActive: boolean) =>
    isActive && ctaAnimationEnabled ? 'motion-safe:animate-[pulse_3s_ease-in-out_infinite]' : ''
  const badgeBaseClass =
    'pointer-events-none absolute -bottom-2 -right-2 translate-x-1/3 translate-y-1/3 rounded-full border border-success/80 bg-success px-2 py-0.5 text-[0.6rem] font-semibold uppercase tracking-[0.25em] text-success-content shadow-[0_10px_25px_rgba(0,0,0,0.35)]'

  return (
    <>
      {/* Main Navbar */}
      <div className="navbar bg-base-100 shadow-lg sticky top-0 z-50 px-2 sm:px-4 w-full">
        <div className="flex-none lg:hidden">
          <label
            htmlFor="nav-drawer"
            className="btn btn-ghost btn-sm btn-circle"
            aria-label="Open menu"
          >
            <svg className="w-5 h-5 sm:w-6 sm:h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </label>
        </div>

        <div className="flex-1 min-w-0">
          <Link href="/" className="btn btn-ghost text-base sm:text-lg md:text-xl font-bold px-2 sm:px-4">
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
          <div ref={ctaClusterRef} className="hidden md:inline-flex items-center gap-2 mr-1">
            <div className="tooltip tooltip-bottom" data-tip="Browse the full Zigbook curriculum" tabIndex={0}>
              <Link
                href="/chapters/00__zigbook_introduction"
                className={`${navCtaBase} border border-accent/70 text-accent hover:border-accent hover:bg-accent/10 focus-visible:outline-accent/70 bg-transparent`}
              >
                Chapters
              </Link>
            </div>
            <div className="tooltip tooltip-bottom" data-tip="Compile Zig snippets in-browser via WASM" tabIndex={0}>
              <Link
                href="/playground"
                className={`${navCtaBase} border border-accent/60 bg-accent/15 text-accent hover:bg-accent/25 focus-visible:outline-accent/70 ${getHighlightClass(shouldHighlightPlayground)}`}
                onClick={markPlaygroundAcknowledged}
                aria-label="Open the Zigbook Playground"
              >
                Playground
                {shouldHighlightPlayground && (
                  <span className={`${badgeBaseClass} ${getBadgePulseClass(shouldHighlightPlayground)}`}>
                    New
                  </span>
                )}
              </Link>
            </div>
            <div className="tooltip tooltip-bottom" data-tip="Join the Zigbook community forums" tabIndex={0}>
              <a
                href="https://forums.zigbook.net/"
                className={`${navCtaBase} border border-accent/80 bg-accent text-base-100 hover:bg-accent/90 focus-visible:outline-accent/80 ${getHighlightClass(shouldHighlightForums)}`}
                target="_blank"
                rel="noreferrer"
                onClick={markForumsAcknowledged}
                aria-label="Visit the Zigbook forums"
              >
                Forums
                {shouldHighlightForums && (
                  <span className={`${badgeBaseClass} ${getBadgePulseClass(shouldHighlightForums)}`}>
                    NEW
                  </span>
                )}
              </a>
            </div>
          </div>
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
                <Link href="/playground" onClick={markPlaygroundAcknowledged}>
                  Playground
                </Link>
              </li>
              <li>
                <a
                  href="https://forums.zigbook.net/"
                  target="_blank"
                  rel="noopener noreferrer"
                  onClick={markForumsAcknowledged}
                >
                  Forums
                </a>
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
              <li className="menu-title mt-1">
                <span>Legal</span>
              </li>
              <li>
                <Link href="/privacy-policy">Privacy Policy</Link>
              </li>
              <li>
                <Link href="/terms-of-service">Terms of Service</Link>
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
          <aside className="menu bg-base-100 min-h-full w-[85vw] max-w-sm p-4 overflow-y-auto">
            <div className="mb-4 flex justify-between items-center">
              <Link href="/" className="text-lg sm:text-xl font-bold">Zigbook</Link>
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

            <div className="mt-4">
              <div className="text-[0.65rem] uppercase tracking-wider text-base-content/60">
                Navigation
              </div>
              <ul className="menu menu-sm gap-1 mt-2 rounded-2xl border border-base-300/50 bg-base-100/80 p-2 shadow-sm">
                <li>
                  <Link
                    href="/chapters/00__zigbook_introduction"
                    onClick={closeDrawer}
                    className="text-xs"
                  >
                    Chapters (Table of Contents)
                  </Link>
                </li>
                <li>
                  <Link
                    href="/playground"
                    onClick={(e) => {
                      closeDrawer()
                      markPlaygroundAcknowledged()
                    }}
                    className="text-xs"
                  >
                    Playground
                  </Link>
                </li>
                <li>
                  <a
                    href="https://forums.zigbook.net/"
                    onClick={() => {
                      closeDrawer()
                      markForumsAcknowledged()
                    }}
                    className="text-xs"
                    target="_blank"
                    rel="noreferrer"
                  >
                    Forums
                  </a>
                </li>
              </ul>
            </div>

            <ul className="menu-md gap-1 mt-2 overflow-y-auto">
              {filteredChapters.map((chapter) => {
                const isActive = currentChapterId === chapter.id
                const baseItem =
                  'flex items-center gap-2 sm:gap-3 rounded-lg px-2 py-2 text-xs sm:text-sm transition-all duration-150 ease-out border'
                const activeItem =
                  'bg-base-100/20 border-accent/60 shadow-[0_6px_18px_rgba(0,0,0,0.3)]'
                const inactiveItem =
                  'border-transparent hover:bg-base-100/70 hover:shadow-[0_4px_12px_rgba(0,0,0,0.18)]'

                return (
                  <li key={chapter.id} className="mt-0.5">
                    <Link
                      href={`/chapters/${chapter.id}`}
                      className={`${baseItem} ${isActive ? activeItem : inactiveItem}`}
                      onClick={closeDrawer}
                    >
                      <span
                        className={`badge badge-xs sm:badge-sm shrink-0 ${isActive ? 'badge-primary' : 'badge-neutral'
                          }`}
                      >
                        {chapter.number}
                      </span>
                      <span className="flex-1 truncate text-xs sm:text-sm text-base-content min-w-0">
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
      <NewLaunchPopover
        highlightPlayground={shouldHighlightPlayground}
        highlightForums={shouldHighlightForums}
        onPlaygroundNavigate={markPlaygroundAcknowledged}
        onForumsNavigate={markForumsAcknowledged}
      />
    </>
  )
}
