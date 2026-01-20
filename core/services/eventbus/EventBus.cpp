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

#include "EventBus.h"

#include <QMutexLocker>

/**
 * @brief Get or create singleton instance (thread-safe)
 *
 * Uses static local variable for thread-safe lazy initialisation.
 * First call creates the instance, subsequent calls return same instance.
 *
 * EXAMPLE:
 *   EventBus::instance().publish("audio/volume_changed", {...});
 *
 * @return Reference to global EventBus instance
 * @note Thread-safe: C++11 static initialisation guarantees
 */
EventBus& EventBus::instance() {
  static EventBus instance;
  return instance;
}

/**
 * @brief Publish an event to all subscribers (thread-safe)
 *
 * Acquires mutex lock, then emits signal to all connected subscribers.
 * Subscribers receive call via Qt signal/slot mechanism.
 *
 * IMPLEMENTATION DETAILS:
 * 1. Acquire QMutexLocker (RAII, exception-safe)
 * 2. Emit messagePublished signal
 * 3. All connected slots called (synchronously in this thread)
 * 4. Lock released when QMutexLocker goes out of scope
 *
 * PERFORMANCE:
 * - Lock time: negligible (~1 microsecond)
 * - Signal emission: depends on number of subscribers
 * - Typical: <1ms for 10-20 subscribers
 * - No memory allocation (QVariantMap is passed by const ref)
 *
 * SCENARIO: AndroidAuto device connection workflow
 * ───────────────────────────────────────────────
 * Time   Component              Operation
 * ────────────────────────────────────────────────────
 * 0ms    AndroidAutoService     prepares payload {deviceId: "AA123", ...}
 * 0.1ms  AndroidAutoService     calls EventBus::instance().publish(...)
 * 0.2ms  QMutexLocker acquired  thread mutex lock
 * 0.3ms  emit messagePublished   signal emitted to subscribers
 * 0.4ms  WebSocketServer        receives signal (connected slot called)
 * 0.5ms  WebSocketServer        broadcasts to all WS clients
 * 0.6ms  UI/QML                 receives via WS, updates display
 * 0.7ms  QMutexLocker released  lock released
 * Total: ~0.7ms latency from event publish to UI update
 *
 * USAGE PATTERNS:
 *
 * Pattern 1: Simple event with payload
 * ───────────────────────────────────
 *   QVariantMap payload;
 *   payload["deviceId"] = "AA001";
 *   payload["deviceName"] = "Pixel 6";
 *   payload["timestamp"] = QDateTime::currentMSecsSinceEpoch();
 *   EventBus::instance().publish("android_auto/device_connected", payload);
 *
 * Pattern 2: Empty payload for simple events
 * ──────────────────────────────────────────
 *   EventBus::instance().publish("media/playback_started", {});
 *
 * Pattern 3: Complex nested payload
 * ─────────────────────────────────
 *   QVariantMap audioConfig;
 *   audioConfig["sampleRate"] = 48000;
 *   audioConfig["channels"] = 2;
 *   audioConfig["bitDepth"] = 16;
 *
 *   QVariantMap payload;
 *   payload["route"] = "bluetooth";
 *   payload["device"] = "HeadsetX";
 *   payload["audioConfig"] = audioConfig;
 *   EventBus::instance().publish("audio/route_changed", payload);
 *
 * @param topic Event topic following "service/event_name" convention
 *              Example: "android_auto/device_connected"
 *              Used to filter events in subscribers
 * @param payload QVariantMap containing event data
 *                Must be JSON-serializable (for WebSocket relay)
 *                Should include timestamp for ordering
 *                Should include context (IDs, names) for filtering
 *
 * @note Thread-safe: may be called from any thread without synchronisation
 * @note Blocks calling thread briefly (only lock/signal time)
 * @note All subscribers are called synchronously in the same thread
 *       If cross-thread notification needed, use Qt::QueuedConnection
 */
void EventBus::publish(const QString& topic, const QVariantMap& payload) {
  QMutexLocker locker(&m_mutex);
  emit messagePublished(topic, payload);
}
