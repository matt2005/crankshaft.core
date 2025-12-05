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

#include "MockVehicleHAL.h"

#include <QDateTime>
#include <QDebug>

MockVehicleHAL::MockVehicleHAL(QObject* parent)
    : VehicleHAL(parent) {
  connect(&m_updateTimer, &QTimer::timeout, this,
          &MockVehicleHAL::updateSimulation);
  initializeDefaults();
}

MockVehicleHAL::~MockVehicleHAL() {
  shutdown();
}

bool MockVehicleHAL::initialize() {
  m_updateTimer.start(500);  // Update every 500ms
  qDebug() << "MockVehicleHAL initialized";
  return true;
}

void MockVehicleHAL::shutdown() {
  m_updateTimer.stop();
  qDebug() << "MockVehicleHAL shutdown";
}

void MockVehicleHAL::initializeDefaults() {
  // Vehicle identification
  m_properties[VehiclePropertyType::VEHICLE_MAKE] = "Crankshaft";
  m_properties[VehiclePropertyType::VEHICLE_MODEL] = "Mock Edition";
  m_properties[VehiclePropertyType::VEHICLE_YEAR] = 2025;
  m_properties[VehiclePropertyType::VIN] = "MOCK000000000001";
  m_properties[VehiclePropertyType::FUEL_TYPE] = "Petrol";
  m_properties[VehiclePropertyType::FUEL_CAPACITY] = 60;

  // Current state - parked
  m_properties[VehiclePropertyType::VEHICLE_SPEED] = 0.0;
  m_properties[VehiclePropertyType::ENGINE_SPEED] = 0;
  m_properties[VehiclePropertyType::GEAR_STATUS] = "PARK";
  m_properties[VehiclePropertyType::PARKING_BRAKE] = "ON";
  m_properties[VehiclePropertyType::FUEL_LEVEL] = 75;

  // Engine
  m_properties[VehiclePropertyType::ENGINE_COOLANT_TEMP] = 90;
  m_properties[VehiclePropertyType::ENGINE_OIL_TEMP] = 85;
  m_properties[VehiclePropertyType::ENGINE_OIL_PRESSURE] = 4.5;

  // Environment
  m_properties[VehiclePropertyType::AMBIENT_AIR_TEMPERATURE] = 22;
  m_properties[VehiclePropertyType::CABIN_TEMPERATURE] = 21;

  // Doors
  m_properties[VehiclePropertyType::DOOR_POS_FRONT_LEFT] = "CLOSED";
  m_properties[VehiclePropertyType::DOOR_POS_FRONT_RIGHT] = "CLOSED";
  m_properties[VehiclePropertyType::DOOR_POS_REAR_LEFT] = "CLOSED";
  m_properties[VehiclePropertyType::DOOR_POS_REAR_RIGHT] = "CLOSED";

  // Lights
  m_properties[VehiclePropertyType::HEADLIGHTS] = "OFF";
  m_properties[VehiclePropertyType::TAILLIGHTS] = "OFF";
  m_properties[VehiclePropertyType::HAZARD_LIGHTS] = "OFF";

  // Climate
  m_properties[VehiclePropertyType::AC_ON] = "ON";
  m_properties[VehiclePropertyType::HVAC_FAN_SPEED] = 50;
  m_properties[VehiclePropertyType::HVAC_POWER_ON] = "ON";

  // Distance
  m_properties[VehiclePropertyType::ODOMETER] = 15234;
  m_properties[VehiclePropertyType::TRIP_DISTANCE] = 0;

  // Location
  m_properties[VehiclePropertyType::VEHICLE_LATITUDE] = 40.7128;
  m_properties[VehiclePropertyType::VEHICLE_LONGITUDE] = -74.0060;
  m_properties[VehiclePropertyType::VEHICLE_HEADING] = 180;

  // Safety
  m_properties[VehiclePropertyType::ABS_ACTIVE] = "OFF";
  m_properties[VehiclePropertyType::STABILITY_CONTROL_ACTIVE] = "OFF";

  // Misc
  m_properties[VehiclePropertyType::WIPERS_STATE] = "OFF";
  m_properties[VehiclePropertyType::RAIN_DETECTED] = "NO";
}

QVariant MockVehicleHAL::getProperty(VehiclePropertyType type) {
  QMutexLocker lock(&m_mutex);
  return m_properties.value(type, QVariant());
}

bool MockVehicleHAL::setProperty(VehiclePropertyType type,
                                 const QVariant& value) {
  if (isPropertyWritable(type)) {
    QMutexLocker lock(&m_mutex);
    m_properties[type] = value;
    emit propertyChanged(type, value);
    return true;
  }
  return false;
}

bool MockVehicleHAL::isPropertyWritable(VehiclePropertyType type) const {
  // Only certain properties are user-writable
  switch (type) {
    // User controllable
    case VehiclePropertyType::AC_ON:
    case VehiclePropertyType::HVAC_FAN_SPEED:
    case VehiclePropertyType::HVAC_POWER_ON:
    case VehiclePropertyType::HVAC_SEAT_TEMPERATURE:
    case VehiclePropertyType::CRUISE_CONTROL_STATE:
    case VehiclePropertyType::CRUISE_CONTROL_SPEED:
    case VehiclePropertyType::HEADLIGHTS:
    case VehiclePropertyType::TAILLIGHTS:
    case VehiclePropertyType::FOG_LIGHTS:
    case VehiclePropertyType::HAZARD_LIGHTS:
    case VehiclePropertyType::WIPERS_SETTING:
    case VehiclePropertyType::GEAR_SELECTION:
    case VehiclePropertyType::PARKING_BRAKE:
    case VehiclePropertyType::DOOR_LOCK_FRONT_LEFT:
    case VehiclePropertyType::DOOR_LOCK_FRONT_RIGHT:
    case VehiclePropertyType::DOOR_LOCK_REAR_LEFT:
    case VehiclePropertyType::DOOR_LOCK_REAR_RIGHT:
      return true;

    default:
      return false;  // Most properties are read-only
  }
}

void MockVehicleHAL::subscribeToProperty(VehiclePropertyType type) {
  QMutexLocker lock(&m_mutex);
  m_subscribers.insert(type);
}

void MockVehicleHAL::unsubscribeFromProperty(VehiclePropertyType type) {
  QMutexLocker lock(&m_mutex);
  m_subscribers.remove(type);
}

QString MockVehicleHAL::getName() const {
  return "MockVehicleHAL";
}

void MockVehicleHAL::setSimulationSpeed(float speed) {
  m_simulationSpeed = qMax(0.1f, speed);
  m_updateTimer.setInterval(static_cast<int>(500 / m_simulationSpeed));
}

void MockVehicleHAL::setSimulateDriving(bool enabled) {
  m_simulateDriving = enabled;
}

void MockVehicleHAL::updateSimulation() {
  QMutexLocker lock(&m_mutex);

  if (!m_simulateDriving) {
    return;
  }

  m_updateCount++;

  // Update simulation every 2 cycles (every second in real time)
  if (m_updateCount % 2 == 0) {
    simulateDrivingState();
  }

  // Emit property changes for subscribers
  for (auto type : m_subscribers) {
    emit propertyChanged(type, m_properties[type]);
  }
}

void MockVehicleHAL::simulateDrivingState() {
  // Simulate starting/stopping driving
  float currentSpeed =
      m_properties[VehiclePropertyType::VEHICLE_SPEED].toFloat();

  m_speedChangeCounter++;

  // Every 50 updates (~25 seconds), change driving mode
  if (m_speedChangeCounter > 50) {
    m_speedChangeCounter = 0;
    m_accelerating = !m_accelerating;

    if (m_accelerating) {
      m_targetSpeed = QRandomGenerator::global()->bounded(60, 120);
      m_properties[VehiclePropertyType::PARKING_BRAKE] = "OFF";
      m_properties[VehiclePropertyType::GEAR_STATUS] = "DRIVE";
    } else {
      m_targetSpeed = 0.0f;
      m_properties[VehiclePropertyType::PARKING_BRAKE] = "ON";
      m_properties[VehiclePropertyType::GEAR_STATUS] = "PARK";
    }
  }

  // Smoothly accelerate/decelerate to target speed
  if (currentSpeed < m_targetSpeed) {
    currentSpeed += m_acceleration;
    if (currentSpeed > m_targetSpeed) {
      currentSpeed = m_targetSpeed;
    }
  } else if (currentSpeed > m_targetSpeed) {
    currentSpeed -= m_acceleration * 1.5f;  // Brake harder
    if (currentSpeed < m_targetSpeed) {
      currentSpeed = m_targetSpeed;
    }
  }

  m_properties[VehiclePropertyType::VEHICLE_SPEED] = currentSpeed;

  // Update RPM based on speed
  int rpm = static_cast<int>(currentSpeed * 50);  // Simplified RPM calc
  m_properties[VehiclePropertyType::ENGINE_SPEED] = rpm;

  // Update odometer
  double odometer =
      m_properties[VehiclePropertyType::ODOMETER].toDouble();
  odometer += (currentSpeed / 3600.0) * 0.5;  // Update every 500ms
  m_properties[VehiclePropertyType::ODOMETER] = odometer;

  // Update trip distance
  double tripDistance =
      m_properties[VehiclePropertyType::TRIP_DISTANCE].toDouble();
  tripDistance += (currentSpeed / 3600.0) * 0.5;
  m_properties[VehiclePropertyType::TRIP_DISTANCE] = tripDistance;

  // Update fuel level (consume 0.001% per second at max speed)
  double fuelLevel =
      m_properties[VehiclePropertyType::FUEL_LEVEL].toDouble();
  fuelLevel -= (currentSpeed / 200.0) * 0.01;  // Consumption rate
  if (fuelLevel < 0) fuelLevel = 0;
  m_properties[VehiclePropertyType::FUEL_LEVEL] =
      qMax(0.0, fuelLevel);

  // Update cabin temperature (slowly changes)
  double cabinTemp =
      m_properties[VehiclePropertyType::CABIN_TEMPERATURE].toDouble();
  double ambientTemp =
      m_properties[VehiclePropertyType::AMBIENT_AIR_TEMPERATURE].toDouble();
  cabinTemp += (ambientTemp - cabinTemp) * 0.01;
  m_properties[VehiclePropertyType::CABIN_TEMPERATURE] = cabinTemp;

  // Random slight variations in engine temp
  double engineTemp =
      m_properties[VehiclePropertyType::ENGINE_COOLANT_TEMP].toDouble();
  engineTemp += QRandomGenerator::global()->bounded(-1, 2);
  engineTemp = qMax(85.0, qMin(110.0, engineTemp));
  m_properties[VehiclePropertyType::ENGINE_COOLANT_TEMP] = engineTemp;

  // Update location (simulate driving in a circle)
  static double angle = 0;
  angle += (currentSpeed / 100.0) * 0.1;
  double lat = 40.7128 + sin(angle) * 0.01;
  double lon = -74.0060 + cos(angle) * 0.01;
  m_properties[VehiclePropertyType::VEHICLE_LATITUDE] = lat;
  m_properties[VehiclePropertyType::VEHICLE_LONGITUDE] = lon;
  m_properties[VehiclePropertyType::VEHICLE_HEADING] =
      static_cast<int>(angle * 180 / 3.14159);
}
