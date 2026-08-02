// Redesign component kit — shell + primitives. Emblems are ivory PNGs tinted via
// CSS mask (see .sc-ic / .sc-med in redesign.css). Data-driven, props only.

export function Icon({ name, size, tone, className = '', style }) {
  const url = `url(assets/emblems/${name}.png)`
  return <span className={`sc-ic ${className}`} style={{
    width: size, height: size, ...(tone ? { backgroundColor: tone } : {}),
    WebkitMaskImage: url, maskImage: url, ...style,
  }} />
}

export function money(n) { return '$' + (Number(n) || 0).toLocaleString('en-US') }

const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
export function shortDate(s) {
  if (!s) return ''
  const d = new Date(String(s).replace(' ', 'T'))
  if (isNaN(d.getTime())) return String(s).slice(5, 10)
  return `${MONTHS[d.getMonth()]} ${d.getDate()}`
}

/* ── shell ── */
export function AppShell({ crest = 'crest-laurel', wordmark = 'Sovereign Stables', brandSub, location,
  user, wallet, onExit, nav, active, onNav, seal, children }) {
  return (
    <div className="sc-app">
      <header className="sc-topbar">
        <Icon name={crest} className="sc-brandmark" />
        <div>
          <div className="sc-wordmark">{wordmark}</div>
          {brandSub ? <div className="sc-brand-sub">{brandSub}</div> : null}
        </div>
        {location ? <div className="sc-locpill"><Icon name="horseshoe" size={14} tone="#c19a3a" />{location}</div> : <span style={{ marginInline: 'auto' }} />}
        <div className="sc-topmeta">
          {user ? <span className="sc-mi sc-mi--user"><Icon name="person-detective" size={16} tone="#c9b27f" />{user}</span> : null}
          <span className="sc-mi"><Icon name="coin-dollar" size={16} tone="#c9b27f" /><b>{money(wallet?.cash)}</b></span>
          <span className="sc-mi"><Icon name="coin-dollar" size={16} tone="#c9b27f" /><b>{wallet?.gold || 0}</b> Gold</span>
        </div>
        <button className="sc-exit" onClick={onExit}>Exit</button>
      </header>

      <nav className="sc-rail">
        {(nav || []).map((n) => (
          <button key={n.key} className={`sc-navitem${n.key === active ? ' is-active' : ''}`} onClick={() => onNav(n.key)}>
            <Icon name={n.icon} />
            <em>{n.label}</em>
          </button>
        ))}
        {seal ? <div className="sc-rail-seal"><b>{seal.top}</b><small>{seal.bottom}</small></div> : null}
      </nav>

      <main className="sc-content">{children}</main>
    </div>
  )
}

export function FramedPage({ children }) {
  return (
    <div className="sc-page">
      <span className="sc-corner sc-corner--tl" /><span className="sc-corner sc-corner--tr" />
      <span className="sc-corner sc-corner--bl" /><span className="sc-corner sc-corner--br" />
      <div className="sc-page-scroll">{children}</div>
    </div>
  )
}

export function PageHead({ title, subtitle, action }) {
  return (
    <div className="sc-phead">
      <div className="sc-ptitle"><h1>{title}</h1>{subtitle ? <p>{subtitle}</p> : null}</div>
      <span className="sc-phead-rule" />
      {action || null}
    </div>
  )
}

export function StatCard({ tone = 'gold', icon, label, value, sub }) {
  return (
    <div className="sc-statcard">
      <span className={`sc-med sc-med--${tone}`}><Icon name={icon} /></span>
      <div>
        <div className="sc-st-l">{label}</div>
        <div className="sc-st-v">{value}</div>
        {sub ? <div className="sc-st-sub">{sub}</div> : null}
      </div>
    </div>
  )
}

export function Button({ variant = 'primary', icon, children, onClick }) {
  return <button className={`sc-btn sc-btn--${variant}`} onClick={onClick}>{icon ? <Icon name={icon} /> : null}{children}</button>
}

export function Pill({ tone = 'neutral', children }) {
  return <span className={`sc-pill sc-pill--${tone}`}>{children}</span>
}

export function Bar({ value, max = 100 }) {
  const pct = Math.max(0, Math.min(100, (Number(value) || 0) / max * 100))
  return <span className="sc-bar"><i style={{ width: `${pct}%` }} /></span>
}

export function Panel({ title, action, children }) {
  return (
    <section className="sc-panel">
      {title ? <h2 className="sc-panel-h">{title}{action ? <a>{action}</a> : null}</h2> : null}
      {children}
    </section>
  )
}
