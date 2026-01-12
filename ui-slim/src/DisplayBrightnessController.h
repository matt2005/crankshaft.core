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

/**
 * @brief Controls display brightness through multiple backends
 * 
 * This controller manages display brightness using the best available method:
 * 1. DBus interface (systemd-logind, UPower)
 * 2. Direct sysfs access (/sys/class/backlight)
 * 3. Qt platform integration (QPlatformScreen)
 * 4. Software brightness fallback (QScreen color adjustment)
 * 
 * The controller automatically detects available backends on startup and
 * uses the most capable one. Gracefully degrades if hardware control is
 * unavailable.
 */
class DisplayBrightnessController : public QObject {
    Q_OBJECT

public:
    /**
     * @brief Backend types for brightness control
     */
    enum class BackendType {
        NONE,           ///< No brightness control available
        DBUS,           ///< DBus-based control (systemd-logind, UPower)
        SYSFS,          ///< Direct sysfs access (/sys/class/backlight)
        QT_PLATFORM,    ///< Qt platform screen integration
        SOFTWARE        ///< Software brightness simulation
    };
    Q_ENUM(BackendType)

    /**
     * @brief Construct a new Display Brightness Controller
     * 
     * @param parent Parent QObject
     */
    explicit DisplayBrightnessController(QObject* parent = nullptr);
    
    /**
     * @brief Destructor
     */
    ~DisplayBrightnessController() override = default;

    /**
     * @brief Initialize the brightness controller
     * 
     * Detects available backends and reads current brightness level.
     * Must be called before using the controller.
     * 
     * @return true if initialization succeeded
     * @return false if initialization failed
     */
    bool initialize();

    /**
     * @brief Get the current brightness level
     * 
     * @return int Brightness percentage (0-100), or -1 if unavailable
     */
    int getCurrentBrightness() const;

    /**
     * @brief Set the brightness level
     * 
     * @param percentage Brightness percentage (0-100)
     * @return true if brightness was set successfully
     * @return false if operation failed
     */
    bool setBrightness(int percentage);

    /**
     * @brief Get the current backend type
     * 
     * @return BackendType The active backend
     */
    BackendType getBackendType() const;

    /**
     * @brief Check if brightness control is available
     * 
     * @return true if brightness can be controlled
     * @return false if no backend is available
     */
    bool isAvailable() const;

signals:
    /**
     * @brief Emitted when brightness changes
     * 
     * @param percentage New brightness percentage (0-100)
     */
    void brightnessChanged(int percentage);

    /**
     * @brief Emitted when backend detection completes
     * 
     * @param backend The detected backend type
     */
    void backendDetected(BackendType backend);

private:
    /**
     * @brief Detect and initialize the best available backend
     * 
     * @return BackendType The detected backend
     */
    BackendType detectBackend();

    /**
     * @brief Try to initialize DBus backend
     * 
     * @return true if DBus backend is available
     * @return false otherwise
     */
    bool tryDbusBackend();

    /**
     * @brief Try to initialize sysfs backend
     * 
     * @return true if sysfs backend is available
     * @return false otherwise
     */
    bool trySysfsBackend();

    /**
     * @brief Try to initialize Qt platform backend
     * 
     * @return true if Qt platform backend is available
     * @return false otherwise
     */
    bool tryQtPlatformBackend();

    /**
     * @brief Initialize software fallback
     * 
     * Always succeeds but provides limited functionality
     * 
     * @return true (always)
     */
    bool initializeSoftwareBackend();

    /**
     * @brief Read brightness from sysfs
     * 
     * @return int Brightness percentage (0-100), or -1 on error
     */
    int readBrightnessFromSysfs() const;

    /**
     * @brief Write brightness to sysfs
     * 
     * @param percentage Brightness percentage (0-100)
     * @return true if write succeeded
     * @return false if write failed
     */
    bool writeBrightnessToSysfs(int percentage);

    /**
     * @brief Apply software brightness adjustment
     * 
     * @param percentage Brightness percentage (0-100)
     * @return true (always succeeds)
     */
    bool applySoftwareBrightness(int percentage);

    /**
     * @brief Validate and clamp brightness percentage
     * 
     * @param percentage Input percentage
     * @return int Clamped percentage (0-100)
     */
    int validatePercentage(int percentage) const;

    BackendType m_backendType = BackendType::NONE;
    int m_currentBrightness = -1;
    QString m_sysfsPath;
    int m_maxBrightness = 100;
};
