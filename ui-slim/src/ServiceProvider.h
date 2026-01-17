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
#include <memory>

// Forward declarations of core services
class AndroidAutoService;
class PreferencesService;
class EventBus;
class AudioRouter;
class Logger;
class ServiceManager;
class MediaPipeline;
class ProfileManager;

/**
 * @brief Singleton provider for Crankshaft core services
 *
 * Manages lifecycle and access to core services used by the slim UI.
 * Initializes services in correct dependency order and provides
 * centralized access point for facade classes.
 */
class ServiceProvider : public QObject {
    Q_OBJECT

public:
    /**
     * @brief Get singleton instance
     */
    static auto instance() -> ServiceProvider&;

    /**
     * @brief Initialize all core services
     * @return true if initialization successful, false on error
     */
    [[nodiscard]] auto initialize() -> bool;

    /**
     * @brief Shutdown all core services
     */
    auto shutdown() -> void;

    /**
     * @brief Check if services are initialized
     */
    [[nodiscard]] auto isInitialized() const -> bool { return m_initialized; }

    // Service accessors
    [[nodiscard]] auto androidAutoService() const -> AndroidAutoService* {
        return m_androidAutoService.get();
    }
    [[nodiscard]] auto preferencesService() const -> PreferencesService* {
        return m_preferencesService.get();
    }
    [[nodiscard]] auto eventBus() const -> EventBus*;  // Returns singleton
    [[nodiscard]] auto audioRouter() const -> AudioRouter* { return m_audioRouter.get(); }
    [[nodiscard]] auto logger() const -> Logger*;  // Returns singleton
    [[nodiscard]] auto serviceManager() const -> ServiceManager* { return m_serviceManager.get(); }
    [[nodiscard]] auto mediaPipeline() const -> MediaPipeline* { return m_mediaPipeline.get(); }
    [[nodiscard]] auto profileManager() const -> ProfileManager* { return m_profileManager.get(); }

signals:
    void initializationFailed(const QString& reason);
    void serviceReady();

private:
    ServiceProvider();
    ~ServiceProvider() override;
    ServiceProvider(const ServiceProvider&) = delete;
    ServiceProvider& operator=(const ServiceProvider&) = delete;

    auto initializePreferences() -> bool;
    auto initializeMediaPipeline() -> bool;
    auto initializeProfileManager() -> bool;
    auto initializeAndroidAuto() -> bool;
    auto initializeAudioRouter() -> bool;
    auto initializeServiceManager() -> bool;
    std::unique_ptr<ServiceManager> m_serviceManager;

    bool m_initialized{false};
};