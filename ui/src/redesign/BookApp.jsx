import { useState, useEffect } from 'react'
import { AppShell, FramedPage, PageHead } from './kit.jsx'
import OperationsScreen from './OperationsScreen.jsx'
import TrainingScreen from './TrainingScreen.jsx'
import { fetchNui, useNuiEvent, isBrowser } from '../nui.js'
import { mockSections } from '../mock.js'

// Owner/Trainer/Admin management book (redesign). Shell + section routing.
const NAV = [
  { key: 'overview', label: 'Overview', icon: 'horseshoe' },
  { key: 'training', label: 'Training', icon: 'horse-run' },
  { key: 'clients', label: 'Clients', icon: 'people' },
  { key: 'breeding', label: 'Breeding', icon: 'breeding-mark' },
  { key: 'staff', label: 'Staff', icon: 'person-detective' },
  { key: 'ledger', label: 'Ledger', icon: 'ledger-book' },
  { key: 'settings', label: 'Settings', icon: 'settings-gear' },
]
const TITLES = {
  clients: 'Clients', breeding: 'Breeding Register',
  staff: 'Staff & Roles', ledger: 'Society Ledger', settings: 'Stable Settings',
}

export default function BookApp({ panel, onClose }) {
  const [section, setSection] = useState('overview')
  const [sections, setSections] = useState(isBrowser ? mockSections : {})
  const [toast, setToast] = useState(null)
  const canManage = ['owner', 'admin', 'trainer'].includes(panel.role)

  useNuiEvent('manage:section', (d) => setSections((prev) => ({ ...prev, [d.section]: { ...(d.data || {}), role: d.role } })))
  useNuiEvent('manage:result', (d) => {
    if (d.result && d.result.message) { setToast({ ok: d.result.ok, msg: d.result.message }) }
    if (section !== 'overview') fetchNui('requestSection', { section })
  })

  const navTo = (key) => {
    setSection(key)
    if (key !== 'overview') fetchNui('requestSection', { section: key })
  }
  const doAction = (action, payload) => fetchNui('manageAction', { action, payload })

  useEffect(() => {
    if (!toast) return
    const t = setTimeout(() => setToast(null), 3200)
    return () => clearTimeout(t)
  }, [toast])

  const location = panel.stableName + (panel.county ? ` · ${panel.county}` : '')
  const secData = sections[section]

  return (
    <AppShell
      crest="crest-laurel" wordmark="Sovereign Stables"
      location={location} user={`${panel.playerName} · ${panel.roleLabel}`}
      wallet={panel.wallet} onExit={onClose}
      nav={NAV} active={section} onNav={navTo}
      seal={{ top: '1896', bottom: 'Sovereign County' }}
    >
      {section === 'overview' && <OperationsScreen o={panel.overview || {}} onAction={doAction} />}
      {section === 'training' && <TrainingScreen data={secData || {}} onAction={doAction} canManage={canManage} />}
      {!['overview', 'training'].includes(section) && (
        <FramedPage>
          <PageHead title={TITLES[section] || 'Section'} subtitle="This ledger page is being drawn up — the records behind it are already kept." />
          <div className="sc-empty">Coming next in the redesign build-out.</div>
        </FramedPage>
      )}

      {toast && <div className={`sc-toast${toast.ok === false ? ' sc-toast--bad' : ''}`}>{toast.msg}</div>}
    </AppShell>
  )
}
