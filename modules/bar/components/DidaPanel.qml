import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10 as QQC
import QtQuick.Effects
import "../../../services" as QsServices

FocusScope {
    id: popupPanel

    property bool shouldShow: false
    property bool projectMenuOpen: false
    property bool moreMenuOpen: false
    property bool composing: false
    signal closeRequested()

    readonly property var dida: QsServices.Dida
    readonly property color cSurface: Qt.rgba(0.14, 0.14, 0.15, 0.91)
    readonly property color cText: "#eeeeee"
    readonly property color cSubText: "#969696"
    readonly property color cDimText: "#777777"
    readonly property color cHover: Qt.rgba(1, 1, 1, 0.075)
    readonly property color cBorder: Qt.rgba(1, 1, 1, 0.085)
    readonly property var taskEntries: buildEntries(dida.currentTasks, dida.lastUpdated)

    implicitWidth: 374
    implicitHeight: 570
    focus: true

    Keys.onEscapePressed: {
        if (projectMenuOpen || moreMenuOpen) {
            projectMenuOpen = false
            moreMenuOpen = false
        } else if (composing) {
            composing = false
        } else {
            closeRequested()
        }
    }

    function projectName() {
        for (let i = 0; i < dida.projects.length; ++i) {
            if (dida.projects[i].id === dida.selectedProjectId)
                return dida.projects[i].name
        }
        return "收集箱"
    }

    function parseTaskDate(task) {
        const raw = task.dueDate || task.startDate
        if (!raw)
            return null
        // Dida365 serializes offsets as +0800; JS Date expects +08:00.
        const normalized = String(raw).replace(/([+-]\d{2})(\d{2})$/, "$1:$2")
        const date = new Date(normalized)
        return isNaN(date.getTime()) ? null : date
    }

    function dayKey(date) {
        return Date.UTC(date.getFullYear(), date.getMonth(), date.getDate())
    }

    function dayOffset(date) {
        return Math.round((dayKey(date) - dayKey(new Date())) / 86400000)
    }

    function dateLabel(task) {
        const date = parseTaskDate(task)
        if (!date)
            return ""
        const offset = dayOffset(date)
        if (offset === 0)
            return "今天"
        if (offset === 1)
            return "明天"
        return (date.getMonth() + 1) + "月" + date.getDate() + "日"
    }

    function buildEntries(tasks, updatedAt) {
        // updatedAt re-evaluates the list after a remote refresh.
        const buckets = [[], [], [], []]
        for (let i = 0; i < tasks.length; ++i) {
            const task = tasks[i]
            const date = parseTaskDate(task)
            if (!date) {
                buckets[3].push(task)
            } else {
                const offset = dayOffset(date)
                buckets[offset <= 0 ? 0 : (offset <= 7 ? 1 : 2)].push(task)
            }
        }

        for (let i = 0; i < 3; ++i) {
            buckets[i].sort(function(a, b) {
                return parseTaskDate(a).getTime() - parseTaskDate(b).getTime()
            })
        }

        const titles = ["今天", "接下来 7 天", "更远", "没有日期"]
        const entries = []
        for (let i = 0; i < buckets.length; ++i) {
            if (buckets[i].length === 0)
                continue
            entries.push({ kind: "heading", title: titles[i] })
            for (let j = 0; j < buckets[i].length; ++j)
                entries.push({ kind: "task", task: buckets[i][j] })
        }
        return entries
    }

    function openComposer() {
        projectMenuOpen = false
        moreMenuOpen = false
        composing = true
        Qt.callLater(function() { titleInput.forceActiveFocus() })
    }

    function submitTask() {
        const title = titleInput.text.trim()
        if (!title || dida.adding)
            return
        dida.addTask(title)
    }

    Connections {
        target: dida
        function onTaskAdded() {
            titleInput.clear()
            popupPanel.composing = false
        }
    }

    Rectangle {
        id: panelSurface
        anchors.fill: parent
        radius: 19
        color: cSurface
        border.color: cBorder
        border.width: 1

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.36)
            shadowBlur: 0.9
            shadowVerticalOffset: 6
        }

        ColumnLayout {
            id: mainContent
            anchors.fill: parent
            anchors.margins: 13
            spacing: 0

            RowLayout {
                id: headerRow
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                spacing: 6

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Text {
                            text: popupPanel.projectName()
                            color: cText
                            font.family: "Inter"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            width: Math.min(218, implicitWidth)
                        }

                        Text {
                            text: "⌄"
                            color: cSubText
                            font.pixelSize: 17
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            popupPanel.moreMenuOpen = false
                            popupPanel.projectMenuOpen = !popupPanel.projectMenuOpen
                        }
                    }
                }

                Item {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 32

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: cText
                        font.family: "Inter"
                        font.pixelSize: 27
                        font.weight: Font.Light
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 9
                        color: addMouse.containsMouse ? cHover : "transparent"
                        z: -1
                    }

                    MouseArea {
                        id: addMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popupPanel.openComposer()
                    }
                }

                Item {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 32

                    Text {
                        anchors.centerIn: parent
                        text: "⋮"
                        color: cText
                        font.pixelSize: 21
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 9
                        color: moreMouse.containsMouse ? cHover : "transparent"
                        z: -1
                    }

                    MouseArea {
                        id: moreMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            popupPanel.projectMenuOpen = false
                            popupPanel.moreMenuOpen = !popupPanel.moreMenuOpen
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 8 }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: dida.configured ? 38 : 55
                visible: dida.errorText.length > 0
                radius: 8
                color: Qt.rgba(0.85, 0.30, 0.30, 0.12)
                border.color: Qt.rgba(0.85, 0.30, 0.30, 0.25)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: dida.errorText
                        color: "#efaaaa"
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: !dida.configured
                        Layout.fillWidth: true
                        text: dida.configPath
                        color: cSubText
                        font.pixelSize: 9
                        elide: Text.ElideMiddle
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                Layout.topMargin: 2
                Layout.bottomMargin: 8
                visible: popupPanel.composing
                radius: 10
                color: Qt.rgba(1, 1, 1, 0.07)
                border.color: cBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 8

                    QQC.TextField {
                        id: titleInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        placeholderText: "添加任务到" + popupPanel.projectName()
                        placeholderTextColor: cDimText
                        color: cText
                        font.pixelSize: 12
                        selectByMouse: true
                        enabled: !dida.adding
                        background: Item {}
                        onAccepted: popupPanel.submitTask()
                    }

                    Text {
                        text: dida.adding ? "添加中" : "添加"
                        color: dida.adding ? cDimText : cText
                        font.pixelSize: 11

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -7
                            enabled: !dida.adding
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popupPanel.submitTask()
                        }
                    }
                }
            }

            ListView {
                id: taskList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                spacing: 0
                model: popupPanel.taskEntries

                delegate: Item {
                    id: entryRow
                    required property var modelData
                    readonly property bool isHeading: modelData.kind === "heading"
                    readonly property var task: isHeading ? null : modelData.task

                    width: taskList.width
                    height: isHeading ? 34 : 33

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 0
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 5
                        visible: entryRow.isHeading
                        text: entryRow.isHeading ? entryRow.modelData.title : ""
                        color: cDimText
                        font.family: "Inter"
                        font.pixelSize: 10
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 7
                        visible: !entryRow.isHeading
                        color: taskHover.hovered ? cHover : "transparent"
                        opacity: dida.pendingTaskId === (entryRow.task ? entryRow.task.id : "") ? 0.50 : 1.0

                        Behavior on color { ColorAnimation { duration: 100 } }

                        HoverHandler { id: taskHover }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 1
                            anchors.rightMargin: 3
                            spacing: 9

                            Rectangle {
                                Layout.preferredWidth: 15
                                Layout.preferredHeight: 15
                                radius: 4
                                color: checkArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                                border.width: 1.2
                                border.color: "#a9a9a9"

                                Text {
                                    anchors.centerIn: parent
                                    text: dida.pendingTaskId === (entryRow.task ? entryRow.task.id : "") ? "✓" : ""
                                    color: cText
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    id: checkArea
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    hoverEnabled: true
                                    enabled: !dida.completing && !dida.adding
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: dida.completeTask(entryRow.task)
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: entryRow.task ? entryRow.task.title : ""
                                color: cText
                                font.family: "Inter"
                                font.pixelSize: 12
                                font.weight: Font.Normal
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                text: entryRow.task ? popupPanel.dateLabel(entryRow.task) : ""
                                visible: text.length > 0
                                color: cSubText
                                font.family: "Inter"
                                font.pixelSize: 10
                            }
                        }
                    }
                }

                QQC.ScrollBar.vertical: QQC.ScrollBar {
                    policy: QQC.ScrollBar.AsNeeded
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                visible: dida.loading
                text: "正在同步…"
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                color: cSubText
                font.pixelSize: 10
            }
        }

        Text {
            anchors.centerIn: parent
            visible: !dida.loading && dida.errorText.length === 0 && dida.currentTasks.length === 0
            text: dida.projects.length === 0 ? "没有可显示的清单" : "这个清单还没有任务"
            color: cSubText
            font.pixelSize: 12
        }

        // Menus live above the scroll view, so their contents are never clipped.
        MouseArea {
            anchors.fill: parent
            z: 5
            visible: popupPanel.projectMenuOpen || popupPanel.moreMenuOpen
            onClicked: {
                popupPanel.projectMenuOpen = false
                popupPanel.moreMenuOpen = false
            }
        }

        Rectangle {
            id: projectMenu
            x: 12
            y: 49
            z: 6
            width: Math.min(252, panelSurface.width - 24)
            height: Math.min(266, dida.projects.length * 36 + 10)
            visible: popupPanel.projectMenuOpen && dida.projects.length > 0
            color: "#303032"
            radius: 11
            border.color: cBorder
            clip: true

            ListView {
                anchors.fill: parent
                anchors.margins: 5
                model: dida.projects
                spacing: 0
                clip: true

                delegate: Rectangle {
                    id: projectEntry
                    required property var modelData
                    width: ListView.view.width
                    height: 36
                    radius: 7
                    color: projectMouse.containsMouse ? cHover : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        spacing: 7

                        Text {
                            Layout.fillWidth: true
                            text: projectEntry.modelData.name
                            color: cText
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }

                        Text {
                            text: dida.projectOpenCount(projectEntry.modelData.id)
                            color: cSubText
                            font.pixelSize: 10
                        }

                        Text {
                            visible: dida.selectedProjectId === projectEntry.modelData.id
                            text: "✓"
                            color: cText
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        id: projectMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            dida.selectProject(projectEntry.modelData.id)
                            popupPanel.projectMenuOpen = false
                        }
                    }
                }
            }
        }

        Rectangle {
            id: moreMenu
            x: panelSurface.width - width - 12
            y: 49
            z: 6
            width: 162
            height: 80
            radius: 11
            visible: popupPanel.moreMenuOpen
            color: "#303032"
            border.color: cBorder

            Column {
                anchors.fill: parent
                anchors.margins: 5
                spacing: 0

                Repeater {
                    model: [
                        { label: "刷新任务", action: "refresh" },
                        { label: "打开滴答清单", action: "open" }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        width: moreMenu.width - 10
                        height: 35
                        radius: 7
                        color: menuMouse.containsMouse ? cHover : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label
                            color: cText
                            font.pixelSize: 11
                        }

                        MouseArea {
                            id: menuMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                popupPanel.moreMenuOpen = false
                                if (modelData.action === "refresh")
                                    dida.refresh()
                                else
                                    Qt.openUrlExternally("https://dida365.com")
                            }
                        }
                    }
                }
            }
        }
    }
}
