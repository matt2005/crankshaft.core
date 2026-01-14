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

#include "ServiceProvider.h"

// Core service includes
#include <QStandardPaths>

#include "../../core/hal/multimedia/MediaPipeline.h"
#include "../../core/services/android_auto/AndroidAutoService.h"
#include "../../core/services/audio/AudioRouter.h"
#include "../../core/services/eventbus/EventBus.h"
#include "../../core/services/logging/Logger.h"
#include "../../core/services/media/MediaService.h"
#include "../../core/services/preferences/PreferencesService.h"
#include "../../core/services/profile/ProfileManager.h"
#include "../../core/services/service_manager/ServiceManager.h"

ServiceProvider::ServiceProvider() : QObject(nullptr) {
    // Constructor - services initialized via initialize()
}

ServiceProvider::~ServiceProvider() { shutdown(); }

ServiceProvider& ServiceProvider::instance() {
    static ServiceProvider instance;
    return instance;
}

auto ServiceProvider::initialize() -> bool {
    if (m_initialized) {
        return true;
    }

    Logger::instance().infoContext("ServiceProvider", "Initializing core services for slim UI");

    // Initialize services in dependency order
    if (!initializePreferences()) {
        emit initializationFailed("Failed to initialize PreferencesService");
        return false;
    }

    if (!initializeMediaPipeline()) {
        emit initializationFailed("Failed to initialize MediaPipeline");
        return false;
    }

    if (!initializeProfileManager()) {
        emit initializationFailed("Failed to initialize ProfileManager");
        return false;
    }

    if (!initializeAndroidAuto()) {
        emit initializationFailed("Failed to initialize AndroidAutoService");
        return false;
    }

    if (!initializeAudioRouter()) {
        emit initializationFailed("Failed to initialize AudioRouter");
        return false;
    }

    if (!initializeServiceManager()) {
        emit initializationFailed("Failed to initialize ServiceManager");
        return false;
    }

    m_initialized = true;
    Logger::instance().infoContext("ServiceProvider", "All core services initialized successfully");
    emit serviceReady();

    return true;
}

auto ServiceProvider::shutdown() -> void {
    if (!m_initialized) {
        return;
    }

    Logger::instance().infoContext("ServiceProvider", "Shutting down core services");

    // Shutdown in reverse order
    m_serviceManager.reset();
    m_audioRouter.reset();
    m_androidAutoService.reset();
    m_profileManager.reset();
    m_mediaPipeline.reset();
    m_preferencesService.reset();

    m_initialized = false;
}

EventBus* ServiceProvider::eventBus() const { return &EventBus::instance(); }

Logger* ServiceProvider::logger() const { return &Logger::instance(); }

auto ServiceProvider::initializePreferences() -> bool {
    QString dbPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) +
                     "/slim-ui-preferences.db";

    m_preferencesService = std::make_unique<PreferencesService>(dbPath);

    if (!m_preferencesService->initialize()) {
        Logger::instance().errorContext(
            "ServiceProvider", "Failed to initialize preferences database", {{"dbPath", dbPath}});
        return false;
    }

    Logger::instance().infoContext("ServiceProvider", "PreferencesService initialized",
                                   {{"dbPath", dbPath}});
    return true;
}

auto ServiceProvider::initializeMediaPipeline() -> bool {
    // MediaPipeline construction - actual implementation depends on core structure
    // For now, create a basic instance
    m_mediaPipeline = std::make_unique<MediaPipeline>();

    Logger::instance().infoContext("ServiceProvider", "MediaPipeline initialized");
    return true;
}

auto ServiceProvider::initializeProfileManager() -> bool {
    // ProfileManager needs a config directory, use standard app data location
    QString configDir =
        QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/profiles";
    m_profileManager = std::make_unique<ProfileManager>(configDir);

    // ProfileManager will initialize profiles internally as needed
    Logger::instance().infoContext("ServiceProvider",
                                   "ProfileManager initialized with config dir: " + configDir);
    return true;
}

auto ServiceProvider::initializeAndroidAuto() -> bool {
    m_androidAutoService = std::unique_ptr<AndroidAutoService>(
        AndroidAutoService::create(m_mediaPipeline.get(), m_profileManager.get(), this));

    if (!m_androidAutoService) {
        Logger::instance().errorContext("ServiceProvider",
                                        "Failed to create AndroidAutoService instance");
        return false;
    }

    if (!m_androidAutoService->initialise()) {
        Logger::instance().errorContext("ServiceProvider",
                                        "Failed to initialize AndroidAutoService");
        return false;
    }

    Logger::instance().infoContext("ServiceProvider", "AndroidAutoService initialized");
    return true;
}

auto ServiceProvider::initializeAudioRouter() -> bool {
    m_audioRouter = std::make_unique<AudioRouter>(m_mediaPipeline.get(), this);

    if (!m_audioRouter->initialize()) {
        Logger::instance().warningContext(
            "ServiceProvider", "AudioRouter initialization failed - continuing in silent mode");
        // Don't fail initialization - allow graceful degradation
    } else {
        Logger::instance().infoContext("ServiceProvider", "AudioRouter initialized");
    }

    return true;
}

auto ServiceProvider::initializeServiceManager() -> bool {
    m_serviceManager = std::make_unique<ServiceManager>(m_profileManager.get(), this);

    Logger::instance().infoContext("ServiceProvider", "ServiceManager initialized");
    return true;
}