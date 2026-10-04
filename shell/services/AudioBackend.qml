import QtQuick

// Adapter: Audio -> generic device rows + verbs for DeviceSelect.
// `kind`: "sink" (outputs) or "source" (inputs).
Item {
    id: root

    property string kind: "sink"

    readonly property string title: kind === "sink" ? "Audio Outputs" : "Audio Inputs"
    readonly property bool powerOn: false
    readonly property bool powerBlocked: false
    readonly property bool asyncConnect: false
    readonly property bool canRescan: false

    readonly property var items: {
        var list = kind === "sink" ? Audio.sinks : Audio.sources
        var out = []
        for (var i = 0; i < list.length; i++) {
            var d = list[i]
            out.push({
                label: d.label,
                value: d.id,
                devState: d.isDefault ? "active" : "",
                signal: 0,
                secure: false,
                volume: d.volume,
                muted: d.muted,
                group: "",
                deviceIcon: "",
                battery: -1,
                batteryAvailable: false,
                trusted: false,
                blocked: false,
                pairing: false,
                saved: false
            })
        }
        return out
    }

    signal status(string id, string text, string kind)
    signal authRequired(string id)

    function connect(id, secret) {
        if (kind === "sink") Audio.setDefaultSink(id)
        else Audio.setDefaultSource(id)
    }

    function togglePower() {}
    function disconnect(id) {}
    function forget(id) {}
    function pair(id) {}
    function cancelPair(id) {}
    function rescan() {}
    function openSettings() {}
    function refresh() { Audio.refresh() }
}
