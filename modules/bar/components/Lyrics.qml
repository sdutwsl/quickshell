import QtQuick 6.10
import QtQuick.Layouts 6.10
import qs.services

// Kept as a compatibility component for the old standalone Bar loader.
// The actual lyric UI now lives inside MediaPlayer.qml.
Item {
    id: root

    property bool embedded: false
    readonly property bool hasLyric: embedded && Lyrics.currentLyric.length > 0

    implicitWidth: 0
    implicitHeight: 20
    visible: false
}
