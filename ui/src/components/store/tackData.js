// The tack tint model mirrors client/components.lua: a named palette + three
// channels (0-254; 255 = "off"). These palettes match the vanilla TACK_PALETTES.
export const TACK_PALETTES = [
  { id: 'metaped_tint_combined_leather', label: 'Combined Leather' },
  { id: 'metaped_tint_leather', label: 'Leather' },
  { id: 'metaped_tint_combined', label: 'Combined' },
  { id: 'metaped_tint_horse_leather', label: 'Horse Leather' },
  { id: 'metaped_tint_generic', label: 'Generic' },
  { id: 'metaped_tint_metal', label: 'Metal' },
]

export const TINT_CHANNELS = [
  { key: 't0', label: 'Base' },
  { key: 't1', label: 'Accent' },
  { key: 't2', label: 'Detail' },
]

export const defaultTint = () => ({ palette: TACK_PALETTES[0].id, t0: 20, t1: 255, t2: 255 })
