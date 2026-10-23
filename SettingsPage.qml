import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item {
    id: settingsPage
    signal backClicked()

    property var proxyModel

    function commitChanges() {
        proxyTest.setTargetUrl(targetField.text)
        backClicked()
    }

    component StyledButton: Button {
        id: btn
        property string btnColor: "#FFFFFF"
        property string btnPressedColor: "#E0E0E0"
        property string txtColor: "#333333"
        property int borderWidth: 1

        Layout.preferredHeight: 40
        padding: 0

        background: Rectangle {
            color: btn.pressed ? btn.btnPressedColor : btn.btnColor
            border.color: "#BDBDBD"
            border.width: btn.borderWidth
            radius: 8
        }
        contentItem: Text {
            text: btn.text
            color: btn.txtColor
            font.pixelSize: 14
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    FileDialog {
        id: saveDialog
        title: "Экспорт списка прокси"
        fileMode: FileDialog.SaveFile
        nameFilters: ["JSON files (*.json)", "All files (*)"]
        defaultSuffix: "json"
        onAccepted: {
            let data = []
            for (let i = 0; i < settingsPage.proxyModel.count; i++) {
                let item = settingsPage.proxyModel.get(i)
                data.push({ host: item.host, port: item.port })
            }
            let jsonString = JSON.stringify(data, null, 4)
            proxyTest.saveToFile(selectedFile, jsonString)
        }
    }

    FileDialog {
        id: loadDialog
        title: "Импорт списка прокси"
        fileMode: FileDialog.OpenFile
        nameFilters: ["JSON files (*.json)", "All files (*)"]
        onAccepted: {
            let jsonString = proxyTest.loadFromFile(selectedFile)
            if (jsonString !== "") {
                try {
                    let data = JSON.parse(jsonString)

                    // Отменяем все текущие проверки при импорте!
                    proxyTest.cancelAll()

                    settingsPage.proxyModel.clear()
                    for (let i = 0; i < data.length; i++) {
                        settingsPage.proxyModel.append({
                            host: data[i].host,
                            port: data[i].port,
                            status: "unknown",
                            response: ""
                        })
                    }
                } catch (e) {
                    console.log("Ошибка парсинга JSON:", e)
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 15

        Text {
            text: "Target URL"
            font.bold: true
            font.pixelSize: 16
            color: "#333333"
        }

        TextField {
            id: targetField
            Layout.fillWidth: true
            text: proxyTest.targetUrl
            placeholderText: "http://example.com"
            font.pixelSize: 14
            padding: 10
            background: Rectangle {
                color: "white"
                border.color: targetField.activeFocus ? "#2196F3" : "#BDBDBD"
                border.width: targetField.activeFocus ? 2 : 1
                radius: 8
            }
            onEditingFinished: proxyTest.setTargetUrl(text)
            onTextChanged: proxyTest.setTargetUrl(text)
        }

        RowLayout {
            spacing: 10
            Layout.fillWidth: true

            CheckBox {
                id: avoidCacheCheckbox
                checked: proxyTest.avoidCache
                onCheckedChanged: proxyTest.setAvoidCache(checked)
            }
            Text {
                text: "Обходить кеш (добавлять метку времени)"
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                font.pixelSize: 14
                color: "#555555"
            }
        }

        RowLayout {
            spacing: 10
            Layout.fillWidth: true
            Layout.topMargin: 5

            Text {
                text: "Таймаут (мс):"
                font.pixelSize: 14
                color: "#555555"
            }

            TextField {
                id: timeoutField
                Layout.preferredWidth: 100
                text: proxyTest.timeoutMs
                font.pixelSize: 14
                padding: 6
                validator: IntValidator { bottom: 1000; top: 60000 }
                background: Rectangle {
                    color: "white"
                    border.color: timeoutField.activeFocus ? "#2196F3" : "#BDBDBD"
                    border.width: timeoutField.activeFocus ? 2 : 1
                    radius: 8
                }
                onEditingFinished: {
                    let ms = parseInt(text)
                    if (ms >= 1000) {
                        proxyTest.setTimeoutMs(ms)
                    }
                }
            }
        }

        Text {
            text: "Proxy List"
            font.bold: true
            font.pixelSize: 16
            color: "#333333"
            Layout.topMargin: 10
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 10

            model: settingsPage.proxyModel

            delegate: RowLayout {
                width: listView.width
                spacing: 10

                TextField {
                    text: model.host
                    Layout.fillWidth: true
                    font.pixelSize: 14
                    padding: 8
                    background: Rectangle {
                        color: "white"
                        border.color: parent.activeFocus ? "#2196F3" : "#BDBDBD"
                        border.width: parent.activeFocus ? 2 : 1
                        radius: 8
                    }
                    onEditingFinished: {
                        settingsPage.proxyModel.setProperty(index, "host", text)
                    }
                }

                TextField {
                    text: model.port
                    Layout.preferredWidth: 80
                    font.pixelSize: 14
                    padding: 8
                    validator: IntValidator { bottom: 1; top: 65535 }
                    background: Rectangle {
                        color: "white"
                        border.color: parent.activeFocus ? "#2196F3" : "#BDBDBD"
                        border.width: parent.activeFocus ? 2 : 1
                        radius: 8
                    }
                    onEditingFinished: {
                        settingsPage.proxyModel.setProperty(index, "port", parseInt(text))
                    }
                }

                Button {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    background: Rectangle {
                        color: parent.pressed ? "#FFCDD2" : "#FFEBEE"
                        radius: 8
                    }
                    contentItem: Text {
                        text: "✕"
                        color: "#D32F2F"
                        font.pixelSize: 18
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        settingsPage.proxyModel.remove(index)
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            StyledButton {
                text: "Add"
                Layout.fillWidth: true
                onClicked: {
                    proxyTest.cancelAll() // Отменяем старые тесты
                    settingsPage.proxyModel.append({
                        host: "127.0.0.1",
                        port: 3128,
                        status: "unknown",
                        response: ""
                    })
                }
            }

            StyledButton {
                text: "Import"
                Layout.fillWidth: true
                onClicked: loadDialog.open()
            }

            StyledButton {
                text: "Export"
                Layout.fillWidth: true
                onClicked: saveDialog.open()
            }
        }

        Button {
            text: "Back"
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            Layout.topMargin: 10

            background: Rectangle {
                color: parent.pressed ? "#1976D2" : "#2196F3"
                radius: 8
            }
            contentItem: Text {
                text: parent.text
                color: "white"
                font.pixelSize: 16
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: {
                targetField.focus = false
                settingsPage.commitChanges()
            }
        }
    }
}