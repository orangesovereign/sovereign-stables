// Mock 'open' payload + owned/wagon data so the storefront renders in a browser.
// Mirrors client/storefront.lua. Never used inside RedM.
export const mockStore = {
  header: { stableLabel: 'Strawberry Stables', charName: 'Claudia Boatwright', job: 'Doctor', cash: 999028, gold: 6, collection: 'Specialty Collection' },
  catalog: {
    rows: [
      { model: 'A_C_Horse_Thoroughbred_BloodBay', name: 'Blood Bay Thoroughbred', breed: 'Thoroughbred', tier: 'specialty', cash: 750, gold: 6 },
      { model: 'A_C_Horse_Thoroughbred_ReverseDappleBlack', name: 'Reverse Dapple Black Thoroughbred', breed: 'Thoroughbred', tier: 'specialty', cash: 750, gold: 6 },
      { model: 'A_C_Horse_Arabian_RedChestnut', name: 'Red Chestnut Arabian', breed: 'Arabian', tier: 'specialty', cash: 750, gold: 6 },
      { model: 'A_C_Horse_Arabian_Grey', name: 'Grey Arabian', breed: 'Arabian', tier: 'specialty', cash: 750, gold: 6 },
      { model: 'A_C_Horse_Arabian_WarpedBrindle', name: 'Warped Brindle Arabian', breed: 'Arabian', tier: 'specialty', cash: 750, gold: 6 },
      { model: 'A_C_Horse_KentuckySaddle_ChestnutPinto', name: 'Chestnut Pinto', breed: 'Kentucky Saddler', tier: 'stock', cash: 250, gold: 2 },
      { model: 'A_C_Horse_KentuckySaddle_Black', name: 'Black Kentucky Saddler', breed: 'Kentucky Saddler', tier: 'stock', cash: 250, gold: 2 },
      { model: 'A_C_Horse_TennesseeWalker_FlaxenRoan', name: 'Grey Tennessee Walker', breed: 'Tennessee Walker', tier: 'stock', cash: 750, gold: 2 },
      { model: 'A_C_Horse_Morgan_Palomino', name: 'Palomino Morgan', breed: 'Morgan', tier: 'stock', cash: 250, gold: 2 },
      { model: 'A_C_Horse_SuffolkPunch_Sorrel', name: 'Sorrel Suffolk Punch', breed: 'Suffolk Punch', tier: 'stock', cash: 750, gold: 6 },
    ],
  },
  detail: {
    model: 'A_C_Horse_Thoroughbred_BloodBay', name: 'Blood Bay Thoroughbred', breed: 'Thoroughbred',
    sex: 'Gelding', age: 5, hands: 15.2, tier: 'specialty', cash: 750, gold: 6,
    lore: 'A dependable mount, sound of wind and limb.',
    stats: { health: 88, stamina: 83, speed: 83, acceleration: 78, turn: 73 },
    brokered: true,
  },
}

// Pushed after open in-game (mocked here for My Horses / Wagons previews).
export const mockOwned = {
  cap: 8,
  owned: [
    { id: 1, name: 'Riverbane', model: 'Missouri Fox Trotter', is_default: 1 },
    { id: 2, name: 'Deadwater', model: 'Turkoman' },
    { id: 3, name: 'Rustfang', model: 'Arabian' },
  ],
}
export const mockWagons = {
  cap: 4,
  owned: [{ id: 10, name: 'Old Faithful', model: 'Field Delivery Wagon', health: 84, storage: 40, is_default: 1 }],
  catalog: [
    { model: 'Field Delivery Wagon', name: 'Field Delivery Wagon', cash: 850, gold: 8, storage: 40 },
    { model: 'Farm Work Wagon', name: 'Farm Work Wagon', cash: 750, gold: 7, storage: 35 },
    { model: 'Passenger Coach', name: 'Passenger Coach', cash: 1250, gold: 12, storage: 20 },
  ],
}
