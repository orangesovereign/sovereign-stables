import { useState } from 'react'
import { Icon, money } from './bits.jsx'
import overviewPages from './Overview.jsx'
import { fetchNui } from '../nui.js'

const NAV_ICON = {
  overview: 'horseshoe', trainer: 'horse-head', staff: 'people',
  breeding: 'fleur', ledger: 'ledger', settings: 'gear', admin: 'star',
}
const TITLES = {
  overview: 'Operations Overview', trainer: 'Trainer Panel', staff: 'Staff & Roles',
  breeding: 'Breeding Register', ledger: 'Society Ledger', settings: 'Stable Settings', admin: 'System Administration',
}
// Right-edge bookmark tabs (secondary views; Operations active for now).
const RIGHT_TABS = [
  { key: 'operations', label: 'Operations', icon: 'horseshoe' },
  { key: 'clients', label: 'Clients', icon: 'horse-head' },
  { key: 'breedings', label: 'Breedings', icon: 'rosette' },
  { key: 'finances', label: 'Finances', icon: 'coin' },
]

export default function ManagementBook({ panel, onClose }) {
  const [section, setSection] = useState('overview')
  const wallet = panel.wallet || {}

  const doAction = (action, payload) => fetchNui('manageAction', { action, payload })

  const pages = section === 'overview'
    ? overviewPages(panel.overview || {}, doAction)
    : {
        left: (
          <>
            <header className="mg2-page-title"><span className="mg2-flourish" /><h1>{TITLES[section] || 'Section'}</h1><span className="mg2-flourish mg2-flourish--r" /></header>
            <div className="mg-empty mg-soon">This page of the ledger is being drawn up.<br />The records behind it are already kept.</div>
          </>
        ),
        right: <div className="mg2-page-blank" />,
      }

  return (
    <main className="ss-ui">
      <section className="ss-book">
        <i className="ss-book-corner ss-book-corner--tl" /><i className="ss-book-corner ss-book-corner--tr" />
        <i className="ss-book-corner ss-book-corner--br" /><i className="ss-book-corner ss-book-corner--bl" />

        <header className="mg-hd">
          <span className="ss-icon ss-icon--sc-logo mg-hd-seal" style={{ '--ss-icon-size': '44px' }} />
          <span className="mg-brand"><b>Sovereign Stables</b><em>Stables &amp; Carriage Co.</em></span>
          <div className="ss-nine ss-cartouche mg-loc">{panel.stableName}{panel.county ? ` · ${panel.county}` : ''}</div>
          <span className="mg-who">{panel.playerName} — {panel.roleLabel}</span>
          <span className="mg2-wallet"><Icon name="coin" size={20} /><b>{money(wallet.cash)}</b></span>
          <span className="mg2-wallet"><Icon name="gold" size={20} /><b>{wallet.gold || 0}</b> Gold</span>
          <button className="ss-nine ss-btn-secondary ss-button mg-exit" onClick={onClose}>Exit</button>
        </header>

        <nav className="ss-left-rail" aria-label="Stable sections">
          {(panel.nav || []).map((n) => (
            <button key={n.key} className={`mg2-rail-btn${n.key === section ? ' is-active' : ''}`} title={n.label} onClick={() => setSection(n.key)}>
              <span className={`ss-nine ss-tab-rail mg2-rail-ico${n.key === section ? ' is-active' : ''}`}><Icon name={NAV_ICON[n.key] || 'diamond'} /></span>
              <em>{n.label}</em>
            </button>
          ))}
          <span className="ss-left-rail__fleur" />
        </nav>

        <div className="ss-pages">
          <article className="ss-page mg2-page mg2-page--l">{pages.left}</article>
          <article className="ss-page mg2-page mg2-page--r">{pages.right}</article>
          <nav className="ss-right-tabs" aria-label="Views">
            {RIGHT_TABS.map((t, i) => (
              <button key={t.key} className={`ss-nine ss-tab-book mg2-rtab${i === 0 ? ' is-active' : ''}`} title={t.label}>
                <Icon name={t.icon} size={22} /><em>{t.label}</em>
              </button>
            ))}
          </nav>
        </div>

        <span className="ss-ribbon-bookmark" />
        <span className="ss-nameplate" />
        <span className="ss-book-clasp" />
      </section>
    </main>
  )
}
