/* =====================================================================
   SOVEREIGN STABLES · NUI SHELL LOGIC
   Phase 0: open/close + focus handshake with the client. No screens yet.
   ===================================================================== */
(function () {
    'use strict';

    var root = document.getElementById('root');
    var closeBtn = document.getElementById('closeBtn');

    // Resource name for NUI callbacks (fallback keeps a browser preview happy).
    var RESOURCE = (typeof GetParentResourceName === 'function')
        ? GetParentResourceName()
        : 'sovereign_stables';

    function show() { root.classList.remove('hidden'); }
    function hide() { root.classList.add('hidden'); }

    // Tell the client to drop NUI focus. Guarded so it no-ops in a browser.
    function requestClose() {
        hide();
        fetch('https://' + RESOURCE + '/close', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({})
        }).catch(function () { /* preview / not in game */ });
    }

    // Messages from client/core.lua
    window.addEventListener('message', function (event) {
        var data = event.data || {};
        if (data.action === 'open') { show(); }
        else if (data.action === 'close') { hide(); }
    });

    // Esc closes; click closes.
    document.addEventListener('keyup', function (e) {
        if (e.key === 'Escape') { requestClose(); }
    });
    if (closeBtn) { closeBtn.addEventListener('click', requestClose); }
})();
