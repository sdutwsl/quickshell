pragma Singleton

import Quickshell.Io
import QtQuick 6.10

Singleton {
    id: root

    property string title: ""

    function refresh() {
        if (!windowProcess.running)
            windowProcess.running = true
    }

    Process {
        id: windowProcess
        command: ["kdotool", "getactivewindow", "getwindowname"]

        stdout: StdioCollector {
            onStreamFinished: root.title = text.trim()
        }

        onExited: exitCode => {
            if (exitCode !== 0)
                root.title = ""
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
