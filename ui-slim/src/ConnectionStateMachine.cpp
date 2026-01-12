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

#include "ConnectionStateMachine.h"
#include "AndroidAutoFacade.h"
#include "../../core/services/logging/Logger.h"

#include <QtMath>

ConnectionStateMachine::ConnectionStateMachine(AndroidAutoFacade* androidAutoFacade, 
                                               QObject* parent)
    : QObject(parent)
    , m_androidAutoFacade(androidAutoFacade)
    , m_currentState(State::Disconnected)
    , m_retryCount(0)
    , m_nextRetryDelay(INITIAL_RETRY_DELAY_MS)
    , m_lastError()
    , m_lastTransitionTime(QDateTime::currentDateTime())
    , m_retryTimer(new QTimer(this))
    , m_connectionTimeout(new QTimer(this)) {
    
    if (!m_androidAutoFacade) {
        Logger::instance().errorContext("ConnectionStateMachine", "AndroidAutoFacade is null");
        return;
    }

    // Setup retry timer
    m_retryTimer->setSingleShot(true);
    connect(m_retryTimer, &QTimer::timeout, this, &ConnectionStateMachine::onRetryTimerTimeout);

    // Setup connection timeout timer
    m_connectionTimeout->setSingleShot(true);
    connect(m_connectionTimeout, &QTimer::timeout, this, &ConnectionStateMachine::onConnectionTimeout);

    // Connect to facade signals
    connect(m_androidAutoFacade, &AndroidAutoFacade::connectionStateChanged,
            this, &ConnectionStateMachine::onFacadeConnectionStateChanged);
    connect(m_androidAutoFacade, &AndroidAutoFacade::connectionFailed,
            this, &ConnectionStateMachine::onFacadeConnectionFailed);
    connect(m_androidAutoFacade, &AndroidAutoFacade::connectionEstablished,
            this, &ConnectionStateMachine::onFacadeConnectionEstablished);

    Logger::instance().infoContext("ConnectionStateMachine", "Initialized");
}

ConnectionStateMachine::~ConnectionStateMachine() {
    stopRetryTimer();
    m_connectionTimeout->stop();
    Logger::instance().infoContext("ConnectionStateMachine", "Shutting down");
}

// Property getters
auto ConnectionStateMachine::currentState() const -> int {
    return static_cast<int>(m_currentState);
}

auto ConnectionStateMachine::retryCount() const -> int {
    return m_retryCount;
}

auto ConnectionStateMachine::nextRetryDelay() const -> int {
    return m_nextRetryDelay;
}

auto ConnectionStateMachine::isRetrying() const -> bool {
    return m_retryTimer->isActive();
}

auto ConnectionStateMachine::lastError() const -> QString {
    return m_lastError;
}

QDateTime ConnectionStateMachine::lastTransitionTime() const {
    return m_lastTransitionTime;
}

// Q_INVOKABLE methods
auto ConnectionStateMachine::startConnection() -> void {
    Logger::instance().infoContext("ConnectionStateMachine", "Starting connection");

    if (m_currentState == State::Connected) {
        Logger::instance().warningContext("ConnectionStateMachine", "Already connected");
        return;
    }

    stopRetryTimer();
    m_retryCount = 0;
    emit retryCountChanged(m_retryCount);

    transitionToState(State::Searching);
    
    if (m_androidAutoFacade) {
        m_androidAutoFacade->startDiscovery();
    }
}

auto ConnectionStateMachine::stopConnection() -> void {
    Logger::instance().infoContext("ConnectionStateMachine", "Stopping connection");

    stopRetryTimer();
    m_connectionTimeout->stop();

    if (m_androidAutoFacade) {
        m_androidAutoFacade->disconnectDevice();
    }

    transitionToState(State::Disconnected);
}

auto ConnectionStateMachine::resetRetryCount() -> void {
    Logger::instance().infoContext("ConnectionStateMachine", "Resetting retry count");
    
    m_retryCount = 0;
    m_nextRetryDelay = INITIAL_RETRY_DELAY_MS;
    
    emit retryCountChanged(m_retryCount);
    emit nextRetryDelayChanged(m_nextRetryDelay);
}

auto ConnectionStateMachine::handleError(const QString& error) -> void {
    Logger::instance().errorContext("ConnectionStateMachine", 
                QString("Handling error: %1").arg(error));

    m_lastError = error;
    emit lastErrorChanged(m_lastError);

    transitionToState(State::Error);

    // Start retry if under max attempts
    if (m_retryCount < MAX_RETRY_COUNT) {
        startRetryTimer();
    } else {
        Logger::instance().warningContext("ConnectionStateMachine", 
                    QString("Max retry count (%1) reached").arg(MAX_RETRY_COUNT));
        emit maxRetriesReached();
    }
}

// Private slots
auto ConnectionStateMachine::onFacadeConnectionStateChanged(int state) -> void {
    Logger::instance().debugContext("ConnectionStateMachine", 
                QString("Facade state changed: %1").arg(state));

    State newState = static_cast<State>(state);
    transitionToState(newState);
}

auto ConnectionStateMachine::onFacadeConnectionFailed(const QString& reason) -> void {
    Logger::instance().errorContext("ConnectionStateMachine", 
                QString("Connection failed: %1").arg(reason));

    handleError(reason);
}

auto ConnectionStateMachine::onFacadeConnectionEstablished(const QString& deviceName) -> void {
    Logger::instance().infoContext("ConnectionStateMachine", 
                QString("Connection established to: %1").arg(deviceName));

    stopRetryTimer();
    m_connectionTimeout->stop();

    if (m_retryCount > 0) {
        emit connectionRecovered();
    }

    resetRetryCount();
    transitionToState(State::Connected);
}

auto ConnectionStateMachine::onRetryTimerTimeout() -> void {
    Logger::instance().infoContext("ConnectionStateMachine", 
                QString("Retry attempt %1 after %2ms delay")
                    .arg(m_retryCount + 1)
                    .arg(m_nextRetryDelay));

    m_retryCount++;
    emit retryCountChanged(m_retryCount);
    emit retryAttemptStarted(m_retryCount, m_nextRetryDelay);

    // Calculate next retry delay (exponential backoff)
    m_nextRetryDelay = calculateRetryDelay();
    emit nextRetryDelayChanged(m_nextRetryDelay);

    // Clear error and retry connection
    m_lastError.clear();
    emit lastErrorChanged(m_lastError);

    transitionToState(State::Searching);
    
    if (m_androidAutoFacade) {
        m_androidAutoFacade->retryConnection();
    }
}

auto ConnectionStateMachine::onConnectionTimeout() -> void {
    Logger::instance().warningContext("ConnectionStateMachine", 
                QString("Connection timeout after %1ms").arg(CONNECTION_TIMEOUT_MS));

    handleError("Connection timed out");
}

// Private methods
auto ConnectionStateMachine::transitionToState(State newState) -> void {
    if (m_currentState == newState) {
        return;
    }

    if (!isValidTransition(m_currentState, newState)) {
        Logger::instance().warningContext("ConnectionStateMachine", 
                    QString("Invalid state transition: %1 -> %2")
                        .arg(m_currentState).arg(newState));
        return;
    }

    State oldState = m_currentState;
    m_currentState = newState;
    m_lastTransitionTime = QDateTime::currentDateTime();

    logTransition(oldState, newState);

    emit currentStateChanged(static_cast<int>(m_currentState));
    emit lastTransitionTimeChanged(m_lastTransitionTime);
    emit stateTransitioned(static_cast<int>(oldState), static_cast<int>(newState));

    // Handle state-specific actions
    switch (m_currentState) {
        case State::Connecting:
            // Start connection timeout
            m_connectionTimeout->start(CONNECTION_TIMEOUT_MS);
            break;
            
        case State::Connected:
            // Stop all timers on successful connection
            stopRetryTimer();
            m_connectionTimeout->stop();
            break;
            
        case State::Disconnected:
            stopRetryTimer();
            m_connectionTimeout->stop();
            break;
            
        case State::Error:
            m_connectionTimeout->stop();
            break;
            
        case State::Searching:
            // Stop retry timer when actively searching
            stopRetryTimer();
            break;
    }
}

auto ConnectionStateMachine::startRetryTimer() -> void {
    if (m_retryTimer->isActive()) {
        stopRetryTimer();
    }

    Logger::instance().infoContext("ConnectionStateMachine", 
                QString("Starting retry timer: %1ms").arg(m_nextRetryDelay));

    m_retryTimer->start(m_nextRetryDelay);
    emit retryingChanged(true);
}

auto ConnectionStateMachine::stopRetryTimer() -> void {
    if (m_retryTimer->isActive()) {
        m_retryTimer->stop();
        emit retryingChanged(false);
        
        Logger::instance().debugContext("ConnectionStateMachine", "Stopped retry timer");
    }
}

auto ConnectionStateMachine::calculateRetryDelay() const -> int {
    // Exponential backoff: delay = INITIAL_RETRY_DELAY * 2^retryCount
    int delay = INITIAL_RETRY_DELAY_MS * qPow(2, m_retryCount);
    
    // Cap at maximum delay
    return qMin(delay, MAX_RETRY_DELAY_MS);
}

auto ConnectionStateMachine::isValidTransition(State from, State to) const -> bool {
    // Allow transitions to same state (no-op)
    if (from == to) {
        return true;
    }

    // Define valid state transitions
    switch (from) {
        case State::Disconnected:
            return to == State::Searching || to == State::Error;
            
        case State::Searching:
            return to == State::Connecting || to == State::Disconnected || to == State::Error;
            
        case State::Connecting:
            return to == State::Connected || to == State::Disconnected || to == State::Error;
            
        case State::Connected:
            return to == State::Disconnected || to == State::Error;
            
        case State::Error:
            return to == State::Searching || to == State::Disconnected;
            
        default:
            return false;
    }
}

auto ConnectionStateMachine::logTransition(State from, State to) -> void {
    const char* stateNames[] = {"Disconnected", "Searching", "Connecting", "Connected", "Error"};
    
    Logger::instance().infoContext("ConnectionStateMachine", 
                QString("State transition: %1 -> %2 (retry count: %3)")
                    .arg(stateNames[static_cast<int>(from)])
                    .arg(stateNames[static_cast<int>(to)])
                    .arg(m_retryCount));
}
