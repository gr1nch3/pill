pragma Singleton
// Shared settings search text. SettingRow hides itself when the query
// doesn't match; the settings shell filters the sidebar with it.
import QtQuick

QtObject {
    property string text: ""
}
