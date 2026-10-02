// SPDX-License-Identifier: MIT
// The "couchbox" page in Bigscreen Settings: couchbox's own adjustable options,
// stored in ~/.config/couchboxrc for the couchbox apps to read.
//
// Generic on purpose: the page (main.qml, built in as ui/main.qml) names each setting's group, key
// and default, so adding a setting needs no C++. The video settings also call
// couchbox-video-profile, which carries them into Plezy and Kodi.

#include <QProcess>

#include <KConfigGroup>
#include <KPluginFactory>
#include <KQuickConfigModule>
#include <KSharedConfig>

class CouchboxSettings : public KQuickConfigModule
{
    Q_OBJECT

public:
    explicit CouchboxSettings(QObject *parent, const KPluginMetaData &data)
        : KQuickConfigModule(parent, data)
        , m_config(KSharedConfig::openConfig(QStringLiteral("couchboxrc")))
    {
    }

    Q_INVOKABLE QString value(const QString &group, const QString &key, const QString &fallback) const
    {
        return m_config->group(group).readEntry(key, fallback);
    }

    // Written and synced right away: Bigscreen Settings has no Apply button.
    Q_INVOKABLE void setValue(const QString &group, const QString &key, const QString &value)
    {
        KConfigGroup cg = m_config->group(group);
        cg.writeEntry(key, value);
        cg.sync();
    }

    // couchbox-video-profile (couchbox-base) writes the [Video] settings into
    // Plezy and Kodi. apply returns at once: a running client gets them when it
    // exits. probe re-detects the hardware and resets [Video] to its
    // recommendations; it takes a moment (vainfo), and the page reloads after.
    Q_INVOKABLE void applyVideo() const
    {
        QProcess::startDetached(QStringLiteral("couchbox-video-profile"), {QStringLiteral("apply")});
    }

    Q_INVOKABLE void probeVideo()
    {
        QProcess::execute(QStringLiteral("couchbox-video-profile"), {QStringLiteral("probe")});
        m_config->reparseConfiguration();
    }

private:
    KSharedConfig::Ptr m_config;
};

K_PLUGIN_CLASS_WITH_JSON(CouchboxSettings, "kcm_mediacenter_couchbox.json")

#include "couchbox.moc"
