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

#include "AudioVolumeController.h"

#include <QFile>
#include <QProcess>

#include "Logger.h"

AudioVolumeController::AudioVolumeController(AudioRouter* audioRouter, QObject* parent)
    : QObject(parent), m_audioRouter(audioRouter) {}

auto AudioVolumeController::initialize() -> bool {
    Logger::instance().infoContext(QStringLiteral("AudioVolumeController"),
                                   QStringLiteral("Initializing audio volume controller"));

    // Detect the best available backend
    m_backendType = detectBackend();

    if (m_backendType == BackendType::NONE) {
        // FR-025: Audio unavailable - log error, emit signal, but don't fail
        QString errorMsg =
            QStringLiteral("No audio backend available - projection will continue without audio");
        handleAudioError(QStringLiteral("initialize"), errorMsg);
        emit audioUnavailable(errorMsg);
        return false;
    }

    m_audioAvailable = true;

    // Read initial volume
    m_currentVolume = getCurrentVolume();

    if (m_currentVolume < 0) {
        Logger::instance().warningContext(
            QStringLiteral("AudioVolumeController"),
            QStringLiteral("Could not read initial volume, using default 50%"));
        m_currentVolume = 50;
    }

    Logger::instance().infoContext(
        QStringLiteral("AudioVolumeController"),
        QStringLiteral("Initialized with backend type %1, current volume: %2%")
            .arg(static_cast<int>(m_backendType))
            .arg(m_currentVolume));

    emit backendDetected(m_backendType);
    return true;
}

auto AudioVolumeController::getCurrentVolume() const -> int {
    if (m_backendType == BackendType::AUDIO_ROUTER) {
        return readVolumeFromAudioRouter();
    }

    // For other backends, return cached value
    // TODO: Implement actual volume reading for other backends
    return m_currentVolume;
}

auto AudioVolumeController::setVolume(int percentage) -> bool {
    if (!m_audioAvailable) {
        Logger::instance().warningContext(
            QStringLiteral("AudioVolumeController"),
            QStringLiteral("Cannot set volume - audio unavailable (FR-025)"));
        return false;
    }

    int validated = validatePercentage(percentage);

    if (validated == m_currentVolume) {
        return true;  // No change needed
    }

    bool success = false;

    switch (m_backendType) {
        case BackendType::AUDIO_ROUTER:
            success = setVolumeViaAudioRouter(validated);
            break;

        case BackendType::PULSEAUDIO:
            // TODO: Implement PulseAudio volume control
            Logger::instance().warningContext(
                QStringLiteral("AudioVolumeController"),
                QStringLiteral("PulseAudio backend not yet implemented"));
            success = false;
            break;

        case BackendType::ALSA:
            // TODO: Implement ALSA volume control
            Logger::instance().warningContext(QStringLiteral("AudioVolumeController"),
                                              QStringLiteral("ALSA backend not yet implemented"));
            success = false;
            break;

        case BackendType::QT_MULTIMEDIA:
            // TODO: Implement Qt Multimedia volume control
            Logger::instance().warningContext(
                QStringLiteral("AudioVolumeController"),
                QStringLiteral("Qt Multimedia backend not yet implemented"));
            success = false;
            break;

        case BackendType::NONE:
        default:
            handleAudioError(QStringLiteral("setVolume"),
                             QStringLiteral("No audio backend available"));
            return false;
    }

    if (success) {
        m_currentVolume = validated;
        Logger::instance().infoContext(QStringLiteral("AudioVolumeController"),
                                       QStringLiteral("Volume set to %1%").arg(validated));
        emit volumeChanged(validated);
    } else {
        handleAudioError(QStringLiteral("setVolume"),
                         QStringLiteral("Failed to set volume to %1%").arg(validated));
    }

    return success;
}

auto AudioVolumeController::isMuted() const -> bool { return m_isMuted; }

auto AudioVolumeController::setMuted(bool muted) -> bool {
    if (!m_audioAvailable) {
        Logger::instance().warningContext(
            QStringLiteral("AudioVolumeController"),
            QStringLiteral("Cannot set mute - audio unavailable (FR-025)"));
        return false;
    }

    if (muted == m_isMuted) {
        return true;  // No change needed
    }

    // TODO: Implement actual mute control for different backends
    m_isMuted = muted;

    Logger::instance().infoContext(
        QStringLiteral("AudioVolumeController"),
        QStringLiteral("Mute state changed to: %1").arg(muted ? "muted" : "unmuted"));

    emit muteChanged(muted);
    return true;
}

AudioVolumeController::BackendType AudioVolumeController::getBackendType() const {
    return m_backendType;
}

auto AudioVolumeController::isAvailable() const -> bool {
    return m_audioAvailable && m_backendType != BackendType::NONE;
}

auto AudioVolumeController::getLastError() const -> QString { return m_lastError; }

auto AudioVolumeController::detectBackend() -> BackendType {
    // Try backends in order of preference

    // 1. Try AudioRouter (best integration with AndroidAuto)
    if (tryAudioRouterBackend()) {
        Logger::instance().infoContext(QStringLiteral("AudioVolumeController"),
                                       QStringLiteral("Using AudioRouter backend"));
        return BackendType::AUDIO_ROUTER;
    }

    // 2. Try PulseAudio (common on Linux desktop)
    if (tryPulseAudioBackend()) {
        Logger::instance().infoContext(QStringLiteral("AudioVolumeController"),
                                       QStringLiteral("Using PulseAudio backend"));
        return BackendType::PULSEAUDIO;
    }

    // 3. Try ALSA (direct hardware control)
    if (tryAlsaBackend()) {
        Logger::instance().infoContext(QStringLiteral("AudioVolumeController"),
                                       QStringLiteral("Using ALSA backend"));
        return BackendType::ALSA;
    }

    // 4. Try Qt Multimedia (fallback)
    if (tryQtMultimediaBackend()) {
        Logger::instance().infoContext(QStringLiteral("AudioVolumeController"),
                                       QStringLiteral("Using Qt Multimedia backend"));
        return BackendType::QT_MULTIMEDIA;
    }

    // FR-025: No audio backend available
    Logger::instance().errorContext(
        QStringLiteral("AudioVolumeController"),
        QStringLiteral("No audio backend available - continuing without audio"));

    return BackendType::NONE;
}

auto AudioVolumeController::tryAudioRouterBackend() -> bool {
    if (!m_audioRouter) {
        return false;
    }

    // TODO: Verify AudioRouter is functional
    // For now, assume it's available if pointer is valid
    return true;
}

auto AudioVolumeController::tryPulseAudioBackend() -> bool {
    // Check if PulseAudio is available by trying to run pactl
    QProcess process;
    process.start(QStringLiteral("pactl"), QStringList{QStringLiteral("info")});

    if (!process.waitForFinished(1000)) {
        Logger::instance().warningContext(QStringLiteral("AudioVolumeController"),
                                          QStringLiteral("PulseAudio check timed out"));
        return false;
    }

    if (process.exitCode() != 0) {
        Logger::instance().infoContext(QStringLiteral("AudioVolumeController"),
                                       QStringLiteral("PulseAudio not available (pactl failed)"));
        return false;
    }

    return true;
}

auto AudioVolumeController::tryAlsaBackend() -> bool {
    // Check if ALSA devices are available
    QFile devicesFile(QStringLiteral("/proc/asound/devices"));

    if (!devicesFile.exists()) {
        Logger::instance().infoContext(
            QStringLiteral("AudioVolumeController"),
            QStringLiteral("ALSA not available (/proc/asound/devices not found)"));
        return false;
    }

    // Check if amixer command is available
    QProcess process;
    process.start(QStringLiteral("which"), QStringList{QStringLiteral("amixer")});

    if (!process.waitForFinished(1000)) {
        return false;
    }

    return process.exitCode() == 0;
}

auto AudioVolumeController::tryQtMultimediaBackend() -> bool {
    // TODO: Implement Qt Multimedia detection
    // Would check if QAudioOutput is available
    return false;
}

auto AudioVolumeController::readVolumeFromAudioRouter() const -> int {
    if (!m_audioRouter) {
        return -1;
    }

    // TODO: Implement actual volume reading from AudioRouter
    // For now, return cached value
    return m_currentVolume;
}

auto AudioVolumeController::setVolumeViaAudioRouter(int percentage) -> bool {
    if (!m_audioRouter) {
        return false;
    }

    // TODO: Implement actual volume control via AudioRouter
    // For now, just update cached value and return success
    Logger::instance().infoContext(
        QStringLiteral("AudioVolumeController"),
        QStringLiteral("Setting volume via AudioRouter: %1%").arg(percentage));

    return true;
}

auto AudioVolumeController::handleAudioError(const QString& context, const QString& message)
    -> void {
    m_lastError = QStringLiteral("%1: %2").arg(context, message);

    Logger::instance().errorContext(QStringLiteral("AudioVolumeController"), m_lastError);

    // FR-025: Log but don't crash - projection continues without audio
    if (m_audioAvailable) {
        m_audioAvailable = false;
        emit audioUnavailable(m_lastError);
    }
}

auto AudioVolumeController::validatePercentage(int percentage) const -> int {
    if (percentage < 0) return 0;
    if (percentage > 100) return 100;
    return percentage;
}