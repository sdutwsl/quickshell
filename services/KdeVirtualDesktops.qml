pragma Singleton

import QtQuick 6.10
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var desktops: []
    property string currentId: ""

    function refreshDesktops() {
        if (!desktopsProcess.running)
            desktopsProcess.running = true
    }

    function refreshCurrent() {
        if (!currentProcess.running)
            currentProcess.running = true
    }

    function refresh() {
        refreshDesktops()
        refreshCurrent()
    }

    function activate(desktop: var) {
        if (!desktop?.id || desktop.id === currentId)
            return

        setCurrentProcess.exec([
            "busctl", "--user", "set-property",
            "org.kde.KWin", "/VirtualDesktopManager",
            "org.kde.KWin.VirtualDesktopManager", "current", "s", desktop.id
        ])
    }

    Process {
        id: desktopsProcess
        command: [
            "busctl", "--user", "get-property",
            "org.kde.KWin", "/VirtualDesktopManager",
            "org.kde.KWin.VirtualDesktopManager", "desktops"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const desktopPattern = /(\d+)\s+"([^"]+)"\s+"([^"]*)"/g
                const desktops = []
                let match

                while ((match = desktopPattern.exec(text)) !== null) {
                    desktops.push({
                        number: Number(match[1]) + 1,
                        id: match[2],
                        name: match[3]
                    })
                }

                root.desktops = desktops
            }
        }
    }

    Process {
        id: currentProcess
        command: [
            "busctl", "--user", "get-property",
            "org.kde.KWin", "/VirtualDesktopManager",
            "org.kde.KWin.VirtualDesktopManager", "current"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/^s\s+"([^"]+)"/)
                if (match)
                    root.currentId = match[1]
            }
        }
    }

    Process {
        id: setCurrentProcess
        onExited: root.refreshCurrent()
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: root.refreshCurrent()
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refreshDesktops()
    }
}
