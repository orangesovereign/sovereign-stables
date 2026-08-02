import { useState, useEffect } from 'react'
import { useNuiEvent, fetchNui, isBrowser } from './nui.js'
import BookApp from './redesign/BookApp.jsx'
import Storefront from './components/Storefront.jsx'
import Customizer from './components/Customizer.jsx'
import { mockPanel } from './mock.js'
import { mockStore, mockCustom } from './components/store/mockStore.js'

// In-browser dev preview: ?ui=book|custom|store (default store).
const devView = isBrowser ? (new URLSearchParams(location.search).get('ui') || 'store') : null

export default function App() {
  const [book, setBook] = useState(devView === 'book' ? mockPanel : null)
  const [store, setStore] = useState(devView === 'store' ? mockStore : null)
  const [custom, setCustom] = useState(devView === 'custom' ? mockCustom : null)

  useNuiEvent('manage:open', (d) => { setStore(null); setBook(d.panel || null) })
  useNuiEvent('manage:close', () => setBook(null))
  useNuiEvent('open', (d) => { setBook(null); setStore(d) })       // storefront open
  useNuiEvent('close', () => setStore(null))
  useNuiEvent('custom:open', (d) => setCustom(d))                  // morph side panel

  const closeBook = () => { setBook(null); fetchNui('manageClose') }

  useEffect(() => {
    const onKey = (e) => {
      if (e.key !== 'Escape') return
      if (custom) { setCustom(null); fetchNui('morphClose') }
      else if (book) closeBook()
      else if (store) { setStore(null); fetchNui('close') }   // releases NUI focus
    }
    window.addEventListener('keyup', onKey)
    return () => window.removeEventListener('keyup', onKey)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [book, custom, store])

  // The customizer is a side panel (world stays visible), so it can overlay
  // whatever else is open — render them together.
  return (
    <>
      {book ? <BookApp panel={book} onClose={closeBook} /> : null}
      {store ? <Storefront initial={store} /> : null}
      {custom ? <Customizer data={custom} onClose={() => setCustom(null)} /> : null}
    </>
  )
}
