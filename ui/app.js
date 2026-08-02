/* =====================================================================
   SOVEREIGN STABLES · STOREFRONT NUI
   Lua drives it via window messages; the JS paints and reports interactions
   back through NUI callbacks. Center stage is transparent — the game renders
   the horse there, so drag/scroll over it steer the orbital camera in Lua.
   ===================================================================== */
(function () {
    'use strict';

    var RESOURCE = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'sovereign_stables';
    var root = document.getElementById('root');

    var rows = [];          // full horse catalog
    var tab = 'specialty';  // active tab
    var ALL_BREEDS = '__all__';
    var breed = ALL_BREEDS; // active breed filter [N1]
    var selected = null;    // selected model id
    var owned = [];         // horses this character owns
    var ownedCap = 0;       // how many they may keep
    var view = 'shop';      // 'shop' | 'owned' | 'wagons' | 'tack'

    // Wagons [WG1/WG13] — mirrors the horse shop/owned split, in one column.
    var wagonRows = [];     // wagon catalog
    var wagons = [];        // wagons this character owns
    var wagonCap = 0;

    // Tack [F1/F5] — tack is PLAYER-owned, so this list is not per-horse. What
    // a given horse is WEARING is `tackComponents`, keyed by slot.
    var tackCats = [];      // categories that actually have stock
    var tackCat = null;     // active category
    var tackCatalog = {};   // { category: [ {id,label,slot,cash,gold}, ... ] }
    var tackOwned = [];     // pieces this character owns
    var tackComponents = {};// { slot: itemId } on the horse being fitted
    var tackTints = {};     // { itemId: {palette,t0,t1,t2} } — saved colours
    var tackOpenSlot = null;// which fitted slot's colour panel is expanded
    var tackMode = 'owned'; // 'owned' (your tack, fit/recolour) or 'shop' (buy)
    var tackHorseId = null; // which owned horse we're fitting

    // Leather-friendly palettes the recolour offers. Tack colour is ungated, so
    // everyone gets the lot; the horse sees the change live as you slide.
    var TACK_PALETTES = [
        { id: 'metaped_tint_combined_leather', label: 'Combined Leather' },
        { id: 'metaped_tint_leather',          label: 'Leather' },
        { id: 'metaped_tint_combined',         label: 'Combined' },
        { id: 'metaped_tint_horse_leather',    label: 'Horse Leather' },
        { id: 'metaped_tint_generic',          label: 'Generic' },
        { id: 'metaped_tint_metal',            label: 'Metal' }
    ];

    function post(name, body) {
        return fetch('https://' + RESOURCE + '/' + name, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(body || {})
        }).catch(function () { /* preview / not in game */ });
    }

    function money(n) { return '$' + (n || 0).toLocaleString('en-US'); }

    // Wagon soundness as a 0-100 percent. `health` is already 0..100 (our scale,
    // matching horses) — so this is the value itself, not a division.
    // CRITICAL: 0 is a real value, not "missing". Reading a wrecked wagon (0) as
    // full was the bug that had the catalog list saying 0% while the detail panel
    // said 100% for the same cart. Only null/undefined means "we don't know", and
    // that assumes full.
    function soundPct(health) {
        if (health === null || health === undefined || health === '') return 100;
        var h = Number(health);
        if (isNaN(h)) return 100;
        return Math.max(0, Math.min(100, Math.round(h)));
    }
    // Condition as words: wrecked at 0, sound at 100, a percent between.
    function condLabel(health) {
        var p = soundPct(health);
        if (p <= 0) return 'Wrecked';
        if (p >= 100) return 'Sound';
        return p + '% sound';
    }
    function el(tag, cls, html) { var e = document.createElement(tag); if (cls) e.className = cls; if (html != null) e.innerHTML = html; return e; }

    /* ---------- catalog list ---------- */
    // Rows on the active tab, before the breed filter. The filter's options are
    // built from THIS, so it only ever offers breeds you could actually reach.
    function tabRows() { return rows.filter(function (r) { return (r.tier || 'stock') === tab; }); }

    function visibleRows() {
        var vis = tabRows();
        if (breed !== ALL_BREEDS) {
            vis = vis.filter(function (r) { return (r.breed || '') === breed; });
        }
        return vis;
    }

    // Rebuild the breed dropdown for the current tab. Counts are included
    // because "Mustang (8)" tells you whether it's worth opening.
    function renderBreedFilter() {
        var sel = document.getElementById('breedFilter');
        var wrap = document.getElementById('breedFilterWrap');
        if (!sel || !wrap) return;

        var counts = {};
        tabRows().forEach(function (r) {
            var b = r.breed || 'Unknown';
            counts[b] = (counts[b] || 0) + 1;
        });
        var names = Object.keys(counts).sort();

        // One breed (or none) means the filter can't narrow anything — hide it
        // rather than show a control that does nothing.
        wrap.classList.toggle('hidden', names.length < 2);

        // If the chosen breed isn't on this tab, fall back to All rather than
        // showing an empty list and leaving the player wondering why.
        if (breed !== ALL_BREEDS && !counts[breed]) breed = ALL_BREEDS;

        var total = tabRows().length;
        var html = '<option value="' + ALL_BREEDS + '">All breeds (' + total + ')</option>';
        names.forEach(function (b) {
            html += '<option value="' + b.replace(/"/g, '&quot;') + '">' + b + ' (' + counts[b] + ')</option>';
        });
        sel.innerHTML = html;
        sel.value = breed;
    }

    /* ---------- owned horses ---------- */
    function renderOwnedList(list) {
        if (!owned.length) {
            list.innerHTML = '<div class="empty">You keep no horses yet. Buy one from the stablefront.</div>';
            document.getElementById('catFoot').textContent = '0 of ' + ownedCap;
            return;
        }
        owned.forEach(function (o) {
            var row = el('button', 'row' + (String(o.id) === String(selected) ? ' is-active' : ''));
            row.innerHTML =
                '<span class="row__portrait">&#9816;</span>' +
                '<span class="row__t"><span class="row__name">' + (o.name || o.model) + '</span>' +
                '<span class="row__breed">' + (o.model || '') + '</span></span>' +
                (Number(o.is_default) === 1 ? '<span class="row__price">&#9733; Default</span>' : '');
            row.addEventListener('click', function () {
                selected = o.id;
                // Picking a horse here is also what the tack room fits to — so
                // you choose the horse once, then walk over to Components.
                tackHorseId = o.id;
                renderList();
                post('selectOwned', { id: o.id });
            });
            list.appendChild(row);
        });
        document.getElementById('catFoot').textContent = owned.length + ' of ' + ownedCap;
    }

    /* ---------- wagons ---------- */
    function renderWagonList(list) {
        // Owned first, then what's for sale — a wagon is a tool, and the one you
        // already have is the one you want to send for.
        if (wagons.length) {
            list.appendChild(el('div', 'list__label', 'Yours'));
            wagons.forEach(function (w) {
                var row = el('button', 'row' + (String(w.id) === String(selected) ? ' is-active' : ''));
                row.innerHTML =
                    '<span class="row__portrait">&#9881;</span>' +
                    '<span class="row__t"><span class="row__name">' + (w.name || w.model) + '</span>' +
                    '<span class="row__breed">' + condLabel(w.health) + '</span></span>' +
                    (Number(w.is_default) === 1 ? '<span class="row__price">&#9733; Default</span>' : '');
                row.addEventListener('click', function () {
                    selected = w.id;
                    renderList();
                    post('selectWagon', { id: w.id });
                });
                list.appendChild(row);
            });
        }
        if (wagonRows.length) {
            list.appendChild(el('div', 'list__label', 'For sale'));
            wagonRows.forEach(function (r) {
                var row = el('button', 'row' + (r.model === selected ? ' is-active' : '') + (r.locked ? ' is-locked' : ''));
                var price = r.locked ? '<span class="lock">&#128274;</span>'
                    : '<span class="row__price">' + money(r.cash) + (r.gold ? '<em> or ' + r.gold + ' gold</em>' : '') + '</span>';
                row.innerHTML =
                    '<span class="row__portrait">&#9881;</span>' +
                    '<span class="row__t"><span class="row__name">' + (r.name || r.model) + '</span>' +
                    '<span class="row__breed">Holds ' + (r.storage || 0) + '</span></span>' + price;
                if (!r.locked) row.addEventListener('click', function () {
                    selected = r.model;
                    renderList();
                    post('selectWagonModel', { model: r.model });
                });
                list.appendChild(row);
            });
        }
        if (!wagons.length && !wagonRows.length) {
            list.innerHTML = '<div class="empty">No wagons here.</div>';
        }
        document.getElementById('catFoot').textContent = wagons.length + ' of ' + wagonCap;
    }

    /* ---------- tack ---------- */
    function renderTackList(list) {
        if (!tackCats.length) {
            // Honest empty state: the categories exist but no verified component
            // hashes are filled in yet. Better than nine empty tabs.
            list.innerHTML = '<div class="empty">The tack room is still being stocked.</div>';
            document.getElementById('catFoot').textContent = '';
            return;
        }
        if (!tackHorseId) {
            list.innerHTML = '<div class="empty">Pick one of your horses first, from My Horses.</div>';
            document.getElementById('catFoot').textContent = '';
            return;
        }
        // Mode toggle: your own tack (fit + recolour) vs the shop (buy). Fitting
        // only ever targets your selected horse, so owned tack gets its own list
        // rather than being mixed in with things for sale (owner ask).
        var mode = el('div', 'tackmode');
        [['owned', 'My Tack'], ['shop', 'Shop']].forEach(function (m) {
            var b = el('button', 'tackmode__b' + (tackMode === m[0] ? ' is-active' : ''), m[1]);
            b.addEventListener('click', function () { tackMode = m[0]; renderList(); });
            mode.appendChild(b);
        });
        list.appendChild(mode);

        if (tackMode === 'owned') { renderOwnedTack(list); }
        else { renderTackShop(list); }
    }

    // One tack row (fit / remove / recolour / buy), used by both lists.
    function renderTackRow(list, t) {
        var isOwnedPiece = tackOwned.some(function (o) { return o.item === t.id; });
        var isWorn = tackComponents[t.slot] === t.id;
        var row = el('button', 'row' + (isWorn ? ' is-active' : ''));
        var right = isWorn ? '<span class="row__price">&#10003; Fitted</span>'
            : isOwnedPiece ? '<span class="row__price">Owned</span>'
            : '<span class="row__price">' + money(t.cash) + '</span>';
        var sub = isWorn ? 'Fitted — click to recolour'
            : isOwnedPiece ? 'Yours — click to fit'
            : 'For sale';
        row.innerHTML =
            '<span class="row__portrait">&#9109;</span>' +
            '<span class="row__t"><span class="row__name">' + t.label + '</span>' +
            '<span class="row__breed">' + sub + '</span></span>' + right;
        row.addEventListener('click', function () {
            if (isWorn) { tackOpenSlot = (tackOpenSlot === t.slot) ? null : t.slot; renderList(); }
            else if (isOwnedPiece) post('applyTack', { horseId: tackHorseId, item: t.id });
            else post('buyTack', { item: t.id });
        });
        list.appendChild(row);
        if (isWorn && tackOpenSlot === t.slot) list.appendChild(buildColourPanel(t));
    }

    // Find an item's catalog entry (it carries slot/label/price).
    function tackItemById(itemId) {
        for (var cat in tackCatalog) {
            var arr = tackCatalog[cat] || [];
            for (var i = 0; i < arr.length; i++) if (arr[i].id === itemId) return arr[i];
        }
        return null;
    }

    // MY TACK — only what you own, grouped by category, fit/recolour on your horse.
    function renderOwnedTack(list) {
        var owned = tackOwned.map(function (o) { return tackItemById(o.item); }).filter(Boolean);
        if (!owned.length) {
            list.appendChild(el('div', 'empty', 'You own no tack yet — open the Shop.'));
            document.getElementById('catFoot').textContent = '0 pieces owned';
            return;
        }
        tackCats.forEach(function (c) {
            var inCat = owned.filter(function (t) { return t.slot === c.slot; });
            if (!inCat.length) return;
            list.appendChild(el('div', 'list__label', c.label));
            inCat.forEach(function (t) { renderTackRow(list, t); });
        });
        document.getElementById('catFoot').textContent = owned.length + ' piece' + (owned.length === 1 ? '' : 's') + ' owned';
    }

    // SHOP — buy new tack. Category strip; owned pieces drop out (they're in My Tack).
    function renderTackShop(list) {
        var strip = el('div', 'catstrip');
        tackCats.forEach(function (c) {
            var b = el('button', 'catstrip__b' + (c.id === tackCat ? ' is-active' : ''), c.label);
            b.addEventListener('click', function () { tackCat = c.id; renderList(); });
            strip.appendChild(b);
        });
        list.appendChild(strip);

        var forSale = (tackCatalog[tackCat] || []).filter(function (t) {
            return !tackOwned.some(function (o) { return o.item === t.id; });
        });
        if (!forSale.length) { list.appendChild(el('div', 'empty', 'You own everything in this category.')); }
        forSale.forEach(function (t) { renderTackRow(list, t); });
        document.getElementById('catFoot').textContent = tackOwned.length + ' piece' + (tackOwned.length === 1 ? '' : 's') + ' owned';
    }

    function buildColourPanel(t) {
        var saved = tackTints[t.id] || {};
        var state = {
            palette: saved.palette || TACK_PALETTES[0].id,
            t0: (saved.t0 == null ? 20 : saved.t0),
            t1: (saved.t1 == null ? 255 : saved.t1),
            t2: (saved.t2 == null ? 255 : saved.t2)
        };
        var panel = el('div', 'tint');

        // Palette selector
        var palRow = el('div', 'tint__row');
        palRow.appendChild(el('span', 'tint__lbl', 'Palette'));
        var sel = document.createElement('select');
        sel.className = 'tint__sel';
        TACK_PALETTES.forEach(function (p) {
            var o = document.createElement('option');
            o.value = p.id; o.textContent = p.label;
            if (p.id === state.palette) o.selected = true;
            sel.appendChild(o);
        });
        palRow.appendChild(sel);
        panel.appendChild(palRow);

        function preview() {
            post('previewTint', { slot: t.slot, palette: state.palette, t0: state.t0, t1: state.t1, t2: state.t2 });
        }
        sel.addEventListener('change', function () { state.palette = sel.value; preview(); });

        // Three channel steppers: arrows step ONE at a time (a slider skips past
        // the exact number too easily — owner ask). Hold an arrow to repeat.
        ['t0', 't1', 't2'].forEach(function (ch, i) {
            var name = ['Base', 'Accent', 'Detail'][i];
            var r = el('div', 'tint__row');
            r.appendChild(el('span', 'tint__lbl', name));

            var dec = el('button', 'tint__arw', '◀');   // ◀
            var val = el('span', 'tint__num', state[ch] === 255 ? 'off' : String(state[ch]));
            var inc = el('button', 'tint__arw', '▶');   // ▶

            function set(v) {
                state[ch] = Math.max(0, Math.min(255, v));
                val.textContent = (state[ch] === 255 ? 'off' : String(state[ch]));
                preview();
            }
            // click = one step; press-and-hold = repeat (accelerating a touch).
            function hold(step) {
                return function () {
                    set(state[ch] + step);
                    var t = setTimeout(function tick() {
                        set(state[ch] + step);
                        t = setTimeout(tick, 90);
                    }, 380);
                    function stop() { clearTimeout(t); document.removeEventListener('mouseup', stop); }
                    document.addEventListener('mouseup', stop);
                };
            }
            dec.addEventListener('mousedown', hold(-1));
            inc.addEventListener('mousedown', hold(1));

            r.appendChild(dec); r.appendChild(val); r.appendChild(inc);
            panel.appendChild(r);
        });

        // Save
        var btn = el('button', 'tint__save', 'Save Colour');
        btn.addEventListener('click', function () {
            post('saveTint', { horseId: tackHorseId, slot: t.slot, palette: state.palette, t0: state.t0, t1: state.t1, t2: state.t2 });
            tackTints[t.id] = { palette: state.palette, t0: state.t0, t1: state.t1, t2: state.t2 };
        });
        panel.appendChild(btn);
        return panel;
    }

    // Swap the catalog column between the shop, the player's horses, wagons and tack.
    var VIEW_COPY = {
        shop:   { head: 'Find your better half.', sub: 'Every horse has a history. Choose one worthy of yours.' },
        owned:  { head: 'Your horses.',           sub: 'The ones that already answer to you.' },
        wagons: { head: 'Wagons & carriages.',    sub: 'What carries the work, and what carries it home.' },
        tack:   { head: 'The tack room.',         sub: 'Buy it once. It goes on whichever horse you ride.' }
    };
    function applyView() {
        var copy = VIEW_COPY[view] || VIEW_COPY.shop;
        document.querySelector('.tabs').style.display = (view === 'shop') ? '' : 'none';
        // The breed filter belongs to the horse shop only — My Horses, Wagons and
        // the tack room have their own lists and it would filter nothing there.
        var bf = document.getElementById('breedFilterWrap');
        if (bf) bf.classList.toggle('hidden', view !== 'shop');
        document.querySelector('.cat__head').textContent = copy.head;
        document.querySelector('.cat__sub').textContent = copy.sub;
        document.querySelectorAll('.nav__item[data-view]').forEach(function (b) {
            b.classList.toggle('is-active', b.dataset.view === view);
        });
        selected = null;
        if (view === 'wagons') {
            post('requestWagons', {});
        } else if (view === 'tack') {
            if (!tackCat && tackCats.length) tackCat = tackCats[0].id;
            post('requestTack', { horseId: tackHorseId });
        } else {
            // Leaving wagons: the stand still has a cart on it. Tell Lua to put
            // a horse back — otherwise you browse horses while a wagon sits there.
            post('restoreHorsePreview', {});
        }
        renderList();
    }

    function renderList() {
        var list = document.getElementById('list');
        list.innerHTML = '';
        if (view === 'owned')  { renderOwnedList(list); return; }
        if (view === 'wagons') { renderWagonList(list); return; }
        if (view === 'tack')   { renderTackList(list); return; }

        // Keep the tab highlight correct BEFORE any early return below, or an
        // empty breed leaves the tabs showing the wrong one as active.
        document.querySelectorAll('.tabs button').forEach(function (b) {
            b.classList.toggle('is-active', b.dataset.tab === tab);
        });

        renderBreedFilter();
        var vis = visibleRows();
        if (!vis.length) {
            list.innerHTML = '<div class="empty">No horses of that breed here.</div>';
            document.getElementById('catFoot').textContent = '0 horses';
            return;
        }
        vis.forEach(function (r) {
            var row = el('button', 'row' + (r.model === selected ? ' is-active' : '') + (r.locked ? ' is-locked' : ''));
            row.dataset.model = r.model;
            var price = r.locked ? '<span class="lock">&#128274;</span>'
                : '<span class="row__price">' + money(r.cash) + (r.gold ? '<em> or ' + r.gold + ' gold</em>' : '') + '</span>';
            row.innerHTML =
                '<span class="row__portrait">&#9816;</span>' +
                '<span class="row__t"><span class="row__name">' + (r.name || r.model) + '</span>' +
                '<span class="row__breed">' + (r.breed || '') + '</span></span>' + price;
            if (!r.locked) row.addEventListener('click', function () { choose(r.model); });
            list.appendChild(row);
        });
        document.getElementById('catFoot').textContent = vis.length + (vis.length === 1 ? ' horse' : ' horses');
    }

    function choose(model) {
        selected = model;
        renderList();
        post('select', { model: model });   // Lua swaps the preview + returns 'detail'
    }

    function cycle(dir) {
        if (view !== 'shop') return;
        var vis = visibleRows(); if (!vis.length) return;
        var i = vis.findIndex(function (r) { return r.model === selected; });
        i = (i + dir + vis.length) % vis.length;
        choose(vis[i].model);
    }

    /* ---------- wagon detail ----------
       Its own panel rather than a branch through the horse one: a wagon has no
       gender, no age, no lineage and no stat bars, so sharing that renderer
       would mean hiding more than it showed. */
    function renderWagonDetail(d) {
        var wrap = document.getElementById('detail');
        var mine = !!d.ownedWagonId;
        var w = mine ? (wagons.filter(function (x) { return String(x.id) === String(d.ownedWagonId); })[0] || {}) : d;
        var cond = condLabel(w.health);
        wrap.innerHTML =
            (mine ? '<div class="ribbon">&#9733; Yours &#9733;</div>' : '') +
            '<div class="detail__breed">Wagons &amp; Carriages</div>' +
            '<h2 class="detail__name">' + (w.name || w.model || 'Wagon') + '</h2>' +
            '<div class="attrs">' +
                '<span><i>&#9881;</i>' + (mine ? cond : 'Holds ' + (w.storage || 0)) + '</span>' +
            '</div>' +
            (w.lore ? '<p class="detail__lore">' + w.lore + '</p>' : '') +
            (mine ? '' : '<div class="price"><b>' + money(w.cash) + '</b>' +
                (w.gold ? '<span> or ' + w.gold + ' <em>gold</em></span>' : '') + '</div>') +
            (mine
                ? '<button class="buy" id="callwagon">Bring It Round</button>' +
                  (Number(w.is_default) === 1
                    ? '<div class="detail__default">&#9733; Your default wagon</div>'
                    : '<button class="buy ghost" id="mkdefwagon">Make Default Wagon</button>')
                : '<button class="buy" id="buywagon">Purchase</button>' +
                  '<div class="buyform hidden" id="wbuyform">' +
                    '<label class="field"><span>Name</span>' +
                      '<input id="wname" maxlength="24" spellcheck="false" placeholder="Name your wagon" /></label>' +
                    '<button class="buy" id="wconfirm">Confirm Purchase</button>' +
                    '<button class="buy ghost" id="wcancel">Cancel</button>' +
                  '</div>') +
            '<div class="detail__foot">' + (mine ? 'Owned &middot; papers on file' : 'Stable slot required') + '</div>';

        var bw = document.getElementById('buywagon');
        var wf = document.getElementById('wbuyform');
        if (bw && wf) {
            bw.addEventListener('click', function () {
                wf.classList.remove('hidden'); bw.classList.add('hidden');
                var n = document.getElementById('wname'); n.value = w.name || ''; n.focus(); n.select();
            });
        }
        var wc = document.getElementById('wconfirm');
        if (wc) wc.addEventListener('click', function () {
            var input = document.getElementById('wname');
            var name = (input.value || '').trim();
            if (!name) { input.focus(); input.classList.add('invalid'); return; }
            post('purchaseWagon', { model: w.model, name: name });
            if (wf) wf.classList.add('hidden');
            if (bw) bw.classList.remove('hidden');
        });
        var wx = document.getElementById('wcancel');
        if (wx) wx.addEventListener('click', function () {
            if (wf) wf.classList.add('hidden'); if (bw) bw.classList.remove('hidden');
        });
        var cw = document.getElementById('callwagon');
        if (cw) cw.addEventListener('click', function () { post('callWagon', { id: d.ownedWagonId }); });
        var md = document.getElementById('mkdefwagon');
        if (md) md.addEventListener('click', function () { post('setDefaultWagon', { id: d.ownedWagonId }); });
    }

    /* ---------- detail panel ---------- */
    function renderDetail(d) {
        var wrap = document.getElementById('detail');
        if (!d) { wrap.innerHTML = ''; return; }
        if (d.isWagon) { renderWagonDetail(d); return; }
        var isOwned = !!d.ownedId;
        var defSex = (d.sex === 'Mare') ? 'Mare' : 'Stallion';   // catalog sex preselects the toggle
        var ribbon = isOwned ? '<div class="ribbon">&#9733; Yours &#9733;</div>'
            : ((d.tier === 'specialty') ? '<div class="ribbon">&#9733; Specialty &#9733;</div>' : '');
        var traits = (d.traits || []).map(function (t) {
            return '<div class="trait"><div class="trait__h">' + (t.level ? '<span class="trait__lv">' + t.level + '</span>' : '') +
                '<b>' + t.name + '</b></div><p>' + (t.desc || '') + '</p></div>';
        }).join('');
        var s = d.stats || {};
        function bar(label, v) {
            return '<div class="stat"><span class="stat__l">' + label + '</span>' +
                '<span class="stat__bar"><i style="width:' + Math.max(0, Math.min(100, v || 0)) + '%"></i></span>' +
                '<span class="stat__v">' + (v || 0) + '</span></div>';
        }
        wrap.innerHTML =
            ribbon +
            '<div class="detail__breed">' + (d.breed || '') + '</div>' +
            '<h2 class="detail__name">' + (d.name || d.model) + '</h2>' +
            '<div class="attrs">' +
                '<span><i>&#9816;</i>' + (d.sex || '') + '</span>' +
                '<span><i>&#9203;</i>' + (d.age || 0) + ' yrs</span>' +
                '<span><i>&#8597;</i>' + (d.hands || 0).toFixed(1) + ' HH</span>' +
            '</div>' +
            '<p class="detail__lore">' + (d.lore || '') + '</p>' +
            (traits ? '<div class="traits">' + traits + '</div>' : '') +
            '<div class="stats">' + bar('Health', s.health) + bar('Stamina', s.stamina) + bar('Speed', s.speed) +
                bar('Acceleration', s.acceleration) + bar('Turn', s.turn) + '</div>' +
            (isOwned ? '' : '<div class="price"><b>' + money(d.cash) + '</b>' + (d.gold ? '<span> or ' + d.gold + ' <em>gold</em></span>' : '') + '</div>') +
            (isOwned
                ? '<button class="buy" id="bringout">Bring Out</button>' +
                  (d.isDefault
                    ? '<div class="detail__default">&#9733; Your default ride</div>'
                    : '<button class="buy ghost" id="mkdef">Make Default Ride</button>')
              // TRAINER-BROKERED: shown, not sold. No purchase prompt at all —
              // a button that always refuses is worse than no button.
              : d.brokered
                ? '<div class="brokered">' +
                    '<div class="brokered__h">Not sold over the counter</div>' +
                    '<p>Speak to the stable&rsquo;s <b>trainer</b> to arrange this horse.</p>' +
                  '</div>'
                : '<button class="buy" id="buy">Purchase</button>' +
                  '<div class="buyform hidden" id="buyform">' +
                    '<label class="field"><span>Name</span>' +
                      '<input id="hname" maxlength="24" spellcheck="false" placeholder="Name your horse" /></label>' +
                    '<div class="field"><span>Gender</span><div class="seg" id="sexseg">' +
                      '<button data-sex="Stallion" class="' + (defSex === 'Stallion' ? 'is-active' : '') + '">Stallion</button>' +
                      '<button data-sex="Mare" class="' + (defSex === 'Mare' ? 'is-active' : '') + '">Mare</button>' +
                    '</div></div>' +
                    '<p class="buyform__note">Chosen once, at purchase. Renaming later needs a deed.</p>' +
                    '<button class="buy" id="confirmbuy">Confirm Purchase</button>' +
                    '<button class="buy ghost" id="cancelbuy">Cancel</button>' +
                  '</div>') +
            '<div class="detail__foot">' +
                (isOwned ? 'Owned &middot; papers on file' : 'Includes ownership papers &middot; Stable slot required') +
            '</div>';
        // Purchase is a two-step: reveal the form, name her, pick a gender, confirm.
        var buy = document.getElementById('buy');
        var form = document.getElementById('buyform');
        var seg = document.getElementById('sexseg');
        function closeForm() { if (form) form.classList.add('hidden'); if (buy) buy.classList.remove('hidden'); }
        if (buy && form) {
            buy.addEventListener('click', function () {
                form.classList.remove('hidden');
                buy.classList.add('hidden');
                var n = document.getElementById('hname');
                n.value = d.name || '';
                n.focus(); n.select();
            });
        }
        if (seg) {
            seg.addEventListener('click', function (e) {
                var b = e.target.closest('button[data-sex]'); if (!b) return;
                seg.querySelectorAll('button').forEach(function (x) { x.classList.toggle('is-active', x === b); });
            });
        }
        var confirmbuy = document.getElementById('confirmbuy');
        if (confirmbuy) confirmbuy.addEventListener('click', function () {
            var input = document.getElementById('hname');
            var name = (input.value || '').trim();
            if (!name) { input.focus(); input.classList.add('invalid'); return; }
            var picked = seg && seg.querySelector('button.is-active');
            post('purchase', { model: d.model, name: name, sex: picked ? picked.dataset.sex : defSex });
            closeForm();
        });
        var cancelbuy = document.getElementById('cancelbuy');
        if (cancelbuy) cancelbuy.addEventListener('click', closeForm);
        var mkdef = document.getElementById('mkdef');
        if (mkdef) mkdef.addEventListener('click', function () { post('setDefault', { id: d.ownedId }); });
        var bringout = document.getElementById('bringout');
        if (bringout) bringout.addEventListener('click', function () { post('bringOut', { id: d.ownedId }); });
    }

    /* ---------- header ---------- */
    function renderHeader(h) {
        document.getElementById('locName').textContent = h.stableLabel || '—';
        document.getElementById('who').textContent = h.charName + (h.job ? ' — ' + h.job : '');
        document.getElementById('cash').textContent = money(h.cash);
        document.getElementById('gold').textContent = (h.gold || 0);
        document.getElementById('permTier').textContent = h.permTier || '—';
        document.getElementById('collection').textContent = (h.collection || 'Collection');
        document.getElementById('stageLoc').textContent = h.stableLabel || '';
    }

    /* ---------- open / close ---------- */
    function open(msg) {
        view = 'shop';
        breed = ALL_BREEDS;   // reset the filter per visit, not per session
        renderHeader(msg.header || {});
        rows = (msg.catalog && msg.catalog.rows) || [];
        // default to whichever tab has stock; prefer specialty
        tab = rows.some(function (r) { return (r.tier || 'stock') === 'specialty'; }) ? 'specialty' : 'stock';
        selected = (msg.detail && msg.detail.model) || (rows[0] && rows[0].model) || null;
        renderList();
        renderDetail(msg.detail || null);
        root.classList.remove('hidden');
    }
    function close() { root.classList.add('hidden'); }
    function requestClose() { close(); post('close', {}); }

    // ── HORSE CUSTOMIZER (morph panel) ──────────────────────────────────
    var czAttrs = [], czGroups = [], czValues = {};
    function czEl(id) { return document.getElementById(id); }
    function czDefault(a) { return a.kind === 'scale' ? 1.0 : 0.0; }
    function czFmt(n) { return (Math.round(n * 100) / 100).toFixed(2); }
    function czSet(a, v) { czValues[a.key] = v; post('morphPreview', { key: a.key, value: v }); }

    function renderCustom() {
        var wrap = czEl('czGroups'); wrap.innerHTML = '';
        var order = (czGroups || []).slice();
        czAttrs.forEach(function (a) { if (order.indexOf(a.group) < 0) order.push(a.group); });
        order.forEach(function (g) {
            var items = czAttrs.filter(function (a) { return a.group === g; });
            if (!items.length) return;
            var sec = document.createElement('div'); sec.className = 'cz__g';
            var gh = document.createElement('div'); gh.className = 'cz__gh'; gh.textContent = g;
            sec.appendChild(gh);
            items.forEach(function (a) {
                var v = (czValues[a.key] != null) ? czValues[a.key] : czDefault(a);
                var row = document.createElement('div'); row.className = 'cz__row';
                if (a.kind === 'toggle') {
                    var lbl = document.createElement('label'); lbl.className = 'cz__lbl'; lbl.textContent = a.label;
                    var chk = document.createElement('input'); chk.type = 'checkbox'; chk.className = 'cz__chk'; chk.checked = v >= 0.5;
                    chk.addEventListener('change', function () { czSet(a, chk.checked ? 1 : 0); });
                    row.appendChild(lbl); row.appendChild(chk);
                } else {
                    var isScale = a.kind === 'scale';
                    var lbl2 = document.createElement('label'); lbl2.className = 'cz__lbl';
                    lbl2.innerHTML = a.label + '<span class="cz__val">' + czFmt(v) + '</span>';
                    var rng = document.createElement('input'); rng.type = 'range';
                    rng.className = 'cz__rng'; rng.min = isScale ? 0.5 : -1; rng.max = isScale ? 2 : 1;
                    rng.step = 0.05; rng.value = v;
                    var valEl = lbl2.querySelector('.cz__val');
                    rng.addEventListener('input', function () {
                        var nv = parseFloat(rng.value); valEl.textContent = czFmt(nv); czSet(a, nv);
                    });
                    row.appendChild(lbl2); row.appendChild(rng);
                }
                sec.appendChild(row);
            });
            wrap.appendChild(sec);
        });
    }
    function czResetAll() {
        czAttrs.forEach(function (a) { czValues[a.key] = czDefault(a); });
        renderCustom();
        czAttrs.forEach(function (a) { post('morphPreview', { key: a.key, value: czValues[a.key] }); });
    }
    function openCustom(d) {
        czAttrs = d.attrs || []; czGroups = d.groups || []; czValues = d.values || {};
        czEl('czName').textContent = d.name || '';
        renderCustom();
        czEl('custom').classList.remove('hidden');
    }
    function closeCustom() { czEl('custom').classList.add('hidden'); post('morphClose', {}); }
    (function () {
        var s = czEl('czSave'), r = czEl('czReset'), x = czEl('czClose');
        if (s) s.addEventListener('click', function () { post('morphSave', { values: czValues }); });
        if (r) r.addEventListener('click', czResetAll);
        if (x) x.addEventListener('click', closeCustom);
    })();
    document.addEventListener('keyup', function (e) {
        if (e.key === 'Escape' && !czEl('custom').classList.contains('hidden')) closeCustom();
    });

    // ── STABLE MANAGEMENT PANEL ─────────────────────────────────────────
    var mgPanel = null, mgSection = 'overview';
    function mgEsc(s) { return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) {
        return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }
    function mgMoney(n) { return '$' + (Number(n) || 0).toLocaleString(); }

    var MG_ICON = { overview: 'horseshoe', trainer: 'horse-head', staff: 'people', breeding: 'fleur', ledger: 'ledger', settings: 'gear', admin: 'star' };
    var MG_TITLES = { overview: 'Operations Overview', trainer: 'Trainer Panel', staff: 'Staff & Roles',
        breeding: 'Breeding Register', ledger: 'Society Ledger', settings: 'Stable Settings', admin: 'System Administration' };
    function mgIcon(name, size) { return '<span class="ss-icon ss-icon--' + name + '"' + (size ? ' style="--ss-icon-size:' + size + 'px"' : '') + '></span>'; }
    function mgStat(icon, value, label) {
        return '<section class="ss-nine ss-plate-stat mg-stat">' + mgIcon(icon, 24) +
            '<strong>' + value + '</strong><small>' + mgEsc(label) + '</small></section>';
    }
    function mgOverview(o) {
        var stats = '';
        if (o.funds) stats += mgStat('coin', mgMoney(o.funds.cash), 'Society Funds');
        stats += mgStat('people', (o.onDuty || 0) + ' / ' + (o.staffCount || 0), 'Employees on Duty');
        stats += mgStat('horse-head', o.clientHorses ? o.clientHorses.total : 0, 'Client Horses');
        stats += mgStat('wagon', o.clientHorses ? o.clientHorses.ready : 0, 'Ready for Pickup');

        var staffRows = (o.staff || []).map(function (e) {
            var on = Number(e.on_duty) === 1;
            return '<section class="ss-nine ss-card-dark mg-row">' +
                '<span class="mg-ini">' + mgEsc((e.name || '?').slice(0, 2).toUpperCase()) + '</span>' +
                '<span class="mg-rt"><strong>' + mgEsc(e.name || 'Employee') + '</strong><small>' + mgEsc((e.role || '') + ' · Grade ' + (e.grade || 1)) + '</small></span>' +
                '<span class="ss-status-chip ' + (on ? 'ss-status-chip--good' : '') + '">' + (on ? 'On Duty' : 'Off Duty') + '</span></section>';
        }).join('') || '<div class="mg-empty">No employees yet.</div>';

        var ledgerHtml = '';
        if (o.funds) {
            var ledRows = (o.ledger || []).map(function (l) {
                var amt = Number(l.amount_cash) || 0;
                return '<div class="mg-lrow"><span>' + mgEsc(l.description) + '</span>' +
                    '<span class="ss-status-chip">' + mgEsc(l.category) + '</span>' +
                    '<b class="' + (amt < 0 ? 'mg-neg' : 'mg-pos') + '">' + (amt < 0 ? '-' : '+') + mgMoney(Math.abs(amt)) + '</b></div>';
            }).join('') || '<div class="mg-empty">No activity yet.</div>';
            ledgerHtml = '<h2 class="ss-section-rule"><span>Recent Ledger</span></h2><div class="ss-stack">' + ledRows + '</div>';
        }

        return '<div class="ss-grid ss-grid--2 mg-stats">' + stats + '</div>' +
            '<h2 class="ss-section-rule"><span>Staff on Duty</span></h2><div class="ss-stack">' + staffRows + '</div>' +
            ledgerHtml;
    }
    function mgSectionBody() {
        var p = mgPanel; if (!p) return '';
        if (mgSection === 'overview') return mgOverview(p.overview || {});
        return '<div class="mg-empty mg-soon">' + mgEsc(MG_TITLES[mgSection] || 'Section') +
            ' — its screen is next; the backend data is already live.</div>';
    }

    function mgRender() {
        var p = mgPanel; if (!p) return;
        var el = document.getElementById('manage');
        var rail = (p.nav || []).map(function (n) {
            return '<button class="ss-nine ss-tab-rail ss-tab-button' + (n.key === mgSection ? ' is-active' : '') +
                '" data-mg="' + n.key + '" aria-label="' + mgEsc(n.label) + '" title="' + mgEsc(n.label) + '">' + mgIcon(MG_ICON[n.key] || 'diamond') + '</button>';
        }).join('');
        el.innerHTML =
            '<main class="ss-ui">' +
              '<section class="ss-book">' +
                '<i class="ss-book-corner ss-book-corner--tl"></i><i class="ss-book-corner ss-book-corner--tr"></i>' +
                '<i class="ss-book-corner ss-book-corner--br"></i><i class="ss-book-corner ss-book-corner--bl"></i>' +
                '<header class="mg-hd">' +
                  '<span class="ss-icon ss-icon--sc-logo" style="--ss-icon-size:34px"></span>' +
                  '<span class="mg-brand"><b>Sovereign Stables</b><em>Stables &amp; Carriage Co.</em></span>' +
                  '<div class="ss-nine ss-cartouche mg-loc">' + mgEsc(p.stableName) + '</div>' +
                  '<span class="mg-who">' + mgEsc((p.playerName || '') + ' — ' + (p.roleLabel || '')) + '</span>' +
                  '<button class="ss-nine ss-btn-secondary ss-button mg-exit" data-mg="__close">Exit</button>' +
                '</header>' +
                '<nav class="ss-left-rail" aria-label="Stable sections">' + rail + '<span class="ss-left-rail__fleur"></span></nav>' +
                '<div class="ss-pages">' +
                  '<article class="ss-page">' +
                    '<header class="ss-page-header"><span class="ss-kicker">Stable Management</span>' +
                      '<h1 class="ss-page-title">' + mgEsc(MG_TITLES[mgSection] || 'Overview') + '</h1></header>' +
                    '<div class="mg-content">' + mgSectionBody() + '</div>' +
                  '</article>' +
                '</div>' +
                '<span class="ss-ribbon-bookmark"></span><span class="ss-nameplate"></span><span class="ss-book-clasp"></span>' +
              '</section>' +
            '</main>';
    }
    function mgOpen(panel) {
        mgPanel = panel; mgSection = 'overview';
        mgRender();
        document.getElementById('manage').classList.remove('hidden');
    }
    function mgClose() { document.getElementById('manage').classList.add('hidden'); mgPanel = null; post('manageClose', {}); }
    document.getElementById('manage').addEventListener('click', function (e) {
        var b = e.target.closest('[data-mg]'); if (!b) return;
        var k = b.getAttribute('data-mg');
        if (k === '__close') { mgClose(); return; }
        mgSection = k; mgRender();
    });
    document.addEventListener('keyup', function (e) {
        if (e.key === 'Escape' && !document.getElementById('manage').classList.contains('hidden')) mgClose();
    });

    window.addEventListener('message', function (ev) {
        var d = ev.data || {};
        if (d.action === 'open') open(d);
        else if (d.action === 'manage:open') mgOpen(d.panel || {});
        else if (d.action === 'custom:open') openCustom(d);
        else if (d.action === 'header') renderHeader(d.header || {});
        else if (d.action === 'detail') renderDetail(d.detail);
        else if (d.action === 'wallet') {
            document.getElementById('cash').textContent = money(d.cash);
            document.getElementById('gold').textContent = (d.gold || 0);
        }
        else if (d.action === 'owned') {
            owned = d.owned || [];
            ownedCap = d.cap || 0;
            document.getElementById('ownBadge').textContent = owned.length;
            // Default the tack room to their default ride, so Components isn't
            // dead on arrival if they never clicked a horse.
            if (!tackHorseId && owned.length) {
                var def = owned.filter(function (o) { return Number(o.is_default) === 1; })[0];
                tackHorseId = (def || owned[0]).id;
            }
            if (view === 'owned') renderList();
        }
        // Both of these arrive as TWO messages: the catalog comes straight from
        // config on the client, the owned list comes back from the server a
        // round-trip later. So only touch the keys a given message actually
        // carries — assigning `d.owned || []` here would blank the player's
        // wagons every time the catalog half arrived.
        else if (d.action === 'wagons') {
            if (d.owned) wagons = d.owned;
            if (d.cap != null) wagonCap = d.cap;
            if (d.catalog) wagonRows = d.catalog;
            document.getElementById('wagonBadge').textContent = wagons.length;
            if (view === 'wagons') renderList();
        }
        else if (d.action === 'tack') {
            if (d.owned) tackOwned = d.owned;
            if (d.categories) tackCats = d.categories;
            if (d.catalog) tackCatalog = d.catalog;
            if (d.components) {
                // Split the colour store (__tints, keyed by item id) out from the
                // worn pieces (keyed by slot), so each stays simple to render.
                var c = d.components;
                tackTints = c.__tints || {};
                tackComponents = {};
                for (var k in c) { if (k !== '__tints' && c.hasOwnProperty(k)) tackComponents[k] = c[k]; }
            }
            if (d.horseId) tackHorseId = d.horseId;
            if (!tackCat && tackCats.length) tackCat = tackCats[0].id;
            document.getElementById('tackBadge').textContent = tackOwned.length;
            if (view === 'tack') renderList();
        }
        else if (d.action === 'close') close();
    });

    /* ---------- stage: drag to orbit, scroll to zoom ---------- */
    var stage = document.getElementById('stage');
    var dragging = false, lastX = 0, lastY = 0, pending = null;
    stage.addEventListener('mousedown', function (e) { dragging = true; lastX = e.clientX; lastY = e.clientY; });
    window.addEventListener('mouseup', function () { dragging = false; });
    window.addEventListener('mousemove', function (e) {
        if (!dragging) return;
        var dx = e.clientX - lastX, dy = e.clientY - lastY;
        lastX = e.clientX; lastY = e.clientY;
        if (!pending) { pending = { dx: 0, dy: 0 }; requestAnimationFrame(flushOrbit); }
        pending.dx += dx; pending.dy += dy;
    });
    function flushOrbit() { var p = pending; pending = null; if (p) post('orbit', p); }
    stage.addEventListener('wheel', function (e) { e.preventDefault(); post('zoom', { delta: e.deltaY }); }, { passive: false });

    /* ---------- controls ---------- */
    document.querySelectorAll('.nav__item[data-view]').forEach(function (b) {
        b.addEventListener('click', function () { view = b.dataset.view; applyView(); });
    });
    // Breed filter [N1]. Picking a breed narrows the list and jumps to its first
    // horse, so the preview stage isn't left showing something you filtered out.
    var breedSel = document.getElementById('breedFilter');
    if (breedSel) {
        breedSel.addEventListener('change', function () {
            breed = breedSel.value;
            var vis = visibleRows();
            if (vis.length && !vis.some(function (r) { return r.model === selected; })) choose(vis[0].model);
            else renderList();
        });
    }

    document.getElementById('prev').addEventListener('click', function () { cycle(-1); });
    document.getElementById('next').addEventListener('click', function () { cycle(1); });
    document.getElementById('esc').addEventListener('click', requestClose);
    document.querySelectorAll('.tabs button').forEach(function (b) {
        b.addEventListener('click', function () {
            tab = b.dataset.tab;
            // Rebuild the filter for the new tab first — it may drop a breed the
            // other tab doesn't carry, and visibleRows() below depends on that.
            renderBreedFilter();
            var vis = visibleRows();
            if (vis.length && !vis.some(function (r) { return r.model === selected; })) choose(vis[0].model);
            else renderList();
        });
    });
    document.addEventListener('keyup', function (e) { if (e.key === 'Escape') requestClose(); });

    // ── DEV PREVIEW ─────────────────────────────────────────────────────
    // Opened standalone in a browser (not in-game, so GetParentResourceName is
    // undefined): auto-show the management clipboard with sample data, so the
    // design can be eyeballed without booting the server. No effect in-game.
    if (typeof GetParentResourceName !== 'function') {
        mgOpen({
            stableName: 'Loveland Stables', playerName: 'Tate Love', roleLabel: 'Owner · Grade 3', role: 'owner',
            nav: [ { key: 'overview', label: 'Overview' }, { key: 'trainer', label: 'Trainer Panel' },
                   { key: 'staff', label: 'Staff & Roles' }, { key: 'breeding', label: 'Breeding' },
                   { key: 'ledger', label: 'Ledger' }, { key: 'settings', label: 'Settings' },
                   { key: 'admin', label: 'Admin Panel' } ],
            overview: {
                funds: { cash: 12450, gold: 6 }, taxDue: 625, onDuty: 3, staffCount: 5,
                clientHorses: { total: 9, raising: 4, training: 5, ready: 2, pending: false },
                breeding: { active: 2, pending: false },
                staff: [
                    { name: 'Tate Love', role: 'owner', grade: 3, on_duty: 1 },
                    { name: 'Bebe Jewels', role: 'trainer', grade: 2, on_duty: 1 },
                    { name: 'Jesse Ricketts', role: 'trainer', grade: 2, on_duty: 1 },
                    { name: 'Elias Mercer', role: 'stablehand', grade: 1, on_duty: 0 }
                ],
                ledger: [
                    { description: 'Training payment · Riverbane', category: 'service', amount_cash: 240 },
                    { description: 'Feed and medicine', category: 'supplies', amount_cash: -145 },
                    { description: 'Society deposit', category: 'deposit', amount_cash: 500 }
                ]
            }
        });
    }
})();
