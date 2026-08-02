import { money } from '../bits.jsx'

const ALL = '__all__'

// The bottom catalog strip: tabs + filter + search + a horizontal row of cards.
// Content depends on the active view (shop / owned / wagons).
export default function CatalogStrip(props) {
  const { view } = props
  if (view === 'owned') return <OwnedStrip {...props} />
  if (view === 'wagons') return <WagonStrip {...props} />
  return <ShopStrip {...props} />
}

function Card({ active, no, tag, thumb, name, sub, price, onClick }) {
  return (
    <button className={`sf-card${active ? ' is-active' : ''}`} onClick={onClick}>
      {no ? <span className="sf-card-no">{no}</span> : null}
      {tag ? <span className="sf-card-tag">{tag}</span> : null}
      <span className="sf-card-portrait" style={thumb ? { backgroundImage: `url(${thumb})` } : undefined} />
      <span className="sf-card-name">{name}</span>
      {sub ? <span className="sf-card-sub">{sub}</span> : null}
      {price ? <span className="sf-card-price">{price}</span> : null}
    </button>
  )
}

function Strip({ tabs, activeTab, onTab, filter, search, onSearch, children }) {
  return (
    <div className="sf-strip">
      <div className="sf-strip-head">
        <div className="sf-tabs">
          {tabs.map((t) => (
            <button key={t.key} className={activeTab === t.key ? 'is-active' : ''} onClick={() => onTab(t.key)}>{t.label}</button>
          ))}
        </div>
        {filter}
        <label className="sf-search"><input placeholder="Search…" value={search} onChange={(e) => onSearch(e.target.value)} /></label>
      </div>
      <div className="sf-cards">{children}</div>
    </div>
  )
}

function ShopStrip({ rows, tab, setTab, breed, setBreed, selected, onChoose, search, setSearch }) {
  const onTab = tab
  const tabRows = rows.filter((r) => (r.tier || 'stock') === onTab)
  const breeds = [...new Set(tabRows.map((r) => r.breed || 'Unknown'))].sort()
  let vis = breed !== ALL ? tabRows.filter((r) => (r.breed || '') === breed) : tabRows
  if (search) vis = vis.filter((r) => (r.name || r.model || '').toLowerCase().includes(search.toLowerCase()))

  const filter = breeds.length > 1 ? (
    <label className="sf-filter"><span>Breed</span>
      <select value={breed} onChange={(e) => setBreed(e.target.value)}>
        <option value={ALL}>All breeds ({tabRows.length})</option>
        {breeds.map((b) => <option key={b} value={b}>{b}</option>)}
      </select>
    </label>
  ) : null

  return (
    <Strip
      tabs={[{ key: 'specialty', label: 'Specialty Horses' }, { key: 'stock', label: 'Stock Horses' }]}
      activeTab={tab} onTab={(k) => { setTab(k); setBreed(ALL) }}
      filter={filter} search={search} onSearch={setSearch}
    >
      {vis.length ? vis.map((r, i) => (
        <Card key={r.model} active={r.model === selected} no={`No. ${String(i + 1).padStart(4, '0')}`}
          tag={r.tier === 'specialty' ? 'Specialty' : 'Stock'} name={r.name || r.model} sub={r.breed}
          price={r.locked ? '🔒' : `${money(r.cash)}${r.gold ? ` or ${r.gold} gold` : ''}`}
          onClick={() => !r.locked && onChoose(r.model)} />
      )) : <div className="sf-empty">No horses of that breed here.</div>}
    </Strip>
  )
}

function OwnedStrip({ owned, selected, onSelectOwned, search, setSearch }) {
  let vis = owned
  if (search) vis = owned.filter((o) => (o.name || o.model || '').toLowerCase().includes(search.toLowerCase()))
  return (
    <Strip tabs={[{ key: 'owned', label: 'Owned Horses' }]} activeTab="owned" onTab={() => {}} search={search} onSearch={setSearch}>
      {vis.length ? vis.map((o) => (
        <Card key={o.id} active={String(o.id) === String(selected)} tag={Number(o.is_default) === 1 ? 'Active' : null}
          name={o.name || o.model} sub={o.model} onClick={() => onSelectOwned(o.id)} />
      )) : <div className="sf-empty">You keep no horses yet.</div>}
    </Strip>
  )
}

function WagonStrip({ wagons, wagonRows, selected, onSelectWagon, onSelectWagonModel, search, setSearch, wagonTab, setWagonTab }) {
  const mine = wagonTab === 'mine'
  const list = mine ? wagons : wagonRows
  let vis = list
  if (search) vis = list.filter((w) => (w.name || w.model || '').toLowerCase().includes(search.toLowerCase()))
  return (
    <Strip
      tabs={[{ key: 'shop', label: 'Wagons for Sale' }, { key: 'mine', label: 'My Wagons' }]}
      activeTab={wagonTab === 'mine' ? 'mine' : 'shop'} onTab={(k) => setWagonTab(k === 'mine' ? 'mine' : 'shop')}
      search={search} onSearch={setSearch}
    >
      {vis.length ? vis.map((w) => (
        <Card key={w.id || w.model} active={mine ? String(w.id) === String(selected) : w.model === selected}
          tag={mine && Number(w.is_default) === 1 ? 'Default' : null} name={w.name || w.model}
          sub={mine ? `Holds ${w.storage || 0}` : `Holds ${w.storage || 0}`}
          price={mine ? null : `${money(w.cash)}${w.gold ? ` or ${w.gold} gold` : ''}`}
          onClick={() => mine ? onSelectWagon(w.id) : onSelectWagonModel(w.model)} />
      )) : <div className="sf-empty">No wagons here.</div>}
    </Strip>
  )
}
