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
import SlimUI

Item {
    id: statusView
    
    // AndroidAutoFacade reference (set by parent)
    property var androidAutoFacade: null
    
    // Connection state enum (must match AndroidAutoFacade::ConnectionState)
    readonly property int stateDisconnected: 0
    readonly property int stateSearching: 1
    readonly property int stateConnecting: 2
    readonly property int stateConnected: 3
    readonly property int stateError: 4
    
    // Current state
    property int connectionState: androidAutoFacade ? androidAutoFacade.connectionState : stateDisconnected
    
    // Background
    Rectangle {
        anchors.fill: parent
        color: Theme.backgroundColor
    }
    
    // Status overlay
    ColumnLayout {
        anchors.centerIn: parent
        spacing: Theme.spacingLarge
        width: Math.min(400, parent.width * 0.8)
        
        // Status icon and spinner
        Item {
            Layout.preferredWidth: 120
            Layout.preferredHeight: 120
            Layout.alignment: Qt.AlignHCenter
            
            // Spinner (visible when searching or connecting)
            BusyIndicator {
                anchors.centerIn: parent
                width: 120
                height: 120
                running: statusView.connectionState === stateSearching || 
                        statusView.connectionState === stateConnecting
                
                contentItem: Item {
                    implicitWidth: 120
                    implicitHeight: 120
                    
                    Rectangle {
                        id: spinner
                        width: parent.width
                        height: parent.height
                        radius: width / 2
                        color: "transparent"
                        border.width: 8
                        border.color: Theme.accentColor
                        
                        // Create arc effect
                        ConicalGradient {
                            anchors.fill: parent
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Theme.accentColor }
                                GradientStop { position: 0.5; color: Qt.rgba(Theme.accentColor.r, 
                                                                            Theme.accentColor.g, 
                                                                            Theme.accentColor.b, 0.3) }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                            
                            RotationAnimation on rotation {
                                from: 0
                                to: 360
                                duration: 1500
                                loops: Animation.Infinite
                                running: parent.parent.parent.running
                            }
                        }
                    }
                }
            }
            
            // Status icon (visible when not loading)
            Text {
                anchors.centerIn: parent
                visible: statusView.connectionState !== stateSearching && 
                        statusView.connectionState !== stateConnecting
                text: statusView.connectionState === stateConnected ? "✓" : 
                      statusView.connectionState === stateError ? "✗" : "○"
                font.pixelSize: 72
                color: statusView.connectionState === stateConnected ? Theme.successColor :
                       statusView.connectionState === stateError ? Theme.errorColor :
                       Theme.textSecondaryColor
            }
        }
        
        // Status text
        Label {
            text: getStatusText()
            font.pixelSize: Theme.fontSizeHeading
            font.bold: true
            color: Theme.textPrimaryColor
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
        }
        
        // Status details
        Label {
            text: getStatusDetails()
            font.pixelSize: Theme.fontSizeBody
            color: Theme.textSecondaryColor
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
        }
        
        // Error message (visible only on error)
        Label {
            visible: statusView.connectionState === stateError
            text: androidAutoFacade ? androidAutoFacade.lastError : ""
            font.pixelSize: Theme.fontSizeBody
            color: Theme.errorColor
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
        }
        
        // Action buttons
        RowLayout {
            spacing: Theme.spacingMedium
            Layout.alignment: Qt.AlignHCenter
            
            // Retry button (visible on error)
            Button {
                visible: statusView.connectionState === stateError
                text: qsTr("Retry")
                Layout.preferredHeight: Theme.touchTargetMinimum
                Layout.preferredWidth: 150
                
                background: Rectangle {
                    color: parent.pressed ? Theme.accentColorPressed :
                           parent.hovered ? Theme.accentColorHover :
                           Theme.accentColor
                    radius: Theme.radiusSmall
                }
                
                contentItem: Text {
                    text: parent.text
                    font.pixelSize: Theme.fontSizeBody
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                onClicked: {
                    if (androidAutoFacade) {
                        androidAutoFacade.retryConnection()
                    }
                }
            }
            
            // Disconnect button (visible when connected)
            Button {
                visible: statusView.connectionState === stateConnected
                text: qsTr("Disconnect")
                Layout.preferredHeight: Theme.touchTargetMinimum
                Layout.preferredWidth: 150
                
                background: Rectangle {
                    color: parent.pressed ? Qt.darker(Theme.errorColor, 1.3) :
                           parent.hovered ? Qt.lighter(Theme.errorColor, 1.1) :
                           Theme.errorColor
                    radius: Theme.radiusSmall
                }
                
                contentItem: Text {
                    text: parent.text
                    font.pixelSize: Theme.fontSizeBody
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                onClicked: {
                    if (androidAutoFacade) {
                        androidAutoFacade.disconnectDevice()
                    }
                }
            }
        }
    }
    
    // Helper functions
    function getStatusText() {
        switch (connectionState) {
            case stateDisconnected:
                return qsTr("Disconnected")
            case stateSearching:
                return qsTr("Searching for devices...")
            case stateConnecting:
                return qsTr("Connecting...")
            case stateConnected:
                var deviceName = androidAutoFacade ? androidAutoFacade.connectedDeviceName : ""
                return qsTr("Connected to %1").arg(deviceName)
            case stateError:
                return qsTr("Connection Error")
            default:
                return qsTr("Unknown State")
        }
    }
    
    function getStatusDetails() {
        switch (connectionState) {
            case stateDisconnected:
                return qsTr("No device connected")
            case stateSearching:
                return qsTr("Make sure your device has Android Auto enabled and USB debugging turned on")
            case stateConnecting:
                return qsTr("Please wait while we establish the connection")
            case stateConnected:
                return qsTr("Android Auto projection is active")
            case stateError:
                return qsTr("Failed to connect to device")
            default:
                return ""
        }
    }
    
    Component.onCompleted: {
        console.log("ConnectionStatusView loaded")
    }
}
