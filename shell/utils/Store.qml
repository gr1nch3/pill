pragma Singleton
// The one JSON persistence incantation: mkdir, one-time legacy move, jq read;
// printf write. Services keep their schemas, Store keeps the shell plumbing.
import QtQuick
import "shquote.js" as Sh

QtObject {
    function dirOf(path) {
        return String(path).replace(/\/[^\/]*$/, "");
    }

    // bash -c string: create the parent dir and move legacyPath into place once.
    function migrateCommand(path, legacyPath) {
        var cmd = "mkdir -p " + Sh.q(dirOf(path)) + "\n";
        if (legacyPath)
            cmd += "[ -f " + Sh.q(path) + " ] || [ ! -f " + Sh.q(legacyPath) + " ] || mv " + Sh.q(legacyPath) + " " + Sh.q(path) + "\n";
        return cmd;
    }

    // bash -c string: migrate, then print compact JSON (jq) for parsing.
    function loadCommand(path, legacyPath) {
        return migrateCommand(path, legacyPath) + "jq -c . " + Sh.q(path) + " 2>/dev/null || true";
    }

    function saveCommand(path, json) {
        return "mkdir -p " + Sh.q(dirOf(path)) + " && printf '%s' " + Sh.q(json) + " > " + Sh.q(path);
    }

    function parse(text) {
        if (!text || String(text).trim() === "")
            return null;
        try {
            return JSON.parse(text);
        } catch (e) {
            console.warn("Store: failed to parse JSON:", e);
            return null;
        }
    }
}
