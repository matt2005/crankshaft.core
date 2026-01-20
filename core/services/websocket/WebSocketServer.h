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

#include <QList>
#include <QObject>
#include <QSslConfiguration>
#include <QWebSocket>
#include <QWebSocketServer>

// Forward declarations
class ServiceManager;

#include "../android_auto/AndroidAutoService.h"

/**
 * @brief WebSocket server for real-time event communication
 *
 * Provides:
 * - Pub/Sub messaging between QML UI and backend services
 * - SSL/TLS support for secure connections (wss://)
 * - Automatic service event relay (AndroidAuto, Preferences, etc.)
 * - Message validation and error handling
 *
 * @note Thread-safe for event emission; connections must be made from same thread as server creation
 */
class WebSocketServer : public QObject {
  Q_OBJECT

 public:
  /**
   * @brief Construct WebSocket server on specified port
   * @param port Port number to listen on (e.g. 8080)
   * @param parent Qt parent object
   */
  explicit WebSocketServer(quint16 port, QObject* parent = nullptr);
  ~WebSocketServer() override;

  /**
   * @brief Broadcast an event to all subscribed clients
   * @param topic Event topic (e.g. "android_auto/state_changed")
   * @param payload JSON object containing event data
   * @see Topic naming convention: "service/event_name"
   */
  void broadcastEvent(const QString& topic, const QVariantMap& payload);

  /**
   * @brief Check if server is actively listening for connections
   * @return true if server is bound and listening
   */
  [[nodiscard]] auto isListening() const -> bool;

  /**
   * @brief Enable SSL/TLS for secure connections (wss://)
   * @param certificatePath Path to PEM-encoded certificate file
   * @param keyPath Path to PEM-encoded private key file
   * @note Must be called before starting server
   */
  void enableSecureMode(const QString& certificatePath, const QString& keyPath);

  /**
   * @brief Check if secure mode (SSL/TLS) is enabled
   * @return true if wss:// connections are supported
   */
  [[nodiscard]] auto isSecureModeEnabled() const -> bool;

  /**
   * @brief Inject service manager for event relay
   * @param serviceManager Pointer to application ServiceManager
   * @note Must be called before initializeServiceConnections()
   */
  void setServiceManager(ServiceManager* serviceManager);

  /**
   * @brief Connect to all service signals for event forwarding
   * @note Call after all services are started and serviceManager is set
   */
  void initializeServiceConnections();

 private slots:
  /// Emitted when a new client connects; initializes event subscriptions
  void onNewConnection();
  /// Processes incoming message from a connected client
  void onTextMessageReceived(const QString& message);
  /// Cleanup when client disconnects; removes subscriptions
  void onClientDisconnected();

  /// Relay: AndroidAuto connection state changed
  void onAndroidAutoStateChanged(int state);
  /// Relay: AndroidAuto device connected successfully
  void onAndroidAutoConnected(const QVariantMap& device);
  /// Relay: AndroidAuto device disconnected
  void onAndroidAutoDisconnected();
  /// Relay: AndroidAuto service error occurred
  void onAndroidAutoError(const QString& error);

 private:
  // Message validation and error reporting
  /**
   * @brief Validate message structure against expected schema
   * @param obj JSON object to validate
   * @param error Output parameter for error message
   * @return true if message is valid, false if malformed
   */
  [[nodiscard]] auto validateMessage(const QJsonObject& obj, QString& error) const -> bool;

  /**
   * @brief Validate service command name against allowed commands
   * @param command Command name to validate
   * @param error Output parameter for error message
   * @return true if command is supported
   */
  [[nodiscard]] auto validateServiceCommand(const QString& command, QString& error) const -> bool;

  /**
   * @brief Send error response to client
   * @param client Target websocket client
   * @param message Error message text
   */
  void sendError(QWebSocket* client, const QString& message) const;

  // Message handlers
  /// Handle topic subscription request from client
  void handleSubscribe(QWebSocket* client, const QString& topic);
  /// Handle topic unsubscription request from client
  void handleUnsubscribe(QWebSocket* client, const QString& topic);
  /// Handle event publication from internal service
  void handlePublish(const QString& topic, const QVariantMap& payload);
  /// Route service command to appropriate service handler
  void handleServiceCommand(QWebSocket* client, const QString& command, const QVariantMap& params);

  /**
   * @brief Check if provided topic matches a subscription pattern
   * @param topic Actual event topic (e.g. "android_auto/connected")
   * @param pattern Subscription pattern (supports wildcards)
   * @return true if topic matches pattern
   * @note Wildcards: "*" matches single segment, "**" matches multiple segments
   */
  [[nodiscard]] auto topicMatches(const QString& topic, const QString& pattern) const -> bool;

  /// Connect AndroidAutoService signals for event forwarding
  void setupAndroidAutoConnections();

  QWebSocketServer* m_server;
  QList<QWebSocket*> m_clients;
  QMap<QWebSocket*, QStringList> m_subscriptions;
  ServiceManager* m_serviceManager;
  bool m_secureModeEnabled;
  QString m_certificatePath;
  QString m_keyPath;
};
