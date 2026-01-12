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
#include "ServiceProvider.h"
#include "AndroidAutoFacade.h"
#include "../../core/services/logging/Logger.h"
#include "../../core/services/preferences/PreferencesService.h"

DeviceManager::DeviceManager(ServiceProvider* serviceProvider,
                             AndroidAutoFacade* androidAutoFacade,
                             QObject* parent)
    : QObject(parent)
    , m_serviceProvider(serviceProvider)
    , m_androidAutoFacade(androidAutoFacade)
    , m_devices()
    , m_lastConnectedDeviceId() {
    
    if (!m_serviceProvider) {
        Logger::instance().errorContext("DeviceManager", "ServiceProvider is null");
        return;
    }
    
    if (!m_androidAutoFacade) {
        Logger::instance().errorContext("DeviceManager", "AndroidAutoFacade is null");
        return;
    }

    // Connect to AndroidAutoFacade signals
    connect(m_androidAutoFacade, &AndroidAutoFacade::deviceAdded,
            this, &DeviceManager::onDeviceAdded);
    connect(m_androidAutoFacade, &AndroidAutoFacade::deviceRemoved,
            this, &DeviceManager::onDeviceRemoved);
    connect(m_androidAutoFacade, &AndroidAutoFacade::connectionEstablished,
            this, &DeviceManager::onConnectionEstablished);

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

int DeviceManager::deviceCount() const {
    return m_devices.size();
}

bool DeviceManager::hasMultipleDevices() const {
    return m_devices.size() > 1;
}

QVariantMap DeviceManager::lastConnectedDevice() const {
    for (const auto& device : m_devices) {
        if (device.deviceId == m_lastConnectedDeviceId) {
            return device.toVariantMap();
        }
    }
    return QVariantMap();
}

// Q_INVOKABLE methods
void DeviceManager::clearDevices() {
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

QString DeviceManager::getTopPriorityDeviceId() const {
    if (m_devices.isEmpty()) {
        return QString();
    }
    
    // Devices are already sorted by priority (highest first)
    return m_devices.first().deviceId;
}

// Private slots
void DeviceManager::onDeviceAdded(const QVariantMap& deviceMap) {
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

void DeviceManager::onDeviceRemoved(const QString& deviceId) {
    Logger::instance().infoContext("DeviceManager", 
                QString("Device removed: %1").arg(deviceId));
    
    removeDevice(deviceId);
    emit deviceRemoved(deviceId);
}

void DeviceManager::onConnectionEstablished(const QString& deviceName) {
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
void DeviceManager::addOrUpdateDevice(const DetectedDevice& device) {
    // Check if device already exists
    for (int i = 0; i < m_devices.size(); ++i) {
        if (m_devices[i].deviceId == device.deviceId) {
            // Update existing device
            m_devices[i] = device;
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

void DeviceManager::removeDevice(const QString& deviceId) {
    for (int i = 0; i < m_devices.size(); ++i) {
        if (m_devices[i].deviceId == deviceId) {
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

void DeviceManager::sortDevicesByPriority() {
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

void DeviceManager::loadLastConnectedDevice() {
    auto* prefsService = m_serviceProvider->preferencesService();
    if (!prefsService) {
        Logger::instance().warningContext("DeviceManager", 
                    "PreferencesService not available, cannot load last connected device");
        return;
    }

    // TODO: Load from preferences once API is confirmed
    // m_lastConnectedDeviceId = prefsService->getString("androidauto.last_device_id", "");
    
    if (!m_lastConnectedDeviceId.isEmpty()) {
        Logger::instance().infoContext("DeviceManager", 
                    QString("Loaded last connected device: %1").arg(m_lastConnectedDeviceId));
    }
}

void DeviceManager::saveLastConnectedDevice(const QString& deviceId) {
    auto* prefsService = m_serviceProvider->preferencesService();
    if (!prefsService) {
        Logger::instance().warningContext("DeviceManager", 
                    "PreferencesService not available, cannot save last connected device");
        return;
    }

    m_lastConnectedDeviceId = deviceId;
    
    // TODO: Save to preferences once API is confirmed
    // prefsService->setString("androidauto.last_device_id", deviceId);
    
    Logger::instance().infoContext("DeviceManager", 
                QString("Saved last connected device: %1").arg(deviceId));
}

int DeviceManager::calculatePriority(const DetectedDevice& device) const {
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
