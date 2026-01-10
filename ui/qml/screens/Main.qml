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
import QtQuick.Controls
import QtQuick.Layouts
import Crankshaft 1.0
import Crankshaft.Components 1.0

ApplicationWindow {
    id: window
    
    visible: true
    width: 1024
    height: 600
    title: Strings.appTitle
    
    color: Theme.background
    
    // Multi-display support: determine if we're on primary display for AA
    property bool isPrimaryDisplay: DisplayModel.primaryDisplayId === "" || true
    
    // Responsive breakpoint detection
    property int breakpoint: LayoutUtils.breakpointTier(width)
    
    onWidthChanged: {
        var oldBreakpoint = breakpoint
        breakpoint = LayoutUtils.breakpointTier(width)
        if (oldBreakpoint !== breakpoint) {
            console.log("[Main] Breakpoint changed:", oldBreakpoint, "→", breakpoint, "Width:", width)
        }
    }
    
    // Connection status indicator
    Rectangle {
        id: statusBar
        anchors.top: parent.top
        width: parent.width
        height: 4
        color: wsClient.connected ? Theme.success : Theme.error
        
        // Fast theme swap: theme colors update immediately
        Behavior on color {
            ColorAnimation { duration: Theme.animationFeedback }
        }
    }
    
    // Main content
    StackView {
        id: stackView
        anchors.fill: parent
        anchors.topMargin: statusBar.height
        
        initialItem: Component {
            HomeScreen {
                Component.onCompleted: {
                    stack = stackView
                    settingsComponent = settingsScreen
                    androidAutoComponent = androidautoScreen
                }
            }
        }
    }
    
    Component {
        id: settingsScreen
        SettingsScreen {}
    }
    
    Component {
        id: androidautoScreen
        AndroidAutoScreen {}
    }
    
    // Handle WebSocket events
    Connections {
        target: wsClient
        
        function onEventReceived(topic, payload) {
            console.log('[Main] Event received:', topic, JSON.stringify(payload))
            
            if (topic === 'ui/theme/changed') {
                Theme.isDark = payload.mode === 'dark'
            } else if (topic === 'androidauto/session/started') {
                console.log('[Main] Android Auto session started, navigating to AA screen')
                // Automatically navigate to AA screen when session starts
                if (stackView.currentItem && stackView.currentItem.stack) {
                    stackView.currentItem.stack.push(androidautoScreen, { stack: stackView })
                }
            } else if (topic === 'androidauto/session/terminated') {
                console.log('[Main] Android Auto session terminated')
                // Optionally: navigate back to home when disconnected
                if (stackView.depth > 1) {
                    stackView.pop()
                }
            }
        }
        
        function onErrorOccurred(error) {
            console.error('[Main] WebSocket error:', error)
        }
    }
}
