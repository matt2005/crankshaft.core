# Android Auto USB Connection Fix

## Problem

Real Android Auto service initialises AASDK components successfully but never connects to USB devices. Phone detected by kernel (18d1:4ee1 Google Pixel 8 Pro) but AASDK never attempts to open device or initiate Android Auto Protocol handshake.

## Root Cause Analysis

### What Was Found

1. **USBHub promise callback incomplete** (line 698-708 in RealAndroidAutoService.cpp):
   ```cpp
   auto promise = aasdk::usb::IUSBHub::Promise::defer(*m_ioService);
   promise->then(
       [this](auto device) {  // ← 'device' parameter is the DeviceHandle
         Logger::instance().info("Device connected");
         // Device connection will be handled in device hotplug callback
       },
       ...
   ```
   - Promise callback receives `DeviceHandle` parameter but ignores it
   - Comment says "will be handled in device hotplug callback" but callback never receives device handle
   - No code to create AOAPDevice, transport, or initiate connection

2. **onUSBHotplug callback not wired** (line 966):
   - Method `onUSBHotplug(bool connected)` exists but is never registered with USBHub
   - USBHub doesn't call external callbacks; it only resolves promises when device ready
   - Callback would need device handle to open device, but has no way to receive it

3. **Missing io_service event loop integration**:
   - AASDK uses boost::asio async operations
   - No evidence of `io_service->run()` or `poll()` being called
   - Qt event loop (QCoreApplication::exec()) doesn't process io_service events
   - Async operations never complete even if scheduled

### How USBHub Actually Works

Based on AASDK source (external/aasdk/src/USB/USBHub.cpp):

1. `USBHub::start(promise)` registers libusb hotplug callback
2. When device plugged in, `hotplugEventsHandler` called by libusb
3. `handleDevice()` opens device and checks if already in AOAP mode
4. If not AOAP, `AccessoryModeQueryChain` executes AAP handshake sequence
5. When device switches to AOAP mode, promise resolves with `DeviceHandle`
6. **Caller must use DeviceHandle to create AOAPDevice and start transport**

Current implementation stops at step 5 - promise resolves but handle discarded.

## Required Fixes

### 1. Complete Promise Callback (Critical)

Update promise handler at line 698 to use the device handle:

```cpp
auto promise = aasdk::usb::IUSBHub::Promise::defer(*m_ioService);
promise->then(
    [this](aasdk::usb::DeviceHandle deviceHandle) {
      Logger::instance().info("Device connected, creating AOAP transport");
      
      // Create AOAP device from handle
      m_aoapDevice = std::make_shared<aasdk::usb::AOAPDevice>(
          *m_usbWrapper, *m_ioService, std::move(deviceHandle));
      
      // Create USB transport
      m_transport = std::make_shared<aasdk::transport::USBTransport>(
          *m_ioService, m_aoapDevice);
      
      // Create messenger with transport
      createMessenger(m_transport);
      
      // Start AAP protocol
      startProtocol();
      
      // Update device metadata
      handleDeviceDetected();
      
      // Update state
      handleConnectionEstablished();
    },
    [this](const aasdk::error::Error& error) {
      Logger::instance().error(
          QString("USB hub error: %1").arg(QString::fromStdString(error.what())));
      transitionToState(ConnectionState::DISCONNECTED);
    });
m_usbHub->start(std::move(promise));
```

### 2. Integrate io_service with Qt Event Loop (Critical)

AASDK async operations require io_service to be polled. Add integration in RealAndroidAutoService constructor or start():

```cpp
// Option A: Use QTimer to poll io_service periodically
m_ioServiceTimer = std::make_unique<QTimer>();
connect(m_ioServiceTimer.get(), &QTimer::timeout, this, [this]() {
  if (m_ioService) {
    m_ioService->poll();  // Process pending async operations
  }
});
m_ioServiceTimer->start(10);  // Poll every 10ms

// Option B: Use QSocketNotifier for better integration (preferred)
// Create notifier for io_service file descriptor if available
// Requires platform-specific implementation
```

**Alternative**: Run io_service in dedicated thread (already have m_aasdkThread):
```cpp
void RealAndroidAutoService::ioServiceThreadFunc() {
  while (!m_stopRequested) {
    try {
      m_ioService->run();  // Blocks until work available
      if (!m_stopRequested) {
        m_ioService->reset();  // Reset for next run
      }
    } catch (const std::exception& e) {
      Logger::instance().error(
          QString("io_service error: %1").arg(e.what()));
    }
  }
}

// In constructor or setupAASDK():
m_aasdkThread = QThread::create([this]() { ioServiceThreadFunc(); });
m_aasdkThread->start();
```

### 3. Remove Unused onUSBHotplug Callback (Optional)

Since USBHub uses promise pattern, not external callbacks:
- Remove `onUSBHotplug()` method (line 966)
- Remove `handleDeviceDetected()` and `handleDeviceRemoved()` if only called from hotplug
- Or repurpose for higher-level logic after promise callback completes

### 4. Add Missing Helper Methods

Need implementations for:
- `createMessenger(transport)` - create Messenger with transport and register channel handlers
- `startProtocol()` - send handshake messages to start AAP protocol
- `setupChannels()` - create video, audio, input, sensor channels after handshake

Reference openauto `AndroidAutoEntity` class for protocol flow.

## Testing Strategy

### Phase 1: Verify Device Detection
1. Enable debug logging: `sudo bash ./scripts/collect-android-diagnostics-extended.sh --enable-debug`
2. Restart services: `sudo systemctl restart crankshaft-core crankshaft-ui`
3. Plug in phone
4. Expected logs:
   ```
   [AASDK] Hotplug event: device arrived
   [AASDK] Opening device 18d1:4ee1
   [AASDK] Device not in AOAP mode, starting query chain
   [AASDK] Sending protocol version query
   [AASDK] Sending accessory strings
   [AASDK] Sending accessory start command
   [AASDK] Device re-enumerated as AOAP device
   [RealAndroidAutoService] Device connected, creating AOAP transport
   ```

### Phase 2: Verify Protocol Handshake
1. Check for AAP version exchange:
   ```
   [Messenger] Sending VersionRequest
   [Messenger] Received VersionResponse
   ```
2. Check for SSL handshake:
   ```
   [Cryptor] Starting SSL handshake
   [Cryptor] SSL handshake complete
   ```
3. Check for channel negotiation:
   ```
   [Messenger] Sending ServiceDiscoveryRequest
   [Messenger] Received ServiceDiscoveryResponse
   [Messenger] Starting video channel
   [Messenger] Starting audio channel
   [Messenger] Starting input channel
   ```

### Phase 3: Verify Data Flow
1. Phone screen should project to display
2. Touch input should work
3. Audio should play through head unit

## Dependencies

- AASDK library (already linked)
- libusb-1.0 (already dependency of AASDK)
- boost::asio (already dependency of AASDK)
- Qt6Core (already linked)

## Estimated Effort

- Fix 1 (promise callback): 2-4 hours
- Fix 2 (io_service integration): 2-3 hours
- Fix 3 (cleanup): 30 minutes
- Fix 4 (helper methods): 4-8 hours (depends on complexity of protocol implementation)
- Testing: 2-4 hours

**Total: 10-20 hours**

## References

- AASDK USBHub: `external/aasdk/src/USB/USBHub.cpp`
- AASDK AOAPDevice: `external/aasdk/include/aasdk/USB/AOAPDevice.hpp`
- Openauto App: `openauto/src/autoapp/App.cpp` (reference implementation)
- Openauto AndroidAutoEntity: `openauto/src/autoapp/Service/AndroidAutoEntity.cpp`
- Diagnostic logs: `run-20386407531-logs/crankshaft-diagnostics-1766315138/`

## Related Issues

- Phone appears in MTP mode (18d1:4ee1) - normal, AASDK switches to AOAP via USB control transfers
- Device re-enumeration (006→007) - expected when switching to AOAP mode
- Driver=[none] - correct, libusb claims device in userspace, no kernel driver needed

## Next Steps

1. Implement Fix 1 and Fix 2
2. Build and test with debug logging enabled
3. Verify device detection and handle passing
4. Implement protocol handshake (Fix 4) if needed
5. Test with real phone
6. Document any additional issues found
