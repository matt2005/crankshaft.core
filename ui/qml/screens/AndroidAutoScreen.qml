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

Rectangle {
    id: androidAutoScreen
    color: Theme.background
    
    // Responsive breakpoint tracking
    property int breakpoint: LayoutUtils.breakpointTier(width)
    
    // Status properties
    property alias videoSurface: videoSurface
    property alias connectionStatus: connectionStatus
    property var stack: null
    
    property string statusText: AndroidAutoStatus.statusText
    property color statusColor: AndroidAutoStatus.statusColor
    property bool isConnected: AndroidAutoStatus.isConnected
    
    // Responsive dimensions
    property int headerHeight: Math.max(Theme.spacing6 * 2 + 24, 60)  // Min 60px for 44px buttons + spacing
    property int controlHeight: Math.max(Theme.spacing6 * 2 + 16, 50) // Min 50px for controls
    property int tapTarget: Theme.minTapTarget  // 44px minimum
    
    Component.onCompleted: {
        console.log("[AndroidAutoScreen] Initialised")
        console.log("[AndroidAutoScreen] wsClient connected?", wsClient.connected)
        console.log("[AndroidAutoScreen] Subscribing to androidauto/#")
        wsClient.subscribe("androidauto/#")
    }
    
    // Reconnect when WebSocket connects
    Connections {
        target: wsClient
        function onConnectedChanged() {
            if (wsClient.connected) {
                console.log("[AndroidAutoScreen] WebSocket connected; re-subscribing")
                wsClient.subscribe("androidauto/#")
            }
        }
    }
    
    // Listen to AA status updates
    Connections {
        target: wsClient
        
        function onEventReceived(topic, payload) {
            console.log("[AndroidAutoScreen] Event:", topic, JSON.stringify(payload))
            
            if (topic === 'androidauto/session/started') {
                console.log('[AndroidAutoScreen] AA session started')
            } else if (topic === 'androidauto/session/failed') {
                console.log('[AndroidAutoScreen] AA session failed:', payload.reason)
            } else if (topic === 'androidauto/session/terminated') {
                console.log('[AndroidAutoScreen] AA session terminated')
            }
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0
        
        // Header: Status bar with connection info
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: androidAutoScreen.headerHeight
            color: Theme.surface
            border.color: Theme.divider
            border.width: 1
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacing2
                spacing: Theme.spacing3
                
                // Status indicator dot
                Rectangle {
                    Layout.preferredWidth: Theme.spacing3
                    Layout.preferredHeight: Theme.spacing3
                    radius: Theme.spacing3 / 2
                    color: AndroidAutoStatus.statusColor
                    
                    Behavior on color {
                        ColorAnimation { duration: Theme.animationDuration }
                    }
                }
                
                // Status text
                Text {
                    id: connectionStatus
                    color: Theme.onSurface
                    font.pixelSize: LayoutUtils.responsiveFontSize(width, 14, 16)
                    font.family: 'Roboto'
                    font.weight: Font.Medium
                    text: AndroidAutoStatus.statusText
                    
                    Layout.fillWidth: true
                }
                
                // Info label
                Text {
                    color: Theme.onSurfaceVariant
                    font.pixelSize: LayoutUtils.responsiveFontSize(width, 12, 14)
                    font.family: 'Roboto'
                    text: qsTr('Connect Android device via USB')
                    visible: width > 500  // Only show on wider displays
                }
            }
        }
        
        // Video/content surface
        Rectangle {
            id: videoSurface
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: '#000000'
            
            // Touch input handler
            MouseArea {
                id: touchArea
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                
                onPressed: (mouse) => {
                    wsClient.publish("androidauto/touch", {
                        "x": mouse.x / width,
                        "y": mouse.y / height,
                        "action": "down"
                    })
                }
                
                onReleased: (mouse) => {
                    wsClient.publish("androidauto/touch", {
                        "x": mouse.x / width,
                        "y": mouse.y / height,
                        "action": "up"
                    })
                }
                
                onPositionChanged: (mouse) => {
                    if (pressed) {
                        wsClient.publish("androidauto/touch", {
                            "x": mouse.x / width,
                            "y": mouse.y / height,
                            "action": "move"
                        })
                    }
                }
            }
            
            // Placeholder UI
            Column {
                anchors.centerIn: parent
                spacing: Theme.spacing4
                
                BusyIndicator {
                    anchors.horizontalCenter: parent.horizontalCenter
                    running: AndroidAutoStatus.state === AndroidAutoStatus.stateLaunching
                }
                
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Theme.onBackground
                    font.pixelSize: LayoutUtils.responsiveFontSize(width, 16, 18)
                    font.bold: true
                    font.family: 'Roboto'
                    text: qsTr('Android Auto Projection\nConnect your Android device via USB')
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
        
        // Control buttons - responsive sizing
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: androidAutoScreen.controlHeight
            color: Theme.surface
            border.color: Theme.divider
            border.width: 1
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacing2
                spacing: Theme.spacing2
                
                // Back button
                Button {
                    id: backButton
                    Layout.preferredWidth: Math.max(androidAutoScreen.tapTarget, implicitWidth)
                    Layout.preferredHeight: androidAutoScreen.tapTarget
                    Layout.alignment: Qt.AlignVCenter
                    text: '⬅'
                    font.pixelSize: Theme.fontSizeBase
                    
                    background: Rectangle {
                        color: backButton.pressed ? Theme.primary.lighter(120) : Theme.onSurface.darker(120)
                        radius: Theme.spacing1
                    }
                    
                    contentItem: Text {
                        text: backButton.text
                        color: Theme.onPrimary
                        font: backButton.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: wsClient.publish("androidauto/key", { "key": "BACK" })
                }
                
                // Home button
                Button {
                    id: homeButton
                    Layout.preferredWidth: Math.max(androidAutoScreen.tapTarget, implicitWidth)
                    Layout.preferredHeight: androidAutoScreen.tapTarget
                    Layout.alignment: Qt.AlignVCenter
                    text: '⌂'
                    font.pixelSize: Theme.fontSizeBase
                    
                    background: Rectangle {
                        color: homeButton.pressed ? Theme.primary.lighter(120) : Theme.onSurface.darker(120)
                        radius: Theme.spacing1
                    }
                    
                    contentItem: Text {
                        text: homeButton.text
                        color: Theme.onPrimary
                        font: homeButton.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: wsClient.publish("androidauto/key", { "key": "HOME" })
                }
                
                // Spacer
                Item { Layout.fillWidth: true }
                
                // Disconnect button
                Button {
                    id: disconnectButton
                    Layout.preferredWidth: Math.max(androidAutoScreen.tapTarget, implicitWidth)
                    Layout.preferredHeight: androidAutoScreen.tapTarget
                    Layout.alignment: Qt.AlignVCenter
                    text: '✕'
                    font.pixelSize: Theme.fontSizeBase
                    
                    background: Rectangle {
                        color: disconnectButton.pressed ? Theme.error.lighter(120) : Theme.error
                        radius: Theme.spacing1
                    }
                    
                    contentItem: Text {
                        text: disconnectButton.text
                        color: Theme.onError
                        font: disconnectButton.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: wsClient.publish("androidauto/disconnect", {})
                }
                
                // Exit button (visible on smaller displays as fallback)
                Button {
                    id: exitButton
                    Layout.preferredWidth: Math.max(androidAutoScreen.tapTarget, implicitWidth)
                    Layout.preferredHeight: androidAutoScreen.tapTarget
                    Layout.alignment: Qt.AlignVCenter
                    text: 'Exit'
                    font.pixelSize: Math.max(12, Theme.fontSizeBase - 2)
                    
                    background: Rectangle {
                        color: exitButton.pressed ? Theme.primary.lighter(120) : Theme.primary
                        radius: Theme.spacing1
                    }
                    
                    contentItem: Text {
                        text: exitButton.text
                        color: Theme.onPrimary
                        font: exitButton.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                        if (stack) {
                            stack.pop()
                        }
                    }
                }
            }
        }

        // Video rendering surface
        Rectangle {
            id: videoSurface
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: '#000000'

            MouseArea {
                id: touchArea
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton

                onPressed: (mouse) => {
                    wsClient.publish("androidauto/touch", {
                        "x": mouse.x / width,
                        "y": mouse.y / height,
                        "action": "down"
                    })
                }

                onReleased: (mouse) => {
                    wsClient.publish("androidauto/touch", {
                        "x": mouse.x / width,
                        "y": mouse.y / height,
                        "action": "up"
                    })
                }

                onPositionChanged: (mouse) => {
                    if (pressed) {
                        wsClient.publish("androidauto/touch", {
                            "x": mouse.x / width,
                            "y": mouse.y / height,
                            "action": "move"
                        })
                    }
                }
            }

            BusyIndicator {
                anchors.centerIn: parent
                running: true
            }

            Text {
                anchors.centerIn: parent
                color: '#FFFFFF'
                font.pixelSize: 18
                font.bold: true
                font.family: 'Roboto'
                text: qsTr('Android Auto Projection\nConnect your Android device via USB')
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // Control buttons
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            color: '#1a1a1a'
            border.color: '#333333'
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Button {
                    id: backButton
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    text: '⬅'
                    font.pixelSize: 16
                    onClicked: wsClient.publish("androidauto/key", { "key": "BACK" })
                }

                Button {
                    id: homeButton
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    text: '⌂'
                    font.pixelSize: 16
                    onClicked: wsClient.publish("androidauto/key", { "key": "HOME" })
                }

                Item { Layout.fillWidth: true }

                Button {
                    id: disconnectButton
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    text: '✕'
                    font.pixelSize: 16
                    onClicked: wsClient.publish("androidauto/disconnect", {})
                }

                Button {
                    id: exitButton
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 40
                    text: 'Exit'
                    font.pixelSize: 14
                    onClicked: {
                        if (stack) {
                            stack.pop()
                        }
                    }
                }
            }
        }
    }
    
    // Consent interstitial (T012)
    ConsentDialog {
        id: consentDialog
        anchors.fill: parent
        isVisible: AndroidAutoStatus.state === AndroidAutoStatus.stateBlocked && !SettingsModel.currentAaConsent
        
        onConsentAccepted: {
            console.log("[AndroidAutoScreen] User accepted AA consent")
            SettingsRegistry.setAaConsent(true)
            wsClient.publish("androidauto/consent", { accepted: true })
            isVisible = false
        }
        
        onConsentDeclined: {
            console.log("[AndroidAutoScreen] User declined AA consent")
            isVisible = false
        }
    }
    
    // Status overlay for blocked/unavailable states (T013)
    AndroidAutoStatusOverlay {
        id: statusOverlay
        anchors.fill: parent
        isVisible: AndroidAutoStatus.state === AndroidAutoStatus.stateUnavailable || 
                   (AndroidAutoStatus.state === AndroidAutoStatus.stateBlocked && SettingsModel.currentAaConsent)
        state: AndroidAutoStatus.state
    }

    // Note: Status is queried via backend connection state changes
    // Not publishing on component load to avoid duplicate events
}