'use client'

import { useEffect, useMemo, useRef, useState } from 'react'
import { useRouter } from 'next/navigation'
import type { Chapter } from '@/lib/xml-parser'
import CommandPaletteContext from './CommandPaletteContext'

interface CommandPaletteClientProps {
  chapters: Chapter[]
  children: React.ReactNode
}

type CommandType = 'chapter' | 'page' | 'external' | 'utility'

type Command = {
  id: string
  label: string
  subtitle?: string
  type: CommandType
  icon: 'chapter' | 'home' | 'github' | 'theme' | 'random' | 'page'
  action: () => void
}

export default function CommandPaletteClient({ chapters, children }: CommandPaletteClientProps) {
  const router = useRouter()
  const [isOpen, setIsOpen] = useState(false)
  const [query, setQuery] = useState('')
  const [activeIndex, setActiveIndex] = useState(0)
  const inputRef = useRef<HTMLInputElement | null>(null)

  const open = () => setIsOpen(true)
  const close = () => {
    setIsOpen(false)
    setQuery('')
  }
  const toggle = () => setIsOpen((prev) => !prev)

  // Focus search input when palette opens
  useEffect(() => {
    if (isOpen && inputRef.current) {
      inputRef.current.focus()
      inputRef.current.select()
    }
  }, [isOpen])

  // Global keyboard shortcuts: Cmd/Ctrl+K to open/toggle, Esc to close
  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      const isK = event.key.toLowerCase() === 'k'
      const isMetaOrCtrl = event.metaKey || event.ctrlKey

      if (isMetaOrCtrl && isK) {
        event.preventDefault()
        toggle()
      } else if (event.key === 'Escape' && isOpen) {
        event.preventDefault()
        close()
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [isOpen])

  const toggleTheme = () => {
    if (typeof document === 'undefined') return
    const root = document.documentElement
    const current =
      root.getAttribute('data-theme') || localStorage.getItem('theme') || 'business'
    const next = current === 'business' ? 'wireframe' : 'business'
    root.setAttribute('data-theme', next)
    localStorage.setItem('theme', next)
  }

  const commands: Command[] = useMemo(() => {
    const chapterCommands: Command[] = chapters.map((chapter) => ({
      id: `chapter:${chapter.id}`,
      label: chapter.title,
      subtitle: `Chapter ${chapter.number}`,
      type: 'chapter',
      icon: 'chapter',
      action: () => {
        router.push(`/chapters/${chapter.id}`)
        close()
      },
    }))

    const pageCommands: Command[] = [
      {
        id: 'page:home',
        label: 'Home',
        subtitle: '/',
        type: 'page',
        icon: 'home',
        action: () => {
          router.push('/')
          close()
        },
      },
      {
        id: 'page:toc',
        label: 'Table of Contents',
        subtitle: '/chapters/00__zigbook_introduction',
        type: 'page',
        icon: 'page',
        action: () => {
          router.push('/chapters/00__zigbook_introduction')
          close()
        },
      },
      {
        id: 'page:playground',
        label: 'Playground',
        subtitle: '/playground',
        type: 'page',
        icon: 'page',
        action: () => {
          router.push('/playground')
          close()
        },
      },
      {
        id: 'page:contribute',
        label: 'Contribute',
        subtitle: '/contribute',
        type: 'page',
        icon: 'page',
        action: () => {
          router.push('/contribute')
          close()
        },
      },
      {
        id: 'page:privacy',
        label: 'Privacy Policy',
        subtitle: '/privacy-policy',
        type: 'page',
        icon: 'page',
        action: () => {
          router.push('/privacy-policy')
          close()
        },
      },
      {
        id: 'page:terms',
        label: 'Terms of Service',
        subtitle: '/terms-of-service',
        type: 'page',
        icon: 'page',
        action: () => {
          router.push('/terms-of-service')
          close()
        },
      },
    ]

    const externalCommands: Command[] = [
      {
        id: 'external:github',
        label: 'Zigbook on GitHub',
        subtitle: 'github.com/zigbook/zigbook',
        type: 'external',
        icon: 'github',
        action: () => {
          window.open('https://github.com/zigbook/zigbook', '_blank', 'noopener,noreferrer')
          close()
        },
      },
    ]

    const utilityCommands: Command[] = [
      {
        id: 'utility:theme',
        label: 'Toggle theme',
        subtitle: 'Business · Wireframe',
        type: 'utility',
        icon: 'theme',
        action: () => {
          toggleTheme()
          close()
        },
      },
      {
        id: 'utility:random-chapter',
        label: 'Random chapter',
        subtitle: chapters.length ? `${chapters.length} available` : undefined,
        type: 'utility',
        icon: 'random',
        action: () => {
          if (!chapters.length) return
          const index = Math.floor(Math.random() * chapters.length)
          const chapter = chapters[index]
          if (!chapter) return
          router.push(`/chapters/${chapter.id}`)
          close()
        },
      },
    ]

    return [...utilityCommands, ...pageCommands, ...chapterCommands, ...externalCommands]
  }, [chapters, router])

  const normalizedQuery = query.trim().toLowerCase()

  const filteredCommands = useMemo(() => {
    if (!normalizedQuery) return commands

    return commands.filter((cmd) => {
      const haystack = `${cmd.label} ${cmd.subtitle || ''}`.toLowerCase()
      return haystack.includes(normalizedQuery)
    })
  }, [commands, normalizedQuery])

  useEffect(() => {
    if (!isOpen) return
    if (!filteredCommands.length) {
      setActiveIndex(0)
    } else {
      setActiveIndex(0)
    }
  }, [isOpen, filteredCommands])

  const handleInputKeyDown = (event: React.KeyboardEvent<HTMLInputElement>) => {
    if (!filteredCommands.length) return

    if (event.key === 'ArrowDown') {
      event.preventDefault()
      setActiveIndex((prev) => (prev + 1) % filteredCommands.length)
    } else if (event.key === 'ArrowUp') {
      event.preventDefault()
      setActiveIndex((prev) => (prev - 1 + filteredCommands.length) % filteredCommands.length)
    } else if (event.key === 'Enter') {
      event.preventDefault()
      const cmd = filteredCommands[activeIndex]
      if (cmd) cmd.action()
    }
  }

  const handleItemClick = (cmd: Command) => {
    cmd.action()
  }

  const contextValue = useMemo(
    () => ({ isOpen, open, close, toggle }),
    [isOpen],
  )

  return (
    <CommandPaletteContext.Provider value={contextValue}>
      {children}
      {isOpen && (
        <div className="fixed inset-0 z-50 flex items-start justify-center pt-[15vh]">
          {/* Backdrop */}
          <button
            type="button"
            className="absolute inset-0 bg-base-300/50 backdrop-blur-sm"
            aria-label="Close command palette"
            onClick={close}
          />

          {/* Panel */}
          <div className="relative z-10 w-full max-w-xl mx-4 rounded-2xl border border-base-300/60 bg-base-100/90 shadow-[0_24px_60px_rgba(0,0,0,0.6)] backdrop-blur-xl">
            {/* Search input */}
            <div className="flex items-center gap-2 border-b border-base-300/60 px-3 py-2.5">
              <svg
                className="h-4 w-4 text-base-content/60"
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
                ref={inputRef}
                type="text"
                className="flex-1 bg-transparent text-sm outline-none placeholder:text-base-content/50"
                placeholder="Jump to chapter, page, or action… · Ctrl / ⌘ K"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                onKeyDown={handleInputKeyDown}
              />
            </div>

            {/* Results list */}
            <div className="max-h-80 overflow-y-auto px-2 py-2 text-sm">
              {filteredCommands.length === 0 ? (
                <div className="px-3 py-6 text-xs text-base-content/60">
                  No results. Try searching for a chapter number, title, or command.
                </div>
              ) : (
                <ul className="space-y-1">
                  {filteredCommands.map((cmd, index) => {
                    const isActive = index === activeIndex

                    const baseItem =
                      'flex items-center justify-between gap-3 rounded-lg px-3 py-2 cursor-pointer border transition-all duration-150 ease-out'
                    const activeItem =
                      'bg-base-200/80 border-accent/70 text-base-content shadow-[0_10px_30px_rgba(0,0,0,0.35)]'
                    const inactiveItem =
                      'border-transparent text-base-content/80 hover:bg-base-200/60 hover:border-base-300/80 hover:-translate-x-[1px]'

                    return (
                      <li key={cmd.id}>
                        <button
                          type="button"
                          onClick={() => handleItemClick(cmd)}
                          className={`${baseItem} ${isActive ? activeItem : inactiveItem}`}
                        >
                          <div className="flex items-center gap-2">
                            <span className="flex h-6 w-6 items-center justify-center rounded-md bg-base-300/80 text-[0.7rem]">
                              {cmd.icon === 'chapter' && 'Ch'}
                              {cmd.icon === 'home' && 'H'}
                              {cmd.icon === 'github' && 'GH'}
                              {cmd.icon === 'theme' && 'Th'}
                              {cmd.icon === 'random' && '?'}
                              {cmd.icon === 'page' && 'Pg'}
                            </span>
                            <div className="flex flex-col items-start text-left">
                              <span className="text-xs sm:text-sm font-medium">{cmd.label}</span>
                              {cmd.subtitle && (
                                <span className="text-[0.7rem] text-base-content/60">{cmd.subtitle}</span>
                              )}
                            </div>
                          </div>
                        </button>
                      </li>
                    )
                  })}
                </ul>
              )}
            </div>

            {/* Footer hints */}
            <div className="flex items-center justify-between border-t border-base-300/60 px-3 py-2 text-[0.7rem] text-base-content/60">
              <span>↑↓ to navigate · Enter to select · Esc to close</span>
              <span className="hidden sm:flex items-center gap-1">
                <span className="kbd kbd-xs">Ctrl</span>
                <span className="kbd kbd-xs">K</span>
                <span className="text-base-content/50">or</span>
                <span className="kbd kbd-xs">⌘</span>
                <span className="kbd kbd-xs">K</span>
              </span>
            </div>
          </div>
        </div>
      )}
    </CommandPaletteContext.Provider>
  )
}
