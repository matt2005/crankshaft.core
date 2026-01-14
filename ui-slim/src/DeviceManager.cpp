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

#include "DeviceManager.h"

#include "../../core/services/logging/Logger.h"
#include "../../core/services/preferences/PreferencesService.h"
#include "AndroidAutoFacade.h"
#include "ServiceProvider.h"

DeviceManager::DeviceManager(ServiceProvider* serviceProvider, AndroidAutoFacade* androidAutoFacade,
                             QObject* parent)
    : QObject(parent),
      m_serviceProvider(serviceProvider),
      m_androidAutoFacade(androidAutoFacade),
      m_devices(),
      m_lastConnectedDeviceId() {
    if (!m_serviceProvider) {
        Logger::instance().errorContext("DeviceManager", "ServiceProvider is null");
        return;
    }

    if (!m_androidAutoFacade) {
        Logger::instance().errorContext("DeviceManager", "AndroidAutoFacade is null");
        return;
    }

    // Connect to AndroidAutoFacade signals
    connect(m_androidAutoFacade, &AndroidAutoFacade::deviceAdded, this,
            &DeviceManager::onDeviceAdded);
    connect(m_androidAutoFacade, &AndroidAutoFacade::deviceRemoved, this,
            &DeviceManager::onDeviceRemoved);
    connect(m_androidAutoFacade, &AndroidAutoFacade::connectionEstablished, this,
            &DeviceManager::onConnectionEstablished);

    // Load last connected device from preferences
    loadLastConnectedDevice();

    Logger::instance().infoContext("DeviceManager", "Initialized successfully");
}

DeviceManager::~DeviceManager() {
    Logger::instance().infoContext("DeviceManager", "Shutting down");
}

// Property getters
QVariantList DeviceManager::detectedDevices() const {
    QVariantList list;
    for (const auto& device : m_devices) {
        list.append(device.toVariantMap());
    }
    return list;
}

auto DeviceManager::deviceCount() const -> int { return m_devices.size(); }

auto DeviceManager::hasMultipleDevices() const -> bool { return m_devices.size() > 1; }

QVariantMap DeviceManager::lastConnectedDevice() const {
    for (const auto& device : m_devices) {
        if (device.deviceId == m_lastConnectedDeviceId) {
            return device.toVariantMap();
        }
    }
    return QVariantMap();
}

// Q_INVOKABLE methods
auto DeviceManager::clearDevices() -> void {
    Logger::instance().debugContext("DeviceManager", "Clearing all devices");

    m_devices.clear();
    emit detectedDevicesChanged();
    emit deviceCountChanged(0);
    emit hasMultipleDevicesChanged(false);
}

QVariantMap DeviceManager::getDevice(const QString& deviceId) const {
    for (const auto& device : m_devices) {
        if (device.deviceId == deviceId) {
            return device.toVariantMap();
        }
    }
    return QVariantMap();
}

auto DeviceManager::getTopPriorityDeviceId() const -> QString {
    if (m_devices.isEmpty()) {
        return QString();
    }

    // Devices are already sorted by priority (highest first)
    return m_devices.first().deviceId;
}

// Private slots
auto DeviceManager::onDeviceAdded(const QVariantMap& deviceMap) -> void {
    DetectedDevice device = DetectedDevice::fromVariantMap(deviceMap);

    // Check if this is the last connected device
    if (!m_lastConnectedDeviceId.isEmpty() && device.deviceId == m_lastConnectedDeviceId) {
        device.wasConnectedBefore = true;
    }

    // Calculate priority
    device.priority = calculatePriority(device);

    Logger::instance().infoContext("DeviceManager",
                                   QString("Device added: %1 (ID: %2, Priority: %3)")
                                       .arg(device.name, device.deviceId)
                                       .arg(device.priority));

    addOrUpdateDevice(device);
    emit deviceDiscovered(device.toVariantMap());
}

auto DeviceManager::onDeviceRemoved(const QString& deviceId) -> void {
    Logger::instance().infoContext("DeviceManager", QString("Device removed: %1").arg(deviceId));

    removeDevice(deviceId);
    emit deviceRemoved(deviceId);
}

auto DeviceManager::onConnectionEstablished(const QString& deviceName) -> void {
    Logger::instance().infoContext("DeviceManager",
                                   QString("Connection established to: %1").arg(deviceName));

    // Find device by name and save as last connected
    for (const auto& device : m_devices) {
        if (device.name == deviceName) {
            saveLastConnectedDevice(device.deviceId);
            emit lastConnectedDeviceChanged();
            break;
        }
    }
}

// Private methods
auto DeviceManager::addOrUpdateDevice(const DetectedDevice& device) -> void {
    // Check if device already exists
    for (auto it = m_devices.begin(); it != m_devices.end(); ++it) {
        if (it->deviceId == device.deviceId) {
            // Update existing device
            *it = device;
            sortDevicesByPriority();
            emit detectedDevicesChanged();
            emit devicesUpdated(detectedDevices());
            return;
        }
    }

    // Add new device
    m_devices.append(device);
    sortDevicesByPriority();

    int count = m_devices.size();
    emit detectedDevicesChanged();
    emit deviceCountChanged(count);
    emit hasMultipleDevicesChanged(count > 1);
    emit devicesUpdated(detectedDevices());
}

auto DeviceManager::removeDevice(const QString& deviceId) -> void {
    for (int i = 0; i < m_devices.size(); ++i) {
        if (m_devices.at(i).deviceId == deviceId) {
            m_devices.removeAt(i);

            int count = m_devices.size();
            emit detectedDevicesChanged();
            emit deviceCountChanged(count);
            emit hasMultipleDevicesChanged(count > 1);
            emit devicesUpdated(detectedDevices());
            return;
        }
    }
}

auto DeviceManager::sortDevicesByPriority() -> void {
    std::sort(m_devices.begin(), m_devices.end(),
              [](const DetectedDevice& a, const DetectedDevice& b) {
                  // Higher priority first
                  if (a.priority != b.priority) {
                      return a.priority > b.priority;
                  }
                  // Then by signal strength
                  if (a.signalStrength != b.signalStrength) {
                      return a.signalStrength > b.signalStrength;
                  }
                  // Then by last seen (more recent first)
                  return a.lastSeen > b.lastSeen;
              });
}

auto DeviceManager::loadLastConnectedDevice() -> void {
    auto* prefsService = m_serviceProvider->preferencesService();
    if (!prefsService) {
        Logger::instance().warningContext(
            "DeviceManager", "PreferencesService not available, cannot load last connected device");
        return;
    }

    // TODO: Load from preferences once API is confirmed
    // m_lastConnectedDeviceId = prefsService->getString("androidauto.last_device_id", "");

    if (!m_lastConnectedDeviceId.isEmpty()) {
        Logger::instance().infoContext(
            "DeviceManager",
            QString("Loaded last connected device: %1").arg(m_lastConnectedDeviceId));
    }
}

auto DeviceManager::saveLastConnectedDevice(const QString& deviceId) -> void {
    auto* prefsService = m_serviceProvider->preferencesService();
    if (!prefsService) {
        Logger::instance().warningContext(
            "DeviceManager", "PreferencesService not available, cannot save last connected device");
        return;
    }

    m_lastConnectedDeviceId = deviceId;

    // TODO: Save to preferences once API is confirmed
    // prefsService->setString("androidauto.last_device_id", deviceId);

    Logger::instance().infoContext("DeviceManager",
                                   QString("Saved last connected device: %1").arg(deviceId));
}

auto DeviceManager::calculatePriority(const DetectedDevice& device) const -> int {
    int priority = 0;

    // Last connected device gets highest priority
    if (device.wasConnectedBefore && device.deviceId == m_lastConnectedDeviceId) {
        priority += 1000;
    }

    // Previously connected devices get medium priority
    if (device.wasConnectedBefore) {
        priority += 100;
    }

    // Signal strength contributes to priority (0-100)
    priority += device.signalStrength;

    return priority;
}