import { Icon, Seal, StatPlate, SectionHead, money, shortDate } from './bits.jsx'

// Operations Overview — the two-page owner/admin dashboard. Returns { left, right }.
export default function overviewPages(o = {}, onAction) {
  const ch = o.clientHorses || {}
  const funds = o.funds || {}
  const total = Number(ch.total) || 0
  const active = (o.breeding && Number(o.breeding.active)) || 0
  const pctOf = (n) => (total ? (n / total) * 100 : (n ? 100 : 0))

  const PHASES = [
    { seal: undefined, color: 'var(--ss-oxblood-500)', title: 'Raising', note: 'Growth and care period', count: Number(ch.raising) || 0, unit: 'horses', pct: pctOf(Number(ch.raising) || 0) },
    { seal: undefined, color: 'var(--ss-oxblood-500)', title: 'Training', note: 'Active trainer assignments', count: Number(ch.training) || 0, unit: 'horses', pct: pctOf(Number(ch.training) || 0) },
    { seal: 'green', color: 'var(--ss-green-500)', title: 'Ready for Pickup', note: 'Client collection pending', count: Number(ch.ready) || 0, unit: 'horses', pct: pctOf(Number(ch.ready) || 0) },
    { seal: 'gold', color: 'var(--ss-warning)', title: 'Active Breedings', note: 'Stud pairings in progress', count: active, unit: 'pairings', pct: active ? Math.min(100, active * 25) : 0 },
  ]

  const onDuty = (o.staff || []).filter((e) => Number(e.on_duty) === 1).slice(0, 3)

  const left = (
    <>
      <PageTitle>Operations Overview</PageTitle>

      <div className="ss-grid ss-grid--2 mg2-stats">
        <StatPlate icon="coin" label="Society Funds" value={money(funds.cash)} />
        <StatPlate icon="people" label="Employees on Duty" value={`${o.onDuty || 0} / ${o.staffCount || 0}`} />
      </div>

      <SectionHead title="Today's Stable Operations" sub="All client work by phase" />
      <div className="mg2-panel">
        {PHASES.map((p) => (
          <div className="mg2-phase" key={p.title}>
            <span className="mg2-phase-seal"><Seal variant={p.seal} size={50} /></span>
            <span className="mg2-phase-main"><strong>{p.title}</strong><small>{p.note}</small></span>
            <span className="mg2-phase-count"><b>{p.count}</b> {p.unit}</span>
            <span className="ss-progress mg2-phase-bar" style={{ '--ss-progress': `${Math.max(4, Math.min(100, p.pct))}%`, '--ss-progress-color': p.color }}><span /></span>
          </div>
        ))}
      </div>

      <SectionHead title="Client Pickup Queue" sub={(o.pickup || []).length ? 'Trained horses ready to return to their owners.' : ''} />
      {(o.pickup || []).length ? (
        <div className="ss-stack mg2-pickups">
          {o.pickup.map((h) => (
            <div className="ss-nine ss-card-dark mg2-pickup" key={h.id}>
              <span className="mg2-pickup-portrait" />
              <span className="mg2-pickup-id"><strong>{h.horse_name}</strong><small>{h.client_name}</small></span>
              <button className="mg2-pickup-btn" onClick={() => onAction && onAction('returnHorse', { id: h.id })}>Ready for Pickup</button>
              <span className="mg2-pickup-note">Notified</span>
            </div>
          ))}
        </div>
      ) : (
        <div className="mg-empty">No horses awaiting pickup.</div>
      )}
    </>
  )

  const notes = o.notes || `${Number(ch.ready) || 0} client pickup(s) pending · ${active} breeding(s) in progress.`

  const right = (
    <>
      <div className="ss-grid ss-grid--2 mg2-stats">
        <StatPlate icon="horse-head" label="Client Horses" value={total} />
        <StatPlate icon="wagon" label="Ready for Pickup" value={Number(ch.ready) || 0} />
      </div>

      <SectionHead title="Staff on Duty" sub="Current shift" />
      {onDuty.length ? (
        <div className="ss-grid mg2-staffgrid">
          {onDuty.map((e, i) => (
            <div className="ss-nine ss-card-dark mg2-staff" key={i}>
              <span className="mg2-staff-badge">{cap(e.role)}</span>
              <span className="mg2-staff-portrait"><Icon name="person" size={30} /></span>
              <strong>{e.name}</strong>
              <small>{e.grade ? `Grade ${e.grade}` : 'On shift'}</small>
            </div>
          ))}
        </div>
      ) : (
        <div className="mg-empty">No one is on duty right now.</div>
      )}

      <section className="ss-nine ss-card-dark mg2-notes">
        <div className="mg2-notes-txt">
          <strong>Current Shift Notes</strong>
          {String(notes).split('\n').map((line, i) => <p key={i}>{line}</p>)}
        </div>
        <span className="ss-seal ss-seal--sc mg2-notes-seal" style={{ '--ss-seal-size': '60px' }} />
      </section>

      {funds.cash != null && (
        <>
          <SectionHead title="Recent Ledger" sub="Latest business activity" />
          <div className="mg2-ledger">
            {(o.ledger || []).length ? o.ledger.map((l, i) => {
              const amt = Number(l.amount_cash) || 0
              return (
                <div className="mg2-led-row" key={i}>
                  <span className="mg2-led-date">{shortDate(l.created_at)}</span>
                  <span className="mg2-led-desc">{l.description}</span>
                  <span className={`mg2-led-amt ${amt < 0 ? 'mg-neg' : 'mg-pos'}`}>{amt < 0 ? '-' : '+'}{money(Math.abs(amt))}</span>
                </div>
              )
            }) : <div className="mg-empty">No activity yet.</div>}
          </div>
        </>
      )}
    </>
  )

  return { left, right }
}

function PageTitle({ children }) {
  return (
    <header className="mg2-page-title">
      <span className="mg2-flourish" />
      <h1>{children}</h1>
      <span className="mg2-flourish mg2-flourish--r" />
    </header>
  )
}

function cap(s) {
  const t = String(s || 'staff')
  return t.charAt(0).toUpperCase() + t.slice(1)
}
