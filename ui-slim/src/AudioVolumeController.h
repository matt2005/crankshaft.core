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

#include <QObject>
#include <QString>

class AudioRouter;

/**
 * @brief Controls system audio volume through multiple backends
 *
 * This controller manages audio volume using the best available method:
 * 1. Core::AudioRouter (preferred, integrates with AndroidAuto pipeline)
 * 2. PulseAudio (via command-line or library)
 * 3. ALSA (direct hardware control)
 * 4. Qt Multimedia (fallback)
 *
 * The controller gracefully handles audio backend failures per FR-025,
 * logging errors and continuing operation without audio.
 */
class AudioVolumeController : public QObject {
    Q_OBJECT

public:
    /**
     * @brief Backend types for volume control
     */
    enum class BackendType {
        NONE,          ///< No audio control available
        AUDIO_ROUTER,  ///< Core::AudioRouter (preferred)
        PULSEAUDIO,    ///< PulseAudio backend
        ALSA,          ///< ALSA hardware control
        QT_MULTIMEDIA  ///< Qt Multimedia fallback
    };
    Q_ENUM(BackendType)

    /**
     * @brief Construct a new Audio Volume Controller
     *
     * @param audioRouter Pointer to core AudioRouter (optional)
     * @param parent Parent QObject
     */
    explicit AudioVolumeController(AudioRouter* audioRouter = nullptr, QObject* parent = nullptr);

    /**
     * @brief Destructor
     */
    ~AudioVolumeController() override = default;

    /**
     * @brief Initialize the volume controller
     *
     * Detects available backends and reads current volume level.
     * Handles FR-025 audio unavailability gracefully.
     *
     * @return true if initialization succeeded
     * @return false if initialization failed (audio unavailable)
     */
    [[nodiscard]] auto initialize() -> bool;

    /**
     * @brief Get the current volume level
     *
     * @return int Volume percentage (0-100), or -1 if unavailable
     */
    [[nodiscard]] auto getCurrentVolume() const -> int;

    /**
     * @brief Set the volume level
     *
     * @param percentage Volume percentage (0-100)
     * @return true if volume was set successfully
     * @return false if operation failed
     */
    [[nodiscard]] auto setVolume(int percentage) -> bool;

    /**
     * @brief Check if audio is muted
     *
     * @return true if muted
     * @return false if not muted or status unknown
     */
    [[nodiscard]] auto isMuted() const -> bool;

    /**
     * @brief Set mute state
     *
     * @param muted true to mute, false to unmute
     * @return true if mute state was set successfully
     * @return false if operation failed
     */
    [[nodiscard]] auto setMuted(bool muted) -> bool;

    /**
     * @brief Get the current backend type
     *
     * @return BackendType The active backend
     */
    [[nodiscard]] auto getBackendType() const -> BackendType;

    /**
     * @brief Check if audio control is available
     *
     * @return true if volume can be controlled
     * @return false if no backend is available (FR-025)
     */
    [[nodiscard]] auto isAvailable() const -> bool;

    /**
     * @brief Get error message for last failure
     *
     * @return QString Error message, empty if no error
     */
    [[nodiscard]] auto getLastError() const -> QString;

signals:
    /**
     * @brief Emitted when volume changes
     *
     * @param percentage New volume percentage (0-100)
     */
    void volumeChanged(int percentage);

    /**
     * @brief Emitted when mute state changes
     *
     * @param muted New mute state
     */
    void muteChanged(bool muted);

    /**
     * @brief Emitted when backend detection completes
     *
     * @param backend The detected backend type
     */
    void backendDetected(BackendType backend);

    /**
     * @brief Emitted when audio backend becomes unavailable (FR-025)
     *
     * @param errorMessage Description of the error
     */
    void audioUnavailable(const QString& errorMessage);

    /**
     * @brief Emitted when audio backend becomes available again
     */
    void audioRestored();

private:
    /**
     * @brief Detect and initialize the best available backend
     *
     * @return BackendType The detected backend
     */
    auto detectBackend() -> BackendType;

    /**
     * @brief Try to initialize AudioRouter backend
     *
     * @return true if AudioRouter is available
     * @return false otherwise
     */
    auto tryAudioRouterBackend() -> bool;

    /**
     * @brief Try to initialize PulseAudio backend
     *
     * @return true if PulseAudio is available
     * @return false otherwise
     */
    auto tryPulseAudioBackend() -> bool;

    /**
     * @brief Try to initialize ALSA backend
     *
     * @return true if ALSA is available
     * @return false otherwise
     */
    auto tryAlsaBackend() -> bool;

    /**
     * @brief Try to initialize Qt Multimedia backend
     *
     * @return true if Qt Multimedia is available
     * @return false otherwise
     */
    auto tryQtMultimediaBackend() -> bool;

    /**
     * @brief Read volume from AudioRouter
     *
     * @return int Volume percentage (0-100), or -1 on error
     */
    auto readVolumeFromAudioRouter() const -> int;

    /**
     * @brief Set volume via AudioRouter
     *
     * @param percentage Volume percentage (0-100)
     * @return true if successful
     * @return false on error
     */
    auto setVolumeViaAudioRouter(int percentage) -> bool;

    /**
     * @brief Handle audio backend error (FR-025)
     *
     * @param context Error context
     * @param message Error message
     */
    auto handleAudioError(const QString& context, const QString& message) -> void;

    /**
     * @brief Validate and clamp volume percentage
     *
     * @param percentage Input percentage
     * @return int Clamped percentage (0-100)
     */
    auto validatePercentage(int percentage) const -> int;

    AudioRouter* m_audioRouter{nullptr};
    BackendType m_backendType{BackendType::NONE};
    int m_currentVolume{0};
    bool m_isMuted{false};
    QString m_lastError;
    bool m_audioAvailable{false};
};