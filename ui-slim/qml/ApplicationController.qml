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

import QtQuick

QtObject {
    id: controller
    
    // Application state
    enum ViewState {
        AndroidAutoView,
        SettingsView
    }
    
    property int currentView: ApplicationController.ViewState.AndroidAutoView
    
    // Connection state (maps to core AndroidAutoService::ConnectionState)
    property string connectionState: "DISCONNECTED"
    property bool isConnected: connectionState === "CONNECTED"
    
    // Error handling
    property string lastError: ""
    property bool hasError: lastError !== ""
    
    // Phase 3 will implement:
    // - View state machine (AA view <-> Settings view)
    // - Connection state propagation from AndroidAutoFacade
    // - Error handling and display
    // - Signal definitions for view transitions
    
    signal viewChanged(int newView)
    signal connectionStateChanged(string state)
    signal errorOccurred(string error)
    
    // View navigation functions
    function showAndroidAutoView() {
        currentView = ApplicationController.ViewState.AndroidAutoView
        viewChanged(currentView)
    }
    
    function showSettingsView() {
        currentView = ApplicationController.ViewState.SettingsView
        viewChanged(currentView)
    }
    
    function toggleView() {
        if (currentView === ApplicationController.ViewState.AndroidAutoView) {
            showSettingsView()
        } else {
            showAndroidAutoView()
        }
    }
    
    // Error handling
    function clearError() {
        lastError = ""
    }
    
    function reportError(errorMessage) {
        lastError = errorMessage
        errorOccurred(errorMessage)
    }
}

