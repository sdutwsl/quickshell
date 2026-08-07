pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick 6.10

Singleton {
    id: root

    property string text: ""
    property bool loading: false

    function refresh() {
        if (weatherProcess.running)
            return
        loading = true
        weatherProcess.running = true
    }

    Process {
        id: weatherProcess
        command: [
            "/bin/sh", "-c",
            "file=\"$HOME/.cache/.region\"; " +
            "[ -f \"$file\" ] || exit 0; " +
            "region=$(cat \"$file\"); " +
            "json=$(curl -fsSL --compressed \"https://weather.cma.cn/api/now/$region\" " +
            "-H 'User-Agent: Mozilla/5.0' -H 'Accept: application/json, text/plain, */*' " +
            "-H 'Referer: https://weather.cma.cn/' 2>/dev/null) || exit 0; " +
            "city=$(printf '%s' \"$json\" | grep -o '\"name\":[^,]*' | head -1 | sed 's/\"name\"://' | tr -d '\"'); " +
            "temp=$(printf '%s' \"$json\" | grep -o '\"temperature\":[^,]*' | head -1 | sed 's/\"temperature\"://'); " +
            "humi=$(printf '%s' \"$json\" | grep -o '\"humidity\":[^,]*' | head -1 | sed 's/\"humidity\"://'); " +
            "[ -n \"$city\" ] && printf '%s 气温: %s°C 湿度: %s%%\\n' \"$city\" \"$temp\" \"$humi\""
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim()
                if (value.length > 0)
                    root.text = value
                root.loading = false
            }
        }

        onExited: root.loading = false
    }

    Timer {
        interval: 300000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
