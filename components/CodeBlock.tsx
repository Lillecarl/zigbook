'use client'

import { useEffect, useRef, useState } from 'react'
import Prism from 'prismjs'
import 'prismjs/components/prism-zig'

export default function CodeBlock({
  code,
  language = 'zig',
}: {
  code: string
  language?: string
}) {
  const [copied, setCopied] = useState(false)
  const copyTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  useEffect(() => {
    Prism.highlightAll()
  }, [code])

  useEffect(() => {
    return () => {
      if (copyTimeoutRef.current) {
        clearTimeout(copyTimeoutRef.current)
      }
    }
  }, [])

  const normalized = (language || 'code').toLowerCase()

  const languageLabels: Record<string, string> = {
    zig: 'Zig',
    sh: 'Shell',
    bash: 'Shell',
    shell: 'Shell',
    zsh: 'Shell',
    json: 'JSON',
    toml: 'TOML',
    yaml: 'YAML',
    yml: 'YAML',
    javascript: 'JavaScript',
    typescript: 'TypeScript',
  }

  const label =
    languageLabels[normalized] ||
    (normalized ? normalized.charAt(0).toUpperCase() + normalized.slice(1) : 'Code')

  const isZig = normalized === 'zig'
  const isShell = ['sh', 'bash', 'shell', 'zsh'].includes(normalized)

  const baseLabelClass =
    'inline-flex items-center rounded-full px-2 py-1 text-[0.65rem] uppercase tracking-wide border'
  const labelVariantClass = isZig
    ? 'border-accent/80 bg-accent/10 text-accent'
    : isShell
    ? 'border-success/70 bg-success/10 text-success'
    : 'border-base-300/70 bg-base-100/10 text-base-content/70'

  const handleCopy = async () => {
    try {
      if (navigator.clipboard && navigator.clipboard.writeText) {
        await navigator.clipboard.writeText(code)
      } else {
        const textarea = document.createElement('textarea')
        textarea.value = code
        textarea.style.position = 'fixed'
        textarea.style.opacity = '0'
        document.body.appendChild(textarea)
        textarea.select()
        document.execCommand('copy')
        document.body.removeChild(textarea)
      }

      setCopied(true)
      if (copyTimeoutRef.current) {
        clearTimeout(copyTimeoutRef.current)
      }
      copyTimeoutRef.current = setTimeout(() => setCopied(false), 1500)
    } catch {
      // Silently ignore copy failures
    }
  }

  const baseButtonClass =
    'inline-flex items-center gap-1 rounded-full border px-2.5 py-1 text-[0.7rem] font-medium text-accent shadow-sm transition-all duration-150'
  const buttonVariantClass = copied
    ? 'border-accent/90 bg-accent/20 hover:bg-accent/25 hover:shadow-[0_6px_20px_rgba(0,0,0,0.45)]'
    : 'border-accent/80 bg-base-100/5 hover:-translate-y-[1px] hover:bg-accent/10 hover:shadow-[0_6px_18px_rgba(0,0,0,0.4)] active:translate-y-0 active:shadow-none'

  return (
    <div className="group my-6 overflow-hidden rounded-xl border border-base-300/60 bg-base-300/30 bg-gradient-to-b from-base-300/60 via-base-300/20 to-base-100/10 shadow-[0_18px_60px_rgba(0,0,0,0.4)] backdrop-blur transition-all duration-150 group-hover:border-accent/80 group-hover:shadow-[0_20px_60px_rgba(0,0,0,0.55)] group-focus-within:border-accent/80 group-focus-within:shadow-[0_20px_60px_rgba(0,0,0,0.55)]">
      <div className="flex items-center justify-between gap-3 border-b border-base-300/60 bg-base-300/60 px-4 py-2 text-xs text-base-content/80">
        <div className="inline-flex items-center gap-2">
          <span className={`${baseLabelClass} ${labelVariantClass}`}>{label}</span>
        </div>
        <button type="button" onClick={handleCopy} className={`${baseButtonClass} ${buttonVariantClass}`}>
          <svg
            className="h-3.5 w-3.5"
            viewBox="0 0 24 24"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
          >
            <rect
              x="9"
              y="9"
              width="11"
              height="11"
              rx="2"
              stroke="currentColor"
              strokeWidth="1.6"
            />
            <rect
              x="4"
              y="4"
              width="11"
              height="11"
              rx="2"
              stroke="currentColor"
              strokeWidth="1.6"
              opacity="0.6"
            />
          </svg>
          <span>{copied ? 'Copied!' : 'Copy'}</span>
        </button>
      </div>

      <div className="max-h-[32rem] overflow-auto px-4 py-3">
        <pre className={`language-${language} text-sm leading-relaxed`}>
          <code className={`language-${language}`}>{code}</code>
        </pre>
      </div>
    </div>
  )
}
