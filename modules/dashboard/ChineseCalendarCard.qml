import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../config" as QsConfig
import "../../services" as QsServices

Rectangle {
    id: root

    readonly property var pywal: QsServices.Pywal
    readonly property var time: QsServices.Time
    readonly property var chineseCalendar: QsServices.ChineseCalendar
    readonly property int todayYear: time.date.getFullYear()
    readonly property int todayMonth: time.date.getMonth()
    readonly property int todayDay: time.date.getDate()

    property int viewYear: todayYear
    property int viewMonth: todayMonth

    readonly property var dayLabels: [
        { text: "一", weekend: false },
        { text: "二", weekend: false },
        { text: "三", weekend: false },
        { text: "四", weekend: false },
        { text: "五", weekend: false },
        { text: "六", weekend: true },
        { text: "日", weekend: true }
    ]

    readonly property int calendarOffset: {
        const first = new Date(viewYear, viewMonth, 1).getDay()
        return (first + 6) % 7
    }

    readonly property var calendarCells: {
        const cells = []
        for (let index = 0; index < 42; index++) {
            const date = new Date(viewYear, viewMonth, index - calendarOffset + 1, 12, 0, 0)
            const year = date.getFullYear()
            const month = date.getMonth()
            const day = date.getDate()
            const info = chineseCalendar.dateInfo(year, month + 1, day)
            const current = year === viewYear && month === viewMonth
            const today = year === todayYear && month === todayMonth && day === todayDay
            const weekday = date.getDay()

            cells.push({
                year: year,
                month: month,
                day: day,
                current: current,
                today: today,
                weekend: weekday === 0 || weekday === 6,
                info: info
            })
        }
        return cells
    }

    function changeMonth(delta) {
        const target = new Date(viewYear, viewMonth + delta, 1, 12, 0, 0)
        viewYear = target.getFullYear()
        viewMonth = target.getMonth()
    }

    function goToday() {
        viewYear = todayYear
        viewMonth = todayMonth
    }

    function cellBackground(cell) {
        if (cell.today)
            return Qt.rgba(pywal.primary.r, pywal.primary.g, pywal.primary.b, 0.18)
        if (!cell.current)
            return Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.025)
        if (cell.info.holiday?.type === "rest")
            return Qt.rgba(pywal.error.r, pywal.error.g, pywal.error.b, 0.07)
        if (cell.info.holiday?.type === "work")
            return Qt.rgba(pywal.warning.r, pywal.warning.g, pywal.warning.b, 0.06)
        return "transparent"
    }

    function dayColor(cell) {
        if (!cell.current)
            return pywal.onSurfaceMuted
        if (cell.info.holiday?.type === "work")
            return pywal.foreground
        if (cell.info.holiday?.type === "rest" || cell.weekend)
            return pywal.error
        return pywal.foreground
    }

    function detailColor(cell) {
        if (!cell.current)
            return pywal.onSurfaceMuted
        if (cell.info.holiday?.type === "work")
            return pywal.warning
        if (cell.info.special)
            return cell.info.holiday?.type === "rest" ? pywal.error : pywal.primary
        return pywal.onSurfaceMuted
    }

    radius: 22
    color: pywal.surfaceContainer
    border.width: 1
    border.color: pywal.outlineVariant
    implicitHeight: 270
    clip: true

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            if (wheel.angleDelta.y !== 0) {
                root.changeMonth(wheel.angleDelta.y > 0 ? -1 : 1)
                wheel.accepted = true
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            spacing: 6

            Text {
                text: "日历"
                font.family: QsConfig.Config.appearance.fontFamily
                font.pixelSize: 15
                font.weight: Font.Bold
                color: root.pywal.foreground
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 24
                radius: 12
                color: todayMouse.containsMouse
                    ? Qt.rgba(root.pywal.primary.r, root.pywal.primary.g, root.pywal.primary.b, 0.16)
                    : Qt.rgba(root.pywal.foreground.r, root.pywal.foreground.g, root.pywal.foreground.b, 0.05)

                Text {
                    anchors.centerIn: parent
                    text: "今天"
                    font.family: QsConfig.Config.appearance.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    color: root.pywal.foreground
                }

                MouseArea {
                    id: todayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.goToday()
                }
            }

            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 12
                color: prevMouse.containsMouse
                    ? Qt.rgba(root.pywal.foreground.r, root.pywal.foreground.g, root.pywal.foreground.b, 0.10)
                    : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    font.family: QsConfig.Config.appearance.fontFamily
                    font.pixelSize: 19
                    color: root.pywal.foreground
                }

                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.changeMonth(-1)
                }
            }

            Text {
                Layout.preferredWidth: 86
                horizontalAlignment: Text.AlignHCenter
                text: `${root.viewYear}年${root.viewMonth + 1}月`
                font.family: QsConfig.Config.appearance.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: root.pywal.foreground
            }

            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 12
                color: nextMouse.containsMouse
                    ? Qt.rgba(root.pywal.foreground.r, root.pywal.foreground.g, root.pywal.foreground.b, 0.10)
                    : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "›"
                    font.family: QsConfig.Config.appearance.fontFamily
                    font.pixelSize: 19
                    color: root.pywal.foreground
                }

                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.changeMonth(1)
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            rowSpacing: 2
            columnSpacing: 4

            Repeater {
                model: root.dayLabels

                Text {
                    id: dayHeader
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 15
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: dayHeader.modelData.text
                    font.family: QsConfig.Config.appearance.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    color: dayHeader.modelData.weekend ? root.pywal.error : root.pywal.onSurfaceMuted
                    opacity: dayHeader.modelData.weekend ? 0.82 : 1.0
                }
            }

            Repeater {
                model: root.calendarCells

                Rectangle {
                    id: dayCell
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 30
                    radius: 9
                    color: root.cellBackground(dayCell.modelData)
                    border.width: dayCell.modelData.today ? 1 : 0
                    border.color: Qt.rgba(root.pywal.primary.r, root.pywal.primary.g, root.pywal.primary.b, 0.42)
                    opacity: dayCell.modelData.current ? 1.0 : 0.46

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 4
                        spacing: -2

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: `${dayCell.modelData.day}`
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 10
                            font.weight: dayCell.modelData.today ? Font.Bold : Font.DemiBold
                            color: root.dayColor(dayCell.modelData)
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: dayCell.modelData.info.label || ""
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 7.5
                            font.weight: dayCell.modelData.info.special ? Font.DemiBold : Font.Normal
                            color: root.detailColor(dayCell.modelData)
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                        }
                    }

                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: 1
                        anchors.rightMargin: 1
                        width: 11
                        height: 11
                        radius: 4
                        visible: dayCell.modelData.current && dayCell.modelData.info.holiday !== null
                        color: dayCell.modelData.info.holiday?.type === "work"
                            ? Qt.rgba(root.pywal.warning.r, root.pywal.warning.g, root.pywal.warning.b, 0.18)
                            : Qt.rgba(root.pywal.error.r, root.pywal.error.g, root.pywal.error.b, 0.18)

                        Text {
                            anchors.centerIn: parent
                            text: dayCell.modelData.info.holiday?.badge ?? ""
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 7
                            font.weight: Font.Bold
                            color: dayCell.modelData.info.holiday?.type === "work"
                                ? root.pywal.warning
                                : root.pywal.error
                        }
                    }
                }
            }
        }
    }
}
