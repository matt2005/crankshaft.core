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

#pragma once

#include <QObject>
#include <QString>
#include <QVariant>
#include <QMap>
#include <QMutex>
#include <memory>

/**
 * @brief Device-specific hardware interface types
 * 
 * Represents hardware interfaces that can have multiple implementations
 * (CAN bus, mock, GPIO, etc.).
 */
enum class DeviceInterfaceType {
  /* Communication Interfaces */
  CAN_BUS,                   // CAN bus interface
  LIN_BUS,                   // LIN bus interface
  ETHERNET,                  // Ethernet interface
  I2C,                       // I2C interface
  SPI,                       // SPI interface
  UART,                      // UART/Serial interface
  USB,                       // USB interface
  BLUETOOTH,                 // Bluetooth interface
  WIFI,                      // WiFi interface
  
  /* Sensor Interfaces */
  IMU,                       // Inertial Measurement Unit
  CAMERA,                    // Camera sensor
  LIDAR,                     // LIDAR sensor
  RADAR,                     // RADAR sensor
  THERMOMETER,               // Temperature sensor
  HUMIDITY,                  // Humidity sensor
  PRESSURE,                  // Pressure sensor
  ACCELEROMETER,             // Accelerometer
  GYROSCOPE,                 // Gyroscope
  MAGNETOMETER,              // Magnetometer (compass)
  GPS,                       // GPS/GNSS receiver
  
  /* Output Interfaces */
  GPIO,                      // General Purpose I/O
  PWM,                       // Pulse Width Modulation
  DISPLAY,                   // Display/Screen output
  LED,                       // LED indicator
  SPEAKER,                   // Audio speaker
  VIBRATOR,                  // Haptic vibrator
  
  /* Power Management */
  POWER_SUPPLY,              // Power supply unit
  BATTERY,                   // Battery management
  USB_POWER,                 // USB power delivery
};

/**
 * @brief Device state enumeration
 */
enum class DeviceState {
  OFFLINE,                   // Not connected or not available
  CONNECTING,                // Connection in progress
  ONLINE,                    // Connected and operational
  ERROR,                     // Error state
};

/**
 * @brief Device interface status structure
 */
struct DeviceStatus {
  DeviceInterfaceType type;
  DeviceState state;
  QString name;
  QString description;
  qint64 lastUpdate;  // Milliseconds since epoch
  QString lastError;  // Last error message if in error state
};

/**
 * @brief Device HAL interface
 * 
 * Abstract base class for device-specific hardware interfaces.
 * Each implementation handles a particular hardware communication method
 * (CAN bus, GPIO, I2C, etc.).
 * 
 * Usage:
 *   auto canBus = std::make_shared<MockCanBusDevice>();
 *   if (canBus->initialize()) {
 *       canBus->sendMessage(0x123, data);
 *   }
 */
class DeviceHAL : public QObject {
  Q_OBJECT
 public:
  explicit DeviceHAL(QObject* parent = nullptr);
  virtual ~DeviceHAL() = default;

  /**
   * @brief Get the device interface type
   */
  virtual DeviceInterfaceType getType() const = 0;

  /**
   * @brief Get device name
   * @return Descriptive name like "CAN Bus 0", "I2C Bus 1", etc.
   */
  virtual QString getName() const = 0;

  /**
   * @brief Get device description
   */
  virtual QString getDescription() const = 0;

  /**
   * @brief Initialise the device
   * @return true if initialisation successful, false otherwise
   */
  virtual bool initialize() = 0;

  /**
   * @brief Shutdown the device gracefully
   */
  virtual void shutdown() = 0;

  /**
   * @brief Get current device state
   */
  virtual DeviceState getState() const = 0;

  /**
   * @brief Check if device is connected and operational
   */
  virtual bool isConnected() const = 0;

  /**
   * @brief Send/write data to device
   * @param data The data to send
   * @return true if sent successfully, false otherwise
   */
  virtual bool sendData(const QByteArray& data) = 0;

  /**
   * @brief Receive/read data from device
   * @return Data received, or empty QByteArray if no data available
   */
  virtual QByteArray receiveData() = 0;

  /**
   * @brief Send a command to the device
   * @param command Command identifier
   * @param parameters Command parameters as variant map
   * @return Command response as QVariant
   */
  virtual QVariant sendCommand(const QString& command,
                               const QVariantMap& parameters = {}) = 0;

  /**
   * @brief Get extended status information
   */
  virtual DeviceStatus getStatus() const = 0;

  /**
   * @brief Set device-specific configuration
   * @param key Configuration key
   * @param value Configuration value
   * @return true if set successfully
   */
  virtual bool setConfig(const QString& key, const QVariant& value) = 0;

  /**
   * @brief Get device-specific configuration
   * @param key Configuration key
   * @return Configuration value, or invalid QVariant if not found
   */
  virtual QVariant getConfig(const QString& key) = 0;

 signals:
  /**
   * @brief Emitted when device state changes
   */
  void stateChanged(DeviceState newState);

  /**
   * @brief Emitted when data is received
   */
  void dataReceived(const QByteArray& data);

  /**
   * @brief Emitted when an error occurs
   */
  void errorOccurred(const QString& message);

  /**
   * @brief Emitted when device connects
   */
  void connected();

  /**
   * @brief Emitted when device disconnects
   */
  void disconnected();

 protected:
  mutable QMutex m_mutex;  // For thread-safe access
};

