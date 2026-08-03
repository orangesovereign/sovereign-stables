import { useState, useEffect } from 'react'
import { Icon, Bar, Button, Pill, money } from '../kit.jsx'

// Right-hand parchment "papers" panel: horse or wagon record with stat bars.
export default function Papers({ detail, view, slots, onPost, onGotoComponents }) {
  if (!detail) return <aside className="sc-papers"><div className="sc-papers-in sc-papers-empty">Choose from the catalog below.</div></aside>
  if (detail.isWagon) return <WagonPapers d={detail} slots={slots} onPost={onPost} />
  return <HorsePapers d={detail} slots={slots} onPost={onPost} onGotoComponents={onGotoComponents} />
}

function Eyebrow({ icon, label }) {
  return (
    <header className="sc-pp-head">
      <Icon name={icon} size={26} tone="#7c2a24" className="sc-pp-emblem" />
      <div className="sc-pp-kicker"><span className="sc-flour" />{label}<span className="sc-flour" /></div>
    </header>
  )
}

function StatRow({ label, value }) {
  return (
    <div className="sc-pp-stat">
      <span className="sc-pp-stat-l">{label}</span>
      <Bar value={value} />
      <span className="sc-pp-stat-v">{Number(value) || 0}</span>
    </div>
  )
}

function Slots({ slots }) {
  if (!slots) return null
  return <div className="sc-pp-slots"><Icon name="horseshoe" size={15} tone="#8a6a2f" />{slots.n} / {slots.cap} {slots.label} Slots</div>
}

function HorsePapers({ d, slots, onPost, onGotoComponents }) {
  const s = d.stats || {}
  const owned = !!d.ownedId
  const label = owned ? 'Owned Horse' : (d.tier === 'specialty' ? 'Specialty' : 'Stock Horse')
  return (
    <aside className="sc-papers">
      <div className="sc-papers-in">
        <Eyebrow icon="horse-head" label={label} />
        <h1 className="sc-pp-name">{d.name || d.model}</h1>
        <div className="sc-pp-sub">{d.breed || 'Horse'}</div>
        {owned ? <div className="sc-pp-pillrow"><Pill tone="green">Active · With You</Pill></div> : null}
        <div className="sc-pp-attrs"><span>{d.sex || '—'}</span><span>{Number(d.age) || 0} yrs</span><span>{(Number(d.hands) || 0).toFixed(1)} HH</span></div>
        {d.lore ? <p className="sc-pp-desc">{d.lore}</p> : null}

        <div className="sc-pp-stats">
          <StatRow label="Health" value={s.health} />
          <StatRow label="Stamina" value={s.stamina} />
          {owned
            ? (<><StatRow label="Bonding" value={s.bonding} /><StatRow label="Training" value={s.training} /></>)
            : (<><StatRow label="Speed" value={s.speed} /><StatRow label="Acceleration" value={s.acceleration} /><StatRow label="Turn" value={s.turn} /></>)}
        </div>

        {owned && d.location ? <div className="sc-pp-loc"><span>Location</span><b>{d.location}</b></div> : null}

        <div className="sc-pp-actions">
          {owned ? (
            <>
              <Button variant="primary" onClick={() => onPost('bringOut', { id: d.ownedId })}>Call Horse</Button>
              <div className="sc-pp-grid2">
                <Button variant="secondary" onClick={onGotoComponents}>Components</Button>
                {!d.isDefault
                  ? <Button variant="secondary" onClick={() => onPost('setDefault', { id: d.ownedId })}>Make Default</Button>
                  : <Button variant="secondary" onClick={() => {}}>Default Ride</Button>}
              </div>
            </>
          ) : d.brokered ? (
            <div className="sc-pp-broker"><b>Not sold over the counter</b><p>Speak to the stable&rsquo;s <em>trainer</em> to arrange this horse.</p></div>
          ) : (
            <BuyBlock d={d} onPost={onPost} kind="horse" />
          )}
        </div>

        <Slots slots={slots} />
        <div className="sc-pp-foot">{owned ? 'Owned · papers on file' : 'Includes ownership papers · Stable slot required'}</div>
      </div>
    </aside>
  )
}

function WagonPapers({ d, slots, onPost }) {
  const mine = !!d.ownedWagonId
  const s = d.stats || {}
  const hasStats = s.durability != null
  return (
    <aside className="sc-papers">
      <div className="sc-papers-in">
        <Eyebrow icon="wagon" label={mine ? 'Work Wagon' : (d.type || 'Wagon')} />
        <h1 className="sc-pp-name">{d.name || d.model || 'Wagon'}</h1>
        <div className="sc-pp-sub">{d.subtype || 'Work & Transport'}</div>
        <div className="sc-pp-attrs">
          {d.seats != null ? <span>{d.seats} seats</span> : null}
          <span>Holds {d.storage || 0}</span>
          {d.team != null ? <span>{d.team} horse team</span> : null}
        </div>
        {d.lore ? <p className="sc-pp-desc">{d.lore}</p> : null}
        {hasStats ? (
          <div className="sc-pp-stats">
            <StatRow label="Durability" value={s.durability} />
            <StatRow label="Speed" value={s.speed} />
            <StatRow label="Handling" value={s.handling} />
            <StatRow label="Cargo" value={s.cargo} />
          </div>
        ) : null}
        <div className="sc-pp-actions">
          {mine ? (
            <>
              <Button variant="primary" onClick={() => onPost('callWagon', { id: d.ownedWagonId })}>Bring It Round</Button>
              {Number(d.is_default) !== 1 ? <Button variant="secondary" onClick={() => onPost('setDefaultWagon', { id: d.ownedWagonId })}>Make Default Wagon</Button> : null}
            </>
          ) : (
            <BuyBlock d={d} onPost={onPost} kind="wagon" />
          )}
        </div>
        <Slots slots={slots} />
        <div className="sc-pp-foot">{mine ? 'Owned · papers on file' : 'Registration included · Stable storage required'}</div>
      </div>
    </aside>
  )
}

function BuyBlock({ d, onPost, kind }) {
  const [open, setOpen] = useState(false)
  const [name, setName] = useState(d.name || '')
  const [sex, setSex] = useState(d.sex === 'Mare' ? 'Mare' : 'Stallion')
  useEffect(() => { setOpen(false); setName(d.name || '') }, [d.model])

  const confirm = () => {
    const n = name.trim(); if (!n) return
    if (kind === 'wagon') onPost('purchaseWagon', { model: d.model, name: n })
    else onPost('purchase', { model: d.model, name: n, sex })
    setOpen(false)
  }

  return (
    <div className="sc-pp-buy">
      <div className="sc-pp-price"><b>{money(d.cash)}</b>{d.gold ? <em> or {d.gold} Gold</em> : null}</div>
      {!open ? (
        <Button variant="primary" onClick={() => setOpen(true)}>{kind === 'wagon' ? 'Purchase Wagon' : 'Purchase Horse'}</Button>
      ) : (
        <div className="sc-pp-form">
          <label className="sc-field"><span>Name</span><input value={name} maxLength={24} spellCheck={false} autoFocus onChange={(e) => setName(e.target.value)} placeholder={`Name your ${kind}`} /></label>
          {kind === 'horse' ? (
            <div className="sc-seg">{['Stallion', 'Mare'].map((x) => <button key={x} className={sex === x ? 'is-active' : ''} onClick={() => setSex(x)}>{x}</button>)}</div>
          ) : null}
          <Button variant="primary" onClick={confirm}>Confirm Purchase</Button>
          <button className="sc-linkbtn" onClick={() => setOpen(false)}>Cancel</button>
        </div>
      )}
    </div>
  )
}
