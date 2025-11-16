'use client'

import Link from 'next/link'

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  return (
    <div className="min-h-screen bg-base-200 flex items-center justify-center px-4 py-10">
      <section className="w-full max-w-xl rounded-2xl border border-base-300/40 bg-base-100/80 px-6 py-8 sm:px-10 sm:py-10 shadow-[0_18px_50px_rgba(0,0,0,0.35)] backdrop-blur-md">
        <div className="mb-4 inline-flex items-center gap-2 rounded-full border border-warning/50 bg-warning/10 px-3 py-1 text-xs font-medium text-warning">
          <span className="h-1.5 w-1.5 rounded-full bg-warning" />
          <span>Something went wrong</span>
        </div>
        <h1 className="mb-3 text-2xl sm:text-3xl font-bold tracking-tight text-base-content">
          We hit an unexpected error.
        </h1>
        <p className="mb-6 text-sm sm:text-base text-base-content/80">
          You can try the action again, or return to the Zigbook home page. If this keeps happening,
          consider reporting it on GitHub.
        </p>

        <div className="flex flex-wrap gap-3 mb-4">
          <button
            type="button"
            onClick={reset}
            className="btn btn-sm sm:btn-md btn-warning text-warning-content"
          >
            Retry
          </button>
          <Link href="/" className="btn btn-sm sm:btn-md btn-ghost border-base-300/70">
            Back home
          </Link>
        </div>

        {process.env.NODE_ENV !== 'production' && error?.message && (
          <p className="mt-2 text-xs text-base-content/60 break-words">
            <span className="font-semibold">Debug info:</span> {error.message}
          </p>
        )}
      </section>
    </div>
  )
}
