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

#include "VehicleHAL.h"
#include "HostHAL.h"
#include "DeviceHAL.h"

#include <QObject>
#include <QRecursiveMutex>
#include <memory>
#include <vector>

/**
 * @brief Hardware Abstraction Layer Manager
 * 
 * Central orchestrator for all hardware abstraction layers.
 * Manages vehicle, host, and device HALs and coordinates property updates.
 * 
 * This is a singleton that should be initialized at application startup.
 * 
 * Usage:
 *   auto& manager = HALManager::instance();
 *   manager.initialize();
 *   
 *   // Get vehicle properties
 *   auto speed = manager.getVehicleProperty(VehiclePropertyType::VEHICLE_SPEED);
 *   
 *   // Subscribe to updates
 *   manager.subscribeToVehicleProperty(VehiclePropertyType::VEHICLE_SPEED, handler);
 *   
 *   // Shutdown when done
 *   manager.shutdown();
 */
class HALManager : public QObject {
  Q_OBJECT

 public:
  /**
   * @brief Get the singleton instance
   */
  static HALManager& instance();

  /**
   * @brief Initialize all HALs
   * @param useDeviceHALs If true, create default mock device HALs
   * @return true if all HALs initialized successfully
   */
  bool initialize(bool useDeviceHALs = true);

  /**
   * @brief Shutdown all HALs gracefully
   */
  void shutdown();

  /**
   * @brief Check if manager is initialized and running
   */
  bool isInitialized() const { return m_initialized; }

  /* ==================== Vehicle HAL ==================== */

  /**
   * @brief Set the vehicle HAL implementation
   * @note Should be called before initialize()
   */
  void setVehicleHAL(std::shared_ptr<VehicleHAL> hal);

  /**
   * @brief Get the vehicle HAL
   */
  std::shared_ptr<VehicleHAL> getVehicleHAL() const {
    return m_vehicleHAL;
  }

  /**
   * @brief Get a vehicle property
   */
  QVariant getVehicleProperty(VehiclePropertyType type) const;

  /**
   * @brief Set a vehicle property (if writable)
   */
  bool setVehicleProperty(VehiclePropertyType type, const QVariant& value);

  /**
   * @brief Subscribe to vehicle property changes
   */
  void subscribeToVehicleProperty(VehiclePropertyType type);

  /**
   * @brief Unsubscribe from vehicle property changes
   */
  void unsubscribeFromVehicleProperty(VehiclePropertyType type);

  /* ==================== Host HAL ==================== */

  /**
   * @brief Set the host HAL implementation
   * @note Should be called before initialize()
   */
  void setHostHAL(std::shared_ptr<HostHAL> hal);

  /**
   * @brief Get the host HAL
   */
  std::shared_ptr<HostHAL> getHostHAL() const {
    return m_hostHAL;
  }

  /**
   * @brief Get a host property
   */
  QVariant getHostProperty(HostPropertyType type) const;

  /**
   * @brief Set a host property (if writable)
   */
  bool setHostProperty(HostPropertyType type, const QVariant& value);

  /**
   * @brief Subscribe to host property changes
   */
  void subscribeToHostProperty(HostPropertyType type);

  /**
   * @brief Unsubscribe from host property changes
   */
  void unsubscribeFromHostProperty(HostPropertyType type);

  /* ==================== Device HAL ==================== */

  /**
   * @brief Register a device HAL
   */
  void registerDeviceHAL(std::shared_ptr<DeviceHAL> device);

  /**
   * @brief Unregister a device HAL
   */
  void unregisterDeviceHAL(const QString& name);

  /**
   * @brief Get all registered device HALs
   */
  std::vector<std::shared_ptr<DeviceHAL>> getDevices() const;

  /**
   * @brief Get a device HAL by name
   */
  std::shared_ptr<DeviceHAL> getDevice(const QString& name) const;

  /**
   * @brief Get all devices of a specific type
   */
  std::vector<std::shared_ptr<DeviceHAL>> getDevicesByType(
      DeviceInterfaceType type) const;

  /* ==================== Diagnostics ==================== */

  /**
   * @brief Get diagnostics information
   */
  QVariantMap getDiagnostics() const;

  /**
   * @brief Get status of all HALs
   */
  QString getStatusReport() const;

 signals:
  /**
   * @brief Emitted when a vehicle property changes
   */
  void vehiclePropertyChanged(VehiclePropertyType type, const QVariant& value);

  /**
   * @brief Emitted when a host property changes
   */
  void hostPropertyChanged(HostPropertyType type, const QVariant& value);

  /**
   * @brief Emitted when initialization completes
   */
  void initialized();

  /**
   * @brief Emitted when shutdown completes
   */
  void shutdown_signal();

  /**
   * @brief Emitted on error
   */
  void errorOccurred(const QString& message);

 private:
  explicit HALManager(QObject* parent = nullptr);
  ~HALManager() override;

  // Prevent copying
  HALManager(const HALManager&) = delete;
  HALManager& operator=(const HALManager&) = delete;

  void connectVehicleHAL();
  void connectHostHAL();
  void connectDeviceHAL(std::shared_ptr<DeviceHAL> device);

  // HAL instances
  std::shared_ptr<VehicleHAL> m_vehicleHAL;
  std::shared_ptr<HostHAL> m_hostHAL;
  std::vector<std::shared_ptr<DeviceHAL>> m_deviceHALs;

  // State
  mutable QRecursiveMutex m_mutex;
  bool m_initialized{false};
};
