import { useRef, useEffect } from 'react'

// Transparent centre stage — the game renders the horse/wagon behind it.
export default function Stage({ onOrbit, onZoom, onPrev, onNext, showCycle = true }) {
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
    const dx = e.clientX - drag.current.x, dy = e.clientY - drag.current.y
    drag.current = { x: e.clientX, y: e.clientY }
    onOrbit(dx, dy)
  }
  const up = () => { drag.current = null }

  return (
    <section ref={ref} className="sc-stage" onMouseDown={down} onMouseMove={move} onMouseUp={up} onMouseLeave={up}>
      <div className="sc-stage-controls">
        <span className="sc-stage-hint">Hold and move to rotate</span>
        {showCycle ? (
          <div className="sc-stage-arrows">
            <button onClick={onPrev} aria-label="Previous">‹</button>
            <button onClick={onNext} aria-label="Next">›</button>
          </div>
        ) : null}
      </div>
    </section>
  )
}
