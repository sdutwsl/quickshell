pragma Singleton

import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinkAudio: sink?.audio ?? null
    readonly property var sourceAudio: source?.audio ?? null

    readonly property bool ready: Pipewire.ready && sinkAudio !== null
    readonly property bool muted: sinkAudio?.muted ?? false
    readonly property real volume: sinkAudio?.volume ?? 0
    readonly property int percentage: Math.round(volume * 100)

    readonly property bool sourceReady: Pipewire.ready && sourceAudio !== null
    readonly property bool sourceMuted: sourceAudio?.muted ?? false
    readonly property real sourceVolume: sourceAudio?.volume ?? 0
    readonly property int sourcePercentage: Math.round(sourceVolume * 100)

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    function clampVolume(value) {
        return Math.max(0, Math.min(1.5, value))
    }

    function setVolume(newVolume) {
        if (!sinkAudio)
            return

        sinkAudio.muted = false
        sinkAudio.volume = clampVolume(newVolume)
    }

    function increaseVolume() {
        setVolume(volume + 0.05)
    }

    function decreaseVolume() {
        setVolume(volume - 0.05)
    }

    function setMute(value) {
        if (sinkAudio)
            sinkAudio.muted = value
    }

    function toggleMute() {
        if (sinkAudio)
            sinkAudio.muted = !sinkAudio.muted
    }

    function setSourceVolume(newVolume) {
        if (!sourceAudio)
            return

        sourceAudio.muted = false
        sourceAudio.volume = clampVolume(newVolume)
    }

    function setSourceMute(value) {
        if (sourceAudio)
            sourceAudio.muted = value
    }

    function toggleSourceMute() {
        if (sourceAudio)
            sourceAudio.muted = !sourceAudio.muted
    }
}
