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

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <QList>
#include <QDateTime>

class ServiceProvider;
class AndroidAutoFacade;

struct DetectedDevice {
    QString deviceId;
    QString name;
    QString type;           // "phone", "tablet", etc.
    int signalStrength;     // 0-100
    QDateTime lastSeen;
    bool wasConnectedBefore;
    int priority;           // Higher = higher priority (last-connected device = highest)
    
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
    Q_PROPERTY(QVariantMap lastConnectedDevice READ lastConnectedDevice NOTIFY lastConnectedDeviceChanged)

  public:
    explicit DeviceManager(ServiceProvider* serviceProvider, 
                          AndroidAutoFacade* androidAutoFacade,
                          QObject* parent = nullptr);
    ~DeviceManager() override;

    // Property getters
    QVariantList detectedDevices() const;
    int deviceCount() const;
    bool hasMultipleDevices() const;
    QVariantMap lastConnectedDevice() const;

    // Q_INVOKABLE methods for QML
    Q_INVOKABLE void clearDevices();
    Q_INVOKABLE QVariantMap getDevice(const QString& deviceId) const;
    Q_INVOKABLE QString getTopPriorityDeviceId() const;

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
    void addOrUpdateDevice(const DetectedDevice& device);
    void removeDevice(const QString& deviceId);
    void sortDevicesByPriority();
    void loadLastConnectedDevice();
    void saveLastConnectedDevice(const QString& deviceId);
    int calculatePriority(const DetectedDevice& device) const;

    ServiceProvider* m_serviceProvider;
    AndroidAutoFacade* m_androidAutoFacade;
    QList<DetectedDevice> m_devices;
    QString m_lastConnectedDeviceId;
};

#endif // DEVICEMANAGER_H
