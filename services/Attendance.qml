pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick 6.10

Singleton {
    id: root

    property string status: "等待刷新"
    property bool checking: false

    function refresh() {
        if (!readProcess.running)
            readProcess.running = true
    }

    function checkNow() {
        if (checkProcess.running)
            return
        checking = true
        status = "检查中…"
        checkProcess.running = true
    }

    Process {
        id: readProcess
        command: ["/bin/sh", "-c", "cat /tmp/attendance_waybar 2>/dev/null || echo '等待刷新'"]

        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim()
                root.status = value.length > 0 ? value : "等待刷新"
            }
        }
    }

    Process {
        id: checkProcess
        command: ["systemctl", "--user", "start", "ncc-attendance.service"]
        onExited: {
            root.checking = false
            root.refresh()
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
