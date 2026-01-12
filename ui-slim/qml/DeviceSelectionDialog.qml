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

Dialog {
    id: deviceDialog
    
    title: qsTr("Select Device")
    modal: true
    standardButtons: Dialog.Cancel
    
    width: Math.min(600, parent.width * 0.8)
    height: Math.min(400, parent.height * 0.6)
    
    // Auto-connect timer (3 seconds for single device)
    property int autoConnectDelay: 3000
    property bool autoConnectEnabled: true
    
    // DeviceManager reference (set by parent)
    property var deviceManager: null
    
    signal deviceSelected(string deviceId)
    
    background: Rectangle {
        color: Theme.surfaceColor
        radius: Theme.radiusMedium
        border.color: Theme.borderColor
        border.width: 1
    }
    
    contentItem: ColumnLayout {
        spacing: Theme.spacingMedium
        
        // Title label
        Label {
            text: deviceManager && deviceManager.hasMultipleDevices 
                  ? qsTr("Multiple devices detected. Select one to connect:")
                  : qsTr("Device detected. Connecting automatically...")
            font.pixelSize: Theme.fontSizeBody
            color: Theme.textPrimaryColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        
        // Device list
        ListView {
            id: deviceListView
            
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            clip: true
            spacing: Theme.spacingSmall
            
            model: deviceManager ? deviceManager.detectedDevices : []
            
            delegate: ItemDelegate {
                width: ListView.view.width
                height: Theme.touchTargetRecommended
                
                background: Rectangle {
                    color: parent.hovered ? Theme.accentColorHover : "transparent"
                    radius: Theme.radiusSmall
                    border.color: modelData.wasConnectedBefore ? Theme.accentColor : "transparent"
                    border.width: 2
                }
                
                contentItem: RowLayout {
                    spacing: Theme.spacingMedium
                    
                    // Device icon
                    Text {
                        text: modelData.type === "tablet" ? "📱" : "📱"
                        font.pixelSize: 32
                        Layout.preferredWidth: 48
                        horizontalAlignment: Text.AlignHCenter
                    }
                    
                    // Device info
                    ColumnLayout {
                        spacing: 4
                        Layout.fillWidth: true
                        
                        Label {
                            text: modelData.name
                            font.pixelSize: Theme.fontSizeBody
                            font.bold: modelData.wasConnectedBefore
                            color: Theme.textPrimaryColor
                            Layout.fillWidth: true
                        }
                        
                        RowLayout {
                            spacing: Theme.spacingSmall
                            
                            Label {
                                text: qsTr("Signal: %1%").arg(modelData.signalStrength)
                                font.pixelSize: Theme.fontSizeCaption
                                color: Theme.textSecondaryColor
                            }
                            
                            Label {
                                visible: modelData.wasConnectedBefore
                                text: qsTr("(Previously connected)")
                                font.pixelSize: Theme.fontSizeCaption
                                color: Theme.accentColor
                            }
                        }
                    }
                    
                    // Connect button
                    Button {
                        text: qsTr("Connect")
                        Layout.preferredHeight: Theme.touchTargetMinimum
                        Layout.preferredWidth: 120
                        
                        background: Rectangle {
                            color: parent.pressed ? Theme.accentColorPressed 
                                  : parent.hovered ? Theme.accentColorHover 
                                  : Theme.accentColor
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
                            deviceDialog.deviceSelected(modelData.deviceId)
                            deviceDialog.close()
                        }
                    }
                }
            }
            
            // Empty state
            Label {
                visible: parent.count === 0
                anchors.centerIn: parent
                text: qsTr("No devices detected")
                font.pixelSize: Theme.fontSizeBody
                color: Theme.textSecondaryColor
            }
        }
        
        // Auto-connect countdown (single device only)
        Label {
            visible: deviceManager && !deviceManager.hasMultipleDevices && autoConnectEnabled
            text: qsTr("Auto-connecting in %1 seconds...").arg(Math.ceil(autoConnectTimer.remainingTime / 1000))
            font.pixelSize: Theme.fontSizeCaption
            color: Theme.textSecondaryColor
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }
    }
    
    // Auto-connect timer for single device
    Timer {
        id: autoConnectTimer
        interval: deviceDialog.autoConnectDelay
        running: false
        repeat: false
        
        property int remainingTime: interval
        
        onTriggered: {
            if (deviceManager && deviceManager.deviceCount === 1 && autoConnectEnabled) {
                var deviceId = deviceManager.getTopPriorityDeviceId()
                if (deviceId) {
                    deviceDialog.deviceSelected(deviceId)
                    deviceDialog.close()
                }
            }
        }
        
        // Update remaining time
        Timer {
            interval: 100
            running: autoConnectTimer.running
            repeat: true
            onTriggered: {
                autoConnectTimer.remainingTime = Math.max(0, 
                    autoConnectTimer.interval - (Date.now() - autoConnectTimer.startTime))
            }
        }
        
        property var startTime: 0
        onRunningChanged: {
            if (running) {
                startTime = Date.now()
                remainingTime = interval
            }
        }
    }
    
    // Start auto-connect when dialog opens with single device
    onOpened: {
        if (deviceManager && deviceManager.deviceCount === 1 && autoConnectEnabled) {
            autoConnectTimer.start()
        }
    }
    
    // Stop timer when closed
    onClosed: {
        autoConnectTimer.stop()
    }
}
