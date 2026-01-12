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

#include "PreferencesFacade.h"
#include "ServiceProvider.h"
#include "Logger.h"

#include "../../core/services/preferences/PreferencesService.h"

namespace {
const char* KEY_DISPLAY_BRIGHTNESS = "slim_ui.display.brightness";
const char* KEY_AUDIO_VOLUME = "slim_ui.audio.volume";
const char* KEY_CONNECTION_PREFERENCE = "slim_ui.connection.preference";
const char* KEY_THEME_MODE = "slim_ui.theme.mode";
const char* KEY_LAST_CONNECTED_DEVICE_ID = "slim_ui.device.lastConnected";

const int DEFAULT_BRIGHTNESS = 50;
const int DEFAULT_VOLUME = 50;
const int MIN_PERCENTAGE = 0;
const int MAX_PERCENTAGE = 100;
}

PreferencesFacade::PreferencesFacade(ServiceProvider* serviceProvider, QObject* parent)
    : QObject(parent), m_serviceProvider(serviceProvider) {
    // Load settings on construction
    loadSettings();
}

auto PreferencesFacade::displayBrightness() const -> int {
    return m_displayBrightness;
}

auto PreferencesFacade::audioVolume() const -> int {
    return m_audioVolume;
}

auto PreferencesFacade::connectionPreference() const -> QString {
    return m_connectionPreference;
}

auto PreferencesFacade::themeMode() const -> QString {
    return m_themeMode;
}

auto PreferencesFacade::lastConnectedDeviceId() const -> QString {
    return m_lastConnectedDeviceId;
}

auto PreferencesFacade::setDisplayBrightness(int value) -> void {
    int validated = validatePercentage(value);
    if (validated == m_displayBrightness) {
        return;
    }

    m_displayBrightness = validated;
    saveSetting(KEY_DISPLAY_BRIGHTNESS, m_displayBrightness);
    Logger::instance().infoContext(QStringLiteral("PreferencesFacade"), 
                                    QStringLiteral("Display brightness changed to %1%").arg(m_displayBrightness));
    emit displayBrightnessChanged(m_displayBrightness);
}

auto PreferencesFacade::setAudioVolume(int value) -> void {
    int validated = validatePercentage(value);
    if (validated == m_audioVolume) {
        return;
    }

    m_audioVolume = validated;
    saveSetting(KEY_AUDIO_VOLUME, m_audioVolume);
    Logger::instance().infoContext(QStringLiteral("PreferencesFacade"), 
                                    QStringLiteral("Audio volume changed to %1%").arg(m_audioVolume));
    emit audioVolumeChanged(m_audioVolume);
}

auto PreferencesFacade::setConnectionPreference(const QString& mode) -> void {
    if (mode == m_connectionPreference) {
        return;
    }

    // Validate mode is USB or WIRELESS
    if (mode != QStringLiteral("USB") && mode != QStringLiteral("WIRELESS")) {
        Logger::instance().warningContext(QStringLiteral("PreferencesFacade"), 
                                          QStringLiteral("Invalid connection preference: %1").arg(mode));
        return;
    }

    m_connectionPreference = mode;
    saveSetting(KEY_CONNECTION_PREFERENCE, m_connectionPreference);
    Logger::instance().infoContext(QStringLiteral("PreferencesFacade"), 
                                    QStringLiteral("Connection preference changed to %1").arg(m_connectionPreference));
    emit connectionPreferenceChanged(m_connectionPreference);
}

auto PreferencesFacade::setThemeMode(const QString& mode) -> void {
    if (mode == m_themeMode) {
        return;
    }

    // Validate mode is LIGHT or DARK
    if (mode != QStringLiteral("LIGHT") && mode != QStringLiteral("DARK")) {
        Logger::instance().warningContext(QStringLiteral("PreferencesFacade"), 
                                          QStringLiteral("Invalid theme mode: %1").arg(mode));
        return;
    }

    m_themeMode = mode;
    saveSetting(KEY_THEME_MODE, m_themeMode);
    Logger::instance().infoContext(QStringLiteral("PreferencesFacade"), 
                                    QStringLiteral("Theme mode changed to %1").arg(m_themeMode));
    emit themeModeChanged(m_themeMode);
}

auto PreferencesFacade::setLastConnectedDeviceId(const QString& deviceId) -> void {
    if (deviceId == m_lastConnectedDeviceId) {
        return;
    }

    m_lastConnectedDeviceId = deviceId;
    saveSetting(KEY_LAST_CONNECTED_DEVICE_ID, m_lastConnectedDeviceId);
    Logger::instance().infoContext(QStringLiteral("PreferencesFacade"), QStringLiteral("Last connected device changed to %1").arg(m_lastConnectedDeviceId));
    emit lastConnectedDeviceIdChanged(m_lastConnectedDeviceId);
}

auto PreferencesFacade::loadSettings() -> void {
    if (!m_serviceProvider) {
        Logger::instance().errorContext(QStringLiteral("PreferencesFacade"), 
                                         QStringLiteral("ServiceProvider not available, using defaults"));
        return;
    }

    auto* prefsService = m_serviceProvider->preferencesService();
    if (!prefsService) {
        Logger::instance().errorContext(QStringLiteral("PreferencesFacade"), 
                                         QStringLiteral("PreferencesService not available, using defaults"));
        return;
    }

    // Load each setting with validation
    m_displayBrightness = validatePercentage(loadSetting(KEY_DISPLAY_BRIGHTNESS, DEFAULT_BRIGHTNESS).toInt());
    m_audioVolume = validatePercentage(loadSetting(KEY_AUDIO_VOLUME, DEFAULT_VOLUME).toInt());
    m_connectionPreference = loadSetting(KEY_CONNECTION_PREFERENCE, QStringLiteral("USB")).toString();
    m_themeMode = loadSetting(KEY_THEME_MODE, QStringLiteral("DARK")).toString();
    m_lastConnectedDeviceId = loadSetting(KEY_LAST_CONNECTED_DEVICE_ID, QString()).toString();

    // Detect and recover from any corruption
    QString recovered = detectAndRecoverCorruption();
    if (!recovered.isEmpty()) {
        Logger::instance().warningContext(QStringLiteral("PreferencesFacade"), QStringLiteral("Settings recovered from corruption: %1").arg(recovered));
        emit settingsRecovered(recovered);
        // Persist recovered settings
        saveSettings();
    }

    m_isInitialized = true;
    Logger::instance().infoContext(QStringLiteral("PreferencesFacade"), QStringLiteral("Settings loaded successfully"));
    emit settingsLoaded();
}

auto PreferencesFacade::saveSettings() -> void {
    if (!m_serviceProvider) {
        Logger::instance().errorContext(QStringLiteral("PreferencesFacade"), 
                                         QStringLiteral("ServiceProvider not available, cannot save"));
        return;
    }

    auto* prefsService = m_serviceProvider->preferencesService();
    if (!prefsService) {
        Logger::instance().errorContext(QStringLiteral("PreferencesFacade"), 
                                         QStringLiteral("PreferencesService not available, cannot save"));
        return;
    }

    // Save each setting
    saveSetting(KEY_DISPLAY_BRIGHTNESS, m_displayBrightness);
    saveSetting(KEY_AUDIO_VOLUME, m_audioVolume);
    saveSetting(KEY_CONNECTION_PREFERENCE, m_connectionPreference);
    saveSetting(KEY_THEME_MODE, m_themeMode);
    saveSetting(KEY_LAST_CONNECTED_DEVICE_ID, m_lastConnectedDeviceId);

    Logger::instance().infoContext(QStringLiteral("PreferencesFacade"), QStringLiteral("Settings saved successfully"));
    emit settingsSaved();
}

auto PreferencesFacade::resetToDefaults() -> void {
    Logger::instance().infoContext(QStringLiteral("PreferencesFacade"), QStringLiteral("Resetting settings to factory defaults"));

    m_displayBrightness = DEFAULT_BRIGHTNESS;
    m_audioVolume = DEFAULT_VOLUME;
    m_connectionPreference = QStringLiteral("USB");
    m_themeMode = QStringLiteral("DARK");
    m_lastConnectedDeviceId.clear();

    saveSettings();

    emit displayBrightnessChanged(m_displayBrightness);
    emit audioVolumeChanged(m_audioVolume);
    emit connectionPreferenceChanged(m_connectionPreference);
    emit themeModeChanged(m_themeMode);
    emit lastConnectedDeviceIdChanged(m_lastConnectedDeviceId);
}

auto PreferencesFacade::loadSetting(const QString& key, const QVariant& defaultValue) -> QVariant {
    if (!m_serviceProvider) {
        return defaultValue;
    }

    auto* prefsService = m_serviceProvider->preferencesService();
    if (!prefsService) {
        return defaultValue;
    }

    QVariant value = prefsService->get(key);
    return value.isValid() ? value : defaultValue;
}

auto PreferencesFacade::saveSetting(const QString& key, const QVariant& value) -> bool {
    if (!m_serviceProvider) {
        return false;
    }

    auto* prefsService = m_serviceProvider->preferencesService();
    if (!prefsService) {
        return false;
    }

    return prefsService->set(key, value);
}

auto PreferencesFacade::validatePercentage(int value) const -> int {
    if (value < MIN_PERCENTAGE) {
        return MIN_PERCENTAGE;
    }
    if (value > MAX_PERCENTAGE) {
        return MAX_PERCENTAGE;
    }
    return value;
}

auto PreferencesFacade::detectAndRecoverCorruption() -> QString {
    QStringList recoveredFields;

    // Validate each setting and reset if invalid
    if (m_displayBrightness < MIN_PERCENTAGE || m_displayBrightness > MAX_PERCENTAGE) {
        Logger::instance().warningContext(QStringLiteral("PreferencesFacade"), QStringLiteral("Corrupted brightness: %1, resetting to default").arg(m_displayBrightness));
        m_displayBrightness = DEFAULT_BRIGHTNESS;
        recoveredFields << QStringLiteral("brightness");
    }

    if (m_audioVolume < MIN_PERCENTAGE || m_audioVolume > MAX_PERCENTAGE) {
        Logger::instance().warningContext(QStringLiteral("PreferencesFacade"), QStringLiteral("Corrupted volume: %1, resetting to default").arg(m_audioVolume));
        m_audioVolume = DEFAULT_VOLUME;
        recoveredFields << QStringLiteral("volume");
    }

    if (m_connectionPreference != QStringLiteral("USB") && m_connectionPreference != QStringLiteral("WIRELESS")) {
        Logger::instance().warningContext(QStringLiteral("PreferencesFacade"), QStringLiteral("Corrupted connection preference: %1, resetting to default").arg(m_connectionPreference));
        m_connectionPreference = QStringLiteral("USB");
        recoveredFields << QStringLiteral("connectionPreference");
    }

    if (m_themeMode != QStringLiteral("LIGHT") && m_themeMode != QStringLiteral("DARK")) {
        Logger::instance().warningContext(QStringLiteral("PreferencesFacade"), QStringLiteral("Corrupted theme mode: %1, resetting to default").arg(m_themeMode));
        m_themeMode = QStringLiteral("DARK");
        recoveredFields << QStringLiteral("themeMode");
    }

    return recoveredFields.join(QStringLiteral(","));
}
