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

    Q_PROPERTY(QVariantList detectedDevices READ detectedDevices NOTIFY detectedDevicesChanged)
    Q_PROPERTY(int deviceCount READ deviceCount NOTIFY deviceCountChanged)
    Q_PROPERTY(bool hasMultipleDevices READ hasMultipleDevices NOTIFY hasMultipleDevicesChanged)
    Q_PROPERTY(
        QVariantMap lastConnectedDevice READ lastConnectedDevice NOTIFY lastConnectedDeviceChanged)

public:
    explicit DeviceManager(ServiceProvider* serviceProvider, AndroidAutoFacade* androidAutoFacade,
                           QObject* parent = nullptr);
    ~DeviceManager() override;

    // Property getters
    [[nodiscard]] auto detectedDevices() const -> QVariantList;
    [[nodiscard]] auto deviceCount() const -> int;
    [[nodiscard]] auto hasMultipleDevices() const -> bool;
    [[nodiscard]] auto lastConnectedDevice() const -> QVariantMap;

    // Q_INVOKABLE methods for QML
    // NOTE: Qt's MOC (Meta-Object Compiler) cannot handle 'auto' keyword in method
    // signatures. Explicit return types are required for Q_INVOKABLE methods.
    // NOLINTBEGIN(modernize-use-trailing-return-type)
    Q_INVOKABLE void clearDevices();
    Q_INVOKABLE [[nodiscard]] QVariantMap getDevice(const QString& deviceId) const;
    Q_INVOKABLE [[nodiscard]] QString getTopPriorityDeviceId() const;
    // NOLINTEND(modernize-use-trailing-return-type)

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