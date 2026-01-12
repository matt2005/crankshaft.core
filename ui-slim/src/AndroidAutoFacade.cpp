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

#include "AndroidAutoFacade.h"
#include "ServiceProvider.h"
#include "../../core/services/android_auto/AndroidAutoService.h"
#include "../../core/services/eventbus/EventBus.h"
#include "../../core/services/logging/Logger.h"

AndroidAutoFacade::AndroidAutoFacade(ServiceProvider* serviceProvider, QObject* parent)
    : QObject(parent)
    , m_serviceProvider(serviceProvider)
    , m_connectionState(ConnectionState::Disconnected)
    , m_connectedDeviceName()
    , m_lastError()
    , m_isVideoActive(false)
    , m_isAudioActive(false) {
    
    if (!m_serviceProvider) {
        Logger::instance().errorContext("AndroidAutoFacade", "ServiceProvider is null");
        return;
    }

    setupEventBusConnections();
    
    Logger::instance().infoContext("AndroidAutoFacade", "Initialized successfully");
}

AndroidAutoFacade::~AndroidAutoFacade() {
    Logger::instance().infoContext("AndroidAutoFacade", "Shutting down");
}

// Property getters
int AndroidAutoFacade::connectionState() const {
    return m_connectionState;
}

QString AndroidAutoFacade::connectedDeviceName() const {
    return m_connectedDeviceName;
}

QString AndroidAutoFacade::lastError() const {
    return m_lastError;
}

bool AndroidAutoFacade::isVideoActive() const {
    return m_isVideoActive;
}

bool AndroidAutoFacade::isAudioActive() const {
    return m_isAudioActive;
}

// Q_INVOKABLE methods
void AndroidAutoFacade::startDiscovery() {
    Logger::instance().infoContext("AndroidAutoFacade", "Starting device discovery");
    
    auto* aaService = m_serviceProvider->androidAutoService();
    if (!aaService) {
        reportError("AndroidAuto service not available");
        return;
    }

    updateConnectionState(ConnectionState::Searching);
    
    // Delegate to core AndroidAutoService
    aaService->startSearching();
}

void AndroidAutoFacade::stopDiscovery() {
    Logger::instance().infoContext("AndroidAutoFacade", "Stopping device discovery");
    
    auto* aaService = m_serviceProvider->androidAutoService();
    if (!aaService) {
        return;
    }

    aaService->stopSearching();
    
    if (m_connectionState == ConnectionState::Searching) {
        updateConnectionState(ConnectionState::Disconnected);
    }
}

void AndroidAutoFacade::connectToDevice(const QString& deviceId) {
    Logger::instance().infoContext("AndroidAutoFacade", 
                QString("Connecting to device: %1").arg(deviceId));
    
    auto* aaService = m_serviceProvider->androidAutoService();
    if (!aaService) {
        reportError("AndroidAuto service not available");
        return;
    }

    updateConnectionState(ConnectionState::Connecting);
    
    // Delegate to core AndroidAutoService
    aaService->connectToDevice(deviceId);
}

void AndroidAutoFacade::disconnectDevice() {
    Logger::instance().infoContext("AndroidAutoFacade", "Disconnecting device");
    
    auto* aaService = m_serviceProvider->androidAutoService();
    if (!aaService) {
        return;
    }

    emit disconnectionRequested();
    
    aaService->disconnect();
    updateConnectionState(ConnectionState::Disconnected);
    
    m_connectedDeviceName.clear();
    emit connectedDeviceNameChanged(m_connectedDeviceName);
}

void AndroidAutoFacade::retryConnection() {
    Logger::instance().infoContext("AndroidAutoFacade", "Retrying connection");
    
    m_lastError.clear();
    emit lastErrorChanged(m_lastError);
    
    startDiscovery();
}

// EventBus slot handlers
void AndroidAutoFacade::onCoreConnectionStateChanged(int state) {
    Logger::instance().debugContext("AndroidAutoFacade", 
                QString("Core connection state changed: %1").arg(state));
    
    updateConnectionState(state);
    
    if (state == ConnectionState::Connected) {
        // Query connected device name from core service
        auto* aaService = m_serviceProvider->androidAutoService();
        if (aaService) {
            // TODO: Get device name from core service API
            m_connectedDeviceName = "Connected Device";
            emit connectedDeviceNameChanged(m_connectedDeviceName);
            emit connectionEstablished(m_connectedDeviceName);
        }
    }
}

void AndroidAutoFacade::onCoreDeviceDiscovered(const QVariantMap& device) {
    Logger::instance().debugContext("AndroidAutoFacade", 
                QString("Device discovered: %1").arg(device.value("name").toString()));
    
    emit deviceAdded(device);
    
    // Emit updated device list
    QVariantList deviceList;
    deviceList.append(device);
    emit devicesDetected(deviceList);
}

void AndroidAutoFacade::onCoreDeviceRemoved(const QString& deviceId) {
    Logger::instance().debugContext("AndroidAutoFacade", 
                QString("Device removed: %1").arg(deviceId));
    
    emit deviceRemoved(deviceId);
}

void AndroidAutoFacade::onCoreVideoStateChanged(bool active) {
    Logger::instance().debugContext("AndroidAutoFacade", 
                QString("Video state changed: %1").arg(active ? "active" : "inactive"));
    
    if (m_isVideoActive != active) {
        m_isVideoActive = active;
        emit isVideoActiveChanged(m_isVideoActive);
    }
}

void AndroidAutoFacade::onCoreAudioStateChanged(bool active) {
    Logger::instance().debugContext("AndroidAutoFacade", 
                QString("Audio state changed: %1").arg(active ? "active" : "inactive"));
    
    if (m_isAudioActive != active) {
        m_isAudioActive = active;
        emit isAudioActiveChanged(m_isAudioActive);
    }
}

void AndroidAutoFacade::onCoreConnectionError(const QString& error) {
    Logger::instance().errorContext("AndroidAutoFacade", 
                QString("Connection error: %1").arg(error));
    
    reportError(error);
    emit connectionFailed(error);
}

// Private methods
void AndroidAutoFacade::setupEventBusConnections() {
    auto* eventBus = m_serviceProvider->eventBus();
    if (!eventBus) {
        Logger::instance().warningContext("AndroidAutoFacade", "EventBus not available");
        return;
    }

    // Subscribe to core AndroidAuto events
    // TODO: Connect to actual EventBus signals once core API is confirmed
    // eventBus->subscribe("androidauto.connection_state_changed", 
    //                    this, &AndroidAutoFacade::onCoreConnectionStateChanged);
    // eventBus->subscribe("androidauto.device_discovered", 
    //                    this, &AndroidAutoFacade::onCoreDeviceDiscovered);
    // eventBus->subscribe("androidauto.device_removed", 
    //                    this, &AndroidAutoFacade::onCoreDeviceRemoved);
    // eventBus->subscribe("androidauto.video_state_changed", 
    //                    this, &AndroidAutoFacade::onCoreVideoStateChanged);
    // eventBus->subscribe("androidauto.audio_state_changed", 
    //                    this, &AndroidAutoFacade::onCoreAudioStateChanged);
    // eventBus->subscribe("androidauto.connection_error", 
    //                    this, &AndroidAutoFacade::onCoreConnectionError);
    
    Logger::instance().debugContext("AndroidAutoFacade", "EventBus connections set up");
}

void AndroidAutoFacade::updateConnectionState(int newState) {
    if (m_connectionState != newState) {
        m_connectionState = newState;
        emit connectionStateChanged(m_connectionState);
        
        Logger::instance().infoContext("AndroidAutoFacade", 
                    QString("Connection state updated: %1").arg(m_connectionState));
    }
}

void AndroidAutoFacade::reportError(const QString& errorMessage) {
    m_lastError = errorMessage;
    emit lastErrorChanged(m_lastError);
    
    updateConnectionState(ConnectionState::Error);
    
    Logger::instance().errorContext("AndroidAutoFacade", errorMessage);
}
