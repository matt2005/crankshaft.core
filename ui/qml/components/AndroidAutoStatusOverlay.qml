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

// Status overlay for blocked/unavailable Android Auto states
// Displays clear messaging and disables user interaction
Rectangle {
    id: statusOverlay
    
    // Properties
    property bool isVisible: false
    property string state: ""  // "unavailable" or "blocked"
    
    color: "transparent"
    visible: isVisible
    
    // Semi-transparent overlay
    Rectangle {
        anchors.fill: parent
        color: Theme.scrim.lighter(220)  // Lighter scrim for blocked state
    }
    
    // Center message with icon and text
    Column {
        anchors.centerIn: parent
        spacing: Theme.spacing4
        
        // Status icon
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 64
            text: {
                switch (statusOverlay.state) {
                    case "unavailable":
                        return "⊘"  // Prohibition sign
                    case "blocked":
                        return "🔒"  // Lock
                    default:
                        return "❔"
                }
            }
        }
        
        // Title
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.onBackground
            font.pixelSize: 24
            font.bold: true
            font.family: 'Roboto'
            text: {
                switch (statusOverlay.state) {
                    case "unavailable":
                        return qsTr('Android Auto\nNot Available')
                    case "blocked":
                        return qsTr('Android Auto\nBlocked')
                    default:
                        return qsTr('Unable to Launch')
                }
            }
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
        
        // Message
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(300, statusOverlay.parent.width - Theme.spacing4 * 2)
            color: Theme.onBackgroundVariant
            font.pixelSize: 16
            font.family: 'Roboto'
            text: AndroidAutoStatus.statusMessage
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            lineHeight: 1.4
        }
        
        // Action hint
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(280, statusOverlay.parent.width - Theme.spacing4 * 2)
            color: Theme.onBackgroundVariant.lighter(120)
            font.pixelSize: 13
            font.family: 'Roboto'
            font.italic: true
            text: {
                if (statusOverlay.state === "unavailable") {
                    return qsTr('Android Auto service is not available. Please check your device connection.')
                } else if (statusOverlay.state === "blocked") {
                    if (!AndroidAutoStatus.hasConsent) {
                        return qsTr('Grant data sharing permission in Settings to enable Android Auto.')
                    } else if (!AndroidAutoStatus.isStationary) {
                        return qsTr('Android Auto is disabled whilst the vehicle is in motion for safety.')
                    }
                }
                return qsTr('Please try again in a moment.')
            }
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            lineHeight: 1.3
        }
    }
}
