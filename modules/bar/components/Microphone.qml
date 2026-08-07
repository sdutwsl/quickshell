import QtQuick 6.10
import QtQuick.Layouts 6.10
import qs.services

Item {
    id: root

    readonly property bool ready: Audio.sourceReady
    readonly property bool muted: Audio.sourceMuted
    readonly property int percentage: Audio.sourcePercentage

    implicitWidth: ready ? micRow.implicitWidth : 0
    implicitHeight: 20
    visible: ready

    RowLayout {
        id: micRow
        anchors.centerIn: parent
        spacing: 3

        Text {
            text: root.muted ? "󰍭" : "󰍬"
            font.family: "Material Design Icons"
            font.pixelSize: 14
            color: root.muted
                ? Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.35)
                : Pywal.foreground
        }

        Text {
            text: root.percentage
            font.family: "Inter"
            font.pixelSize: 10
            font.weight: Font.Medium
            color: root.muted
                ? Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.35)
                : Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.7)
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Audio.toggleSourceMute()
        onWheel: wheel => {
            const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05
            Audio.setSourceVolume(Audio.sourceVolume + step)
        }
    }
}
