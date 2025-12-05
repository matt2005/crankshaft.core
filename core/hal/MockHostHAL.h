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

#include "HostHAL.h"

#include <QTimer>
#include <QSet>

/**
 * @brief Mock host HAL for testing and development
 * 
 * Provides simulated host/system properties.
 * Useful for development without real system integration.
 */
class MockHostHAL : public HostHAL {
  Q_OBJECT
 public:
  explicit MockHostHAL(QObject* parent = nullptr);
  ~MockHostHAL() override;

  // HostHAL interface
  QVariant getProperty(HostPropertyType type) override;
  bool setProperty(HostPropertyType type, const QVariant& value) override;
  bool isPropertyWritable(HostPropertyType type) const override;
  void subscribeToProperty(HostPropertyType type) override;
  void unsubscribeFromProperty(HostPropertyType type) override;
  QString getName() const override;
  bool initialize() override;
  void shutdown() override;

 private slots:
  void updateSimulation();

 private:
  void initializeDefaults();

  QMap<HostPropertyType, QVariant> m_properties;
  QSet<HostPropertyType> m_subscribers;

  QTimer m_updateTimer;
  int m_updateCount{0};
};
