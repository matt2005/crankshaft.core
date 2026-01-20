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

#include <QMutex>
#include <QObject>
#include <QVariantMap>

/**
 * @class EventBus
 * @brief Central event hub for publish-subscribe messaging
 *
 * EventBus implements a Pub/Sub pattern using Qt signals/slots for
 * in-process, loosely-coupled communication between services and UI.
 *
 * DESIGN RATIONALE:
 * - Loose coupling: Services don't know about each other
 * - Scalability: New services added without modifying existing code
 * - Testability: Mock event streams for unit testing
 * - Performance: Events can be batched or processed asynchronously
 * - Real-time UI: Automatic updates when service state changes
 *
 * USAGE PATTERN (Singleton):
 *   // Publisher publishes event
 *   QVariantMap payload;
 *   payload["deviceId"] = "AA123";
 *   payload["timestamp"] = QDateTime::currentMSecsSinceEpoch();
 *   EventBus::instance().publish("android_auto/device_connected", payload);
 *
 *   // Subscriber receives event
 *   connect(&EventBus::instance(), &EventBus::messagePublished,
 *           this, [](const QString& topic, const QVariantMap& payload) {
 *       if (topic == "android_auto/device_connected") {
 *           qInfo() << "Device connected:" << payload["deviceId"];
 *       }
 *   });
 *
 * TOPIC NAMING CONVENTION:
 *   Format: "service/event_name"
 *   Examples:
 *   - "android_auto/device_connected"
 *   - "android_auto/projection_started"
 *   - "audio/route_changed"
 *   - "media/playback_started"
 *   - "bluetooth/device_paired"
 *
 * SCENARIO EXAMPLES:
 *
 * 1. AndroidAuto Device Connection (Normal Flow)
 *    ───────────────────────────────────────────
 *    Time   Component              Event                         Payload
 *    ──────────────────────────────────────────────────────────────────────
 *    0ms    HAL/AASDK              USB device detected
 *    5ms    AndroidAutoService     publish("android_auto/device_connected")
 *           Payload: {deviceId: "AA001", deviceName: "Pixel", ...}
 *    10ms   WebSocketServer        relays event to all clients
 *    15ms   UI (QML)               receives event, shows "Ready to project"
 *    20ms   User taps "Start"      sendCommand("android_auto/start_projection")
 *    25ms   WebSocketServer        routes command to service
 *    50ms   MediaPipeline          starts decoding H.264 stream
 *    100ms  AndroidAutoService     publish("android_auto/projection_started")
 *    105ms  UI                     shows video output, starts playback
 *
 * 2. Audio Route Change (Bluetooth Connected)
 *    ────────────────────────────────────
 *    Time   Component              Event
 *    ──────────────────────────────────────────────────────────
 *    0ms    BluetoothHAL           detects device connection
 *    10ms   AudioService           receives bluetooth/device_connected
 *    15ms   AudioService           calls audioHal->setRoute(Bluetooth)
 *    20ms   AudioHAL               ALSA reconfigures to BT device
 *    30ms   AudioService           publish("audio/route_changed")
 *           Payload: {route: "bluetooth", device: "HeadsetX", ...}
 *    35ms   UI                     shows "Playing on: HeadsetX"
 *    40ms   (if playback active)   audio seamlessly continues on BT device
 *
 * 3. Error Scenario: Bluetooth Device Disconnects Mid-Playback
 *    ──────────────────────────────────────────────────────────
 *    Time   Component              Event
 *    ──────────────────────────────────────────────────────────
 *    0ms    BluetoothHAL           USB dongle disconnected
 *    5ms    AudioService           receives bluetooth/device_disconnected
 *    10ms   AudioService           calls audioHal->setRoute(Speaker)
 *    15ms   AudioHAL               ALSA switches to speaker output
 *    20ms   AudioService           publish("audio/route_changed")
 *    25ms   UI                     shows "Playing on: Speaker"
 *    30ms   (playback continues)   uninterrupted audio on speaker
 *
 * THREAD SAFETY:
 * - publish() is protected by QMutex
 * - Safe to call from any thread
 * - Signals emitted in calling thread (Qt default behaviour)
 * - Subscribers should use Qt::QueuedConnection if cross-thread
 *
 * PERFORMANCE CONSIDERATIONS:
 * - Each publish() is synchronous in calling thread
 * - For many subscribers, consider batching events
 * - EventBus itself has minimal overhead (<1ms per publish)
 * - Payload copy is shallow (QVariantMap is copy-on-write)
 *
 * @see WebSocketServer for event relay to remote UI clients
 * @see ServiceManager for service orchestration
 */
class EventBus : public QObject {
  Q_OBJECT

 public:
  /**
   * @brief Get singleton instance
   * @return Reference to global EventBus instance
   * @note Thread-safe, creates on first call
   */
  static EventBus& instance();

  /**
   * @brief Publish event to all subscribers
   *
   * Emits messagePublished signal which reaches:
   * - In-process subscribers (connect via Qt signals/slots)
   * - WebSocket clients (via WebSocketServer relay)
   * - Other services and UI components
   *
   * EXAMPLE:
   *   QVariantMap payload;
   *   payload["deviceId"] = "AA123";
   *   payload["connected"] = true;
   *   payload["timestamp"] = QDateTime::currentMSecsSinceEpoch();
   *   EventBus::instance().publish("android_auto/device_connected", payload);
   *
   * @param topic Event topic following "service/event_name" convention
   * @param payload QVariantMap containing event data
   *                - Must be JSON-serializable (no custom Qt types)
   *                - Timestamp should be included for event ordering
   *                - Context (IDs, names) helps subscribers filter
   *
   * @note Is thread-safe; may be called from any thread
   * @note Emits are synchronous; consider async if many subscribers
   * @see TOPIC NAMING CONVENTION section above for topic examples
   */
  void publish(const QString& topic, const QVariantMap& payload);

 signals:
  /**
   * @brief Emitted whenever an event is published
   *
   * All subscribers connect to this signal to receive events.
   * Typically filtered by topic name.
   *
   * Example subscriber:
   *   connect(&EventBus::instance(), &EventBus::messagePublished,
   *           [](const QString& topic, const QVariantMap& payload) {
   *       if (topic == "android_auto/device_connected") {
   *           handleAndroidAutoDeviceConnected(payload);
   *       }
   *   });
   *
   * @param topic The event topic (e.g., "android_auto/device_connected")
   * @param payload JSON-compatible QVariantMap with event data
   */
  void messagePublished(const QString& topic, const QVariantMap& payload);

 private:
  /// Private constructor (singleton pattern)
  EventBus() = default;
  /// Private destructor (singleton pattern)
  ~EventBus() = default;
  /// Deleted copy constructor (singleton pattern)
  EventBus(const EventBus&) = delete;
  /// Deleted assignment operator (singleton pattern)
  EventBus& operator=(const EventBus&) = delete;

  /// Mutex for thread-safe publish() calls
  QMutex m_mutex;
};
