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

#include "DeviceHAL.h"

#include <QTimer>
#include <deque>

/**
 * @brief Mock device HAL for testing and development
 * 
 * Simulates various device interfaces (CAN bus, GPIO, etc.)
 * without requiring actual hardware.
 */
class MockDeviceHAL : public DeviceHAL {
  Q_OBJECT
 public:
  /**
   * @brief Create a mock device for the specified interface type
   */
  MockDeviceHAL(DeviceInterfaceType type, QObject* parent = nullptr);
  ~MockDeviceHAL() override;

  // DeviceHAL interface
  DeviceInterfaceType getType() const override { return m_type; }
  QString getName() const override;
  QString getDescription() const override;
  bool initialize() override;
  void shutdown() override;
  DeviceState getState() const override { return m_state; }
  bool isConnected() const override {
    return m_state == DeviceState::ONLINE;
  }
  bool sendData(const QByteArray& data) override;
  QByteArray receiveData() override;
  QVariant sendCommand(const QString& command,
                       const QVariantMap& parameters = {}) override;
  DeviceStatus getStatus() const override;
  bool setConfig(const QString& key, const QVariant& value) override;
  QVariant getConfig(const QString& key) override;

 private slots:
  void updateSimulation();

 private:
  void initializeDefaults();

  DeviceInterfaceType m_type;
  DeviceState m_state{DeviceState::OFFLINE};

  QMap<QString, QVariant> m_config;
  std::deque<QByteArray> m_rxBuffer;  // Simulated receive buffer
  QTimer m_updateTimer;

  QString m_lastError;
  qint64 m_lastUpdate{0};
};
