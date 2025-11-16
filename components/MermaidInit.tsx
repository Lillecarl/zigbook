'use client'

import { useEffect } from 'react'

export default function MermaidInit() {
  useEffect(() => {
    // Load mermaid script if not already loaded
    if (typeof window !== 'undefined' && !(window as any).mermaid) {
      const script = document.createElement('script')
      script.src = 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js'
      script.async = true
      script.onload = () => {
        const mermaid = (window as any).mermaid
        if (mermaid) {
          mermaid.initialize({ 
            startOnLoad: true,
            theme: 'neutral',
            securityLevel: 'loose',
          })
          // Re-render any mermaid diagrams on the page
          mermaid.contentLoaded()
        }
      }
      document.head.appendChild(script)
    } else {
      // Mermaid already loaded, just reinitialize
      const mermaid = (window as any).mermaid
      if (mermaid) {
        mermaid.contentLoaded()
      }
    }
  }, [])

  return null
}
