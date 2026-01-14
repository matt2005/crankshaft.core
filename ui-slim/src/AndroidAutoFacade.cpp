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

#include "../../core/services/android_auto/AndroidAutoService.h"
#include "../../core/services/eventbus/EventBus.h"
#include "../../core/services/logging/Logger.h"
#include "ServiceProvider.h"

AndroidAutoFacade::AndroidAutoFacade(ServiceProvider* serviceProvider, QObject* parent)
    : QObject(parent),
      m_serviceProvider(serviceProvider),
      m_connectionState(ConnectionState::Disconnected),
      m_connectedDeviceName(),
      m_lastError(),
      m_isVideoActive(false),
      m_isAudioActive(false) {
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
auto AndroidAutoFacade::connectionState() const -> int { return m_connectionState; }

auto AndroidAutoFacade::connectedDeviceName() const -> QString { return m_connectedDeviceName; }

auto AndroidAutoFacade::lastError() const -> QString { return m_lastError; }

auto AndroidAutoFacade::isVideoActive() const -> bool { return m_isVideoActive; }

auto AndroidAutoFacade::isAudioActive() const -> bool { return m_isAudioActive; }

// Q_INVOKABLE methods
auto AndroidAutoFacade::startDiscovery() -> void {
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

auto AndroidAutoFacade::stopDiscovery() -> void {
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

auto AndroidAutoFacade::connectToDevice(const QString& deviceId) -> void {
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

auto AndroidAutoFacade::disconnectDevice() -> void {
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

auto AndroidAutoFacade::retryConnection() -> void {
    Logger::instance().infoContext("AndroidAutoFacade", "Retrying connection");

    m_lastError.clear();
    emit lastErrorChanged(m_lastError);

    startDiscovery();
}

// EventBus slot handlers
auto AndroidAutoFacade::onCoreConnectionStateChanged(int state) -> void {
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

auto AndroidAutoFacade::onCoreDeviceDiscovered(const QVariantMap& device) -> void {
    Logger::instance().debugContext(
        "AndroidAutoFacade", QString("Device discovered: %1").arg(device.value("name").toString()));

    emit deviceAdded(device);

    // Emit updated device list
    QVariantList deviceList;
    deviceList.append(device);
    emit devicesDetected(deviceList);
}

auto AndroidAutoFacade::onCoreDeviceRemoved(const QString& deviceId) -> void {
    Logger::instance().debugContext("AndroidAutoFacade",
                                    QString("Device removed: %1").arg(deviceId));

    emit deviceRemoved(deviceId);
}

auto AndroidAutoFacade::onCoreVideoStateChanged(bool active) -> void {
    Logger::instance().debugContext(
        "AndroidAutoFacade",
        QString("Video state changed: %1").arg(active ? "active" : "inactive"));

    if (m_isVideoActive != active) {
        m_isVideoActive = active;
        emit isVideoActiveChanged(m_isVideoActive);
    }
}

auto AndroidAutoFacade::onCoreAudioStateChanged(bool active) -> void {
    Logger::instance().debugContext(
        "AndroidAutoFacade",
        QString("Audio state changed: %1").arg(active ? "active" : "inactive"));

    if (m_isAudioActive != active) {
        m_isAudioActive = active;
        emit isAudioActiveChanged(m_isAudioActive);
    }
}

auto AndroidAutoFacade::onCoreConnectionError(const QString& error) -> void {
    Logger::instance().errorContext("AndroidAutoFacade",
                                    QString("Connection error: %1").arg(error));

    reportError(error);
    emit connectionFailed(error);
}

// Private methods
auto AndroidAutoFacade::setupEventBusConnections() -> void {
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

auto AndroidAutoFacade::updateConnectionState(int newState) -> void {
    if (m_connectionState != newState) {
        m_connectionState = newState;
        emit connectionStateChanged(m_connectionState);

        Logger::instance().infoContext(
            "AndroidAutoFacade", QString("Connection state updated: %1").arg(m_connectionState));
    }
}

auto AndroidAutoFacade::reportError(const QString& errorMessage) -> void {
    m_lastError = errorMessage;
    emit lastErrorChanged(m_lastError);

    updateConnectionState(ConnectionState::Error);

    Logger::instance().errorContext("AndroidAutoFacade", errorMessage);
}