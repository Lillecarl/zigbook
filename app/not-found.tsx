import Link from 'next/link'
import Navbar from '@/components/Navbar'
import Footer from '@/components/Footer'
import { getAllChapters } from '@/lib/xml-parser'

export default async function NotFound() {
  const chapters = await getAllChapters()

  return (
    <div className="min-h-screen bg-base-200">
      <Navbar chapters={chapters} />
      <main className="flex items-center justify-center px-4 py-10">
        <section className="mx-auto w-full max-w-xl rounded-2xl border border-base-300/40 bg-base-100/80 px-6 py-8 sm:px-10 sm:py-10 shadow-[0_18px_50px_rgba(0,0,0,0.35)] backdrop-blur-md">
          <div className="mb-4 text-xs font-semibold uppercase tracking-wider text-accent/80">
            404 · Page not found
          </div>
          <h1 className="mb-3 text-3xl sm:text-4xl font-bold tracking-tight text-base-content">
            This path doesn&apos;t exist in the Zigverse.
          </h1>
          <p className="mb-8 text-sm sm:text-base text-base-content/80">
            The page you were looking for may have moved, been renamed, or never existed. You can go
            back home or jump into a chapter from the table of contents.
          </p>

          <div className="flex flex-wrap gap-3">
            <Link href="/" className="btn btn-sm sm:btn-md btn-accent">
              Back home
            </Link>
            <Link
              href="/chapters/00__zigbook_introduction"
              className="btn btn-sm sm:btn-md btn-ghost border-base-300/70"
            >
              Browse chapters
            </Link>
          </div>
        </section>
      </main>

      <Footer />
    </div>
  )
}
