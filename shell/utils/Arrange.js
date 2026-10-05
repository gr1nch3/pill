// Display-arrangement geometry for the Displays page: pure functions over
// plain displays { name, x, y, w, h, disabled } where w/h are LOGICAL
// footprints (physical pixels / scale, axes swapped when rotated), x/y in
// compositor layout coordinates. Kept out of QML so the snap/tidy math can be
// unit-tested (Arrange.test.mjs) — this is the logic behind the classic
// "cursor can't cross between screens" gap bug, which needs two monitors to
// even reproduce by hand.
//
// Adapted from the arrangement geometry in neur0map/ryoku-arch (ryoku/hub/
// quickshell/pages/lib/arrange.js), trimmed to what Bubbles' canvas uses.
// Functions mutate x/y in place.

// True when display i shares a full edge with another enabled display AND
// overlaps it on the perpendicular axis, i.e. the cursor can cross between
// them. A lone display (nothing else enabled) counts as fine.
function touchesAny(mons, i) {
    var m = mons[i];
    var mx2 = m.x + m.w, my2 = m.y + m.h;
    var lone = true;
    for (var j = 0; j < mons.length; j++) {
        if (j === i || mons[j].disabled)
            continue;
        lone = false;
        var o = mons[j];
        var ox2 = o.x + o.w, oy2 = o.y + o.h;
        var hTouch = (mx2 === o.x || ox2 === m.x)
            && Math.min(my2, oy2) - Math.max(m.y, o.y) > 0;
        var vTouch = (my2 === o.y || oy2 === m.y)
            && Math.min(mx2, ox2) - Math.max(m.x, o.x) > 0;
        if (hTouch || vTouch)
            return true;
    }
    return lone;
}

// Pull display i flush against its nearest enabled neighbour, on whichever
// axis dominates the offset, clamped so they keep a crossable overlap (>= a
// quarter of the smaller side). No-op when there is no other enabled display.
function attachFlush(mons, i) {
    var m = mons[i];
    var mcx = m.x + m.w / 2, mcy = m.y + m.h / 2;
    var best = -1, bd = Infinity;
    for (var j = 0; j < mons.length; j++) {
        if (j === i || mons[j].disabled)
            continue;
        var o = mons[j];
        var d = Math.pow(o.x + o.w / 2 - mcx, 2) + Math.pow(o.y + o.h / 2 - mcy, 2);
        if (d < bd) { bd = d; best = j; }
    }
    if (best < 0)
        return;
    var n = mons[best];
    var dx = mcx - (n.x + n.w / 2), dy = mcy - (n.y + n.h / 2);
    if (Math.abs(dx) >= Math.abs(dy)) {
        m.x = dx >= 0 ? n.x + n.w : n.x - m.w;
        var ovy = Math.max(1, Math.min(m.h, n.h) * 0.25);
        m.y = Math.max(n.y - m.h + ovy, Math.min(m.y, n.y + n.h - ovy));
    } else {
        m.y = dy >= 0 ? n.y + n.h : n.y - m.h;
        var ovx = Math.max(1, Math.min(m.w, n.w) * 0.25);
        m.x = Math.max(n.x - m.w + ovx, Math.min(m.x, n.x + n.w - ovx));
    }
    m.x = Math.round(m.x);
    m.y = Math.round(m.y);
}

// Ensure every enabled display is part of one connected block. Bounded passes
// converge for any realistic monitor count. Returns true if it moved anything.
function tidyGaps(mons) {
    var changed = false;
    for (var pass = 0; pass < mons.length; pass++) {
        var any = false;
        for (var i = 0; i < mons.length; i++) {
            if (mons[i].disabled)
                continue;
            if (!touchesAny(mons, i)) {
                attachFlush(mons, i);
                any = true;
                changed = true;
            }
        }
        if (!any)
            break;
    }
    return changed;
}

// The main display is the one at the global origin; fall back to the
// top-left-most enabled display when none sits exactly at 0,0.
function deriveMain(mons) {
    var best = "", bx = Infinity, by = Infinity, exact = "";
    for (var i = 0; i < mons.length; i++) {
        var m = mons[i];
        if (m.disabled)
            continue;
        if (m.x === 0 && m.y === 0)
            exact = m.name;
        if (m.x < bx || (m.x === bx && m.y < by)) { bx = m.x; by = m.y; best = m.name; }
    }
    return exact || best;
}

if (typeof module !== "undefined" && module.exports)
    module.exports = { touchesAny, attachFlush, tidyGaps, deriveMain };
