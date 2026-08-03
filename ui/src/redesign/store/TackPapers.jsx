import { useState, useEffect } from 'react'
import { Icon, Button, money } from '../kit.jsx'
import { TACK_PALETTES, TINT_CHANNELS, defaultTint } from '../../components/store/tackData.js'

// "Saddlery Work Order" papers: item record + component configuration
// (palette + Base/Accent/Detail channels), wired to the vanilla tint contract.
export default function TackPapers({ item, isOwned, isWorn, savedTint, categoryLabel, horseName, ownedCount, onBuy, onEquip, onPreview, onSave }) {
  const [tint, setTint] = useState(savedTint || defaultTint())
  useEffect(() => { setTint(savedTint || defaultTint()) }, [item && item.id])

  if (!item) {
    return <aside className="sc-papers"><div className="sc-papers-in sc-papers-empty">Pick a component from the strip below to fit and colour it.</div></aside>
  }

  const change = (patch) => { const next = { ...tint, ...patch }; setTint(next); if (isWorn) onPreview(item.slot, next) }
  const palIndex = Math.max(0, TACK_PALETTES.findIndex((p) => p.id === tint.palette))
  const stepPalette = (dir) => change({ palette: TACK_PALETTES[(palIndex + dir + TACK_PALETTES.length) % TACK_PALETTES.length].id })
  const stepChannel = (key, dir) => {
    const cur = tint[key] === 255 ? 255 : Number(tint[key]) || 0
    change({ [key]: cur === 255 && dir < 0 ? 254 : Math.max(0, Math.min(255, cur + dir)) })
  }
  const chanText = (v) => (v === 255 ? 'Off' : String(v))

  return (
    <aside className="sc-papers">
      <div className="sc-papers-in">
        <header className="sc-pp-head">
          <Icon name="saddle" size={26} tone="#7c2a24" className="sc-pp-emblem" />
          <div className="sc-pp-kicker"><span className="sc-flour" />{categoryLabel || 'Component'}<span className="sc-flour" /></div>
        </header>
        <h1 className="sc-pp-name">{item.label || item.id}</h1>
        {item.desc ? <p className="sc-pp-desc">{item.desc}</p> : null}

        <div className="sc-pp-cfg-h">Component Configuration</div>
        <div className="sc-pp-cfg">
          <Stepper label="Palette" value={TACK_PALETTES[palIndex].label} onDec={() => stepPalette(-1)} onInc={() => stepPalette(1)} wide />
          {TINT_CHANNELS.map((c) => <Stepper key={c.key} label={c.label} value={chanText(tint[c.key])} onDec={() => stepChannel(c.key, -1)} onInc={() => stepChannel(c.key, 1)} />)}
        </div>
        {isWorn ? <div className="sc-pp-live">Live changes — tint updates on your horse immediately.</div> : null}

        <div className="sc-pp-actions">
          {!isOwned ? (
            <>
              <div className="sc-pp-price"><b>{money(item.cash)}</b></div>
              <Button variant="primary" onClick={() => onBuy(item.id)}>Purchase &amp; Equip</Button>
            </>
          ) : isWorn ? (
            <>
              <Button variant="primary" onClick={() => onSave(item.slot, tint)}>Save Colour</Button>
              <button className="sc-linkbtn" onClick={() => change(defaultTint())}>Reset Numbers</button>
            </>
          ) : (
            <Button variant="primary" onClick={() => onEquip(item.id)}>Equip on Horse</Button>
          )}
        </div>

        {horseName ? <div className="sc-pp-compat"><Icon name="horseshoe" size={14} tone="#4f6138" />Compatible with {horseName}</div> : null}
        <div className="sc-pp-slots"><Icon name="saddle" size={15} tone="#8a6a2f" />{ownedCount || 0} Owned Components</div>
      </div>
    </aside>
  )
}

function Stepper({ label, value, onDec, onInc, wide }) {
  return (
    <div className={`sc-step${wide ? ' sc-step--wide' : ''}`}>
      <span className="sc-step-l">{label}</span>
      <div className="sc-step-ctl">
        <button onClick={onDec} aria-label={`${label} down`}>‹</button>
        <span className="sc-step-v">{value}</span>
        <button onClick={onInc} aria-label={`${label} up`}>›</button>
      </div>
    </div>
  )
}
