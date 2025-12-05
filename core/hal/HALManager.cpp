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

#include "HALManager.h"

#include "MockVehicleHAL.h"
#include "MockHostHAL.h"
#include "MockDeviceHAL.h"

#include <QDebug>

HALManager::HALManager(QObject* parent) : QObject(parent) {}

HALManager::~HALManager() {}

HALManager& HALManager::instance() {
  static HALManager s_instance;
  return s_instance;
}

bool HALManager::initialize(bool useDeviceHALs) {
  QMutexLocker lock(&m_mutex);

  if (m_initialized) {
    qWarning() << "HALManager already initialized";
    return false;
  }

  // If no HAL is set, use defaults
  if (!m_vehicleHAL) {
    m_vehicleHAL = std::make_shared<MockVehicleHAL>();
  }
  if (!m_hostHAL) {
    m_hostHAL = std::make_shared<MockHostHAL>();
  }

  // Initialize vehicle HAL
  if (!m_vehicleHAL->initialize()) {
    emit errorOccurred("Failed to initialize Vehicle HAL");
    return false;
  }
  connectVehicleHAL();

  // Initialize host HAL
  if (!m_hostHAL->initialize()) {
    emit errorOccurred("Failed to initialize Host HAL");
    return false;
  }
  connectHostHAL();

  // Create default device HALs if requested
  if (useDeviceHALs) {
    auto canBus = std::make_shared<MockDeviceHAL>(DeviceInterfaceType::CAN_BUS);
    auto i2c = std::make_shared<MockDeviceHAL>(DeviceInterfaceType::I2C);
    auto gps = std::make_shared<MockDeviceHAL>(DeviceInterfaceType::GPS);

    for (auto& device : {canBus, i2c, gps}) {
      if (device->initialize()) {
        registerDeviceHAL(device);
      } else {
        qWarning() << "Failed to initialize device:" << device->getName();
      }
    }
  }

  m_initialized = true;
  qInfo() << "HALManager initialized successfully";
  emit initialized();

  return true;
}

void HALManager::shutdown() {
  QMutexLocker lock(&m_mutex);

  if (!m_initialized) {
    return;
  }

  // Shutdown all devices
  for (auto& device : m_deviceHALs) {
    device->shutdown();
  }
  m_deviceHALs.clear();

  // Shutdown vehicle HAL
  if (m_vehicleHAL) {
    m_vehicleHAL->shutdown();
  }

  // Shutdown host HAL
  if (m_hostHAL) {
    m_hostHAL->shutdown();
  }

  m_initialized = false;
  qInfo() << "HALManager shutdown complete";
  emit shutdown_signal();
}

/* ==================== Vehicle HAL ==================== */

void HALManager::setVehicleHAL(std::shared_ptr<VehicleHAL> hal) {
  QMutexLocker lock(&m_mutex);
  if (m_initialized) {
    qWarning() << "Cannot set Vehicle HAL after initialization";
    return;
  }
  m_vehicleHAL = hal;
}

QVariant HALManager::getVehicleProperty(VehiclePropertyType type) const {
  if (!m_vehicleHAL) {
    return QVariant();
  }
  return m_vehicleHAL->getProperty(type);
}

bool HALManager::setVehicleProperty(VehiclePropertyType type,
                                    const QVariant& value) {
  if (!m_vehicleHAL) {
    return false;
  }
  return m_vehicleHAL->setProperty(type, value);
}

void HALManager::subscribeToVehicleProperty(VehiclePropertyType type) {
  if (m_vehicleHAL) {
    m_vehicleHAL->subscribeToProperty(type);
  }
}

void HALManager::unsubscribeFromVehicleProperty(VehiclePropertyType type) {
  if (m_vehicleHAL) {
    m_vehicleHAL->unsubscribeFromProperty(type);
  }
}

/* ==================== Host HAL ==================== */

void HALManager::setHostHAL(std::shared_ptr<HostHAL> hal) {
  QMutexLocker lock(&m_mutex);
  if (m_initialized) {
    qWarning() << "Cannot set Host HAL after initialization";
    return;
  }
  m_hostHAL = hal;
}

QVariant HALManager::getHostProperty(HostPropertyType type) const {
  if (!m_hostHAL) {
    return QVariant();
  }
  return m_hostHAL->getProperty(type);
}

bool HALManager::setHostProperty(HostPropertyType type,
                                 const QVariant& value) {
  if (!m_hostHAL) {
    return false;
  }
  return m_hostHAL->setProperty(type, value);
}

void HALManager::subscribeToHostProperty(HostPropertyType type) {
  if (m_hostHAL) {
    m_hostHAL->subscribeToProperty(type);
  }
}

void HALManager::unsubscribeFromHostProperty(HostPropertyType type) {
  if (m_hostHAL) {
    m_hostHAL->unsubscribeFromProperty(type);
  }
}

/* ==================== Device HAL ==================== */

void HALManager::registerDeviceHAL(std::shared_ptr<DeviceHAL> device) {
  QMutexLocker lock(&m_mutex);
  m_deviceHALs.push_back(device);
  connectDeviceHAL(device);
  qDebug() << "Device registered:" << device->getName();
}

void HALManager::unregisterDeviceHAL(const QString& name) {
  QMutexLocker lock(&m_mutex);
  auto it =
      std::find_if(m_deviceHALs.begin(), m_deviceHALs.end(),
                   [&name](const auto& d) { return d->getName() == name; });
  if (it != m_deviceHALs.end()) {
    (*it)->shutdown();
    m_deviceHALs.erase(it);
    qDebug() << "Device unregistered:" << name;
  }
}

std::vector<std::shared_ptr<DeviceHAL>> HALManager::getDevices() const {
  QMutexLocker lock(&m_mutex);
  return m_deviceHALs;
}

std::shared_ptr<DeviceHAL> HALManager::getDevice(const QString& name) const {
  QMutexLocker lock(&m_mutex);
  for (const auto& device : m_deviceHALs) {
    if (device->getName() == name) {
      return device;
    }
  }
  return nullptr;
}

std::vector<std::shared_ptr<DeviceHAL>> HALManager::getDevicesByType(
    DeviceInterfaceType type) const {
  QMutexLocker lock(&m_mutex);
  std::vector<std::shared_ptr<DeviceHAL>> result;
  for (const auto& device : m_deviceHALs) {
    if (device->getType() == type) {
      result.push_back(device);
    }
  }
  return result;
}

/* ==================== Diagnostics ==================== */

QVariantMap HALManager::getDiagnostics() const {
  QMutexLocker lock(&m_mutex);
  QVariantMap diag;

  diag["initialized"] = m_initialized;
  diag["vehicle_hal"] = m_vehicleHAL ? m_vehicleHAL->getName() : "None";
  diag["host_hal"] = m_hostHAL ? m_hostHAL->getName() : "None";
  diag["device_count"] = static_cast<int>(m_deviceHALs.size());

  QVariantList deviceList;
  for (const auto& device : m_deviceHALs) {
    QVariantMap deviceInfo;
    deviceInfo["name"] = device->getName();
    deviceInfo["description"] = device->getDescription();
    deviceInfo["connected"] = device->isConnected();
    deviceList.append(deviceInfo);
  }
  diag["devices"] = deviceList;

  return diag;
}

QString HALManager::getStatusReport() const {
  QMutexLocker lock(&m_mutex);
  QString report;

  report += "=== HAL Manager Status ===\n";
  report += QString("Initialized: %1\n").arg(m_initialized ? "Yes" : "No");
  report += QString("Vehicle HAL: %1\n")
      .arg(m_vehicleHAL ? m_vehicleHAL->getName() : "None");
  report += QString("Host HAL: %1\n")
      .arg(m_hostHAL ? m_hostHAL->getName() : "None");
  report += QString("Device Count: %1\n").arg(m_deviceHALs.size());

  if (!m_deviceHALs.empty()) {
    report += "\nDevices:\n";
    for (const auto& device : m_deviceHALs) {
      auto status = device->getStatus();
      report += QString("  - %1: %2\n")
          .arg(device->getName(),
               status.state == DeviceState::ONLINE ? "ONLINE" : "OFFLINE");
    }
  }

  return report;
}

void HALManager::connectVehicleHAL() {
  if (!m_vehicleHAL) {
    return;
  }

  connect(m_vehicleHAL.get(), &VehicleHAL::propertyChanged, this,
          [this](VehiclePropertyType type, const QVariant& value) {
            emit vehiclePropertyChanged(type, value);
          });

  connect(m_vehicleHAL.get(), &VehicleHAL::errorOccurred, this,
          &HALManager::errorOccurred);
}

void HALManager::connectHostHAL() {
  if (!m_hostHAL) {
    return;
  }

  connect(m_hostHAL.get(), &HostHAL::propertyChanged, this,
          [this](HostPropertyType type, const QVariant& value) {
            emit hostPropertyChanged(type, value);
          });

  connect(m_hostHAL.get(), &HostHAL::errorOccurred, this,
          &HALManager::errorOccurred);
}

void HALManager::connectDeviceHAL(std::shared_ptr<DeviceHAL> device) {
  if (!device) {
    return;
  }

  connect(device.get(), &DeviceHAL::errorOccurred, this,
          &HALManager::errorOccurred);
}
