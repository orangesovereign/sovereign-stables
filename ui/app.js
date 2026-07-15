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

    var rows = [];          // full catalog
    var tab = 'specialty';  // active tab
    var selected = null;    // selected model id
    var owned = [];         // horses this character owns
    var ownedCap = 0;       // how many they may keep
    var view = 'shop';      // 'shop' | 'owned'

    function post(name, body) {
        return fetch('https://' + RESOURCE + '/' + name, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(body || {})
        }).catch(function () { /* preview / not in game */ });
    }

    function money(n) { return '$' + (n || 0).toLocaleString('en-US'); }
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
                renderList();
                post('selectOwned', { id: o.id });
            });
            list.appendChild(row);
        });
        document.getElementById('catFoot').textContent = owned.length + ' of ' + ownedCap;
    }

    // Swap the catalog column between the shop and the player's own horses.
    function applyView() {
        var isOwned = (view === 'owned');
        document.querySelector('.tabs').style.display = isOwned ? 'none' : '';
        document.querySelector('.cat__head').textContent = isOwned ? 'Your horses.' : 'Find your better half.';
        document.querySelector('.cat__sub').textContent = isOwned
            ? 'The ones that already answer to you.'
            : 'Every horse has a history. Choose one worthy of yours.';
        document.querySelectorAll('.nav__item[data-view]').forEach(function (b) {
            b.classList.toggle('is-active', b.dataset.view === view);
        });
        selected = null;
        renderList();
    }

    function renderList() {
        var list = document.getElementById('list');
        list.innerHTML = '';
        if (view === 'owned') { renderOwnedList(list); return; }
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

    /* ---------- detail panel ---------- */
    function renderDetail(d) {
        var wrap = document.getElementById('detail');
        if (!d) { wrap.innerHTML = ''; return; }
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
            '<div class="stats">' + bar('Health', s.health) + bar('Stamina', s.stamina) + bar('Speed', s.speed) + bar('Acceleration', s.acceleration) + '</div>' +
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
            if (view === 'owned') renderList();
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
