--[[=====================================================================
  SOVEREIGN STABLES · TACK & COMPONENTS
  ---------------------------------------------------------------------
  Buyable horse equipment/appearance components. Component hashes come from
  the game; this catalog just names, prices and groups them.

  TACK BELONGS TO THE PLAYER, NOT THE HORSE (owner ruling): buy a saddle once
  and it goes on whichever horse you ride. Ownership lives in `sovereign_tack`
  (keyed by charid); what a given horse is WEARING lives in that horse's
  `components` column. Two questions, two places.

  All ten categories are stocked — 66 families, 479 component hashes. See the
  SOURCE & LICENCE note above Config.Tack and docs/CREDITS.md before editing.
=====================================================================]]--

Config = Config or {}

-- Categories the customizer will present. `slot` maps to how it is applied.
Config.TackCategories = {
    { id = 'saddle',     label = 'Saddles',     slot = 'saddle'     },
    { id = 'saddlebags', label = 'Saddlebags',  slot = 'saddlebags' },
    { id = 'horn',       label = 'Saddle Horns', slot = 'horn'      },
    { id = 'stirrups',   label = 'Stirrups',    slot = 'stirrups'   },
    { id = 'blanket',    label = 'Blankets',    slot = 'blanket'    },
    { id = 'bedroll',    label = 'Bedrolls',    slot = 'bedroll'    },
    { id = 'lantern',    label = 'Lanterns',    slot = 'lantern'    },
    { id = 'mask',       label = 'Masks',       slot = 'mask'       },
    { id = 'mane',       label = 'Manes',       slot = 'mane'       },
    { id = 'tail',       label = 'Tails',       slot = 'tail'       },
}

--------------------------------------------------------------------------------
-- TACK OWNERSHIP RULES  (owner ruling 2026-07-15)
--------------------------------------------------------------------------------
-- Tack belongs to the PLAYER, not the horse. Buy a saddle once and it goes on
-- whichever horse you ride. When a horse dies, its tack comes back to you (the
-- cargo it was carrying does not).
-- ⚖️ RULED 2026-07-15 (1.4 ledger Q1). I had read "pay only the difference" as
-- a trade-in BETWEEN pieces — swap a $40 saddle for a $60 one, pay $20, lose
-- the $40. That was wrong. The owner's actual meaning:
--
--     "This would apply to CUSTOMIZATIONS of a tack item you already own.
--      Color changes, Saddle Bag additions, Bed Rolls etc."
--
-- So the difference is charged when you CHANGE A PIECE YOU OWN — retint your
-- saddle, add a bedroll to it — not when you buy a different saddle. Two
-- distinct saddles are two things you own (a collection); one saddle in two
-- colours is one thing you adjusted.
--
-- That reading is also what the game models: in RDR2 bedrolls, saddlebags,
-- lanterns and horns hang off the SADDLE, and saddles carry tint slots — which
-- is exactly the shape of sirevlc's open TACK.lua (TINTA/TINTB/TINTC +
-- CUSTOMIZABLE per item).
Config.TackRules = {
    -- You may never be charged twice for a piece you already own. Also enforced
    -- by a UNIQUE key in sql/install.sql, so no code path can get this wrong.
    neverRebuyOwned = true,

    -- COLLECTION, not trade-in. Buying a second saddle is buying a second
    -- saddle: full price, and you keep both. A work saddle and a good saddle
    -- are two pieces of tack, and you own a stable of different horses to put
    -- them on. (Was `true` in the first 1.4 build — corrected by the Q1 ruling.)
    tradeInWithinSlot = false,

    -- ⏳ THE ACTUAL "pay only the difference" RULE LIVES IN CUSTOMIZATION —
    -- retinting a saddle you own, adding a bedroll to it. That system is
    -- S14/S15 and lands in PHASE 2; there is nothing to charge a difference on
    -- until tack items have options to change. When it lands, the price of a
    -- customization is (new option − what you already paid for that slot),
    -- floored at zero. Left here so the rule isn't lost between phases.
    customizationChargesDifference = true,

    -- Never refund on a downgrade — the difference floors at zero.
    allowDowngradeRefund = false,
}

--------------------------------------------------------------------------------
-- THE CATALOG
--------------------------------------------------------------------------------
-- Item shape:
--   ['item_id'] = { label = 'Shown to players',
--                   price   = { cash = 40, gold = 0 },
--                   hash    = 0x106961A8,      -- the DEFAULT look
--                   variants = { 0x..., ... }, -- every colourway of this piece
--                   jobs = 'all', stables = 'all' }
--
-- `hash` is the metaped component hash, applied at runtime via the pipeline the
-- Phase 1 spike proved (0xD3A7B003ED343FD9 + UpdatePedVariation 0xCC8CA3E88256E58F).
-- Components are NOT breed-locked (spike result A8), so ONE universal list
-- serves every horse — there are no per-breed tables to maintain.
--
-- WHAT `variants` IS, AND WHY IT MATTERS
--   Each entry is a FAMILY of the same piece in different colours/tints. You buy
--   the family; switching between its variants is a CUSTOMISATION, which is
--   exactly the owner's Q1 ruling — "adjust a tack and you pay only the
--   difference... colour changes". Nothing reads `variants` yet: the customiser
--   is S14/S15 in PHASE 2. Until then every piece wears variant #1 (`hash`).
--   The data is here so Phase 2 is a UI job, not another archaeology job.
--
-- SOURCE & LICENCE — read before editing
--   These hashes come from vorp_stables' `data.lua` (VORPCORE/vorp_stables-lua),
--   which is MIT licensed. See docs/CREDITS.md for the required notice. They are
--   RDR2's own component ids — facts about the game, not authored content — and
--   independently corroborated: all ELEVEN hashes our Phase 1 spike applied to a
--   live horse and watched change appear here as the first variant of their
--   family (e.g. 0x106961A8 = Lumley McClelland). That agreement is why this
--   table is trusted rather than merely copied.
--
-- ⚠️ PRICES ARE PLACEHOLDERS pending the economy pass, same as horses/wagons.
--   They are DERIVED, not invented: vorp ships a relative price multiplier per
--   family, and we multiply it by a per-category base. So the *ratios* are real
--   (Tapaderos stirrups cost 3x Belled Oxbow) even though the absolute numbers
--   are not settled. Bases used: saddle 15 - saddlebags 25 - horn 4 -
--   stirrups 10 - blanket 15 - bedroll 20 - lantern 25 - mask 15 - mane 50 -
--   tail 50. Lanterns and masks carry vorp's 999 marker, meaning "not normally
--   sold" — they are stocked here anyway and priced by us; say if they should
--   be pulled or job-locked.
Config.Tack = {

    saddle = {
        ['saddle_lumley_mcclelland'] = { label = 'Lumley McClelland', price = { cash = 40.35 },
            hash = 0x106961A8,
            variants = { 0x106961A8, 0x150D0DAA, 0x17153A45, 0x1C14443F, 0x1F7C4C5, 0x2E4668A3, 
                          0x2ECD9E70, 0x3D0C3AED, 0x3F9F62CE, 0x4B372288, 0x5D717C9, 0x78F07DFA, 
                          0xC04FE429, 0xD97573C1, 0xDE47F51, 0xEB1139AB, 0xF3BEA853, 0xF94D5623 } },
        ['saddle_stenger_roping'] = { label = 'Stenger Roping', price = { cash = 37.50 },
            hash = 0x21E8DDFA,
            variants = { 0x21E8DDFA, 0x2E216DBC, 0x2F8C7941, 0x5A9E4F6C, 0x60DE5335, 0x6384D886, 
                          0x64CEC6DF, 0x694DE418, 0x76887E89, 0x8DABACD7, 0x90489DD2, 0x9E0C3959, 
                          0xB61F0668, 0xBC52F5E6, 0xC7D58D0B, 0xD61B2996, 0xDA84CF33, 0xFD4E14C5 } },
        ['saddle_kneller_mother_hubbard'] = { label = 'Kneller Mother Hubbard', price = { cash = 36.00 },
            hash = 0x14168240,
            variants = { 0x14168240, 0x2844E292, 0x3E949A74, 0x5B6390D9, 0x5BBC54C3, 0x6D403492, 
                          0x70BB7EC1, 0x7FD859C2, 0x87F421F7, 0x8D163776, 0x8D9D754C, 0x9CD94BC1, 
                          0xBA6A921E, 0xBB335077, 0xC1AF1568, 0xCE8C2F22, 0xD11CBF82, 0xF36A78DE } },
        ['saddle_lumley_ranch_cutter'] = { label = 'Lumley Ranch Cutter', price = { cash = 34.50 },
            hash = 0x6FEABF89,
            variants = { 0x6FEABF89, 0x7A23C686, 0x7C19770A, 0x7C2C580C, 0x88C363C5, 0x8DD09A7C, 
                          0x93DA8768, 0x9B1C95F8, 0x9FF23EBF, 0xA1154105, 0xA21923E5, 0xA8DB3175, 
                          0xB357E58A, 0xC10B5450, 0xD2C8F7CB, 0xE5B31D9F, 0xF373B920, 0xFC6AF7AF } },
        ['saddle_kneller_dakota'] = { label = 'Kneller Dakota', price = { cash = 33.00 },
            hash = 0x15FB6791,
            variants = { 0x15FB6791, 0x3827D232, 0x40C53D24, 0x47D2CB3F, 0x9533FA8E, 0xA7AC9F7B, 
                          0xB7B33F88, 0xB9BE555D, 0xC7FC601A, 0xDA36048D, 0xE039FC0F, 0xE36C8274, 
                          0xE52BAC3F, 0xEC882931, 0xF2F0045, 0xF4B14B4A, 0xF687A8AA } },
        ['saddle_gerden_vaquero'] = { label = 'Gerden Vaquero', price = { cash = 32.25 },
            hash = 0x189F7005,
            variants = { 0x189F7005, 0x1D0BF8F2, 0x1EC65C0, 0x219D85E2, 0x4C1A5ADB, 0x522CCED, 
                          0x5546EB7A, 0x5B45F932, 0x7092A211, 0x7DBB3E1C, 0x8E64DDB5, 0x8FFCF06B, 
                          0xA39D34E, 0xAD4A6355, 0xBE703DF7, 0xBFD09512, 0xC0C04297, 0xD2FA64BC, 
                          0xE5510BB8, 0xE6488B58, 0xF1BAA60D, 0xF7682D97 } },
        ['saddle_gerden_trail_saddle'] = { label = 'Gerden Trail Saddle', price = { cash = 31.50 },
            hash = 0x1EE21489,
            variants = { 0x1EE21489, 0x20359E53, 0x24F24446, 0x2E3F3A62, 0x306806F, 0x335DC49F, 
                          0x534A7D59, 0x660B29F9, 0x6C622F8C, 0x70C65BED, 0x8E22730C, 0x93B7057, 
                          0xC454830C, 0xD6BF27E1, 0xD7FC86BF, 0xE9B7AA35, 0xF4118E4, 0xFCE1D7A4 } },
        ['saddle_alligator_ranch_cutter'] = { label = 'Alligator Ranch Cutter', price = { cash = 30.00 },
            hash = 0xB5802A5F,
            variants = { 0xB5802A5F } },
        ['saddle_panther_trail'] = { label = 'Panther Trail', price = { cash = 30.00 },
            hash = 0xC76C46D9,
            variants = { 0xC76C46D9 } },
        ['saddle_boar_mother_hubbard'] = { label = 'Boar Mother Hubbard', price = { cash = 30.00 },
            hash = 0xD225CCA0,
            variants = { 0xD225CCA0 } },
        ['saddle_bear_dakota'] = { label = 'Bear Dakota', price = { cash = 30.00 },
            hash = 0xDE5A2905,
            variants = { 0xDE5A2905 } },
        ['saddle_beaver_roping_castor'] = { label = 'Beaver Roping Castor', price = { cash = 28.50 },
            hash = 0x2BEA8ED4,
            variants = { 0x2BEA8ED4 } },
        ['saddle_rattlesnake_vaquero'] = { label = 'Rattlesnake Vaquero', price = { cash = 16.50 },
            hash = 0x7D795D72,
            variants = { 0x7D795D72 } },
        ['saddle_cougar_mcclelland'] = { label = 'Cougar McClelland', price = { cash = 15.00 },
            hash = 0x353FC03C,
            variants = { 0x353FC03C } },
    },

    saddlebags = {
        ['saddlebags_standard'] = { label = 'Standard', price = { cash = 25.00 },
            hash = 0x1D4EDB88,
            variants = { 0x1D4EDB88, 0x20AA8620, 0x293E17B3, 0x2AEFF6CA, 0x5277E9BA, 0x577EF434, 
                          0x8BE10F93, 0x9D593283, 0xAE110017, 0xB4F40DD9, 0xC019F804, 0xC05AA4AA, 
                          0xD048C482, 0xE2ADE94C, 0xE4108D59, 0xE57042B4, 0xE893DFD, 0xEEC77E72, 
                          0xF0C30271, 0xF8FB69CA } },
    },

    horn = {
        ['horn_steel_diablo'] = { label = 'Steel Diablo', price = { cash = 12.00 },
            hash = 0x9AD2AA40,
            variants = { 0x9AD2AA40 } },
        ['horn_steel_diez_corona'] = { label = 'Steel Diez Corona', price = { cash = 11.60 },
            hash = 0xED0BCEB5,
            variants = { 0xED0BCEB5 } },
        ['horn_birch_torquemada'] = { label = 'Birch Torquemada', price = { cash = 10.76 },
            hash = 0xF8CAE723,
            variants = { 0xF8CAE723 } },
        ['horn_brass_eagle'] = { label = 'Brass Eagle', price = { cash = 10.56 },
            hash = 0x34135CC3,
            variants = { 0x34135CC3 } },
        ['horn_pine_dally'] = { label = 'Pine Dally', price = { cash = 10.20 },
            hash = 0xDBE6AC3B,
            variants = { 0xDBE6AC3B } },
        ['horn_redemption_sindewinder'] = { label = 'Redemption Sindewinder', price = { cash = 10.00 },
            hash = 0xE1B1B8F1,
            variants = { 0xE1B1B8F1 } },
        ['horn_steel_dally'] = { label = 'Steel Dally', price = { cash = 9.20 },
            hash = 0xE1DC3856,
            variants = { 0xE1DC3856 } },
        ['horn_maple_torquemada'] = { label = 'Maple Torquemada', price = { cash = 8.48 },
            hash = 0x333CDC06,
            variants = { 0x333CDC06 } },
        ['horn_maple_duck_bill'] = { label = 'Maple Duck Bill', price = { cash = 8.48 },
            hash = 0xC6C381F5,
            variants = { 0xC6C381F5 } },
        ['horn_aspen_thick_neck'] = { label = 'Aspen Thick Neck', price = { cash = 8.12 },
            hash = 0xF826E4EB,
            variants = { 0xF826E4EB } },
        ['horn_birch_dally'] = { label = 'Birch Dally', price = { cash = 8.00 },
            hash = 0x107D9598,
            variants = { 0x107D9598, 0x2A28C8BE } },
        ['horn_aspen_duck_bill'] = { label = 'Aspen Duck Bill', price = { cash = 7.96 },
            hash = 0x3E40711D,
            variants = { 0x3E40711D } },
        ['horn_birch_wide_belly'] = { label = 'Birch Wide Belly', price = { cash = 6.00 },
            hash = 0xF09C56EE,
            variants = { 0xF09C56EE } },
    },

    stirrups = {
        ['stirrups_tapaderos'] = { label = 'Tapaderos', price = { cash = 15.00 },
            hash = 0xBDF19F85,
            variants = { 0xBDF19F85 } },
        ['stirrups_barroque'] = { label = 'Barroque', price = { cash = 13.00 },
            hash = 0xCB9A3AD6,
            variants = { 0xCB9A3AD6 } },
        ['stirrups_fillies'] = { label = 'Fillies', price = { cash = 12.00 },
            hash = 0x8246282F,
            variants = { 0x8246282F } },
        ['stirrups_slim_line_iron'] = { label = 'Slim-line Iron', price = { cash = 11.50 },
            hash = 0xE73FF221,
            variants = { 0xE73FF221 } },
        ['stirrups_safety'] = { label = 'Safety', price = { cash = 10.00 },
            hash = 0x3B3AB08,
            variants = { 0x3B3AB08 } },
        ['stirrups_hooded'] = { label = 'Hooded', price = { cash = 10.00 },
            hash = 0xD8AE54FE,
            variants = { 0xD8AE54FE } },
        ['stirrups_slim_line'] = { label = 'Slim-line', price = { cash = 9.90 },
            hash = 0x75178DD2,
            variants = { 0x75178DD2 } },
        ['stirrups_oxbow'] = { label = 'Oxbow', price = { cash = 8.00 },
            hash = 0x9EE8E174,
            variants = { 0x9EE8E174 } },
        ['stirrups_bell'] = { label = 'Bell', price = { cash = 6.90 },
            hash = 0x8D0BC7DA,
            variants = { 0x8D0BC7DA } },
        ['stirrups_deep_roper'] = { label = 'Deep Roper', price = { cash = 6.00 },
            hash = 0x67AF7302,
            variants = { 0x67AF7302 } },
        ['stirrups_belled_oxbow'] = { label = 'Belled Oxbow', price = { cash = 5.00 },
            hash = 0x587DD49F,
            variants = { 0x587DD49F } },
    },

    blanket = {
        ['blanket_diablo'] = { label = 'Diablo', price = { cash = 30.00 },
            hash = 0x7951D487,
            variants = { 0x7951D487, 0xA3D5298D, 0xEDCB3D78 } },
        ['blanket_millesani'] = { label = 'Millesani', price = { cash = 26.25 },
            hash = 0x5894FB24,
            variants = { 0x5894FB24, 0x9E468686, 0xAB302059, 0xD9E17DBB, 0xE32A1050 } },
        ['blanket_owanjila'] = { label = 'Owanjila', price = { cash = 21.00 },
            hash = 0x53B325B7,
            variants = { 0x53B325B7, 0x7D637917, 0x90A31F96, 0x9AD633FC, 0xB19B4519, 0xC073E2CA, 
                          0xC7688D20 } },
        ['blanket_cotorra'] = { label = 'Cotorra', price = { cash = 16.50 },
            hash = 0x508B80B9,
            variants = { 0x508B80B9, 0x67CAAF37, 0xEBB4B70D } },
        ['blanket_iron_cloud'] = { label = 'Iron Cloud', price = { cash = 15.75 },
            hash = 0xC097E12C,
            variants = { 0xC097E12C, 0xCDD2FB96, 0xD333865B, 0xE409A807, 0xF6484C84 } },
        ['blanket_siltwater'] = { label = 'Siltwater', price = { cash = 15.00 },
            hash = 0x127E0412,
            variants = { 0x127E0412, 0x20D4A0BF, 0x2A6D33E8, 0xDC87A9F, 0xFFB1DE72 } },
        ['blanket_roanoke_ridge'] = { label = 'Roanoke Ridge', price = { cash = 15.00 },
            hash = 0x19C5E80C,
            variants = { 0x19C5E80C, 0x3278996D, 0x3D34F3, 0x64BE7DF8, 0xEC040C89 } },
        ['blanket_rio_bravo'] = { label = 'Rio Bravo', price = { cash = 15.00 },
            hash = 0x269583CA,
            variants = { 0x269583CA, 0x3973A986, 0x4A294AF1, 0x97EBE669, 0xED0190A3 } },
        ['blanket_cholla_springs'] = { label = 'Cholla Springs', price = { cash = 15.00 },
            hash = 0x342916F3,
            variants = { 0x342916F3, 0x6B2084E5, 0x78FB209A, 0x8FAD4DFE, 0x9DE0EA65 } },
        ['blanket_nekoti_rock'] = { label = 'Nekoti Rock', price = { cash = 15.00 },
            hash = 0x3BA0D76D,
            variants = { 0x3BA0D76D, 0x4BF1F80F, 0x5F0F9E4A, 0x71DFC3EA, 0xF506CA32 } },
        ['blanket_manzanita'] = { label = 'Manzanita', price = { cash = 15.00 },
            hash = 0x4655E362,
            variants = { 0x4655E362, 0xAD283105, 0xC2EF5C93, 0xC8A467FD, 0xDBEF0E96 } },
        ['blanket_bayou'] = { label = 'Bayou', price = { cash = 15.00 },
            hash = 0x533A022A,
            variants = { 0x533A022A, 0x823A602A, 0xB0F7BDA4, 0xBBF05395, 0xFDC3D6D3 } },
    },

    bedroll = {
        ['bedroll_padded_wool'] = { label = 'Padded Wool', price = { cash = 15.40 },
            hash = 0x45FEA6D8,
            variants = { 0x45FEA6D8, 0x69B29DC5, 0x72FCB059, 0x7C8A149A, 0x84E5AFA, 0x8DD7B735, 
                          0x98214B1C, 0x9D868568, 0xA643680C, 0xD258EF10 } },
        ['bedroll_wool'] = { label = 'Wool', price = { cash = 10.00 },
            hash = 0x12F0DF9F,
            variants = { 0x12F0DF9F, 0x18BB6B30, 0x1B43F045, 0x55A0E4FE, 0x69B21ADD, 0x7B55D476, 
                          0x8C9F7709, 0x9FD99D7D, 0xAC1F34C, 0xD8258E14, 0xFFB0391E } },
        ['bedroll_canvas'] = { label = 'Canvas', price = { cash = 6.00 },
            hash = 0x27543EBB,
            variants = { 0x27543EBB, 0x36BEDD90, 0x4B7E0712, 0x73D157B4, 0x841C784A, 0xA1FD8B43, 
                          0xB4532FEE, 0xBC664014, 0xD020E789 } },
    },

    lantern = {
        ['lantern_normal'] = { label = 'Normal', price = { cash = 25.00 },
            hash = 0x635E387C,   -- vorp marks this 999 = not normally sold; priced by us
            variants = { 0x635E387C } },
    },

    mask = {
        ['mask_all'] = { label = 'All', price = { cash = 15.00 },
            hash = 0xFA5B72BB,   -- vorp marks this 999 = not normally sold; priced by us
            variants = { 0xFA5B72BB, 0xF606EC4A, 0xEEF65F11, 0xEC10D626, 0xE3278C28, 0xDDCDB9A0, 
                          0xD70C73EA, 0xC907FCA9, 0xC70D8F40, 0xBD887906, 0xB567EBF5, 0xB395D1C5, 
                          0xB0395F88, 0xA45049C6, 0x9DB125FC, 0x9A11B219, 0x9946F874, 0x90A62272, 
                          0x8DCC1CBE, 0x8DB38601, 0x8C471684, 0x872A0C5A, 0x7BFA791B, 0x7A773AC1, 
                          0x702A4AF3, 0x6B355791, 0x69CD996E, 0x68FB97DE, 0x68DB4FAD, 0x62C5B02A, 
                          0x61BEAE08, 0x4E22622C, 0x4C8C83A4, 0x406FC6C7, 0x30044BAC, 0x226B2F76, 
                          0x13AC6E51, 0x08A78F53, 0xF0ED62FF, 0xF17728C7 } },
    },

    mane = {
        ['mane_dreadlocks'] = { label = 'Dreadlocks', price = { cash = 5.00 },
            hash = 0x1FDC6D0F,
            variants = { 0x1FDC6D0F, 0x241D7FBD, 0x3A7C2C86, 0x483AC803, 0x512377B, 0x6038F7FF, 
                          0x6D9412B5, 0x83563E39, 0x96FE6589, 0x9A640A3, 0xB2FB934B, 0xC929BFA7, 
                          0xCDC9C8E7, 0xDCF5321, 0xE02377D6, 0xFF17AB82, 0xFFF3B76A } },
        ['mane_braided'] = { label = 'Braided', price = { cash = 5.00 },
            hash = 0x25627B98,
            variants = { 0x25627B98, 0x2E378E8A, 0x3BFE2A17, 0x4FCC51B3, 0x54A3CB0, 0x5D596CCD, 
                          0x6F4510C4, 0x7D902D5A, 0x92B2579E, 0x97105EF6, 0xA0F4F423, 0xA64BFD6D, 
                          0xB13D134B, 0xCF434F57, 0xD4E65BE5, 0xDC62E996, 0xE9FE04D0 } },
        ['mane_short'] = { label = 'Short', price = { cash = 5.00 },
            hash = 0x18199F48,
            variants = { 0x18199F48, 0x354F6B7, 0x3F1FEE4C, 0x4F148D45, 0x52DC15C8, 0x5DE62AE8, 
                          0x648A3924, 0x7098D141, 0x86457C9A, 0x960C1B33, 0x99F5A3FA, 0xA4E1B8DE, 
                          0xABA8475F, 0xB288D42C, 0xBD7B6B05, 0xC15371C1, 0xF2E555D8 } },
        ['mane_regular'] = { label = 'Regular', price = { cash = 5.00 },
            hash = 0x130E341A,
            variants = { 0x130E341A, 0x16923E26, 0x1A5A45B6, 0x2FCAF0CB, 0x419D9470, 0x41EA9196, 
                          0x5445B9C0, 0x5ED14B9F, 0x66215D77, 0x817B10F6, 0xA7A4DD49, 0xB5F379E6, 
                          0xD894BF28, 0xE1435081, 0xEA46E28C, 0xFF020F3A } },
        ['mane_long'] = { label = 'Long', price = { cash = 5.00 },
            hash = 0x235DBF1,
            variants = { 0x235DBF1, 0x446A6F01, 0x5F0395A3, 0x5FE29755, 0x632F2B7, 0x6CB9310E, 
                          0x838E5EB8, 0x94F58186, 0x97D095F4, 0xA193A97A, 0xAA3FAC1A, 0xAFB7C24, 
                          0xB881489D, 0xC8646863, 0xC9D16B31, 0xE0BC27A6, 0xFC74DF3B } },
    },

    tail = {
        ['tail_dreadlocks'] = { label = 'Dreadlocks', price = { cash = 5.00 },
            hash = 0x12DBBBAF,
            variants = { 0x12DBBBAF, 0x3B8A8D0C, 0x4951F22, 0x49CD2991, 0x607956E9, 0x6DB6F164, 
                          0x7522834F, 0x84269E43, 0x876B27E0, 0x88A2AA53, 0x96EDC3D1, 0x972AC447, 
                          0xA8A4673A, 0xBCD412B1, 0xCE62B5CE, 0xDD9F5447, 0xEFA67855 } },
        ['tail_braid'] = { label = 'Braid', price = { cash = 5.00 },
            hash = 0x17EB79D3,
            variants = { 0x17EB79D3, 0x1A3B721B, 0x25B51566, 0x33E7B1CB, 0x4124CC49, 0x4F5268A4, 
                          0xA3DA055A, 0xA62C9657, 0xA7438C29, 0xB4AB3354, 0xC2FA4FF2, 0xC74FCC45, 
                          0xD143E02D, 0xEBC7218B, 0xED0397AC, 0xF6B0AB06 } },
        ['tail_short'] = { label = 'Short', price = { cash = 5.00 },
            hash = 0x1BB5EAA1,
            variants = { 0x1BB5EAA1, 0x1E9A18C2, 0x2E753874, 0x3B27D1DD, 0x3D212D77, 0x5062FC53, 
                          0x508AD44A, 0x543203ED, 0x5F4871C5, 0x695B2E3F, 0x75C4C716, 0x82DB38EE, 
                          0x84ADE4E4, 0xAFB492C, 0xC0AF3489, 0xDCE41557, 0xDDB48566, 0xEAEAB164 } },
        ['tail_regular'] = { label = 'Regular', price = { cash = 5.00 },
            hash = 0x383E86F3,
            variants = { 0x383E86F3, 0x3D1F13D4, 0x4B51B039, 0x574BC82D, 0x66C266F, 0x69756C80, 
                          0x740701A3, 0x7A248ABE, 0x84D6B90, 0x894C290D, 0x9CB1CFD8, 0xA0775A83, 
                          0xA4F0E056, 0xB244FE1E, 0xCDFF359A, 0xE38F5D96, 0xEAA5EEE7, 0xED787168 } },
        ['tail_long'] = { label = 'Long', price = { cash = 5.00 },
            hash = 0x1F7A99EA,
            variants = { 0x1F7A99EA, 0x30603BB5, 0x3AE050B5, 0x5D7FA043, 0x607E6DD, 0x73073A2, 
                          0x810A5CE0, 0xB4374DB1, 0xC304EB4C, 0xD7D68A7B, 0xD9288D47, 0xD9EA1916, 
                          0xEABBBAB9, 0xF4294320, 0xF4A3443C, 0xF867D611 } },
    },
}

-- Horseshoe upgrade track [S12]. maxLevel caps upgrades; each level has a price/effect.
Config.Horseshoes = {
    enabled  = true,
    maxLevel = 3,
    levels   = {
        -- [1] = { label = 'Iron Shoes',  price = { cash = 25 },  speed = 0.02, stamina = 0.03 },
        -- [2] = { label = 'Steel Shoes', price = { cash = 60 },  speed = 0.04, stamina = 0.05 },
    },
    flaming = { enabled = false },   -- [S13] cosmetic flaming shoe, off until the FX spike lands
    cleaning = { enabled = true },   -- hoof/shoe cleaning w/ neglect penalty [H6/J16]
}
