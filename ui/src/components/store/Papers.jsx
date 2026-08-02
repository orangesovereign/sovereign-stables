import { useState, useEffect } from 'react'
import PipRow from './Pips.jsx'
import { money } from '../bits.jsx'

// The right-hand "papers" panel: a parchment sheet in a leather frame with brass
// corners, a top banner, and the horse/wagon record. Mirrors the vanilla
// renderDetail / renderWagonDetail contract.
export default function Papers({ detail, view, onPost, onGotoComponents }) {
  if (!detail) return <aside className="sf-papers sf-papers--empty" />
  if (detail.isWagon) return <WagonPapers d={detail} onPost={onPost} />
  return <HorsePapers d={detail} view={view} onPost={onPost} onGotoComponents={onGotoComponents} />
}

function Frame({ banner, bannerTone = 'oxblood', children }) {
  return (
    <aside className="sf-papers">
      <span className="sf-papers-clip" />
      <div className="ss-parchment-surface sf-papers-sheet">
        <i className="sf-corner sf-corner--tl" /><i className="sf-corner sf-corner--tr" />
        <i className="sf-corner sf-corner--bl" /><i className="sf-corner sf-corner--br" />
        {banner ? <div className={`ss-nine ss-banner sf-banner sf-banner--${bannerTone}`}>{banner}</div> : null}
        {children}
      </div>
      <span className="sf-papers-plate" />
    </aside>
  )
}

function HorsePapers({ d, view, onPost, onGotoComponents }) {
  const s = d.stats || {}
  const owned = !!d.ownedId
  const banner = owned ? 'Active Horse' : (d.tier === 'specialty' ? 'Specialty' : 'Stock')
  return (
    <Frame banner={banner} bannerTone={owned ? 'oxblood' : (d.tier === 'specialty' ? 'oxblood' : 'brass')}>
      <div className="sf-sub"><span className="sf-sub-rule" />{d.breed || 'Horse'}<span className="sf-sub-rule" /></div>
      <h2 className="sf-name">{d.name || d.model}</h2>
      <div className="sf-attrs">
        <span><b>{d.sex || '—'}</b></span>
        <span>{Number(d.age) || 0} yrs</span>
        <span>{(Number(d.hands) || 0).toFixed(1)} HH</span>
      </div>
      {owned && (d.ownerName || d.location) ? (
        <div className="sf-meta">
          {d.ownerName ? <div><small>Owned by</small><b>{d.ownerName}</b></div> : null}
          {d.location ? <div><small>Current location</small><b>{d.location}</b></div> : null}
        </div>
      ) : null}
      {d.lore ? <p className="sf-lore">{d.lore}</p> : null}
      <div className="sf-stats">
        <PipRow label="Health" value={s.health} />
        <PipRow label="Stamina" value={s.stamina} />
        {owned
          ? (<><PipRow label="Bonding" value={s.bonding} /><PipRow label="Training" value={s.training} /></>)
          : (<><PipRow label="Speed" value={s.speed} /><PipRow label="Acceleration" value={s.acceleration} /><PipRow label="Turn" value={s.turn} /></>)}
      </div>

      {owned ? (
        <div className="sf-actions">
          <button className="sf-btn sf-btn--buy" onClick={() => onPost('bringOut', { id: d.ownedId })}>Call Horse</button>
          <button className="sf-btn sf-btn--dark" onClick={onGotoComponents}>Select Components</button>
          {!d.isDefault && <button className="sf-btn sf-btn--dark" onClick={() => onPost('setDefault', { id: d.ownedId })}>Make Default Ride</button>}
          <p className="sf-note">Calling this horse will store your current active mount.</p>
        </div>
      ) : d.brokered ? (
        <div className="sf-brokered">
          <div className="sf-price sf-price--muted">Not sold over the counter</div>
          <p className="sf-note">Speak to the stable&rsquo;s <b>trainer</b> to arrange this horse.</p>
        </div>
      ) : (
        <BuyBlock d={d} onPost={onPost} kind="horse" />
      )}

      <div className="sf-foot">{owned ? 'Owned · papers on file' : 'Includes ownership papers · Stable slot required'}</div>
    </Frame>
  )
}

function WagonPapers({ d, onPost }) {
  const mine = !!d.ownedWagonId
  const s = d.stats || {}
  return (
    <Frame banner={mine ? 'Work Wagon' : 'Delivery'} bannerTone="oxblood">
      <div className="sf-sub"><span className="sf-sub-rule" />{d.type || 'Four-Wheel Wagon'}<span className="sf-sub-rule" /></div>
      <h2 className="sf-name">{d.name || d.model || 'Wagon'}</h2>
      <div className="sf-attrs">
        {d.seats != null ? <span>{d.seats} seats</span> : null}
        <span>Holds {d.storage || 0}</span>
        {d.team != null ? <span>{d.team} horse team</span> : null}
      </div>
      {d.lore ? <p className="sf-lore">{d.lore}</p> : null}
      {(s.durability != null) && (
        <div className="sf-stats">
          <PipRow label="Durability" value={s.durability} glyph="wheel" />
          <PipRow label="Cargo" value={s.cargo} glyph="wheel" />
          <PipRow label="Handling" value={s.handling} glyph="wheel" />
          <PipRow label="Speed" value={s.speed} glyph="wheel" />
          <PipRow label="Braking" value={s.braking} glyph="wheel" />
        </div>
      )}
      {mine ? (
        <div className="sf-actions">
          <button className="sf-btn sf-btn--buy" onClick={() => onPost('callWagon', { id: d.ownedWagonId })}>Bring It Round</button>
          {Number(d.is_default) !== 1 && <button className="sf-btn sf-btn--dark" onClick={() => onPost('setDefaultWagon', { id: d.ownedWagonId })}>Make Default Wagon</button>}
        </div>
      ) : (
        <BuyBlock d={d} onPost={onPost} kind="wagon" />
      )}
      <div className="sf-foot">{mine ? 'Owned · papers on file' : 'Registration included · Stable storage required'}</div>
    </Frame>
  )
}

// Price + two-step purchase form (name, and gender for horses).
function BuyBlock({ d, onPost, kind }) {
  const [open, setOpen] = useState(false)
  const [name, setName] = useState(d.name || '')
  const [sex, setSex] = useState(d.sex === 'Mare' ? 'Mare' : 'Stallion')
  useEffect(() => { setOpen(false); setName(d.name || '') }, [d.model])

  const confirm = () => {
    const n = name.trim()
    if (!n) return
    if (kind === 'wagon') onPost('purchaseWagon', { model: d.model, name: n })
    else onPost('purchase', { model: d.model, name: n, sex })
    setOpen(false)
  }

  return (
    <div className="sf-buy">
      <div className="sf-price"><b>{money(d.cash)}</b>{d.gold ? <span> or {d.gold} <em>Gold</em></span> : null}</div>
      {!open ? (
        <button className="sf-btn sf-btn--buy" onClick={() => setOpen(true)}>{kind === 'wagon' ? 'Purchase Wagon' : 'Purchase Horse'}</button>
      ) : (
        <div className="sf-buyform">
          <label className="sf-field"><span>Name</span><input value={name} maxLength={24} spellCheck={false} onChange={(e) => setName(e.target.value)} placeholder={`Name your ${kind}`} autoFocus /></label>
          {kind === 'horse' && (
            <div className="sf-seg">
              {['Stallion', 'Mare'].map((x) => (
                <button key={x} className={sex === x ? 'is-active' : ''} onClick={() => setSex(x)}>{x}</button>
              ))}
            </div>
          )}
          <button className="sf-btn sf-btn--buy" onClick={confirm}>Confirm Purchase</button>
          <button className="sf-btn sf-btn--ghost" onClick={() => setOpen(false)}>Cancel</button>
        </div>
      )}
    </div>
  )
}
