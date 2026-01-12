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

#include <QObject>
#include <QString>
#include <QVariant>

// Forward declaration
class ServiceProvider;

/**
 * @brief QML bridge to core PreferencesService for settings management.
 *
 * Provides unified access to display, audio, and connection settings with:
 * - Range validation (brightness/volume 0-100)
 * - Corruption detection and recovery
 * - Signal emission on changes
 * - Persistent storage via core PreferencesService
 *
 * All settings use slim_ui.* key prefix for isolation from core settings.
 * Factory defaults: brightness 50%, volume 50%, USB connection, dark theme.
 */
class PreferencesFacade : public QObject {
    Q_OBJECT

    // Display settings
    Q_PROPERTY(int displayBrightness READ displayBrightness WRITE setDisplayBrightness NOTIFY displayBrightnessChanged)
    Q_PROPERTY(QString themeMode READ themeMode WRITE setThemeMode NOTIFY themeModeChanged)

    // Audio settings
    Q_PROPERTY(int audioVolume READ audioVolume WRITE setAudioVolume NOTIFY audioVolumeChanged)

    // Connection settings
    Q_PROPERTY(QString connectionPreference READ connectionPreference WRITE setConnectionPreference NOTIFY connectionPreferenceChanged)
    Q_PROPERTY(QString lastConnectedDeviceId READ lastConnectedDeviceId WRITE setLastConnectedDeviceId NOTIFY lastConnectedDeviceIdChanged)

  public:
    /**
     * @brief Connection preference mode.
     * @note Enum values must match core AndroidAutoService enums.
     */
    enum ConnectionMode {
        USB = 0,       ///< USB connection (default)
        Wireless = 1   ///< Wireless connection
    };
    Q_ENUM(ConnectionMode)

    /**
     * @brief Theme mode enumeration.
     */
    enum ThemeMode {
        Light = 0,  ///< Light theme
        Dark = 1    ///< Dark theme (default)
    };
    Q_ENUM(ThemeMode)

    explicit PreferencesFacade(ServiceProvider* serviceProvider, QObject* parent = nullptr);
    ~PreferencesFacade() = default;

    // Property getters
    int displayBrightness() const;
    int audioVolume() const;
    QString connectionPreference() const;
    QString themeMode() const;
    QString lastConnectedDeviceId() const;

    // Property setters
    void setDisplayBrightness(int value);
    void setAudioVolume(int value);
    void setConnectionPreference(const QString& mode);
    void setThemeMode(const QString& mode);
    void setLastConnectedDeviceId(const QString& deviceId);

    // Settings management
    Q_INVOKABLE void loadSettings();
    Q_INVOKABLE void saveSettings();
    Q_INVOKABLE void resetToDefaults();

  signals:
    void displayBrightnessChanged(int value);
    void audioVolumeChanged(int value);
    void connectionPreferenceChanged(const QString& mode);
    void themeModeChanged(const QString& mode);
    void lastConnectedDeviceIdChanged(const QString& deviceId);
    void settingsLoaded();
    void settingsSaved();
    void settingsRecovered(const QString& recoveredFields); ///< Emitted when corrupted settings are reset.

  private:
    /**
     * @brief Load setting with validation and default fallback.
     * @param key Setting key (without slim_ui prefix).
     * @param defaultValue Default value if key not found.
     * @return Setting value or default if not found.
     */
    QVariant loadSetting(const QString& key, const QVariant& defaultValue);

    /**
     * @brief Save setting with validation.
     * @param key Setting key (without slim_ui prefix).
     * @param value Value to save (will be validated).
     * @return True if saved successfully, false if validation failed.
     */
    bool saveSetting(const QString& key, const QVariant& value);

    /**
     * @brief Validate integer value is within range [0, 100].
     * @param value Value to validate.
     * @return Clamped value in [0, 100].
     */
    int validatePercentage(int value) const;

    /**
     * @brief Detect and recover from corrupted settings.
     * @return Comma-separated list of corrupted fields recovered.
     */
    QString detectAndRecoverCorruption();

    // Member variables
    ServiceProvider* m_serviceProvider = nullptr;
    int m_displayBrightness = 50;        ///< Default 50%
    int m_audioVolume = 50;              ///< Default 50%
    QString m_connectionPreference = QStringLiteral("USB");  ///< Default USB
    QString m_themeMode = QStringLiteral("DARK");            ///< Default dark
    QString m_lastConnectedDeviceId;
    bool m_isInitialized = false;
};
