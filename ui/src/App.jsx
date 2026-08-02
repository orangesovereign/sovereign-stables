import { useState, useEffect } from 'react'
import { useNuiEvent, fetchNui, isBrowser } from './nui.js'
import ManagementBook from './components/ManagementBook.jsx'
import Storefront from './components/Storefront.jsx'
import { mockPanel } from './mock.js'
import { mockStore } from './components/store/mockStore.js'

// The NUI is one of three states: closed, the management book, or the storefront.
// They map to distinct server messages and are never open at once.
// In-browser dev preview: ?ui=book shows the book, anything else shows the store.
const devView = isBrowser && new URLSearchParams(location.search).get('ui') === 'book' ? 'book' : (isBrowser ? 'store' : null)

export default function App() {
  const [book, setBook] = useState(devView === 'book' ? mockPanel : null)
  const [store, setStore] = useState(devView === 'store' ? mockStore : null)

  useNuiEvent('manage:open', (d) => { setStore(null); setBook(d.panel || null) })
  useNuiEvent('manage:close', () => setBook(null))
  useNuiEvent('open', (d) => { setBook(null); setStore(d) })       // storefront open
  useNuiEvent('close', () => setStore(null))

  const closeBook = () => { setBook(null); fetchNui('manageClose') }

  useEffect(() => {
    const onKey = (e) => { if (e.key === 'Escape' && book) closeBook() }
    window.addEventListener('keyup', onKey)
    return () => window.removeEventListener('keyup', onKey)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [book])

  if (book) return <ManagementBook panel={book} onClose={closeBook} />
  if (store) return <Storefront initial={store} />
  return null
}
