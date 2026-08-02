import { FramedPage, PageHead, StatCard, Panel, Button, Pill, Bar, Icon, money, shortDate } from './kit.jsx'

// OPERATIONS (owner/trainer overview). Binds to the server's `overview` payload.
export default function OperationsScreen({ o = {}, onAction }) {
  const ch = o.clientHorses || {}
  const funds = o.funds || {}
  const onDuty = (o.staff || []).filter((e) => Number(e.on_duty) === 1)
  const queue = o.pickup || []   // real "ready" rows; full in-training queue needs the training relay

  return (
    <FramedPage>
      <PageHead title="Operations" subtitle="Manage daily stable activities, client horses, and staff."
        action={<Button variant="primary" icon="people" onClick={() => onAction && onAction('newClient')}>New Client</Button>} />

      <div className="sc-statrow">
        <StatCard tone="gold" icon="coin-dollar" label="Society Funds" value={money(funds.cash)} />
        <StatCard tone="dark" icon="people" label="Staff on Duty" value={<>{o.onDuty || 0} <small>of {o.staffCount || 0}</small></>} sub="Active staff today" />
        <StatCard tone="green" icon="horseshoe" label="Active Client Horses" value={Number(ch.total) || 0} sub="In training or care" />
        <StatCard tone="gold" icon="cart" label="Ready for Pickup" value={Number(ch.ready) || 0} sub="Awaiting client pickup" />
      </div>

      <div className="sc-cols">
        <Panel title="Operations Queue">
          <div className="sc-filters">
            <input className="sc-input" placeholder="Search horses or clients…" />
            <select className="sc-select"><option>All Services</option></select>
            <select className="sc-select"><option>All Statuses</option></select>
          </div>
          <table className="sc-table">
            <thead><tr><th>Horse</th><th>Client</th><th>Service</th><th>Trainer</th><th>Progress</th><th>Due</th><th>Status</th></tr></thead>
            <tbody>
              {queue.length ? queue.map((h) => (
                <tr key={h.id}>
                  <td className="sc-t-strong">{h.horse_name}</td>
                  <td>{h.client_name}</td>
                  <td><Pill tone="green">Ready</Pill></td>
                  <td className="sc-t-sub">—</td>
                  <td><Bar value={100} /></td>
                  <td className="sc-t-sub">Today</td>
                  <td><Pill tone="green">Ready</Pill></td>
                </tr>
              )) : <tr><td colSpan={7}><div className="sc-empty">No client horses in the queue yet.</div></td></tr>}
            </tbody>
          </table>
        </Panel>

        <div style={{ display: 'grid', gap: 16 }}>
          <Panel title="Staff on Duty" action="View All">
            {onDuty.length ? onDuty.slice(0, 4).map((e, i) => (
              <div className="sc-srow" key={i}>
                <span className="sc-avatar"><Icon name="person-detective" /></span>
                <div className="sc-srow-main"><b>{e.name}</b><small>{cap(e.role)}{e.grade ? ` · Grade ${e.grade}` : ''}</small></div>
                <div className="sc-srow-r"><Pill tone="green">On Duty</Pill></div>
              </div>
            )) : <div className="sc-empty">No one is on duty.</div>}
          </Panel>

          <Panel title="Recent Ledger" action="View Ledger">
            {(o.ledger || []).length ? o.ledger.map((l, i) => {
              const amt = Number(l.amount_cash) || 0
              return (
                <div className="sc-ledrow" key={i}>
                  <span className="d">{shortDate(l.created_at)}</span>
                  <span className="t">{l.description}</span>
                  <span className={`a ${amt < 0 ? 'sc-neg' : 'sc-pos'}`}>{amt < 0 ? '-' : '+'}{money(Math.abs(amt))}</span>
                </div>
              )
            }) : <div className="sc-empty">No activity yet.</div>}
          </Panel>
        </div>
      </div>
    </FramedPage>
  )
}

function cap(s) { const t = String(s || 'staff'); return t.charAt(0).toUpperCase() + t.slice(1) }
