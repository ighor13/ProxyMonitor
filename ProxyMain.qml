import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: mainPage
    signal settingsClicked()

    property var proxyModel

    readonly property int columns: Math.max(2, Math.floor(width / 160))

    function getShortName(host) {
        if (!host) return "";
        if (/^\d/.test(host)) {
            return host;
        }
        return host.split('.')[0];
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        GridView {
            id: gridView
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: width / mainPage.columns
            cellHeight: 80
            clip: true

            model: mainPage.proxyModel

            delegate: Item {
                id: delegateItem
                width: gridView.cellWidth
                height: gridView.cellHeight

                Rectangle {
                    id: card
                    anchors.fill: parent
                    anchors.margins: 5
                    radius: 10

                    border.width: 2
                    border.color: {
                        if (model.status === "alive") return "#4CAF50"   // Зеленый
                        if (model.status === "dead") return "#F44336"    // Красный
                        if (model.status === "timeout") return "#F44336" // Красный
                        if (model.status === "dns_fail") return "#000000"// Черный
                        if (model.status === "testing") return "#FFC107" // ЖЁЛТЫЙ (в процессе)
                        return "#9E9E9E" // СЕРЫЙ (unknown по умолчанию)
                    }
                    color: {
                        if (model.status === "alive") return "#E8F5E9"
                        if (model.status === "dead") return "#FFEBEE"
                        if (model.status === "timeout") return "#FFEBEE"
                        if (model.status === "dns_fail") return "#E0E0E0"
                        if (model.status === "testing") return "#FFF8E1" // Светло-желтый
                        return "#F5F5F5" // Светло-серый
                    }

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: "#30000000"
                        shadowBlur: 0.2
                        shadowVerticalOffset: 1
                    }

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                    }

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 8
                        spacing: 2

                        Text {
                            text: mainPage.getShortName(model.host)
                            font.pixelSize: 14
                            font.bold: true
                            color: model.status === "dns_fail" ? "#666666" : "#333333"
                            anchors.horizontalCenter: parent.horizontalCenter
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WrapAnywhere
                            width: parent.width
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                        Text {
                            text: ":" + model.port
                            font.pixelSize: 12
                            color: "#666666"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    Popup {
                        id: tooltipPopup
                        visible: hoverArea.containsMouse && model.response !== ""
                        x: card.width / 2 - width / 2
                        y: card.height + 2
                        background: null
                        closePolicy: Popup.NoAutoClose

                        Rectangle {
                            width: Math.min(tooltipLayout.implicitWidth + 24, 320)
                            height: tooltipLayout.implicitHeight + 16
                            color: "#37474F"
                            radius: 6
                            border.color: "#263238"
                            border.width: 1
                            x: -width / 2

                            ColumnLayout {
                                id: tooltipLayout
                                anchors.centerIn: parent
                                width: parent.width - 24
                                spacing: 4

                                Text {
                                    text: model.host
                                    color: "#B0BEC5"
                                    font.pixelSize: 11
                                    font.bold: true
                                    wrapMode: Text.Wrap
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: model.response
                                    color: "#FFFFFF"
                                    font.pixelSize: 12
                                    wrapMode: Text.Wrap
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 10
            spacing: 20

            Button {
                text: "▶ Test"
                font.pixelSize: 16
                Layout.preferredWidth: 130
                Layout.preferredHeight: 46

                background: Rectangle {
                    color: parent.pressed ? "#1976D2" : "#2196F3"
                    radius: 10
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font: parent.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    // Отменяем все старые процессы перед новым запуском
                    proxyTest.cancelAll()

                    let proxiesToTest = []
                    for (let i = 0; i < mainPage.proxyModel.count; i++) {
                        let item = mainPage.proxyModel.get(i)
                        proxiesToTest.push({
                            host: item.host,
                            port: item.port
                        })
                        mainPage.proxyModel.setProperty(i, "status", "unknown")
                        mainPage.proxyModel.setProperty(i, "response", "")
                    }
                    proxyTest.testAll(proxiesToTest)
                }
            }

            Button {
                text: "⚙ Settings"
                font.pixelSize: 16
                Layout.preferredWidth: 130
                Layout.preferredHeight: 46

                background: Rectangle {
                    color: parent.pressed ? "#E0E0E0" : "#FFFFFF"
                    border.color: "#BDBDBD"
                    border.width: 1
                    radius: 10
                }
                contentItem: Text {
                    text: parent.text
                    color: "#333333"
                    font: parent.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: mainPage.settingsClicked()
            }
        }
    }

    Connections {
        target: proxyTest
        function onProxyResult(index, alive, info, errorMsg, status) {
            if (index >= 0 && index < mainPage.proxyModel.count) {
                mainPage.proxyModel.setProperty(index, "status", status)
                mainPage.proxyModel.setProperty(index, "response", info)
            }
        }
    }
}