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
    static ServiceProvider& instance();

    /**
     * @brief Initialize all core services
     * @return true if initialization successful, false on error
     */
    bool initialize();

    /**
     * @brief Shutdown all core services
     */
    void shutdown();

    /**
     * @brief Check if services are initialized
     */
    bool isInitialized() const { return m_initialized; }

    // Service accessors
    AndroidAutoService* androidAutoService() const { return m_androidAutoService.get(); }
    PreferencesService* preferencesService() const { return m_preferencesService.get(); }
    EventBus* eventBus() const;  // Returns singleton
    AudioRouter* audioRouter() const { return m_audioRouter.get(); }
    Logger* logger() const;  // Returns singleton
    ServiceManager* serviceManager() const { return m_serviceManager.get(); }
    MediaPipeline* mediaPipeline() const { return m_mediaPipeline.get(); }
    ProfileManager* profileManager() const { return m_profileManager.get(); }

signals:
    void initializationFailed(const QString& reason);
    void serviceReady();

private:
    ServiceProvider();
    ~ServiceProvider() override;
    ServiceProvider(const ServiceProvider&) = delete;
    ServiceProvider& operator=(const ServiceProvider&) = delete;

    bool initializePreferences();
    bool initializeMediaPipeline();
    bool initializeProfileManager();
    bool initializeAndroidAuto();
    bool initializeAudioRouter();
    bool initializeServiceManager();

    std::unique_ptr<PreferencesService> m_preferencesService;
    std::unique_ptr<MediaPipeline> m_mediaPipeline;
    std::unique_ptr<ProfileManager> m_profileManager;
    std::unique_ptr<AndroidAutoService> m_androidAutoService;
    std::unique_ptr<AudioRouter> m_audioRouter;
    std::unique_ptr<ServiceManager> m_serviceManager;

    bool m_initialized{false};
};

