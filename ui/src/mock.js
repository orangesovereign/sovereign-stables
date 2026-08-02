// Sample payload so the book renders in a plain browser (Vite dev/preview).
// Mirrors the server's Management.push shape. Never used inside RedM.
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
