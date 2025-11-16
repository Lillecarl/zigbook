export default function HeroBackground() {
  return (
    <div
      aria-hidden="true"
      className="pointer-events-none absolute inset-0 -z-10 overflow-hidden"
    >
      {/* Upper-right orbital panels */}
      <svg
        className="hero-orbit-slow absolute -top-32 -right-24 h-[460px] w-[460px] text-accent/40"
        viewBox="0 0 600 600"
      >
        <g opacity="0.9">
          <rect
            x="220"
            y="80"
            width="260"
            height="150"
            rx="32"
            fill="currentColor"
            opacity="0.10"
          />
          <rect
            x="190"
            y="150"
            width="260"
            height="160"
            rx="32"
            fill="currentColor"
            opacity="0.06"
          />
          <rect
            x="250"
            y="210"
            width="230"
            height="130"
            rx="28"
            fill="currentColor"
            opacity="0.08"
          />
        </g>

        {/* Flow rings / paths */}
        <g
          fill="none"
          stroke="currentColor"
          strokeWidth="1.2"
          opacity="0.55"
        >
          <circle cx="320" cy="240" r="140" className="[stroke-dasharray:4_8]" />
          <circle cx="320" cy="240" r="190" className="[stroke-dasharray:2_10]" />
          <path
            d="M180 260C220 210 270 190 320 190C375 190 430 210 470 250"
            className="[stroke-dasharray:6_10]"
            strokeLinecap="round"
          />
        </g>

        {/* Moving nodes (rotate with the whole group) */}
        <g fill="currentColor" opacity="0.9">
          <circle cx="320" cy="100" r="5" />
          <circle cx="470" cy="240" r="4" />
          <circle cx="210" cy="260" r="3.5" />
        </g>
      </svg>

      {/* Lower-left subtle strata */}
      <svg
        className="hero-orbit-slower absolute -bottom-40 -left-32 h-[420px] w-[420px] text-primary/25"
        viewBox="0 0 600 600"
      >
        <g opacity="0.9">
          <rect
            x="80"
            y="260"
            width="260"
            height="150"
            rx="32"
            fill="currentColor"
            opacity="0.10"
          />
          <rect
            x="110"
            y="210"
            width="220"
            height="130"
            rx="28"
            fill="currentColor"
            opacity="0.06"
          />
        </g>

        <g
          fill="none"
          stroke="currentColor"
          strokeWidth="1.1"
          opacity="0.5"
        >
          <path
            d="M80 340C140 300 200 290 260 300C310 308 350 330 390 360"
            className="[stroke-dasharray:5_10]"
            strokeLinecap="round"
          />
          <circle cx="210" cy="330" r="70" className="[stroke-dasharray:3_7]" />
        </g>

        <g fill="currentColor" opacity="0.9">
          <circle cx="110" cy="360" r="4" />
          <circle cx="270" cy="290" r="3.5" />
        </g>
      </svg>
    </div>
  )
}
