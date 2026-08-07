import QtQuick 6.10
import QtQuick.Layouts 6.10
import qs.services

Item {
    id: root

    readonly property bool hasWeather: Weather.text.length > 0

    implicitWidth: hasWeather ? Math.min(weatherRow.implicitWidth, 170) : 0
    implicitHeight: 20
    visible: hasWeather

    RowLayout {
        id: weatherRow
        anchors.centerIn: parent
        spacing: 5

        Text {
            text: "󰖐"
            font.family: "Material Design Icons"
            font.pixelSize: 14
            color: Pywal.info
        }

        Text {
            Layout.maximumWidth: 150
            text: Weather.loading && Weather.text.length === 0 ? "天气刷新中…" : Weather.text
            font.family: "Inter"
            font.pixelSize: 10
            font.weight: Font.Medium
            color: Pywal.foreground
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Weather.refresh()
    }
}
