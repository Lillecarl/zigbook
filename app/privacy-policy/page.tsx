import Navbar from '@/components/Navbar'
import Footer from '@/components/Footer'
import { getAllChapters } from '@/lib/xml-parser'

export const metadata = {
  title: 'Privacy Policy',
  description: 'Privacy policy for zigbook.net and forums.zigbook.net',
}

export default async function PrivacyPolicyPage() {
  const chapters = await getAllChapters()

  return (
    <div className="flex min-h-screen flex-col bg-base-200">
      <Navbar chapters={chapters} />

      <main className="flex-1 px-4 py-8 sm:px-6 lg:px-10 lg:py-12">
        <article className="prose-zigbook mx-auto w-full max-w-4xl">
          <div className="rounded-2xl border border-base-300/40 bg-base-100/80 px-6 py-8 shadow-[0_18px_50px_rgba(0,0,0,0.35)] backdrop-blur-md sm:px-10 sm:py-10">
            {/* Header */}
            <div className="mb-8 space-y-3">
              <div className="inline-flex items-center gap-2 rounded-full border border-info/50 bg-info/10 px-3 py-1 text-xs font-medium text-info">
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
                    d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                  />
                </svg>
                <span>Legal Document</span>
              </div>
              <h1 className="text-3xl font-bold tracking-tight text-base-content sm:text-4xl">
                Privacy Policy
              </h1>
              <p className="text-sm text-base-content/60">
                Last Updated: November 20, 2025
              </p>
            </div>

            {/* Introduction */}
            <div className="space-y-6 text-base leading-relaxed text-base-content">
              <p>
                This Privacy Policy explains how zigbook.net, forums.zigbook.net, and their
                associated open-source repositories (&ldquo;we,&rdquo; &ldquo;us,&rdquo; or
                &ldquo;the Services&rdquo;) collect, use, and protect information. By using the
                Services, you agree to the practices described here.
              </p>
              <p>
                The Services are community-operated and maintained via public Git repositories. As
                a result, certain operational details and data flows may be visible publicly.
              </p>

              {/* Section 1 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">
                  1. Information We Collect
                </h2>
                <p>
                  We collect the minimum information necessary to operate the Services. The
                  information may include:
                </p>

                <div className="ml-4 space-y-4">
                  <div>
                    <h3 className="text-lg font-semibold text-base-content">
                      1.1 Information You Provide
                    </h3>
                    <ul className="ml-6 mt-2 list-disc space-y-2">
                      <li>
                        <strong>Account information:</strong> When creating an account, you may
                        provide a username, email address, password, profile details, or other
                        optional information.
                      </li>
                      <li>
                        <strong>User contributions:</strong> Posts, comments, messages, uploaded
                        files, and other content you submit.
                      </li>
                      <li>
                        <strong>Repository contributions:</strong> If you contribute to the public
                        repositories (e.g., via Git commits), your contributions and associated
                        metadata (such as your Git username and commit history) may be publicly
                        visible.
                      </li>
                    </ul>
                  </div>

                  <div>
                    <h3 className="text-lg font-semibold text-base-content">
                      1.2 Automatically Collected Information
                    </h3>
                    <p className="mt-2">The Services may automatically collect:</p>
                    <ul className="ml-6 mt-2 list-disc space-y-2">
                      <li>
                        <strong>Server logs:</strong> IP addresses, browser type, operating system,
                        referring URLs, timestamps, and general usage data.
                      </li>
                      <li>
                        <strong>Cookies or local storage:</strong> Used to maintain sessions, store
                        preferences, or authenticate users.
                      </li>
                      <li>
                        <strong>Security data:</strong> Information used to detect abuse,
                        unauthorized access, or malicious activity.
                      </li>
                    </ul>
                  </div>

                  <div>
                    <h3 className="text-lg font-semibold text-base-content">
                      1.3 Optional Analytics
                    </h3>
                    <p className="mt-2">
                      If analytics tools are enabled, they may collect anonymized usage statistics.
                      Any analytics will be documented transparently in the public repositories.
                    </p>
                  </div>
                </div>
              </section>

              {/* Section 2 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">
                  2. How We Use Information
                </h2>
                <p>We use collected information to:</p>
                <ul className="ml-6 list-disc space-y-2">
                  <li>Operate and maintain the Services.</li>
                  <li>Authenticate users and manage accounts.</li>
                  <li>Moderate content and enforce community policies.</li>
                  <li>Improve performance, security, and reliability.</li>
                  <li>Enable community governance and maintain the public repositories.</li>
                  <li>Comply with legal obligations when applicable.</li>
                </ul>
                <p className="mt-4 font-medium">
                  We do not sell or rent your personal information.
                </p>
              </section>

              {/* Section 3 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">
                  3. Public Nature of the Services
                </h2>
                <p>
                  Because the Services are community-owned and built on publicly accessible
                  repositories:
                </p>
                <ul className="ml-6 list-disc space-y-2">
                  <li>
                    Contributions to the repositories (issues, pull requests, comments, commits) are
                    publicly visible.
                  </li>
                  <li>
                    Some Service features, such as public user profiles or posted content, may be
                    publicly accessible.
                  </li>
                  <li>
                    Moderation actions, site changes, or governance decisions may be recorded
                    publicly.
                  </li>
                </ul>
                <p className="mt-4 font-medium text-warning">
                  You should not submit sensitive personal information that you do not wish to be
                  public.
                </p>
              </section>

              {/* Section 4 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">
                  4. Cookies and Tracking Technologies
                </h2>
                <p>The Services may use cookies or similar technologies to:</p>
                <ul className="ml-6 list-disc space-y-2">
                  <li>Maintain login sessions.</li>
                  <li>Store user preferences.</li>
                  <li>Enhance usability.</li>
                </ul>
                <p className="mt-4">
                  No third-party tracking cookies are intentionally used unless specified in
                  repository documentation.
                </p>
                <p className="mt-4">
                  You may disable cookies in your browser, but some features may not function
                  properly.
                </p>
              </section>

              {/* Section 5 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">5. Data Sharing</h2>
                <p>We may share information only in limited circumstances:</p>

                <div className="ml-4 space-y-4">
                  <div>
                    <h3 className="text-lg font-semibold text-base-content">
                      5.1 With the Community
                    </h3>
                    <p className="mt-2">
                      Due to the open and collaborative nature of the project, relevant information
                      may be shared with community maintainers to operate or improve the Services.
                    </p>
                  </div>

                  <div>
                    <h3 className="text-lg font-semibold text-base-content">
                      5.2 With Service Providers
                    </h3>
                    <p className="mt-2">
                      If infrastructure providers (e.g., hosting, email services, content delivery
                      networks) are used, they may process data on our behalf under their own
                      policies.
                    </p>
                  </div>

                  <div>
                    <h3 className="text-lg font-semibold text-base-content">
                      5.3 For Legal Compliance
                    </h3>
                    <p className="mt-2">
                      We may disclose information when required by law, regulation, or a valid legal
                      process.
                    </p>
                  </div>
                </div>
              </section>

              {/* Section 6 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">6. Data Security</h2>
                <p>
                  We take reasonable measures to protect information from unauthorized access, loss,
                  or misuse. Because the Services are community-maintained and open-source, absolute
                  security cannot be guaranteed.
                </p>
                <p className="mt-4">
                  You are responsible for using strong passwords and securing your account
                  credentials.
                </p>
              </section>

              {/* Section 7 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">7. Data Retention</h2>
                <p>
                  We retain information as long as necessary to operate the Services, maintain
                  community records, or comply with legal obligations.
                </p>
                <p className="mt-4">
                  User-generated content and repository contributions may remain publicly available
                  indefinitely as part of the permanent project history.
                </p>
              </section>

              {/* Section 8 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">8. Your Choices</h2>
                <ul className="ml-6 list-disc space-y-2">
                  <li>
                    <strong>Access and update:</strong> You may update your account information
                    through your profile settings where available.
                  </li>
                  <li>
                    <strong>Deletion:</strong> You may request deletion of your account. Certain
                    data—such as published posts or open-source contributions—may remain due to their
                    public and archival nature.
                  </li>
                  <li>
                    <strong>Cookies:</strong> You may disable cookies in your browser.
                  </li>
                </ul>
              </section>

              {/* Section 9 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">
                  9. Third-Party Links
                </h2>
                <p>
                  The Services may contain links to external sites. We are not responsible for their
                  privacy practices or content.
                </p>
              </section>

              {/* Section 10 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">
                  10. Children&apos;s Privacy
                </h2>
                <p>
                  The Services are not intended for children under 13, or the minimum age required
                  under local law. We do not knowingly collect personal data from children.
                </p>
              </section>

              {/* Section 11 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">
                  11. Changes to This Privacy Policy
                </h2>
                <p>
                  This Privacy Policy may be updated periodically. Changes will be posted clearly.
                  Continued use of the Services constitutes acceptance of the revised Policy.
                </p>
              </section>

              {/* Section 12 */}
              <section className="mt-8 space-y-4">
                <h2 className="text-2xl font-semibold text-base-content">12. Contact</h2>
                <p>
                  Because the Services are community-governed, privacy-related questions or concerns
                  may be submitted through the public repositories associated with the sites.
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
