import Quickshell
import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../../config" as QsConfig
import "../../../services" as QsServices

// Plasma virtual desktops, backed by KWin's session D-Bus interface.
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
    }
}
