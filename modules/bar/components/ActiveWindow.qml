import QtQuick 6.10
import QtQuick.Layouts 6.10
import qs.services

Item {
    id: root

    // The standalone Bar loader leaves this false so the old separate pill stays hidden.
    // Workspaces.qml enables it to place the title inside the workspace module.
    property bool embedded: false
    readonly property bool hasWindow: embedded && ActiveWindow.title.length > 0
    readonly property int fixedWidth: 170

    implicitWidth: hasWindow ? fixedWidth : 0
    implicitHeight: 20
    visible: hasWindow

    RowLayout {
        anchors.fill: parent
        spacing: 5

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: "󰖯"
            font.family: "Material Design Icons"
            font.pixelSize: 13
            color: Pywal.secondary
        }

        Item {
            id: titleViewport
            Layout.fillWidth: true
            Layout.preferredHeight: 20
            clip: true

            Text {
                id: titleText
                anchors.verticalCenter: parent.verticalCenter
                text: ActiveWindow.title
                font.family: "Inter"
                font.pixelSize: 10
                font.weight: Font.Medium
                color: Pywal.foreground
                wrapMode: Text.NoWrap

                property bool needsScroll: implicitWidth > titleViewport.width

                x: needsScroll ? 0 : Math.max(0, (titleViewport.width - implicitWidth) / 2)

                SequentialAnimation {
                    id: titleMarquee
                    running: titleText.needsScroll && root.visible
                    loops: Animation.Infinite

                    PauseAnimation { duration: 1800 }
                    NumberAnimation {
                        target: titleText
                        property: "x"
                        to: -(titleText.implicitWidth + 16)
                        duration: Math.max(1200, titleText.implicitWidth * 24)
                        easing.type: Easing.Linear
                    }
                    PropertyAction {
                        target: titleText
                        property: "x"
                        value: titleViewport.width
                    }
                    NumberAnimation {
                        target: titleText
                        property: "x"
                        to: 0
                        duration: 260
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    Connections {
        target: ActiveWindow
        function onTitleChanged() {
            titleText.x = titleText.needsScroll
                ? 0
                : Math.max(0, (titleViewport.width - titleText.implicitWidth) / 2)
            if (titleText.needsScroll && root.visible)
                titleMarquee.restart()
        }
    }
}
