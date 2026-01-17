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

#ifndef AUDIOBRIDGE_H
#define AUDIOBRIDGE_H

#include <QObject>
#include <QString>

class ServiceProvider;

class AudioBridge : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool isAudioAvailable READ isAudioAvailable NOTIFY audioAvailabilityChanged)
    Q_PROPERTY(QString audioBackend READ audioBackend NOTIFY audioBackendChanged)
    Q_PROPERTY(int bufferSize READ bufferSize NOTIFY bufferSizeChanged)
    Q_PROPERTY(int sampleRate READ sampleRate NOTIFY sampleRateChanged)

public:
    enum AudioBackend { None = 0, ALSA = 1, PulseAudio = 2 };
    Q_ENUM(AudioBackend)

    explicit AudioBridge(ServiceProvider* serviceProvider, QObject* parent = nullptr);
    ~AudioBridge() override;

    // Property getters
    [[nodiscard]] auto isAudioAvailable() const -> bool;
    [[nodiscard]] auto audioBackend() const -> QString;
    [[nodiscard]] auto bufferSize() const -> int;
    [[nodiscard]] auto sampleRate() const -> int;

    // Q_INVOKABLE methods for QML
    Q_INVOKABLE [[nodiscard]] auto initialize() -> bool;
    Q_INVOKABLE auto shutdown() -> void;
    Q_INVOKABLE [[nodiscard]] auto setVolume(int volume) -> bool;  // 0-100

signals:
    void audioAvailabilityChanged(bool available);
    void audioBackendChanged(const QString& backend);
    void bufferSizeChanged(int size);
    void sampleRateChanged(int rate);
    void audioError(const QString& error);
    void audioInitialized(const QString& backend);
    void audioDataReceived(int bytesReceived);

private slots:
    void onCoreAudioDataAvailable(const QByteArray& data);
    void onCoreAudioFormatChanged(int sampleRate, int channels, int bitsPerSample);
    void onCoreAudioError(const QString& error);

private:
    auto detectAudioBackend() -> void;
    auto initializeAudioRouter() -> bool;
    auto setupEventBusConnections() -> void;
    auto handleAudioData(const QByteArray& data) -> void;
    auto reportError(const QString& errorMessage) -> void;

    ServiceProvider* m_serviceProvider;
    AudioBackend m_audioBackend;
    bool m_isAudioAvailable;
    int m_bufferSize;
    int m_sampleRate;
    int m_channels;
    int m_bitsPerSample;
};

#endif  // AUDIOBRIDGE_H