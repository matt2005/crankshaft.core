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

#include "VehicleHAL.h"

VehicleHAL::VehicleHAL(QObject* parent) : QObject(parent) {}

QString VehicleHAL::propertyTypeToString(VehiclePropertyType type) {
  static const QMap<VehiclePropertyType, QString> typeNames{
    {VehiclePropertyType::ENGINE_SPEED, "ENGINE_SPEED"},
    {VehiclePropertyType::VEHICLE_SPEED, "VEHICLE_SPEED"},
    {VehiclePropertyType::FUEL_LEVEL, "FUEL_LEVEL"},
    {VehiclePropertyType::FUEL_CAPACITY, "FUEL_CAPACITY"},
    {VehiclePropertyType::FUEL_TYPE, "FUEL_TYPE"},
    {VehiclePropertyType::ENGINE_COOLANT_TEMP, "ENGINE_COOLANT_TEMP"},
    {VehiclePropertyType::ENGINE_OIL_TEMP, "ENGINE_OIL_TEMP"},
    {VehiclePropertyType::ENGINE_OIL_PRESSURE, "ENGINE_OIL_PRESSURE"},
    {VehiclePropertyType::GEAR_STATUS, "GEAR_STATUS"},
    {VehiclePropertyType::GEAR_SELECTION, "GEAR_SELECTION"},
    {VehiclePropertyType::PARKING_BRAKE, "PARKING_BRAKE"},
    {VehiclePropertyType::BATTERY_LEVEL, "BATTERY_LEVEL"},
    {VehiclePropertyType::BATTERY_VOLTAGE, "BATTERY_VOLTAGE"},
    {VehiclePropertyType::BATTERY_CURRENT, "BATTERY_CURRENT"},
    {VehiclePropertyType::CHARGING_STATE, "CHARGING_STATE"},
    {VehiclePropertyType::CHARGING_TIME_REMAINING, "CHARGING_TIME_REMAINING"},
    {VehiclePropertyType::AMBIENT_AIR_TEMPERATURE, "AMBIENT_AIR_TEMPERATURE"},
    {VehiclePropertyType::CABIN_TEMPERATURE, "CABIN_TEMPERATURE"},
    {VehiclePropertyType::DOOR_POS_FRONT_LEFT, "DOOR_POS_FRONT_LEFT"},
    {VehiclePropertyType::DOOR_POS_FRONT_RIGHT, "DOOR_POS_FRONT_RIGHT"},
    {VehiclePropertyType::DOOR_POS_REAR_LEFT, "DOOR_POS_REAR_LEFT"},
    {VehiclePropertyType::DOOR_POS_REAR_RIGHT, "DOOR_POS_REAR_RIGHT"},
    {VehiclePropertyType::WINDOW_POS_FRONT_LEFT, "WINDOW_POS_FRONT_LEFT"},
    {VehiclePropertyType::WINDOW_POS_FRONT_RIGHT, "WINDOW_POS_FRONT_RIGHT"},
    {VehiclePropertyType::WINDOW_POS_REAR_LEFT, "WINDOW_POS_REAR_LEFT"},
    {VehiclePropertyType::WINDOW_POS_REAR_RIGHT, "WINDOW_POS_REAR_RIGHT"},
    {VehiclePropertyType::HEADLIGHTS, "HEADLIGHTS"},
    {VehiclePropertyType::TAILLIGHTS, "TAILLIGHTS"},
    {VehiclePropertyType::FOG_LIGHTS, "FOG_LIGHTS"},
    {VehiclePropertyType::TURN_SIGNAL_LEFT, "TURN_SIGNAL_LEFT"},
    {VehiclePropertyType::TURN_SIGNAL_RIGHT, "TURN_SIGNAL_RIGHT"},
    {VehiclePropertyType::HAZARD_LIGHTS, "HAZARD_LIGHTS"},
    {VehiclePropertyType::AC_ON, "AC_ON"},
    {VehiclePropertyType::HVAC_FAN_SPEED, "HVAC_FAN_SPEED"},
    {VehiclePropertyType::HVAC_POWER_ON, "HVAC_POWER_ON"},
    {VehiclePropertyType::HVAC_SEAT_TEMPERATURE, "HVAC_SEAT_TEMPERATURE"},
    {VehiclePropertyType::CRUISE_CONTROL_STATE, "CRUISE_CONTROL_STATE"},
    {VehiclePropertyType::CRUISE_CONTROL_SPEED, "CRUISE_CONTROL_SPEED"},
    {VehiclePropertyType::ABS_ACTIVE, "ABS_ACTIVE"},
    {VehiclePropertyType::STABILITY_CONTROL_ACTIVE, "STABILITY_CONTROL_ACTIVE"},
    {VehiclePropertyType::LANE_KEEP_ASSIST, "LANE_KEEP_ASSIST"},
    {VehiclePropertyType::ODOMETER, "ODOMETER"},
    {VehiclePropertyType::TRIP_DISTANCE, "TRIP_DISTANCE"},
    {VehiclePropertyType::DISTANCE_TO_SERVICE, "DISTANCE_TO_SERVICE"},
    {VehiclePropertyType::DOOR_LOCK_FRONT_LEFT, "DOOR_LOCK_FRONT_LEFT"},
    {VehiclePropertyType::DOOR_LOCK_FRONT_RIGHT, "DOOR_LOCK_FRONT_RIGHT"},
    {VehiclePropertyType::DOOR_LOCK_REAR_LEFT, "DOOR_LOCK_REAR_LEFT"},
    {VehiclePropertyType::DOOR_LOCK_REAR_RIGHT, "DOOR_LOCK_REAR_RIGHT"},
    {VehiclePropertyType::VEHICLE_HEADING, "VEHICLE_HEADING"},
    {VehiclePropertyType::VEHICLE_LATITUDE, "VEHICLE_LATITUDE"},
    {VehiclePropertyType::VEHICLE_LONGITUDE, "VEHICLE_LONGITUDE"},
    {VehiclePropertyType::VEHICLE_ALTITUDE, "VEHICLE_ALTITUDE"},
    {VehiclePropertyType::RAIN_DETECTED, "RAIN_DETECTED"},
    {VehiclePropertyType::NIGHT_MODE, "NIGHT_MODE"},
    {VehiclePropertyType::WIPERS_STATE, "WIPERS_STATE"},
    {VehiclePropertyType::WIPERS_SETTING, "WIPERS_SETTING"},
    {VehiclePropertyType::VEHICLE_MAKE, "VEHICLE_MAKE"},
    {VehiclePropertyType::VEHICLE_MODEL, "VEHICLE_MODEL"},
    {VehiclePropertyType::VEHICLE_YEAR, "VEHICLE_YEAR"},
    {VehiclePropertyType::VIN, "VIN"},
  };

  return typeNames.value(type, "UNKNOWN");
}

VehiclePropertyType VehicleHAL::propertyTypeFromString(const QString& name) {
  static const QMap<QString, VehiclePropertyType> typeMap{
    {"ENGINE_SPEED", VehiclePropertyType::ENGINE_SPEED},
    {"VEHICLE_SPEED", VehiclePropertyType::VEHICLE_SPEED},
    {"FUEL_LEVEL", VehiclePropertyType::FUEL_LEVEL},
    {"FUEL_CAPACITY", VehiclePropertyType::FUEL_CAPACITY},
    {"FUEL_TYPE", VehiclePropertyType::FUEL_TYPE},
    {"ENGINE_COOLANT_TEMP", VehiclePropertyType::ENGINE_COOLANT_TEMP},
    {"ENGINE_OIL_TEMP", VehiclePropertyType::ENGINE_OIL_TEMP},
    {"ENGINE_OIL_PRESSURE", VehiclePropertyType::ENGINE_OIL_PRESSURE},
    {"GEAR_STATUS", VehiclePropertyType::GEAR_STATUS},
    {"GEAR_SELECTION", VehiclePropertyType::GEAR_SELECTION},
    {"PARKING_BRAKE", VehiclePropertyType::PARKING_BRAKE},
    {"BATTERY_LEVEL", VehiclePropertyType::BATTERY_LEVEL},
    {"BATTERY_VOLTAGE", VehiclePropertyType::BATTERY_VOLTAGE},
    {"BATTERY_CURRENT", VehiclePropertyType::BATTERY_CURRENT},
    {"CHARGING_STATE", VehiclePropertyType::CHARGING_STATE},
    {"CHARGING_TIME_REMAINING", VehiclePropertyType::CHARGING_TIME_REMAINING},
    {"AMBIENT_AIR_TEMPERATURE", VehiclePropertyType::AMBIENT_AIR_TEMPERATURE},
    {"CABIN_TEMPERATURE", VehiclePropertyType::CABIN_TEMPERATURE},
    {"ODOMETER", VehiclePropertyType::ODOMETER},
    {"TRIP_DISTANCE", VehiclePropertyType::TRIP_DISTANCE},
  };

  return typeMap.value(name, VehiclePropertyType::VEHICLE_SPEED);
}
