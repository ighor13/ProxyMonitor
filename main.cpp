#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle> // Подключаем для смены стиля
#include "proxytest.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    app.setOrganizationName("ProxyMonitor");
    app.setApplicationName("ProxyMonitor");

    // Принудительно используем Basic стиль, чтобы кастомизация кнопок работала
    QQuickStyle::setStyle("Basic");

    ProxyTest proxyTest;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("proxyTest", &proxyTest);

    const QUrl url(QStringLiteral("qrc:/qt/qml/ProxyMonitor/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl)
                             QCoreApplication::exit(-1);
                     }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}