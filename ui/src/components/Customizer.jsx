import { useState, useMemo, useEffect } from 'react'
import { fetchNui } from '../nui.js'

// Horse morph customizer — a side panel; the horse stays visible in the world.
// Mirrors the vanilla openCustom/renderCustom contract.
const def = (a) => (a.kind === 'scale' ? 1.0 : 0.0)
const fmt = (n) => (Math.round(n * 100) / 100).toFixed(2)

export default function Customizer({ data, onClose }) {
  const attrs = data.attrs || []
  const [values, setValues] = useState(() => ({ ...(data.values || {}) }))

  useEffect(() => { setValues({ ...(data.values || {}) }) }, [data])

  // Group order: server-declared groups first, then any stragglers in attr order.
  const groups = useMemo(() => {
    const order = [...(data.groups || [])]
    attrs.forEach((a) => { if (!order.includes(a.group)) order.push(a.group) })
    return order.map((g) => ({ name: g, items: attrs.filter((a) => a.group === g) })).filter((g) => g.items.length)
  }, [data, attrs])

  const set = (a, v) => {
    setValues((prev) => ({ ...prev, [a.key]: v }))
    fetchNui('morphPreview', { key: a.key, value: v })
  }
  const resetAll = () => {
    const next = {}
    attrs.forEach((a) => { next[a.key] = def(a) })
    setValues(next)
    attrs.forEach((a) => fetchNui('morphPreview', { key: a.key, value: next[a.key] }))
  }
  const save = () => fetchNui('morphSave', { values })
  const close = () => { onClose(); fetchNui('morphClose') }

  const valOf = (a) => (values[a.key] != null ? values[a.key] : def(a))

  return (
    <div className="cz">
      <div className="cz-panel">
        <header className="cz-hd">
          <div className="cz-t"><h2>Horse Customizer</h2><p>{data.name || ''}</p></div>
          <button className="cz-x" onClick={close}>Done</button>
        </header>

        <div className="cz-groups">
          {groups.map((g) => (
            <section className="cz-g" key={g.name}>
              <div className="cz-gh">{g.name}</div>
              {g.items.map((a) => {
                const v = valOf(a)
                if (a.kind === 'toggle') {
                  return (
                    <label className="cz-row cz-row--toggle" key={a.key}>
                      <span className="cz-lbl">{a.label}</span>
                      <input type="checkbox" className="ss-toggle cz-chk" checked={v >= 0.5} onChange={(e) => set(a, e.target.checked ? 1 : 0)} />
                    </label>
                  )
                }
                const isScale = a.kind === 'scale'
                return (
                  <div className="cz-row" key={a.key}>
                    <label className="cz-lbl">{a.label}<span className="cz-val">{fmt(v)}</span></label>
                    <input type="range" className="cz-rng" min={isScale ? 0.5 : -1} max={isScale ? 2 : 1} step={0.05}
                      value={v} onChange={(e) => set(a, parseFloat(e.target.value))} />
                  </div>
                )
              })}
            </section>
          ))}
        </div>

        <footer className="cz-ft">
          <button className="cz-reset" onClick={resetAll}>Reset all</button>
          <button className="cz-save" onClick={save}>Save Shape</button>
        </footer>
      </div>
    </div>
  )
}
