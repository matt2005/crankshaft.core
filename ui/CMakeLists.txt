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

project(crankshaft-ui)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick WebSockets LinguistTools)

# Set Qt policies to suppress warnings
qt_policy(SET QTP0001 NEW)  # Use :/qt/qml/ prefix
qt_policy(SET QTP0004 NEW)  # Require qmldir files

# Create executable first
qt_add_executable(crankshaft-ui
  main.cpp
  Theme.h
  WebSocketClient.h
  WebSocketClient.cpp
  SettingsRegistry.h
  SettingsRegistry.cpp
)

# Enable AUTOMOC for metatype generation
set_target_properties(crankshaft-ui PROPERTIES
  AUTOMOC ON
  RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/ui
)

# Compile translations
set(TS_FILES
  i18n/ui_en_GB.ts
  i18n/ui_de_DE.ts
)

qt_add_translations(crankshaft-ui
  TS_FILES ${TS_FILES}
  RESOURCE_PREFIX "/i18n"
)

qt_add_qml_module(crankshaft-ui
  URI Crankshaft
  VERSION 1.0
  NO_PLUGIN_OPTIONAL
  NO_GENERATE_QMLDIR
  QML_FILES
    ${CMAKE_CURRENT_SOURCE_DIR}/qml/screens/Main.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/qml/screens/HomeScreen.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/qml/screens/SettingsScreen.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/qml/screens/AndroidAutoScreen.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/qml/screens/ToolsPage.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/qml/screens/ProfilesPage.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/qml/screens/WiFiSettingsPage.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/qml/screens/BluetoothSettingsPage.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/qml/models/SettingsModel.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/qml/models/Strings.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/qml/components/AppButton.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/qml/components/Card.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/qml/components/Icon.qml
    ${CMAKE_CURRENT_SOURCE_DIR}/qml/components/MaterialDesignIcons.js
  RESOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/assets/icons/mdi.svg
    ${CMAKE_CURRENT_SOURCE_DIR}/qmldir
)

# Add Material Design Icons font as a separate resource
if(MDI_FONT_FILE AND EXISTS "${MDI_FONT_FILE}")
  set_source_files_properties(${MDI_FONT_FILE}
    PROPERTIES QT_RESOURCE_ALIAS "materialdesignicons-webfont.ttf"
  )
  qt_add_resources(crankshaft-ui "mdi-font"
    PREFIX "/fonts"
    FILES ${MDI_FONT_FILE}
  )
endif()

target_include_directories(crankshaft-ui PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(crankshaft-ui PRIVATE
  Qt6::Core
  Qt6::Gui
  Qt6::Qml
  Qt6::Quick
  Qt6::WebSockets
)

# Install ui executable
install(TARGETS crankshaft-ui
  RUNTIME DESTINATION bin
  COMPONENT ui
)

# Install Material Design Icons font
if(MDI_FONT_FILE AND EXISTS "${MDI_FONT_FILE}")
  install(FILES "${MDI_FONT_FILE}"
    DESTINATION share/fonts/truetype/material-design-icons
    COMPONENT ui
  )
endif()
