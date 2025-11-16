import type { ReactNode } from 'react'
import { getAllChapters } from '@/lib/xml-parser'
import CommandPaletteClient from './CommandPaletteClient'

export default async function CommandPaletteProvider({
  children,
}: {
  children: ReactNode
}) {
  const chapters = await getAllChapters()

  return <CommandPaletteClient chapters={chapters}>{children}</CommandPaletteClient>
}
