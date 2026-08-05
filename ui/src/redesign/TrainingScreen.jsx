import { useState } from 'react'
import { FramedPage, PageHead, StatCard, Panel, Button, Pill, Bar, shortDate } from './kit.jsx'

// TRAINING BOARD. Binds to the training section payload: { roster, counts, trainers, tiers, role }.
const PHASE = {
  raising:  { label: 'Raising',  tone: 'amber',   next: 'training' },
  training: { label: 'Training', tone: 'oxblood', next: 'ready' },
  ready:    { label: 'Ready',    tone: 'green',   next: null },
  returned: { label: 'Returned', tone: 'neutral', next: null },
}
const TRAINER_CAP = 6

export default function TrainingScreen({ data = {}, onAction, canManage }) {
  const roster = data.roster || []
  const counts = data.counts || {}
  const trainers = data.trainers || []
  const tiers = data.tiers || []
  const [q, setQ] = useState('')
  const [phaseFilter, setPhaseFilter] = useState('all')

  const tierLabel = (id) => (tiers.find((t) => t.id === id) || {}).label || id || '—'
  let rows = roster
  if (phaseFilter !== 'all') rows = rows.filter((r) => r.phase === phaseFilter)
  if (q) rows = rows.filter((r) => `${r.horse} ${r.client}`.toLowerCase().includes(q.toLowerCase()))

  return (
    <FramedPage>
      <PageHead title="Training Board" subtitle="Assign trainers, track service phases, and manage capacity."
        action={canManage ? <Button variant="primary" icon="people" onClick={() => onAction('intake', {})}>New Client</Button> : null} />

      <div className="sc-statrow">
        <StatCard tone="green" icon="horseshoe" label="Active Client Horses" value={Number(counts.total) || 0} sub="In training or care" />
        <StatCard tone="dark" icon="horse-run" label="In Training" value={Number(counts.training) || 0} sub="Active assignments" />
        <StatCard tone="gold" icon="cart" label="Ready for Pickup" value={Number(counts.ready) || 0} sub="Awaiting client pickup" />
        <StatCard tone="dark" icon="person-detective" label="Trainers" value={trainers.length} sub="On the roster" />
      </div>

      <div className="sc-cols">
        <Panel title="Training Assignments">
          <div className="sc-filters">
            <input className="sc-input" placeholder="Search horses or clients…" value={q} onChange={(e) => setQ(e.target.value)} />
            <select className="sc-select" value={phaseFilter} onChange={(e) => setPhaseFilter(e.target.value)}>
              <option value="all">All Phases</option>
              {Object.keys(PHASE).map((p) => <option key={p} value={p}>{PHASE[p].label}</option>)}
            </select>
          </div>
          <table className="sc-table">
            <thead><tr><th>Horse</th><th>Client</th><th>Service</th><th>Trainer</th><th>Progress</th><th>Due</th><th>Status</th></tr></thead>
            <tbody>
              {rows.length ? rows.map((h) => {
                const ph = PHASE[h.phase] || { label: h.phase, tone: 'neutral', next: null }
                return (
                  <tr key={h.id}>
                    <td className="sc-t-strong">{h.horse}<div className="sc-t-sub">{h.breed || h.gender || ''}</div></td>
                    <td>{h.client}</td>
                    <td className="sc-t-sub">{tierLabel(h.tier)}</td>
                    <td className="sc-t-sub">{h.trainer || '—'}</td>
                    <td><Bar value={Number(h.progress) || 0} /></td>
                    <td className="sc-t-sub">{h.readyAt ? shortDate(h.readyAt * 1000) : '—'}</td>
                    <td>
                      <div className="sc-rowactions">
                        <Pill tone={ph.tone}>{ph.label}</Pill>
                        {canManage && ph.next ? <button className="sc-linkbtn" onClick={() => onAction('setPhase', { id: h.id, phase: ph.next })}>Advance</button> : null}
                        {canManage && h.phase !== 'ready' && h.phase !== 'returned' ? <button className="sc-linkbtn" onClick={() => onAction('markReady', { id: h.id })}>Ready</button> : null}
                        {canManage && h.phase === 'ready' ? <button className="sc-linkbtn" onClick={() => onAction('returnHorse', { id: h.id })}>Return</button> : null}
                      </div>
                    </td>
                  </tr>
                )
              }) : <tr><td colSpan={7}><div className="sc-empty">No client horses in training yet.</div></td></tr>}
            </tbody>
          </table>
        </Panel>

        <div style={{ display: 'grid', gap: 16 }}>
          <Panel title="Trainer Capacity">
            {trainers.length ? trainers.map((t) => (
              <div className="sc-srow" key={t.charid}>
                <div className="sc-srow-main"><b>{t.name}</b><small>Trainer · {t.assigned} / {TRAINER_CAP} assigned</small>
                  <Bar value={Math.min(100, (Number(t.assigned) || 0) / TRAINER_CAP * 100)} />
                </div>
              </div>
            )) : <div className="sc-empty">No trainers on staff.</div>}
          </Panel>

          <Panel title="Service Phases">
            {Object.entries(PHASE).map(([k, v]) => (
              <div className="sc-legendrow" key={k}>
                <span className={`sc-dot sc-dot--${v.tone}`} />
                <b>{v.label}</b>
                <small>{counts[k] != null ? `${counts[k]} horse(s)` : ''}</small>
              </div>
            ))}
          </Panel>
        </div>
      </div>
    </FramedPage>
  )
}
