'use client'

import { useEffect, useMemo, useRef, useState } from 'react'

interface ChapterOutlineProps {
  targetId?: string
}

interface HeadingItem {
  id: string
  title: string
  level: 2 | 3
}

export default function ChapterOutline({ targetId = 'chapter-article' }: ChapterOutlineProps) {
  const [headings, setHeadings] = useState<HeadingItem[]>([])
  const [activeId, setActiveId] = useState<string | null>(null)
  const [prefersReducedMotion, setPrefersReducedMotion] = useState(false)
  const headingElementsRef = useRef<HTMLElement[]>([])

  // Detect reduced motion preference
  useEffect(() => {
    const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)')

    const updatePreference = () => {
      setPrefersReducedMotion(mediaQuery.matches)
    }

    updatePreference()

    if (typeof mediaQuery.addEventListener === 'function') {
      mediaQuery.addEventListener('change', updatePreference)
      return () => mediaQuery.removeEventListener('change', updatePreference)
    }

    // Fallback for older browsers
    // eslint-disable-next-line deprecation/deprecation
    mediaQuery.addListener(updatePreference)
    // eslint-disable-next-line deprecation/deprecation
    return () => mediaQuery.removeListener(updatePreference)
  }, [])

  // Collect headings from the rendered article
  useEffect(() => {
    const article = document.getElementById(targetId)
    if (!article) return

    const elements = Array.from(
      article.querySelectorAll('h2[id], h3[id]'),
    ) as HTMLElement[]

    headingElementsRef.current = elements

    const collected: HeadingItem[] = elements.map((el) => ({
      id: el.id,
      title: el.textContent?.trim() || el.id,
      level: el.tagName.toLowerCase() === 'h2' ? 2 : 3,
    }))

    setHeadings(collected)
  }, [targetId])

  // Scroll spy: update activeId based on scroll position
  useEffect(() => {
    if (!headings.length) return

    const article = document.getElementById(targetId)
    const scrollContainer = article?.closest('main')

    const handleScroll = () => {
      const items = headingElementsRef.current
      if (!items.length) return

      const offset = 96 // px from top (~ navbar + progress)

      let currentId = items[0].id
      for (const el of items) {
        const rect = el.getBoundingClientRect()
        if (rect.top - offset <= 0) {
          currentId = el.id
        } else {
          break
        }
      }

      setActiveId(currentId)
    }

    // Throttle with rAF
    let ticking = false
    const onScroll = () => {
      if (!ticking) {
        window.requestAnimationFrame(() => {
          handleScroll()
          ticking = false
        })
        ticking = true
      }
    }

    handleScroll()

    if (scrollContainer instanceof HTMLElement) {
      scrollContainer.addEventListener('scroll', onScroll, { passive: true })
      window.addEventListener('resize', handleScroll)

      return () => {
        scrollContainer.removeEventListener('scroll', onScroll)
        window.removeEventListener('resize', handleScroll)
      }
    } else {
      window.addEventListener('scroll', onScroll, { passive: true })
      window.addEventListener('resize', handleScroll)

      return () => {
        window.removeEventListener('scroll', onScroll)
        window.removeEventListener('resize', handleScroll)
      }
    }
  }, [headings, targetId])

  const handleClick = (id: string) => (event: React.MouseEvent<HTMLAnchorElement>) => {
    event.preventDefault()
    const target = document.getElementById(id)
    if (!target) return

    target.scrollIntoView({
      behavior: prefersReducedMotion ? 'auto' : 'smooth',
      block: 'start',
    })

    if (history.replaceState) {
      history.replaceState(null, '', `#${id}`)
    }
  }

  const hasHeadings = headings.length > 0

  const groupedHeadings = useMemo(() => headings, [headings])

  if (!hasHeadings) return null

  return (
    <aside className="hidden lg:flex lg:h-full lg:w-64 xl:w-72 lg:shrink-0 lg:flex-col border-l border-base-300 bg-base-200/60 pr-4 py-6">
      <nav aria-label="In-page chapters" className="h-full overflow-y-auto">
        <div className="rounded-xl border border-base-300/40 bg-base-100/70 px-4 py-4 shadow-[0_10px_40px_rgba(0,0,0,0.25)] backdrop-blur">
          <div className="mb-3 text-xs font-semibold uppercase tracking-wide text-base-content/70">
            On this page
          </div>
          <ul className="space-y-1 text-xs sm:text-sm">
            {groupedHeadings.map((heading) => {
              const isActive = heading.id === activeId
              const baseItem =
                'flex items-center gap-2 rounded-md px-2 py-1 transition-all duration-150 ease-out'
              const levelClass =
                heading.level === 3 ? 'ml-4 text-[0.78rem]' : 'text-[0.82rem] font-medium'
              const activeClass =
                'text-accent bg-base-100/60 border-l-2 border-accent'
              const inactiveClass =
                'text-base-content/60 hover:text-base-content hover:-translate-x-[1px]'

              return (
                <li key={heading.id}>
                  <a
                    href={`#${heading.id}`}
                    onClick={handleClick(heading.id)}
                    className={`${baseItem} ${levelClass} ${
                      isActive ? activeClass : inactiveClass
                    }`}
                  >
                    <span
                      className={`h-1.5 w-1.5 rounded-full ${
                        isActive ? 'bg-accent' : 'bg-base-300'
                      }`}
                    />
                    <span className="truncate">{heading.title}</span>
                  </a>
                </li>
              )
            })}
          </ul>
        </div>
      </nav>
    </aside>
  )
}
