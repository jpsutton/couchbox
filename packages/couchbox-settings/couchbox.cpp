// SPDX-License-Identifier: MIT
// The "couchbox" page in Bigscreen Settings: couchbox's own adjustable options,
// stored in ~/.config/couchboxrc for the couchbox apps to read.
//
// Generic on purpose: the page (main.qml, built in as ui/main.qml) names each setting's group, key
// and default, so adding a setting needs no C++.

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

private:
    KSharedConfig::Ptr m_config;
};

K_PLUGIN_CLASS_WITH_JSON(CouchboxSettings, "kcm_mediacenter_couchbox.json")

#include "couchbox.moc"
