import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Services.SystemTray

RowLayout {
    id: root

    property var barWindow
    readonly property bool hasItems: SystemTray.items.values.length > 0

    spacing: 4

    function showMenu(item, anchor) {
        if (!item.hasMenu || root.barWindow === undefined) {
            return false
        }

        const point = anchor.mapToItem(null, anchor.width / 2, anchor.height)
        item.display(root.barWindow, Math.round(point.x), Math.round(point.y))
        return true
    }

    Repeater {
        model: SystemTray.items

        delegate: Rectangle {
            id: trayItem

            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            radius: 4
            color: "transparent"

            Behavior on color {
                ColorAnimation { duration: 120 }
            }

            Image {
                anchors.centerIn: parent
                width: 16
                height: 16
                source: modelData.icon
                sourceSize.width: width
                sourceSize.height: height
                fillMode: Image.PreserveAspectFit
                smooth: false
                mipmap: false
                visible: status === Image.Ready
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                hoverEnabled: true
                onEntered: trayItem.color = Qt.rgba(1, 1, 1, 0.08)
                onExited: trayItem.color = "transparent"

                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) {
                        if (modelData.onlyMenu && root.showMenu(modelData, trayItem)) {
                            return
                        }

                        modelData.activate()
                    } else if (mouse.button === Qt.RightButton) {
                        root.showMenu(modelData, trayItem)
                    } else if (mouse.button === Qt.MiddleButton) {
                        modelData.secondaryActivate()
                    }
                }

                onWheel: wheel => {
                    if (Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y)) {
                        modelData.scroll(wheel.angleDelta.x, true)
                    } else {
                        modelData.scroll(wheel.angleDelta.y, false)
                    }
                }
            }
        }
    }
}
