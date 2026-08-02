import { useEffect, useRef } from 'react'

// True when running in a plain browser (Vite dev / preview) rather than RedM CEF.
export const isBrowser = typeof window === 'undefined' || typeof window.GetParentResourceName !== 'function'

const resourceName = () =>
  (typeof window !== 'undefined' && typeof window.GetParentResourceName === 'function')
    ? window.GetParentResourceName()
    : 'sovereign_stables'

// POST a NUI callback to the Lua side. Returns the parsed JSON (or null).
export async function fetchNui(event, data = {}) {
  if (isBrowser) {
    // eslint-disable-next-line no-console
    console.info(`[NUI mock] ${event}`, data)
    return null
  }
  try {
    const res = await fetch(`https://${resourceName()}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    })
    return await res.json()
  } catch {
    return null
  }
}

// Subscribe to a SendNUIMessage({ action, ... }) from Lua.
export function useNuiEvent(action, handler) {
  const saved = useRef(handler)
  saved.current = handler
  useEffect(() => {
    const listener = (e) => {
      const d = e.data || {}
      if (d.action === action) saved.current(d)
    }
    window.addEventListener('message', listener)
    return () => window.removeEventListener('message', listener)
  }, [action])
}
