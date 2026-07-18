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
    var tackHorseId = null; // which owned horse we're fitting

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
    function visibleRows() { return rows.filter(function (r) { return (r.tier || 'stock') === tab; }); }

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
        // Category strip
        var strip = el('div', 'catstrip');
        tackCats.forEach(function (c) {
            var b = el('button', 'catstrip__b' + (c.id === tackCat ? ' is-active' : ''), c.label);
            b.addEventListener('click', function () { tackCat = c.id; renderList(); });
            strip.appendChild(b);
        });
        list.appendChild(strip);

        var items = (tackCatalog[tackCat] || []);
        if (!items.length) {
            list.appendChild(el('div', 'empty', 'Nothing in this category yet.'));
        }
        items.forEach(function (t) {
            var isOwnedPiece = tackOwned.some(function (o) { return o.item === t.id; });
            var isWorn = tackComponents[t.slot] === t.id;
            var row = el('button', 'row' + (isWorn ? ' is-active' : ''));
            var right = isWorn ? '<span class="row__price">&#10003; Fitted</span>'
                : isOwnedPiece ? '<span class="row__price">Owned</span>'
                : '<span class="row__price">' + money(t.cash) + '</span>';
            row.innerHTML =
                '<span class="row__portrait">&#9109;</span>' +
                '<span class="row__t"><span class="row__name">' + t.label + '</span>' +
                '<span class="row__breed">' + (isOwnedPiece ? 'Yours — fit it to any horse' : 'For sale') + '</span></span>' + right;
            row.addEventListener('click', function () {
                if (isWorn) post('removeTack', { horseId: tackHorseId, slot: t.slot });
                else if (isOwnedPiece) post('applyTack', { horseId: tackHorseId, item: t.id });
                else post('buyTack', { item: t.id });
            });
            list.appendChild(row);
        });
        document.getElementById('catFoot').textContent = tackOwned.length + ' piece' + (tackOwned.length === 1 ? '' : 's') + ' owned';
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
        var vis = visibleRows();
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
        document.querySelectorAll('.tabs button').forEach(function (b) {
            b.classList.toggle('is-active', b.dataset.tab === tab);
        });
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
                : '<button class="buy" id="buywagon">Request Purchase</button>' +
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
                : '<button class="buy" id="buy">Request Purchase</button>' +
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

    window.addEventListener('message', function (ev) {
        var d = ev.data || {};
        if (d.action === 'open') open(d);
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
            if (d.components) tackComponents = d.components;
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
    document.getElementById('prev').addEventListener('click', function () { cycle(-1); });
    document.getElementById('next').addEventListener('click', function () { cycle(1); });
    document.getElementById('esc').addEventListener('click', requestClose);
    document.querySelectorAll('.tabs button').forEach(function (b) {
        b.addEventListener('click', function () {
            tab = b.dataset.tab;
            var vis = visibleRows();
            if (vis.length && !vis.some(function (r) { return r.model === selected; })) choose(vis[0].model);
            else renderList();
        });
    });
    document.addEventListener('keyup', function (e) { if (e.key === 'Escape') requestClose(); });
})();
