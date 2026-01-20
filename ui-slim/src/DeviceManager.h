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

#ifndef DEVICEMANAGER_H
#define DEVICEMANAGER_H

#include <QDateTime>
#include <QList>
#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>

class ServiceProvider;
class AndroidAutoFacade;

struct DetectedDevice {
    QString deviceId;
    QString name;
    QString type;        // "phone", "tablet", etc.
    int signalStrength;  // 0-100
    QDateTime lastSeen;
    bool wasConnectedBefore;
    int priority;  // Higher = higher priority (last-connected device = highest)

    QVariantMap toVariantMap() const {
        QVariantMap map;
        map["deviceId"] = deviceId;
        map["name"] = name;
        map["type"] = type;
        map["signalStrength"] = signalStrength;
        map["lastSeen"] = lastSeen;
        map["wasConnectedBefore"] = wasConnectedBefore;
        map["priority"] = priority;
        return map;
    }

    static DetectedDevice fromVariantMap(const QVariantMap& map) {
        DetectedDevice device;
        device.deviceId = map.value("deviceId").toString();
        device.name = map.value("name").toString();
        device.type = map.value("type", "phone").toString();
        device.signalStrength = map.value("signalStrength", 0).toInt();
        device.lastSeen = map.value("lastSeen", QDateTime::currentDateTime()).toDateTime();
        device.wasConnectedBefore = map.value("wasConnectedBefore", false).toBool();
        device.priority = map.value("priority", 0).toInt();
        return device;
    }
};

class DeviceManager : public QObject {
    Q_OBJECT

    /**\n     * @brief List of detected AndroidAuto-compatible devices\n     * Each device is a QVariantMap containing: deviceId, name, type, signalStrength, lastSeen, wasConnectedBefore, priority\n     */\n    Q_PROPERTY(QVariantList detectedDevices READ detectedDevices NOTIFY detectedDevicesChanged)\n\n    /**\n     * @brief Number of devices currently detected\n     */\n    Q_PROPERTY(int deviceCount READ deviceCount NOTIFY deviceCountChanged)\n\n    /**\n     * @brief True if more than one device is detected\n     */\n    Q_PROPERTY(bool hasMultipleDevices READ hasMultipleDevices NOTIFY hasMultipleDevicesChanged)\n\n    /**\n     * @brief Information about the last successfully connected device\n     */\n    Q_PROPERTY(\n        QVariantMap lastConnectedDevice READ lastConnectedDevice NOTIFY lastConnectedDeviceChanged)

public:
    explicit DeviceManager(ServiceProvider* serviceProvider, AndroidAutoFacade* androidAutoFacade,
                           QObject* parent = nullptr);
    ~DeviceManager() override;

    // Property getters
    [[nodiscard]] auto detectedDevices() const -> QVariantList;
    [[nodiscard]] auto deviceCount() const -> int;
    [[nodiscard]] auto hasMultipleDevices() const -> bool;
    [[nodiscard]] auto lastConnectedDevice() const -> QVariantMap;

    /**\n     * @brief Q_INVOKABLE methods for QML interface\n     * @note Qt's MOC (Meta-Object Compiler) cannot handle 'auto' keyword in method\n     *       signatures. Explicit return types are required for Q_INVOKABLE methods.\n     */\n    // NOLINTBEGIN(modernize-use-trailing-return-type)\n\n    /**\n     * @brief Remove all cached device information\n     * Clears the internal device list; does not affect currently connected device.\n     */\n    Q_INVOKABLE void clearDevices();\n\n    /**\n     * @brief Retrieve full information for a specific device\n     * @param deviceId Unique device identifier\n     * @return QVariantMap containing device properties, empty map if not found\n     */\n    Q_INVOKABLE [[nodiscard]] QVariantMap getDevice(const QString& deviceId) const;\n\n    /**\n     * @brief Get the ID of the highest-priority detected device\n     * @return Device ID of highest priority device, empty string if no devices detected\n     * Priority is based on: last-connected devices (highest), signal strength, recency\n     */\n    Q_INVOKABLE [[nodiscard]] QString getTopPriorityDeviceId() const;\n    // NOLINTEND(modernize-use-trailing-return-type)

signals:
    void detectedDevicesChanged();
    void deviceCountChanged(int count);
    void hasMultipleDevicesChanged(bool hasMultiple);
    void lastConnectedDeviceChanged();

    void deviceDiscovered(const QVariantMap& device);
    void deviceRemoved(const QString& deviceId);
    void devicesUpdated(const QVariantList& devices);

private slots:
    void onDeviceAdded(const QVariantMap& device);
    void onDeviceRemoved(const QString& deviceId);
    void onConnectionEstablished(const QString& deviceName);

private:
    auto addOrUpdateDevice(const DetectedDevice& device) -> void;
    auto removeDevice(const QString& deviceId) -> void;
    auto sortDevicesByPriority() -> void;
    auto loadLastConnectedDevice() -> void;
    auto saveLastConnectedDevice(const QString& deviceId) -> void;
    auto calculatePriority(const DetectedDevice& device) const -> int;

    ServiceProvider* m_serviceProvider;
    AndroidAutoFacade* m_androidAutoFacade;
    QList<DetectedDevice> m_devices;
    QString m_lastConnectedDeviceId;
};

#endif  // DEVICEMANAGER_H