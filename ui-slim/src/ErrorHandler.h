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
    static auto instance() -> ErrorHandler*;

    /**
     * @brief Report an error with code and optional context
     * @param code Error code
     * @param context Additional context information
     * @param severity Error severity level
     * @note Qt's MOC (Meta-Object Compiler) requires explicit return types for
     *       Q_INVOKABLE methods; 'auto' keyword is not supported.
     */
    // NOLINTBEGIN(modernize-use-trailing-return-type)
    Q_INVOKABLE void reportError(ErrorCode code, const QString& context = QString(),
                                 Severity severity = Severity::Error);

    /**
     * @brief Clear the last error
     */
    Q_INVOKABLE void clearError();
    // NOLINTEND(modernize-use-trailing-return-type)

    /**
     * @brief Get the last error code as string
     */
    [[nodiscard]] auto lastError() const -> QString { return m_lastErrorCode; }

    /**
     * @brief Get the last error message
     */
    [[nodiscard]] auto lastErrorMessage() const -> QString { return m_lastErrorMessage; }

    /**
     * @brief Check if there's an active error
     */
    [[nodiscard]] auto hasError() const -> bool { return !m_lastErrorCode.isEmpty(); }

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
    auto errorCodeToString(ErrorCode code) const -> QString;

    /**
     * @brief Get user-friendly message for error code
     */
    auto getErrorMessage(ErrorCode code, const QString& context) const -> QString;

    /**
     * @brief Check if error is retryable
     */
    auto isRetryable(ErrorCode code) const -> bool;

    /**
     * @brief Log error with context
     */
    auto logError(ErrorCode code, const QString& message, const QString& context, Severity severity)
        -> void;

    QString m_lastErrorCode;
    QString m_lastErrorMessage;
    static ErrorHandler* s_instance;
};