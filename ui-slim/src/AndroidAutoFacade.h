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

#ifndef ANDROIDAUTOFACADE_H
#define ANDROIDAUTOFACADE_H

#include <QObject>
#include <QString>
#include <QVariantMap>

class ServiceProvider;

class AndroidAutoFacade : public QObject {
    Q_OBJECT

    // Connection state: Maps to core AndroidAutoService::ConnectionState
    Q_PROPERTY(int connectionState READ connectionState NOTIFY connectionStateChanged)

    // Connected device information
    Q_PROPERTY(
        QString connectedDeviceName READ connectedDeviceName NOTIFY connectedDeviceNameChanged)

    // Last error message
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)

    // Media state
    Q_PROPERTY(bool isVideoActive READ isVideoActive NOTIFY isVideoActiveChanged)
    Q_PROPERTY(bool isAudioActive READ isAudioActive NOTIFY isAudioActiveChanged)

public:
    enum ConnectionState {
        Disconnected = 0,
        Searching = 1,
        Connecting = 2,
        Connected = 3,
        Error = 4
    };
    Q_ENUM(ConnectionState)

    explicit AndroidAutoFacade(ServiceProvider* serviceProvider, QObject* parent = nullptr);
    ~AndroidAutoFacade() override;

    // Property getters
    [[nodiscard]] auto connectionState() const -> int;
    [[nodiscard]] auto connectedDeviceName() const -> QString;
    [[nodiscard]] auto lastError() const -> QString;
    [[nodiscard]] auto isVideoActive() const -> bool;
    [[nodiscard]] auto isAudioActive() const -> bool;

    // Q_INVOKABLE methods for QML
    Q_INVOKABLE void startDiscovery();
    Q_INVOKABLE void stopDiscovery();
    Q_INVOKABLE void connectToDevice(const QString& deviceId);
    Q_INVOKABLE void disconnectDevice();
    Q_INVOKABLE void retryConnection();

signals:
    // Connection state changes
    void connectionStateChanged(int state);
    void connectedDeviceNameChanged(const QString& name);
    void lastErrorChanged(const QString& error);

    // Media state changes
    void isVideoActiveChanged(bool active);
    void isAudioActiveChanged(bool active);

    // Discovery events
    void devicesDetected(const QVariantList& devices);
    void deviceAdded(const QVariantMap& device);
    void deviceRemoved(const QString& deviceId);

    // Connection events
    void connectionFailed(const QString& reason);
    void connectionEstablished(const QString& deviceName);
    void disconnectionRequested();

private slots:
    // EventBus subscriptions
    void onCoreConnectionStateChanged(int state);
    void onCoreDeviceDiscovered(const QVariantMap& device);
    void onCoreDeviceRemoved(const QString& deviceId);
    void onCoreVideoStateChanged(bool active);
    void onCoreAudioStateChanged(bool active);
    void onCoreConnectionError(const QString& error);

private:
    auto setupEventBusConnections() -> void;
    auto updateConnectionState(int newState) -> void;
    auto reportError(const QString& errorMessage) -> void;

    ServiceProvider* m_serviceProvider;
    int m_connectionState;
    QString m_connectedDeviceName;
    QString m_lastError;
    bool m_isVideoActive;
    bool m_isAudioActive;
};

#endif  // ANDROIDAUTOFACADE_H