pragma Singleton
// One owner for pactl: default sink/source + full device lists, live via
// `pactl subscribe`. Callers ask for devices and verbs, never command strings.
import QtQuick
import "../utils"

Item {
    id: root

    // [{ id, label, volume, muted, isDefault }]
    property var sinks: []
    property var sources: []

    readonly property var defaultSink: _defaultOf(sinks)
    readonly property var defaultSource: _defaultOf(sources)

    // Default-output convenience for the OSD and volume keys.
    readonly property int percent: defaultSink ? defaultSink.volume : 0
    readonly property bool muted: defaultSink ? defaultSink.muted : false
    readonly property bool micMuted: defaultSource ? defaultSource.muted : false

    signal changed

    property string _defSinkId: ""
    property string _defSourceId: ""
    property var _sinkBuf: []
    property var _sourceBuf: []
    property int _lastPercent: -1
    property bool _lastMuted: false

    function _defaultOf(list) {
        for (var i = 0; i < list.length; i++)
            if (list[i].isDefault) return list[i]
        return list.length > 0 ? list[0] : null
    }

    function _withDefault(buf, defId) {
        var out = []
        for (var i = 0; i < buf.length; i++) {
            var d = buf[i]
            out.push({ id: d.id, label: d.label, volume: d.volume, muted: d.muted, isDefault: d.id === defId })
        }
        return out
    }

    function refresh() {
        sinkCmd.run()
        sourceCmd.run()
    }

    function _find(id) {
        for (var i = 0; i < sinks.length; i++)
            if (sinks[i].id === id) return { kind: "sink", device: sinks[i] }
        for (var j = 0; j < sources.length; j++)
            if (sources[j].id === id) return { kind: "source", device: sources[j] }
        return null
    }

    function _update(id, patch) {
        var hit = _find(id)
        if (!hit) return
        var list = hit.kind === "sink" ? sinks : sources
        var out = []
        for (var i = 0; i < list.length; i++) {
            var d = list[i]
            if (d.id !== id) { out.push(d); continue }
            var copy = { id: d.id, label: d.label, volume: d.volume, muted: d.muted, isDefault: d.isDefault }
            for (var k in patch) copy[k] = patch[k]
            out.push(copy)
        }
        if (hit.kind === "sink") sinks = out
        else sources = out
    }

    // id omitted => the default output device (OSD/volume-key callers).
    function setVolume(id, pct) {
        if (id === undefined) id = defaultSink ? defaultSink.id : ""
        var hit = _find(id)
        if (!hit) return
        pct = Math.max(0, Math.min(150, Math.round(pct)))
        actionCmd.command = ["pactl", hit.kind === "sink" ? "set-sink-volume" : "set-source-volume", id, pct + "%"]
        actionCmd.run()
        _update(id, { volume: pct })
    }

    function setPercent(pct) {
        if (defaultSink) setVolume(defaultSink.id, pct)
    }

    function adjust(delta) {
        if (defaultSink) setVolume(defaultSink.id, defaultSink.volume + delta)
    }

    // id omitted => the default output device.
    function toggleMute(id) {
        if (id === undefined) id = defaultSink ? defaultSink.id : ""
        var hit = _find(id)
        if (!hit) return
        actionCmd.command = ["pactl", hit.kind === "sink" ? "set-sink-mute" : "set-source-mute", id, "toggle"]
        actionCmd.run()
        _update(id, { muted: !hit.device.muted })
    }

    function toggleMic() {
        if (defaultSource) toggleMute(defaultSource.id)
    }

    function setDefaultSink(id) {
        actionCmd.command = ["pactl", "set-default-sink", id]
        actionCmd.run()
        refresh()
    }

    function setDefaultSource(id) {
        actionCmd.command = ["pactl", "set-default-source", id]
        actionCmd.run()
        refresh()
    }

    function _notifyDefault() {
        var ds = defaultSink
        if (!ds) return
        if (root._lastPercent !== -1 && (ds.volume !== root._lastPercent || ds.muted !== root._lastMuted))
            root.changed()
        root._lastPercent = ds.volume
        root._lastMuted = ds.muted
    }

    // ── pactl adapter ──────────────────────────────────────────────────────
    readonly property string sinkScript: "cur=$(pactl get-default-sink 2>/dev/null || true)\n" +
        "printf 'DEFAULT:%s\\n' \"$cur\"\n" +
        "pactl --format=json list sinks 2>/dev/null | jq -c '.[] | {id: .name, label: .description, volume: (([.volume[].value_percent | sub(\"%\";\"\") | tonumber] | max) // 0), muted: .mute}' 2>/dev/null || true"

    readonly property string sourceScript: "cur=$(pactl get-default-source 2>/dev/null || true)\n" +
        "printf 'DEFAULT:%s\\n' \"$cur\"\n" +
        "pactl --format=json list sources 2>/dev/null | jq -c '.[] | select((.name | contains(\".monitor\")) | not) | {id: .name, label: .description, volume: (([.volume[].value_percent | sub(\"%\";\"\") | tonumber] | max) // 0), muted: .mute}' 2>/dev/null || true"

    Cmd {
        id: sinkCmd
        command: ["bash", "-c", root.sinkScript]
        autorun: false
        onLine: function(line) {
            if (line.indexOf("DEFAULT:") === 0) { root._defSinkId = line.slice(8); return }
            var d = Store.parse(line)
            if (d) root._sinkBuf.push(d)
        }
        onDone: {
            root.sinks = root._withDefault(root._sinkBuf, root._defSinkId)
            root._sinkBuf = []
            root._notifyDefault()
        }
    }

    Cmd {
        id: sourceCmd
        command: ["bash", "-c", root.sourceScript]
        autorun: false
        onLine: function(line) {
            if (line.indexOf("DEFAULT:") === 0) { root._defSourceId = line.slice(8); return }
            var d = Store.parse(line)
            if (d) root._sourceBuf.push(d)
        }
        onDone: {
            root.sources = root._withDefault(root._sourceBuf, root._defSourceId)
            root._sourceBuf = []
        }
    }

    Cmd {
        command: ["pactl", "subscribe"]
        onLine: function(line) {
            if (line.indexOf("'change' on sink") >= 0 || line.indexOf("'change' on source") >= 0
                || line.indexOf("'change' on server") >= 0)
                root.refresh()
        }
    }

    Cmd { id: actionCmd; autorun: false }

    Component.onCompleted: root.refresh()
}
