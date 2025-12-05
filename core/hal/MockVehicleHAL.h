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

#include <QTimer>
#include <QRandomGenerator>
#include <QSet>

/**
 * @brief Mock vehicle HAL for testing and development
 * 
 * Provides realistic simulated vehicle data with dynamic property updates.
 * Useful for development without hardware access.
 * 
 * Features:
 * - Simulated realistic vehicle state changes
 * - Dynamic values that update periodically
 * - Configurable simulation behaviour
 * - All vehicle properties available
 */
class MockVehicleHAL : public VehicleHAL {
  Q_OBJECT
 public:
  explicit MockVehicleHAL(QObject* parent = nullptr);
  ~MockVehicleHAL() override;

  // VehicleHAL interface
  QVariant getProperty(VehiclePropertyType type) override;
  bool setProperty(VehiclePropertyType type, const QVariant& value) override;
  bool isPropertyWritable(VehiclePropertyType type) const override;
  void subscribeToProperty(VehiclePropertyType type) override;
  void unsubscribeFromProperty(VehiclePropertyType type) override;
  QString getName() const override;
  bool initialize() override;
  void shutdown() override;

  /**
   * @brief Set simulation speed multiplier
   * @param speed 1.0 = normal, 2.0 = twice as fast, 0.5 = half speed
   */
  void setSimulationSpeed(float speed);

  /**
   * @brief Start/stop simulating driving
   */
  void setSimulateDriving(bool enabled);

  /**
   * @brief Get current simulation state
   */
  bool isSimulatingDriving() const { return m_simulateDriving; }

 private slots:
  void updateSimulation();

 private:
  /**
   * @brief Initialise property defaults
   */
  void initializeDefaults();

  /**
   * @brief Simulate vehicle driving state
   */
  void simulateDrivingState();

  /**
   * @brief Generate realistic speed variations
   */
  void updateSpeedProfile();

  // Property storage
  QMap<VehiclePropertyType, QVariant> m_properties;
  QSet<VehiclePropertyType> m_subscribers;

  // Simulation state
  QTimer m_updateTimer;
  float m_simulationSpeed{1.0f};
  bool m_simulateDriving{true};
  int m_updateCount{0};

  // Driving simulation parameters
  float m_currentSpeed{0.0f};
  float m_targetSpeed{50.0f};
  float m_acceleration{0.5f};
  bool m_accelerating{true};
  int m_speedChangeCounter{0};
};
