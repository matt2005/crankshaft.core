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

#pragma once

#include <QString>
#include <QVariantMap>

class PreferencesService;

/**
 * @brief Handles settings file format versioning and migration
 * 
 * This class manages settings schema versioning and provides migration
 * capabilities for future format changes. It detects corrupt or outdated
 * settings and can automatically recover to factory defaults.
 */
class SettingsMigration {
public:
    /**
     * @brief Schema version constants
     */
    static constexpr int CURRENT_SCHEMA_VERSION = 1;
    static constexpr const char* SCHEMA_VERSION_KEY = "slim_ui.schema.version";
    
    /**
     * @brief Factory default settings
     */
    struct FactoryDefaults {
        static constexpr int BRIGHTNESS = 50;
        static constexpr int VOLUME = 50;
        static constexpr const char* CONNECTION_PREFERENCE = "USB";
        static constexpr const char* THEME_MODE = "DARK";
    };
    
    /**
     * @brief Construct a new Settings Migration object
     * 
     * @param preferencesService Pointer to the preferences service
     */
    explicit SettingsMigration(PreferencesService* preferencesService);
    
    /**
     * @brief Detect and return the current schema version
     * 
     * @return int The detected schema version, or 0 if not found
     */
    int detectSchemaVersion() const;
    
    /**
     * @brief Check if settings need migration
     * 
     * @return true if migration is needed
     * @return false if settings are current
     */
    bool needsMigration() const;
    
    /**
     * @brief Perform migration from old version to current
     * 
     * @param fromVersion The version to migrate from
     * @return true if migration succeeded
     * @return false if migration failed
     */
    bool migrate(int fromVersion);
    
    /**
     * @brief Check if settings are corrupted
     * 
     * Validates all required settings exist and have valid values
     * 
     * @return true if corruption detected
     * @return false if settings are valid
     */
    bool detectCorruption() const;
    
    /**
     * @brief Recover settings by resetting to factory defaults
     * 
     * @return true if recovery succeeded
     * @return false if recovery failed
     */
    bool recoverToDefaults();
    
    /**
     * @brief Initialize settings with factory defaults if not present
     * 
     * @return true if initialization succeeded
     * @return false if initialization failed
     */
    bool initializeDefaults();
    
    /**
     * @brief Validate a specific setting value
     * 
     * @param key The setting key to validate
     * @param value The value to validate
     * @return true if valid
     * @return false if invalid
     */
    bool validateSetting(const QString& key, const QVariant& value) const;
    
    /**
     * @brief Get all setting keys that should exist
     * 
     * @return QStringList List of required setting keys
     */
    static QStringList getRequiredSettingKeys();

private:
    PreferencesService* m_preferencesService;
    
    /**
     * @brief Migrate from version 0 (unversioned) to version 1
     * 
     * @return true if migration succeeded
     * @return false if migration failed
     */
    bool migrateV0ToV1();
    
    /**
     * @brief Validate percentage value (0-100)
     * 
     * @param value The value to validate
     * @return true if valid
     * @return false if invalid
     */
    bool validatePercentage(const QVariant& value) const;
    
    /**
     * @brief Validate enum value against allowed values
     * 
     * @param value The value to validate
     * @param allowedValues List of allowed values
     * @return true if valid
     * @return false if invalid
     */
    bool validateEnum(const QVariant& value, const QStringList& allowedValues) const;
};
