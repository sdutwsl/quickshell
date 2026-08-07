pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick 6.10
import "." as QsServices

Singleton {
    id: root

    property string currentLyric: ""
    property string loadedTrackKey: ""
    property string requestedTrackKey: ""
    property var timedLines: []
    property bool loading: false

    readonly property var player: QsServices.Players.active
    readonly property bool available: player !== null

    function valueString(value) {
        if (value === undefined || value === null)
            return ""
        if (Array.isArray(value))
            return value.join(", ")
        return `${value}`
    }

    function trackKey() {
        if (!player)
            return ""
        return `${valueString(player.trackArtist)}\u0000${valueString(player.trackAlbum)}\u0000${valueString(player.trackTitle)}`
    }

    function refreshTrack() {
        const key = trackKey()
        if (key.length === 0) {
            loadedTrackKey = ""
            requestedTrackKey = ""
            timedLines = []
            currentLyric = ""
            return
        }

        if (key === loadedTrackKey || key === requestedTrackKey || lyricProcess.running)
            return

        requestedTrackKey = key
        timedLines = []
        currentLyric = ""
        loading = true

        lyricProcess.command = [
            "curl", "-fsS", "-G",
            "-H", "Authorization: 114514",
            "--data-urlencode", `title=${valueString(player.trackTitle)}`,
            "--data-urlencode", `album=${valueString(player.trackAlbum)}`,
            "--data-urlencode", `artist=${valueString(player.trackArtist)}`,
            "http://127.0.0.1:28883/api/v1/lyrics/single"
        ]
        lyricProcess.running = true
    }

    function parseLrc(raw) {
        const result = []
        const lines = raw.split(/\r?\n/)

        for (let i = 0; i < lines.length; i++) {
            const match = lines[i].match(/^\[(\d+):([0-9.]+)\](.*)$/)
            if (!match)
                continue

            const seconds = Number(match[1]) * 60 + Number(match[2])
            if (isNaN(seconds))
                continue

            result.push({
                time: seconds,
                text: match[3].trim()
            })
        }

        result.sort((a, b) => a.time - b.time)
        return result
    }

    function updateCurrentLyric() {
        if (!player || timedLines.length === 0) {
            currentLyric = ""
            return
        }

        const position = Number(player.position ?? 0)
        let lyric = ""

        for (let i = 0; i < timedLines.length; i++) {
            if (timedLines[i].time > position)
                break
            lyric = timedLines[i].text
        }

        if (currentLyric !== lyric)
            currentLyric = lyric
    }

    function copyCurrentLyric() {
        if (currentLyric.length === 0)
            return
        Quickshell.execDetached([
            "/bin/sh", "-c",
            "printf '%s' \"$1\" | wl-copy",
            "sh", currentLyric
        ])
    }

    Process {
        id: lyricProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.timedLines = root.parseLrc(text)
                root.loadedTrackKey = root.requestedTrackKey
                root.requestedTrackKey = ""
                root.loading = false
                root.updateCurrentLyric()
            }
        }

        onExited: {
            root.loading = false
            if (root.requestedTrackKey.length > 0 && root.timedLines.length === 0) {
                root.loadedTrackKey = root.requestedTrackKey
                root.requestedTrackKey = ""
            }
        }
    }

    Connections {
        target: QsServices.Players
        function onActiveChanged() { root.refreshTrack() }
    }

    Connections {
        target: root.player
        ignoreUnknownSignals: true
        function onTrackTitleChanged() { root.refreshTrack() }
        function onTrackAlbumChanged() { root.refreshTrack() }
        function onTrackArtistChanged() { root.refreshTrack() }
    }

    Timer {
        interval: 200
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.refreshTrack()
            root.updateCurrentLyric()
        }
    }
}
