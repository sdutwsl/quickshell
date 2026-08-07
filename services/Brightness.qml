pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string displayObjectPath: ""
    property int currentValue: 0
    property int maxValue: 10000
    property int pendingTarget: -1

    readonly property bool available: displayObjectPath !== ""
    readonly property real brightness: maxValue > 0 ? currentValue / maxValue : 0
    readonly property real level: brightness
    readonly property int percentage: Math.round(brightness * 100)

    Component.onCompleted: {
        detectDisplay()
        updateTimer.start()
    }

    function detectDisplay() {
        if (displayDetectProcess.running)
            return

        displayDetectProcess.command = [
            "busctl", "--user", "tree", "org.kde.ScreenBrightness"
        ]
        displayDetectProcess.running = true
    }

    function readMaxBrightness() {
        if (!available || maxBrightnessProcess.running)
            return

        maxBrightnessProcess.command = [
            "busctl", "--user", "get-property",
            "org.kde.ScreenBrightness",
            displayObjectPath,
            "org.kde.ScreenBrightness.Display",
            "MaxBrightness"
        ]
        maxBrightnessProcess.running = true
    }

    function readBrightness() {
        // Do not let a stale D-Bus read overwrite the optimistic slider value
        // while a SetBrightness call is active or another target is queued.
        if (!available || brightnessProcess.running || setBrightnessProcess.running || pendingTarget >= 0)
            return

        brightnessProcess.command = [
            "busctl", "--user", "get-property",
            "org.kde.ScreenBrightness",
            displayObjectPath,
            "org.kde.ScreenBrightness.Display",
            "Brightness"
        ]
        brightnessProcess.running = true
    }

    function parseBusctlInt(output) {
        const parts = output.trim().split(/\s+/)
        if (parts.length < 2)
            return NaN
        return parseInt(parts[parts.length - 1])
    }

    function setBrightness(value) {
        if (!available)
            return

        const normalized = Math.max(0, Math.min(1, value))
        const target = Math.round(normalized * maxValue)

        // Reflect the handle immediately while the D-Bus calls are serialized.
        currentValue = target
        pendingTarget = target
        applyPendingBrightness()
    }

    function applyPendingBrightness() {
        if (!available || pendingTarget < 0 || setBrightnessProcess.running)
            return

        const target = pendingTarget
        pendingTarget = -1

        // Verified on Plasma 6: SetBrightness has signature (int brightness,
        // uint flags), exposed by org.kde.ScreenBrightness.Display.
        setBrightnessProcess.command = [
            "busctl", "--user", "call",
            "org.kde.ScreenBrightness",
            displayObjectPath,
            "org.kde.ScreenBrightness.Display",
            "SetBrightness",
            "iu",
            `${target}`,
            "0"
        ]
        setBrightnessProcess.running = true
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
                const match = text.match(/\/org\/kde\/ScreenBrightness\/(display[^\s]+)/)
                root.displayObjectPath = match
                    ? `/org/kde/ScreenBrightness/${match[1]}`
                    : ""

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
                const value = root.parseBusctlInt(text)
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
                const value = root.parseBusctlInt(text)
                if (!isNaN(value)
                        && value >= 0
                        && !setBrightnessProcess.running
                        && root.pendingTarget < 0) {
                    root.currentValue = value
                }
            }
        }
    }

    Process {
        id: setBrightnessProcess
        running: false

        onExited: {
            if (root.pendingTarget >= 0)
                root.applyPendingBrightness()
            else
                root.readBrightness()
        }
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
                root.detectDisplay()
        }
    }
}
