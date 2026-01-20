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

#ifndef CONNECTIONSTATEMACHINE_H
#define CONNECTIONSTATEMACHINE_H

#include <QDateTime>
#include <QObject>
#include <QString>

#include <QTimer>

class AndroidAutoFacade;

class ConnectionStateMachine : public QObject {
    Q_OBJECT

    Q_PROPERTY(int currentState READ currentState NOTIFY currentStateChanged)
    Q_PROPERTY(int retryCount READ retryCount NOTIFY retryCountChanged)
    Q_PROPERTY(int nextRetryDelay READ nextRetryDelay NOTIFY nextRetryDelayChanged)
    Q_PROPERTY(bool isRetrying READ isRetrying NOTIFY retryingChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(
        QDateTime lastTransitionTime READ lastTransitionTime NOTIFY lastTransitionTimeChanged)

public:
    enum State { Disconnected = 0, Searching = 1, Connecting = 2, Connected = 3, Error = 4 };
    Q_ENUM(State)

    explicit ConnectionStateMachine(AndroidAutoFacade* androidAutoFacade,
                                    QObject* parent = nullptr);
    ~ConnectionStateMachine() override;

    // Property getters
    [[nodiscard]] auto currentState() const -> int;
    [[nodiscard]] auto retryCount() const -> int;
    [[nodiscard]] auto nextRetryDelay() const -> int;
    [[nodiscard]] auto isRetrying() const -> bool;
    [[nodiscard]] auto lastError() const -> QString;
    [[nodiscard]] auto lastTransitionTime() const -> QDateTime;

    // Q_INVOKABLE methods for QML
    Q_INVOKABLE void startConnection();
    Q_INVOKABLE void stopConnection();
    Q_INVOKABLE void resetRetryCount();
    Q_INVOKABLE void handleError(const QString& error);

signals:
    void currentStateChanged(int state);
    void retryCountChanged(int count);
    void nextRetryDelayChanged(int delayMs);
    void retryingChanged(bool isRetrying);
    void lastErrorChanged(const QString& error);
    void lastTransitionTimeChanged(const QDateTime& time);

    void stateTransitioned(int fromState, int toState);
    void retryAttemptStarted(int retryCount, int delayMs);
    void maxRetriesReached();
    void connectionRecovered();

private slots:
    void onFacadeConnectionStateChanged(int state);
    void onFacadeConnectionFailed(const QString& reason);
    void onFacadeConnectionEstablished(const QString& deviceName);
    void onRetryTimerTimeout();
    void onConnectionTimeout();

private:
    auto transitionToState(State newState) -> void;
    auto startRetryTimer() -> void;
    auto stopRetryTimer() -> void;
    auto calculateRetryDelay() const -> int;
    auto isValidTransition(State from, State to) const -> bool;
    auto logTransition(State from, State to) -> void;

    AndroidAutoFacade* m_androidAutoFacade;
    State m_currentState;
    int m_retryCount;
    int m_nextRetryDelay;
    QString m_lastError;
    QDateTime m_lastTransitionTime;

    QTimer* m_retryTimer;
    QTimer* m_connectionTimeout;

    // Retry configuration
    static constexpr int INITIAL_RETRY_DELAY_MS = 1000;  // 1 second
    static constexpr int MAX_RETRY_DELAY_MS = 30000;     // 30 seconds
    static constexpr int MAX_RETRY_COUNT = 10;
    static constexpr int CONNECTION_TIMEOUT_MS = 15000;  // 15 seconds
};

#endif  // CONNECTIONSTATEMACHINE_H