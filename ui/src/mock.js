// Sample payload so the book renders in a plain browser (Vite dev/preview).
// Mirrors the server's Management.push shape. Never used inside RedM.
// Per-section dev data (browser preview only; in-game this arrives via manage:section).
export const mockSections = {
  training: {
    role: 'owner',
    counts: { raising: 4, training: 5, ready: 2, returned: 1, total: 11 },
    tiers: [{ id: 'basic', label: 'Basic Training' }, { id: 'advanced', label: 'Advanced Training' }, { id: 'raise', label: 'Colt Raising' }],
    trainers: [
      { charid: 1, name: 'Bebe Jewels', assigned: 4, training: 3, raising: 1 },
      { charid: 2, name: 'Jesse Ricketts', assigned: 3, training: 2, raising: 1 },
    ],
    roster: [
      { id: 1, horse: 'Riverbane', breed: 'Kentucky Saddler', client: 'Evelyn Shaw', tier: 'advanced', phase: 'training', trainer: 'Bebe Jewels', progress: 60, readyAt: Math.floor(Date.now() / 1000) + 172800 },
      { id: 2, horse: 'Copperwash', breed: 'Tennessee Walker', client: 'Silas Reed', tier: 'raise', phase: 'raising', trainer: 'Bebe Jewels', progress: 35, readyAt: Math.floor(Date.now() / 1000) + 600000 },
      { id: 3, horse: 'Rustfang', breed: 'Morgan', client: 'Mae Carter', tier: 'advanced', phase: 'ready', trainer: 'Jesse Ricketts', progress: 100, readyAt: Math.floor(Date.now() / 1000) },
      { id: 4, horse: 'Deadwater', breed: 'Turkoman', client: 'Nora Bell', tier: 'advanced', phase: 'training', trainer: 'Jesse Ricketts', progress: 25, readyAt: Math.floor(Date.now() / 1000) + 700000 },
    ],
  },
}

export const mockPanel = {
  stableId: 'loveland',
  stableName: 'Loveland Stables',
  county: 'Van Horn',
  role: 'owner',
  roleLabel: 'Owner',
  playerName: 'Tate Love',
  wallet: { cash: 999028, gold: 6 },
  nav: [
    { key: 'overview', label: 'Overview' },
    { key: 'trainer', label: 'Trainer Panel' },
    { key: 'staff', label: 'Staff & Roles' },
    { key: 'breeding', label: 'Breeding' },
    { key: 'ledger', label: 'Ledger' },
    { key: 'settings', label: 'Settings' },
  ],
  overview: {
    funds: { cash: 12450, gold: 0 },
    onDuty: 3,
    staffCount: 5,
    clientHorses: { raising: 4, training: 5, ready: 2, total: 9 },
    breeding: { active: 2 },
    staff: [
      { name: 'Tate Love', role: 'owner', grade: 3, on_duty: 1 },
      { name: 'Bebe Jewels', role: 'trainer', grade: 2, on_duty: 1 },
      { name: 'Jesse Ricketts', role: 'trainer', grade: 2, on_duty: 1 },
      { name: 'Elias Mercer', role: 'stablehand', grade: 1, on_duty: 0 },
    ],
    notes: 'Two client pickups pending.\nOne breeding result expected tomorrow.',
    pickup: [
      { id: 1, horse_name: 'Rustfang', client_name: 'Mae Carter' },
      { id: 2, horse_name: 'Ashen Crown', client_name: 'Isaac Cole' },
    ],
    ledger: [
      { description: 'Training payment · Riverbane', category: 'service', amount_cash: 240, created_at: '2026-07-30 10:00:00' },
      { description: 'Feed and medicine', category: 'supply', amount_cash: -145, created_at: '2026-07-30 09:00:00' },
      { description: 'Society deposit', category: 'deposit', amount_cash: 500, created_at: '2026-07-29 12:00:00' },
    ],
  },
}
