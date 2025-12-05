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

#include "HostHAL.h"

HostHAL::HostHAL(QObject* parent) : QObject(parent) {}

QString HostHAL::propertyTypeToString(HostPropertyType type) {
  static const QMap<HostPropertyType, QString> typeNames{
    {HostPropertyType::SYSTEM_TIME_HOURS, "SYSTEM_TIME_HOURS"},
    {HostPropertyType::SYSTEM_TIME_MINUTES, "SYSTEM_TIME_MINUTES"},
    {HostPropertyType::SYSTEM_TIME_SECONDS, "SYSTEM_TIME_SECONDS"},
    {HostPropertyType::SYSTEM_DATE_YEAR, "SYSTEM_DATE_YEAR"},
    {HostPropertyType::SYSTEM_DATE_MONTH, "SYSTEM_DATE_MONTH"},
    {HostPropertyType::SYSTEM_DATE_DAY, "SYSTEM_DATE_DAY"},
    {HostPropertyType::DEVICE_MODEL, "DEVICE_MODEL"},
    {HostPropertyType::DEVICE_MANUFACTURER, "DEVICE_MANUFACTURER"},
    {HostPropertyType::DEVICE_SERIAL_NUMBER, "DEVICE_SERIAL_NUMBER"},
    {HostPropertyType::DEVICE_BUILD_FINGERPRINT, "DEVICE_BUILD_FINGERPRINT"},
    {HostPropertyType::DEVICE_OS_VERSION, "DEVICE_OS_VERSION"},
    {HostPropertyType::DEVICE_FIRMWARE_VERSION, "DEVICE_FIRMWARE_VERSION"},
    {HostPropertyType::CPU_TEMPERATURE, "CPU_TEMPERATURE"},
    {HostPropertyType::GPU_TEMPERATURE, "GPU_TEMPERATURE"},
    {HostPropertyType::MEMORY_TOTAL, "MEMORY_TOTAL"},
    {HostPropertyType::MEMORY_AVAILABLE, "MEMORY_AVAILABLE"},
    {HostPropertyType::MEMORY_USED, "MEMORY_USED"},
    {HostPropertyType::STORAGE_TOTAL, "STORAGE_TOTAL"},
    {HostPropertyType::STORAGE_AVAILABLE, "STORAGE_AVAILABLE"},
    {HostPropertyType::DISPLAY_BRIGHTNESS, "DISPLAY_BRIGHTNESS"},
    {HostPropertyType::DISPLAY_BACKLIGHT, "DISPLAY_BACKLIGHT"},
    {HostPropertyType::DISPLAY_RESOLUTION_WIDTH, "DISPLAY_RESOLUTION_WIDTH"},
    {HostPropertyType::DISPLAY_RESOLUTION_HEIGHT, "DISPLAY_RESOLUTION_HEIGHT"},
    {HostPropertyType::DISPLAY_DPI, "DISPLAY_DPI"},
    {HostPropertyType::AUDIO_OUTPUT_VOLUME, "AUDIO_OUTPUT_VOLUME"},
    {HostPropertyType::AUDIO_OUTPUT_MUTED, "AUDIO_OUTPUT_MUTED"},
    {HostPropertyType::AUDIO_INPUT_ACTIVE, "AUDIO_INPUT_ACTIVE"},
    {HostPropertyType::WIFI_ENABLED, "WIFI_ENABLED"},
    {HostPropertyType::WIFI_CONNECTED, "WIFI_CONNECTED"},
    {HostPropertyType::WIFI_SSID, "WIFI_SSID"},
    {HostPropertyType::WIFI_SIGNAL_STRENGTH, "WIFI_SIGNAL_STRENGTH"},
    {HostPropertyType::BLUETOOTH_ENABLED, "BLUETOOTH_ENABLED"},
    {HostPropertyType::BLUETOOTH_CONNECTED, "BLUETOOTH_CONNECTED"},
    {HostPropertyType::BLUETOOTH_DEVICE_COUNT, "BLUETOOTH_DEVICE_COUNT"},
    {HostPropertyType::CELLULAR_SIGNAL_STRENGTH, "CELLULAR_SIGNAL_STRENGTH"},
    {HostPropertyType::CELLULAR_NETWORK_TYPE, "CELLULAR_NETWORK_TYPE"},
    {HostPropertyType::GPS_ENABLED, "GPS_ENABLED"},
    {HostPropertyType::GPS_STATUS, "GPS_STATUS"},
    {HostPropertyType::GPS_ACCURACY, "GPS_ACCURACY"},
    {HostPropertyType::BATTERY_HEALTH, "BATTERY_HEALTH"},
    {HostPropertyType::USB_CONNECTED, "USB_CONNECTED"},
    {HostPropertyType::CHARGING_ENABLED, "CHARGING_ENABLED"},
    {HostPropertyType::POWER_STATE, "POWER_STATE"},
    {HostPropertyType::ACCELEROMETER_X, "ACCELEROMETER_X"},
    {HostPropertyType::ACCELEROMETER_Y, "ACCELEROMETER_Y"},
    {HostPropertyType::ACCELEROMETER_Z, "ACCELEROMETER_Z"},
    {HostPropertyType::GYROSCOPE_X, "GYROSCOPE_X"},
    {HostPropertyType::GYROSCOPE_Y, "GYROSCOPE_Y"},
    {HostPropertyType::GYROSCOPE_Z, "GYROSCOPE_Z"},
    {HostPropertyType::COMPASS_HEADING, "COMPASS_HEADING"},
    {HostPropertyType::LIGHT_SENSOR, "LIGHT_SENSOR"},
    {HostPropertyType::SYSTEM_UPTIME, "SYSTEM_UPTIME"},
    {HostPropertyType::SYSTEM_LOAD_AVERAGE, "SYSTEM_LOAD_AVERAGE"},
  };

  return typeNames.value(type, "UNKNOWN");
}

HostPropertyType HostHAL::propertyTypeFromString(const QString& name) {
  static const QMap<QString, HostPropertyType> typeMap{
    {"SYSTEM_TIME_HOURS", HostPropertyType::SYSTEM_TIME_HOURS},
    {"SYSTEM_TIME_MINUTES", HostPropertyType::SYSTEM_TIME_MINUTES},
    {"SYSTEM_TIME_SECONDS", HostPropertyType::SYSTEM_TIME_SECONDS},
    {"SYSTEM_DATE_YEAR", HostPropertyType::SYSTEM_DATE_YEAR},
    {"SYSTEM_DATE_MONTH", HostPropertyType::SYSTEM_DATE_MONTH},
    {"SYSTEM_DATE_DAY", HostPropertyType::SYSTEM_DATE_DAY},
    {"DEVICE_MODEL", HostPropertyType::DEVICE_MODEL},
    {"DEVICE_MANUFACTURER", HostPropertyType::DEVICE_MANUFACTURER},
    {"DEVICE_SERIAL_NUMBER", HostPropertyType::DEVICE_SERIAL_NUMBER},
    {"BATTERY_HEALTH", HostPropertyType::BATTERY_HEALTH},
    {"USB_CONNECTED", HostPropertyType::USB_CONNECTED},
    {"CHARGING_ENABLED", HostPropertyType::CHARGING_ENABLED},
    {"POWER_STATE", HostPropertyType::POWER_STATE},
    {"DISPLAY_BRIGHTNESS", HostPropertyType::DISPLAY_BRIGHTNESS},
    {"AUDIO_OUTPUT_VOLUME", HostPropertyType::AUDIO_OUTPUT_VOLUME},
    {"WIFI_ENABLED", HostPropertyType::WIFI_ENABLED},
    {"BLUETOOTH_ENABLED", HostPropertyType::BLUETOOTH_ENABLED},
    {"GPS_ENABLED", HostPropertyType::GPS_ENABLED},
  };

  return typeMap.value(name, HostPropertyType::SYSTEM_TIME_HOURS);
}
