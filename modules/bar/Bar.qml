import Quickshell
import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../components"
import "../../config" as QsConfig
import "../../services" as QsServices

Item {
    id: root

    property var screen
    property var barWindow
    property var controlCenter
    property var launcher
    property var sidebar
    property var dashboard

    property string activePopup: ""
    readonly property bool hasPopup: activePopup !== ""
    readonly property real popupAreaHeight: hasPopup ? popupHost.height : 0

    readonly property var config: QsConfig.Config
    readonly property var pywal: QsServices.Pywal

    function togglePopup(name: string) {
        activePopup = activePopup === name ? "" : name
    }

    function closePopup() {
        activePopup = ""
    }

    function popupAnchorTarget() {
        if (activePopup === "network" || activePopup === "bluetooth")
            return connectivityPill
        return powerPill
    }

    Item {
        id: barContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 11
        anchors.rightMargin: 11
        anchors.topMargin: 1
        height: config.bar.height - 2

        Row {
            id: leftGroup
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            AuroraSurface {
                id: leftModule
                height: 32
                width: leftContent.implicitWidth + 18
                radius: 20
                color: pywal.surfaceContainerHigh
                strokeColor: pywal.outlineVariant
                borderWidth: 0
                accentColor: pywal.primary
                elevation: 3

                RowLayout {
                    id: leftContent
                    anchors.centerIn: parent
                    spacing: 10

                    Loader {
                        id: workspacesLoader
                        Layout.alignment: Qt.AlignVCenter
                        asynchronous: true
                        source: "components/Workspaces.qml"

                        Binding {
                            target: workspacesLoader.item
                            property: "screen"
                            value: root.screen
                            when: workspacesLoader.status === Loader.Ready && root.screen !== undefined
                            restoreMode: Binding.RestoreBinding
                        }
                    }
                }
            }

            AuroraSurface {
                id: mediaModule
                height: 32
                width: mediaPlayerLoader.implicitWidth + 18
                radius: 20
                color: pywal.surfaceContainerHigh
                strokeColor: pywal.outlineVariant
                borderWidth: 0
                accentColor: pywal.secondary
                elevation: 3
                clip: true

                Loader {
                    id: mediaPlayerLoader
                    anchors.centerIn: parent
                    asynchronous: true
                    source: "components/MediaPlayer.qml"

                    Binding {
                        target: mediaPlayerLoader.item
                        property: "barWindow"
                        value: root.barWindow
                        when: mediaPlayerLoader.status === Loader.Ready && root.barWindow !== undefined
                        restoreMode: Binding.RestoreBinding
                    }

                    Binding {
                        target: mediaPlayerLoader.item
                        property: "mediaPopup"
                        value: null
                        when: mediaPlayerLoader.status === Loader.Ready
                        restoreMode: Binding.RestoreBinding
                    }
                }
            }

            AuroraSurface {
                id: weatherModule
                visible: weatherLoader.item?.hasWeather ?? false
                height: 32
                width: visible ? weatherLoader.implicitWidth + 18 : 0
                radius: 20
                color: pywal.surfaceContainerHigh
                strokeColor: pywal.outlineVariant
                borderWidth: 0
                accentColor: pywal.info
                elevation: 3

                Loader {
                    id: weatherLoader
                    anchors.centerIn: parent
                    asynchronous: true
                    source: "components/Weather.qml"
                }
            }

            AuroraSurface {
                id: activeWindowModule
                visible: activeWindowLoader.item?.hasWindow ?? false
                height: 32
                width: visible ? activeWindowLoader.implicitWidth + 18 : 0
                radius: 20
                color: pywal.surfaceContainerHigh
                strokeColor: pywal.outlineVariant
                borderWidth: 0
                accentColor: pywal.secondary
                elevation: 3

                Loader {
                    id: activeWindowLoader
                    anchors.centerIn: parent
                    asynchronous: true
                    source: "components/ActiveWindow.qml"
                }
            }

            AuroraSurface {
                id: attendanceModule
                height: 32
                width: attendanceLoader.implicitWidth + 18
                radius: 20
                color: pywal.surfaceContainerHigh
                strokeColor: pywal.outlineVariant
                borderWidth: 0
                accentColor: pywal.primary
                elevation: 3

                Loader {
                    id: attendanceLoader
                    anchors.centerIn: parent
                    asynchronous: true
                    source: "components/Attendance.qml"
                }
            }
        }

        Row {
            id: centerGroup
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            AuroraSurface {
                id: lyricModule
                visible: (lyricLoader.item?.hasLyric ?? false) && barContainer.width >= 1900
                height: 32
                width: visible ? lyricLoader.implicitWidth + 18 : 0
                radius: 20
                color: pywal.surfaceContainerHigh
                strokeColor: pywal.outlineVariant
                borderWidth: 0
                accentColor: pywal.primary
                elevation: 3

                Loader {
                    id: lyricLoader
                    anchors.centerIn: parent
                    asynchronous: true
                    source: "components/Lyrics.qml"
                }
            }

            AuroraSurface {
                id: centerModule
                height: 32
                width: clockLoader.implicitWidth + 22
                radius: 20
                color: pywal.surfaceContainerHighest
                strokeColor: pywal.outlineVariant
                borderWidth: 0
                accentColor: pywal.primary
                elevation: 4
                highlighted: true

                Loader {
                    id: clockLoader
                    anchors.centerIn: parent
                    asynchronous: true
                    source: "components/Clock.qml"

                    Binding {
                        target: clockLoader.item
                        property: "launcher"
                        value: root.launcher
                        when: clockLoader.status === Loader.Ready && root.launcher !== undefined
                        restoreMode: Binding.RestoreBinding
                    }

                    Binding {
                        target: clockLoader.item
                        property: "controlCenter"
                        value: root.controlCenter
                        when: clockLoader.status === Loader.Ready && root.controlCenter !== undefined
                        restoreMode: Binding.RestoreBinding
                    }

                    Binding {
                        target: clockLoader.item
                        property: "sidebar"
                        value: root.sidebar
                        when: clockLoader.status === Loader.Ready && root.sidebar !== undefined
                        restoreMode: Binding.RestoreBinding
                    }

                    Binding {
                        target: clockLoader.item
                        property: "dashboard"
                        value: root.dashboard
                        when: clockLoader.status === Loader.Ready && root.dashboard !== undefined
                        restoreMode: Binding.RestoreBinding
                    }
                }
            }
        }

        Row {
            id: rightPills
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            AuroraSurface {
                id: connectivityPill
                height: 32
                width: connectivityContent.implicitWidth + 18
                radius: 20
                color: pywal.surfaceContainerHigh
                strokeColor: pywal.outlineVariant
                borderWidth: 0
                accentColor: pywal.info
                elevation: 3

                Row {
                    id: connectivityContent
                    anchors.centerIn: parent
                    spacing: 4

                    Loader {
                        id: networkLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/Network.qml"

                        Binding {
                            target: networkLoader.item
                            property: "barWindow"
                            value: root.barWindow
                            when: networkLoader.status === Loader.Ready && root.barWindow !== undefined
                            restoreMode: Binding.RestoreBinding
                        }

                        Binding {
                            target: networkLoader.item
                            property: "bar"
                            value: root
                            when: networkLoader.status === Loader.Ready
                            restoreMode: Binding.RestoreBinding
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 12
                        radius: 0.5
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.12)
                    }

                    Loader {
                        id: bluetoothLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/Bluetooth.qml"

                        Binding {
                            target: bluetoothLoader.item
                            property: "barWindow"
                            value: root.barWindow
                            when: bluetoothLoader.status === Loader.Ready && root.barWindow !== undefined
                            restoreMode: Binding.RestoreBinding
                        }

                        Binding {
                            target: bluetoothLoader.item
                            property: "bar"
                            value: root
                            when: bluetoothLoader.status === Loader.Ready
                            restoreMode: Binding.RestoreBinding
                        }
                    }
                }
            }

            AuroraSurface {
                id: audioPill
                height: 32
                width: audioContent.implicitWidth + 18
                radius: 20
                color: pywal.surfaceContainerHigh
                strokeColor: pywal.outlineVariant
                borderWidth: 0
                accentColor: pywal.secondary
                elevation: 3

                Row {
                    id: audioContent
                    anchors.centerIn: parent
                    spacing: 6

                    Loader {
                        id: brightnessLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/Brightness.qml"

                        Binding {
                            target: brightnessLoader.item
                            property: "barWindow"
                            value: root.barWindow
                            when: brightnessLoader.status === Loader.Ready && root.barWindow !== undefined
                            restoreMode: Binding.RestoreBinding
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 12
                        radius: 0.5
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.12)
                    }

                    Loader {
                        id: volumeLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/Volume.qml"

                        Binding {
                            target: volumeLoader.item
                            property: "barWindow"
                            value: root.barWindow
                            when: volumeLoader.status === Loader.Ready && root.barWindow !== undefined
                            restoreMode: Binding.RestoreBinding
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: microphoneLoader.item?.ready ? 1 : 0
                        height: 12
                        radius: 0.5
                        visible: microphoneLoader.item?.ready ?? false
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.12)
                    }

                    Loader {
                        id: microphoneLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/Microphone.qml"
                    }
                }
            }

            AuroraSurface {
                id: powerPill
                height: 32
                width: powerContent.implicitWidth + 18
                radius: 20
                color: pywal.surfaceContainerHigh
                strokeColor: pywal.outlineVariant
                borderWidth: 0
                accentColor: pywal.primary
                elevation: 3

                Row {
                    id: powerContent
                    anchors.centerIn: parent
                    spacing: 6

                    Loader {
                        id: statusIndicatorsLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/StatusIndicators.qml"
                        visible: item?.hasActiveIndicators ?? false
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 12
                        radius: 0.5
                        visible: statusIndicatorsLoader.item?.hasActiveIndicators ?? false
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.12)
                    }

                    Loader {
                        id: batteryLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        active: config.bar.showBattery
                        source: "components/Battery.qml"
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 12
                        radius: 0.5
                        visible: config.bar.showBattery
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.12)
                    }

                    Loader {
                        id: notifCenterLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/NotificationCenterToggle.qml"

                        Binding {
                            target: notifCenterLoader.item
                            property: "sidebar"
                            value: root.sidebar
                            when: notifCenterLoader.status === Loader.Ready && root.sidebar !== undefined
                            restoreMode: Binding.RestoreBinding
                        }

                        Binding {
                            target: notifCenterLoader.item
                            property: "controlCenter"
                            value: root.controlCenter
                            when: notifCenterLoader.status === Loader.Ready && root.controlCenter !== undefined
                            restoreMode: Binding.RestoreBinding
                        }

                        Binding {
                            target: notifCenterLoader.item
                            property: "launcher"
                            value: root.launcher
                            when: notifCenterLoader.status === Loader.Ready && root.launcher !== undefined
                            restoreMode: Binding.RestoreBinding
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 12
                        radius: 0.5
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.12)
                    }

                    Loader {
                        id: controlCenterLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/ControlCenterToggle.qml"

                        Binding {
                            target: controlCenterLoader.item
                            property: "controlCenter"
                            value: root.controlCenter
                            when: controlCenterLoader.status === Loader.Ready && root.controlCenter !== undefined
                            restoreMode: Binding.RestoreBinding
                        }
                    }

                    Loader {
                        id: systemTrayLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/SystemTray.qml"
                        visible: item?.hasItems ?? false

                        Binding {
                            target: systemTrayLoader.item
                            property: "barWindow"
                            value: root.barWindow
                            when: systemTrayLoader.status === Loader.Ready && root.barWindow !== undefined
                            restoreMode: Binding.RestoreBinding
                        }
                    }
                }
            }
        }
    }

    Item {
        id: popupHost
        anchors.top: barContainer.bottom
        anchors.topMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        height: hasPopup ? popupContentWrapper.height + 12 : 0
        clip: true

        property bool mouseHasEntered: false
        property bool mouseInside: popupHoverHandler.hovered

        onVisibleChanged: {
            if (!visible) {
                mouseHasEntered = false
                popupCloseTimer.stop()
            }
        }

        Connections {
            target: root
            function onHasPopupChanged() {
                if (root.hasPopup) {
                    popupHost.mouseHasEntered = false
                    popupCloseTimer.stop()
                } else {
                    popupCloseTimer.stop()
                }
            }
        }

        Timer {
            id: popupCloseTimer
            interval: 400
            onTriggered: {
                if (!popupHost.mouseInside && popupHost.mouseHasEntered && root.hasPopup)
                    root.closePopup()
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            visible: hasPopup
            onClicked: root.closePopup()
        }

        Item {
            id: popupContentWrapper
            y: 4
            x: {
                const w = width
                const hostPadding = 12
                const anchor = root.popupAnchorTarget()

                if (anchor) {
                    const centerInHost = anchor.mapToItem(popupHost, anchor.width / 2, anchor.height).x
                    return Math.max(hostPadding, Math.min(popupHost.width - w - hostPadding, centerInHost - (w / 2)))
                }

                return Math.max(hostPadding, popupHost.width - w - hostPadding)
            }
            width: activePopup === "network" ? 340 : 320
            height: {
                if (btPanelLoader.active && btPanelLoader.item)
                    return btPanelLoader.item.implicitHeight
                if (netPanelLoader.active && netPanelLoader.item)
                    return netPanelLoader.item.implicitHeight
                return 0
            }

            scale: hasPopup ? 1.0 : 0.92
            opacity: hasPopup ? 1 : 0
            transformOrigin: Item.TopRight

            Behavior on scale {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.1
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            HoverHandler {
                id: popupHoverHandler
                onHoveredChanged: {
                    if (hovered) {
                        popupHost.mouseHasEntered = true
                        popupCloseTimer.stop()
                    } else if (popupHost.mouseHasEntered && root.hasPopup) {
                        popupCloseTimer.restart()
                    }
                }
            }

            Loader {
                id: btPanelLoader
                anchors.fill: parent
                active: root.activePopup === "bluetooth"
                source: "components/BluetoothPanel.qml"

                onLoaded: {
                    item.shouldShow = true
                    item.forceActiveFocus()
                }

                Connections {
                    target: btPanelLoader.item
                    function onCloseRequested() { root.closePopup() }
                }
            }

            Loader {
                id: netPanelLoader
                anchors.fill: parent
                active: root.activePopup === "network"
                source: "components/NetworkPanel.qml"

                onLoaded: {
                    item.shouldShow = true
                    item.forceActiveFocus()
                }

                Connections {
                    target: netPanelLoader.item
                    function onCloseRequested() { root.closePopup() }
                }
            }
        }
    }
}
