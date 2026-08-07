pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string displayName: ""
    property int currentValue: 0
    property int maxValue: 10000

    readonly property bool available: displayName !== ""
    readonly property real brightness: maxValue > 0 ? currentValue / maxValue : 0
    readonly property real level: brightness
    readonly property int percentage: Math.round(brightness * 100)

    Component.onCompleted: {
        detectDisplays()
        updateTimer.start()
    }

    function displayPath() {
        return displayName !== ""
            ? `/org/kde/ScreenBrightness/${displayName}`
            : ""
    }

    function detectDisplays() {
        if (!displayDetectProcess.running) {
            displayDetectProcess.command = [
                "qdbus6",
                "org.kde.ScreenBrightness",
                "/org/kde/ScreenBrightness",
                "org.kde.ScreenBrightness.DisplaysDBusNames"
            ]
            displayDetectProcess.running = true
        }
    }

    function readMaxBrightness() {
        if (!available || maxBrightnessProcess.running)
            return

        maxBrightnessProcess.command = [
            "qdbus6",
            "org.kde.ScreenBrightness",
            displayPath(),
            "org.kde.ScreenBrightness.Display.MaxBrightness"
        ]
        maxBrightnessProcess.running = true
    }

    function readBrightness() {
        if (!available || brightnessProcess.running)
            return

        brightnessProcess.command = [
            "qdbus6",
            "org.kde.ScreenBrightness",
            displayPath(),
            "org.kde.ScreenBrightness.Display.Brightness"
        ]
        brightnessProcess.running = true
    }

    function setBrightness(value) {
        if (!available || setBrightnessProcess.running)
            return

        const normalized = Math.max(0, Math.min(1, value))
        const target = Math.round(normalized * maxValue)

        // Use Plasma's own brightness service so the system tray, OSD and
        // Quickshell all observe the same value. The final 0 keeps KDE's OSD.
        setBrightnessProcess.command = [
            "qdbus6",
            "org.kde.ScreenBrightness",
            displayPath(),
            "org.kde.ScreenBrightness.Display.SetBrightness",
            `${target}`,
            "0"
        ]
        setBrightnessProcess.running = true

        // Update optimistically; the next D-Bus read confirms the real value.
        currentValue = target
    }

    function increaseBrightness() {
        setBrightness(brightness + 0.05)
    }

    function decreaseBrightness() {
        setBrightness(brightness - 0.05)
    }

    Process {
        id: displayDetectProcess
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const names = text.trim().split(/\s+/).filter(name => name.length > 0)
                root.displayName = names.length > 0 ? names[0] : ""

                if (root.available) {
                    root.readMaxBrightness()
                    root.readBrightness()
                }
            }
        }
    }

    Process {
        id: maxBrightnessProcess
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const value = parseInt(text.trim())
                if (!isNaN(value) && value > 0)
                    root.maxValue = value
            }
        }
    }

    Process {
        id: brightnessProcess
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const value = parseInt(text.trim())
                if (!isNaN(value) && value >= 0)
                    root.currentValue = value
            }
        }
    }

    Process {
        id: setBrightnessProcess
        running: false
        onExited: root.readBrightness()
    }

    Timer {
        id: updateTimer
        interval: 1500
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.available)
                root.readBrightness()
            else
                root.detectDisplays()
        }
    }
}
