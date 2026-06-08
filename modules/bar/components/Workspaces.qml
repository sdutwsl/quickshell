import Quickshell
import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../../config" as QsConfig
import "../../../services" as QsServices

// Static workspace markers. Compositor-specific workspace switching is kept out
// of this fork so the shell can run under Plasma and other Wayland sessions.
Item {
    id: root
    
    property var screen
    
    readonly property var config: QsConfig.Config
    readonly property var pywal: QsServices.Pywal
    
    implicitWidth: layout.implicitWidth
    implicitHeight: config.bar.height - config.bar.padding * 2
    
    RowLayout {
        id: layout
        
        anchors.centerIn: parent
        spacing: root.config.bar.workspaces.spacing
        
        Repeater {
            id: workspaceRepeater
            model: root.config.bar.workspaces.count
            
            delegate: Loader {
                required property int index
                
                source: "Workspace.qml"
                asynchronous: false
                
                onLoaded: {
                    item.workspaceId = index + 1
                    item.isActive = index === 0
                    item.isOccupied = false
                }
            }
        }
    }
}
