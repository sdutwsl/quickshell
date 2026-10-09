import QtQuick 6.10
import "../../../services" as QsServices
import "../../../components/effects"

Item {
    id: root

    property var bar

    readonly property var dida: QsServices.Dida
    readonly property var pywal: QsServices.Pywal
    readonly property bool isActive: bar?.activePopup === "dida"
    readonly property bool isHovered: mouse.containsMouse

    implicitWidth: taskIcon.implicitWidth + (badge.visible ? badge.width + 4 : 8)
    implicitHeight: taskIcon.implicitHeight

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            if (!bar)
                return

            bar.togglePopup("dida")
            if (bar.activePopup === "dida")
                dida.refresh()
        }
    }

    Text {
        id: taskIcon
        anchors.centerIn: parent
        text: "󰄲"
        font.family: "Material Design Icons"
        font.pixelSize: 18
        color: dida.errorText.length > 0
            ? pywal.error
            : (isActive || isHovered ? pywal.primary : pywal.foreground)

        Behavior on color {
            ColorAnimation {
                duration: Material3Anim.short3
                easing.bezierCurve: Material3Anim.standard
            }
        }

        scale: mouse.pressed ? 0.92 : (isHovered || isActive ? 1.08 : 1.0)
        Behavior on scale {
            NumberAnimation {
                duration: Material3Anim.short2
                easing.bezierCurve: Material3Anim.standard
            }
        }
    }

    Rectangle {
        id: badge
        anchors.left: taskIcon.right
        anchors.leftMargin: 2
        anchors.top: taskIcon.top
        width: Math.max(16, badgeText.implicitWidth + 8)
        height: 16
        radius: 8
        visible: dida.openCount > 0
        color: Qt.rgba(pywal.primary.r, pywal.primary.g, pywal.primary.b, 0.9)

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: dida.openCount > 99 ? "99+" : String(dida.openCount)
            font.family: "Inter"
            font.pixelSize: 9
            font.weight: Font.Bold
            color: pywal.background
        }
    }
}
