import QtQuick 6.10
import QtQuick.Layouts 6.10
import qs.services

Item {
    id: root

    readonly property bool hasWindow: ActiveWindow.title.length > 0

    implicitWidth: hasWindow ? Math.min(windowRow.implicitWidth, 190) : 0
    implicitHeight: 20
    visible: hasWindow

    RowLayout {
        id: windowRow
        anchors.centerIn: parent
        spacing: 5

        Text {
            text: "󰖯"
            font.family: "Material Design Icons"
            font.pixelSize: 13
            color: Pywal.secondary
        }

        Text {
            Layout.maximumWidth: 168
            text: ActiveWindow.title
            font.family: "Inter"
            font.pixelSize: 10
            font.weight: Font.Medium
            color: Pywal.foreground
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
        }
    }
}
