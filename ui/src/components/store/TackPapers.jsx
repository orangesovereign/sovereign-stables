import { useState, useEffect } from 'react'
import { money } from '../bits.jsx'
import { TACK_PALETTES, TINT_CHANNELS, defaultTint } from './tackData.js'

// The "Saddlery Work Order" papers panel: item record + component configuration
// (palette + Base/Accent/Detail channels), wired to the vanilla tint contract.
export default function TackPapers({ item, isOwned, isWorn, savedTint, categoryLabel, onBuy, onEquip, onPreview, onSave }) {
  const [tint, setTint] = useState(savedTint || defaultTint())
  useEffect(() => { setTint(savedTint || defaultTint()) }, [item && item.id])

  if (!item) {
    return (
      <aside className="sf-papers">
        <div className="ss-parchment-surface sf-papers-sheet">
          <div className="sf-soon">Pick a component from the strip below to fit and colour it.</div>
        </div>
      </aside>
    )
  }

  const change = (patch) => {
    const next = { ...tint, ...patch }
    setTint(next)
    if (isWorn) onPreview(item.slot, next)
  }
  const palIndex = Math.max(0, TACK_PALETTES.findIndex((p) => p.id === tint.palette))
  const stepPalette = (dir) => {
    const i = (palIndex + dir + TACK_PALETTES.length) % TACK_PALETTES.length
    change({ palette: TACK_PALETTES[i].id })
  }
  const stepChannel = (key, dir) => {
    const cur = tint[key] === 255 ? 255 : Number(tint[key]) || 0
    let v = cur === 255 && dir < 0 ? 254 : Math.max(0, Math.min(255, cur + dir))
    change({ [key]: v })
  }
  const chanText = (v) => (v === 255 ? 'Off' : String(v))

  return (
    <aside className="sf-papers">
      <span className="sf-papers-clip" />
      <div className="ss-parchment-surface sf-papers-sheet">
        <i className="sf-corner sf-corner--tl" /><i className="sf-corner sf-corner--tr" />
        <i className="sf-corner sf-corner--bl" /><i className="sf-corner sf-corner--br" />
        <div className="ss-nine ss-banner sf-banner sf-banner--oxblood">Saddlery Work Order</div>

        <div className="sf-sub"><span className="sf-sub-rule" />{categoryLabel || 'Component'}<span className="sf-sub-rule" /></div>
        <h2 className="sf-name">{item.label || item.id}</h2>
        {item.desc ? <p className="sf-lore">{item.desc}</p> : null}

        <div className="sf-sub sf-sub--config"><span className="sf-sub-rule" />Component Configuration<span className="sf-sub-rule" /></div>
        <div className="sf-config">
          <Stepper label="Palette" value={TACK_PALETTES[palIndex].label} onDec={() => stepPalette(-1)} onInc={() => stepPalette(1)} wide />
          {TINT_CHANNELS.map((c) => (
            <Stepper key={c.key} label={c.label} value={chanText(tint[c.key])} onDec={() => stepChannel(c.key, -1)} onInc={() => stepChannel(c.key, 1)} />
          ))}
        </div>
        {isWorn ? <div className="sf-live">Live changes — tint updates on your horse immediately.</div> : null}

        <div className="sf-buy">
          {!isOwned ? (
            <>
              <div className="sf-price"><b>{money(item.cash)}</b></div>
              <button className="sf-btn sf-btn--buy" onClick={() => onBuy(item.id)}>Purchase &amp; Equip</button>
            </>
          ) : isWorn ? (
            <button className="sf-btn sf-btn--buy" onClick={() => onSave(item.slot, tint)}>Save Colour</button>
          ) : (
            <button className="sf-btn sf-btn--buy" onClick={() => onEquip(item.id)}>Equip on Horse</button>
          )}
          {isOwned ? <button className="sf-btn sf-btn--ghost" onClick={() => change(defaultTint())}>Reset Numbers</button> : null}
        </div>
        <div className="sf-foot">{isWorn ? 'Fitted · colour saved to this horse' : isOwned ? 'Owned · click Equip to fit' : 'Purchased tack fits whichever horse you ride'}</div>
      </div>
      <span className="sf-papers-plate" />
    </aside>
  )
}

function Stepper({ label, value, onDec, onInc, wide }) {
  return (
    <div className={`sf-step${wide ? ' sf-step--wide' : ''}`}>
      <span className="sf-step-l">{label}</span>
      <div className="sf-step-ctl">
        <button onClick={onDec} aria-label={`${label} down`}>‹</button>
        <span className="sf-step-v">{value}</span>
        <button onClick={onInc} aria-label={`${label} up`}>›</button>
      </div>
    </div>
  )
}
