# HAL (Hardware Abstraction Layer) Comprehensive Documentation

**Project**: Crankshaft Automotive Infotainment System  
**Last Updated**: 2025-01-15  
**Scope**: Audio, Video, Transport, Wireless HAL implementations

## 1. HAL Architecture Overview

### 1.1 Purpose and Design

The Hardware Abstraction Layer provides:
- **Platform Independence**: Same code works on Raspberry Pi, Desktop, Vehicle
- **Testability**: Mock implementations for unit tests
- **Performance**: Hardware-specific optimizations transparent to services
- **Maintainability**: Isolated hardware concerns

### 1.2 HAL Layer Stack

```
┌─────────────────────────────────────────┐
│ Services (AndroidAuto, Media, Bluetooth)│
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│ HAL (Hardware Abstraction Layer)        │
│ ┌──────────┬──────────┬──────────────┐  │
│ │ Audio    │ Video    │ Transport    │  │
│ │ HAL      │ HAL      │ HAL          │  │
│ ├──────────┼──────────┼──────────────┤  │
│ │ Wireless │ Functional │ Multimedia │  │
│ │ HAL      │ Devices    │ Pipeline   │  │
│ └──────────┴──────────┴──────────────┘  │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│ Linux Subsystems                        │
│ ALSA  V4L2  GStreamer  libusb  GPIO    │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│ Linux Kernel                            │
│ USB  I2C  CAN  SPI  Serial             │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│ Hardware                                │
│ USB Devices  Audio Codec  Video Decoder│
│ Wireless Module  CAN Interface         │
└─────────────────────────────────────────┘
```

### 1.3 Interface Pattern

All HAL components follow a common interface pattern:

```cpp
// Abstract interface (header)
class IAudioHAL {
public:
    virtual ~IAudioHAL() = default;
    virtual bool initialize() = 0;
    virtual bool setRoute(AudioRoute route) = 0;
    virtual bool start() = 0;
    virtual void stop() = 0;
    virtual bool isReady() const = 0;
};

// Concrete implementation (e.g., ALSA)
class AudioHALALSA : public IAudioHAL {
public:
    bool initialize() override { /* ALSA initialization */ }
    bool setRoute(AudioRoute route) override { /* ALSA route switch */ }
    // ...
};

// Mock implementation (testing)
class MockAudioHAL : public IAudioHAL {
public:
    bool initialize() override { return true; }  // No-op
    bool setRoute(AudioRoute route) override { return true; }  // No-op
    // ...
};
```

---

## 2. Audio HAL (`core/hal/multimedia/AudioHAL.h`)

### 2.1 Design and Purpose

**File**: `core/hal/multimedia/AudioHAL.h`  
**Implementation**: ALSA (Advanced Linux Sound Architecture)  
**Responsibilities**:
- Abstraction over Linux audio subsystem (ALSA)
- Multi-route support (Speaker, Headset, Bluetooth, AUX)
- Volume control and mixing
- Audio device enumeration
- Error handling and recovery

### 2.2 Audio Routes

```cpp
enum class AudioRoute {
    Default,      // Primary output (speaker)
    Headset,      // Wired headphones
    Bluetooth,    // BT speaker or headset
    Auxiliary,    // AUX input (if applicable)
    Internal,     // Internal testing only
};
```

### 2.3 Audio Configuration

```cpp
struct AudioConfig {
    int sampleRate;      // 44100, 48000, 96000, 192000
    int channels;        // 1 (mono), 2 (stereo)
    int bitDepth;        // 16, 24, 32 bits
    int bufferSize;      // Frames (affects latency)
    
    // Typical automotive configuration:
    AudioConfig automotive = {
        sampleRate: 48000,   // Professional audio standard
        channels: 2,         // Stereo
        bitDepth: 16,        // Standard for car systems
        bufferSize: 4096     // ~85ms latency at 48kHz
    };
};
```

### 2.4 Initialization Flow

```cpp
// Step 1: Create and initialize
auto audioHal = new AudioHAL();

// Step 2: Check availability
if (!audioHal->isReady()) {
    qWarning() << "Audio device not available";
    return false;
}

// Step 3: Configure
audioHal->setAudioConfig(automotive_config);

// Step 4: Set route
audioHal->setRoute(AudioRoute::Speaker);

// Step 5: Start playback
audioHal->startPlayback();

// Step 6: Feed audio data
QByteArray pcmData = /* 16-bit PCM frames */;
audioHal->pushAudio(pcmData);
```

### 2.5 Audio Flow Diagram

```
Input PCM Stream (44.1kHz stereo)
    ↓
┌─────────────────────────────────────────┐
│ AudioHAL::pushAudio(QByteArray data)    │
│ - Check if playing                      │
│ - Validate PCM format                   │
│ - Buffer management                     │
└─────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────┐
│ ALSA Audio Buffer                       │
│ - Ring buffer (configurable size)       │
│ - Sample rate conversion (if needed)    │
│ - Resampler (SRC - Secret Rabbit Code)  │
└─────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────┐
│ Route Selector (multiplexer)            │
│ ├─ Speaker output (default)             │
│ ├─ Headphone output (if detected)       │
│ ├─ Bluetooth (if connected)             │
│ └─ AUX output                           │
└─────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────┐
│ Audio Output Device (Physical)          │
│ - DAC (Digital-to-Analog Converter)     │
│ - Amplifier                             │
│ - Speaker/Headphone/BT Module          │
└─────────────────────────────────────────┘
    ↓
Audio plays in vehicle
```

### 2.6 Scenario: Route Switching

**Scenario**: User connects Bluetooth headset while media is playing

```cpp
// STEP 1: Bluetooth device detected by BluetoothHAL
BluetoothHAL detects connection
  └─ publishes "bluetooth/device_connected"

// STEP 2: AudioService receives event
AudioService::onBluetoothDeviceConnected() {
    // STEP 3: Check if audio is active
    if (!m_audioHal->isPlaying()) {
        // No active playback, just switch route
        m_audioHal->setRoute(AudioRoute::Bluetooth);
        return;
    }
    
    // STEP 4: Audio is playing - perform seamless switch
    
    // 4a: Reduce volume slightly to mask switching artifacts
    int currentVolume = m_audioHal->getVolume();
    m_audioHal->setVolume(currentVolume - 5);
    
    // 4b: Pause ALSA playback briefly (5ms)
    // This ensures no corrupted frames during route switch
    
    // 4c: Switch audio route in ALSA
    m_audioHal->setRoute(AudioRoute::Bluetooth);
    
    // 4d: Flush buffers and reinitialize stream
    // This prevents audio clicks from buffer leftover
    
    // 4e: Resume playback
    // 4f: Restore volume gradually (ramp up)
    m_audioHal->setVolume(currentVolume);
    
    // STEP 5: Publish event for UI and diagnostics
    QVariantMap payload;
    payload["route"] = "bluetooth";
    payload["device"] = bluetoothDeviceName;
    payload["seamless"] = true;
    EventBus::instance().publish("audio/route_changed", payload);
}
```

**Timing**:
```
Time    Event
──────────────────────────────────────────
-1ms    Audio playing on speaker at 75% volume
0ms     BT device detected
5ms     Volume reduced to 70% (imperceptible ramp)
10ms    ALSA paused
15ms    Route switched to Bluetooth
20ms    Buffers flushed
25ms    Playback resumed on Bluetooth
30ms    Volume ramped back to 75%
35ms    User hears smooth transition (no click/pop)
```

### 2.7 Error Handling

```cpp
// ALSA underrun (buffer ran empty)
class AudioHAL {
    void handleUnderrun() {
        // 1. Detect underrun from ALSA
        // 2. Log error with timestamp
        Logger::instance().warning(
            "Audio underrun at " + QString::number(QDateTime::currentMSecsSinceEpoch())
        );
        
        // 3. For streaming: request retransmit from source
        if (isStreaming()) {
            emitEvent("audio/request_retransmit");
            // Source should resend latest frames
        }
        
        // 4. For local playback: recover by seeking back
        if (hasLocalFile()) {
            seek(currentPosition - 1000);  // Replay last 1 second
        }
        
        // 5. Publish diagnostic event
        QVariantMap payload;
        payload["type"] = "underrun";
        payload["severity"] = "warning";
        payload["bufferLevelPercent"] = 0;
        EventBus::instance().publish("audio/error", payload);
    }
};
```

### 2.8 Multi-Stream Mixing

**AudioMixer**: Combines multiple audio streams into one output

```cpp
class AudioMixer {
    // Input sources
    void addStream(const QString& streamId, int priority);
    void removeStream(const QString& streamId);
    
    // Push audio data from each stream
    void pushAudioToStream(const QString& streamId, const QByteArray& data);
};

// Example: Navigation + Media + Bluetooth Call
MediaStream (priority: 50)
NavigationStream (priority: 100)  // Higher = more important
CallStream (priority: 200)        // Call is most important

// Audio Mixer algorithm:
// 1. Sort streams by priority
// 2. CallStream: 100% volume
// 3. NavigationStream: 40% volume (call active)
// 4. MediaStream: 20% volume (background)
// 5. Mix: output = 1.0*call + 0.4*nav + 0.2*media
// 6. Normalize if sum > 1.0
```

---

## 3. Video HAL (`core/hal/multimedia/VideoHAL.h`)

### 3.1 Design and Purpose

**File**: `core/hal/multimedia/VideoHAL.h`  
**Implementation**: GStreamer (platform-independent)  
**Responsibilities**:
- Video codec abstraction (H.264, H.265, VP9)
- Hardware acceleration detection
- Frame rate adaptation
- Synchronisation with display refresh
- Error detection and recovery

### 3.2 Video Pipeline

```
Raw H.264 Bitstream (from AASDK/RTP)
    ↓
┌──────────────────────────────────────┐
│ GStreamer Pipeline                   │
│ ┌──────────────────────────────────┐ │
│ │ rtph264depay (RTP depacketizer)  │ │
│ └────────────┬─────────────────────┘ │
│              ↓                        │
│ ┌──────────────────────────────────┐ │
│ │ h264parse (NAL unit parser)      │ │
│ │ - Extract keyframes              │ │
│ │ - Parse SPS/PPS                  │ │
│ └────────────┬─────────────────────┘ │
│              ↓                        │
│ ┌──────────────────────────────────┐ │
│ │ avdec_h264 (libavcodec decoder)  │ │
│ │ OR nvdec_h264 (NVIDIA NVDEC)     │ │
│ │ OR vaapih264dec (VA-API)         │ │
│ │ - Decode NALU → YUV frames       │ │
│ │ - Hardware acceleration          │ │
│ └────────────┬─────────────────────┘ │
│              ↓                        │
│ ┌──────────────────────────────────┐ │
│ │ videoconvert (Format converter)  │ │
│ │ YUV I420 → RGB (GPU accel)       │ │
│ └────────────┬─────────────────────┘ │
│              ↓                        │
│ ┌──────────────────────────────────┐ │
│ │ videorate (Frame rate adapter)   │ │
│ │ Input fps ≠ output fps           │ │
│ └────────────┬─────────────────────┘ │
│              ↓                        │
│ ┌──────────────────────────────────┐ │
│ │ qtsink (Qt Video Output)         │ │
│ │ Render to QML VideoOutput widget │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
    ↓
Qt VideoOutput Widget
    ↓
Display (60Hz refresh)
```

### 3.3 Video Configuration

```cpp
enum class VideoResolution {
    VGA,        // 640×480
    WVGA,       // 800×480
    HD_720p,    // 1280×720 (recommended for automotive)
    HD_1080p,   // 1920×1080
    QHD,        // 2560×1440
};

struct VideoConfig {
    VideoResolution resolution;
    int frameRate;              // 30 or 60 fps
    int bitrate;                // kbps (used for encoding)
    QString codec;              // "h264", "h265", "vp9"
    int brightness;             // 0-100
    int contrast;               // 0-100
    bool hardwareAcceleration;  // Use GPU if available
};

// Automotive-optimized configuration
VideoConfig automotive = {
    resolution: VideoResolution::HD_720p,
    frameRate: 30,              // Sufficient for navigation
    bitrate: 2000,              // ~2 Mbps (conservative)
    codec: "h264",              // Widely supported
    brightness: 50,
    contrast: 50,
    hardwareAcceleration: true  // Reduce CPU load
};
```

### 3.4 Adaptive Bitrate Streaming

**Goal**: Maintain smooth playback under variable network conditions

```cpp
class GStreamerVideoDecoder {
    void monitorPerformance() {
        // Monitor every 1 second:
        // 1. Frame drop rate
        // 2. CPU usage
        // 3. Buffer depth
        
        if (frameDropRate > 5%) {
            // Network/CPU is struggling, reduce quality
            currentBitrate = max(500, currentBitrate - 500);  // -500 kbps
            requestNewQuality(currentBitrate);
        } else if (frameDropRate == 0 && cpuUsage < 40%) {
            // Network/CPU has headroom, increase quality
            currentBitrate = min(5000, currentBitrate + 500);  // +500 kbps
            requestNewQuality(currentBitrate);
        }
    }
    
    void requestNewQuality(int bitrate) {
        // Request encoder (on source device) to send at new bitrate
        // Wait for keyframe at new bitrate
        // Resume smooth playback
    }
};

// Scenario: Network degrades during Android Auto projection
Time   Network         CPU      Video                 Action
─────────────────────────────────────────────────────────────
0ms    5 Mbps avail    20%      1080p 60fps 5 Mbps   Normal
100ms  3 Mbps avail    30%      (network hiccup)
200ms  2 Mbps avail    45%      Frames starting drop
300ms  Detect 10% drop           Reduce to 720p 30fps  1.5 Mbps
400ms  2 Mbps stable   35%      720p 30fps 1.5 Mbps  Smooth again
1000ms 4 Mbps avail    20%      Network recovers
1100ms Detect low drop           Increase to 1080p 30fps 3 Mbps
1200ms 4 Mbps avail    25%      1080p 30fps 3 Mbps   Smooth
```

### 3.5 Latency Optimization

**Critical for driving**: Display latency must be <200ms

```cpp
// Latency breakdown:
Total Latency = Network + Decode + Convert + Render + Display
              = 50ms + 30ms + 10ms + 10ms + 16ms = 116ms

// Automotive target: <200ms (human reaction time ~300-400ms)

// Optimization techniques:
class VideoHALOptimized {
    // 1. Low-latency RTP profile (H.264 nal_hrd=cbr)
    // 2. Small GStreamer buffer sizes (caps.set_simple("max-lateness", 0))
    // 3. Hardware decoding (NVDEC, VAAPI, MediaCodec)
    // 4. GPU texture upload (zero-copy rendering)
    // 5. Sync to display refresh (60Hz for smooth playback)
};
```

### 3.6 Error Handling

```cpp
class VideoHALErrorHandler {
    void handleVideoErrors() {
        // Error 1: Corrupted H.264 frame
        // Symptoms: Decoder error, frame loss
        if (gstError == GST_CORE_ERROR_FAILED) {
            Logger::instance().warning("Video frame corruption");
            // Request keyframe from encoder
            emitEvent("video/request_keyframe");
            // Discard corrupted frame
            // Wait for next keyframe
        }
        
        // Error 2: Unsupported codec
        // Symptoms: Decoder not found
        if (gstError == GST_STREAM_ERROR_CODEC_NOT_FOUND) {
            Logger::instance().error("Unsupported codec");
            // Notify source to send different codec
            emitEvent("video/unsupported_codec");
            // Stop playback gracefully
        }
        
        // Error 3: Persistent frame drops (>20%)
        // Symptoms: High CPU, network lag
        if (frameDropRate > 20%) {
            Logger::instance().warning("Persistent frame drops");
            // Degrade resolution/framerate more aggressively
            // Notify user
            emitEvent("video/quality_degraded");
        }
    }
};
```

---

## 4. Transport Layer (`core/hal/transport/`)

### 4.1 Purpose

**Files**: `Transport.h`, `UARTTransport.h`, `Transport.cpp`

**Responsibilities**:
- Abstract data transport (USB, UART, CAN, TCP/IP)
- Framing and protocol handling
- Error detection (checksum, CRC)
- Connection state management

### 4.2 Transport Interface

```cpp
// Abstract interface
class ITransport {
public:
    virtual ~ITransport() = default;
    virtual bool connect() = 0;
    virtual bool isConnected() const = 0;
    virtual bool send(const QByteArray& data) = 0;
    virtual bool receive(QByteArray& data) = 0;
    virtual void disconnect() = 0;
};

// Implementations
class USBTransport : public ITransport { /* libusb */ };
class UARTTransport : public ITransport { /* serial port */ };
class CANTransport : public ITransport { /* SocketCAN */ };
class TCPTransport : public ITransport { /* Qt network */ };
```

### 4.3 UART Protocol (Vehicle Integration)

**Purpose**: Communicate with vehicle CAN bus gateway via UART

```
┌─────────────────────────────────────────┐
│ Vehicle CAN Bus                         │
│ (steering wheel, climate, diagnostics) │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│ CAN Gateway (e.g., OBD-II adapter)      │
│ Converts CAN → UART                    │
└────────────────┬────────────────────────┘
                 │ /dev/ttyUSB0
                 │ 115200 baud, 8N1
                 │
┌────────────────▼────────────────────────┐
│ Raspberry Pi UART                       │
│ /dev/ttyAMA0 (hardware) or GPIO        │
│ or /dev/ttyUSB0 (USB adapter)          │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│ UARTTransport (Crankshaft)              │
│ ├─ Opens serial port                    │
│ ├─ Configures: 115200, 8 bits, no parity
│ ├─ Reads/writes data                    │
│ └─ Handles errors                       │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│ CANDevice / FunctionalDevice            │
│ ├─ Parses UART frames                   │
│ ├─ Converts to standardised events      │
│ └─ Publishes to EventBus                │
└─────────────────────────────────────────┘
```

**UART Frame Format**:
```
Frame Structure:
┌────┬────────┬────────┬─────┬────┐
│STX │ LENGTH │ CMD    │DATA │CRC │
└────┴────────┴────────┴─────┴────┘
1B     1B      1B     VAR  1B

STX = 0x02 (Start of TeXt)
LENGTH = Length of CMD + DATA
CMD = Command type (0x10-0x1F)
DATA = Variable length payload
CRC = Checksum for error detection

Example: Steering wheel button press
────────────────────────────────────
Button ID: 0x14 (Next Track), State: Press
TX:  02 03 10 14 01 A7
     ├─ STX
     ├─ LENGTH = 3 (CMD + button_id + state)
     ├─ CMD = 0x10 (Button event)
     ├─ DATA = 0x14, 0x01 (button ID, pressed)
     └─ CRC = 0xA7

RX Processing:
1. Read bytes until STX (0x02)
2. Read LENGTH
3. Read CMD and DATA
4. Verify CRC
5. Parse command (e.g., button_press → media/next_track)
```

### 4.4 UART Error Handling

```cpp
class UARTTransport {
    // Error scenarios
    void handleFrameError() {
        // 1. CRC mismatch
        // Action: Discard frame, request retransmit
        
        // 2. Timeout (no data for 1 second)
        // Action: Send heartbeat/ping
        
        // 3. Framing error (invalid STX)
        // Action: Resynchronize (find next STX)
        
        // 4. Buffer overrun
        // Action: Clear buffer, reconnect
        
        // 5. Port disconnected
        // Action: Close, attempt reconnect with backoff
    }
};
```

---

## 5. Multimedia Pipeline (`core/hal/multimedia/MediaPipeline.h`)

### 5.1 Purpose

**File**: `core/hal/multimedia/MediaPipeline.h`

**Responsibilities**:
- Coordinate audio and video HALs
- Synchronise audio/video timing
- Manage stream lifecycle
- Handle simultaneous streams

### 5.2 Pipeline Architecture

```cpp
class MediaPipeline {
public:
    // Configuration and lifecycle
    bool start(const MediaConfig& config);
    bool stop();
    bool isActive() const;
    
    // Audio operations
    bool pushAudioData(const QByteArray& data);
    void setAudioRoute(AudioHAL::AudioRoute route);
    void setAudioVolume(int percent);
    
    // Video operations
    bool pushVideoFrame(const QByteArray& frameData);
    void setVideoResolution(VideoHAL::VideoResolution resolution);
    void setBrightness(int level);
};

// Scenario: Android Auto H.264+AAC streaming
MediaConfig config;
config.streamName = "AndroidAuto";
config.enableAudio = true;
config.enableVideo = true;
config.audioSampleRate = 48000;
config.audioChannels = 2;
config.videoCodec = "H264";
config.videoResolution = VideoHAL::VideoResolution::HD_720p;

MediaPipeline pipeline;
pipeline.start(config);

// Decode and feed data
while (projectionActive) {
    QByteArray h264Frame = aasdk->getVideoFrame();
    QByteArray aacSamples = aasdk->getAudioSamples();
    
    pipeline.pushVideoFrame(h264Frame);
    pipeline.pushAudioData(aacSamples);
}

pipeline.stop();
```

### 5.3 Audio/Video Synchronisation

**Challenge**: Audio and video may arrive at different times/rates

```cpp
class MediaPipeline {
    void synchronizeAudioVideo() {
        // Timestamp-based sync:
        // 1. All frames have timestamp (RTP timestamp)
        // 2. Audio buffer reads based on video timestamp
        // 3. If audio ahead: skip samples
        // 4. If audio behind: repeat samples
        
        // Typical sync window: ±80ms (human perception limit)
        if (abs(audioTimestamp - videoTimestamp) > 80) {
            Logger::instance().warning("Audio/video sync skew");
            audioBuffer.seek(videoTimestamp);  // Resync
        }
    }
};
```

---

## 6. Key Performance Metrics

| Component | Metric | Target | Actual |
|-----------|--------|--------|--------|
| Audio Latency | Input→Output | <50ms | ~30ms |
| Video Latency | Input→Display | <200ms | ~120ms |
| Audio Underruns | Per hour (vehicle) | 0 | <1 |
| Video Frame Drops | Per minute | 0 | <1 (acceptable) |
| Startup Time | HAL init | <500ms | ~200ms |
| Route Switch | Speaker→BT | Seamless | ~50ms |
| Memory (per stream) | Audio | <5MB | ~2MB |
| Memory (per stream) | Video | <10MB | ~8MB |

---

## 7. Testing HAL Components

### Unit Tests (Mock HAL)

```cpp
// Example: Audio route switch test
class AudioHALTest : public ::testing::Test {
protected:
    MockAudioHAL audioHal;
};

TEST_F(AudioHALTest, SwitchRouteSpeakerToHeadphone) {
    EXPECT_CALL(audioHal, setRoute(AudioRoute::Speaker));
    EXPECT_CALL(audioHal, setRoute(AudioRoute::Headset));
    
    audioHal.setRoute(AudioRoute::Speaker);
    EXPECT_TRUE(audioHal.isPlaying());
    
    audioHal.setRoute(AudioRoute::Headset);
    EXPECT_TRUE(audioHal.isPlaying());  // Still playing
}
```

### Integration Tests (Real HAL)

```cpp
// Test on actual hardware
void testAudioPlaybackRealDevice() {
    AudioHAL audioHal;
    audioHal.initialize();
    audioHal.setRoute(AudioRoute::Speaker);
    audioHal.startPlayback();
    
    // Generate 1kHz sine wave
    QByteArray testData = generateSineWave(1000, 48000, 2 * 48000);  // 2 seconds
    audioHal.pushAudio(testData);
    
    QThread::sleep(3000);  // Play + verify
    audioHal.stopPlayback();
}
```

---

## 8. Documentation Checklist

- [x] Audio HAL comprehensive scenarios
- [x] Video HAL codec and latency
- [x] Transport layer UART protocol
- [x] MediaPipeline coordination
- [x] Error handling strategies
- [ ] Hardware acceleration details
- [ ] CAN bus protocol specifics
- [ ] Bluetooth audio routing details
- [ ] Performance profiling guide
- [ ] Troubleshooting guide

---

**End of HAL Documentation**
