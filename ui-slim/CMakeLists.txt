# Project: Crankshaft
# This file is part of Crankshaft project.
# Copyright (C) 2025 OpenCarDev Team
#
#  Crankshaft is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  Crankshaft is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with Crankshaft. If not, see <http://www.gnu.org/licenses/>.

cmake_minimum_required(VERSION 3.16)

project(crankshaft-slim-ui)

# Set C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable AUTOMOC, AUTORCC, AUTOUIC
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Find required Qt6 components
find_package(Qt6 REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    Multimedia
    Sql
    LinguistTools
    Network
    WebSockets
    DBus
    Bluetooth
)

# Find dependencies for core services
find_package(PkgConfig REQUIRED)
pkg_check_modules(GSTREAMER REQUIRED gstreamer-1.0)
pkg_check_modules(GSTREAMER_APP REQUIRED gstreamer-app-1.0)
pkg_check_modules(GSTREAMER_VIDEO REQUIRED gstreamer-video-1.0)
pkg_check_modules(GSTREAMER_AUDIO REQUIRED gstreamer-audio-1.0)
pkg_check_modules(LIBUSB REQUIRED libusb-1.0)

find_package(OpenSSL REQUIRED)
find_package(Protobuf REQUIRED)

# AASDK is built as subdirectory by root CMakeLists

# Add main executable with core service sources
qt_add_executable(crankshaft-slim-ui
    src/main.cpp
    src/ServiceProvider.h
    src/ServiceProvider.cpp
    src/AndroidAutoFacade.h
    src/AndroidAutoFacade.cpp
    src/PreferencesFacade.h
    src/PreferencesFacade.cpp
    src/SettingsMigration.h
    src/SettingsMigration.cpp
    src/DisplayBrightnessController.h
    src/DisplayBrightnessController.cpp
    src/AudioVolumeController.h
    src/AudioVolumeController.cpp
    src/DeviceManager.h
    src/DeviceManager.cpp
    src/AudioBridge.h
    src/AudioBridge.cpp
    src/TouchEventForwarder.h
    src/TouchEventForwarder.cpp
    src/ConnectionStateMachine.h
    src/ConnectionStateMachine.cpp
    src/ErrorHandler.h
    src/ErrorHandler.cpp
    
    # Core services (exclude main.cpp)
    ${CMAKE_SOURCE_DIR}/core/services/eventbus/EventBus.cpp
    ${CMAKE_SOURCE_DIR}/core/services/logging/Logger.cpp
    ${CMAKE_SOURCE_DIR}/core/services/profile/ProfileManager.cpp
    ${CMAKE_SOURCE_DIR}/core/services/service_manager/ServiceManager.cpp
    ${CMAKE_SOURCE_DIR}/core/services/android_auto/AndroidAutoService.cpp
    ${CMAKE_SOURCE_DIR}/core/services/android_auto/MockAndroidAutoService.cpp
    ${CMAKE_SOURCE_DIR}/core/services/android_auto/RealAndroidAutoService.cpp
    ${CMAKE_SOURCE_DIR}/core/services/android_auto/ProtocolHelpers.cpp
    ${CMAKE_SOURCE_DIR}/core/services/preferences/PreferencesService.cpp
    ${CMAKE_SOURCE_DIR}/core/services/audio/AudioRouter.cpp
    ${CMAKE_SOURCE_DIR}/core/services/media/MediaService.cpp
    ${CMAKE_SOURCE_DIR}/core/services/session/SessionStore.cpp
    ${CMAKE_SOURCE_DIR}/core/hal/multimedia/MediaPipeline.cpp
    ${CMAKE_SOURCE_DIR}/core/hal/multimedia/GStreamerVideoDecoder.cpp
    ${CMAKE_SOURCE_DIR}/core/hal/multimedia/AudioMixer.cpp
    ${CMAKE_SOURCE_DIR}/core/hal/multimedia/AudioHAL.cpp
    ${CMAKE_SOURCE_DIR}/core/hal/multimedia/VideoHAL.cpp
    ${CMAKE_SOURCE_DIR}/core/hal/multimedia/IVideoDecoder.cpp
    ${CMAKE_SOURCE_DIR}/core/hal/multimedia/IAudioMixer.cpp
    
    # QML resources
    qml.qrc
)

# Set runtime output directory
set_target_properties(crankshaft-slim-ui PROPERTIES
    AUTOMOC ON
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/ui-slim
)

# Link libraries (Qt6 + dependencies for core services)
target_link_libraries(crankshaft-slim-ui PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Multimedia
    Qt6::Sql
    Qt6::Network
    Qt6::WebSockets
    Qt6::DBus
    Qt6::Bluetooth
    nlohmann_json::nlohmann_json
    nlohmann_json_schema_validator
    aap_protobuf
    aasdk
    OpenSSL::SSL
    OpenSSL::Crypto
    ${PROTOBUF_LIBRARIES}
    ${GSTREAMER_LIBRARIES}
    ${GSTREAMER_APP_LIBRARIES}
    ${GSTREAMER_VIDEO_LIBRARIES}
    ${GSTREAMER_AUDIO_LIBRARIES}
    ${LIBUSB_LIBRARIES}
)

# Include directories (sources, core services, dependencies)
target_include_directories(crankshaft-slim-ui PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/core
    ${CMAKE_SOURCE_DIR}/core/services
    ${CMAKE_SOURCE_DIR}/core/hal
    ${CMAKE_SOURCE_DIR}/external/aasdk/include
    ${GSTREAMER_INCLUDE_DIRS}
    ${GSTREAMER_APP_INCLUDE_DIRS}
    ${GSTREAMER_VIDEO_INCLUDE_DIRS}
    ${GSTREAMER_AUDIO_INCLUDE_DIRS}
    ${LIBUSB_INCLUDE_DIRS}
    ${PROTOBUF_INCLUDE_DIRS}
    ${OPENSSL_INCLUDE_DIR}
)

# Translation support
set(TS_FILES
    translations/slim-ui_en_GB.ts
)

qt_add_translations(crankshaft-slim-ui
    TS_FILES ${TS_FILES}
    RESOURCE_PREFIX "/i18n"
)

# Clang-format integration
if(CLANG_FORMAT_EXECUTABLE)
    add_custom_target(clang-format-slim-ui
        COMMAND ${CLANG_FORMAT_EXECUTABLE} -i
            src/*.h src/*.cpp
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Running clang-format on slim-ui source files"
    )
endif()

# Tests
if(BUILD_TESTS)
    add_subdirectory(tests)
endif()
