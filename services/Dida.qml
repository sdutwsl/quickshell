pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick 6.10
import "." as QsServices

Singleton {
    id: root

    property bool loading: false
    property bool completing: false
    property bool configured: false
    property bool loadedOnce: false

    property string errorCode: ""
    property string errorText: ""
    property string errorDetails: ""
    property string configPath: Quickshell.env("HOME") + "/.config/quickshell/dida365.json"

    property var projects: []
    property var tasks: []
    property string inboxId: ""
    property string selectedProjectId: ""
    property string pendingTaskId: ""
    property double lastUpdated: 0

    readonly property int openCount: tasks.length
    readonly property var currentTasks: tasks.filter(function(task) {
        return task.projectId === selectedProjectId
    })

    function helperCommand(args) {
        return ["python3", Quickshell.shellPath("scripts/dida365.py")].concat(args)
    }

    function projectOpenCount(projectId) {
        let count = 0
        for (let i = 0; i < tasks.length; ++i) {
            if (tasks[i].projectId === projectId)
                count++
        }
        return count
    }

    function selectProject(projectId) {
        selectedProjectId = projectId
    }

    function refresh() {
        if (syncProcess.running)
            return

        loading = true
        errorCode = ""
        errorText = ""
        errorDetails = ""
        syncProcess.exec(helperCommand(["sync"]))
    }

    function completeTask(task) {
        if (!task || !task.id || !task.projectId || completionProcess.running)
            return

        completing = true
        pendingTaskId = task.id
        errorCode = ""
        errorText = ""
        errorDetails = ""
        completionProcess.exec(helperCommand(["complete", task.id, task.projectId]))
    }

    function parsePayload(raw) {
        const value = raw.trim()
        if (value.length === 0)
            return null

        try {
            return JSON.parse(value)
        } catch (e) {
            errorCode = "invalid_json"
            errorText = "滴答辅助进程返回了无法解析的数据"
            errorDetails = value
            return null
        }
    }

    function applyError(payload) {
        configured = payload.configured !== false
        if (payload.configPath)
            configPath = payload.configPath
        errorCode = payload.error || "unknown_error"
        errorText = payload.message || "滴答清单请求失败"
        errorDetails = payload.details || ""
    }

    Process {
        id: syncProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const payload = root.parsePayload(text)
                root.loading = false
                root.loadedOnce = true

                if (!payload)
                    return

                if (!payload.ok) {
                    root.applyError(payload)
                    return
                }

                root.configured = true
                root.errorCode = ""
                root.errorText = ""
                root.errorDetails = ""
                root.projects = payload.projects || []
                root.tasks = payload.tasks || []
                root.inboxId = payload.inboxId || ""
                if (payload.configPath)
                    root.configPath = payload.configPath
                root.lastUpdated = Date.now()

                let selectedStillExists = false
                for (let i = 0; i < root.projects.length; ++i) {
                    if (root.projects[i].id === root.selectedProjectId) {
                        selectedStillExists = true
                        break
                    }
                }

                if (!selectedStillExists) {
                    if (root.inboxId)
                        root.selectedProjectId = root.inboxId
                    else if (root.projects.length > 0)
                        root.selectedProjectId = root.projects[0].id
                    else
                        root.selectedProjectId = ""
                }
            }
        }

        onExited: function(code) {
            root.loading = false
            if (code !== 0 && root.errorText.length === 0) {
                root.errorCode = "helper_failed"
                root.errorText = "滴答辅助进程异常退出"
            }
        }
    }

    Process {
        id: completionProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const payload = root.parsePayload(text)
                root.completing = false
                const completedId = root.pendingTaskId
                root.pendingTaskId = ""

                if (!payload)
                    return

                if (!payload.ok) {
                    root.applyError(payload)
                    return
                }

                root.tasks = root.tasks.filter(function(task) {
                    return task.id !== completedId
                })

                Qt.callLater(root.refresh)
            }
        }

        onExited: function(code) {
            root.completing = false
            if (code !== 0 && root.errorText.length === 0) {
                root.errorCode = "complete_failed"
                root.errorText = "完成任务失败"
            }
        }
    }

    Timer {
        interval: 300000
        repeat: true
        running: root.loadedOnce && root.configured
        onTriggered: root.refresh()
    }

    Component.onCompleted: QsServices.Logger.debug("Dida", "Service initialized")
}
