import QtQuick 6.10
import QtQuick.Layouts 6.10
import qs.services

Item {
    id: root

    implicitWidth: Math.min(attendanceRow.implicitWidth, 150)
    implicitHeight: 20

    RowLayout {
        id: attendanceRow
        anchors.centerIn: parent
        spacing: 5

        Text {
            text: Attendance.checking ? "󰔛" : "󰅐"
            font.family: "Material Design Icons"
            font.pixelSize: 14
            color: Attendance.checking ? Pywal.warning : Pywal.primary
        }

        Text {
            Layout.maximumWidth: 128
            text: `考勤：${Attendance.status}`
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
        onClicked: Attendance.checkNow()
    }
}
