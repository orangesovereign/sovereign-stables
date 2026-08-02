import { useRef, useEffect } from 'react'

// The transparent centre stage — the game renders the horse/wagon behind it.
// Drag to orbit, wheel to zoom, bottom arrows to cycle.
export default function Stage({ onOrbit, onZoom, onPrev, onNext }) {
  const ref = useRef(null)
  const drag = useRef(null)

  useEffect(() => {
    const node = ref.current
    if (!node) return
    const onWheel = (e) => { e.preventDefault(); onZoom(e.deltaY) }
    node.addEventListener('wheel', onWheel, { passive: false })
    return () => node.removeEventListener('wheel', onWheel)
  }, [onZoom])

  const down = (e) => { drag.current = { x: e.clientX, y: e.clientY } }
  const move = (e) => {
    if (!drag.current) return
    const dx = e.clientX - drag.current.x
    const dy = e.clientY - drag.current.y
    drag.current = { x: e.clientX, y: e.clientY }
    onOrbit(dx, dy)
  }
  const up = () => { drag.current = null }

  return (
    <section ref={ref} className="sf-stage" onMouseDown={down} onMouseMove={move} onMouseUp={up} onMouseLeave={up}>
      <div className="sf-stage-controls">
        <span className="sf-stage-hint">Drag to inspect</span>
        <div className="sf-stage-arrows">
          <button onClick={onPrev} aria-label="Previous">‹</button>
          <span className="sf-stage-diamond" />
          <button onClick={onNext} aria-label="Next">›</button>
        </div>
      </div>
    </section>
  )
}
