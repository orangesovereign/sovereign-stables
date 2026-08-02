import { useState, useCallback } from 'react'
import { useNuiEvent, fetchNui, isBrowser } from '../nui.js'
import { Icon, money } from './bits.jsx'
import Stage from './store/Stage.jsx'
import Papers from './store/Papers.jsx'
import TackPapers from './store/TackPapers.jsx'
import CatalogStrip from './store/CatalogStrip.jsx'
import { mockOwned, mockWagons, mockTack } from './store/mockStore.js'

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

  // ---- tack (Components) ----
  const [tackCats, setTackCats] = useState(isBrowser ? mockTack.categories : [])
  const [tackCatalog, setTackCatalog] = useState(isBrowser ? mockTack.catalog : {})
  const [tackOwned, setTackOwned] = useState(isBrowser ? mockTack.owned : [])
  const [tackWorn, setTackWorn] = useState(isBrowser ? { saddle: mockTack.components.saddle } : {})
  const [tackTints, setTackTints] = useState(isBrowser ? mockTack.components.__tints : {})
  const [tackHorseId, setTackHorseId] = useState(isBrowser ? mockTack.horseId : null)
  const [tackCat, setTackCat] = useState(isBrowser ? 'saddle' : null)
  const [tackSel, setTackSel] = useState(isBrowser ? 'saddle_ranch_cutter' : null)

  useNuiEvent('header', (h) => { setHeader(h); setWallet({ cash: h.cash, gold: h.gold }) })
  useNuiEvent('detail', (d) => setDetail(d.detail))
  useNuiEvent('wallet', (d) => setWallet({ cash: d.cash, gold: d.gold }))
  useNuiEvent('owned', (d) => { setOwned(d.owned || []); setOwnedCap(d.cap || 0) })
  useNuiEvent('wagons', (d) => {
    if (d.owned) setWagons(d.owned)
    if (d.catalog) setWagonRows(d.catalog)
  })
  useNuiEvent('tack', (d) => {
    if (d.categories) { setTackCats(d.categories); setTackCat((c) => c || (d.categories[0] && d.categories[0].id)) }
    if (d.catalog) setTackCatalog(d.catalog)
    if (d.owned) setTackOwned(d.owned)
    if (d.horseId) setTackHorseId(d.horseId)
    if (d.components) {
      const worn = {}
      let tints = {}
      for (const k in d.components) {
        if (k === '__tints') tints = d.components[k] || {}
        else worn[k] = d.components[k]
      }
      setTackWorn(worn)
      setTackTints(tints)
    }
  })

  const post = useCallback((name, body) => fetchNui(name, body), [])
  const onOrbit = useCallback((dx, dy) => fetchNui('orbit', { dx, dy }), [])
  const onZoom = useCallback((delta) => fetchNui('zoom', { delta }), [])

  const goView = (v) => {
    setView(v); setSelected(null); setSearch('')
    if (v === 'wagons') { setWagonTab('shop'); post('requestWagons', {}) }
    else if (v === 'tack') post('requestTack', { horseId: tackHorseId })
    else post('restoreHorsePreview', {})
  }

  // ---- tack callbacks ----
  const selectTackHorse = (id) => { setTackHorseId(id); post('requestTack', { horseId: id }) }
  const buyTack = (item) => post('buyTack', { item })
  const equipTack = (item) => post('applyTack', { horseId: tackHorseId, item })
  const previewTint = (slot, t) => post('previewTint', { slot, palette: t.palette, t0: t.t0, t1: t.t1, t2: t.t2 })
  const saveTint = (slot, t) => {
    post('saveTint', { horseId: tackHorseId, slot, palette: t.palette, t0: t.t0, t1: t.t1, t2: t.t2 })
    if (tackSel) setTackTints((prev) => ({ ...prev, [tackSel]: t }))
  }
  const tackItem = tackSel ? (tackCatalog[tackCat] || []).find((t) => t.id === tackSel) ||
    Object.values(tackCatalog).flat().find((t) => t.id === tackSel) : null
  const tackCatObj = (tackCats || []).find((c) => c.id === tackCat)

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
        <button className="ss-nine ss-btn-secondary ss-button sf-exit" onClick={() => post('close', {})}>Exit</button>
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
        <TackPapers
          item={tackItem}
          categoryLabel={tackCatObj && tackCatObj.label}
          isOwned={!!tackItem && (tackOwned || []).some((o) => o.item === tackItem.id)}
          isWorn={!!tackItem && tackCatObj && tackWorn[tackCatObj.slot] === tackItem.id}
          savedTint={tackItem ? tackTints[tackItem.id] : null}
          onBuy={buyTack} onEquip={equipTack} onPreview={previewTint} onSave={saveTint}
        />
      ) : (
        <Papers detail={detail} view={view} onPost={post} onGotoComponents={() => goView('tack')} />
      )}

      <CatalogStrip
        view={view} rows={rows} tab={tab} setTab={setTab} breed={breed} setBreed={setBreed}
        selected={selected} onChoose={choose} search={search} setSearch={setSearch}
        owned={owned} onSelectOwned={selectOwned}
        wagons={wagons} wagonRows={wagonRows} wagonTab={wagonTab} setWagonTab={setWagonTab}
        onSelectWagon={selectWagon} onSelectWagonModel={selectWagonModel}
        tackCats={tackCats} tackCatalog={tackCatalog} tackCat={tackCat} setTackCat={setTackCat}
        tackOwned={tackOwned} tackWorn={tackWorn} tackSel={tackSel} onSelectTack={setTackSel}
        tackHorseId={tackHorseId} onSelectHorse={selectTackHorse}
      />
    </div>
  )
}
