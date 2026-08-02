import { useState, useEffect } from 'react'
import { useNuiEvent, fetchNui, isBrowser } from './nui.js'
import ManagementBook from './components/ManagementBook.jsx'
import { mockPanel } from './mock.js'

export default function App() {
  // In a plain browser, preload the mock so the book is visible while building.
  // In RedM this starts null and opens only on the server's manage:open.
  const [panel, setPanel] = useState(isBrowser ? mockPanel : null)

  useNuiEvent('manage:open', (d) => setPanel(d.panel || null))
  useNuiEvent('manage:close', () => setPanel(null))

  const close = () => {
    setPanel(null)
    fetchNui('manageClose')
  }

  useEffect(() => {
    const onKey = (e) => { if (e.key === 'Escape' && panel) close() }
    window.addEventListener('keyup', onKey)
    return () => window.removeEventListener('keyup', onKey)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [panel])

  if (!panel) return null
  return <ManagementBook panel={panel} onClose={close} />
}
