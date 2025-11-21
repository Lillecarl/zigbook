import Navbar from '@/components/Navbar'
import Footer from '@/components/Footer'
import ZigPlayground, { type PlaygroundFile } from '@/components/ZigPlayground'
import { getAllChapters } from '@/lib/xml-parser'
import fs from 'node:fs/promises'
import path from 'node:path'

export const metadata = {
    title: 'Zigbook Playground',
    description:
        'Polyglot Zig experimentation space with browser-based compilation, ZLS diagnostics, and a stateless single-file workspace built for Zigbook readers.',
}

const warningPoints = [
    'The Zig toolchain boots entirely in-browser using an experimental WASM build that still misses upstream optimizations.',
    'Compiler crashes, stack overflows, or hanging workers are known issues—refreshing typically clears the slate.',
    'Runtime assets download on demand. Slow or flaky networks may cause warmups to fail the first time around.',
    'Output, logs, and editor state are ephemeral. Export the generated WASM if you need a durable artifact.',
]

export default async function PlaygroundPage() {
    const chapters = await getAllChapters()

    const templatePath = path.join(process.cwd(), 'public', 'templates', 'main.zig')
    let templateContent = ''
    try {
        templateContent = await fs.readFile(templatePath, 'utf-8')
    } catch (error) {
        console.error('Failed to read template file:', error)
        // Fallback if file read fails
        templateContent = `//! File: main.zig
//! This example shows how to use \`std.debug.print\` for stderr output
//! and \`std.fs.File.stdout().writeAll\` for stdout output.

/// Imports the Zig standard library, providing access to core functionality
/// This import is typically required in most Zig programs to access fundamental utilities.
const std = @import("std");

/// A constant alias for \`std.debug.print\`, used for printing debug messages to stderr.
const print = std.debug.print;

/// The main entry point of the program.
pub fn main() !void {
    print("Hello World!", .{});
    try std.fs.File.stdout().writeAll("Welcome to Zigbook!\\n");
}

// Don't forget to join the Zig community!
// Visit https://forums.zigbook.net for more information.
`
    }

    const starterFiles: PlaygroundFile[] = [
        {
            id: 'main-zig',
            name: 'main.zig',
            path: 'src/main.zig',
            contents: templateContent,
        }
    ]

    return (
        <div className="min-h-screen bg-gradient-to-b from-base-200 via-base-200/80 to-base-100">
            <Navbar chapters={chapters} />

            <main className="px-4 py-10 sm:px-6 lg:px-10 lg:py-16">
                <div className="mx-auto w-full max-w-6xl space-y-12 lg:space-y-16">
                    <section
                        role="alert"
                        className="mx-auto w-full max-w-4xl overflow-hidden rounded-3xl border border-error/40 bg-error/15 px-6 py-6 text-base-content shadow-[0_18px_60px_rgba(0,0,0,0.3)] sm:px-8"
                    >
                        <div className="space-y-4">
                            <div className="inline-flex items-center gap-2 rounded-full border border-error/30 bg-error/10 px-3 py-1 text-[0.6rem] font-semibold uppercase tracking-[0.35em] text-error">
                                <span className="h-1.5 w-1.5 rounded-full bg-error" />
                                <span>Before you dive in</span>
                            </div>
                            <ul className="space-y-2 text-sm text-base-content/85">
                                {warningPoints.map((note) => (
                                    <li key={note} className="flex items-start gap-3">
                                        <span className="mt-1 inline-flex h-2.5 w-2.5 flex-shrink-0 rounded-full bg-error/80 shadow-[0_0_10px_hsl(var(--er)/0.6)]" />
                                        <span>{note}</span>
                                    </li>
                                ))}
                            </ul>
                        </div>
                    </section>

                    <section
                        id="workspace"
                        className="relative rounded-[2.25rem] border border-base-300/50 bg-base-100/90 px-4 py-6 sm:px-6 sm:py-8 lg:px-10 lg:py-12 shadow-[0_25px_90px_rgba(0,0,0,0.35)] backdrop-blur"
                    >
                        <div className="mb-8 space-y-6">
                            <div className="inline-flex items-center gap-2 rounded-full border border-primary/40 bg-primary/10 px-3 py-1 text-[0.65rem] font-semibold uppercase tracking-[0.3em] text-primary">
                                <span className="h-1.5 w-1.5 rounded-full bg-primary" /> Workspace
                            </div>
                            <div className="grid gap-4 sm:grid-cols-2">
                                <article className="rounded-2xl border border-error/30 bg-error/10 p-4 text-base-content shadow-[0_12px_30px_rgba(0,0,0,0.18)]">
                                    <p className="text-xs uppercase tracking-[0.3em] text-error/70">Status</p>
                                    <p className="mt-2 text-2xl font-semibold text-base-content">High-voltage beta</p>
                                    <p className="text-sm text-base-content/70">Expect breaking changes, missing std symbols, and compiler panics.</p>
                                </article>
                                <article className="rounded-2xl border border-warning/40 bg-warning/10 p-4 text-base-content shadow-[0_12px_30px_rgba(0,0,0,0.18)]">
                                    <p className="text-xs uppercase tracking-[0.3em] text-warning/70">What to do</p>
                                    <p className="mt-2 text-2xl font-semibold text-base-content">Refresh responsibly</p>
                                    <p className="text-sm text-base-content/70">Keep exports handy and share repros via GitHub issues when things explode.</p>
                                </article>
                            </div>
                        </div>

                        <ZigPlayground initialFiles={starterFiles} />
                    </section>
                </div>
            </main>

            <Footer />
        </div>
    )
}
