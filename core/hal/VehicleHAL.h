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
 * @brief Vehicle property types enumeration
 * 
 * Represents various vehicle properties that can be read and/or written.
 * Inspired by Android Automotive VehiclePropertyType.
 */
enum class VehiclePropertyType {
  /* Engine & Drivetrain */
  ENGINE_SPEED,              // RPM
  VEHICLE_SPEED,             // km/h
  FUEL_LEVEL,                // 0-100%
  FUEL_CAPACITY,             // Litres
  FUEL_TYPE,                 // String: Petrol, Diesel, Electric, Hybrid, etc.
  
  /* Engine Status */
  ENGINE_COOLANT_TEMP,       // Celsius
  ENGINE_OIL_TEMP,           // Celsius
  ENGINE_OIL_PRESSURE,       // Bar/PSI
  
  /* Transmission */
  GEAR_STATUS,               // PARK, REVERSE, NEUTRAL, DRIVE, SPORT, etc.
  GEAR_SELECTION,            // User-selected gear
  PARKING_BRAKE,             // ON/OFF
  
  /* Battery & Charging */
  BATTERY_LEVEL,             // 0-100% (EVs)
  BATTERY_VOLTAGE,           // Volts
  BATTERY_CURRENT,           // Amps
  CHARGING_STATE,            // NOT_CHARGING, CHARGING_DC, CHARGING_AC
  CHARGING_TIME_REMAINING,   // Minutes
  
  /* Environment */
  AMBIENT_AIR_TEMPERATURE,   // Celsius (external)
  CABIN_TEMPERATURE,         // Celsius (interior)
  
  /* Doors & Windows */
  DOOR_POS_FRONT_LEFT,       // OPEN/CLOSED/AJAR
  DOOR_POS_FRONT_RIGHT,      // OPEN/CLOSED/AJAR
  DOOR_POS_REAR_LEFT,        // OPEN/CLOSED/AJAR
  DOOR_POS_REAR_RIGHT,       // OPEN/CLOSED/AJAR
  WINDOW_POS_FRONT_LEFT,     // 0-100% (open percentage)
  WINDOW_POS_FRONT_RIGHT,    // 0-100%
  WINDOW_POS_REAR_LEFT,      // 0-100%
  WINDOW_POS_REAR_RIGHT,     // 0-100%
  
  /* Lighting */
  HEADLIGHTS,                // ON/OFF
  TAILLIGHTS,                // ON/OFF
  FOG_LIGHTS,                // ON/OFF
  TURN_SIGNAL_LEFT,          // ON/OFF
  TURN_SIGNAL_RIGHT,         // ON/OFF
  HAZARD_LIGHTS,             // ON/OFF
  
  /* Climate Control */
  AC_ON,                     // ON/OFF
  HVAC_FAN_SPEED,            // 0-100% or 1-10
  HVAC_POWER_ON,             // ON/OFF
  HVAC_SEAT_TEMPERATURE,     // -5 to 5 (cold to hot)
  
  /* Driving Assistance */
  CRUISE_CONTROL_STATE,      // OFF, ON, ACTIVE
  CRUISE_CONTROL_SPEED,      // km/h
  ABS_ACTIVE,                // ON/OFF
  STABILITY_CONTROL_ACTIVE,  // ON/OFF
  LANE_KEEP_ASSIST,          // ON/OFF
  
  /* Odometer */
  ODOMETER,                  // km/miles
  TRIP_DISTANCE,             // km/miles
  DISTANCE_TO_SERVICE,       // km
  
  /* Doors & Security */
  DOOR_LOCK_FRONT_LEFT,      // LOCKED/UNLOCKED
  DOOR_LOCK_FRONT_RIGHT,     // LOCKED/UNLOCKED
  DOOR_LOCK_REAR_LEFT,       // LOCKED/UNLOCKED
  DOOR_LOCK_REAR_RIGHT,      // LOCKED/UNLOCKED
  
  /* Navigation & Position */
  VEHICLE_HEADING,           // 0-359 degrees (magnetic north)
  VEHICLE_LATITUDE,          // Decimal degrees
  VEHICLE_LONGITUDE,         // Decimal degrees
  VEHICLE_ALTITUDE,          // Metres
  
  /* Driving Conditions */
  RAIN_DETECTED,             // YES/NO
  NIGHT_MODE,                // ON/OFF (based on light sensor)
  WIPERS_STATE,              // OFF, INTERMITTENT, SLOW, FAST
  WIPERS_SETTING,            // User setting
  
  /* Vehicle Info */
  VEHICLE_MAKE,              // Toyota, BMW, etc.
  VEHICLE_MODEL,             // Model name
  VEHICLE_YEAR,              // Year of manufacture
  VIN,                       // Vehicle Identification Number
};

/**
 * @brief Represents a vehicle property value
 */
struct VehiclePropertyValue {
  VehiclePropertyType type;
  QVariant value;
  qint64 timestamp;  // Milliseconds since epoch
  int32_t status;    // 0 = OK, >0 = Warning/Error
};

/**
 * @brief Vehicle HAL interface
 * 
 * Abstract base class for vehicle hardware abstraction layer.
 * Implementations provide access to vehicle properties.
 * 
 * Usage:
 *   auto hal = std::make_shared<MockVehicleHAL>();
 *   auto speed = hal->getProperty(VehiclePropertyType::VEHICLE_SPEED);
 *   hal->setPropertyListener(listener);
 */
class VehicleHAL : public QObject {
  Q_OBJECT
 public:
  explicit VehicleHAL(QObject* parent = nullptr);
  virtual ~VehicleHAL() = default;

  /**
   * @brief Get a vehicle property value
   * @param type The property type to retrieve
   * @return Property value, or invalid QVariant if property doesn't exist
   */
  virtual QVariant getProperty(VehiclePropertyType type) = 0;

  /**
   * @brief Set a vehicle property value (if writable)
   * @param type The property type to set
   * @param value The value to set
   * @return true if set successfully, false if read-only or invalid
   */
  virtual bool setProperty(VehiclePropertyType type, const QVariant& value) = 0;

  /**
   * @brief Check if a property is writable
   * @param type The property type
   * @return true if writable, false if read-only
   */
  virtual bool isPropertyWritable(VehiclePropertyType type) const = 0;

  /**
   * @brief Subscribe to property change notifications
   * @param type Property type to monitor
   * @note Implementations should emit propertyChanged signal when value updates
   */
  virtual void subscribeToProperty(VehiclePropertyType type) = 0;

  /**
   * @brief Unsubscribe from property change notifications
   * @param type Property type to stop monitoring
   */
  virtual void unsubscribeFromProperty(VehiclePropertyType type) = 0;

  /**
   * @brief Get HAL implementation name
   * @return Name like "MockVehicleHAL", "CanBusVehicleHAL", etc.
   */
  virtual QString getName() const = 0;

  /**
   * @brief Initialise the HAL
   * @return true if initialisation successful, false otherwise
   */
  virtual bool initialize() = 0;

  /**
   * @brief Shutdown the HAL gracefully
   */
  virtual void shutdown() = 0;

  /**
   * @brief Convert property type to human-readable string
   */
  static QString propertyTypeToString(VehiclePropertyType type);

  /**
   * @brief Convert property type from string
   */
  static VehiclePropertyType propertyTypeFromString(const QString& name);

 signals:
  /**
   * @brief Emitted when a vehicle property changes
   * @param type The property type that changed
   * @param value The new value
   */
  void propertyChanged(VehiclePropertyType type, const QVariant& value);

  /**
   * @brief Emitted when an error occurs
   * @param message Error description
   */
  void errorOccurred(const QString& message);

 protected:
  QMutex m_mutex;  // For thread-safe access
};
