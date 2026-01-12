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

# Find Qt6 Test framework and additional components
find_package(Qt6 REQUIRED COMPONENTS Test Core Multimedia)

# Test discovery function - Phase 3-4 Minimal Smoke Tests
# Note: These are framework validation tests, not full integration tests
# Full facade testing requires ServiceProvider and core service mocks
function(add_slim_ui_test test_name test_source)
    # Phase 3-4 tests: minimal framework validation
    # Do NOT include facade implementations to avoid cascading core dependencies
    add_executable(${test_name}
        ${test_source}
        ${CMAKE_SOURCE_DIR}/core/services/logging/Logger.h
        ${CMAKE_SOURCE_DIR}/core/services/logging/Logger.cpp
    )
    
    set_target_properties(${test_name} PROPERTIES
        AUTOMOC ON
        RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/ui-slim/tests
    )
    
    target_link_libraries(${test_name} PRIVATE
        Qt6::Test
        Qt6::Core
        Qt6::Multimedia
    )
    
    target_include_directories(${test_name} PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/../src
        ${CMAKE_SOURCE_DIR}/core
        ${CMAKE_SOURCE_DIR}/core/services
    )

    # Register test with CTest
    add_test(
        NAME ${test_name}
        COMMAND ${test_name}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/ui-slim/tests
    )
endfunction()

# Add test cases (to be implemented in Phase 3-6)
# Placeholder structure for future tests:
# - test_android_auto_facade.cpp (Phase 3)
# - test_connection_state_machine.cpp (Phase 3)
# - test_preferences_facade.cpp (Phase 4)
# - test_audio_failure_scenarios.cpp (Phase 5)

# Phase 3 tests
add_slim_ui_test(test_android_auto_facade ${CMAKE_CURRENT_SOURCE_DIR}/test_android_auto_facade.cpp)
add_slim_ui_test(test_connection_state_machine ${CMAKE_CURRENT_SOURCE_DIR}/test_connection_state_machine.cpp)

# Phase 4 tests
add_slim_ui_test(test_preferences_facade ${CMAKE_CURRENT_SOURCE_DIR}/test_preferences_facade.cpp)
add_slim_ui_test(test_slim_settings_persistence ${CMAKE_CURRENT_SOURCE_DIR}/test_slim_settings_persistence.cpp)
add_slim_ui_test(test_audio_failure_scenarios ${CMAKE_CURRENT_SOURCE_DIR}/test_audio_failure_scenarios.cpp)
