import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10 as QQC
import QtQuick.Effects
import "../../../services" as QsServices

FocusScope {
    id: popupPanel

    property bool shouldShow: false
    signal closeRequested()

    readonly property var dida: QsServices.Dida
    readonly property var pywal: QsServices.Pywal

    readonly property color cSurface: pywal.background
    readonly property color cSurfaceContainer: Qt.lighter(pywal.background, 1.15)
    readonly property color cPrimary: pywal.primary
    readonly property color cText: pywal.foreground
    readonly property color cSubText: Qt.rgba(cText.r, cText.g, cText.b, 0.62)
    readonly property color cBorder: Qt.rgba(cText.r, cText.g, cText.b, 0.08)
    readonly property color cHover: Qt.rgba(cText.r, cText.g, cText.b, 0.06)

    implicitWidth: 440
    implicitHeight: 520
    focus: true

    Keys.onEscapePressed: closeRequested()

    function priorityColor(priority) {
        if (priority >= 5)
            return pywal.error
        if (priority >= 3)
            return pywal.warning
        if (priority >= 1)
            return pywal.info
        return cSubText
    }

    function dueLabel(task) {
        const value = task?.dueDate || task?.startDate || ""
        if (!value)
            return ""

        const normalized = String(value).replace(/([+-][0-9][0-9])([0-9][0-9])$/, "$1:$2")
        const date = new Date(normalized)

        if (isNaN(date.getTime()))
            return String(value).slice(0, 16).replace("T", " ")

        if (task?.isAllDay)
            return Qt.formatDate(date, "MM-dd")

        return Qt.formatDateTime(date, "MM-dd HH:mm")
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: cSurface
        border.color: cBorder
        border.width: 1

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.35)
            shadowBlur: 1.0
            shadowVerticalOffset: 6
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    width: 36
                    height: 36
                    radius: 12
                    color: Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.15)

                    Text {
                        anchors.centerIn: parent
                        text: "≡"
                        font.family: "Inter"
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        color: cPrimary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "滴答清单"
                        font.family: "Inter"
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        color: cText
                    }

                    Text {
                        text: dida.loading
                            ? "正在同步…"
                            : (dida.openCount + " 个未完成任务")
                        font.family: "Inter"
                        font.pixelSize: 10
                        color: cSubText
                    }
                }

                Rectangle {
                    width: 32
                    height: 32
                    radius: 10
                    color: refreshArea.containsMouse ? cHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰑐"
                        font.family: "Material Design Icons"
                        font.pixelSize: 16
                        color: dida.loading ? cPrimary : cText

                        RotationAnimation on rotation {
                            running: dida.loading
                            from: 0
                            to: 360
                            duration: 900
                            loops: Animation.Infinite
                        }
                    }

                    MouseArea {
                        id: refreshArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !dida.loading
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dida.refresh()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 54
                radius: 12
                color: Qt.rgba(pywal.error.r, pywal.error.g, pywal.error.b, 0.10)
                border.width: 1
                border.color: Qt.rgba(pywal.error.r, pywal.error.g, pywal.error.b, 0.24)
                visible: dida.errorText.length > 0

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 9
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: dida.errorText
                        font.family: "Inter"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: pywal.error
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: !dida.configured
                        text: dida.configPath
                        font.family: "monospace"
                        font.pixelSize: 9
                        color: cSubText
                        elide: Text.ElideMiddle
                    }
                }
            }

            ListView {
                id: projectList
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                orientation: ListView.Horizontal
                spacing: 6
                clip: true
                model: dida.projects
                visible: dida.projects.length > 0

                delegate: Rectangle {
                    id: projectChip
                    required property var modelData

                    width: Math.min(170, projectLabel.implicitWidth + countLabel.implicitWidth + 28)
                    height: 32
                    radius: 16
                    color: dida.selectedProjectId === modelData.id
                        ? Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.18)
                        : (projectMouse.containsMouse ? cHover : cSurfaceContainer)
                    border.width: 1
                    border.color: dida.selectedProjectId === modelData.id
                        ? Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.45)
                        : cBorder

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            id: projectLabel
                            width: Math.min(116, implicitWidth)
                            text: projectChip.modelData.name
                            font.family: "Inter"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: dida.selectedProjectId === projectChip.modelData.id ? cPrimary : cText
                            elide: Text.ElideRight
                        }

                        Text {
                            id: countLabel
                            text: String(dida.projectOpenCount(projectChip.modelData.id))
                            font.family: "Inter"
                            font.pixelSize: 9
                            color: cSubText
                        }
                    }

                    MouseArea {
                        id: projectMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dida.selectProject(projectChip.modelData.id)
                    }
                }

                QQC.ScrollBar.horizontal: QQC.ScrollBar {
                    policy: QQC.ScrollBar.AsNeeded
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: cSurfaceContainer
                clip: true

                ListView {
                    id: taskList
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 2
                    clip: true
                    model: dida.currentTasks

                    delegate: Rectangle {
                        id: taskRow
                        required property var modelData

                        width: taskList.width
                        height: Math.max(52, taskText.implicitHeight + 18)
                        radius: 10
                        color: rowHover.hovered ? cHover : "transparent"
                        opacity: dida.pendingTaskId === modelData.id ? 0.48 : 1

                        Behavior on opacity { NumberAnimation { duration: 120 } }
                        Behavior on color { ColorAnimation { duration: 80 } }

                        HoverHandler {
                            id: rowHover
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                                radius: 11
                                color: checkMouse.containsMouse
                                    ? Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.14)
                                    : "transparent"
                                border.width: 1.5
                                border.color: priorityColor(taskRow.modelData.priority)

                                Text {
                                    anchors.centerIn: parent
                                    text: dida.pendingTaskId === taskRow.modelData.id ? "󰔛" : ""
                                    font.family: "Material Design Icons"
                                    font.pixelSize: 12
                                    color: cPrimary
                                }

                                MouseArea {
                                    id: checkMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: !dida.completing
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: dida.completeTask(taskRow.modelData)
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                Text {
                                    id: taskText
                                    Layout.fillWidth: true
                                    text: taskRow.modelData.title
                                    font.family: "Inter"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: cText
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    visible: dueLabel(taskRow.modelData).length > 0 || taskRow.modelData.priority > 0

                                    Text {
                                        visible: dueLabel(taskRow.modelData).length > 0
                                        text: dueLabel(taskRow.modelData)
                                        font.family: "Inter"
                                        font.pixelSize: 9
                                        color: cSubText
                                    }

                                    Text {
                                        visible: taskRow.modelData.priority > 0
                                        text: "●"
                                        font.pixelSize: 8
                                        color: priorityColor(taskRow.modelData.priority)
                                    }
                                }
                            }
                        }
                    }

                    QQC.ScrollBar.vertical: QQC.ScrollBar {
                        policy: QQC.ScrollBar.AsNeeded
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        visible: !dida.loading
                            && dida.errorText.length === 0
                            && dida.currentTasks.length === 0

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰄬"
                            font.family: "Material Design Icons"
                            font.pixelSize: 38
                            color: Qt.rgba(cText.r, cText.g, cText.b, 0.22)
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: dida.projects.length === 0 ? "没有可显示的清单" : "这个清单已经清空"
                            font.family: "Inter"
                            font.pixelSize: 11
                            color: cSubText
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: dida.lastUpdated > 0
                    ? ("上次同步 " + Qt.formatTime(new Date(dida.lastUpdated), "HH:mm:ss"))
                    : "点击右上角刷新以同步"
                font.family: "Inter"
                font.pixelSize: 9
                color: cSubText
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
