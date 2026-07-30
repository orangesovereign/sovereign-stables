# Sovereign Stables: Definitive RedM Horse and Tack Color Customization Guide

**Platform:** RedM / Red Dead Redemption 2 only  
**Framework:** Framework-independent; suitable for VORP integration  
**Research date:** July 30, 2026

## Executive finding

Color customization is possible, but RedM does **not** expose a GTA-style horse or saddle RGB color property.

RDR2 builds horses and tack through the **MetaPed** system:

1. A horse model supplies the skeleton and base outfit.
2. Horse coat parts and tack are MetaPed assets made from drawable, albedo, normal, and material assets.
3. A tintable albedo uses a named palette plus three **palette indexes**.
4. Saddles and other tack are normally equipped as `shop_items.ymt` items.
5. A saddle can be freely recolored only when its underlying albedo was authored with `useTintPalette = True`. Otherwise, the script must select another vanilla shop-item colorway or use a custom texture.

The production implementation therefore needs two related systems:

- **Horse coat construction:** explicitly apply the correct head/body/hair asset records with `_SET_META_PED_TAG`.
- **Tack construction:** equip the selected shop item first with `_APPLY_SHOP_ITEM_TO_PED`, then retint its rendered MetaPed tag(s) when those tags are tint-capable.

This distinction is why a generic “set saddle RGB” implementation fails.

## The important tint rule

The native accepts:

```text
palette, tint0, tint1, tint2
```

Those tint values are **not RGB**:

- `tint0` selects a palette entry for the albedo's **green mask channel**.
- `tint1` selects a palette entry for the albedo's **red mask channel**.
- `tint2` selects a palette entry for the albedo's **blue mask channel**.
- `0–254` are palette indexes.
- `255` disables that channel.

The words green, red, and blue describe the texture masks, not the final displayed colors. Passing `{255, 0, 0}` as though it were red RGB will not produce ordinary red.

The NUI should show palette swatches or curated named presets backed by index values. A browser hex/RGB picker should only be used if the frontend converts the selected color to the nearest valid entry in the correct extracted RDR2 palette.

## Relevant RDR2 assets

Use CodeX/CodeWalker-compatible RDR2 asset tooling to inspect:

| File or asset | Purpose |
|---|---|
| `metapeds.ymt` | Ped definitions and links to MetaPed data |
| `a_c_horse_*.ymt` | Vanilla horse outfit presets and explicit assets |
| `assets_drawable.ymt` | Geometry/drawable definitions |
| `assets_albedo.ymt` | Color texture definitions and `useTintPalette` |
| `assets_normal.ymt` | Normal-map definitions |
| `assets_material.ymt` | Material definitions |
| `assets_tint.ymt` | Tint presets; useful as reference but not required at runtime |
| `settings.ymt` | MetaPed categories and palette configuration |
| `shop_items.ymt` | Saddles, blankets, bags, bridles, and other purchasable tack |
| `graphics.ytd` | Palette textures such as `metaped_tint_horse` |

For a vanilla horse, do not invent asset combinations. Extract the horse's outfit YMT, record the head/body/hair asset names, and build an approved appearance registry.

## Native map

| Native | Hash | Use |
|---|---:|---|
| `IS_PED_READY_TO_RENDER` | `0xA0BC8FAED8CFEB3C` | Wait before reading or modifying MetaPed data |
| `_APPLY_SHOP_ITEM_TO_PED` | `0xD3A7B003ED343FD9` | Equip a saddle/tack shop item |
| `REMOVE_SHOP_ITEM_FROM_PED_BY_CATEGORY` | `0xDF631E4BCE1B1FC4` | Clear the current tack category when necessary |
| `_GET_NUM_COMPONENTS_IN_PED` | `0x90403E8107B60E81` | Enumerate rendered MetaPed components |
| Component category lookup | `0x9B90842304C938A7` | Read the category for a component index |
| `GET_META_PED_ASSET_GUIDS` | `0xA9C28516A6DC9D56` | Read drawable/albedo/normal/material hashes |
| `GET_META_PED_ASSET_TINT` | `0xE7998FEC53A33BBE` | Read palette and three tint indexes |
| `_SET_META_PED_TAG` | `0xBC6DF00D7A4A6819` | Add/replace a MetaPed asset with explicit tint data |
| Component-load finalizer | `0xAAB86462966168CE` | Commonly paired with variation update |
| `_UPDATE_PED_VARIATION` | `0xCC8CA3E88256E58F` | Commit component/texture changes |
| `REMOVE_TAG_FROM_META_PED` | `0xD710A5007C2AC539` | Remove a specific explicit asset/tag |

Common horse tack category hashes found in working RDR2/RedM component catalogs:

| Category | Hash |
|---|---:|
| Blankets / saddlecloths | `0x17CEB41A` |
| Saddles | `0xBAA7E618` |
| Saddle horns | `0x05447332` |
| Saddlebags | `0x80451C25` |
| Saddle stirrups | `0xDA6DADCA` |
| Bedrolls / luggage | `0xEFB31921` |
| Tails | `0xA63CAE10` |
| Manes | `0xAA0217AB` |
| Bridles/masks group used by common catalogs | `0xD3500E5D` |
| Horse mustache | `0x30DEFDDF` |
| Lanterns | `0x1530BE1C` |
| Bits/bridle-related group | `0x94B2E3AF` |
| Holsters | `0xAC106B30` |

Treat the numeric category hashes as authoritative. Community-facing labels are inconsistent: one resource may call `0xD3500E5D` “masks,” while an asset catalog may call the same group “horse bridles.”

## Correct application order

Apply appearance in this order:

1. Create the horse ped and apply its base outfit preset.
2. Wait until `IS_PED_READY_TO_RENDER` returns true.
3. Apply all selected tack shop items.
4. Finalize/update the ped variation.
5. Apply explicit coat MetaPed tags.
6. Apply supported tack tint overrides.
7. Finalize/update the ped variation once after the batch.
8. Restore horse gameplay setup such as ownership, bonding, stats, and prompts as required by the stable script.

Important consequences:

- Applying a saddle shop item **after** its tint override can replace the tinted tag and restore the default color.
- Calling a component reset or setting the base outfit **after** customization can erase the coat and tack.
- Do not update the variation after every slider tick. Preview locally with a short debounce and commit once.

## Framework-independent Lua foundation

```lua
local Native = {
    IsReady = 0xA0BC8FAED8CFEB3C,
    ApplyShopItem = 0xD3A7B003ED343FD9,
    RemoveShopCategory = 0xDF631E4BCE1B1FC4,
    GetComponentCount = 0x90403E8107B60E81,
    GetComponentCategory = 0x9B90842304C938A7,
    GetAssetGuids = 0xA9C28516A6DC9D56,
    GetAssetTint = 0xE7998FEC53A33BBE,
    SetMetaPedTag = 0xBC6DF00D7A4A6819,
    FinalizeComponents = 0xAAB86462966168CE,
    UpdateVariation = 0xCC8CA3E88256E58F,
}

local function clampTint(value)
    value = math.floor(tonumber(value) or 255)
    return math.max(0, math.min(255, value))
end

local function waitUntilMetaPedReady(ped, timeoutMs)
    local deadline = GetGameTimer() + (timeoutMs or 5000)

    while DoesEntityExist(ped) and
          not Citizen.InvokeNative(Native.IsReady, ped) do
        if GetGameTimer() >= deadline then
            return false, 'metaped_ready_timeout'
        end
        Wait(0)
    end

    return DoesEntityExist(ped)
end

local function finalizeAppearance(ped)
    Citizen.InvokeNative(Native.FinalizeComponents, ped, true)
    Citizen.InvokeNative(
        Native.UpdateVariation,
        ped,
        false, true, true, true, false
    )
end

local function applyShopItem(ped, shopItemHash)
    Citizen.InvokeNative(
        Native.ApplyShopItem,
        ped,
        shopItemHash,
        true,  -- immediately
        true,  -- multiplayer
        true   -- horse shop-item path used by working stable implementations
    )
end

local function applyMetaPedTag(ped, tag)
    Citizen.InvokeNative(
        Native.SetMetaPedTag,
        ped,
        tag.drawable,
        tag.albedo,
        tag.normal,
        tag.material,
        tag.palette,
        clampTint(tag.tint0),
        clampTint(tag.tint1),
        clampTint(tag.tint2)
    )
end

local function getComponentCount(ped)
    return Citizen.InvokeNative(
        Native.GetComponentCount,
        ped,
        Citizen.ResultAsInteger()
    )
end

local function getComponentCategory(ped, index)
    return Citizen.InvokeNative(
        Native.GetComponentCategory,
        ped,
        index,
        0,
        Citizen.ResultAsInteger()
    )
end

local function getAssetGuids(ped, index)
    return Citizen.InvokeNative(
        Native.GetAssetGuids,
        ped,
        index,
        Citizen.PointerValueInt(),
        Citizen.PointerValueInt(),
        Citizen.PointerValueInt(),
        Citizen.PointerValueInt()
    )
end

local function getAssetTint(ped, index)
    return Citizen.InvokeNative(
        Native.GetAssetTint,
        ped,
        index,
        Citizen.PointerValueInt(),
        Citizen.PointerValueInt(),
        Citizen.PointerValueInt(),
        Citizen.PointerValueInt()
    )
end

local function inspectMetaPed(ped)
    local components = {}
    local count = getComponentCount(ped)

    for index = 0, count - 1 do
        local category = getComponentCategory(ped, index)
        local drawable, albedo, normal, material = getAssetGuids(ped, index)
        local palette, tint0, tint1, tint2 = getAssetTint(ped, index)

        components[#components + 1] = {
            index = index,
            category = category,
            drawable = drawable,
            albedo = albedo,
            normal = normal,
            material = material,
            palette = palette,
            tint0 = tint0,
            tint1 = tint1,
            tint2 = tint2,
        }
    end

    return components
end
```

The pointer-return style above follows the working RedM Lua pattern used by the MetaPed research examples. Test it on the server's current artifact build because several RedM natives remain partially named or typed in NativeDB.

## Applying a horse coat

The approved appearance registry should contain the exact asset records extracted from RDR2. Example:

```lua
local appearance = {
    coat = {
        head = {
            drawable = `p_c_horse_01_head_000`,
            albedo = `p_c_horse_01_head_000_c0_879_ab`,
            normal = `p_c_horse_01_head_000_c0_000_nm`,
            material = `p_c_horse_01_head_000_c0_000_m`,
            palette = `metaped_tint_horse`,
            tint0 = 47,
            tint1 = 0,
            tint2 = 194,
        },
        body = {
            drawable = `p_c_horse_01_hand_000`,
            albedo = `p_c_horse_01_hand_000_c0_879_ab`,
            normal = `p_c_horse_01_hand_000_c0_000_nm`,
            material = `p_c_horse_01_hand_000_c0_000_m`,
            palette = `metaped_tint_horse`,
            tint0 = 47,
            tint1 = 0,
            tint2 = 194,
        },
    },
}

local function applyCoat(ped, coat)
    if not waitUntilMetaPedReady(ped, 5000) then
        return false
    end

    -- Extend this list with mane, tail, eyes, eyelashes, feathers, etc.
    -- only when those exact assets are present in the approved registry.
    applyMetaPedTag(ped, coat.head)
    applyMetaPedTag(ped, coat.body)
    finalizeAppearance(ped)
    return true
end
```

The example asset set is a proven runtime pattern, not a universal coat. Every selectable coat should be an extracted and tested preset. Using an albedo intended for a different drawable can create seams, missing body pieces, wrong normals, or deformation.

## Applying and recoloring tack

### Safe vanilla colorway

If the selected color is already a vanilla catalog option, save and apply that option's shop-item hash:

```lua
local function replaceTackItem(ped, categoryHash, shopItemHash)
    Citizen.InvokeNative(
        Native.RemoveShopCategory,
        ped,
        categoryHash,
        0,
        false
    )

    applyShopItem(ped, shopItemHash)
    finalizeAppearance(ped)
end
```

This is the most compatible route. RDR2 often represents visually different colors as distinct shop-item hashes even when they share a mesh.

### Free tint where the base asset allows it

For a tintable saddle:

1. Capture `inspectMetaPed(ped)` before applying the saddle.
2. Apply the saddle shop item and finalize the variation.
3. Capture the component list again.
4. Identify the new or replaced saddle asset records.
5. Preserve each record's drawable, albedo, normal, material, and palette.
6. Change only its tint indexes.
7. Reapply the tag(s) and finalize once.

Do not assume the saddle is represented by only one rendered asset. Complex tack can be an asset bundle, and related visual pieces may appear in more than one component/category.

```lua
local function retintTags(ped, tags, tint0, tint1, tint2)
    if not waitUntilMetaPedReady(ped, 5000) then
        return false
    end

    for i = 1, #tags do
        local tag = tags[i]
        applyMetaPedTag(ped, {
            drawable = tag.drawable,
            albedo = tag.albedo,
            normal = tag.normal,
            material = tag.material,
            palette = tag.palette, -- preserve the asset's palette
            tint0 = tint0,
            tint1 = tint1,
            tint2 = tint2,
        })
    end

    finalizeAppearance(ped)
    return true
end
```

Do **not** force `metaped_tint_horse` onto a saddle. Preserve the palette declared or returned for that tack asset unless asset research proves another palette is compatible.

### How to decide whether a saddle supports tint

The definitive source is the saddle albedo entry in `assets_albedo.ymt`:

```xml
<useTintPalette value="True" />
```

Build a server-side whitelist/catalog during development:

```lua
local TackCatalog = {
    -- Example structure only; populate it from extracted/tested assets.
    [0xC5913F48] = {
        category = 0xBAA7E618,
        tintable = true,
        supportedPalettes = {
            -- exact palette hashes/names found in the asset data
        },
        tags = {
            -- exact drawable/albedo/normal/material/palette records
        },
    },
}
```

If `tintable` is false:

- hide/disable the free-color controls;
- offer its known vanilla shop-item colorways; or
- supply a custom streamed albedo/asset.

This is a real engine limitation, not a missing native.

## Diagnostic component dumper

Use a debug command against a test horse before and after equipping an item. It discovers what the running game actually rendered and prevents the implementation from relying on mislabeled component tables.

```lua
local function unsigned32(value)
    value = tonumber(value) or 0
    if value < 0 then
        value = value + 4294967296
    end
    return value
end

local function hex32(value)
    return ('0x%08X'):format(unsigned32(value))
end

RegisterCommand('sovhorse_dump', function()
    local playerPed = PlayerPedId()
    local horse = Citizen.InvokeNative(0x4C8B59171957BCF7, playerPed)

    if horse == 0 or not DoesEntityExist(horse) then
        print('[sovereign_stables] No last mount is available.')
        return
    end

    if not waitUntilMetaPedReady(horse, 5000) then
        print('[sovereign_stables] Horse MetaPed was not ready.')
        return
    end

    for _, component in ipairs(inspectMetaPed(horse)) do
        print(json.encode({
            index = component.index,
            category = hex32(component.category),
            drawable = hex32(component.drawable),
            albedo = hex32(component.albedo),
            normal = hex32(component.normal),
            material = hex32(component.material),
            palette = hex32(component.palette),
            tint0 = component.tint0,
            tint1 = component.tint1,
            tint2 = component.tint2,
        }))
    end
end, false)
```

For a cleaner catalog builder, compare the before/after sets by the tuple:

```text
category + drawable + albedo + normal + material
```

Do not persist component indexes. Indexes are runtime positions and may change when another shop item or MetaPed tag is added.

## Recommended saved appearance schema

Persist the appearance against the stable script's permanent horse ID, not the entity handle or network ID.

```json
{
  "version": 1,
  "baseModel": "a_c_horse_americanpaint_overo",
  "coatPresetId": "paint_overo_custom_014",
  "coat": {
    "head": {
      "drawable": "p_c_horse_01_head_000",
      "albedo": "p_c_horse_01_head_000_c0_879_ab",
      "normal": "p_c_horse_01_head_000_c0_000_nm",
      "material": "p_c_horse_01_head_000_c0_000_m",
      "palette": "metaped_tint_horse",
      "tints": [47, 0, 194]
    },
    "body": {
      "drawable": "p_c_horse_01_hand_000",
      "albedo": "p_c_horse_01_hand_000_c0_879_ab",
      "normal": "p_c_horse_01_hand_000_c0_000_nm",
      "material": "p_c_horse_01_hand_000_c0_000_m",
      "palette": "metaped_tint_horse",
      "tints": [47, 0, 194]
    }
  },
  "tack": {
    "saddle": {
      "shopItemHash": 3314630472,
      "tintPresetId": "dark_oxblood",
      "tints": [10, 44, 255]
    }
  }
}
```

Production recommendations:

- Save a compact preset ID when possible and resolve asset details from a versioned server catalog.
- Store raw asset records only when the player can construct genuinely unique combinations.
- Validate every asset/shop-item hash against the server catalog.
- Validate every tint as an integer from `0` through `255`.
- Never trust client-supplied price, horse ownership, permissions, or allowed asset lists.

## Replication and late-join reliability

The database should be authoritative. MetaPed changes are applied client-side, so add a replicated appearance instruction for the networked horse:

1. Server validates and saves the appearance.
2. Server writes the complete appearance payload to one entity state-bag key, for example `sovereign:horseAppearance`.
3. Clients listen for that state change.
4. When the horse exists locally and is ready to render, the client applies the appearance.
5. Reapply after horse spawn, stream-in, routing-bucket transition, or any tack shop-item change.

Cfx state bags are shallow. Replace the complete `sovereign:horseAppearance` value; do not mutate a nested Lua property and expect it to replicate.

Use a permanent database horse ID for storage. Network IDs exist only for an entity lifetime and can later be reused.

For the customization preview:

- keep rapid slider changes local;
- debounce rendering;
- send one validated server commit when the player purchases/confirms;
- avoid database writes and replicated state updates for every single slider movement.

## Failure patterns to remove from the current implementation

| Faulty approach | Why it fails |
|---|---|
| Passing hex/RGB values to `tint0/1/2` | They are palette indexes and mask channels, not RGB |
| Calling GTA `SET_PED_COMPONENT_VARIATION` logic | RDR2 horses/tack use MetaPed assets |
| Applying only a saddle category hash | The category identifies a group; the shop-item hash selects an actual tack item |
| Treating component hash, shop-item hash, and asset GUID as interchangeable | They represent different layers of the MetaPed system |
| Tinting before applying the shop item | The shop item can overwrite the tinted tag |
| Forcing one palette onto every asset | Horse coats and tack can use different palettes |
| Offering color controls for every saddle | Baked/non-tintable albedos ignore free tint |
| Saving runtime component indexes | Index positions change as components are added/replaced |
| Calling variation update on every frame | Causes unnecessary rebuilds, flicker, and race conditions |
| Applying before the ped is ready | Leads to missing, black, reverted, or partially applied components |
| Resetting the ped/outfit after customization | Erases or replaces the custom MetaPed tags |
| Letting the client submit arbitrary hashes | Enables invalid assets, abuse, and potential instability |

## Acceptance test matrix

The feature is not finished until it passes:

1. **Known coat:** one vanilla horse receives a known head/body albedo and three clearly different tint presets.
2. **Mask behavior:** tint0, tint1, and tint2 are changed independently to prove which visual region each controls.
3. **Seams:** inspect head/body/legs at close range and in rain/wet lighting.
4. **Tintable saddle:** three supported tint presets survive mount/dismount.
5. **Non-tintable saddle:** UI correctly offers variants or disables the tint control.
6. **Tack replacement:** changing the saddle reapplies the saved saddle tint afterward.
7. **Store/respawn:** appearance survives stable storage, resource restart, and horse respawn.
8. **Two clients:** another player sees the same coat and tack.
9. **Late scope:** a player riding into streaming range sees the correct appearance.
10. **Ownership migration:** appearance remains correct after the original entity owner disconnects.
11. **Invalid request:** server rejects unknown shop items, unknown asset presets, and tint values outside `0–255`.
12. **Performance:** dragging a slider does not trigger a server/database write every frame.

## Final implementation decision

Build Sovereign Stables around a **curated asset catalog**, not an unrestricted RGB picker:

- Coat preset chooses valid head/body/pattern assets.
- Three swatch controls choose valid palette indexes for the asset's mask channels.
- Tack item chooses a valid `shop_items.ymt` hash.
- Tint controls appear only for tack whose base albedo supports tint.
- Vanilla colorway variants cover the rest.
- Server persistence plus entity state bags make the result reliable for respawns and other players.

This is the same engine path that allows advanced horse servers to offer extensive coat and tack customization. Their breadth comes from a large, tested asset/preset catalog—not from a hidden universal horse-color native.

## Research sources

- [Cfx RedM native definitions](https://static.cfx.re/natives/natives_rdr3.lua)
- [Cfx MetaPed modification and metadata research](https://forum.cfx.re/t/ped-modification-and-metadata-overview-outfits-assets-expressions-shop-items-overlays-etc/5124046)
- [Cfx custom horse runtime tint example](https://forum.cfx.re/t/how-to-add-a-new-custom-horse/5185418)
- [RSG Horses GPL component implementation](https://github.com/Rexshack-RedM/rsg-horses)
- [RDR3 discoveries asset research](https://github.com/femga/rdr3_discoveries)
- [Cfx state bag documentation](https://docs.fivem.net/docs/scripting-manual/networking/state-bags/)
- [Cfx network/local ID documentation](https://docs.fivem.net/docs/scripting-manual/networking/ids/)
