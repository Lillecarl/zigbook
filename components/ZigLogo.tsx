'use client'

import { useEffect, useState } from 'react'
import Image from 'next/image'

export default function ZigLogo() {
  const [theme, setTheme] = useState('business')

  useEffect(() => {
    // Get initial theme
    const savedTheme = localStorage.getItem('theme') || 'business'
    setTheme(savedTheme)

    // Listen for theme changes
    const observer = new MutationObserver(() => {
      const currentTheme = document.documentElement.getAttribute('data-theme')
      if (currentTheme) {
        setTheme(currentTheme)
      }
    })

    observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ['data-theme']
    })

    return () => observer.disconnect()
  }, [])

  const isDark = theme === 'business'

  return (
    <div className="flex justify-center lg:justify-start animate-float pt-2 lg:pt-0">
      <div className="relative inline-flex items-center justify-center">
        <div className="absolute inset-0 rounded-full bg-gradient-to-b from-accent/70 via-accent/20 to-transparent blur-3xl scale-125" />
        <Image
          src={isDark ? '/assets/zig-logo-light.svg' : '/assets/zig-logo-dark.svg'}
          alt="Zig Logo"
          width={240}
          height={240}
          className="relative drop-shadow-[0_0_55px_rgba(249,115,22,0.9)] hover:drop-shadow-[0_0_80px_rgba(249,115,22,1)] transition-all duration-300"
        />
      </div>
    </div>
  )
}
