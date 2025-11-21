import Link from 'next/link'

export default function Footer() {
  const currentYear = new Date().getFullYear()

  return (
    <footer className="border-t border-base-300/40 bg-base-100/60 backdrop-blur-sm">
      <div className="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
        <div className="flex flex-col items-center justify-between gap-4 sm:flex-row">
          {/* Left side - Copyright */}
          <div className="text-center text-xs text-base-content/60 sm:text-left">
            <p>© {currentYear} Zigbook. Community-owned, open source.</p>
          </div>

          {/* Right side - Links */}
          <nav className="flex flex-wrap items-center justify-center gap-4 text-xs sm:gap-6">
            <Link
              href="/privacy-policy"
              className="text-base-content/60 transition-colors hover:text-base-content"
            >
              Privacy Policy
            </Link>
            <Link
              href="/terms-of-service"
              className="text-base-content/60 transition-colors hover:text-base-content"
            >
              Terms of Service
            </Link>
            <a
              href="https://github.com/zigbook/zigbook"
              target="_blank"
              rel="noopener noreferrer"
              className="text-base-content/60 transition-colors hover:text-base-content"
            >
              GitHub
            </a>
          </nav>
        </div>
      </div>
    </footer>
  )
}
