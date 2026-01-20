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

#ifndef TOUCHEVENTFORWARDER_H
#define TOUCHEVENTFORWARDER_H

#include <QElapsedTimer>
#include <QObject>
#include <QPointF>
#include <QSize>
#include <QVariantList>
#include <QVariantMap>

class AndroidAutoFacade;
class ServiceProvider;

struct TouchPoint {
    int id;
    QPointF position;        // Original position in QML coordinates
    QPointF scaledPosition;  // Scaled position for AndroidAuto
    float pressure;
    QSize area;

    QVariantMap toVariantMap() const {
        QVariantMap map;
        map["id"] = id;
        map["x"] = scaledPosition.x();
        map["y"] = scaledPosition.y();
        map["pressure"] = pressure;
        map["areaWidth"] = area.width();
        map["areaHeight"] = area.height();
        return map;
    }
};

class TouchEventForwarder : public QObject {
    Q_OBJECT

    Q_PROPERTY(QSize displaySize READ displaySize WRITE setDisplaySize NOTIFY displaySizeChanged)
    Q_PROPERTY(QSize androidAutoSize READ androidAutoSize WRITE setAndroidAutoSize NOTIFY
                   androidAutoSizeChanged)
    Q_PROPERTY(bool isEnabled READ isEnabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(int averageLatency READ averageLatency NOTIFY averageLatencyChanged)

public:
    explicit TouchEventForwarder(AndroidAutoFacade* androidAutoFacade,
                                 ServiceProvider* serviceProvider, QObject* parent = nullptr);
    ~TouchEventForwarder() override;

    // Property getters/setters
    [[nodiscard]] auto displaySize() const -> QSize;
    auto setDisplaySize(const QSize& size) -> void;

    [[nodiscard]] auto androidAutoSize() const -> QSize;
    auto setAndroidAutoSize(const QSize& size) -> void;

    [[nodiscard]] auto isEnabled() const -> bool;
    auto setEnabled(bool enabled) -> void;

    [[nodiscard]] auto averageLatency() const -> int;

    // Q_INVOKABLE methods for QML
    // NOTE: Qt's MOC (Meta-Object Compiler) cannot handle 'auto' keyword in method
    // signatures. Explicit return types are required for Q_INVOKABLE methods.
    // NOLINTBEGIN(modernize-use-trailing-return-type)
    Q_INVOKABLE void forwardTouchEvent(const QString& eventType, const QVariantList& touchPoints);
    Q_INVOKABLE void forwardMouseEvent(const QString& eventType, qreal x, qreal y);
    // NOLINTEND(modernize-use-trailing-return-type)

signals:
    void displaySizeChanged(const QSize& size);
    void androidAutoSizeChanged(const QSize& size);
    void enabledChanged(bool enabled);
    void averageLatencyChanged(int latency);
    void touchEventForwarded(const QString& eventType, int pointCount);
    void forwardingError(const QString& error);

private:
    TouchPoint createTouchPoint(int id, qreal x, qreal y, float pressure, const QSize& area);
    QList<TouchPoint> convertTouchPoints(const QVariantList& qmlTouchPoints);
    void sendToAndroidAuto(const QString& eventType, const QList<TouchPoint>& points);
    void updateLatencyStats(qint64 latencyMs);
    QPointF scaleCoordinates(const QPointF& point) const;

    AndroidAutoFacade* m_androidAutoFacade;
    ServiceProvider* m_serviceProvider;
    QSize m_displaySize;
    QSize m_androidAutoSize;
    bool m_isEnabled;

    // Latency tracking
    QElapsedTimer m_latencyTimer;
    QList<qint64> m_latencyHistory;
    int m_averageLatency;
    static constexpr int MAX_LATENCY_SAMPLES = 50;
};

#endif  // TOUCHEVENTFORWARDER_H