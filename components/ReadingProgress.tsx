'use client'

import { useEffect, useState } from 'react'

interface ReadingProgressProps {
  targetId: string
}

export default function ReadingProgress({ targetId }: ReadingProgressProps) {
  const [progress, setProgress] = useState(0)

  useEffect(() => {
    const target = document.getElementById(targetId)
    if (!target) return

    let ticking = false

    const updateProgress = () => {
      const rect = target.getBoundingClientRect()
      const viewportHeight = window.innerHeight || document.documentElement.clientHeight
      const totalScrollable = rect.height - viewportHeight

      if (totalScrollable <= 0) {
        // Short content: show as complete once the title has reached the top
        setProgress(rect.top <= 0 ? 1 : 0)
        return
      }

      const distance = Math.min(Math.max(-rect.top, 0), totalScrollable)
      const ratio = distance / totalScrollable
      setProgress(Number.isFinite(ratio) ? ratio : 0)
    }

    const handleScroll = () => {
      if (!ticking) {
        window.requestAnimationFrame(() => {
          updateProgress()
          ticking = false
        })
        ticking = true
      }
    }

    updateProgress()
    window.addEventListener('scroll', handleScroll, { passive: true })
    window.addEventListener('resize', updateProgress)

    return () => {
      window.removeEventListener('scroll', handleScroll)
      window.removeEventListener('resize', updateProgress)
    }
  }, [targetId])

  const clamped = Math.min(Math.max(progress, 0), 1)

  return (
    <div className="sticky top-[4rem] z-40 bg-transparent">
      <div className="mx-auto w-full max-w-5xl px-4 lg:px-10">
        <div className="h-1.5 rounded-full bg-base-300/60 overflow-hidden">
          <div
            className="h-full rounded-full bg-accent transition-[width] duration-150 ease-out"
            style={{ width: `${clamped * 100}%` }}
          />
        </div>
      </div>
    </div>
  )
}
