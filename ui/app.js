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

    function renderList() {
        var list = document.getElementById('list');
        list.innerHTML = '';
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
        var vis = visibleRows(); if (!vis.length) return;
        var i = vis.findIndex(function (r) { return r.model === selected; });
        i = (i + dir + vis.length) % vis.length;
        choose(vis[i].model);
    }

    /* ---------- detail panel ---------- */
    function renderDetail(d) {
        var wrap = document.getElementById('detail');
        if (!d) { wrap.innerHTML = ''; return; }
        var ribbon = (d.tier === 'specialty') ? '<div class="ribbon">&#9733; Specialty &#9733;</div>' : '';
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
            '<div class="price"><b>' + money(d.cash) + '</b>' + (d.gold ? '<span> or ' + d.gold + ' <em>gold</em></span>' : '') + '</div>' +
            '<button class="buy" id="buy">Request Purchase</button>' +
            '<div class="detail__foot">Includes ownership papers &middot; Stable slot required</div>';
        var buy = document.getElementById('buy');
        if (buy) buy.addEventListener('click', function () { post('purchase', { model: d.model }); });
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
