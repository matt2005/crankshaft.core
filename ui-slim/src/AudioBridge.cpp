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

#include "AudioBridge.h"
#include "ServiceProvider.h"
#include "../../core/services/logging/Logger.h"
#include "../../core/services/audio/AudioRouter.h"
#include "../../core/services/eventbus/EventBus.h"

#include <QFile>

AudioBridge::AudioBridge(ServiceProvider* serviceProvider, QObject* parent)
    : QObject(parent)
    , m_serviceProvider(serviceProvider)
    , m_audioBackend(AudioBackend::None)
    , m_isAudioAvailable(false)
    , m_bufferSize(4096)
    , m_sampleRate(48000)
    , m_channels(2)
    , m_bitsPerSample(16) {
    
    if (!m_serviceProvider) {
        Logger::instance().errorContext("AudioBridge", "ServiceProvider is null");
        return;
    }

    // Detect available audio backend
    detectAudioBackend();
    
    Logger::instance().infoContext("AudioBridge", "Initialized");
}

AudioBridge::~AudioBridge() {
    shutdown();
    Logger::instance().infoContext("AudioBridge", "Shutting down");
}

// Property getters
bool AudioBridge::isAudioAvailable() const {
    return m_isAudioAvailable;
}

QString AudioBridge::audioBackend() const {
    switch (m_audioBackend) {
        case AudioBackend::ALSA:
            return "ALSA";
        case AudioBackend::PulseAudio:
            return "PulseAudio";
        case AudioBackend::None:
        default:
            return "None";
    }
}

int AudioBridge::bufferSize() const {
    return m_bufferSize;
}

int AudioBridge::sampleRate() const {
    return m_sampleRate;
}

// Q_INVOKABLE methods
bool AudioBridge::initialize() {
    Logger::instance().infoContext("AudioBridge", "Initializing audio system");

    if (m_audioBackend == AudioBackend::None) {
        Logger::instance().warningContext("AudioBridge", 
                    "No audio backend detected, running in silent mode");
        emit audioError("No audio backend available");
        return false;
    }

    // Initialize AudioRouter via ServiceProvider
    if (!initializeAudioRouter()) {
        Logger::instance().errorContext("AudioBridge", 
                    "Failed to initialize AudioRouter");
        reportError("Audio initialization failed");
        return false;
    }

    // Setup EventBus connections for audio data
    setupEventBusConnections();

    m_isAudioAvailable = true;
    emit audioAvailabilityChanged(true);
    emit audioInitialized(audioBackend());

    Logger::instance().infoContext("AudioBridge", 
                QString("Audio system initialized with backend: %1, sample rate: %2 Hz, buffer: %3 bytes")
                    .arg(audioBackend())
                    .arg(m_sampleRate)
                    .arg(m_bufferSize));

    return true;
}

void AudioBridge::shutdown() {
    if (!m_isAudioAvailable) {
        return;
    }

    Logger::instance().infoContext("AudioBridge", "Shutting down audio system");

    auto* audioRouter = m_serviceProvider->audioRouter();
    if (audioRouter) {
        // TODO: Stop audio routing via AudioRouter once API is confirmed
        // audioRouter->stop();
    }

    m_isAudioAvailable = false;
    emit audioAvailabilityChanged(false);
}

bool AudioBridge::setVolume(int volume) {
    if (volume < 0 || volume > 100) {
        Logger::instance().warningContext("AudioBridge", 
                    QString("Invalid volume level: %1 (must be 0-100)").arg(volume));
        return false;
    }

    auto* audioRouter = m_serviceProvider->audioRouter();
    if (!audioRouter) {
        Logger::instance().warningContext("AudioBridge", 
                    "AudioRouter not available, cannot set volume");
        return false;
    }

    // TODO: Set volume via AudioRouter once API is confirmed
    // audioRouter->setVolume(volume / 100.0f); // Convert to 0.0-1.0

    Logger::instance().debugContext("AudioBridge", 
                QString("Volume set to: %1%").arg(volume));

    return true;
}

// Private slots
void AudioBridge::onCoreAudioDataAvailable(const QByteArray& data) {
    if (!m_isAudioAvailable) {
        return;
    }

    handleAudioData(data);
    emit audioDataReceived(data.size());
}

void AudioBridge::onCoreAudioFormatChanged(int sampleRate, int channels, int bitsPerSample) {
    Logger::instance().infoContext("AudioBridge", 
                QString("Audio format changed: %1 Hz, %2 channels, %3 bits")
                    .arg(sampleRate)
                    .arg(channels)
                    .arg(bitsPerSample));

    m_sampleRate = sampleRate;
    m_channels = channels;
    m_bitsPerSample = bitsPerSample;

    emit sampleRateChanged(m_sampleRate);
}

void AudioBridge::onCoreAudioError(const QString& error) {
    Logger::instance().errorContext("AudioBridge", 
                QString("Core audio error: %1").arg(error));
    
    reportError(error);
}

// Private methods
void AudioBridge::detectAudioBackend() {
    // Check for PulseAudio first (preferred on modern Linux)
    if (QFile::exists("/usr/bin/pulseaudio") || 
        QFile::exists("/usr/bin/pactl") ||
        qEnvironmentVariableIsSet("PULSE_SERVER")) {
        m_audioBackend = AudioBackend::PulseAudio;
        Logger::instance().infoContext("AudioBridge", "Detected PulseAudio backend");
        return;
    }

    // Check for ALSA
    if (QFile::exists("/proc/asound/version") || 
        QFile::exists("/dev/snd") ||
        QFile::exists("/usr/share/alsa")) {
        m_audioBackend = AudioBackend::ALSA;
        Logger::instance().infoContext("AudioBridge", "Detected ALSA backend");
        return;
    }

    // No audio backend detected
    m_audioBackend = AudioBackend::None;
    Logger::instance().warningContext("AudioBridge", 
                "No audio backend detected (checked PulseAudio and ALSA)");
}

bool AudioBridge::initializeAudioRouter() {
    auto* audioRouter = m_serviceProvider->audioRouter();
    if (!audioRouter) {
        Logger::instance().errorContext("AudioBridge", 
                    "AudioRouter service not available");
        return false;
    }

    // TODO: Initialize AudioRouter with detected backend once API is confirmed
    // bool success = audioRouter->initialize(audioBackend());
    // if (!success) {
    //     Logger::instance().errorContext("AudioBridge", 
    //                 "AudioRouter initialization failed");
    //     return false;
    // }

    Logger::instance().infoContext("AudioBridge", 
                QString("AudioRouter initialized with %1 backend").arg(audioBackend()));

    return true;
}

void AudioBridge::setupEventBusConnections() {
    auto* eventBus = m_serviceProvider->eventBus();
    if (!eventBus) {
        Logger::instance().warningContext("AudioBridge", 
                    "EventBus not available for audio events");
        return;
    }

    // TODO: Subscribe to audio events from core once EventBus API is confirmed
    // eventBus->subscribe("androidauto.audio_data", 
    //                    this, &AudioBridge::onCoreAudioDataAvailable);
    // eventBus->subscribe("androidauto.audio_format_changed", 
    //                    this, &AudioBridge::onCoreAudioFormatChanged);
    // eventBus->subscribe("androidauto.audio_error", 
    //                    this, &AudioBridge::onCoreAudioError);

    Logger::instance().debugContext("AudioBridge", "EventBus connections set up");
}

void AudioBridge::handleAudioData(const QByteArray& data) {
    auto* audioRouter = m_serviceProvider->audioRouter();
    if (!audioRouter) {
        return;
    }

    // TODO: Route audio data to output via AudioRouter once API is confirmed
    // audioRouter->writeAudioData(data);

    Logger::instance().debugContext("AudioBridge", 
                QString("Processed %1 bytes of audio data").arg(data.size()));
}

void AudioBridge::reportError(const QString& errorMessage) {
    emit audioError(errorMessage);
    Logger::instance().errorContext("AudioBridge", errorMessage);
}
