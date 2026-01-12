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

#include <QMap>
#include <QObject>
#include <QString>

/**
 * @brief Centralized error handling and user notification system
 *
 * Maps error codes to user-friendly messages, logs errors with context,
 * and emits signals for QML to display error dialogs.
 */
class ErrorHandler : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(QString lastErrorMessage READ lastErrorMessage NOTIFY lastErrorChanged)
    Q_PROPERTY(bool hasError READ hasError NOTIFY lastErrorChanged)

public:
    /**
     * @brief Error codes for various failure scenarios
     */
    enum class ErrorCode {
        // Connection errors
        ConnectionFailed,
        ConnectionTimeout,
        DeviceNotFound,
        DeviceDisconnected,

        // Audio errors
        AudioBackendUnavailable,
        AudioStreamFailed,
        AudioDeviceNotFound,

        // Video errors
        VideoStreamFailed,
        VideoDecoderFailed,

        // Settings errors
        SettingsCorrupted,
        SettingsSaveFailed,
        SettingsLoadFailed,

        // Service errors
        ServiceInitFailed,
        ServiceCrash,

        // General errors
        UnknownError
    };
    Q_ENUM(ErrorCode)

    /**
     * @brief Error severity levels
     */
    enum class Severity {
        Info,     // Informational, no action needed
        Warning,  // Warning, may affect functionality
        Error,    // Error, functionality impaired
        Critical  // Critical, application may not function
    };
    Q_ENUM(Severity)

    explicit ErrorHandler(QObject* parent = nullptr);
    ~ErrorHandler() override = default;

    /**
     * @brief Get singleton instance
     */
    static ErrorHandler* instance();

    /**
     * @brief Report an error with code and optional context
     * @param code Error code
     * @param context Additional context information
     * @param severity Error severity level
     */
    Q_INVOKABLE void reportError(ErrorCode code, const QString& context = QString(),
                                 Severity severity = Severity::Error);

    /**
     * @brief Clear the last error
     */
    Q_INVOKABLE void clearError();

    /**
     * @brief Get the last error code as string
     */
    QString lastError() const { return m_lastErrorCode; }

    /**
     * @brief Get the last error message
     */
    QString lastErrorMessage() const { return m_lastErrorMessage; }

    /**
     * @brief Check if there's an active error
     */
    bool hasError() const { return !m_lastErrorCode.isEmpty(); }

signals:
    /**
     * @brief Emitted when an error occurs
     * @param code Error code as string
     * @param message User-friendly error message
     * @param severity Error severity
     * @param retryable Whether the error can be retried
     */
    void errorOccurred(const QString& code, const QString& message, int severity, bool retryable);

    /**
     * @brief Emitted when the last error changes
     */
    void lastErrorChanged();

private:
    /**
     * @brief Convert error code to string
     */
    QString errorCodeToString(ErrorCode code) const;

    /**
     * @brief Get user-friendly message for error code
     */
    QString getErrorMessage(ErrorCode code, const QString& context) const;

    /**
     * @brief Check if error is retryable
     */
    bool isRetryable(ErrorCode code) const;

    /**
     * @brief Log error with context
     */
    void logError(ErrorCode code, const QString& message, const QString& context,
                  Severity severity);

    QString m_lastErrorCode;
    QString m_lastErrorMessage;

    static ErrorHandler* s_instance;
};
