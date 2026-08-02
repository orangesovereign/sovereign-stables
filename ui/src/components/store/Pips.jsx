// A stat row rendered as filled/empty horseshoe (or wagon-wheel) pips + a value,
// matching the storefront concept's papers panel.
export default function PipRow({ label, value, max = 100, pips = 8, glyph = 'horseshoe' }) {
  const v = Math.max(0, Math.min(max, Number(value) || 0))
  const filled = Math.round((v / max) * pips)
  return (
    <div className="sf-stat">
      <span className="sf-stat-l">{label}</span>
      <span className="sf-pips" aria-hidden="true">
        {Array.from({ length: pips }).map((_, i) => (
          <span key={i} className={`sf-pip sf-pip--${glyph}${i < filled ? ' is-on' : ''}`} />
        ))}
      </span>
      <span className="sf-stat-v">{Number(value) || 0}</span>
    </div>
  )
}
