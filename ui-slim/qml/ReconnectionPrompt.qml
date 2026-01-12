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
    id: reconnectionPrompt
    
    title: qsTr("Connection Failed")
    modal: true
    
    width: Math.min(500, parent.width * 0.8)
    height: Math.min(350, parent.height * 0.6)
    
    // ConnectionStateMachine reference (set by parent)
    property var connectionStateMachine: null
    
    // Error message
    property string errorMessage: ""
    property int retryCount: 0
    
    signal manualConnectRequested()
    signal dismissed()
    
    background: Rectangle {
        color: Theme.surfaceColor
        radius: Theme.radiusMedium
        border.color: Theme.errorColor
        border.width: 2
    }
    
    contentItem: ColumnLayout {
        spacing: Theme.spacingLarge
        
        // Error icon
        Text {
            text: "⚠️"
            font.pixelSize: 64
            Layout.alignment: Qt.AlignHCenter
        }
        
        // Title
        Label {
            text: qsTr("Reconnection Failed")
            font.pixelSize: Theme.fontSizeHeading
            font.bold: true
            color: Theme.errorColor
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }
        
        // Description
        Label {
            text: qsTr("Unable to reconnect to your AndroidAuto device after %1 attempts.").arg(retryCount)
            font.pixelSize: Theme.fontSizeBody
            color: Theme.textPrimaryColor
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }
        
        // Error message
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: errorLabel.height + Theme.spacingMedium * 2
            color: Qt.rgba(Theme.errorColor.r, Theme.errorColor.g, Theme.errorColor.b, 0.1)
            radius: Theme.radiusSmall
            border.color: Theme.errorColor
            border.width: 1
            
            Label {
                id: errorLabel
                anchors.fill: parent
                anchors.margins: Theme.spacingMedium
                text: errorMessage || qsTr("Connection error - please check your device")
                font.pixelSize: Theme.fontSizeCaption
                color: Theme.errorColor
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
        
        // Suggestions
        Label {
            text: qsTr("Suggestions:\n• Check USB cable connection\n• Enable Android Auto on your device\n• Restart your device")
            font.pixelSize: Theme.fontSizeCaption
            color: Theme.textSecondaryColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            lineHeight: 1.5
        }
        
        // Spacer
        Item {
            Layout.fillHeight: true
        }
        
        // Action buttons
        RowLayout {
            spacing: Theme.spacingMedium
            Layout.fillWidth: true
            
            // Dismiss button
            Button {
                text: qsTr("Dismiss")
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.touchTargetMinimum
                
                background: Rectangle {
                    color: parent.pressed ? Qt.darker(Theme.borderColor, 1.2) :
                           parent.hovered ? Qt.lighter(Theme.borderColor, 1.2) :
                           Theme.borderColor
                    radius: Theme.radiusSmall
                }
                
                contentItem: Text {
                    text: parent.text
                    font.pixelSize: Theme.fontSizeBody
                    color: Theme.textPrimaryColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                onClicked: {
                    reconnectionPrompt.dismissed()
                    reconnectionPrompt.close()
                }
            }
            
            // Manual Connect button
            Button {
                text: qsTr("Try Again")
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.touchTargetMinimum
                
                background: Rectangle {
                    color: parent.pressed ? Theme.accentColorPressed :
                           parent.hovered ? Theme.accentColorHover :
                           Theme.accentColor
                    radius: Theme.radiusSmall
                }
                
                contentItem: Text {
                    text: parent.text
                    font.pixelSize: Theme.fontSizeBody
                    font.bold: true
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                onClicked: {
                    reconnectionPrompt.manualConnectRequested()
                    reconnectionPrompt.close()
                }
            }
        }
    }
    
    // Update error message from connection state machine
    Connections {
        target: connectionStateMachine
        
        function onLastErrorChanged(error) {
            errorMessage = error
        }
        
        function onRetryCountChanged(count) {
            retryCount = count
        }
    }
    
    Component.onCompleted: {
        if (connectionStateMachine) {
            errorMessage = connectionStateMachine.lastError
            retryCount = connectionStateMachine.retryCount
        }
    }
}
