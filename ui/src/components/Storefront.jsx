import { useState, useCallback } from 'react'
import { useNuiEvent, fetchNui, isBrowser } from '../nui.js'
import { Icon, money } from './bits.jsx'
import Stage from './store/Stage.jsx'
import Papers from './store/Papers.jsx'
import CatalogStrip from './store/CatalogStrip.jsx'
import { mockOwned, mockWagons } from './store/mockStore.js'

const ALL = '__all__'
const RAIL = [
  { key: 'shop', label: 'Stablefront', icon: 'barn' },
  { key: 'owned', label: 'My Horses', icon: 'horse-head' },
  { key: 'tack', label: 'Components', icon: 'horseshoe' },
  { key: 'wagons', label: 'Wagons', icon: 'wagon-wheel' },
]

export default function Storefront({ initial }) {
  const [header, setHeader] = useState(initial.header || {})
  const [rows] = useState((initial.catalog && initial.catalog.rows) || [])
  const [detail, setDetail] = useState(initial.detail || null)
  const [view, setView] = useState('shop')
  const [tab, setTab] = useState(rows.some((r) => (r.tier || 'stock') === 'specialty') ? 'specialty' : 'stock')
  const [breed, setBreed] = useState(ALL)
  const [selected, setSelected] = useState((initial.detail && initial.detail.model) || (rows[0] && rows[0].model) || null)
  const [search, setSearch] = useState('')

  const [owned, setOwned] = useState(isBrowser ? mockOwned.owned : [])
  const [ownedCap, setOwnedCap] = useState(isBrowser ? mockOwned.cap : 0)
  const [wagons, setWagons] = useState(isBrowser ? mockWagons.owned : [])
  const [wagonRows, setWagonRows] = useState(isBrowser ? mockWagons.catalog : [])
  const [wagonTab, setWagonTab] = useState('shop')
  const [wallet, setWallet] = useState({ cash: (initial.header || {}).cash || 0, gold: (initial.header || {}).gold || 0 })

  useNuiEvent('header', (h) => { setHeader(h); setWallet({ cash: h.cash, gold: h.gold }) })
  useNuiEvent('detail', (d) => setDetail(d.detail))
  useNuiEvent('wallet', (d) => setWallet({ cash: d.cash, gold: d.gold }))
  useNuiEvent('owned', (d) => { setOwned(d.owned || []); setOwnedCap(d.cap || 0) })
  useNuiEvent('wagons', (d) => {
    if (d.owned) setWagons(d.owned)
    if (d.catalog) setWagonRows(d.catalog)
  })

  const post = useCallback((name, body) => fetchNui(name, body), [])
  const onOrbit = useCallback((dx, dy) => fetchNui('orbit', { dx, dy }), [])
  const onZoom = useCallback((delta) => fetchNui('zoom', { delta }), [])

  const goView = (v) => {
    setView(v); setSelected(null); setSearch('')
    if (v === 'wagons') { setWagonTab('shop'); post('requestWagons', {}) }
    else if (v === 'tack') post('requestTack', {})
    else post('restoreHorsePreview', {})
  }

  const choose = (model) => { setSelected(model); post('select', { model }) }
  const selectOwned = (id) => { setSelected(id); post('selectOwned', { id }) }
  const selectWagon = (id) => { setSelected(id); post('selectWagon', { id }) }
  const selectWagonModel = (m) => { setSelected(m); post('selectWagonModel', { model: m }) }

  const cycle = (dir) => {
    if (view !== 'shop') return
    let vis = rows.filter((r) => (r.tier || 'stock') === tab)
    if (breed !== ALL) vis = vis.filter((r) => (r.breed || '') === breed)
    if (!vis.length) return
    let i = vis.findIndex((r) => r.model === selected)
    i = (i + dir + vis.length) % vis.length
    choose(vis[i].model)
  }

  return (
    <div className="sf-root">
      <header className="sf-hd">
        <span className="ss-icon ss-icon--sc-logo" style={{ '--ss-icon-size': '40px' }} />
        <span className="sf-brand"><b>Sovereign Stables</b><em>Stables &amp; Carriage Co.</em></span>
        <div className="ss-nine ss-cartouche sf-loc">{header.stableLabel || '—'}</div>
        <span className="sf-who">{header.charName}{header.job ? ` — ${header.job}` : ''}</span>
        <span className="sf-wallet"><Icon name="coin" size={18} /><b>{money(wallet.cash)}</b></span>
        <span className="sf-wallet"><Icon name="gold" size={18} /><b>{wallet.gold || 0}</b> Gold</span>
        <button className="ss-nine ss-btn-secondary ss-button sf-exit" onClick={() => post('requestClose', {})}>Exit</button>
      </header>

      <nav className="sf-rail">
        {RAIL.map((r) => (
          <button key={r.key} className={`sf-rail-btn${view === r.key ? ' is-active' : ''}`} onClick={() => goView(r.key)}>
            <span className={`ss-nine ss-tab-rail sf-rail-ico${view === r.key ? ' is-active' : ''}`}><Icon name={r.icon} /></span>
            <em>{r.label}</em>
          </button>
        ))}
        <span className="sf-rail-fleur" />
      </nav>

      <Stage onOrbit={onOrbit} onZoom={onZoom} onPrev={() => cycle(-1)} onNext={() => cycle(1)} />

      {view === 'tack' ? (
        <aside className="sf-papers sf-papers--empty"><div className="sf-soon">The saddlery is being fitted out.<br />Components arrive next.</div></aside>
      ) : (
        <Papers detail={detail} view={view} onPost={post} onGotoComponents={() => goView('tack')} />
      )}

      <CatalogStrip
        view={view} rows={rows} tab={tab} setTab={setTab} breed={breed} setBreed={setBreed}
        selected={selected} onChoose={choose} search={search} setSearch={setSearch}
        owned={owned} onSelectOwned={selectOwned}
        wagons={wagons} wagonRows={wagonRows} wagonTab={wagonTab} setWagonTab={setWagonTab}
        onSelectWagon={selectWagon} onSelectWagonModel={selectWagonModel}
      />
    </div>
  )
}
