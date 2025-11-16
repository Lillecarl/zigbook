import type { Metadata, Viewport } from 'next'
import './globals.css'
import CommandPaletteProvider from '@/components/CommandPaletteProvider'

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 5,
  userScalable: true,
  themeColor: '#0f172a',
}

export const metadata: Metadata = {
  metadataBase: new URL('https://zigbook.net'),
  title: {
    default: 'Zigbook – Learn the Zig Programming Language',
    template: '%s – Zigbook',
  },
  description:
    'Zigbook is a comprehensive, open-source guide to the Zig programming language, packed with hands-on chapters, projects, and real-world examples.',
  openGraph: {
    title: 'Zigbook – Learn the Zig Programming Language',
    description:
      'Zigbook is a comprehensive, open-source guide to the Zig programming language, packed with hands-on chapters, projects, and real-world examples.',
    url: 'https://zigbook.net',
    siteName: 'Zigbook',
    images: [
      {
        url: '/og-zigbook.webp',
        width: 1200,
        height: 630,
        alt: 'Zigbook – Learn the Zig Programming Language',
      },
    ],
    locale: 'en_US',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Zigbook – Learn the Zig Programming Language',
    description:
      'Zigbook is a comprehensive, open-source guide to the Zig programming language, packed with hands-on chapters, projects, and real-world examples.',
    images: ['/og-zigbook.webp'],
  },
  icons: {
    icon: '/favicon.svg',
    shortcut: '/favicon.svg',
    apple: '/favicon.svg',
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" className="w-full">
      <body className="w-full min-w-full overflow-x-hidden">
        <CommandPaletteProvider>{children}</CommandPaletteProvider>
      </body>
    </html>
  )
}
