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

// Android Auto state machine and status tracker
// State transitions: unavailable → blocked → available → launching → active → (back to blocked/available)
QtObject {
    id: aaStatus
    
    // State enumeration (lowercase due to QML naming rules)
    readonly property string stateUnavailable: "unavailable"
    readonly property string stateBlocked: "blocked"
    readonly property string stateAvailable: "available"
    readonly property string stateLaunching: "launching"
    readonly property string stateActive: "active"
    
    // Current state
    property string state: "unavailable"
    
    // Whether hardware/service is available at all
    property bool isServiceAvailable: false
    
    // Whether user consent has been granted (persisted)
    property bool hasConsent: SettingsModel.currentAaConsent
    
    // Whether vehicle is stationary (safe to launch)
    property bool isStationary: true
    
    // Launch timeout tracking (ms)
    property int launchTimeoutMs: 5000
    property int launchElapsedMs: 0
    
    // Signals for state transitions
    signal stateChanged(string newState)
    signal launchStarted()
    signal launchCompleted()
    signal launchFailed(string reason)
    signal consentRequired()
    signal vehicleMoving()
    
    // Derived properties for UI
    property bool canLaunch: state === aaStatus.stateAvailable
    
    // Legacy properties for compatibility
    property string statusText: {
        if (state === aaStatus.stateActive) {
            return "Android Auto - Connected"
        } else if (state === aaStatus.stateLaunching) {
            return "Android Auto - Connecting..."
        } else if (state === aaStatus.stateAvailable) {
            return "Android Auto - Ready"
        } else if (state === aaStatus.stateBlocked) {
            if (!hasConsent) {
                return "Android Auto - Requires Consent"
            } else if (!isStationary) {
                return "Android Auto - Disabled (Driving)"
            }
            return "Android Auto - Blocked"
        } else {
            return "Android Auto - Unavailable"
        }
    }
    
    property color statusColor: {
        switch (state) {
            case aaStatus.stateActive:
                return "#4CAF50"  // Green
            case aaStatus.stateLaunching:
                return "#FF9800"  // Orange
            case aaStatus.stateAvailable:
                return "#2196F3"  // Blue
            case aaStatus.stateBlocked:
                return "#FF9800"  // Orange
            default:
                return "#F44336"  // Red
        }
    }
    
    property bool isConnected: state === aaStatus.stateActive
    
    // Derived property for UI message
    property string statusMessage: {
        switch (state) {
            case aaStatus.stateUnavailable:
                return "Android Auto is not available"
            case aaStatus.stateBlocked:
                if (!hasConsent) {
                    return "Android Auto requires data sharing consent"
                }
                if (!isStationary) {
                    return "Android Auto is disabled whilst driving for safety"
                }
                return "Android Auto is temporarily blocked"
            case aaStatus.stateAvailable:
                return "Ready to launch Android Auto"
            case aaStatus.stateLaunching:
                return "Launching Android Auto... (" + launchElapsedMs + "ms)"
            case aaStatus.stateActive:
                return "Android Auto is active"
            default:
                return "Unknown state"
        }
    }
    
    property string statusIcon: {
        switch (state) {
            case aaStatus.stateUnavailable:
                return "mdi-android-auto"
            case aaStatus.stateBlocked:
                return "mdi-android-auto"
            case aaStatus.stateAvailable:
                return "mdi-play-circle"
            case aaStatus.stateLaunching:
                return "mdi-loading"
            case aaStatus.stateActive:
                return "mdi-check-circle"
            default:
                return "mdi-help-circle"
        }
    }
    
    // Update state based on conditions
    function updateState() {
        if (!isServiceAvailable) {
            setState(aaStatus.stateUnavailable)
            return
        }
        
        if (state === aaStatus.stateLaunching || state === aaStatus.stateActive) {
            // Don't interrupt launching/active state
            return
        }
        
        if (!hasConsent) {
            setState(aaStatus.stateBlocked)
            consentRequired()
            logStructured('WARN', 'aa_state_change', 'Consent required', {
                previousState: state,
                newState: aaStatus.stateBlocked,
                reason: 'missing_consent'
            })
            return
        }
        
        if (!isStationary) {
            setState(aaStatus.stateBlocked)
            vehicleMoving()
            logStructured('WARN', 'aa_state_change', 'Vehicle moving, AA disabled', {
                previousState: state,
                newState: aaStatus.stateBlocked,
                reason: 'vehicle_moving'
            })
            return
        }
        
        setState(aaStatus.stateAvailable)
    }
    
    // Structured logging helper
    function logStructured(level, event, message, context) {
        var timestamp = new Date().toISOString()
        var logEntry = {
            timestamp: timestamp,
            level: level,      // INFO, WARN, ERROR
            event: event,       // Component event (e.g. 'aa_state_change', 'settings_changed')
            message: message,   // Human-readable message
            context: context    // Additional structured data
        }
        console.log('[' + timestamp + '] [' + level + '] [' + event + '] ' + message + 
                    ' | Context: ' + JSON.stringify(context))
    }
    
    // Attempt to launch AA
    function requestLaunch() {
        if (!canLaunch) {
            launchFailed("Cannot launch in state: " + state)
            logStructured('ERROR', 'aa_launch_failed', 'Launch not permitted', {
                currentState: state,
                reason: 'invalid_state'
            })
            return false
        }
        
        setState(aaStatus.stateLaunching)
        launchStarted()
        launchElapsedMs = 0
        logStructured('INFO', 'aa_launch_started', 'Android Auto launch initiated', {
            timestamp: new Date().getTime(),
            consentGiven: hasConsent,
            stationary: isStationary
        })
        
        // Monitor launch timeout
        if (launchTimer.running) {
            launchTimer.stop()
        }
        launchTimer.start()
        
        // Publish launch request to backend
        wsClient.publish("androidauto/launch", {
            consentGiven: hasConsent,
            stationary: isStationary
        })
        
        return true
    }
    
    // Called by backend when launch succeeds
    function onLaunchSuccess() {
        if (state === aaStatus.stateLaunching) {
            setState(aaStatus.stateActive)
            launchCompleted()
            launchTimer.stop()
        }
    }
    
    // Called by backend when launch fails
    function onLaunchFailure(reason) {
        if (state === aaStatus.stateLaunching) {
            launchTimer.stop()
            launchFailed(reason || "Launch failed")
            updateState()  // Return to safe state
        }
    }
    
    // Called by backend when service state changes
    function onServiceAvailabilityChanged(available) {
        isServiceAvailable = available
        updateState()
    }
    
    // Called by SettingsModel when consent changes
    function onConsentChanged(consented) {
        hasConsent = consented
        if (!consented) {
            // Revoke AA access immediately
            if (state === aaStatus.stateActive) {
                wsClient.publish("androidauto/terminate", {})
            }
        }
        updateState()
    }
    
    // Called by vehicle data service when motion detected
    function onVehicleMotionDetected() {
        isStationary = false
        if (state === aaStatus.stateActive) {
            wsClient.publish("androidauto/pause", {})
        }
        updateState()
    }
    
    // Called when vehicle stops
    function onVehicleStationary() {
        isStationary = true
        updateState()
    }
    
    // Called when AA session terminates
    function onSessionTerminated() {
        setState(aaStatus.stateAvailable)
    }
    
    // Internal state setter with structured logging
    function setState(newState) {
        if (state !== newState) {
            var oldState = state
            state = newState
            
            // Structured logging for all state transitions
            logStructured('INFO', 'aa_state_transition', 'State changed', {
                previousState: oldState,
                newState: newState,
                timestamp: new Date().getTime()
            })
            
            stateChanged(newState)
        }
    }
    
    // Launch timeout timer
    Timer {
        id: launchTimer
        interval: 100
        repeat: true
        
        onTriggered: {
            launchElapsedMs += 100
            if (launchElapsedMs >= aaStatus.launchTimeoutMs) {
                stop()
                aaStatus.onLaunchFailure("Launch timeout (" + aaStatus.launchTimeoutMs + "ms)")
            }
        }
    }
    
    // WebSocket connection for backend events
    property var wsConnections: Connections {
        target: wsClient
        
        function onConnectedChanged() {
            if (wsClient.connected) {
                console.log('[AndroidAutoStatus] WebSocket connected; subscribing to AA events')
                wsClient.subscribe('androidauto/#')
            }
        }
        
        function onEventReceived(topic, payload) {
            console.log('[AndroidAutoStatus] Event:', topic, payload)
            
            if (topic === 'androidauto/service/available') {
                aaStatus.onServiceAvailabilityChanged(true)
            } else if (topic === 'androidauto/service/unavailable') {
                aaStatus.onServiceAvailabilityChanged(false)
            } else if (topic === 'androidauto/session/started') {
                aaStatus.onLaunchSuccess()
            } else if (topic === 'androidauto/session/failed') {
                aaStatus.onLaunchFailure(payload.reason || "Unknown error")
            } else if (topic === 'androidauto/session/terminated') {
                aaStatus.onSessionTerminated()
            }
        }
    }
    
    // Connect to external state changes
    property var settingsConnections: Connections {
        target: SettingsModel
        function onCurrentAaConsentChanged() {
            aaStatus.onConsentChanged(SettingsModel.currentAaConsent)
        }
    }
    
    Component.onCompleted: {
        // Subscribe to AA events
        if (wsClient && wsClient.subscribe) {
            wsClient.subscribe('androidauto/#')
        }
        // Initialise state based on current conditions
        updateState()
    }
}
