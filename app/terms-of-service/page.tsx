import Navbar from '@/components/Navbar'
import Footer from '@/components/Footer'
import { getAllChapters } from '@/lib/xml-parser'

export const metadata = {
  title: 'Terms of Service',
  description: 'Terms of service for zigbook.net and forums.zigbook.net',
}

export default async function TermsOfServicePage() {
  const chapters = await getAllChapters()

  return (
    <div className="flex min-h-screen flex-col bg-base-200">
      <Navbar chapters={chapters} />

      <main className="flex-1 px-4 py-8 sm:px-6 lg:px-10 lg:py-12">
        <article className="prose-zigbook mx-auto w-full max-w-4xl">
          <div className="rounded-2xl border border-base-300/40 bg-base-100/80 px-6 py-8 shadow-[0_18px_50px_rgba(0,0,0,0.35)] backdrop-blur-md sm:px-10 sm:py-10">
            {/* Header */}
            <div className="mb-8 space-y-3">
              <div className="inline-flex items-center gap-2 rounded-full border border-warning/50 bg-warning/10 px-3 py-1 text-xs font-medium text-warning">
                <svg
                  className="h-4 w-4"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                  />
                </svg>
                <span>Legal Document</span>
              </div>
              <h1 className="text-3xl font-bold tracking-tight text-base-content sm:text-4xl">
                Terms of Service
              </h1>
              <p className="text-sm text-base-content/60">
                Last Updated: November 20, 2025
              </p>
            </div>

            {/* Introduction */}
            <div className="space-y-6 text-base leading-relaxed text-base-content">
              <p>
                These Terms of Service (&ldquo;Terms&rdquo;) govern your access to and use of
                zigbook.net, forums.zigbook.net, and any related services (collectively, the
                &ldquo;Services&rdquo;). By accessing or using the Services, you agree to be bound
                by these Terms. If you do not agree, you must not use the Services.
              </p>
              <p>
                Both sites are community-owned and operated via their respective public Git
                repositories. By participating in or contributing to these repositories, you also
                agree to any contribution guidelines or licenses included within them.
              </p>

              {/* Section 1 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">1. Eligibility</h2>
                <p>
                  You must be at least 13 years old, or the minimum age required under your local
                  law, to use the Services. By using the Services, you represent that you meet this
                  requirement.
                </p>
              </section>

              {/* Section 2 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">
                  2. Community-Owned Nature of the Services
                </h2>
                <p>
                  The Services are maintained, developed, and governed by the community through open
                  and publicly accessible repositories. By engaging with the Services you
                  acknowledge:
                </p>
                <ol className="ml-6 list-decimal space-y-2">
                  <li>
                    Content, features, and policies may evolve over time through community
                    contributions.
                  </li>
                  <li>
                    No single individual or organization guarantees continued availability,
                    stability, or operation of the Services.
                  </li>
                  <li>
                    Governance decisions may be made through community processes defined in the
                    repositories.
                  </li>
                </ol>
              </section>

              {/* Section 3 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">3. User Accounts</h2>
                <p>Some features may require creating an account.</p>
                <p className="mt-4">You agree to:</p>
                <ul className="ml-6 list-disc space-y-2">
                  <li>Provide accurate information.</li>
                  <li>Maintain the security of your credentials.</li>
                  <li>Be responsible for all activity under your account.</li>
                </ul>
                <p className="mt-4">
                  Accounts may be suspended or terminated if you violate these Terms or community
                  policies.
                </p>
              </section>

              {/* Section 4 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">4. User Content</h2>
                <p>
                  &ldquo;User Content&rdquo; refers to any text, code, media, or other materials
                  you submit to the Services or the associated repositories.
                </p>

                <div className="ml-4 space-y-4">
                  <div>
                    <h3 className="text-lg font-semibold text-base-content">4.1 Ownership</h3>
                    <p className="mt-2">
                      You retain ownership of your User Content, subject to the licenses you grant
                      under these Terms and any repository-specific licenses.
                    </p>
                  </div>

                  <div>
                    <h3 className="text-lg font-semibold text-base-content">
                      4.2 License to the Services
                    </h3>
                    <p className="mt-2">
                      By submitting User Content, you grant the operators of the Services and the
                      community a non-exclusive, worldwide, royalty-free license to host, reproduce,
                      distribute, modify, adapt, display, and create derivative works as necessary
                      for the operation, improvement, and preservation of the Services and their
                      repositories.
                    </p>
                  </div>

                  <div>
                    <h3 className="text-lg font-semibold text-base-content">
                      4.3 Responsibilities
                    </h3>
                    <p className="mt-2">
                      You are solely responsible for your User Content. You agree that you will not
                      submit content that:
                    </p>
                    <ul className="ml-6 mt-2 list-disc space-y-2">
                      <li>Violates any law or regulation.</li>
                      <li>Infringes on intellectual property rights.</li>
                      <li>Contains harassing, hateful, or abusive material.</li>
                      <li>Constitutes spam or unauthorized advertising.</li>
                      <li>Contains malicious code.</li>
                    </ul>
                    <p className="mt-4">
                      The community may moderate, remove, or restrict content at its discretion.
                    </p>
                  </div>
                </div>
              </section>

              {/* Section 5 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">
                  5. Open Source and Repository Contributions
                </h2>
                <p>
                  The Services rely on publicly maintained Git repositories. By contributing to
                  these repositories, you agree to any contribution policies, licenses, or
                  Contributor License Agreements (CLAs), if applicable.
                </p>
                <p className="mt-4">
                  Repository maintainers may accept, modify, or reject contributions at their
                  discretion.
                </p>
              </section>

              {/* Section 6 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">
                  6. Prohibited Activities
                </h2>
                <p>You agree not to:</p>
                <ul className="ml-6 list-disc space-y-2">
                  <li>Interfere with or disrupt the Services.</li>
                  <li>Attempt unauthorized access to servers, accounts, or data.</li>
                  <li>Use the Services for unlawful purposes.</li>
                  <li>Harvest user data without consent.</li>
                  <li>Impersonate others or misrepresent your affiliation.</li>
                </ul>
              </section>

              {/* Section 7 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">
                  7. Intellectual Property
                </h2>
                <p>
                  The zigbook.net and forums.zigbook.net names, branding, and logos may be protected
                  by trademark or other rights. You may not use them without permission except as
                  allowed by applicable law.
                </p>
                <p className="mt-4">
                  Software, documentation, and content provided by the Services may be licensed
                  under open-source or community licenses. You agree to comply with those license
                  terms.
                </p>
              </section>

              {/* Section 8 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">
                  8. Third-Party Links and Content
                </h2>
                <p>
                  The Services may contain links to third-party websites. These links are provided
                  &ldquo;as-is.&rdquo; The Services are not responsible for third-party content,
                  policies, or actions.
                </p>
              </section>

              {/* Section 9 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">9. Disclaimers</h2>
                <p>To the fullest extent permitted by law:</p>
                <ul className="ml-6 list-disc space-y-2">
                  <li>
                    The Services are provided &ldquo;as is&rdquo; and &ldquo;as available.&rdquo;
                  </li>
                  <li>
                    No warranties, express or implied, are made regarding availability, security,
                    accuracy, or reliability.
                  </li>
                  <li>
                    The community and maintainers disclaim all liability for any loss, damage, or
                    data breach arising from use of the Services.
                  </li>
                </ul>
              </section>

              {/* Section 10 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">
                  10. Limitation of Liability
                </h2>
                <p>
                  To the maximum extent allowed by law, the Services, their maintainers,
                  contributors, and affiliated individuals or organizations shall not be liable for:
                </p>
                <ul className="ml-6 list-disc space-y-2">
                  <li>Indirect, incidental, special, consequential, or punitive damages.</li>
                  <li>Loss of data, profits, or business opportunities.</li>
                  <li>
                    Damages resulting from third-party conduct or unauthorized access.
                  </li>
                </ul>
                <p className="mt-4 font-medium">
                  Your sole remedy for dissatisfaction with the Services is to stop using them.
                </p>
              </section>

              {/* Section 11 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">11. Indemnification</h2>
                <p>
                  You agree to indemnify and hold harmless the Services, their maintainers,
                  contributors, and community members from any claims, liabilities, damages, or
                  expenses arising from your use of the Services or violation of these Terms.
                </p>
              </section>

              {/* Section 12 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">12. Termination</h2>
                <p>
                  The Services may suspend or terminate access for any reason, including violation
                  of these Terms or community policies. You may stop using the Services at any time.
                </p>
                <p className="mt-4">
                  Termination does not affect any licenses already granted to User Content or code
                  contributions.
                </p>
              </section>

              {/* Section 13 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">
                  13. Changes to These Terms
                </h2>
                <p>
                  Because the Services evolve through community stewardship, these Terms may be
                  updated periodically. Updates will be posted prominently. Continued use of the
                  Services after changes become effective constitutes acceptance of the revised
                  Terms.
                </p>
              </section>

              {/* Section 14 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">14. Governing Law</h2>
                <p>
                  These Terms are governed by the laws of the jurisdiction selected by the primary
                  repository maintainers or, if none is specified, the jurisdiction in which the
                  user resides. Any disputes shall be resolved under that jurisdiction&apos;s
                  courts.
                </p>
              </section>

              {/* Section 15 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">15. Contact</h2>
                <p>
                  Because the Services are community-maintained, inquiries may be submitted via the
                  public repositories associated with the respective sites.
                </p>
              </section>

              {/* Footer note */}
              <div className="mt-12 rounded-xl border border-base-300/40 bg-base-200/40 px-4 py-3">
                <p className="text-sm text-base-content/70">
                  <strong>Note:</strong> This is a living document maintained by the community. For
                  the most up-to-date version and change history, please refer to the{' '}
                  <a
                    href="https://github.com/zigbook/zigbook"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-accent hover:underline"
                  >
                    Zigbook GitHub repository
                  </a>
                  .
                </p>
              </div>
            </div>
          </div>
        </article>
      </main>

      <Footer />
    </div>
  )
}
