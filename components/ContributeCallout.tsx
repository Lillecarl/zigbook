import Link from 'next/link'

interface ContributeCalloutProps {
  chapterId?: string
}

export default function ContributeCallout({ chapterId }: ContributeCalloutProps) {
  const issueTitle = chapterId
    ? `Feedback for chapter ${chapterId}`
    : 'Feedback for Zigbook chapter'

  const issueUrl = `https://github.com/zigbook/zigbook/issues/new?title=${encodeURIComponent(
    issueTitle,
  )}`

  return (
    <div className="mt-10">
      <div className="flex flex-col gap-3 rounded-xl border border-base-300/60 bg-base-100/60 px-4 py-3 text-sm shadow-sm sm:flex-row sm:items-center sm:justify-between">
        <div className="flex items-start gap-3">
          <div className="mt-0.5 h-6 w-6 flex-shrink-0 rounded-full bg-base-300/80 flex items-center justify-center text-xs text-base-content/80">
            <svg
              className="h-3.5 w-3.5"
              viewBox="0 0 24 24"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M12 6V14"
                stroke="currentColor"
                strokeWidth="1.8"
                strokeLinecap="round"
              />
              <circle
                cx="12"
                cy="17"
                r="1"
                fill="currentColor"
              />
              <path
                d="M12 4C7.58172 4 4 7.58172 4 12C4 16.4183 7.58172 20 12 20C16.4183 20 20 16.4183 20 12C20 7.58172 16.4183 4 12 4Z"
                stroke="currentColor"
                strokeWidth="1.4"
              />
            </svg>
          </div>
          <div>
            <p className="font-medium text-base-content">
              Help make this chapter better.
            </p>
            <p className="text-base-content/70">
              Found a typo, rough edge, or missing explanation? Open an issue or propose a small
              improvement on GitHub.
            </p>
          </div>
        </div>
        <div className="flex flex-wrap gap-2 sm:justify-end">
          <a
            href={issueUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="btn btn-xs sm:btn-sm btn-accent"
          >
            Open issue
          </a>
          <Link
            href="https://github.com/zigbook/zigbook"
            className="btn btn-xs sm:btn-sm btn-ghost border-base-300/70"
            target="_blank"
          >
            View repository
          </Link>
        </div>
      </div>
    </div>
  )
}
