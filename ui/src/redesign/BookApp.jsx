import { useState } from 'react'
import { AppShell, FramedPage, PageHead } from './kit.jsx'
import OperationsScreen from './OperationsScreen.jsx'
import { fetchNui } from '../nui.js'

// Owner/Trainer/Admin management book (redesign). Shell + section routing.
// Only Operations is built so far; other sections show an honest placeholder.
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
  training: 'Training Board', clients: 'Clients', breeding: 'Breeding Register',
  staff: 'Staff & Roles', ledger: 'Society Ledger', settings: 'Stable Settings',
}

export default function BookApp({ panel, onClose }) {
  const [section, setSection] = useState('overview')
  const doAction = (action, payload) => fetchNui('manageAction', { action, payload })
  const location = panel.stableName + (panel.county ? ` · ${panel.county}` : '')

  return (
    <AppShell
      crest="crest-laurel" wordmark="Sovereign Stables"
      location={location} user={`${panel.playerName} · ${panel.roleLabel}`}
      wallet={panel.wallet} onExit={onClose}
      nav={NAV} active={section} onNav={setSection}
      seal={{ top: '1896', bottom: 'Sovereign County' }}
    >
      {section === 'overview'
        ? <OperationsScreen o={panel.overview || {}} onAction={doAction} />
        : (
          <FramedPage>
            <PageHead title={TITLES[section] || 'Section'} subtitle="This ledger page is being drawn up — the records behind it are already kept." />
            <div className="sc-empty">Coming next in the redesign build-out.</div>
          </FramedPage>
        )}
    </AppShell>
  )
}
