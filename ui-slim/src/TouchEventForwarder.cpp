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

#include "TouchEventForwarder.h"

#include "../../core/services/android_auto/AndroidAutoService.h"
#include "../../core/services/logging/Logger.h"
#include "AndroidAutoFacade.h"
#include "ServiceProvider.h"

TouchEventForwarder::TouchEventForwarder(AndroidAutoFacade* androidAutoFacade,
                                         ServiceProvider* serviceProvider, QObject* parent)
    : QObject(parent),
      m_androidAutoFacade(androidAutoFacade),
      m_serviceProvider(serviceProvider),
      m_displaySize(1024, 600)  // Default Raspberry Pi display
      ,
      m_androidAutoSize(1024, 600)  // Default AndroidAuto resolution
      ,
      m_isEnabled(true),
      m_averageLatency(0) {
    if (!m_androidAutoFacade) {
        Logger::instance().errorContext("TouchEventForwarder", "AndroidAutoFacade is null");
        return;
    }

    if (!m_serviceProvider) {
        Logger::instance().errorContext("TouchEventForwarder", "ServiceProvider is null");
        return;
    }

    Logger::instance().infoContext("TouchEventForwarder",
                                   QString("Initialized with display: %1x%2, AA: %3x%4")
                                       .arg(m_displaySize.width())
                                       .arg(m_displaySize.height())
                                       .arg(m_androidAutoSize.width())
                                       .arg(m_androidAutoSize.height()));
}

TouchEventForwarder::~TouchEventForwarder() {
    Logger::instance().infoContext("TouchEventForwarder", "Shutting down");
}

// Property getters/setters
QSize TouchEventForwarder::displaySize() const { return m_displaySize; }

auto TouchEventForwarder::setDisplaySize(const QSize& size) -> void {
    if (m_displaySize != size) {
        m_displaySize = size;
        emit displaySizeChanged(size);

        Logger::instance().infoContext(
            "TouchEventForwarder",
            QString("Display size changed to: %1x%2").arg(size.width()).arg(size.height()));
    }
}

QSize TouchEventForwarder::androidAutoSize() const { return m_androidAutoSize; }

auto TouchEventForwarder::setAndroidAutoSize(const QSize& size) -> void {
    if (m_androidAutoSize != size) {
        m_androidAutoSize = size;
        emit androidAutoSizeChanged(size);

        Logger::instance().infoContext(
            "TouchEventForwarder",
            QString("AndroidAuto size changed to: %1x%2").arg(size.width()).arg(size.height()));
    }
}

auto TouchEventForwarder::isEnabled() const -> bool { return m_isEnabled; }

auto TouchEventForwarder::setEnabled(bool enabled) -> void {
    if (m_isEnabled != enabled) {
        m_isEnabled = enabled;
        emit enabledChanged(enabled);

        Logger::instance().infoContext(
            "TouchEventForwarder",
            QString("Touch forwarding %1").arg(enabled ? "enabled" : "disabled"));
    }
}

auto TouchEventForwarder::averageLatency() const -> int { return m_averageLatency; }

// Q_INVOKABLE methods
auto TouchEventForwarder::forwardTouchEvent(const QString& eventType,
                                            const QVariantList& touchPoints) -> void {
    if (!m_isEnabled) {
        return;
    }

    if (!m_androidAutoFacade) {
        emit forwardingError("AndroidAutoFacade not available");
        return;
    }

    // Start latency measurement
    m_latencyTimer.start();

    // Convert QML touch points to our format
    QList<TouchPoint> points = convertTouchPoints(touchPoints);

    if (points.isEmpty()) {
        Logger::instance().warningContext("TouchEventForwarder",
                                          "No valid touch points to forward");
        return;
    }

    // Send to AndroidAuto
    sendToAndroidAuto(eventType, points);

    // Measure latency
    qint64 latency = m_latencyTimer.nsecsElapsed() / 1000;  // Convert to microseconds
    updateLatencyStats(latency);

    emit touchEventForwarded(eventType, points.size());

    Logger::instance().debugContext("TouchEventForwarder",
                                    QString("Forwarded %1 event with %2 points, latency: %3 μs")
                                        .arg(eventType)
                                        .arg(points.size())
                                        .arg(latency));
}

auto TouchEventForwarder::forwardMouseEvent(const QString& eventType, qreal x, qreal y) -> void {
    if (!m_isEnabled) {
        return;
    }

    // Convert mouse to single touch point
    QVariantList touchPoints;
    QVariantMap point;
    point["id"] = 0;
    point["x"] = x;
    point["y"] = y;
    point["pressure"] = 1.0;
    point["areaWidth"] = 10;
    point["areaHeight"] = 10;
    touchPoints.append(point);

    forwardTouchEvent(eventType, touchPoints);
}

// Private methods
TouchPoint TouchEventForwarder::createTouchPoint(int id, qreal x, qreal y, float pressure,
                                                 const QSize& area) {
    TouchPoint point;
    point.id = id;
    point.position = QPointF(x, y);
    point.scaledPosition = scaleCoordinates(point.position);
    point.pressure = pressure;
    point.area = area;
    return point;
}

auto TouchEventForwarder::convertTouchPoints(const QVariantList& qmlTouchPoints) -> QList<TouchPoint> {
    QList<TouchPoint> points;

    for (const QVariant& var : qmlTouchPoints) {
        QVariantMap pointMap = var.toMap();

        int id = pointMap.value("id", 0).toInt();
        qreal x = pointMap.value("x", 0.0).toReal();
        qreal y = pointMap.value("y", 0.0).toReal();
        float pressure = pointMap.value("pressure", 1.0).toFloat();
        int areaWidth = pointMap.value("areaWidth", 10).toInt();
        int areaHeight = pointMap.value("areaHeight", 10).toInt();

        TouchPoint point = createTouchPoint(id, x, y, pressure, QSize(areaWidth, areaHeight));
        points.append(point);
    }

    return points;
}

void TouchEventForwarder::sendToAndroidAuto(const QString& eventType,
                                            const QList<TouchPoint>& points) {
    auto* aaService = m_serviceProvider->androidAutoService();
    if (!aaService) {
        Logger::instance().warningContext("TouchEventForwarder",
                                          "AndroidAutoService not available");
        emit forwardingError("AndroidAutoService not available");
        return;
    }

    // Convert to QVariantList for transmission
    QVariantList pointList;
    for (const TouchPoint& point : points) {
        pointList.append(point.toVariantMap());
    }

    // TODO: Send to AndroidAutoService via API once confirmed
    // aaService->sendTouchEvent(eventType.toStdString(), pointList);

    Logger::instance().debugContext("TouchEventForwarder",
                                    QString("Sent %1 event with %2 points to AndroidAutoService")
                                        .arg(eventType)
                                        .arg(points.size()));
}

auto TouchEventForwarder::updateLatencyStats(qint64 latencyMs) -> void {
    m_latencyHistory.append(latencyMs);

    // Keep only last MAX_LATENCY_SAMPLES
    if (m_latencyHistory.size() > MAX_LATENCY_SAMPLES) {
        m_latencyHistory.removeFirst();
    }

    // Calculate average
    qint64 sum = 0;
    for (qint64 latency : m_latencyHistory) {
        sum += latency;
    }

    int newAverage = m_latencyHistory.isEmpty() ? 0 : sum / m_latencyHistory.size();

    if (m_averageLatency != newAverage) {
        m_averageLatency = newAverage;
        emit averageLatencyChanged(m_averageLatency);
    }
}

auto TouchEventForwarder::scaleCoordinates(const QPointF& point) const -> QPointF {
    if (m_displaySize.width() == 0 || m_displaySize.height() == 0) {
        Logger::instance().warningContext("TouchEventForwarder",
                                          "Invalid display size for coordinate scaling");
        return point;
    }

    // Calculate scaling factors
    qreal scaleX = static_cast<qreal>(m_androidAutoSize.width()) / m_displaySize.width();
    qreal scaleY = static_cast<qreal>(m_androidAutoSize.height()) / m_displaySize.height();

    // Scale coordinates
    qreal scaledX = point.x() * scaleX;
    qreal scaledY = point.y() * scaleY;

    // Clamp to AndroidAuto bounds
    scaledX = qBound(0.0, scaledX, static_cast<qreal>(m_androidAutoSize.width() - 1));
    scaledY = qBound(0.0, scaledY, static_cast<qreal>(m_androidAutoSize.height() - 1));

    return QPointF(scaledX, scaledY);
}