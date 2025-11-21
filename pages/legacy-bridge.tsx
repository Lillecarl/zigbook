// This file exists purely so the legacy Pages Router stays valid.
// Without at least one conventional page in /pages, Next.js 16
// generates `LayoutRoutes = never` inside `.next/types/validator.ts`,
// which makes TypeScript choke with "Route is not assignable to never"
// during `next build`. Once the DocBook source files are moved out of
// /pages (or Next fixes the typed routes bug), this component can be
// deleted.
export default function LegacyBridge() {
  return null
}

export async function getStaticProps() {
  return {
    notFound: true,
  }
}
