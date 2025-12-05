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

#include "MockDeviceHAL.h"

#include <QDateTime>
#include <QDebug>
#include <QRandomGenerator>

MockDeviceHAL::MockDeviceHAL(DeviceInterfaceType type, QObject* parent)
    : DeviceHAL(parent), m_type(type) {
  connect(&m_updateTimer, &QTimer::timeout, this,
          &MockDeviceHAL::updateSimulation);
  initializeDefaults();
}

MockDeviceHAL::~MockDeviceHAL() {
  shutdown();
}

QString MockDeviceHAL::getName() const {
  switch (m_type) {
    case DeviceInterfaceType::CAN_BUS:
      return "CAN Bus 0";
    case DeviceInterfaceType::I2C:
      return "I2C Bus 1";
    case DeviceInterfaceType::GPIO:
      return "GPIO Controller";
    case DeviceInterfaceType::UART:
      return "Serial Port /dev/ttyUSB0";
    case DeviceInterfaceType::ETHERNET:
      return "Ethernet eth0";
    case DeviceInterfaceType::GPS:
      return "GPS Module";
    default:
      return "Device";
  }
}

QString MockDeviceHAL::getDescription() const {
  switch (m_type) {
    case DeviceInterfaceType::CAN_BUS:
      return "CAN Bus communication interface (500 kbps)";
    case DeviceInterfaceType::I2C:
      return "I2C communication interface (100 kHz)";
    case DeviceInterfaceType::GPIO:
      return "General Purpose I/O controller";
    case DeviceInterfaceType::UART:
      return "Serial UART interface (115200 baud)";
    case DeviceInterfaceType::ETHERNET:
      return "Ethernet network interface";
    case DeviceInterfaceType::GPS:
      return "GPS/GNSS receiver module";
    default:
      return "Mock device interface";
  }
}

bool MockDeviceHAL::initialize() {
  m_state = DeviceState::CONNECTING;
  emit stateChanged(m_state);

  // Simulate connection delay
  m_updateTimer.singleShot(500, this, [this]() {
    QMutexLocker lock(&m_mutex);
    m_state = DeviceState::ONLINE;
    m_lastUpdate = QDateTime::currentMSecsSinceEpoch();
    emit stateChanged(m_state);
    emit connected();
    qDebug() << "MockDeviceHAL" << getName() << "connected";
  });

  return true;
}

void MockDeviceHAL::shutdown() {
  m_updateTimer.stop();
  if (m_state == DeviceState::ONLINE) {
    QMutexLocker lock(&m_mutex);
    m_state = DeviceState::OFFLINE;
    emit stateChanged(m_state);
    emit disconnected();
    qDebug() << "MockDeviceHAL" << getName() << "shutdown";
  }
}

bool MockDeviceHAL::sendData(const QByteArray& data) {
  if (!isConnected()) {
    m_lastError = "Device not connected";
    return false;
  }

  QMutexLocker lock(&m_mutex);
  // Echo back some data to simulate communication
  m_rxBuffer.push_back(data);
  emit dataReceived(data);
  return true;
}

QByteArray MockDeviceHAL::receiveData() {
  QMutexLocker lock(&m_mutex);
  if (m_rxBuffer.empty()) {
    return {};
  }
  QByteArray data = m_rxBuffer.front();
  m_rxBuffer.pop_front();
  return data;
}

QVariant MockDeviceHAL::sendCommand(const QString& command,
                                    const QVariantMap& parameters) {
  if (!isConnected()) {
    m_lastError = "Device not connected";
    emit errorOccurred(m_lastError);
    return QVariant();
  }

  QMutexLocker lock(&m_mutex);

  // Simulate command execution
  if (command == "get_status") {
    return QVariant::fromValue(getStatus());
  } else if (command == "reset") {
    m_state = DeviceState::ONLINE;
    return true;
  } else if (command == "test") {
    return "Mock device test response";
  } else if (command == "echo") {
    return parameters.value("message", "No message");
  }

  m_lastError = "Unknown command: " + command;
  return QVariant();
}

DeviceStatus MockDeviceHAL::getStatus() const {
  QMutexLocker lock(&m_mutex);
  return DeviceStatus{
      m_type,           // type
      m_state,          // state
      getName(),        // name
      getDescription(), // description
      m_lastUpdate,     // lastUpdate
      m_lastError       // lastError
  };
}

bool MockDeviceHAL::setConfig(const QString& key, const QVariant& value) {
  QMutexLocker lock(&m_mutex);
  m_config[key] = value;
  return true;
}

QVariant MockDeviceHAL::getConfig(const QString& key) {
  QMutexLocker lock(&m_mutex);
  return m_config.value(key, QVariant());
}

void MockDeviceHAL::initializeDefaults() {
  // Set default configuration for each device type
  switch (m_type) {
    case DeviceInterfaceType::CAN_BUS:
      m_config["baudrate"] = 500000;
      m_config["timeout"] = 1000;
      break;
    case DeviceInterfaceType::I2C:
      m_config["speed"] = 100000;
      m_config["timeout"] = 1000;
      break;
    case DeviceInterfaceType::UART:
      m_config["baudrate"] = 115200;
      m_config["parity"] = "NONE";
      m_config["stopbits"] = 1;
      break;
    case DeviceInterfaceType::GPIO:
      m_config["pin_count"] = 40;
      m_config["mode"] = "general_purpose";
      break;
    default:
      break;
  }
}

void MockDeviceHAL::updateSimulation() {
  if (!isConnected()) {
    return;
  }

  QMutexLocker lock(&m_mutex);
  m_lastUpdate = QDateTime::currentMSecsSinceEpoch();
}
