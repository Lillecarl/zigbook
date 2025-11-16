import { getAllChapters } from '@/lib/xml-parser'
import SidebarClient from './SidebarClient'

interface SidebarProps {
  currentChapterId?: string
}

export default async function Sidebar({ currentChapterId }: SidebarProps) {
  const chapters = await getAllChapters()

  return <SidebarClient chapters={chapters} currentChapterId={currentChapterId} />
}

