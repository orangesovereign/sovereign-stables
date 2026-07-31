--[[=====================================================================
  SOVEREIGN STABLES · HORSE MORPHOLOGY ATTRIBUTES
  ---------------------------------------------------------------------
  Every shape setting the Horse Customiser / breed creator exposes. The panel
  RENDERS FROM THIS TABLE — add, remove, rename, or reorder freely and the UI
  follows. Config is the source of truth.

  Each attribute drives one or more MetaPedExpression indices via
  _SET_CHAR_EXPRESSION (0x5653AB26C82938CF), value -1.0 .. 1.0, committed with
  _UPDATE_PED_VARIATION. CONFIRMED working in-game 2026-07-31 (scale + morphs).
  Expression id reference: pastebin Ld76cAn7.

    kind    = 'expr'  (default) — a -1..1 MetaPedExpression slider
            = 'scale'           — uniform body scale via _SET_PED_SCALE (0.5..2.0)
            = 'toggle'          — a 0/1 expression (e.g. gender)
    indices = one or MORE expression ids driven together by the single slider
              (left+right pairs are combined so one slider keeps the horse
              symmetric; split them into two entries if you want asymmetry).
=====================================================================]]--

Config = Config or {}

Config.HorseMorph = {

    -- ── BODY ────────────────────────────────────────────────────────────────
    { group = 'Body', key = 'scale',       label = 'Overall Size',   kind = 'scale' },
    { group = 'Body', key = 'body_size',   label = 'Body Size',      indices = { 10726 } },
    { group = 'Body', key = 'muscle',      label = 'Muscle',         indices = { 3015 } },
    { group = 'Body', key = 'muscle_tone', label = 'Muscle Tone',    indices = { 8147 } },
    { group = 'Body', key = 'belly',       label = 'Belly Size',     indices = { 57577, 63348 } },
    { group = 'Body', key = 'chest',       label = 'Chest / Back Width', indices = { 41478 } },
    { group = 'Body', key = 'waist',       label = 'Waist Width',    indices = { 50460 } },
    { group = 'Body', key = 'hip',         label = 'Hip / Stomach',  indices = { 49787 } },
    { group = 'Body', key = 'butt',        label = 'Rump Size',      indices = { 62347 } },
    { group = 'Body', key = 'rear_height', label = 'Rear Height',    indices = { 11904 } },
    { group = 'Body', key = 'shoulder_h',  label = 'Shoulder Height',indices = { 15833 } },
    { group = 'Body', key = 'throat',      label = 'Throat Size',    indices = { 2075 } },

    -- ── NECK ────────────────────────────────────────────────────────────────
    { group = 'Neck', key = 'neck_height', label = 'Neck Height',    indices = { 10002 } },
    { group = 'Neck', key = 'neck_base',   label = 'Neck Base Height',indices = { 42991 } },
    { group = 'Neck', key = 'neck_thick',  label = 'Neck Thickness', indices = { 26839 } },
    { group = 'Neck', key = 'neck_width',  label = 'Neck Width',     indices = { 36277 } },
    { group = 'Neck', key = 'neck_depth',  label = 'Neck Depth',     indices = { 60890 } },

    -- ── LEGS ────────────────────────────────────────────────────────────────
    { group = 'Legs', key = 'front_legs',  label = 'Front Leg Length', indices = { 8420 } },
    { group = 'Legs', key = 'hind_legs',   label = 'Hind Leg Length',  indices = { 16934 } },
    { group = 'Legs', key = 'thighs',      label = 'Thigh Thickness',  indices = { 36550 } },
    { group = 'Legs', key = 'knees',       label = 'Knee / Hock Size', indices = { 26933 } },
    { group = 'Legs', key = 'ankles',      label = 'Ankle Size',       indices = { 60975 } },
    { group = 'Legs', key = 'hooves',      label = 'Hoof Size',        indices = { 39436 } },
    { group = 'Legs', key = 'hoof_len',    label = 'Hoof Length',      indices = { 9675 } },

    -- ── HEAD ────────────────────────────────────────────────────────────────
    { group = 'Head', key = 'head_size',   label = 'Head Size',      indices = { 48003 } },
    { group = 'Head', key = 'head_width',  label = 'Head Width',     indices = { 43213 } },
    { group = 'Head', key = 'forehead',    label = 'Forehead Height',indices = { 55026 } },
    { group = 'Head', key = 'jaw_sag',     label = 'Under-Jaw Sag',  indices = { 1589 } },

    -- ── MUZZLE ──────────────────────────────────────────────────────────────
    { group = 'Muzzle', key = 'nose_len',    label = 'Nose Length',       indices = { 3054 } },
    { group = 'Muzzle', key = 'nose_size',   label = 'Nose Size',         indices = { 22549 } },
    { group = 'Muzzle', key = 'nose_bridge_d',label = 'Nose Bridge Depth', indices = { 62196 } },
    { group = 'Muzzle', key = 'nose_bridge_h',label = 'Nose Bridge Height',indices = { 29982 } },
    { group = 'Muzzle', key = 'nostrils',    label = 'Nostril Size',      indices = { 36120, 35608 } },

    -- ── EARS (left+right combined) ──────────────────────────────────────────
    { group = 'Ears', key = 'ear_size',   label = 'Ear Size',          indices = { 23050, 22538 } },
    { group = 'Ears', key = 'ear_fb',     label = 'Ear Forward / Back', indices = { 19780, 19812 } },
    { group = 'Ears', key = 'ear_x',      label = 'Ear Spread',        indices = { 19781, 19813 } },
    { group = 'Ears', key = 'ear_height', label = 'Ear Height',        indices = { 10308 } },
    { group = 'Ears', key = 'ear_angle',  label = 'Ear Angle',         indices = { 46798 } },
    { group = 'Ears', key = 'ear_depth',  label = 'Ear Depth',         indices = { 49231 } },

    -- ── EYES (left+right combined) ──────────────────────────────────────────
    { group = 'Eyes', key = 'eye_size',   label = 'Eye Size',          indices = { 34850, 34338 } },
    { group = 'Eyes', key = 'eye_fb',     label = 'Eye Forward / Back', indices = { 17697, 17185 } },
    { group = 'Eyes', key = 'eye_height', label = 'Eye Height',        indices = { 17698, 17186 } },

    -- ── TAIL ────────────────────────────────────────────────────────────────
    { group = 'Tail', key = 'tail_angle', label = 'Tail Angle',        indices = { 54287 } },

    -- ── SPECIAL ─────────────────────────────────────────────────────────────
    -- Gender morph: 0.0 = male, 1.0 = female (affects build + adds female-only
    -- shaping). A toggle, not a -1..1 slider.
    { group = 'Special', key = 'gender', label = 'Gender (female)', kind = 'toggle', indices = { 41611 } },
}

-- The order groups appear in the panel. Any group used above but not listed here
-- is appended after these, in first-seen order.
Config.HorseMorphGroups = { 'Body', 'Neck', 'Legs', 'Head', 'Muzzle', 'Ears', 'Eyes', 'Tail', 'Special' }
