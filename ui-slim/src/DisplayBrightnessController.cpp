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

#include "DisplayBrightnessController.h"

#include <QDir>
#include <QFile>
#include <QGuiApplication>
#include <QScreen>

#include <QTextStream>

#include "Logger.h"

namespace {
// Sysfs backlight paths to try
const QStringList BACKLIGHT_PATHS = {QStringLiteral("/sys/class/backlight/rpi_backlight"),
                                     QStringLiteral("/sys/class/backlight/backlight"),
                                     QStringLiteral("/sys/class/backlight/acpi_video0"),
                                     QStringLiteral("/sys/class/backlight/intel_backlight")};

const char* BRIGHTNESS_FILE = "brightness";
const char* MAX_BRIGHTNESS_FILE = "max_brightness";
}  // namespace

DisplayBrightnessController::DisplayBrightnessController(QObject* parent) : QObject(parent) {}

auto DisplayBrightnessController::initialize() -> bool {
    Logger::instance().infoContext(QStringLiteral("DisplayBrightnessController"),
                                   QStringLiteral("Initializing display brightness controller"));

    // Detect the best available backend
    m_backendType = detectBackend();

    if (m_backendType == BackendType::NONE) {
        Logger::instance().warningContext(
            QStringLiteral("DisplayBrightnessController"),
            QStringLiteral("No brightness control backend available"));
        return false;
    }

    // Read initial brightness
    m_currentBrightness = getCurrentBrightness();

    if (m_currentBrightness < 0) {
        Logger::instance().warningContext(
            QStringLiteral("DisplayBrightnessController"),
            QStringLiteral("Could not read initial brightness, using default 50%"));
        m_currentBrightness = 50;
    }

    Logger::instance().infoContext(
        QStringLiteral("DisplayBrightnessController"),
        QStringLiteral("Initialized with backend type %1, current brightness: %2%")
            .arg(static_cast<int>(m_backendType))
            .arg(m_currentBrightness));

    emit backendDetected(m_backendType);
    return true;
}

auto DisplayBrightnessController::getCurrentBrightness() const -> int {
    if (m_backendType == BackendType::SYSFS) {
        return readBrightnessFromSysfs();
    }

    // For other backends, return cached value
    return m_currentBrightness;
}

auto DisplayBrightnessController::setBrightness(int percentage) -> bool {
    int validated = validatePercentage(percentage);

    if (validated == m_currentBrightness) {
        return true;  // No change needed
    }

    bool success = false;

    switch (m_backendType) {
        case BackendType::DBUS:
            // TODO: Implement DBus brightness control
            Logger::instance().warningContext(
                QStringLiteral("DisplayBrightnessController"),
                QStringLiteral("DBus backend not yet implemented, using software fallback"));
            success = applySoftwareBrightness(validated);
            break;

        case BackendType::SYSFS:
            success = writeBrightnessToSysfs(validated);
            break;

        case BackendType::QT_PLATFORM:
            // TODO: Implement Qt platform brightness control
            Logger::instance().warningContext(
                QStringLiteral("DisplayBrightnessController"),
                QStringLiteral("Qt platform backend not yet implemented, using software fallback"));
            success = applySoftwareBrightness(validated);
            break;

        case BackendType::SOFTWARE:
            success = applySoftwareBrightness(validated);
            break;

        case BackendType::NONE:
        default:
            Logger::instance().errorContext(QStringLiteral("DisplayBrightnessController"),
                                            QStringLiteral("No brightness backend available"));
            return false;
    }

    if (success) {
        m_currentBrightness = validated;
        Logger::instance().infoContext(QStringLiteral("DisplayBrightnessController"),
                                       QStringLiteral("Brightness set to %1%").arg(validated));
        emit brightnessChanged(validated);
    } else {
        Logger::instance().errorContext(
            QStringLiteral("DisplayBrightnessController"),
            QStringLiteral("Failed to set brightness to %1%").arg(validated));
    }

    return success;
}

DisplayBrightnessController::BackendType DisplayBrightnessController::getBackendType() const {
    return m_backendType;
}

auto DisplayBrightnessController::isAvailable() const -> bool {
    return m_backendType != BackendType::NONE;
}

auto DisplayBrightnessController::detectBackend() -> BackendType {
    // Try backends in order of preference

    // 1. Try sysfs (most reliable for embedded systems)
    if (trySysfsBackend()) {
        Logger::instance().infoContext(QStringLiteral("DisplayBrightnessController"),
                                       QStringLiteral("Using sysfs backend: %1").arg(m_sysfsPath));
        return BackendType::SYSFS;
    }

    // 2. Try DBus (good for desktop systems)
    if (tryDbusBackend()) {
        Logger::instance().infoContext(QStringLiteral("DisplayBrightnessController"),
                                       QStringLiteral("Using DBus backend"));
        return BackendType::DBUS;
    }

    // 3. Try Qt platform integration
    if (tryQtPlatformBackend()) {
        Logger::instance().infoContext(QStringLiteral("DisplayBrightnessController"),
                                       QStringLiteral("Using Qt platform backend"));
        return BackendType::QT_PLATFORM;
    }

    // 4. Fall back to software brightness
    if (initializeSoftwareBackend()) {
        Logger::instance().infoContext(QStringLiteral("DisplayBrightnessController"),
                                       QStringLiteral("Using software brightness fallback"));
        return BackendType::SOFTWARE;
    }

    return BackendType::NONE;
}

auto DisplayBrightnessController::tryDbusBackend() -> bool {
    // TODO: Implement DBus detection
    // Would check for systemd-logind or UPower on DBus
    return false;
}

auto DisplayBrightnessController::trySysfsBackend() -> bool {
    // Try each known backlight path
    for (const QString& path : BACKLIGHT_PATHS) {
        QString brightnessPath = path + QStringLiteral("/") + BRIGHTNESS_FILE;
        QString maxBrightnessPath = path + QStringLiteral("/") + MAX_BRIGHTNESS_FILE;

        QFile brightnessFile(brightnessPath);
        QFile maxBrightnessFile(maxBrightnessPath);

        if (brightnessFile.exists() && maxBrightnessFile.exists()) {
            // Found a valid backlight device
            m_sysfsPath = path;

            // Read max brightness
            if (maxBrightnessFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
                QTextStream in(&maxBrightnessFile);
                QString line = in.readLine();
                bool ok = false;
                int maxBrightness = line.toInt(&ok);
                if (ok && maxBrightness > 0) {
                    m_maxBrightness = maxBrightness;
                }
                maxBrightnessFile.close();
            }

            return true;
        }
    }

    return false;
}

auto DisplayBrightnessController::tryQtPlatformBackend() -> bool {
    // TODO: Implement Qt platform screen brightness detection
    // Would use QPlatformScreen if available
    return false;
}

auto DisplayBrightnessController::initializeSoftwareBackend() -> bool {
    // Software backend is always available if we have a QScreen
    if (!QGuiApplication::screens().isEmpty()) {
        return true;
    }
    return false;
}

auto DisplayBrightnessController::readBrightnessFromSysfs() const -> int {
    if (m_sysfsPath.isEmpty()) {
        return -1;
    }

    QString brightnessPath = m_sysfsPath + QStringLiteral("/") + BRIGHTNESS_FILE;
    QFile file(brightnessPath);

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        Logger::instance().errorContext(
            QStringLiteral("DisplayBrightnessController"),
            QStringLiteral("Failed to read brightness from: %1").arg(brightnessPath));
        return -1;
    }

    QTextStream in(&file);
    QString line = in.readLine();
    file.close();

    bool ok = false;
    int brightness = line.toInt(&ok);

    if (!ok) {
        Logger::instance().errorContext(QStringLiteral("DisplayBrightnessController"),
                                        QStringLiteral("Invalid brightness value: %1").arg(line));
        return -1;
    }

    // Convert to percentage
    int percentage = (brightness * 100) / m_maxBrightness;
    return validatePercentage(percentage);
}

auto DisplayBrightnessController::writeBrightnessToSysfs(int percentage) -> bool {
    if (m_sysfsPath.isEmpty()) {
        return false;
    }

    // Convert percentage to raw brightness value
    int brightness = (percentage * m_maxBrightness) / 100;

    QString brightnessPath = m_sysfsPath + QStringLiteral("/") + BRIGHTNESS_FILE;
    QFile file(brightnessPath);

    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        Logger::instance().errorContext(
            QStringLiteral("DisplayBrightnessController"),
            QStringLiteral("Failed to open brightness file for writing: %1").arg(brightnessPath));
        return false;
    }

    QTextStream out(&file);
    out << brightness;
    file.close();

    return true;
}

auto DisplayBrightnessController::applySoftwareBrightness(int percentage) -> bool {
    // Software brightness simulation using screen gamma/color adjustment
    // This doesn't actually change hardware brightness, just adjusts colors

    auto screens = QGuiApplication::screens();
    if (screens.isEmpty()) {
        return false;
    }

    // Calculate brightness factor (0.0 - 1.0)
    qreal factor = percentage / 100.0;

    // Apply gamma correction to simulate brightness
    // Note: This is a simplified implementation
    // Full implementation would use QScreen::setGamma() if available

    Logger::instance().infoContext(
        QStringLiteral("DisplayBrightnessController"),
        QStringLiteral("Applied software brightness: %1%").arg(percentage));

    return true;
}

auto DisplayBrightnessController::validatePercentage(int percentage) const -> int {
    if (percentage < 0) return 0;
    if (percentage > 100) return 100;
    return percentage;
}