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

// Android Auto consent interstitial
// Displays when AA is available but user hasn't granted data sharing consent
Rectangle {
    id: consentDialog
    
    // Signals
    signal consentAccepted()
    signal consentDeclined()
    
    // Properties
    property bool isVisible: false
    
    color: "transparent"
    visible: isVisible
    
    // Semi-transparent overlay
    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
    }
    
    // Center dialog with rounded corners
    Rectangle {
        id: dialogBox
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.spacing4 * 2, 500)
        height: implicitHeight
        color: Theme.surface
        radius: Theme.spacing2
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacing4
            spacing: Theme.spacing3
            
            // Title
            Text {
                Layout.fillWidth: true
                color: Theme.onSurface
                font.pixelSize: 20
                font.bold: true
                font.family: 'Roboto'
                text: qsTr('Android Auto Data Sharing')
                wrapMode: Text.Wrap
            }
            
            // Divider
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.divider
            }
            
            // Message text
            Text {
                Layout.fillWidth: true
                color: Theme.onSurface
                font.pixelSize: 14
                font.family: 'Roboto'
                text: qsTr('To use Android Auto, we need your permission to share vehicle and device data. This data helps provide features like navigation, media control, and safety notifications.\n\nYour data is only used whilst Android Auto is active and will not be stored after disconnection.')
                wrapMode: Text.WordWrap
                lineHeight: 1.5
            }
            
            // Details section
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: detailsColumn.implicitHeight + Theme.spacing3 * 2
                color: Theme.surfaceVariant.lighter(240)
                radius: Theme.spacing1
                
                ColumnLayout {
                    id: detailsColumn
                    anchors.fill: parent
                    anchors.margins: Theme.spacing3
                    spacing: Theme.spacing2
                    
                    Text {
                        color: Theme.onSurfaceVariant
                        font.pixelSize: 12
                        font.bold: true
                        font.family: 'Roboto'
                        text: qsTr('We access:')
                    }
                    
                    Text {
                        color: Theme.onSurfaceVariant
                        font.pixelSize: 12
                        font.family: 'Roboto'
                        text: qsTr('• Vehicle speed and location\n• Screen touches and inputs\n• Connected device information')
                        lineHeight: 1.3
                    }
                }
            }
            
            // Spacer
            Item {
                Layout.fillHeight: true
            }
            
            // Action buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacing3
                
                // Decline button
                Button {
                    id: declineButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.minTapTarget
                    text: qsTr('Not Now')
                    
                    background: Rectangle {
                        color: declineButton.pressed ? Theme.onSurfaceVariant.lighter(120) : Theme.surfaceVariant
                        radius: Theme.spacing1
                        border.color: Theme.divider
                        border.width: 1
                    }
                    
                    contentItem: Text {
                        text: declineButton.text
                        color: Theme.onSurfaceVariant
                        font.pixelSize: 14
                        font.bold: true
                        font.family: 'Roboto'
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: consentDialog.consentDeclined()
                }
                
                // Accept button
                Button {
                    id: acceptButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.minTapTarget
                    text: qsTr('Allow')
                    
                    background: Rectangle {
                        color: acceptButton.pressed ? Theme.primary.lighter(120) : Theme.primary
                        radius: Theme.spacing1
                    }
                    
                    contentItem: Text {
                        text: acceptButton.text
                        color: Theme.onPrimary
                        font.pixelSize: 14
                        font.bold: true
                        font.family: 'Roboto'
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: consentDialog.consentAccepted()
                }
            }
        }
    }
}
