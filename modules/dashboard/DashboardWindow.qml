import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../components"
import "../controlcenter/components"

PopupWindow {
    id: root

    property var anchorWindow
    property bool shouldShow: false

    readonly property var config: QsConfig.Config
    readonly property var pywal: QsServices.Pywal
    readonly property var time: QsServices.Time
    readonly property var systemUsage: QsServices.SystemUsage
    readonly property var players: QsServices.Players
    readonly property var network: QsServices.Network
    readonly property var audio: QsServices.Audio
    readonly property var powerProfiles: QsServices.PowerProfiles
    readonly property var notifs: QsServices.Notifs
    readonly property var bluetooth: QsServices.Bluetooth

    readonly property color cSurface: pywal.surfaceContainerHighest
    readonly property color cSurfaceContainer: pywal.surfaceContainerHigh
    readonly property color cSurfaceContainerHigh: pywal.surfaceContainerHigh
    readonly property color cPrimary: pywal.primary
    readonly property color cText: pywal.foreground
    readonly property color cSubText: pywal.onSurfaceMuted
    readonly property color cBorder: pywal.outlineVariant
    readonly property bool hasMedia: players?.active !== null

    readonly property var currentDate: time.date
    readonly property int currentMonth: currentDate.getMonth()
    readonly property int currentYear: currentDate.getFullYear()
    readonly property int currentDay: currentDate.getDate()
    readonly property var dayLabels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    readonly property int calendarOffset: {
        const first = new Date(currentYear, currentMonth, 1).getDay()
        return (first + 6) % 7
    }
    readonly property int calendarDays: new Date(currentYear, currentMonth + 1, 0).getDate()
    readonly property var calendarCells: {
        const cells = []
        const prevMonthDays = new Date(currentYear, currentMonth, 0).getDate()
        for (let index = 0; index < 42; index++) {
            const dayNumber = index - calendarOffset + 1
            if (dayNumber < 1) {
                cells.push({ day: prevMonthDays + dayNumber, current: false, today: false })
            } else if (dayNumber > calendarDays) {
                cells.push({ day: dayNumber - calendarDays, current: false, today: false })
            } else {
                cells.push({ day: dayNumber, current: true, today: dayNumber === currentDay })
            }
        }
        return cells
    }

    function closeDashboard() {
        shouldShow = false
    }

    function launchAndClose(command) {
        closeDashboard()
        Qt.callLater(() => Quickshell.execDetached(command))
    }

    onShouldShowChanged: {
        if (shouldShow)
            Qt.callLater(() => panel.forceActiveFocus())
    }

    anchor.window: anchorWindow
    anchor.rect.x: anchorWindow
        ? Math.max(0, Math.round((anchorWindow.width - config.dashboard.width) / 2))
        : 0
    anchor.rect.y: (config.bar.height ?? 34) + config.dashboard.margin
    anchor.rect.width: 1
    anchor.rect.height: 1

    grabFocus: true
    implicitWidth: config.dashboard.width
    implicitHeight: Math.min(
        config.dashboard.height,
        (anchorWindow?.screen?.height ?? Quickshell.screens[0].height)
            - (config.bar.height ?? 34)
            - config.dashboard.margin
            - 24
    )
    visible: config.dashboard.enabled && shouldShow && anchorWindow !== null
    color: "transparent"

    onVisibleChanged: {
        if (!visible)
            shouldShow = false
    }

    FocusScope {
        id: panel
        anchors.fill: parent
        focus: root.shouldShow

        Keys.onEscapePressed: root.closeDashboard()

        AuroraSurface {
            anchors.fill: parent
            radius: 28
            color: root.cSurface
            strokeColor: root.cBorder
            accentColor: root.cPrimary
            elevation: 4
            highlighted: root.shouldShow

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 180
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: time.format("dddd")
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 28
                            font.weight: Font.Bold
                            color: root.cText
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: time.format("MMMM d, yyyy  •  HH:mm:ss")
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 12
                            color: root.cSubText
                            elide: Text.ElideRight
                        }
                    }

                    SummaryChip {
                        icon: root.notifs.unreadCount > 0 ? "󰂚" : "󰂜"
                        label: root.notifs.unreadCount > 0 ? `${root.notifs.unreadCount} unread` : "Inbox clear"
                        accent: root.cPrimary
                        maxWidth: 120
                    }

                    SummaryChip {
                        icon: root.network.connected ? "󰖩" : "󰖪"
                        label: root.network.connected ? (root.network.ssid || "Wi‑Fi") : "Offline"
                        accent: root.network.connected ? pywal.info : root.cSubText
                        maxWidth: 150
                    }

                    SummaryChip {
                        icon: root.bluetooth.connected ? "󰂱" : "󰂲"
                        label: root.bluetooth.connected ? (root.bluetooth.deviceName || "Bluetooth") : "Bluetooth"
                        accent: root.bluetooth.connected ? pywal.secondary : root.cSubText
                        maxWidth: 150
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 16

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        spacing: 16

                        SurfaceCard {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 254

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 12

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: "Calendar"
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: 15
                                        font.weight: Font.Bold
                                        color: root.cText
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        text: time.format("MMMM yyyy")
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: 12
                                        color: root.cSubText
                                    }
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    columns: 7
                                    rowSpacing: 6
                                    columnSpacing: 6

                                    Repeater {
                                        model: root.dayLabels

                                        Text {
                                            id: dayHeader
                                            required property var modelData
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignHCenter
                                            text: dayHeader.modelData
                                            font.family: QsConfig.Config.appearance.fontFamily
                                            font.pixelSize: 11
                                            font.weight: Font.Medium
                                            color: root.cSubText
                                        }
                                    }

                                    Repeater {
                                        model: root.calendarCells

                                        Rectangle {
                                            id: dayCell
                                            required property var modelData
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.preferredHeight: 24
                                            radius: 12
                                            color: dayCell.modelData.today
                                                ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.18)
                                                : dayCell.modelData.current
                                                    ? "transparent"
                                                    : Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.03)
                                            border.width: dayCell.modelData.today ? 1 : 0
                                            border.color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.36)

                                            Text {
                                                anchors.centerIn: parent
                                                text: `${dayCell.modelData.day}`
                                                font.family: QsConfig.Config.appearance.fontFamily
                                                font.pixelSize: 11
                                                font.weight: dayCell.modelData.today ? Font.Bold : Font.Medium
                                                color: dayCell.modelData.current ? root.cText : root.cSubText
                                                opacity: dayCell.modelData.current ? 1.0 : 0.45
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        SurfaceCard {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 12

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: "Daily Controls"
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: 15
                                        font.weight: Font.Bold
                                        color: root.cText
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        text: root.powerProfiles.isAvailable
                                            ? root.powerProfiles.getProfileLabel(root.powerProfiles.activeProfile)
                                            : "Power"
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: 11
                                        color: root.cSubText
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    QuickAction {
                                        Layout.fillWidth: true
                                        icon: "󰄀"
                                        label: "Region"
                                        subLabel: "Screenshot"
                                        accent: root.cPrimary
                                        onClicked: root.launchAndClose(["spectacle", "-r", "-b", "-c"])
                                    }

                                    QuickAction {
                                        Layout.fillWidth: true
                                        icon: "󰻃"
                                        label: "Record"
                                        subLabel: "Region"
                                        accent: pywal.error
                                        onClicked: root.launchAndClose(["spectacle", "--record", "r"])
                                    }

                                    QuickAction {
                                        Layout.fillWidth: true
                                        icon: "󰆍"
                                        label: "Terminal"
                                        subLabel: "Kitty"
                                        accent: pywal.secondary
                                        onClicked: root.launchAndClose(["kitty"])
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Repeater {
                                        model: root.powerProfiles.availableProfiles

                                        Rectangle {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 36
                                            radius: 18
                                            color: root.powerProfiles.activeProfile === modelData
                                                ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.16)
                                                : root.cSurfaceContainerHigh
                                            border.width: 1
                                            border.color: root.powerProfiles.activeProfile === modelData
                                                ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.36)
                                                : Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.05)

                                            Text {
                                                anchors.centerIn: parent
                                                text: root.powerProfiles.getProfileLabel(modelData)
                                                font.family: QsConfig.Config.appearance.fontFamily
                                                font.pixelSize: 11
                                                font.weight: Font.Medium
                                                color: root.powerProfiles.activeProfile === modelData ? root.cPrimary : root.cText
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.powerProfiles.setProfile(modelData)
                                            }
                                        }
                                    }
                                }

                                SurfaceMetricRow {
                                    icon: root.audio.muted ? "󰖁" : "󰕾"
                                    title: "Volume"
                                    value: `${Math.round(root.audio.percentage ?? 0)}%`
                                    detail: root.audio.muted ? "Muted" : "Default output"
                                    accent: pywal.secondary
                                }

                                SurfaceMetricRow {
                                    icon: root.network.connected ? "󰖩" : "󰖪"
                                    title: "Network"
                                    value: root.network.connected ? (root.network.ssid || "Connected") : "Disconnected"
                                    detail: root.network.connected ? `Signal ${root.network.signalStrength}%` : "Wi‑Fi idle"
                                    accent: pywal.info
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        spacing: 16

                        SystemStats {
                            Layout.fillWidth: true
                            systemUsage: root.systemUsage
                            pywal: root.pywal
                        }

                        SurfaceCard {
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.hasMedia ? 124 : 88

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 0

                                Text {
                                    visible: !root.hasMedia
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.topMargin: 22
                                    text: "No media playing"
                                    font.family: QsConfig.Config.appearance.fontFamily
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    color: root.cSubText
                                }

                                MediaCard {
                                    visible: root.hasMedia
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    mpris: root.players
                                    pywal: root.pywal
                                }
                            }
                        }

                        SurfaceCard {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 170

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: "Today at a Glance"
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: 15
                                        font.weight: Font.Bold
                                        color: root.cText
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        text: root.time.format("ddd")
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: 11
                                        color: root.cSubText
                                    }
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    columns: 2
                                    columnSpacing: 8
                                    rowSpacing: 8

                                    InsightCard {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        title: "CPU / RAM"
                                        body: `${Math.round((root.systemUsage.cpuPerc ?? 0) * 100)}%  /  ${Math.round((root.systemUsage.memPerc ?? 0) * 100)}%`
                                        accent: pywal.error
                                    }

                                    InsightCard {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        title: "Network"
                                        body: `↓ ${Math.round((root.systemUsage.downloadSpeed ?? 0) / 1024)} · ↑ ${Math.round((root.systemUsage.uploadSpeed ?? 0) / 1024)} KB/s`
                                        accent: pywal.info
                                    }

                                    InsightCard {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        title: "Inbox"
                                        body: root.notifs.unreadCount > 0
                                            ? `${root.notifs.unreadCount} unread`
                                            : "All clear"
                                        accent: pywal.primary
                                    }

                                    InsightCard {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        title: "Power"
                                        body: root.powerProfiles.isAvailable
                                            ? root.powerProfiles.getProfileLabel(root.powerProfiles.activeProfile)
                                            : "Unavailable"
                                        accent: pywal.secondary
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component SurfaceCard: Rectangle {
        radius: 22
        color: root.cSurfaceContainer
        border.width: 1
        border.color: root.cBorder
    }

    component SummaryChip: Rectangle {
        id: chipRoot

        required property string icon
        required property string label
        required property color accent
        property int maxWidth: 140

        implicitWidth: Math.min(chipRow.implicitWidth + 18, maxWidth)
        implicitHeight: 34
        radius: 17
        color: Qt.rgba(accent.r, accent.g, accent.b, 0.14)
        border.width: 1
        border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.18)
        clip: true

        RowLayout {
            id: chipRow
            anchors.fill: parent
            anchors.leftMargin: 9
            anchors.rightMargin: 9
            spacing: 6

            Text {
                text: chipRoot.icon
                font.family: "Material Design Icons"
                font.pixelSize: 15
                color: chipRoot.accent
            }

            Text {
                Layout.fillWidth: true
                text: chipRoot.label
                font.family: QsConfig.Config.appearance.fontFamily
                font.pixelSize: 11
                font.weight: Font.Medium
                color: root.cText
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
            }
        }
    }

    component QuickAction: Rectangle {
        id: actionRoot

        required property string icon
        required property string label
        required property string subLabel
        required property color accent
        signal clicked()

        radius: 18
        color: mouse.containsMouse ? Qt.lighter(root.cSurfaceContainerHigh, 1.03) : root.cSurfaceContainerHigh
        border.width: 1
        border.color: Qt.rgba(actionRoot.accent.r, actionRoot.accent.g, actionRoot.accent.b, 0.22)
        implicitHeight: 84
        scale: mouse.pressed ? 0.985 : mouse.containsMouse ? 1.01 : 1.0

        Behavior on scale {
            NumberAnimation { duration: 180; easing.bezierCurve: [0.22, 1.0, 0.36, 1.0] }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            Text {
                text: actionRoot.icon
                font.family: "Material Design Icons"
                font.pixelSize: 20
                color: actionRoot.accent
            }

            Text {
                Layout.fillWidth: true
                text: actionRoot.label
                font.family: QsConfig.Config.appearance.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: root.cText
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: actionRoot.subLabel
                font.family: QsConfig.Config.appearance.fontFamily
                font.pixelSize: 10
                color: root.cSubText
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: actionRoot.clicked()
        }
    }

    component SurfaceMetricRow: Rectangle {
        id: metricRoot

        required property string icon
        required property string title
        required property string value
        required property string detail
        required property color accent

        radius: 16
        color: root.cSurfaceContainerHigh
        border.width: 1
        border.color: Qt.rgba(metricRoot.accent.r, metricRoot.accent.g, metricRoot.accent.b, 0.14)
        implicitHeight: 52
        clip: true

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Text {
                text: metricRoot.icon
                font.family: "Material Design Icons"
                font.pixelSize: 18
                color: metricRoot.accent
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: metricRoot.title
                    font.family: QsConfig.Config.appearance.fontFamily
                    font.pixelSize: 11
                    color: root.cSubText
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: metricRoot.detail
                    font.family: QsConfig.Config.appearance.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: root.cText
                    elide: Text.ElideRight
                }
            }

            Text {
                Layout.maximumWidth: 140
                text: metricRoot.value
                font.family: QsConfig.Config.appearance.fontFamily
                font.pixelSize: 12
                font.weight: Font.Bold
                color: root.cText
                elide: Text.ElideRight
            }
        }
    }

    component InsightCard: Rectangle {
        id: insightRoot

        required property string title
        required property string body
        required property color accent

        radius: 16
        color: root.cSurfaceContainerHigh
        border.width: 1
        border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.18)
        implicitHeight: 62
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 3

            Text {
                Layout.fillWidth: true
                text: insightRoot.title
                font.family: QsConfig.Config.appearance.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: insightRoot.accent
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
            }

            Text {
                Layout.fillWidth: true
                text: insightRoot.body
                font.family: QsConfig.Config.appearance.fontFamily
                font.pixelSize: 11
                color: root.cText
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
            }
        }
    }
}
