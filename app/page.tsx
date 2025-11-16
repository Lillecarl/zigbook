import Link from 'next/link'
import AnimatedTerminal from '@/components/AnimatedTerminal'
import ThemeToggle from '@/components/ThemeToggle'
import ZigLogo from '@/components/ZigLogo'
import HeroBackground from '@/components/HeroBackground'

export default function Home() {
  return (
    <div className="min-h-screen bg-base-200 relative overflow-hidden">
      <HeroBackground />

      {/* Navbar */}
      <div className="navbar bg-base-100/80 backdrop-blur border-b border-base-300/40 relative z-20">
        <div className="flex-1">
          <a className="btn btn-ghost px-2 md:px-3 text-lg md:text-xl font-semibold tracking-tight">
            Zigbook
          </a>
        </div>
        <div className="flex-none gap-2">
          <Link
            href="/chapters/00__zigbook_introduction"
            className="btn btn-outline btn-sm md:btn-md border-accent/60 text-accent hover:border-accent hover:bg-accent/10"
          >
            Chapters
          </Link>
          <ThemeToggle />
        </div>
      </div>

      {/* Hero Section */}
      <main className="relative z-10">
        <section className="hero min-h-[calc(100vh-4rem)] lg:min-h-[calc(100vh-5rem)] py-8 lg:py-10">
          <div className="hero-content w-full max-w-6xl px-4 md:px-6 lg:px-8">
            <div className="flex w-full flex-col items-center gap-10 lg:flex-row lg:items-stretch lg:gap-16">
              {/* Text / meta column */}
              <div className="flex-1 max-w-xl text-center lg:text-left">
                <div className="space-y-6 md:space-y-8">
                  {/* Floating Zig Logo */}
                  <ZigLogo />

                  {/* Headline */}
                  <div className="space-y-4">
                    <h1 className="text-3xl sm:text-4xl lg:text-4xl font-bold leading-tight tracking-tight">
                      Learning Zig is not just about adding a language to your resume.
                    </h1>
                    <p className="text-lg sm:text-xl text-base-content/70 leading-relaxed">
                      It is about fundamentally changing how you think about software.
                    </p>
                  </div>

                  {/* Quote block */}
                  <div className="mt-2 inline-flex max-w-xl items-start gap-3 rounded-xl border border-base-300/50 bg-base-100/5 px-4 py-3 text-left shadow-sm">
                    <div className="mt-1 h-10 w-px bg-gradient-to-b from-accent/70 via-accent/20 to-transparent" />
                    <div className="space-y-1">
                      <p className="text-base sm:text-lg md:text-xl italic text-base-content/80 font-light">
                        &ldquo;You came for syntax.
                      </p>
                      <p className="text-base sm:text-lg md:text-xl italic text-accent font-medium">
                        You&apos;ll leave with a philosophy.&rdquo;
                      </p>
                    </div>
                  </div>

                  {/* Meta */}
                  <div className="pt-2 text-xs sm:text-sm text-base-content/60">
                    <p>61 chapters • Project-based • Zero AI • Written by @zigbook</p>
                  </div>
                </div>
              </div>

              {/* Terminal column */}
              <div className="flex-1 max-w-xl w-full">
                <AnimatedTerminal />
              </div>
            </div>
          </div>
        </section>
      </main>
    </div>
  )
}
