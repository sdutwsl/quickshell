import Quickshell
import QtQuick 6.10
import QtQuick.Layouts 6.10
import qs.services
import "../../../components/effects"

Item {
    id: root

    property var launcher
    property var controlCenter
    property var sidebar
    property var dashboard

    readonly property var weekdayNames: [
        "星期日",
        "星期一",
        "星期二",
        "星期三",
        "星期四",
        "星期五",
        "星期六"
    ]

    implicitWidth: clockText.implicitWidth
    implicitHeight: clockText.implicitHeight

    Text {
        id: clockText
        anchors.centerIn: parent
        text: `${Time.format("yyyy年MM月dd日")} ${root.weekdayNames[Time.date.getDay()]} ${Time.format("HH:mm:ss")}`
        color: Pywal.foreground
        font.pixelSize: 12
        font.weight: Font.Bold
        font.family: "Inter"
        font.letterSpacing: 0.25
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                const value = Time.format("yyyy-MM-dd HH:mm:ss")
                Quickshell.execDetached([
                    "/bin/sh", "-c",
                    "printf '%s' \"$1\" | wl-copy",
                    "sh", value
                ])
                return
            }

            if (!root.dashboard)
                return

            root.dashboard.shouldShow = !root.dashboard.shouldShow
            if (root.dashboard.shouldShow) {
                if (root.controlCenter)
                    root.controlCenter.shouldShow = false
                if (root.sidebar)
                    root.sidebar.shouldShow = false
            }
        }
    }
}
