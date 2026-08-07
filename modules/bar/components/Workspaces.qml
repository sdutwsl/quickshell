import Quickshell
import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../../config" as QsConfig
import "../../../services" as QsServices

// Plasma virtual desktops, backed by KWin's session D-Bus interface.
// The active window title shares this same outer AuroraSurface in Bar.qml.
Item {
    id: root
    
    property var screen
    
    readonly property var config: QsConfig.Config
    readonly property var pywal: QsServices.Pywal
    readonly property var kdeDesktops: QsServices.KdeVirtualDesktops

    implicitWidth: layout.implicitWidth
    implicitHeight: config.bar.height - config.bar.padding * 2
    
    RowLayout {
        id: layout
        
        anchors.centerIn: parent
        spacing: root.config.bar.workspaces.spacing
        
        Repeater {
            id: workspaceRepeater
            model: root.kdeDesktops.desktops

            delegate: Loader {
                id: workspaceLoader
                required property var modelData

                source: "Workspace.qml"
                asynchronous: false

                Binding {
                    target: workspaceLoader.item
                    property: "workspaceId"
                    value: workspaceLoader.modelData.number
                    when: workspaceLoader.status === Loader.Ready
                }

                Binding {
                    target: workspaceLoader.item
                    property: "isActive"
                    value: workspaceLoader.modelData.id === root.kdeDesktops.currentId
                    when: workspaceLoader.status === Loader.Ready
                }

                Binding {
                    target: workspaceLoader.item
                    property: "isOccupied"
                    value: false
                    when: workspaceLoader.status === Loader.Ready
                }

                Connections {
                    target: workspaceLoader.item
                    enabled: workspaceLoader.status === Loader.Ready

                    function onClicked() {
                        root.kdeDesktops.activate(workspaceLoader.modelData)
                    }
                }
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 1
            Layout.preferredHeight: 12
            visible: activeWindowLoader.item?.hasWindow ?? false
            color: Qt.rgba(root.pywal.foreground.r, root.pywal.foreground.g, root.pywal.foreground.b, 0.14)
        }

        Loader {
            id: activeWindowLoader
            Layout.alignment: Qt.AlignVCenter
            asynchronous: true
            source: "ActiveWindow.qml"

            Binding {
                target: activeWindowLoader.item
                property: "embedded"
                value: true
                when: activeWindowLoader.status === Loader.Ready
                restoreMode: Binding.RestoreBinding
            }
        }
    }
}
