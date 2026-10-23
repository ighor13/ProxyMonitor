import QtQuick
import QtQuick.Controls
import QtCore

ApplicationWindow {
    id: window
    visible: true
    width: 400
    height: 700
    title: "Proxy Monitor"

    Settings {
        id: appSettings
        category: "ProxyConfig"
        property string savedProxies: ""
        property string savedTargetUrl: "http://example.com"
        property bool savedAvoidCache: true
        property int savedTimeoutMs: 15000
    }

    ListModel {
        id: globalProxyModel
    }

    function saveModel() {
        let data = []
        for (let i = 0; i < globalProxyModel.count; i++) {
            let item = globalProxyModel.get(i)
            // Сохраняем ТОЛЬКО host и port, без статусов и ответов!
            data.push({ host: item.host, port: item.port })
        }
        appSettings.savedProxies = JSON.stringify(data)
        appSettings.savedTargetUrl = proxyTest.targetUrl
        appSettings.savedAvoidCache = proxyTest.avoidCache
        appSettings.savedTimeoutMs = proxyTest.timeoutMs
    }

    function loadModel() {
        proxyTest.setTargetUrl(appSettings.savedTargetUrl)
        proxyTest.setAvoidCache(appSettings.savedAvoidCache)
        proxyTest.setTimeoutMs(appSettings.savedTimeoutMs)

        if (appSettings.savedProxies !== "") {
            try {
                let data = JSON.parse(appSettings.savedProxies)
                for (let i = 0; i < data.length; i++) {
                    globalProxyModel.append({
                        host: data[i].host,
                        port: data[i].port,
                        status: "unknown", // Принудительно сбрасываем в серый
                        response: ""
                    })
                }
            } catch (e) {
                generateDefaults()
            }
        } else {
            generateDefaults()
        }
    }

    function generateDefaults() {
        for (let i = 1; i <= 20; i++) {
            globalProxyModel.append({
                host: "192.168.1." + i,
                port: 3128,
                status: "unknown",
                response: ""
            })
        }
        saveModel()
    }

    Component.onCompleted: {
        loadModel()
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: splashComponent
    }

    Component {
        id: splashComponent
        ProxySplash {
            onTimeout: stackView.replace(mainComponent)
        }
    }

    Component {
        id: mainComponent
        ProxyMain {
            proxyModel: globalProxyModel
            onSettingsClicked: stackView.push(settingsComponent)
        }
    }

    Component {
        id: settingsComponent
        SettingsPage {
            proxyModel: globalProxyModel
            onBackClicked: {
                window.saveModel()
                stackView.pop()
            }
        }
    }
}