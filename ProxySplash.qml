import QtQuick
import QtQuick.Controls

Item {
    id: splash
    signal timeout()

    Rectangle {
        anchors.fill: parent
        color: "#2c3e50"

        Column {
            anchors.centerIn: parent
            spacing: 20
            Text {
                text: "Proxy Monitor"
                color: "white"
                font.pixelSize: 32
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }
            BusyIndicator {
                running: true
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        onTriggered: splash.timeout()
    }
}