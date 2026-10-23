#include "proxytest.h"
#include <QNetworkRequest>
#include <QSslConfiguration>
#include <QSslError>
#include <QDebug>
#include <QFile>
#include <QTextStream>
#include <QUrl>
#include <QDateTime>
#include <QUrlQuery>

ProxyTest::ProxyTest(QObject *parent)
    : QObject(parent)
    , m_manager(new QNetworkAccessManager(this))
{
}

void ProxyTest::setTargetUrl(const QString &url)
{
    if (m_targetUrl == url) return;
    m_targetUrl = url;
    emit targetUrlChanged();
}

void ProxyTest::setAvoidCache(bool avoid)
{
    if (m_avoidCache == avoid) return;
    m_avoidCache = avoid;
    emit avoidCacheChanged();
}

void ProxyTest::setTimeoutMs(int ms)
{
    if (m_timeoutMs == ms) return;
    m_timeoutMs = ms;
    emit timeoutMsChanged();
}

void ProxyTest::cancelAll()
{
    m_generation++;

    // Безопасная отмена: находим все дочерние таймеры и ответы, созданные нами
    QList<QTimer*> timers = findChildren<QTimer*>();
    for (QTimer *timer : timers) {
        timer->stop();
        timer->deleteLater();
    }

    QList<QNetworkReply*> replies = findChildren<QNetworkReply*>();
    for (QNetworkReply *reply : replies) {
        reply->abort();
        reply->deleteLater();
    }
}

void ProxyTest::testAll(const QVariantList &proxies)
{
    cancelAll();

    m_proxyList.clear();
    for (const auto &v : proxies) {
        QVariantMap map = v.toMap();
        m_proxyList.append({map["host"].toString(), map["port"].toInt()});
    }

    for (int i = 0; i < m_proxyList.size(); ++i) {
        testSingleProxy(i, m_proxyList[i]);
    }
}

void ProxyTest::testSingleProxy(int index, const ProxyConfig &config)
{
    int gen = m_generation;
    emit proxyResult(index, false, "", "Testing", "testing");

    QHostInfo::lookupHost(config.host, this, [this, index, config, gen](const QHostInfo &hostInfo) {
        if (gen != m_generation) return;

        if (hostInfo.error() != QHostInfo::NoError || hostInfo.addresses().isEmpty()) {
            emit proxyResult(index, false, "", "DNS fail", "dns_fail");
        } else {
            doHttpTest(index, config, gen);
        }
    });
}

void ProxyTest::doHttpTest(int index, const ProxyConfig &config, int gen)
{
    if (gen != m_generation) return;

    QNetworkProxy proxy;
    proxy.setType(QNetworkProxy::HttpProxy);
    proxy.setHostName(config.host);
    proxy.setPort(static_cast<quint16>(config.port));

    QNetworkAccessManager *manager = new QNetworkAccessManager(this);
    manager->setProxy(proxy);

    connect(manager, &QNetworkAccessManager::sslErrors,
            [](QNetworkReply *reply, const QList<QSslError> &errors) {
                Q_UNUSED(errors);
                reply->ignoreSslErrors();
            });

    QUrl url(m_targetUrl);
    if (m_avoidCache) {
        QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd-HH-mm-ss-zzz");
        QString separator = url.hasQuery() ? "&" : "?";

        QString urlString = url.toString();
        int hashIndex = urlString.indexOf('#');
        QString hash = "";
        if (hashIndex != -1) {
            hash = urlString.mid(hashIndex);
            urlString = urlString.left(hashIndex);
        }
        url = QUrl(urlString + separator + "_t=" + timestamp + hash);
    }

    QNetworkRequest request{url};
    request.setRawHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    request.setRawHeader("Pragma", "no-cache");
    request.setRawHeader("Expires", "0");
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);

    QNetworkReply *reply = manager->get(request);

    QTimer *timer = new QTimer(this);
    timer->setSingleShot(true);
    timer->setInterval(m_timeoutMs);

    connect(timer, &QTimer::timeout, this, [this, index, reply, timer, manager, gen]() {
        if (gen != m_generation) return;
        if (reply && reply->isRunning()) {
            reply->abort();
            emit proxyResult(index, false, "", "Timeout", "timeout");
        }

        timer->deleteLater();
        manager->deleteLater();
    });

    connect(reply, &QNetworkReply::finished, this, [this, index, reply, timer, manager, gen]() {
        if (gen != m_generation) {
            reply->deleteLater();
            manager->deleteLater();
            return;
        }

        if (timer->isActive()) {
            timer->stop();
        }
        timer->deleteLater();

        if (reply->error() == QNetworkReply::NoError) {
            QString responseText = QString::fromUtf8(reply->readAll()).trimmed();
            if (responseText.length() > 300) {
                responseText = responseText.left(300) + "...";
            }
            emit proxyResult(index, true, responseText, "", "alive");
        } else {
            if (reply->error() != QNetworkReply::OperationCanceledError) {
                emit proxyResult(index, false, "", reply->errorString(), "dead");
            }
        }

        reply->deleteLater();
        manager->deleteLater();
    });

    timer->start();
}

bool ProxyTest::saveToFile(const QString &filePath, const QString &data)
{
    QUrl url(filePath);
    QString localPath = url.isLocalFile() ? url.toLocalFile() : filePath;

    QFile file(localPath);
    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream out(&file);
        out.setEncoding(QStringConverter::Utf8);
        out << data;
        file.close();
        return true;
    }
    qDebug() << "Не удалось сохранить файл:" << localPath;
    return false;
}

QString ProxyTest::loadFromFile(const QString &filePath)
{
    QUrl url(filePath);
    QString localPath = url.isLocalFile() ? url.toLocalFile() : filePath;

    QFile file(localPath);
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&file);
        in.setEncoding(QStringConverter::Utf8);
        QString content = in.readAll();
        file.close();
        return content;
    }
    qDebug() << "Не удалось прочитать файл:" << localPath;
    return QString();
}