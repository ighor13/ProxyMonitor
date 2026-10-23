#ifndef PROXYTEST_H
#define PROXYTEST_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkProxy>
#include <QNetworkReply>
#include <QTimer>
#include <QList>
#include <QHostInfo>

struct ProxyConfig {
    QString host;
    int port = 3128;
};

class ProxyTest : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString targetUrl READ targetUrl WRITE setTargetUrl NOTIFY targetUrlChanged)
    Q_PROPERTY(bool avoidCache READ avoidCache WRITE setAvoidCache NOTIFY avoidCacheChanged)
    Q_PROPERTY(int timeoutMs READ timeoutMs WRITE setTimeoutMs NOTIFY timeoutMsChanged)

public:
    explicit ProxyTest(QObject *parent = nullptr);

    QString targetUrl() const { return m_targetUrl; }
    Q_INVOKABLE void setTargetUrl(const QString &url);

    bool avoidCache() const { return m_avoidCache; }
    Q_INVOKABLE void setAvoidCache(bool avoid);

    int timeoutMs() const { return m_timeoutMs; }
    Q_INVOKABLE void setTimeoutMs(int ms);

    Q_INVOKABLE void testAll(const QVariantList &proxies);
    Q_INVOKABLE void cancelAll();

    Q_INVOKABLE bool saveToFile(const QString &filePath, const QString &data);
    Q_INVOKABLE QString loadFromFile(const QString &filePath);

signals:
    void proxyResult(int index, bool alive, const QString &info, const QString &errorMsg = QString(), const QString &status = QString());
    void targetUrlChanged();
    void avoidCacheChanged();
    void timeoutMsChanged();

private:
    void testSingleProxy(int index, const ProxyConfig &config);
    void doHttpTest(int index, const ProxyConfig &config, int gen);

    QNetworkAccessManager *m_manager;
    QString m_targetUrl = "http://example.com";
    bool m_avoidCache = true;
    int m_timeoutMs = 15000;
    QList<ProxyConfig> m_proxyList;

    int m_generation = 0;
};

#endif // PROXYTEST_H