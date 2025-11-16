'use client'

import { useEffect, useState, useRef, KeyboardEvent } from 'react'

export default function AnimatedTerminal() {
  const [input, setInput] = useState('')
  const [history, setHistory] = useState<string[]>([
    'Welcome to Zigbook',
    '',
    'Ready to transform how you think about software?',
    'Type: zig build zigbook',
    '',
    '$ '
  ])
  const [cursorVisible, setCursorVisible] = useState(true)
  const [prefersReducedMotion, setPrefersReducedMotion] = useState(false)
  const inputRef = useRef<HTMLInputElement>(null)

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

  // Blinking cursor (respect reduced motion)
  useEffect(() => {
    if (prefersReducedMotion) {
      setCursorVisible(true)
      return
    }

    const interval = setInterval(() => {
      setCursorVisible(v => !v)
    }, 530)

    return () => clearInterval(interval)
  }, [prefersReducedMotion])

  const handleKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') {
      e.preventDefault()
      const cmd = input.trim()
      
      if (cmd === 'zig build zigbook') {
        setHistory(prev => [
          ...prev, 
          `$ ${cmd}`,
          '',
          '🚀 Initializing Zigbook...',
          '📚 Loading 61 chapters...',
          '✨ Preparing your transformation...',
          '',
          '✓ Ready! Redirecting to Chapter 0...',
        ])
        setInput('')
        
        // Redirect after animation
        setTimeout(() => {
          window.location.href = '/chapters/00__zigbook_introduction'
        }, 2000)
      } else if (cmd === 'clear') {
        setHistory(['$ '])
        setInput('')
      } else if (cmd === 'help') {
        setHistory(prev => [
          ...prev,
          `$ ${cmd}`,
          '',
          'Available commands:',
          '  zig build zigbook  - Start your learning journey',
          '  help              - Show this message',
          '  clear             - Clear terminal',
          '',
          '$ '
        ])
        setInput('')
      } else if (cmd) {
        setHistory(prev => [
          ...prev, 
          `$ ${cmd}`, 
          `zsh: command not found: ${cmd}`,
          '',
          'Try: zig build zigbook',
          '$ '
        ])
        setInput('')
      } else {
        setHistory(prev => [...prev, '$ '])
        setInput('')
      }
    }
  }

  return (
    <div className="mx-auto w-full max-w-2xl">
      {/* Terminal Window */}
      <div className="group relative overflow-hidden rounded-xl border border-base-300/70 bg-base-300/40 bg-gradient-to-b from-base-300/60 via-base-300/20 to-base-100/10 shadow-[0_18px_60px_rgba(0,0,0,0.55)] backdrop-blur transition-all duration-150 hover:border-accent/70 hover:shadow-[0_22px_70px_rgba(0,0,0,0.6)]">
        {/* Terminal Header */}
        <div className="flex items-center gap-2 border-b border-base-300/70 bg-base-300/70 px-4 py-2.5">
          <div className="flex gap-1.5">
            <div className="h-2.5 w-2.5 rounded-full bg-error/80 transition-colors duration-150 group-hover:bg-error" />
            <div className="h-2.5 w-2.5 rounded-full bg-warning/80 transition-colors duration-150 group-hover:bg-warning" />
            <div className="h-2.5 w-2.5 rounded-full bg-success/80 transition-colors duration-150 group-hover:bg-success" />
          </div>
          <div className="flex-1 text-center text-xs sm:text-sm font-medium text-base-content/70">
            zsh — zigbook.net
          </div>
        </div>

        {/* Terminal Content */}
        <div
          className="relative cursor-text p-5 font-mono text-sm md:text-base min-h-[300px] text-left text-base-content/90"
          onClick={() => inputRef.current?.focus()}
        >
          {history.map((line, idx) => {
            if (line.startsWith('$ ') && idx === history.length - 1) {
              // Current input line
              return (
                <div key={idx} className="flex items-center">
                  <span className="mr-2 text-[0.75rem] text-base-content/50">zigbook %</span>
                  <span className="font-semibold text-success">$ </span>
                  <span className="ml-2 text-base-content">{input}</span>
                  {cursorVisible && (
                    <span className="ml-0.5 inline-block h-5 w-2 bg-success" />
                  )}
                </div>
              )
            } else if (line.startsWith('$ ')) {
              return (
                <div key={idx} className="flex items-center font-semibold text-success">
                  <span className="mr-2 text-[0.75rem] text-base-content/50">zigbook %</span>
                  <span>{line}</span>
                </div>
              )
            } else {
              return (
                <div key={idx} className="whitespace-pre text-base-content/90">
                  {line}
                </div>
              )
            }
          })}
          
          <input
            ref={inputRef}
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={handleKeyDown}
            className="opacity-0 absolute pointer-events-none"
            autoFocus
          />
        </div>
      </div>
      
      <div className="mt-3 flex justify-center text-xs sm:text-sm text-base-content/70">
        <div className="inline-flex items-center gap-2 rounded-full border border-accent/40 bg-base-100/10 px-3 py-1.5">
          <span className="h-1.5 w-1.5 rounded-full bg-accent" />
          <span className="italic">Interactive terminal • Type to get started</span>
        </div>
      </div>
    </div>
  )
}
