// Small presentational primitives that wrap the kit's classes/assets.

export function Icon({ name, size }) {
  return <span className={`ss-icon ss-icon--${name}`} style={size ? { '--ss-icon-size': `${size}px` } : undefined} />
}

export function Seal({ variant, size = 46 }) {
  return <span className={`ss-seal${variant ? ` ss-seal--${variant}` : ''}`} style={{ '--ss-seal-size': `${size}px` }} />
}

// Wide dark stat plate: round brass medallion + label + value (matches concept).
export function StatPlate({ icon, label, value }) {
  return (
    <section className="ss-nine ss-card-dark mg2-stat">
      <span className="mg2-medallion"><Icon name={icon} size={26} /></span>
      <span className="mg2-stat-txt">
        <small>{label}</small>
        <strong>{value}</strong>
      </span>
    </section>
  )
}

// Centred section header: display title + small-caps sub, hairline under.
export function SectionHead({ title, sub }) {
  return (
    <div className="mg2-head">
      <h2>{title}</h2>
      {sub ? <small>{sub}</small> : null}
    </div>
  )
}

export function money(n) {
  return '$' + (Number(n) || 0).toLocaleString()
}

const MONTHS = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC']
export function shortDate(s) {
  if (!s) return ''
  const d = new Date(String(s).replace(' ', 'T'))
  if (isNaN(d.getTime())) return String(s).slice(5, 10)
  return `${MONTHS[d.getMonth()]} ${d.getDate()}`
}
