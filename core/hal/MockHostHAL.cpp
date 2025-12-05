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

#include "MockHostHAL.h"

#include <QDateTime>
#include <QDebug>

MockHostHAL::MockHostHAL(QObject* parent)
    : HostHAL(parent) {
  connect(&m_updateTimer, &QTimer::timeout, this,
          &MockHostHAL::updateSimulation);
  initializeDefaults();
}

MockHostHAL::~MockHostHAL() {
  shutdown();
}

bool MockHostHAL::initialize() {
  m_updateTimer.start(1000);  // Update every second
  qDebug() << "MockHostHAL initialized";
  return true;
}

void MockHostHAL::shutdown() {
  m_updateTimer.stop();
  qDebug() << "MockHostHAL shutdown";
}

void MockHostHAL::initializeDefaults() {
  // System time (updated by timer)
  QDateTime now = QDateTime::currentDateTime();
  m_properties[HostPropertyType::SYSTEM_TIME_HOURS] = now.time().hour();
  m_properties[HostPropertyType::SYSTEM_TIME_MINUTES] = now.time().minute();
  m_properties[HostPropertyType::SYSTEM_TIME_SECONDS] = now.time().second();
  m_properties[HostPropertyType::SYSTEM_DATE_YEAR] = now.date().year();
  m_properties[HostPropertyType::SYSTEM_DATE_MONTH] = now.date().month();
  m_properties[HostPropertyType::SYSTEM_DATE_DAY] = now.date().day();

  // Device information
  m_properties[HostPropertyType::DEVICE_MODEL] = "Crankshaft System";
  m_properties[HostPropertyType::DEVICE_MANUFACTURER] = "OpenCarDev";
  m_properties[HostPropertyType::DEVICE_SERIAL_NUMBER] = "MOCK-0000-0001";
  m_properties[HostPropertyType::DEVICE_OS_VERSION] = "Linux 5.15";
  m_properties[HostPropertyType::DEVICE_FIRMWARE_VERSION] = "1.0.0-mock";

  // System resources
  m_properties[HostPropertyType::CPU_TEMPERATURE] = 65;
  m_properties[HostPropertyType::MEMORY_TOTAL] = 4096;  // MB
  m_properties[HostPropertyType::MEMORY_AVAILABLE] = 2048;
  m_properties[HostPropertyType::MEMORY_USED] = 2048;
  m_properties[HostPropertyType::STORAGE_TOTAL] = 32768;  // MB
  m_properties[HostPropertyType::STORAGE_AVAILABLE] = 16384;

  // Display
  m_properties[HostPropertyType::DISPLAY_BRIGHTNESS] = 80;
  m_properties[HostPropertyType::DISPLAY_BACKLIGHT] = "ON";
  m_properties[HostPropertyType::DISPLAY_RESOLUTION_WIDTH] = 1024;
  m_properties[HostPropertyType::DISPLAY_RESOLUTION_HEIGHT] = 600;
  m_properties[HostPropertyType::DISPLAY_DPI] = 96;

  // Audio
  m_properties[HostPropertyType::AUDIO_OUTPUT_VOLUME] = 75;
  m_properties[HostPropertyType::AUDIO_OUTPUT_MUTED] = "NO";
  m_properties[HostPropertyType::AUDIO_INPUT_ACTIVE] = "NO";

  // Connectivity
  m_properties[HostPropertyType::WIFI_ENABLED] = "YES";
  m_properties[HostPropertyType::WIFI_CONNECTED] = "YES";
  m_properties[HostPropertyType::WIFI_SSID] = "Crankshaft-Network";
  m_properties[HostPropertyType::WIFI_SIGNAL_STRENGTH] = 85;
  m_properties[HostPropertyType::BLUETOOTH_ENABLED] = "YES";
  m_properties[HostPropertyType::BLUETOOTH_CONNECTED] = "NO";
  m_properties[HostPropertyType::BLUETOOTH_DEVICE_COUNT] = 2;

  // GPS
  m_properties[HostPropertyType::GPS_ENABLED] = "YES";
  m_properties[HostPropertyType::GPS_STATUS] = "3D_FIX";
  m_properties[HostPropertyType::GPS_ACCURACY] = 5;

  // Power
  m_properties[HostPropertyType::BATTERY_HEALTH] = "GOOD";
  m_properties[HostPropertyType::USB_CONNECTED] = "NO";
  m_properties[HostPropertyType::CHARGING_ENABLED] = "NO";
  m_properties[HostPropertyType::POWER_STATE] = "ON";

  // Sensors
  m_properties[HostPropertyType::ACCELEROMETER_X] = 0.0;
  m_properties[HostPropertyType::ACCELEROMETER_Y] = 0.0;
  m_properties[HostPropertyType::ACCELEROMETER_Z] = 9.81;  // Gravity
  m_properties[HostPropertyType::LIGHT_SENSOR] = 500;      // Lux

  // System state
  m_properties[HostPropertyType::SYSTEM_UPTIME] = 3600;  // 1 hour
}

QVariant MockHostHAL::getProperty(HostPropertyType type) {
  QMutexLocker lock(&m_mutex);
  return m_properties.value(type, QVariant());
}

bool MockHostHAL::setProperty(HostPropertyType type,
                              const QVariant& value) {
  if (isPropertyWritable(type)) {
    QMutexLocker lock(&m_mutex);
    m_properties[type] = value;
    emit propertyChanged(type, value);
    return true;
  }
  return false;
}

bool MockHostHAL::isPropertyWritable(HostPropertyType type) const {
  switch (type) {
    case HostPropertyType::DISPLAY_BRIGHTNESS:
    case HostPropertyType::DISPLAY_BACKLIGHT:
    case HostPropertyType::AUDIO_OUTPUT_VOLUME:
    case HostPropertyType::AUDIO_OUTPUT_MUTED:
    case HostPropertyType::WIFI_ENABLED:
    case HostPropertyType::BLUETOOTH_ENABLED:
    case HostPropertyType::GPS_ENABLED:
    case HostPropertyType::CHARGING_ENABLED:
      return true;

    default:
      return false;
  }
}

void MockHostHAL::subscribeToProperty(HostPropertyType type) {
  QMutexLocker lock(&m_mutex);
  m_subscribers.insert(type);
}

void MockHostHAL::unsubscribeFromProperty(HostPropertyType type) {
  QMutexLocker lock(&m_mutex);
  m_subscribers.remove(type);
}

QString MockHostHAL::getName() const {
  return "MockHostHAL";
}

void MockHostHAL::updateSimulation() {
  QMutexLocker lock(&m_mutex);

  // Update system time
  QDateTime now = QDateTime::currentDateTime();
  m_properties[HostPropertyType::SYSTEM_TIME_HOURS] = now.time().hour();
  m_properties[HostPropertyType::SYSTEM_TIME_MINUTES] = now.time().minute();
  m_properties[HostPropertyType::SYSTEM_TIME_SECONDS] = now.time().second();

  // Increment uptime
  m_properties[HostPropertyType::SYSTEM_UPTIME] =
      m_properties[HostPropertyType::SYSTEM_UPTIME].toInt() + 1;

  // Slightly vary memory usage
  int memUsed =
      m_properties[HostPropertyType::MEMORY_USED].toInt();
  memUsed += (std::rand() % 20) - 10;  // -10 to +10 MB
  memUsed = qMax(1024, qMin(3500, memUsed));
  m_properties[HostPropertyType::MEMORY_USED] = memUsed;
  m_properties[HostPropertyType::MEMORY_AVAILABLE] = 4096 - memUsed;

  // Vary CPU temperature
  double cpuTemp = m_properties[HostPropertyType::CPU_TEMPERATURE].toDouble();
  cpuTemp += (std::rand() % 4) - 2;  // -2 to +2°C
  cpuTemp = qMax(50.0, qMin(85.0, cpuTemp));
  m_properties[HostPropertyType::CPU_TEMPERATURE] = cpuTemp;

  // Emit property changes for subscribers
  for (auto type : m_subscribers) {
    emit propertyChanged(type, m_properties[type]);
  }
}
