import QtQuick 6.10
import QtQuick.Layouts 6.10
import qs.services

Item {
    id: root

    readonly property bool hasLyric: Lyrics.currentLyric.length > 0

    implicitWidth: hasLyric ? Math.min(lyricRow.implicitWidth, 300) : 0
    implicitHeight: 20
    visible: hasLyric

    RowLayout {
        id: lyricRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: "󰎈"
            font.family: "Material Design Icons"
            font.pixelSize: 14
            color: Pywal.primary
        }

        Text {
            Layout.maximumWidth: 274
            text: Lyrics.currentLyric
            font.family: "Inter"
            font.pixelSize: 10
            font.weight: Font.Medium
            color: Pywal.foreground
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Lyrics.copyCurrentLyric()
    }
}
