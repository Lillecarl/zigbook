import Navbar from '@/components/Navbar'
import Footer from '@/components/Footer'
import { getAllChapters } from '@/lib/xml-parser'

export const metadata = {
  title: 'Contribute to Zigbook',
}

export default async function ContributePage() {
  const chapters = await getAllChapters()

  return (
    <div className="min-h-screen bg-base-200">
      <Navbar chapters={chapters} />

      <main className="px-4 sm:px-6 lg:px-10 py-8 lg:py-12">
        <div className="mx-auto w-full max-w-3xl lg:max-w-4xl">
          <section className="rounded-2xl border border-base-300/40 bg-base-100/80 px-6 py-8 sm:px-10 sm:py-10 shadow-[0_18px_50px_rgba(0,0,0,0.35)] backdrop-blur-md">
            <div className="mb-4 inline-flex items-center gap-2 rounded-full border border-accent/50 bg-base-100/60 px-3 py-1 text-xs font-medium text-accent">
              <span className="h-1.5 w-1.5 rounded-full bg-accent" />
              <span>Open source · Community-powered</span>
            </div>

            <h1 className="text-3xl sm:text-4xl font-bold tracking-tight text-base-content mb-4">
              Contribute to Zigbook
            </h1>

            <p className="text-sm sm:text-base text-base-content/80 mb-8 max-w-2xl">
              Zigbook is an independent, community-backed guide to the Zig programming language.
              Thoughtful contributions—whether small fixes or deep improvements—help make it better for
              everyone.
            </p>

            <article className="prose-zigbook space-y-8">
              <section>
                <h2 className="prose-heading mb-3">Why contribute</h2>
                <p>
                  Zig is evolving quickly, and so are the ways we teach and learn it. Contributions help
                  keep examples current, refine explanations, and surface perspectives from real Zig users
                  building real projects.
                </p>
              </section>

              <section>
                <h2 className="prose-heading mb-3">Ways to contribute</h2>
                <ul>
                  <li>Fix typos, broken links, or formatting issues in existing chapters.</li>
                  <li>Suggest clearer explanations for tricky concepts or edge cases.</li>
                  <li>Add small, focused examples or exercises that reinforce the text.</li>
                  <li>Report bugs or confusing behavior in sample code.</li>
                  <li>Propose improvements to the Zigbook site UI and developer experience.</li>
                </ul>
              </section>

              <section>
                <h2 className="prose-heading mb-3">How to contribute</h2>
                <p>
                  Contributions happen through GitHub. You can start small by opening an issue, or dive in
                  with a pull request if you already have a concrete change in mind.
                </p>
                <div className="mt-4 flex flex-wrap gap-3">
                  <a
                    href="https://github.com/zigbook/zigbook/issues/new/choose"
                    className="btn btn-sm sm:btn-md btn-accent"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    Open an issue on GitHub
                  </a>
                  <a
                    href="https://github.com/zigbook/zigbook/pulls"
                    className="btn btn-sm sm:btn-md btn-ghost border-base-300/70"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    Open a pull request
                  </a>
                </div>
              </section>

              <section>
                <h2 className="prose-heading mb-3">Content standards</h2>
                <div className="alert alert-info rounded-xl border border-base-300/60 shadow-sm">
                  <svg
                    className="h-5 w-5 flex-shrink-0"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                  <div className="text-sm leading-relaxed">
                    <p className="font-semibold mb-1">Human-written chapters only</p>
                    <p>
                      Zigbook&apos;s chapter text is written and edited by humans. While UI code and tooling
                      around the book may use automation, <strong>AI-generated chapter content is not
                        accepted</strong>.
                    </p>
                  </div>
                </div>
                <p>
                  When proposing edits, aim to preserve the existing voice: concrete, practical, and
                  slightly opinionated. Clear explanations, well-documented code, and good tests are always
                  welcome.
                </p>
              </section>

              <section>
                <h2 className="prose-heading mb-3">Community & support</h2>
                <p>
                  Zigbook lives alongside the broader Zig community. If you have language questions,
                  performance puzzles, or want to share a project, you might also enjoy these spaces:
                </p>
                <ul>
                  <li>
                    <a href="https://forums.zigbook.net" target="_blank" rel="noopener noreferrer">
                      Ziglang Forums
                    </a>{' '}
                    – community forum for Zig discussions.
                  </li>
                  <li>
                    <a href="https://forums.zigbook.net/category/12/deep-dives" target="_blank" rel="noopener noreferrer">
                      Zig compiler discussions
                    </a>{' '}
                    – design notes, proposals, and deep dives.
                  </li>
                  <li>
                    <a href="https://ziglang.org/learn/" target="_blank" rel="noopener noreferrer">
                      ziglang.org/learn
                    </a>{' '}
                    – official learning resources.
                  </li>
                </ul>
                <p>
                  If you&apos;re not sure whether an idea fits Zigbook, open an issue and start a
                  conversation. Early feedback is encouraged.
                </p>
              </section>
            </article>
          </section>
        </div>
      </main>

      <Footer />
    </div>
  )
}
