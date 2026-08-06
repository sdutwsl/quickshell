import QtQuick 6.10
import QtQuick.Controls 6.10
import QtQuick.Layouts 6.10
import Quickshell
import qs.services
import "../../../components"
import "../../../components/effects"

// Compact Music Widget - Fixed buttons, proper text reset
Item {
    id: root
    
    property var barWindow
    property var mediaPopup
    
    // Always show - either player content or "No media" text
    // Use fixed width for no media state to avoid circular dependency
    implicitWidth: hasPlayer ? contentRow.implicitWidth : 70
    implicitHeight: 22
    visible: true
    
    readonly property var player: Players.active
    readonly property bool hasPlayer: player !== null
    readonly property bool isPlaying: player?.isPlaying ?? false
    readonly property real progress: player?.position ?? 0
    readonly property real duration: player?.length ?? 1
    readonly property real progressPercent: duration > 0 ? progress / duration : 0
    
    property bool isHovered: contentMouse.containsMouse || noMediaMouse.containsMouse
    
    // Reset text position when paused
    onIsPlayingChanged: {
        if (!isPlaying) {
            marqueeAnim.stop()
            titleText.x = titleText.needsScroll ? 0 : (80 - titleText.implicitWidth) / 2
        }
    }
    
    // No media placeholder
    RowLayout {
        id: noMediaRow
        anchors.centerIn: parent
        spacing: 6
        visible: !hasPlayer
        opacity: !hasPlayer ? 1 : 0
        
        Behavior on opacity { NumberAnimation { duration: 200 } }
        
        Text {
            text: "󰎇"
            font.family: "Material Design Icons"
            font.pixelSize: 14
            color: Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.4)
            Layout.alignment: Qt.AlignVCenter
        }
        
        Text {
            text: "No media"
            font.family: "Inter"
            font.pixelSize: 10
            font.weight: Font.Medium
            color: Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.4)
            Layout.alignment: Qt.AlignVCenter
        }
    }
    
    // Mouse area for no media state (outside layout)
    MouseArea {
        id: noMediaMouse
        anchors.fill: parent
        visible: !hasPlayer
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Players.raiseOrLaunch()
    }
    
    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6
        visible: hasPlayer
        opacity: hasPlayer ? 1 : 0
        
        Behavior on opacity { NumberAnimation { duration: 200 } }
        
        // Album artwork
        Rectangle {
            Layout.preferredWidth: 14
            Layout.preferredHeight: 14
            Layout.alignment: Qt.AlignVCenter
            radius: 7
            color: Pywal.surfaceContainerLow
            clip: true

            Image {
                id: albumArt
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                text: "󰝚"
                font.family: "Material Design Icons"
                font.pixelSize: 10
                color: Pywal.primary
                visible: albumArt.status !== Image.Ready
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Players.raiseOrLaunch(root.player)
            }
        }
        
        // Track Title - Marquee with proper reset
        Item {
            Layout.preferredWidth: 80
            Layout.preferredHeight: parent.height
            Layout.alignment: Qt.AlignVCenter
            clip: true
            
            MouseArea {
                id: contentMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Players.raiseOrLaunch(root.player)
            }
            
            Text {
                id: titleText
                anchors.verticalCenter: parent.verticalCenter
                
                text: root.player?.trackTitle ?? "Unknown"
                color: Pywal.foreground
                font.pixelSize: 10
                font.weight: Font.Medium
                
                property bool needsScroll: implicitWidth > 80
                
                x: needsScroll ? 0 : (80 - implicitWidth) / 2
                
                Behavior on x {
                    enabled: !marqueeAnim.running
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }
                
                SequentialAnimation {
                    id: marqueeAnim
                    running: titleText.needsScroll && root.isPlaying
                    loops: Animation.Infinite
                    
                    PauseAnimation { duration: 2000 }
                    NumberAnimation {
                        target: titleText
                        property: "x"
                        to: -(titleText.implicitWidth + 20)
                        duration: titleText.implicitWidth * 30
                        easing.type: Easing.Linear
                    }
                    PropertyAction { 
                        target: titleText
                        property: "x"
                        value: 80
                    }
                    NumberAnimation {
                        target: titleText
                        property: "x"
                        to: 0
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
        
        // Stylish divider
        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 12
            Layout.alignment: Qt.AlignVCenter
            radius: 0.5
            color: Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.18)
        }
        
        // Controls - Fixed with proper click handling
        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 2
            
            // Previous button
            Rectangle {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                radius: 10
                color: prevArea.containsMouse ? Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.15) : "transparent"
                
                Behavior on color { ColorAnimation { duration: 100 } }
                Behavior on scale { NumberAnimation { duration: 80 } }
                scale: prevArea.pressed ? 0.9 : 1.0
                
                Text {
                    anchors.centerIn: parent
                    text: "󰒮"
                    font.family: "Material Design Icons"
                    font.pixelSize: 13
                    color: prevArea.containsMouse ? Pywal.primary : Pywal.foreground
                    
                    Behavior on color { ColorAnimation { duration: 100 } }
                }
                
                MouseArea {
                    id: prevArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onClicked: {
                        if (root.player && root.player.canGoPrevious) {
                            root.player.previous()
                        }
                    }
                }
            }
            
            // Play/Pause button - Main action
            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 12
                color: playArea.containsMouse ? Qt.lighter(Pywal.primary, 1.08) : Pywal.primary
                
                Behavior on scale { NumberAnimation { duration: 80 } }
                scale: playArea.pressed ? 0.85 : (playArea.containsMouse ? 1.05 : 1.0)
                
                // Glow effect
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 4
                    height: parent.height + 4
                    radius: width / 2
                    color: "transparent"
                    border.width: 2
                    border.color: Qt.rgba(Pywal.primary.r, Pywal.primary.g, Pywal.primary.b, playArea.containsMouse ? 0.3 : 0)
                    z: -1
                    
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                }
                
                Text {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: root.isPlaying ? 0 : 1
                    text: root.isPlaying ? "󰏤" : "󰐊"
                    font.family: "Material Design Icons"
                    font.pixelSize: 14
                    color: Pywal.onPrimary
                }
                
                MouseArea {
                    id: playArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onClicked: {
                        Players.toggle(root.player)
                    }
                }
            }
            
            // Next button
            Rectangle {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                radius: 10
                color: nextArea.containsMouse ? Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.15) : "transparent"
                
                Behavior on color { ColorAnimation { duration: 100 } }
                Behavior on scale { NumberAnimation { duration: 80 } }
                scale: nextArea.pressed ? 0.9 : 1.0
                
                Text {
                    anchors.centerIn: parent
                    text: "󰒭"
                    font.family: "Material Design Icons"
                    font.pixelSize: 13
                    color: nextArea.containsMouse ? Pywal.primary : Pywal.foreground
                    
                    Behavior on color { ColorAnimation { duration: 100 } }
                }
                
                MouseArea {
                    id: nextArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onClicked: {
                        if (root.player && root.player.canGoNext) {
                            root.player.next()
                        }
                    }
                }
            }
        }
        
        // Player volume
        Item {
            id: playerVolumeControl

            Layout.preferredWidth: 54
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: playerVolumeSlider.value === 0 ? "󰖁" : "󰕾"
                font.family: "Material Design Icons"
                font.pixelSize: 13
                color: playerVolumeSlider.enabled ? Pywal.primary : Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.35)
            }

            Slider {
                id: playerVolumeSlider
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                height: 20
                from: 0
                to: 100
                value: (root.player?.volume ?? 1) * 100
                enabled: root.player?.canControl === true && root.player?.volumeSupported === true
                live: true

                onMoved: root.player.volume = value / 100

                HoverHandler {
                    cursorShape: Qt.OpenHandCursor
                }

                background: Rectangle {
                    x: playerVolumeSlider.leftPadding
                    y: playerVolumeSlider.topPadding + playerVolumeSlider.availableHeight / 2 - height / 2
                    width: playerVolumeSlider.availableWidth
                    height: 4
                    radius: 2
                    color: Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.12)

                    Rectangle {
                        width: playerVolumeSlider.visualPosition * parent.width
                        height: parent.height
                        radius: 2
                        color: Pywal.primary
                    }
                }

                handle: Rectangle {
                    x: playerVolumeSlider.leftPadding + playerVolumeSlider.visualPosition * (playerVolumeSlider.availableWidth - width)
                    y: playerVolumeSlider.topPadding + playerVolumeSlider.availableHeight / 2 - height / 2
                    width: 8
                    height: 8
                    radius: 4
                    color: Pywal.onPrimary
                }
            }
        }
    }
}
