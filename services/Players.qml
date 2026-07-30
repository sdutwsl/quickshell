pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQml.Models
import QtQuick 6.10

Singleton {
    id: root

    readonly property var list: Mpris.players.values
    property var active: null

    Connections {
        target: Mpris.players

        function onValuesChanged() {
            root.updateActivePlayer()
        }
    }

    Instantiator {
        model: Mpris.players

        Connections {
            required property MprisPlayer modelData
            target: modelData

            function onPlaybackStateChanged() {
                root.updateActivePlayer()
            }
        }

        onObjectAdded: root.updateActivePlayer()
        onObjectRemoved: root.updateActivePlayer()
    }

    function updateActivePlayer() {
        let newActive = null

        for (var i = 0; i < list.length; i++) {
            if (list[i]?.isPlaying) {
                newActive = list[i]
                break
            }
        }

        if (newActive) {
            active = newActive
            return
        }

        for (var i = 0; i < list.length; i++) {
            if (list[i] === active) {
                return
            }
        }

        active = list[0] ?? null
    }

    Component.onCompleted: {
        updateActivePlayer()
    }

    function getIdentity(player: var): string {
        return player?.identity ?? "Unknown";
    }

    function toggle(player) {
        const target = player ?? active
        if (!target)
            return

        if (target.isPlaying) {
            if (target.canPause)
                target.pause()
        } else if (target.canPlay) {
            target.play()
        }
    }
}
