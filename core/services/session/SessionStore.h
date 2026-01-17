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
#include <QVariantMap>
#include <memory>

class QSqlDatabase;

/**
 * @brief SQLite-backed session and Android device metadata store
 *
 * Persists AndroidDevice and Session entities to enable reconnection tracking,
 * diagnostics, and lifecycle management for Android Auto connections.
 */
class SessionStore : public QObject {
  Q_OBJECT

 public:
  explicit SessionStore(const QString& dbPath = QString(), QObject* parent = nullptr);
  ~SessionStore() override;

  // Initialize database and schema
  [[nodiscard]] auto initialize() -> bool;

  // AndroidDevice operations
  [[nodiscard]] auto createDevice(const QString& deviceId, const QVariantMap& deviceInfo) -> bool;
  [[nodiscard]] QVariantMap getDevice(const QString& deviceId) const;
  [[nodiscard]] QList<QVariantMap> getAllDevices() const;
  [[nodiscard]] auto updateDeviceLastSeen(const QString& deviceId) -> bool;
  [[nodiscard]] auto deleteDevice(const QString& deviceId) -> bool;

  // Session operations
  [[nodiscard]] auto createSession(const QString& sessionId, const QString& deviceId,
                                   const QString& initialState) -> bool;
  [[nodiscard]] QVariantMap getSession(const QString& sessionId) const;
  [[nodiscard]] QVariantMap getSessionByDevice(const QString& deviceId) const;
  [[nodiscard]] auto updateSessionState(const QString& sessionId, const QString& newState) -> bool;
  [[nodiscard]] auto updateSessionHeartbeat(const QString& sessionId) -> bool;
  [[nodiscard]] auto endSession(const QString& sessionId) -> bool;

 private:
  [[nodiscard]] auto createSchema() -> bool;

  std::unique_ptr<QSqlDatabase> m_db;
  QString m_dbPath;
};
