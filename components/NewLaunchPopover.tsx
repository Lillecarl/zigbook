'use client'

import Link from 'next/link'
import { useCallback, useEffect, useState } from 'react'

const POPOVER_SNOOZE_KEY = 'zigbook-newlaunch-snooze-until'
const REMIND_LATER_MS = 6 * 60 * 60 * 1000 // 6 hours
const DISMISS_MS = 30 * 24 * 60 * 60 * 1000 // 30 days

interface NewLaunchPopoverProps {
    highlightPlayground: boolean
    highlightForums: boolean
    onPlaygroundNavigate: () => void
    onForumsNavigate: () => void
}

export default function NewLaunchPopover({
    highlightPlayground,
    highlightForums,
    onPlaygroundNavigate,
    onForumsNavigate,
}: NewLaunchPopoverProps) {
    const [prefersReducedMotion, setPrefersReducedMotion] = useState(false)
    const [isMounted, setIsMounted] = useState(false)
    const [isVisible, setIsVisible] = useState(false)

    const shouldAnnounce = highlightPlayground || highlightForums

    useEffect(() => {
        if (!shouldAnnounce) {
            setIsVisible(false)
            setIsMounted(false)
            return
        }
        if (typeof window === 'undefined') return
        const snoozeUntilRaw = window.localStorage.getItem(POPOVER_SNOOZE_KEY)
        const snoozeUntil = snoozeUntilRaw ? Number(snoozeUntilRaw) : 0
        if (snoozeUntil && snoozeUntil > Date.now()) return
        const timer = window.setTimeout(() => {
            setIsMounted(true)
            window.requestAnimationFrame(() => setIsVisible(true))
        }, 1500)
        return () => window.clearTimeout(timer)
    }, [shouldAnnounce])

    useEffect(() => {
        if (typeof window === 'undefined') return
        if (!isMounted) return
        if (isVisible) return
        const timer = window.setTimeout(() => setIsMounted(false), 320)
        return () => window.clearTimeout(timer)
    }, [isMounted, isVisible])

    useEffect(() => {
        if (typeof window === 'undefined' || typeof window.matchMedia !== 'function') return
        const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)')
        const updateMotionPreference = () => setPrefersReducedMotion(mediaQuery.matches)
        updateMotionPreference()
        if (typeof mediaQuery.addEventListener === 'function') {
            mediaQuery.addEventListener('change', updateMotionPreference)
        } else if (typeof mediaQuery.addListener === 'function') {
            mediaQuery.addListener(updateMotionPreference)
        }
        return () => {
            if (typeof mediaQuery.removeEventListener === 'function') {
                mediaQuery.removeEventListener('change', updateMotionPreference)
            } else if (typeof mediaQuery.removeListener === 'function') {
                mediaQuery.removeListener(updateMotionPreference)
            }
        }
    }, [])

    const scheduleSnooze = useCallback((durationMs: number) => {
        if (typeof window === 'undefined') return
        window.localStorage.setItem(POPOVER_SNOOZE_KEY, String(Date.now() + durationMs))
    }, [])

    const dismissWithSnooze = useCallback(
        (durationMs: number) => {
            scheduleSnooze(durationMs)
            setIsVisible(false)
        },
        [scheduleSnooze],
    )

    const handleRemindLater = useCallback(() => {
        dismissWithSnooze(REMIND_LATER_MS)
    }, [dismissWithSnooze])

    const handleDismiss = useCallback(() => {
        dismissWithSnooze(DISMISS_MS)
    }, [dismissWithSnooze])

    if (!shouldAnnounce || !isMounted) {
        return null
    }

    const translationClass = prefersReducedMotion ? '' : isVisible ? 'translate-y-0' : 'translate-y-4'
    const opacityClass = isVisible ? 'opacity-100' : 'opacity-0'
    const pointerClass = isVisible ? '' : 'pointer-events-none'
    const pulseClass = prefersReducedMotion ? '' : 'motion-safe:animate-[pulse_3s_ease-in-out_infinite]'

    return (
        <div
            className={`fixed bottom-6 right-4 z-[60] max-w-sm rounded-3xl border border-base-300/70 bg-base-100/95 p-4 shadow-[0_25px_90px_rgba(0,0,0,0.35)] backdrop-blur transition-all duration-300 ${translationClass
                } ${opacityClass} ${pointerClass} ${prefersReducedMotion ? '' : 'motion-safe:drop-shadow-[0_25px_90px_rgba(0,0,0,0.45)]'}`}
            role="dialog"
            aria-label="New Zigbook updates"
        >
            <div className="flex items-start justify-between gap-3">
                <div className="space-y-1">
                    <p className="text-[0.6rem] font-semibold uppercase tracking-[0.35em] text-accent">Newly shipped</p>
                    <h3 className="text-lg font-semibold text-base-content">New Zig Playground + New Zig Community Forums</h3>
                    <p className="text-sm text-base-content/70">
                        Experiment with Zig right in your browser! After trying things out, join the conversation on the new Zigbook Community forums.
                    </p>
                </div>
                <button
                    type="button"
                    className="btn btn-ghost btn-xs btn-circle text-base-content/60"
                    onClick={handleDismiss}
                    aria-label="Dismiss announcement"
                >
                    ✕
                </button>
            </div>

            <div className="mt-4 grid gap-3">
                <Link
                    href="/playground"
                    onClick={() => {
                        onPlaygroundNavigate()
                        handleDismiss()
                    }}
                    className={`btn btn-primary btn-sm justify-between ${highlightPlayground && !prefersReducedMotion ? pulseClass : ''
                        }`}
                >
                    Launch the playground
                    <span className="text-xs text-base-100/80">NEW</span>
                </Link>
                <a
                    href="https://forums.zigbook.net/"
                    target="_blank"
                    rel="noreferrer"
                    onClick={() => {
                        onForumsNavigate()
                        handleDismiss()
                    }}
                    className={`btn btn-secondary btn-sm justify-between ${highlightForums && !prefersReducedMotion ? pulseClass : ''
                        }`}
                >
                    Join the forums
                    <span className="text-xs text-base-100/80">NEW</span>
                </a>
            </div>

            <div className="mt-4 flex flex-wrap gap-2 text-xs text-base-content/70">
                <button type="button" className="btn btn-ghost btn-xs" onClick={handleRemindLater}>
                    Remind me later
                </button>
                <button type="button" className="btn btn-ghost btn-xs" onClick={handleDismiss}>
                    I&apos;m all set
                </button>
            </div>
        </div>
    )
}
