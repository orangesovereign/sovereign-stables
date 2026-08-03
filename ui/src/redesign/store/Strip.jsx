import { Icon, money } from '../kit.jsx'

const ALL = '__all__'

// Bottom catalog strip: tabs + filter + search + a horizontal row of cards.
export default function Strip(props) {
  const { view } = props
  if (view === 'owned') return <OwnedStrip {...props} />
  if (view === 'wagons') return <WagonStrip {...props} />
  if (view === 'tack') return <TackStrip {...props} />
  return <ShopStrip {...props} />
}

function Frame({ tabs, activeTab, onTab, filter, search, onSearch, children }) {
  return (
    <div className="sc-strip">
      <div className="sc-strip-head">
        <div className="sc-strip-tabs">
          {tabs.map((t) => <button key={t.key} className={activeTab === t.key ? 'is-active' : ''} onClick={() => onTab(t.key)}>{t.label}</button>)}
        </div>
        {filter}
        <label className="sc-strip-search"><Icon name="ledger-book" size={13} tone="#8a6a2f" /><input placeholder="Search…" value={search} onChange={(e) => onSearch(e.target.value)} /></label>
      </div>
      <div className="sc-strip-cards">{children}</div>
    </div>
  )
}

function Card({ active, glyph = 'horse-head', name, sub, price, status, onClick }) {
  return (
    <button className={`sc-card${active ? ' is-active' : ''}`} onClick={onClick}>
      <span className="sc-card-thumb"><Icon name={glyph} size={34} tone="#6f5a33" /></span>
      <span className="sc-card-body">
        <span className="sc-card-name">{name}</span>
        {sub ? <span className="sc-card-sub">{sub}</span> : null}
        {price ? <span className="sc-card-price">{price}</span> : null}
      </span>
      {status ? <span className={`sc-card-status sc-card-status--${status.tone}`}>{status.text}</span> : null}
    </button>
  )
}

function Select({ label, value, onChange, children }) {
  return <label className="sc-strip-filter"><span>{label}</span><select value={value} onChange={onChange}>{children}</select></label>
}

function ShopStrip({ rows, tab, setTab, breed, setBreed, selected, onChoose, search, setSearch }) {
  const tabRows = rows.filter((r) => (r.tier || 'stock') === tab)
  const breeds = [...new Set(tabRows.map((r) => r.breed || 'Unknown'))].sort()
  let vis = breed !== ALL ? tabRows.filter((r) => (r.breed || '') === breed) : tabRows
  if (search) vis = vis.filter((r) => (r.name || r.model || '').toLowerCase().includes(search.toLowerCase()))
  const filter = breeds.length > 1 ? (
    <Select label="Breed" value={breed} onChange={(e) => setBreed(e.target.value)}>
      <option value={ALL}>All breeds ({tabRows.length})</option>
      {breeds.map((b) => <option key={b} value={b}>{b}</option>)}
    </Select>
  ) : null
  return (
    <Frame tabs={[{ key: 'specialty', label: 'Specialty' }, { key: 'stock', label: 'Stock' }]} activeTab={tab} onTab={(k) => { setTab(k); setBreed(ALL) }} filter={filter} search={search} onSearch={setSearch}>
      {vis.length ? vis.map((r) => (
        <Card key={r.model} active={r.model === selected} name={r.name || r.model} sub={r.breed}
          price={r.locked ? 'Locked' : `${money(r.cash)}${r.gold ? ` · ${r.gold}g` : ''}`}
          status={r.locked ? { tone: 'lock', text: 'Job Locked' } : { tone: 'good', text: 'Available' }}
          onClick={() => !r.locked && onChoose(r.model)} />
      )) : <div className="sc-strip-empty">No horses of that breed here.</div>}
    </Frame>
  )
}

function OwnedStrip({ owned, selected, onSelectOwned, search, setSearch }) {
  let vis = owned
  if (search) vis = owned.filter((o) => (o.name || o.model || '').toLowerCase().includes(search.toLowerCase()))
  return (
    <Frame tabs={[{ key: 'owned', label: 'Owned Horses' }]} activeTab="owned" onTab={() => {}} search={search} onSearch={setSearch}>
      {vis.length ? vis.map((o) => (
        <Card key={o.id} active={String(o.id) === String(selected)} name={o.name || o.model} sub={o.model}
          status={Number(o.is_default) === 1 ? { tone: 'good', text: 'Active' } : { tone: 'info', text: 'Stored' }}
          onClick={() => onSelectOwned(o.id)} />
      )) : <div className="sc-strip-empty">You keep no horses yet.</div>}
    </Frame>
  )
}

function WagonStrip({ wagons, wagonRows, selected, onSelectWagon, onSelectWagonModel, search, setSearch, wagonTab, setWagonTab }) {
  const mine = wagonTab === 'mine'
  const list = mine ? wagons : wagonRows
  let vis = list
  if (search) vis = list.filter((w) => (w.name || w.model || '').toLowerCase().includes(search.toLowerCase()))
  return (
    <Frame tabs={[{ key: 'shop', label: 'For Sale' }, { key: 'mine', label: 'My Wagons' }]} activeTab={mine ? 'mine' : 'shop'} onTab={(k) => setWagonTab(k === 'mine' ? 'mine' : 'shop')} search={search} onSearch={setSearch}>
      {vis.length ? vis.map((w) => (
        <Card key={w.id || w.model} glyph="wagon" active={mine ? String(w.id) === String(selected) : w.model === selected}
          name={w.name || w.model} sub={`Holds ${w.storage || 0}`}
          price={mine ? null : `${money(w.cash)}${w.gold ? ` · ${w.gold}g` : ''}`}
          status={mine ? (Number(w.is_default) === 1 ? { tone: 'good', text: 'Default' } : { tone: 'info', text: 'Owned' }) : { tone: 'good', text: 'Available' }}
          onClick={() => mine ? onSelectWagon(w.id) : onSelectWagonModel(w.model)} />
      )) : <div className="sc-strip-empty">No wagons here.</div>}
    </Frame>
  )
}

function TackStrip({ tackCats, tackCatalog, tackCat, setTackCat, tackOwned, tackWorn, tackSel, onSelectTack, owned, tackHorseId, onSelectHorse, search, setSearch }) {
  const items = tackCatalog[tackCat] || []
  let vis = items
  if (search) vis = items.filter((t) => (t.label || t.id || '').toLowerCase().includes(search.toLowerCase()))
  const ownedIds = new Set((tackOwned || []).map((o) => o.item))
  const cat = (tackCats || []).find((c) => c.id === tackCat)
  const horseSelect = (owned || []).length ? (
    <Select label="Horse" value={tackHorseId || ''} onChange={(e) => onSelectHorse(Number(e.target.value))}>
      {(owned || []).map((o) => <option key={o.id} value={o.id}>{o.name || o.model}</option>)}
    </Select>
  ) : null
  return (
    <Frame tabs={(tackCats || []).map((c) => ({ key: c.id, label: c.label }))} activeTab={tackCat} onTab={setTackCat} filter={horseSelect} search={search} onSearch={setSearch}>
      {vis.length ? vis.map((t) => {
        const isOwned = ownedIds.has(t.id)
        const isWorn = cat && tackWorn[cat.slot] === t.id
        return (
          <Card key={t.id} glyph="saddle" active={t.id === tackSel} name={t.label || t.id} sub={cat ? cat.label : ''}
            price={isOwned ? null : money(t.cash)}
            status={isWorn ? { tone: 'good', text: 'Fitted' } : isOwned ? { tone: 'info', text: 'Owned' } : { tone: 'good', text: 'Available' }}
            onClick={() => onSelectTack(t.id)} />
        )
      }) : <div className="sc-strip-empty">The saddlery is still being stocked.</div>}
    </Frame>
  )
}
