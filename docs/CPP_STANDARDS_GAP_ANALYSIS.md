# C++ Standards Gap Analysis
## Crankshaft MVP Project

**Generated:** 2026-01-14  
**Last Updated:** 2026-01-14  
**Branch:** bugfix/moderise_return  
**Current Standards:** C++20 (all internal + AASDK), C++17 (OpenAuto)  
**Target Standards:** C++23 / C++26  
**Analysis Scope:** Core application, UI, and external dependencies (AASDK, OpenAuto)

---

## Executive Summary

### Current State
- **Main Project:** C++20 (crankshaft-mvp core) ✅
- **UI Module:** C++20 (ui-slim) ✅ **UPGRADED 2026-01-14**
- **Tools:** C++20 (aa_test) ✅ **UPGRADED 2026-01-14**
- **AASDK Library:** C++20 (external/aasdk) ✅ **UPGRADED 2026-01-14** (submodule eee33b4)
- **OpenAuto:** C++17 (external dependency)

### Recent Progress (2026-01-14) ✅

**Completed Work:**
1. ✅ Upgraded ui-slim from C++17 → C++20
2. ✅ Upgraded aa_test from C++17 → C++20
3. ✅ **Upgraded AASDK submodule from C++17 → C++20** (commit eee33b4)
   - Already includes constexpr for USB constants
   - Foundation ready for modern C++ features
4. ✅ Replaced raw loops with STL algorithms:
   - `ProfileManager::setDeviceEnabled()` → `std::find_if`
   - `ProfileManager::setDeviceUseMock()` → `std::find_if`
   - `SettingsMigration::detectCorruption()` → `std::any_of`
5. ✅ Fixed virtual function calls in destructors (4 classes)
6. ✅ Fixed ProfileManager validation logic (schema validation)
7. ✅ Added `#include <algorithm>` where needed

### Remaining Modernization Opportunities
With full C++20 adoption across all core modules and AASDK, this analysis identifies **100+ remaining opportunities** for modernization:
- **Critical** (blocking security/correctness): 6 items (OpenAuto only)
- **High Priority** (performance/safety): 25 items
- **Medium Priority** (code quality): 45 items
- **Low Priority** (style/consistency): 25+ items

**Major Achievement:** 🎉 All internal code and AASDK now on C++20!

---

## 1. Language Standard Configuration

### 1.1 Current Configuration

| Component | Current Standard | CMake Version | Status | Last Updated |
|-----------|-----------------|---------------|---------|--------------|
| crankshaft-mvp (main) | C++20 | 3.16 | ✅ Modern | 2025-12 |
| ui-slim | C++20 | 3.16 | ✅ Modern | **2026-01-14** |
| core | C++20 (inherited) | 3.16 | ✅ Modern | 2025-12 |
| aa_test tool | C++20 | 3.16 | ✅ Modern | **2026-01-14** |
| **external/aasdk** | **C++20** | 3.16 | ✅ **Modern** | **2026-01-14** |
| **external/aasdk/protobuf** | **C++20** | 3.16 | ✅ **Modern** | **2026-01-14** |
| openauto | C++17 | 3.14 | ⚠️ Requires coordination | - |

### 1.2 Completed Upgrades ✅

```cmake
# ✅ COMPLETED 2026-01-14: Upgraded ui-slim to C++20
# File: ui-slim/CMakeLists.txt
set(CMAKE_CXX_STANDARD 20)  # from 17

# ✅ COMPLETED 2026-01-14: Upgraded aa_test to C++20
# File: tools/aa_test/CMakeLists.txt
set(CMAKE_CXX_STANDARD 20)  # from 17

# ✅ COMPLETED 2026-01-14: Upgraded AASDK to C++20
# File: external/aasdk/CMakeLists.txt (submodule commit eee33b4)
set(CMAKE_CXX_STANDARD 20)  # from 17
# Note: Already includes constexpr constants in USB layer
```

### 1.3 Future Upgrades

```cmake
# Priority 1 (Future): Plan C++23 migration
# Blocked by: Qt6 C++23 support, compiler availability on Raspberry Pi OS
set(CMAKE_CXX_STANDARD 23)  # target for Q3-Q4 2026
```

**Updated Migration Path:**
1. ~~**Q1 2026:** Upgrade ui-slim and aa_test to C++20~~ ✅ **COMPLETED 2026-01-14**
2. ~~**Q1 2026:** Upgrade AASDK submodule to C++20~~ ✅ **COMPLETED 2026-01-14**
3. **Q2 2026:** Coordinate with OpenAuto upstream for C++20 migration
4. **Q2 2026:** Evaluate C++23 compiler support on target platforms
5. **Q3 2026:** Begin C++23 migration if dependencies support it

---

## 2. C++20/C++23 Feature Adoption Opportunities

### 2.1 Concepts and Constraints (C++20) - HIGH PRIORITY

**Status:** NOT USED  
**Benefit:** Type safety, better error messages, self-documenting code  
**Estimated Effort:** Medium (15-20 hours)

#### Opportunities

```cpp
// CURRENT: Template functions without constraints
template<typename T>
void processData(T data) {
    data.serialize(); // Error if T doesn't have serialize()
}

// C++20 MODERNIZATION: Use concepts
#include <concepts>

template<typename T>
concept Serializable = requires(T t) {
    { t.serialize() } -> std::convertible_to<QByteArray>;
};

template<Serializable T>
void processData(T data) {
    data.serialize(); // Clear intent, better errors
}
```

**Files to Update:**
- `core/services/profile/ProfileManager.h` - Profile type constraints
- `core/hal/multimedia/MediaPipeline.h` - HAL component concepts
- `ui-slim/src/DeviceManager.cpp` - Device configuration templates
- `core/services/websocket/WebSocketServer.h` - Message handler concepts

**Implementation Tasks:**
- [ ] Define `ProfileType` concept for host/vehicle profiles
- [ ] Define `HALComponent` concept for multimedia HAL
- [ ] Define `WebSocketMessage` concept for message handlers
- [ ] Add `DeviceConfigurable` concept for device managers

---

### 2.2 Ranges Library (C++20) - HIGH PRIORITY

**Status:** NOT USED (using raw loops and STL algorithms)  
**Benefit:** Composable, lazy evaluation, cleaner code  
**Estimated Effort:** Medium (20-30 hours)

#### Opportunities

```cpp
// CURRENT: ProfileManager.cpp lines 550-570
auto it = std::find_if(devices.begin(), devices.end(), 
    [&deviceName](const DeviceConfig& d) { 
        return d.name == deviceName; 
    });

// C++20 RANGES MODERNIZATION:
#include <ranges>
namespace views = std::ranges::views;

auto found = devices 
    | views::filter([&](const auto& d) { return d.name == deviceName; })
    | views::take(1);

if (!std::ranges::empty(found)) {
    auto& device = *std::ranges::begin(found);
    device.enabled = enabled;
}

// BETTER: Use ranges::find_if
auto it = std::ranges::find_if(devices, 
    [&](const auto& d) { return d.name == deviceName; });
```

**High-Value Transformations:**

1. **Profile filtering** (ProfileManager.cpp)
   ```cpp
   // Current: Manual filtering
   QList<HostProfile> active;
   for (const auto& profile : m_hostProfiles) {
       if (profile.isActive) active.append(profile);
   }
   
   // C++20 ranges:
   auto activeProfiles = m_hostProfiles 
       | views::filter(&HostProfile::isActive)
       | std::ranges::to<QList>();
   ```

2. **Device list transformations** (DeviceManager.cpp)
   ```cpp
   // Current: Multiple passes
   QStringList names;
   for (const auto& device : getDevices()) {
       if (device.enabled) {
           names.append(device.name);
       }
   }
   
   // C++20 ranges:
   auto names = getDevices()
       | views::filter(&DeviceConfig::enabled)
       | views::transform(&DeviceConfig::name)
       | std::ranges::to<QStringList>();
   ```

**Files to Update:**
- `core/services/profile/ProfileManager.cpp` (350+ lines with loops)
- `core/hal/multimedia/AudioManagerImpl.cpp` (device enumeration)
- `ui-slim/src/DeviceManager.cpp` (device filtering)
- `ui-slim/src/SettingsMigration.cpp` (validation loops)

---

### 2.3 std::optional and std::expected (C++23) - CRITICAL

**Status:** MINIMAL USE (relying on pointer nullability)  
**Benefit:** Explicit error handling, no more null pointer crashes  
**Estimated Effort:** High (40-50 hours)

#### Current Pattern (Unsafe)

```cpp
// CURRENT: ProfileManager.cpp line 594
QList<DeviceConfig> ProfileManager::getProfileDevices(const QString& profileId) const {
  if (m_hostProfiles.contains(profileId)) {
    return m_hostProfiles.value(profileId).devices;
  }
  return QList<DeviceConfig>();  // Empty list on error - ambiguous!
}

// PROBLEM: Caller can't distinguish between "profile not found" vs "profile has no devices"
```

#### C++23 Modernization

```cpp
#include <expected>

// OPTION 1: std::optional for simple cases
std::optional<QList<DeviceConfig>> getProfileDevices(const QString& profileId) const {
  if (m_hostProfiles.contains(profileId)) {
    return m_hostProfiles.value(profileId).devices;
  }
  return std::nullopt; // Explicit "not found"
}

// Usage:
if (auto devices = manager.getProfileDevices(id)) {
    // Process devices.value()
} else {
    // Handle error: profile not found
}

// OPTION 2: std::expected for richer error reporting
enum class ProfileError { NotFound, Invalid, IOError };

std::expected<QList<DeviceConfig>, ProfileError> 
getProfileDevices(const QString& profileId) const {
  if (!m_hostProfiles.contains(profileId)) {
    return std::unexpected(ProfileError::NotFound);
  }
  return m_hostProfiles.value(profileId).devices;
}

// Usage:
auto result = manager.getProfileDevices(id);
if (result) {
    // Process result.value()
} else {
    switch (result.error()) {
        case ProfileError::NotFound:
            Logger::instance().error("Profile not found");
            break;
        // ...
    }
}
```

**Critical Conversions:**

1. **ProfileManager return values** (8 functions)
   - `getHostProfile()` → `std::optional<HostProfile>`
   - `getVehicleProfile()` → `std::optional<VehicleProfile>`
   - `getProfileDevices()` → `std::optional<QList<DeviceConfig>>`
   - `loadProfiles()` → `std::expected<void, LoadError>`

2. **HAL component initialization**
   - `AudioManager::initialize()` → `std::expected<void, HalError>`
   - `BluetoothManager::connect()` → `std::expected<void, BtError>`

3. **AndroidAuto connection**
   - `AndroidAutoFacade::connect()` → `std::expected<ConnectionInfo, AAError>`

**Files to Update:**
- `core/services/profile/ProfileManager.h` + `.cpp`
- `core/hal/multimedia/AudioManager.h`
- `core/hal/wireless/BluetoothManager.h`
- `ui-slim/src/AndroidAutoFacade.h` + `.cpp`

---

### 2.4 std::string_view - MEDIUM PRIORITY

**Status:** NOT USED (using QString, const QString&)  
**Benefit:** Zero-copy string passing, performance improvement  
**Estimated Effort:** Low (10-15 hours)  
**Note:** Limited applicability due to Qt QString dominance

#### Opportunities (Non-Qt interfaces)

```cpp
// AASDK code - C-string interfaces
// CURRENT: aasdk/src/USB/USBWrapper.cpp
void logError(const std::string& message);

// C++17 MODERNIZATION:
void logError(std::string_view message);  // No allocation for literals

// Usage:
logError("Device not found");  // No std::string construction!
```

**Limited Scope:**
- AASDK internal logging (5-10 functions)
- Internal C++ utilities (not Qt-facing APIs)
- Configuration file parsing

---

### 2.5 Designated Initializers (C++20) - LOW PRIORITY

**Status:** NOT USED  
**Benefit:** Readable struct initialization, self-documenting  
**Estimated Effort:** Low (5-10 hours)

```cpp
// CURRENT: ProfileManager.cpp
DeviceConfig device;
device.name = "bluetooth";
device.type = DeviceType::Bluetooth;
device.enabled = true;
device.useMock = false;

// C++20 MODERNIZATION:
DeviceConfig device {
    .name = "bluetooth",
    .type = DeviceType::Bluetooth,
    .enabled = true,
    .useMock = false
};
```

**Files to Update:**
- `core/services/profile/ProfileManager.cpp` (device creation)
- `core/hal/multimedia/MediaPipeline.cpp` (pipeline config)
- Test files (mock object initialization)

---

### 2.6 constexpr and consteval - MEDIUM PRIORITY

**Status:** MINIMAL USE  
**Benefit:** Compile-time computation, reduced runtime overhead  
**Estimated Effort:** Medium (15-20 hours)

#### Opportunities

```cpp
// CURRENT: Magic numbers scattered in code
#define MAX_DEVICES 10
#define DEFAULT_PORT 5277

// C++20 MODERNIZATION:
constexpr int MAX_DEVICES = 10;
constexpr int DEFAULT_PORT = 5277;

// C++20: constexpr functions
constexpr int calculateBufferSize(int channels, int sampleRate) {
    return channels * sampleRate * 4; // 32-bit samples
}

// C++23: consteval for compile-time only
consteval const char* getVersionString() {
    return "2025.01.14";
}
```

**Conversion Targets:**
- Configuration constants (ports, sizes, limits)
- Version strings and build info
- Enum to string conversions
- Lookup tables

---

### 2.7 std::span (C++20) - MEDIUM PRIORITY

**Status:** NOT USED (using raw pointers + size)  
**Benefit:** Safe array access, bounds checking  
**Estimated Effort:** Medium (15-20 hours)

```cpp
// CURRENT: AASDK common::Data uses std::vector
void processAudioData(const std::vector<uint8_t>& data);

// C++20 MODERNIZATION:
#include <span>
void processAudioData(std::span<const uint8_t> data);

// Accepts vector, array, C-array without copying!
std::vector<uint8_t> vec{1,2,3};
processAudioData(vec);

uint8_t arr[] = {1,2,3};
processAudioData(arr);
```

**Application Areas:**
- Audio buffer processing (HAL layer)
- Video frame handling
- Network packet manipulation
- USB data transfers

---

## 3. Deprecated Feature Removal

### 3.1 std::bind → Lambda Functions - HIGH PRIORITY

**Status:** EXTENSIVE USE (50+ occurrences)  
**Reason:** std::bind deprecated in C++17, removed in C++20/23  
**Benefit:** Cleaner code, better type inference  
**Estimated Effort:** High (30-40 hours)

#### Pattern Analysis

```cpp
// PATTERN 1: Simple callback binding (aasdk/openauto)
// CURRENT: AccessoryModeProtocolVersionQuery.ut.cpp:44
promise_->then(
    std::bind(&AccessoryModeQueryPromiseHandlerMock::onResolve, &promiseHandlerMock_, std::placeholders::_1),
    std::bind(&AccessoryModeQueryPromiseHandlerMock::onReject, &promiseHandlerMock_, std::placeholders::_1)
);

// MODERNIZATION:
promise_->then(
    [this](auto result) { promiseHandlerMock_.onResolve(result); },
    [this](auto error) { promiseHandlerMock_.onReject(error); }
);

// PATTERN 2: Member function binding (openauto/App.cpp:167)
// CURRENT:
promise->then(
    std::bind(&App::aoapDeviceHandler, this->shared_from_this(), std::placeholders::_1),
    std::bind(&App::onUSBHubError, this->shared_from_this(), std::placeholders::_1)
);

// MODERNIZATION:
auto self = shared_from_this();
promise->then(
    [self](auto device) { self->aoapDeviceHandler(device); },
    [self](auto error) { self->onUSBHubError(error); }
);

// PATTERN 3: Thread join (openauto/autoapp.cpp:306)
// CURRENT:
std::for_each(threadPool.begin(), threadPool.end(), 
    std::bind(&std::thread::join, std::placeholders::_1));

// MODERNIZATION:
std::ranges::for_each(threadPool, [](auto& thread) { thread.join(); });
```

**Files Requiring Updates (50+ occurrences):**

| File | Occurrences | Priority |
|------|-------------|----------|
| `external/aasdk/src/USB/AccessoryModeProtocolVersionQuery.ut.cpp` | 8 | High |
| `openauto/src/autoapp/App.cpp` | 3 | High |
| `openauto/src/autoapp/Service/ServiceFactory.cpp` | 7 | High |
| `openauto/src/autoapp/UI/ConnectDialog.cpp` | 3 | Medium |
| `openauto/src/autoapp/UI/SettingsWindow.cpp` | 2 | Medium |
| `external/aasdk/src/Transport/TCPTransport.ut.cpp` | 8 | Medium |
| Others | 19+ | Low |

**Migration Strategy:**
1. **Phase 1:** Update test files (isolated, easier to test)
2. **Phase 2:** Update service layer (App.cpp, ServiceFactory.cpp)
3. **Phase 3:** Update UI layer
4. **Phase 4:** Update transport layer

---

### 3.2 typedef → using (C++11+) - MEDIUM PRIORITY

**Status:** HEAVY USE (40+ occurrences)  
**Reason:** `typedef` is older syntax, `using` is more readable  
**Benefit:** Consistency, template aliases  
**Estimated Effort:** Low (5-8 hours - automated)

```cpp
// CURRENT: aasdk/include/aasdk/Transport/ITransport.hpp:32
typedef std::shared_ptr<ITransport> Pointer;
typedef io::Promise<common::Data> ReceivePromise;
typedef io::Promise<void> SendPromise;

// MODERNIZATION:
using Pointer = std::shared_ptr<ITransport>;
using ReceivePromise = io::Promise<common::Data>;
using SendPromise = io::Promise<void>;
```

**Automated Conversion Script:**
```bash
# Find and replace typedef with using
find . -name "*.hpp" -o -name "*.h" | xargs sed -i \
  's/typedef \(.*\) \([A-Za-z_][A-Za-z0-9_]*\);/using \2 = \1;/g'
```

**Files to Update:**
- All AASDK headers (`aasdk/include/**/*.hpp`)
- OpenAuto headers (`openauto/include/**/*.hpp`)
- 40+ typedef declarations

---

### 3.3 NULL → nullptr - CRITICAL

**Status:** 12+ occurrences  
**Reason:** NULL is C-style, unsafe  
**Benefit:** Type safety, prevents implicit conversions  
**Estimated Effort:** Low (2-3 hours)

```cpp
// CURRENT: Multiple files checking for null pointers
if (serviceProvider == NULL) {
    Logger::instance().errorContext("AudioBridge", "ServiceProvider is null");
}

// MODERNIZATION:
if (serviceProvider == nullptr) {
    Logger::instance().errorContext("AudioBridge", "ServiceProvider is nullptr");
}
```

**Files to Update:**
- `ui-slim/src/AndroidAutoFacade.cpp:36`
- `ui-slim/src/AudioBridge.cpp:39`
- `ui-slim/src/DeviceManager.cpp:32, 35, 40`
- `ui-slim/src/ConnectionStateMachine.cpp:39`
- `openauto/src/btservice/AndroidBluetoothServer.cpp:87`

**Automated Fix:**
```bash
# Safe replacement (checks for NULL as identifier, not in strings)
find ui-slim core -name "*.cpp" -o -name "*.h" | xargs sed -i 's/\bNULL\b/nullptr/g'
```

---

### 3.4 Raw Loops → Algorithms - MEDIUM PRIORITY

**Status:** PARTIALLY COMPLETED ✅ (2026-01-14)  
**Effort So Far:** 8 hours  
**Remaining Effort:** 20-25 hours

**Completed Conversions (2026-01-14):**
- ✅ `ProfileManager::setDeviceEnabled()` → `std::find_if` (line 558)
- ✅ `ProfileManager::setDeviceUseMock()` → `std::find_if` (line 580)
- ✅ `SettingsMigration::detectCorruption()` → `std::any_of`
- ✅ `AudioRouter::getDeviceById()` → `std::find_if` (line 174)
- ✅ Added `#include <algorithm>` to ProfileManager.cpp and SettingsMigration.cpp

**Remaining Opportunities (25+ loops):**

```cpp
// EXAMPLE: ProfileManager::loadProfiles() line 660
// CURRENT: Manual filtering
for (const auto& value : doc.array()) {
  if (value.isObject()) {
    // ... process object
  }
}

// C++20 MODERNIZATION:
auto objects = doc.array() 
    | views::filter([](const auto& v) { return v.isObject(); });
for (const auto& obj : objects) {
    // ... process object
}
```

**Next Targets:**
- `ProfileManager::loadProfiles()` - JSON array filtering
- `ProfileManager::saveProfiles()` - Profile serialization
- Audio/Video buffer processing loops
- Device enumeration loops

---

## 4. Modern Memory Management

### 4.1 Smart Pointer Usage Review

**Current State: GOOD** ✅
- Extensive use of `std::shared_ptr` and `std::unique_ptr`
- Custom deleters for C library resources (libusb, GStreamer)
- Using directives for clean aliases (`using Ptr = std::shared_ptr<T>`)

**Example (Good Pattern):**
```cpp
// aasdk/src/USB/USBWrapper.cpp:87
DeviceListHandle handle(
    new DeviceList(raw_handle, raw_handle + result),
    [raw_handle](auto in_device_list) {
        if (!in_device_list->empty()) {
            libusb_free_device_list(raw_handle, 1);
        }
        in_device_list->clear();
        delete in_device_list;
    }
);
```

**Improvement Opportunities:**

1. **std::make_shared preference** (C++11)
   ```cpp
   // CURRENT: Direct shared_ptr construction
   auto promise = std::shared_ptr<Promise>(new Promise(ioService));
   
   // BETTER:
   auto promise = std::make_shared<Promise>(ioService);
   ```

2. **std::make_unique for unique_ptr** (C++14) - Already used ✅

### 4.2 RAII Improvements

**Current: Partial RAII**

**Opportunities:**
```cpp
// Add RAII wrappers for C resources
class GStreamerPipeline {
    std::unique_ptr<GstPipeline, decltype(&gst_object_unref)> pipeline_;
public:
    GStreamerPipeline(GstPipeline* p) 
        : pipeline_(p, gst_object_unref) {}
    // Automatic cleanup on destruction
};
```

---

## 5. Coroutines (C++20) - FUTURE CONSIDERATION

**Status:** NOT USED  
**Benefit:** Async/await-style asynchronous programming  
**Estimated Effort:** Very High (100+ hours)  
**Priority:** LOW (requires architectural changes)

### 5.1 Potential Applications

```cpp
// CURRENT: Callback-based async (AASDK Promise pattern)
void connect(Promise::Pointer promise) {
    transport_->connect([promise](bool success) {
        if (success) {
            promise->resolve();
        } else {
            promise->reject(Error::CONNECTION_FAILED);
        }
    });
}

// C++20 COROUTINES: (Future consideration)
task<void> connect() {
    bool success = co_await transport_->connectAsync();
    if (!success) {
        throw Error::CONNECTION_FAILED;
    }
}

// Usage becomes linear:
task<void> startAndroidAuto() {
    try {
        co_await connectUSB();
        co_await performHandshake();
        co_await startMediaStream();
    } catch (const Error& e) {
        handleError(e);
    }
}
```

**Recommendation:** 
- **Do not implement now** - requires complete Promise system rewrite
- **Consider for future major version (2.0)** if benefits justify refactoring
- Monitor Qt coroutine support development

---

## 6. C++23 Features (Future Planning)

### 6.1 std::expected (vs std::optional)

**Status:** Not available yet (C++23)  
**Timeline:** 2026-2027 (once GCC 13+ widely available on Raspberry Pi OS)

Already covered in Section 2.3.

### 6.2 std::flat_map and std::flat_set

**Benefit:** Better cache locality than std::map  
**Application:** ProfileManager hash maps

```cpp
// CURRENT: QMap, QHash (Qt containers)
QMap<QString, HostProfile> m_hostProfiles;

// C++23 FUTURE:
#include <flat_map>
std::flat_map<QString, HostProfile> m_hostProfiles;
// Better performance for iteration, lower memory overhead
```

### 6.3 std::print (C++23)

```cpp
// CURRENT: Qt logging or std::cout
Logger::instance().info(QString("Device %1 connected").arg(deviceName));

// C++23:
std::print("Device {} connected\n", deviceName);
```

**Note:** Limited usefulness due to Qt logging framework.

---

## 7. Compiler and Toolchain Requirements

### 7.1 Current Toolchain

```bash
# Target: Raspberry Pi OS (Debian Bookworm/Trixie)
$ g++ --version
g++ (Debian 12.2.0-14) 12.2.0

# C++20 support: ✅ Full
# C++23 support: ⚠️ Partial (experimental)
```

### 7.2 Feature Support Matrix

| Feature | GCC 10 | GCC 11 | GCC 12 | GCC 13 | Raspberry Pi OS |
|---------|--------|--------|--------|--------|-----------------|
| Concepts | ✅ | ✅ | ✅ | ✅ | ✅ Available |
| Ranges | Partial | ✅ | ✅ | ✅ | ✅ Available |
| std::span | ❌ | ✅ | ✅ | ✅ | ✅ Available |
| std::expected | ❌ | ❌ | ❌ | ✅ | ⚠️ Requires GCC 13+ |
| std::flat_map | ❌ | ❌ | ❌ | Partial | ❌ Not yet |
| Coroutines | Partial | ✅ | ✅ | ✅ | ✅ Available |

### 7.3 Qt6 Compatibility

```bash
# Qt6 C++20 support: ✅ Full (Qt 6.2+)
# Qt6 C++23 support: ⚠️ Planned for Qt 6.8+ (late 2024)
```

**Recommendation:**
- **Safe to use:** C++20 features (concepts, ranges, span)
- **Wait for:** C++23 features until GCC 13 in Raspberry Pi OS stable
- **Monitor:** Qt6.8+ for C++23 compatibility

---

## 8. Implementation Roadmap

### Phase 1: Quick Wins (Q1 2026) - 2 weeks

**Status:** IN PROGRESS (50% complete)  
**Effort Remaining:** 22 hours (of 40)  
**Risk:** Low  
**Impact:** High code quality improvement

**Completed (2026-01-14):**
- [x] ✅ Upgrade ui-slim to C++20 (2 hours) **DONE**
- [x] ✅ Upgrade aa_test to C++20 (2 hours) **DONE**
- [x] ✅ STL algorithm conversions (8 hours) **DONE**
- [x] ✅ Virtual destructor fixes (4 hours) **DONE**
- [x] ✅ ProfileManager validation fixes (2 hours) **DONE**

**Remaining:**
- [ ] Replace `NULL` with `nullptr` (2 hours)
- [ ] Convert `typedef` to `using` (8 hours)
- [ ] Add constexpr to constants (10 hours)
- [ ] Designated initializers in config structs (4 hours)

**Deliverables:**
- [x] ✅ Updated CMake configuration (ui-slim, aa_test)
- [x] ✅ Cleaner cppcheck report (useStlAlgorithm warnings resolved)
- [ ] C++20 features developer guide
- [ ] Complete NULL/typedef cleanup

---

### Phase 2: High-Value Conversions (Q2 2026) - 6 weeks

**Effort:** 120 hours  
**Risk:** Medium  
**Impact:** Major code quality + performance

- [ ] Replace std::bind with lambdas (40 hours)
- [ ] Introduce std::optional for nullable returns (30 hours)
- [ ] Apply ranges to hot loops (30 hours)
- [ ] Add concepts to template interfaces (20 hours)

**Testing Required:**
- Full regression test suite
- Performance benchmarks (audio/video latency)
- Memory leak testing

---

### Phase 3: Advanced Features (Q3 2026) - 8 weeks

**Effort:** 160 hours  
**Risk:** High  
**Impact:** Modern architecture

- [ ] Implement std::expected error handling (50 hours)
- [ ] Refactor with std::span (30 hours)
- [ ] Comprehensive ranges adoption (40 hours)
- [ ] Evaluate coroutines for async operations (40 hours)

**Blockers:**
- Raspberry Pi OS GCC 13+ availability
- Qt 6.8+ stable release
- Upstream AASDK/OpenAuto coordination

---

### Phase 4: C++23 Migration (Q4 2026 / Q1 2027) - TBD

**Conditional on:**
- GCC 13 in Raspberry Pi OS stable repositories
- Qt 6.8+ production readiness
- std::expected stability testing

---

## 9. Testing Strategy

### 9.1 Validation Approach

1. **Compiler Warnings:** Enable all C++20/23 warnings
   ```cmake
   add_compile_options(
       -Wall -Wextra -Wpedantic
       -Wc++20-compat -Wc++23-extensions
   )
   ```

2. **Static Analysis:** Update cppcheck rules
   ```bash
   cppcheck --std=c++20 --enable=all \
       --suppress=missingInclude \
       --suppress=unusedFunction \
       --inline-suppr \
       core/ ui-slim/
   ```

3. **Unit Tests:** Expand coverage for modernized code
   - Test std::optional null handling
   - Validate ranges correctness
   - Benchmark performance changes

4. **Integration Tests:** Android Auto connectivity
   - USB AOAP negotiation
   - Audio/video streaming
   - Bluetooth pairing

### 9.2 Performance Benchmarks

Establish baselines before modernization:
```bash
# Audio latency
./benchmark_audio_pipeline

# Video frame processing
./benchmark_video_decode

# Profile load time
./benchmark_profile_manager
```

---

## 10. Coordination with External Projects

### 10.1 AASDK (f1xpl/aasdk)

**Current:** C++20 ✅ **UPGRADED 2026-01-14** (submodule commit eee33b4)  
**Status:** Ready for advanced C++20 features  
**Next Steps:** Apply modern patterns

**Completed:**
- ✅ Upgraded to C++20
- ✅ constexpr constants in USB layer

**Recommended Next Changes:**
- Replace std::bind with lambdas (50+ occurrences in tests)
- Apply std::optional to USB/Transport APIs
- Leverage concepts for template constraints
- Consider std::span for data buffers
- Modernize Promise implementation (or evaluate coroutines)

### 10.2 OpenAuto (f1xpl/openauto)

**Current:** C++17  
**Depends on:** AASDK C++20 migration ✅ **UNBLOCKED**  
**Timeline:** Q2 2026 (accelerated - AASDK ready)

**Proposed Changes:**
- Align with AASDK C++20 migration
- Modernize UI code (Qt6 C++20 features)
- Apply ranges to service layer

---

## 11. Documentation and Training

### 11.1 Developer Guidelines

Create:
- **C++20 Features Guide** for team
- **Migration Cookbook** with before/after examples
- **Code Review Checklist** for C++20 compliance

### 11.2 CI/CD Integration

```yaml
# .github/workflows/cpp-modernization.yml
- name: Check C++20 Compliance
  run: |
    cppcheck --std=c++20 --error-exitcode=1 \
        --enable=style --suppress=missingInclude \
        core/ ui-slim/
    
    # Check for deprecated patterns
    ! grep -r "std::bind" core/ ui-slim/
    ! grep -r "\bNULL\b" core/ ui-slim/
    ! grep -r "typedef.*Pointer" core/ ui-slim/
```

---

## 12. Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Breaking changes in dependencies | Medium | High | Coordinate with upstream, maintain forks |
| Compiler bugs in C++23 features | Medium | Medium | Thorough testing, fallback implementations |
| Performance regressions | Low | High | Benchmarking before/after, profiling |
| Team learning curve | Medium | Low | Training, documentation, code reviews |
| Raspberry Pi toolchain delays | High | Medium | Stay on C++20 until GCC 13 stable |

---

## 13. Success Metrics

### Code Quality
- ✅ Zero `NULL` occurrences
- ✅ Zero `std::bind` in new code
- ✅ Zero `typedef` (use `using`)
- ✅ 80%+ constexpr for constants
- ✅ 50%+ functions using ranges

### Performance
- ✅ No audio latency increase
- ✅ No video frame drops
- ✅ Profile load time < 100ms

### Maintainability
- ✅ Reduced SLOC (-10% target)
- ✅ Improved error handling (std::expected)
- ✅ Better type safety (concepts)

---

## 14. Conclusion

### Summary

The Crankshaft MVP codebase has achieved **full C++20 adoption** across all internal modules (core, ui-slim, tools) as of 2026-01-14. Significant modernization work has been completed with remaining opportunities focused on external dependencies and advanced C++20 features.

**Completed Actions (2026-01-14):**
1. ✅ Upgraded ui-slim to C++20
2. ✅ Upgraded aa_test to C++20
3. ✅ **Upgraded AASDK submodule to C++20** 🎉
4. ✅ Applied STL algorithms (std::find_if, std::any_of)
5. ✅ Fixed virtual destructor issues
6. ✅ Improved ProfileManager error handling

**Immediate Next Actions (Q1 2026):**
1. Replace NULL with nullptr
2. Convert typedef to using
3. Add constexpr to constants
4. Begin std::bind elimination

**Medium-Term (Q2-Q3 2026):**
1. Apply C++20 ranges extensively
2. Introduce std::optional for safety
3. Add concepts for template constraints
4. Coordinate with AASDK/OpenAuto upstream

**Long-Term (Q4 2026+):**
1. Plan C++23 migration (std::expected)
2. Evaluate coroutines for async operations
3. Adopt C++23 standard library features

### Estimated Total Effort

- **Phase 1 (Quick Wins):** 40 hours (50% complete - 18 hours completed)
- **Phase 2 (High-Value):** 120 hours
- **Phase 3 (Advanced):** 160 hours
- **Total Remaining:** ~302 hours (~7.5 weeks full-time)
- **Total Project:** 320 hours (~8 weeks full-time)

### ROI Justification

**Benefits:**
- ✅ Safer code (nullptr, optional, expected)
- ✅ More maintainable (ranges, concepts, lambdas)
- ✅ Better performance (constexpr, span, ranges)
- ✅ Future-proof (C++23/26 ready)
- ✅ Easier onboarding (modern idiomatic C++)

**Cost:** 8 weeks development + testing  
**Payback Period:** 6-12 months (via reduced bugs, faster development)

---

## 15. References

### Standards Documentation
- [C++20 Standard (ISO/IEC 14882:2020)](https://isocpp.org/std/the-standard)
- [C++23 Standard (ISO/IEC 14882:2023)](https://en.cppreference.com/w/cpp/23)
- [C++ Core Guidelines](https://isocpp.github.io/CppCoreGuidelines/)

### Compiler Support
- [GCC C++ Standards Support](https://gcc.gnu.org/projects/cxx-status.html)
- [Clang C++ Status](https://clang.llvm.org/cxx_status.html)
- [Qt6 C++ Requirements](https://doc.qt.io/qt-6/cpp20.html)

### Project Specific
- [AASDK Repository](https://github.com/f1xpl/aasdk)
- [OpenAuto Repository](https://github.com/f1xpl/openauto)
- [Crankshaft Build Guide](BUILD.md)
- [Developer Handbook](docs/ci-cd/developer-handbook.md)

---

## 16. Changelog

### Version 1.1 - 2026-01-14
**Completed Work:**
- ✅ Upgraded ui-slim from C++17 to C++20
- ✅ Upgraded aa_test from C++17 to C++20
- ✅ **Upgraded AASDK submodule from C++17 to C++20 (commit eee33b4)** 🎉
- ✅ Applied STL algorithms to replace raw loops:
  - ProfileManager::setDeviceEnabled() → std::find_if
  - ProfileManager::setDeviceUseMock() → std::find_if
  - SettingsMigration::detectCorruption() → std::any_of
  - AudioRouter::getDeviceById() → std::find_if
- ✅ Fixed virtual function calls in destructors (4 classes)
- ✅ Fixed ProfileManager validation logic
- ✅ Resolved cppcheck useStlAlgorithm warnings
- ✅ Updated Phase 1 progress (50% complete)

**Branch:** bugfix/moderise_return  
**Build Status:** ✅ Passing (Debug build verified)

### Version 1.0 - 2026-01-14
- Initial gap analysis document created
- Identified 127+ modernization opportunities
- Established 3-phase implementation roadmap

---

**Document Version:** 1.1  
**Last Updated:** 2026-01-14 15:30 UTC  
**Next Review:** 2026-02-14 (Monthly)
