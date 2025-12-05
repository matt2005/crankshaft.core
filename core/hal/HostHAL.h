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
 * @brief Host/system property types enumeration
 * 
 * Represents system and device properties that are not vehicle-specific.
 */
enum class HostPropertyType {
  /* System Time & Date */
  SYSTEM_TIME_HOURS,         // 0-23
  SYSTEM_TIME_MINUTES,       // 0-59
  SYSTEM_TIME_SECONDS,       // 0-59
  SYSTEM_DATE_YEAR,          // YYYY
  SYSTEM_DATE_MONTH,         // 1-12
  SYSTEM_DATE_DAY,           // 1-31
  
  /* Device Information */
  DEVICE_MODEL,              // Device model name
  DEVICE_MANUFACTURER,       // Manufacturer
  DEVICE_SERIAL_NUMBER,      // Serial number
  DEVICE_BUILD_FINGERPRINT,  // Build identification
  DEVICE_OS_VERSION,         // OS/Kernel version
  DEVICE_FIRMWARE_VERSION,   // Firmware version
  
  /* System Resources */
  CPU_TEMPERATURE,           // Celsius
  GPU_TEMPERATURE,           // Celsius
  MEMORY_TOTAL,              // MB
  MEMORY_AVAILABLE,          // MB
  MEMORY_USED,               // MB
  STORAGE_TOTAL,             // MB
  STORAGE_AVAILABLE,         // MB
  
  /* Display */
  DISPLAY_BRIGHTNESS,        // 0-100%
  DISPLAY_BACKLIGHT,         // ON/OFF
  DISPLAY_RESOLUTION_WIDTH,  // Pixels
  DISPLAY_RESOLUTION_HEIGHT, // Pixels
  DISPLAY_DPI,               // Dots per inch
  
  /* Audio */
  AUDIO_OUTPUT_VOLUME,       // 0-100%
  AUDIO_OUTPUT_MUTED,        // YES/NO
  AUDIO_INPUT_ACTIVE,        // YES/NO (microphone)
  
  /* Connectivity */
  WIFI_ENABLED,              // YES/NO
  WIFI_CONNECTED,            // YES/NO
  WIFI_SSID,                 // Network name
  WIFI_SIGNAL_STRENGTH,      // 0-100%
  BLUETOOTH_ENABLED,         // YES/NO
  BLUETOOTH_CONNECTED,       // YES/NO
  BLUETOOTH_DEVICE_COUNT,    // Number of paired devices
  CELLULAR_SIGNAL_STRENGTH,  // 0-100% or RSSI
  CELLULAR_NETWORK_TYPE,     // 2G/3G/4G/5G/LTE
  
  /* GPS/Location */
  GPS_ENABLED,               // YES/NO
  GPS_STATUS,                // NO_FIX, 2D_FIX, 3D_FIX
  GPS_ACCURACY,              // Metres
  
  /* Power Management */
  BATTERY_HEALTH,            // GOOD, WARM, OVERHEAT, DEAD, UNKNOWN
  USB_CONNECTED,             // YES/NO
  CHARGING_ENABLED,          // YES/NO
  POWER_STATE,               // ON, SUSPEND, HIBERNATE
  
  /* Sensors */
  ACCELEROMETER_X,           // m/s²
  ACCELEROMETER_Y,           // m/s²
  ACCELEROMETER_Z,           // m/s²
  GYROSCOPE_X,               // rad/s
  GYROSCOPE_Y,               // rad/s
  GYROSCOPE_Z,               // rad/s
  COMPASS_HEADING,           // 0-359 degrees
  LIGHT_SENSOR,              // Lux
  
  /* System State */
  SYSTEM_UPTIME,             // Seconds
  SYSTEM_LOAD_AVERAGE,       // CPU load
};

/**
 * @brief Host HAL interface
 * 
 * Abstract base class for host/system hardware abstraction layer.
 * Provides access to system properties independent of the vehicle.
 */
class HostHAL : public QObject {
  Q_OBJECT
 public:
  explicit HostHAL(QObject* parent = nullptr);
  virtual ~HostHAL() = default;

  /**
   * @brief Get a host property value
   * @param type The property type to retrieve
   * @return Property value, or invalid QVariant if property doesn't exist
   */
  virtual QVariant getProperty(HostPropertyType type) = 0;

  /**
   * @brief Set a host property value (if writable)
   * @param type The property type to set
   * @param value The value to set
   * @return true if set successfully, false if read-only or invalid
   */
  virtual bool setProperty(HostPropertyType type, const QVariant& value) = 0;

  /**
   * @brief Check if a property is writable
   * @param type The property type
   * @return true if writable, false if read-only
   */
  virtual bool isPropertyWritable(HostPropertyType type) const = 0;

  /**
   * @brief Subscribe to property change notifications
   * @param type Property type to monitor
   */
  virtual void subscribeToProperty(HostPropertyType type) = 0;

  /**
   * @brief Unsubscribe from property change notifications
   * @param type Property type to stop monitoring
   */
  virtual void unsubscribeFromProperty(HostPropertyType type) = 0;

  /**
   * @brief Get HAL implementation name
   * @return Name like "MockHostHAL", "LinuxHostHAL", etc.
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
  static QString propertyTypeToString(HostPropertyType type);

  /**
   * @brief Convert property type from string
   */
  static HostPropertyType propertyTypeFromString(const QString& name);

 signals:
  /**
   * @brief Emitted when a host property changes
   * @param type The property type that changed
   * @param value The new value
   */
  void propertyChanged(HostPropertyType type, const QVariant& value);

  /**
   * @brief Emitted when an error occurs
   * @param message Error description
   */
  void errorOccurred(const QString& message);

 protected:
  QMutex m_mutex;  // For thread-safe access
};
