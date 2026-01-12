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

#include "ErrorHandler.h"

#include <QDateTime>
#include <QDebug>

ErrorHandler* ErrorHandler::s_instance = nullptr;

ErrorHandler::ErrorHandler(QObject* parent) : QObject(parent) { s_instance = this; }

ErrorHandler* ErrorHandler::instance() {
    if (!s_instance) {
        s_instance = new ErrorHandler();
    }
    return s_instance;
}

auto ErrorHandler::reportError(ErrorCode code, const QString& context, Severity severity) -> void {
    QString errorCode = errorCodeToString(code);
    QString message = getErrorMessage(code, context);
    bool retryable = isRetryable(code);

    // Log the error
    logError(code, message, context, severity);

    // Update last error
    m_lastErrorCode = errorCode;
    m_lastErrorMessage = message;
    emit lastErrorChanged();

    // Emit signal for QML to display dialog
    emit errorOccurred(errorCode, message, static_cast<int>(severity), retryable);
}

auto ErrorHandler::clearError() -> void {
    if (!m_lastErrorCode.isEmpty()) {
        m_lastErrorCode.clear();
        m_lastErrorMessage.clear();
        emit lastErrorChanged();
    }
}

auto ErrorHandler::errorCodeToString(ErrorCode code) const -> QString {
    switch (code) {
        case ErrorCode::ConnectionFailed:
            return QStringLiteral("CONNECTION_FAILED");
        case ErrorCode::ConnectionTimeout:
            return QStringLiteral("CONNECTION_TIMEOUT");
        case ErrorCode::DeviceNotFound:
            return QStringLiteral("DEVICE_NOT_FOUND");
        case ErrorCode::DeviceDisconnected:
            return QStringLiteral("DEVICE_DISCONNECTED");
        case ErrorCode::AudioBackendUnavailable:
            return QStringLiteral("AUDIO_BACKEND_UNAVAILABLE");
        case ErrorCode::AudioStreamFailed:
            return QStringLiteral("AUDIO_STREAM_FAILED");
        case ErrorCode::AudioDeviceNotFound:
            return QStringLiteral("AUDIO_DEVICE_NOT_FOUND");
        case ErrorCode::VideoStreamFailed:
            return QStringLiteral("VIDEO_STREAM_FAILED");
        case ErrorCode::VideoDecoderFailed:
            return QStringLiteral("VIDEO_DECODER_FAILED");
        case ErrorCode::SettingsCorrupted:
            return QStringLiteral("SETTINGS_CORRUPTED");
        case ErrorCode::SettingsSaveFailed:
            return QStringLiteral("SETTINGS_SAVE_FAILED");
        case ErrorCode::SettingsLoadFailed:
            return QStringLiteral("SETTINGS_LOAD_FAILED");
        case ErrorCode::ServiceInitFailed:
            return QStringLiteral("SERVICE_INIT_FAILED");
        case ErrorCode::ServiceCrash:
            return QStringLiteral("SERVICE_CRASH");
        default:
            return QStringLiteral("UNKNOWN_ERROR");
    }
}

auto ErrorHandler::getErrorMessage(ErrorCode code, const QString& context) const -> QString {
    QString message;

    switch (code) {
        case ErrorCode::ConnectionFailed:
            message = QStringLiteral("Failed to connect to AndroidAuto device");
            break;
        case ErrorCode::ConnectionTimeout:
            message = QStringLiteral("Connection attempt timed out");
            break;
        case ErrorCode::DeviceNotFound:
            message = QStringLiteral("No AndroidAuto device found");
            break;
        case ErrorCode::DeviceDisconnected:
            message = QStringLiteral("AndroidAuto device disconnected");
            break;
        case ErrorCode::AudioBackendUnavailable:
            message = QStringLiteral("Audio unavailable - video projection will continue");
            break;
        case ErrorCode::AudioStreamFailed:
            message = QStringLiteral("Audio streaming failed");
            break;
        case ErrorCode::AudioDeviceNotFound:
            message = QStringLiteral("Audio device not found");
            break;
        case ErrorCode::VideoStreamFailed:
            message = QStringLiteral("Video streaming failed");
            break;
        case ErrorCode::VideoDecoderFailed:
            message = QStringLiteral("Video decoder initialization failed");
            break;
        case ErrorCode::SettingsCorrupted:
            message = QStringLiteral("Settings file corrupted - restored to defaults");
            break;
        case ErrorCode::SettingsSaveFailed:
            message = QStringLiteral("Failed to save settings");
            break;
        case ErrorCode::SettingsLoadFailed:
            message = QStringLiteral("Failed to load settings");
            break;
        case ErrorCode::ServiceInitFailed:
            message = QStringLiteral("Service initialization failed");
            break;
        case ErrorCode::ServiceCrash:
            message = QStringLiteral("Service crashed unexpectedly");
            break;
        default:
            message = QStringLiteral("An unknown error occurred");
            break;
    }

    // Append context if provided
    if (!context.isEmpty()) {
        message += QStringLiteral(": ") + context;
    }

    return message;
}

auto ErrorHandler::isRetryable(ErrorCode code) const -> bool {
    switch (code) {
        case ErrorCode::ConnectionFailed:
        case ErrorCode::ConnectionTimeout:
        case ErrorCode::DeviceNotFound:
        case ErrorCode::AudioStreamFailed:
        case ErrorCode::VideoStreamFailed:
            return true;

        case ErrorCode::DeviceDisconnected:
        case ErrorCode::AudioBackendUnavailable:
        case ErrorCode::AudioDeviceNotFound:
        case ErrorCode::VideoDecoderFailed:
        case ErrorCode::SettingsCorrupted:
        case ErrorCode::SettingsSaveFailed:
        case ErrorCode::SettingsLoadFailed:
        case ErrorCode::ServiceInitFailed:
        case ErrorCode::ServiceCrash:
        case ErrorCode::UnknownError:
        default:
            return false;
    }
}

void ErrorHandler::logError(ErrorCode code, const QString& message, const QString& context,
                            Severity severity) {
    QString severityStr;
    switch (severity) {
        case Severity::Info:
            severityStr = QStringLiteral("INFO");
            break;
        case Severity::Warning:
            severityStr = QStringLiteral("WARNING");
            break;
        case Severity::Error:
            severityStr = QStringLiteral("ERROR");
            break;
        case Severity::Critical:
            severityStr = QStringLiteral("CRITICAL");
            break;
    }

    QString errorCode = errorCodeToString(code);
    QString timestamp = QDateTime::currentDateTime().toString(Qt::ISODate);

    QString logMessage = QString("[%1] [SlimUI:ErrorHandler] [%2] %3 (%4)")
                             .arg(timestamp)
                             .arg(severityStr)
                             .arg(message)
                             .arg(errorCode);

    if (!context.isEmpty()) {
        logMessage += QString(" - Context: %1").arg(context);
    }

    // Log based on severity
    switch (severity) {
        case Severity::Info:
            qInfo().noquote() << logMessage;
            break;
        case Severity::Warning:
            qWarning().noquote() << logMessage;
            break;
        case Severity::Error:
        case Severity::Critical:
            qCritical().noquote() << logMessage;
            break;
    }
}
