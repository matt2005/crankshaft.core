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

    /**
     * @brief Connection state: Maps to core AndroidAutoService::ConnectionState
     * Possible values: Disconnected (0), Searching (1), Connecting (2), Connected (3), Error (4)
     */
    Q_PROPERTY(int connectionState READ connectionState NOTIFY connectionStateChanged)

    /**
     * @brief Name of the currently connected Android Auto device
     */
    Q_PROPERTY(
        QString connectedDeviceName READ connectedDeviceName NOTIFY connectedDeviceNameChanged)

    /**
     * @brief Last error message from AndroidAuto subsystem
     */
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)

    /**
     * @brief Video stream status from connected device
     * Indicates whether video data is being received and processed
     */
    Q_PROPERTY(bool isVideoActive READ isVideoActive NOTIFY isVideoActiveChanged)

    /**
     * @brief Audio stream status from connected device
     * Indicates whether audio data is being received and processed
     */
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

    /**
     * @brief Q_INVOKABLE methods for QML interface
     * @note Qt's MOC (Meta-Object Compiler) cannot handle 'auto' keyword in method
     *       signatures. Explicit return types are required for Q_INVOKABLE methods.
     *       See: https://doc.qt.io/qt-6/metaobjects.html for MOC limitations.
     */
    // NOLINTBEGIN(modernize-use-trailing-return-type)
    /**
     * @brief Start discovery of Android Auto compatible devices
     * Initiates USB and Bluetooth scanning for AndroidAuto-capable devices.
     */
    Q_INVOKABLE void startDiscovery();

    /**
     * @brief Stop device discovery
     * Halts ongoing device scanning operations.
     */
    Q_INVOKABLE void stopDiscovery();

    /**
     * @brief Establish connection to specified device
     * @param deviceId Unique identifier of target device
     */
    Q_INVOKABLE void connectToDevice(const QString& deviceId);

    /**
     * @brief Disconnect from currently connected device
     * Gracefully closes all active connections and cleans up resources.
     */
    Q_INVOKABLE void disconnectDevice();

    /**
     * @brief Retry connection to previously connected device
     * Implements exponential backoff with maximum retry attempts.
     */
    Q_INVOKABLE void retryConnection();
    // NOLINTEND(modernize-use-trailing-return-type)

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