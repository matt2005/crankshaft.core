/*
 * Project: Crankshaft
 * This file is part of Crankshaft project.
 * Copyright (C) 2025 OpenCarDev Team
 *
 *  Crankshaft is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Crankshaft is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Crankshaft. If not, see <http://www.gnu.org/licenses/>.
 */

#include "SettingsMigration.h"

#include <algorithm>
#include <QVariant>

#include "../../core/services/preferences/PreferencesService.h"
#include "Logger.h"

namespace {
// Setting key constants
const char* KEY_DISPLAY_BRIGHTNESS = "slim_ui.display.brightness";
const char* KEY_AUDIO_VOLUME = "slim_ui.audio.volume";
const char* KEY_CONNECTION_PREFERENCE = "slim_ui.connection.preference";
const char* KEY_THEME_MODE = "slim_ui.theme.mode";
const char* KEY_LAST_CONNECTED_DEVICE_ID = "slim_ui.device.lastConnected";

// Validation constants
const int MIN_PERCENTAGE = 0;
const int MAX_PERCENTAGE = 100;
const QStringList VALID_CONNECTION_PREFERENCES = {"USB", "WIRELESS"};
const QStringList VALID_THEME_MODES = {"LIGHT", "DARK"};
}  // namespace

SettingsMigration::SettingsMigration(PreferencesService* preferencesService)
    : m_preferencesService(preferencesService) {}

auto SettingsMigration::detectSchemaVersion() const -> int {
    if (!m_preferencesService) {
        Logger::instance().errorContext(QStringLiteral("SettingsMigration"),
                                        QStringLiteral("PreferencesService is null"));
        return 0;
    }

    if (!m_preferencesService->contains(SCHEMA_VERSION_KEY)) {
        Logger::instance().infoContext(
            QStringLiteral("SettingsMigration"),
            QStringLiteral("No schema version found, assuming version 0"));
        return 0;
    }

    bool ok = false;
    int version = m_preferencesService->get(SCHEMA_VERSION_KEY).toInt(&ok);

    if (!ok) {
        Logger::instance().warningContext(
            QStringLiteral("SettingsMigration"),
            QStringLiteral("Invalid schema version format, treating as version 0"));
        return 0;
    }

    Logger::instance().infoContext(QStringLiteral("SettingsMigration"),
                                   QStringLiteral("Detected schema version: %1").arg(version));
    return version;
}

auto SettingsMigration::needsMigration() const -> bool {
    int currentVersion = detectSchemaVersion();
    return currentVersion < CURRENT_SCHEMA_VERSION;
}

auto SettingsMigration::migrate(int fromVersion) -> bool {
    if (!m_preferencesService) {
        Logger::instance().errorContext(
            QStringLiteral("SettingsMigration"),
            QStringLiteral("Cannot migrate: PreferencesService is null"));
        return false;
    }

    Logger::instance().infoContext(QStringLiteral("SettingsMigration"),
                                   QStringLiteral("Starting migration from version %1 to %2")
                                       .arg(fromVersion)
                                       .arg(CURRENT_SCHEMA_VERSION));

    // Migration path from old to current version
    if (fromVersion == 0) {
        if (!migrateV0ToV1()) {
            Logger::instance().errorContext(QStringLiteral("SettingsMigration"),
                                            QStringLiteral("Migration from v0 to v1 failed"));
            return false;
        }
        // Update local variable for next iteration
        // Note: this only affects the local copy; the preference is updated below
    }

    // Future migrations would go here:
    // if (fromVersion == 1) {
    //     if (!migrateV1ToV2()) {
    //         return false;
    //     }
    //     fromVersion = 2;
    // }

    // Update schema version
    if (!m_preferencesService->set(SCHEMA_VERSION_KEY, CURRENT_SCHEMA_VERSION)) {
        Logger::instance().warningContext(QStringLiteral("SettingsMigration"),
                                          QStringLiteral("Failed to set schema version"));
    }

    Logger::instance().infoContext(QStringLiteral("SettingsMigration"),
                                   QStringLiteral("Migration completed successfully to version %1")
                                       .arg(CURRENT_SCHEMA_VERSION));

    return true;
}

auto SettingsMigration::detectCorruption() const -> bool {
    if (!m_preferencesService) {
        return true;  // Null service is corruption
    }

    // Check if all required keys exist
    const auto requiredKeys = getRequiredSettingKeys();
    bool anyMissing = std::any_of(requiredKeys.begin(), requiredKeys.end(),
                                  [this](const QString& key) {
                                    return !m_preferencesService->contains(key);
                                  });
    if (anyMissing) {
      for (const auto& key : requiredKeys) {
        if (!m_preferencesService->contains(key)) {
          Logger::instance().warningContext(
              QStringLiteral("SettingsMigration"),
              QStringLiteral("Missing required setting: %1").arg(key));
        }
      }
      return true;
    }

    return false;
}

auto SettingsMigration::recoverToDefaults() -> bool {
    if (!m_preferencesService) {
        Logger::instance().errorContext(
            QStringLiteral("SettingsMigration"),
            QStringLiteral("Cannot recover: PreferencesService is null"));
        return false;
    }

    Logger::instance().warningContext(QStringLiteral("SettingsMigration"),
                                      QStringLiteral("Recovering settings to factory defaults"));

    // Set all factory defaults
    bool success = true;
    success &= m_preferencesService->set(KEY_DISPLAY_BRIGHTNESS, FactoryDefaults::BRIGHTNESS);
    success &= m_preferencesService->set(KEY_AUDIO_VOLUME, FactoryDefaults::VOLUME);
    success &= m_preferencesService->set(KEY_CONNECTION_PREFERENCE,
                                         FactoryDefaults::CONNECTION_PREFERENCE);
    success &= m_preferencesService->set(KEY_THEME_MODE, FactoryDefaults::THEME_MODE);
    success &= m_preferencesService->set(KEY_LAST_CONNECTED_DEVICE_ID, QString());
    success &= m_preferencesService->set(SCHEMA_VERSION_KEY, CURRENT_SCHEMA_VERSION);

    if (!success) {
        Logger::instance().warningContext(
            QStringLiteral("SettingsMigration"),
            QStringLiteral("Some settings failed to persist during recovery"));
    }

    Logger::instance().infoContext(QStringLiteral("SettingsMigration"),
                                   QStringLiteral("Settings recovered to factory defaults"));

    return true;
}

auto SettingsMigration::initializeDefaults() -> bool {
    if (!m_preferencesService) {
        Logger::instance().errorContext(
            QStringLiteral("SettingsMigration"),
            QStringLiteral("Cannot initialize: PreferencesService is null"));
        return false;
    }

    bool initialized = false;

    // Initialize missing settings with defaults
    if (!m_preferencesService->contains(KEY_DISPLAY_BRIGHTNESS)) {
        if (m_preferencesService->set(KEY_DISPLAY_BRIGHTNESS, FactoryDefaults::BRIGHTNESS)) {
            initialized = true;
        }
    }

    if (!m_preferencesService->contains(KEY_AUDIO_VOLUME)) {
        if (m_preferencesService->set(KEY_AUDIO_VOLUME, FactoryDefaults::VOLUME)) {
            initialized = true;
        }
    }

    if (!m_preferencesService->contains(KEY_CONNECTION_PREFERENCE)) {
        if (m_preferencesService->set(KEY_CONNECTION_PREFERENCE,
                                      FactoryDefaults::CONNECTION_PREFERENCE)) {
            initialized = true;
        }
    }

    if (!m_preferencesService->contains(KEY_THEME_MODE)) {
        if (m_preferencesService->set(KEY_THEME_MODE, FactoryDefaults::THEME_MODE)) {
            initialized = true;
        }
    }

    if (!m_preferencesService->contains(KEY_LAST_CONNECTED_DEVICE_ID)) {
        if (m_preferencesService->set(KEY_LAST_CONNECTED_DEVICE_ID, QString())) {
            initialized = true;
        }
    }

    if (!m_preferencesService->contains(SCHEMA_VERSION_KEY)) {
        if (m_preferencesService->set(SCHEMA_VERSION_KEY, CURRENT_SCHEMA_VERSION)) {
            initialized = true;
        }
    }

    if (initialized) {
        Logger::instance().infoContext(
            QStringLiteral("SettingsMigration"),
            QStringLiteral("Initialized missing settings with factory defaults"));
    }

    return true;
}

auto SettingsMigration::validateSetting(const QString& key, const QVariant& value) const -> bool {
    if (key == KEY_DISPLAY_BRIGHTNESS || key == KEY_AUDIO_VOLUME) {
        return validatePercentage(value);
    }

    if (key == KEY_CONNECTION_PREFERENCE) {
        return validateEnum(value, VALID_CONNECTION_PREFERENCES);
    }

    if (key == KEY_THEME_MODE) {
        return validateEnum(value, VALID_THEME_MODES);
    }

    if (key == KEY_LAST_CONNECTED_DEVICE_ID) {
        // Device ID can be any string, including empty
        return true;
    }

    if (key == SCHEMA_VERSION_KEY) {
        bool ok = false;
        int version = value.toInt(&ok);
        return ok && version >= 0;
    }

    // Unknown key
    Logger::instance().warningContext(QStringLiteral("SettingsMigration"),
                                      QStringLiteral("Unknown setting key: %1").arg(key));
    return true;  // Don't fail on unknown keys for forward compatibility
}

QStringList SettingsMigration::getRequiredSettingKeys() {
    return QStringList{KEY_DISPLAY_BRIGHTNESS, KEY_AUDIO_VOLUME, KEY_CONNECTION_PREFERENCE,
                       KEY_THEME_MODE, KEY_LAST_CONNECTED_DEVICE_ID};
}

auto SettingsMigration::migrateV0ToV1() -> bool {
    // Version 0 to Version 1 migration
    // In v0, settings may not have been structured or may be missing
    // In v1, we ensure all required settings exist with valid values

    Logger::instance().infoContext(QStringLiteral("SettingsMigration"),
                                   QStringLiteral("Migrating from v0 (unversioned) to v1"));

    // Check if corruption exists, if so, recover to defaults
    if (detectCorruption()) {
        Logger::instance().warningContext(
            QStringLiteral("SettingsMigration"),
            QStringLiteral("Corruption detected during v0->v1 migration, recovering to defaults"));
        return recoverToDefaults();
    }

    // Initialize any missing settings
    return initializeDefaults();
}

auto SettingsMigration::validatePercentage(const QVariant& value) const -> bool {
    bool ok = false;
    int intValue = value.toInt(&ok);
    return ok && intValue >= MIN_PERCENTAGE && intValue <= MAX_PERCENTAGE;
}

auto SettingsMigration::validateEnum(const QVariant& value, const QStringList& allowedValues) const
    -> bool {
    QString strValue = value.toString();
    return allowedValues.contains(strValue);
}