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

pragma Singleton
import QtQuick

// Multi-display management and enumeration model
QtObject {
    id: displayModel
    
    // Structured logging helper
    function logStructured(level, event, message, context) {
        var timestamp = new Date().toISOString()
        console.log('[' + timestamp + '] [' + level + '] [' + event + '] ' + message + 
                    ' | Context: ' + JSON.stringify(context))
    }
    
    // Signal emitted when displays change (connect/disconnect)
    signal primaryDisplayDisconnected()
    
    // Available displays detected on system
    property var displays: []
    
    // Current primary display ID
    property string primaryDisplayId: ""
    
    // Display options for settings UI
    property var displayOptions: {
        var options = []
        for (var i = 0; i < displays.length; i++) {
            options.push({
                value: displays[i].id,
                label: displays[i].name + " (" + displays[i].width + "x" + displays[i].height + ")"
            })
        }
        return options
    }
    
    // Total number of connected displays
    property int displayCount: displays.length
    
    // Is primary display still connected
    property bool isPrimaryDisplayConnected: {
        for (var i = 0; i < displays.length; i++) {
            if (displays[i].id === primaryDisplayId) {
                return true
            }
        }
        return false
    }
    
    // Get display by ID
    function getDisplayById(displayId) {
        for (var i = 0; i < displays.length; i++) {
            if (displays[i].id === displayId) {
                return displays[i]
            }
        }
        return null
    }
    
    // Get primary display object
    function getPrimaryDisplay() {
        return getDisplayById(primaryDisplayId)
    }
    
    // Set primary display (with validation)
    function setPrimaryDisplay(displayId) {
        var display = getDisplayById(displayId)
        if (display) {
            var oldDisplayId = primaryDisplayId
            primaryDisplayId = displayId
            logStructured('INFO', 'display_changed', 'Primary display changed', {
                previousDisplayId: oldDisplayId,
                newDisplayId: displayId,
                displayName: display.name,
                resolution: display.width + 'x' + display.height
            })
            return true
        }
        console.warn("Display not found: " + displayId)
        return false
    }
    
    // Called by C++ when display configuration changes
    function onDisplaysUpdated(newDisplays) {
        // Validate primary display still exists
        if (primaryDisplayId && !isPrimaryDisplayConnected) {
            logStructured('WARN', 'display_disconnected', 'Primary display disconnected', {
                displayId: primaryDisplayId,
                connectedDisplays: newDisplays.length
            })
            primaryDisplayDisconnected()
            
            // Fall back to first available display
            if (newDisplays.length > 0) {
                var newPrimaryId = newDisplays[0].id
                logStructured('INFO', 'display_fallback', 'Falling back to available display', {
                    newPrimaryId: newPrimaryId,
                    displayName: newDisplays[0].name
                })
                primaryDisplayId = newPrimaryId
            } else {
                logStructured('ERROR', 'display_unavailable', 'No displays available', {})
                primaryDisplayId = ""
            }
        } else if (newDisplays.length !== displays.length) {
            logStructured('INFO', 'display_count_changed', 'Display count changed', {
                previousCount: displays.length,
                newCount: newDisplays.length,
                totalDisplays: newDisplays.map(function(d) { return d.name }).join(', ')
            })
        }
        
        displays = newDisplays
        displaysChanged()
    }
    
    // Called when UI needs to select a display
    function selectDisplay(displayId) {
        if (setPrimaryDisplay(displayId)) {
            wsClient.publish("ui/display/primary", { displayId: displayId })
        }
    }
    
    Component.onCompleted: {
        // C++ DisplayManager will call onDisplaysUpdated on startup
        // to initialise displays and primary display from QSettings
    }
}
