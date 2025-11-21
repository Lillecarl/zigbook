'use client'

import { useEffect, useState, useRef, KeyboardEvent } from 'react'

const normalizeCommand = (raw: string) => raw.trim().replace(/\s+/g, ' ').toLowerCase()

const CANONICAL_COMMANDS = {
  build: 'zig build zigbook',
  help: 'help',
  clear: 'clear',
} as const

const BUILD_ALIASES = [
  CANONICAL_COMMANDS.build,
  'zig build',
  'zig build -Drelease-fast',
  'start',
  'run',
  'start zigbook',
  'run zigbook',
].map(normalizeCommand)

const HELP_ALIASES = [CANONICAL_COMMANDS.help, '?', 'man', 'man zigbook', '--help', '-h'].map(
  normalizeCommand
)

const CLEAR_ALIASES = [CANONICAL_COMMANDS.clear, 'cls'].map(normalizeCommand)

const ABOUT_ALIASES = ['about', 'zigbook', 'whoami'].map(normalizeCommand)

const SUGGESTABLE_COMMANDS = (Object.values(CANONICAL_COMMANDS) as string[]).map(cmd => ({
  display: cmd,
  normalized: normalizeCommand(cmd),
}))

function levenshtein(a: string, b: string): number {
  const aLen = a.length
  const bLen = b.length

  if (aLen === 0) return bLen
  if (bLen === 0) return aLen

  const dp = Array.from({ length: aLen + 1 }, () => new Array<number>(bLen + 1))

  for (let i = 0; i <= aLen; i++) dp[i][0] = i
  for (let j = 0; j <= bLen; j++) dp[0][j] = j

  for (let i = 1; i <= aLen; i++) {
    for (let j = 1; j <= bLen; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1
      dp[i][j] = Math.min(
        dp[i - 1][j] + 1, // deletion
        dp[i][j - 1] + 1, // insertion
        dp[i - 1][j - 1] + cost // substitution
      )
    }
  }

  return dp[aLen][bLen]
}

function findClosestCommand(normalizedInput: string): string | null {
  if (!normalizedInput) return null

  let bestCommand: string | null = null
  let bestDistance = Number.POSITIVE_INFINITY

  for (const { display, normalized } of SUGGESTABLE_COMMANDS) {
    const distance = levenshtein(normalizedInput, normalized)
    if (distance < bestDistance) {
      bestDistance = distance
      bestCommand = display
    }
  }

  const length = Math.max(normalizedInput.length, bestCommand?.length ?? 0)
  if (!bestCommand || length === 0) return null

  // Only suggest if the edit distance is reasonably small relative to the length
  const ratio = bestDistance / length
  if (bestDistance <= 1 || ratio <= 0.35) {
    return bestCommand
  }

  return null
}

export default function AnimatedTerminal() {
  const [input, setInput] = useState('')
  const [history, setHistory] = useState<string[]>([
    'Welcome to Zigbook 🦎',
    '',
    'Ready to transform how you think about software?',
    'Exec: zig build zigbook',
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
    mediaQuery.addListener(updatePreference)
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
      const normalized = normalizeCommand(input)

      if (!cmd) {
        setHistory(prev => [...prev, '$ '])
        setInput('')
        return
      }

      // Main entry command (accept a few variants, ignore case & extra spaces)
      if (BUILD_ALIASES.includes(normalized)) {
        setHistory(prev => [
          ...prev, 
          `$ ${cmd}`,
          '',
          '🦎 Initializing Zigbook...',
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
      // Clear terminal (with common aliases)
      } else if (CLEAR_ALIASES.includes(normalized)) {
        setHistory(['$ '])
        setInput('')
      // Help / usage information
      } else if (HELP_ALIASES.includes(normalized)) {
        setHistory(prev => [
          ...prev,
          `$ ${cmd}`,
          '',
          'Available commands:',
          '  zig build zigbook   - Start your learning journey',
          '  help                - Show this message',
          '  clear               - Clear terminal output',
          '',
          'Tips:',
          '  • Commands are case-insensitive and ignore extra spaces.',
          '  • Try `zig build zigbook` to jump into Chapter 0.',
          '',
          'There may also be a couple of hidden commands waiting to be discovered.',
          '',
          '$ '
        ])
        setInput('')
      // About / info easter egg
      } else if (ABOUT_ALIASES.includes(normalized)) {
        setHistory(prev => [
          ...prev,
          `$ ${cmd}`,
          '',
          'Zigbook is an open-source, in-depth guide to Zig that emphasizes real-world projects,',
          'composable patterns, and understanding how your code actually works under the hood.',
          '',
          'Learn more at https://zigbook.net',
          '',
          '$ ',
        ])
        setInput('')
      // Fun easter eggs
      } else if (normalized === 'sudo zig build zigbook') {
        setHistory(prev => [
          ...prev,
          `$ ${cmd}`,
          '',
          "[sudo] password for zigbook: ********",
          'Permission denied: you already have all the access you need here.',
          'Try: zig build zigbook',
          '$ ',
        ])
        setInput('')
      } else if (normalized === 'rm -rf /' || normalized === 'rm -rf /*') {
        setHistory(prev => [
          ...prev,
          `$ ${cmd}`,
          '',
          "Error: refusing to run a destructive command in this demo shell.",
          'Your real filesystem is safe. Try: zig build zigbook instead.',
          '$ ',
        ])
        setInput('')
      } else if (normalized === 'motivate' || normalized === 'inspire') {
        setHistory(prev => [
          ...prev,
          `$ ${cmd}`,
          '',
          'Every expert Zig developer was once where you are now. The important part is showing up,',
          'typing the code, and reading the errors rather than fearing them.',
          '',
          'You are absolutely capable of learning this. Let\'s go build something.',
          '',
          '$ ',
        ])
        setInput('')
      } else if (cmd) {
        const suggestion = findClosestCommand(normalized)
        setHistory(prev => [
          ...prev, 
          `$ ${cmd}`, 
          `zsh: command not found: ${cmd}`,
          ...(suggestion ? [`Did you mean: ${suggestion}?`] : []),
          '',
          'Try: zig build zigbook',
          '$ '
        ])
        setInput('')
      }
    }
  }

  return (
    <div className="mx-auto w-full max-w-2xl px-2">
      {/* Terminal Window */}
      <div className="group relative overflow-hidden rounded-xl border border-base-300/70 bg-base-300/40 bg-gradient-to-b from-base-300/60 via-base-300/20 to-base-100/10 shadow-[0_18px_60px_rgba(0,0,0,0.55)] backdrop-blur transition-all duration-150 hover:border-accent/70 hover:shadow-[0_22px_70px_rgba(0,0,0,0.6)]">
        {/* Terminal Header */}
        <div className="flex items-center gap-2 border-b border-base-300/70 bg-base-300/70 px-3 sm:px-4 py-2.5">
          <div className="flex gap-1.5 shrink-0">
            <div className="h-2 w-2 sm:h-2.5 sm:w-2.5 rounded-full bg-error/80 transition-colors duration-150 group-hover:bg-error" />
            <div className="h-2 w-2 sm:h-2.5 sm:w-2.5 rounded-full bg-warning/80 transition-colors duration-150 group-hover:bg-warning" />
            <div className="h-2 w-2 sm:h-2.5 sm:w-2.5 rounded-full bg-success/80 transition-colors duration-150 group-hover:bg-success" />
          </div>
          <div className="flex-1 text-center text-xs sm:text-sm font-medium text-base-content/70 truncate">
            zsh — zigbook.net
          </div>
        </div>

        {/* Terminal Content */}
        <div
          className="relative cursor-text p-3 sm:p-4 md:p-5 font-mono text-[0.7rem] sm:text-xs md:text-sm min-h-[260px] sm:min-h-[300px] text-left text-base-content/90 overflow-x-auto"
          onClick={() => inputRef.current?.focus()}
        >
          {history.map((line, idx) => {
            if (line.startsWith('$ ') && idx === history.length - 1) {
              // Current input line
              return (
                <div key={idx} className="flex items-center">
                  <span className="mr-1 sm:mr-2 text-[0.65rem] sm:text-[0.75rem] text-base-content/50 shrink-0">zigbook %</span>
                  <span className="font-semibold text-success shrink-0">$ </span>
                  <span className="ml-1 sm:ml-2 text-base-content break-all">{input}</span>
                  {cursorVisible && (
                    <span className="ml-0.5 inline-block h-4 sm:h-5 w-1.5 sm:w-2 bg-success shrink-0" />
                  )}
                </div>
              )
            } else if (line.startsWith('$ ')) {
              return (
                <div key={idx} className="flex items-center font-semibold text-success">
                  <span className="mr-1 sm:mr-2 text-[0.65rem] sm:text-[0.75rem] text-base-content/50 shrink-0">zigbook %</span>
                  <span className="break-all">{line}</span>
                </div>
              )
            } else {
              return (
                <div
                  key={idx}
                  className="whitespace-pre-wrap break-words text-base-content/90"
                >
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
      
      <div className="mt-3 flex justify-center text-xs sm:text-sm text-base-content/70 px-2">
        <div className="inline-flex items-center gap-2 rounded-full border border-accent/40 bg-base-100/10 px-3 py-1.5 max-w-full">
          <span className="h-1.5 w-1.5 rounded-full bg-accent shrink-0" />
          <span className="italic break-words text-center">Interactive terminal • Type to get started</span>
        </div>
      </div>
    </div>
  )
}
