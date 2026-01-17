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

#include <QByteArray>
#include <QObject>
#include <QString>
#include <QStringList>

/**
 * @brief Hardware Abstraction Layer for video devices
 *
 * Provides low-level video hardware control and configuration.
 */
class VideoHAL : public QObject {
  Q_OBJECT

 public:
  enum class VideoResolution { SD_480p, HD_720p, FullHD_1080p, UHD_4K };
  Q_ENUM(VideoResolution)

  explicit VideoHAL(QObject* parent = nullptr);
  ~VideoHAL() override;

  auto setResolution(VideoResolution resolution) -> bool;
  VideoResolution getResolution() const;

  auto setBrightness(int brightness) -> bool;
  auto getBrightness() const -> int;

  auto setContrast(int contrast) -> bool;
  auto getContrast() const -> int;

  auto startVideoStream(const QString& streamName, const QString& codec) -> bool;
  auto stopVideoStream(const QString& streamName) -> bool;
  auto pushVideoFrame(const QByteArray& frameData) -> bool;

  QStringList getSupportedCodecs() const;
  auto setVideoSink(const QString& sinkName) -> bool;

 signals:
  void errorOccurred(const QString& message);
  void streamStarted(const QString& streamName);
  void streamStopped(const QString& streamName);
  void streamEnded();
  void resolutionChanged(VideoResolution resolution);
  void brightnessChanged(int brightness);
  void contrastChanged(int contrast);

 private:
  auto initializePipeline() -> bool;
  void cleanup();

  class VideoHALPrivate;
  VideoHALPrivate* d;
};
