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

Item {
    id: root
    
    // Properties following Design for Driving guidelines
    property string title: ""
    property string description: ""
    property string icon: ""
    signal clicked()
    
    // Minimum touch target: 76dp per Design for Driving, cards can be larger
    width: 200
    height: 150
    
    // Responsive scale with fast feedback (≤500ms total response)
    scale: mouseArea.pressed ? 0.95 : (mouseArea.containsMouse ? 1.02 : 1.0)
    
    Behavior on scale {
        NumberAnimation { duration: Theme.animationFeedback }  // 150ms for quick visual feedback
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
    
    Rectangle {
        id: background
        anchors.fill: parent
        // Ensure 4.5:1 contrast ratio on surface
        color: Theme.surface
        radius: Theme.radiusSm  // Matching Theme token for consistency
        border.color: Theme.divider
        border.width: 1
        
        Behavior on color {
            ColorAnimation { duration: Theme.animationFeedback }
        }
        
        Column {
            anchors.centerIn: parent
            anchors.margins: Theme.spacingMd  // 16dp padding per Theme scale
            spacing: Theme.spacingSm  // 8dp spacing (Theme.spacingScale)
            width: parent.width - (Theme.spacingMd * 2)
            
            Icon {
                name: root.icon
                // 48px icon size, scaled appropriately for tile
                size: Math.round(Theme.fontSizeLarge)  // 48px from Typography
                anchors.horizontalCenter: parent.horizontalCenter
                // Icon colour must maintain 4.5:1 contrast against surface
                color: Theme.textPrimary
            }
            
            Text {
                text: root.title
                // Card title uses subtitle1 font size for hierarchy (20–24px)
                font.pixelSize: Theme.fontSizeSubtitle1
                font.bold: true
                color: Theme.textPrimary
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: 2
            }
            
            Text {
                text: root.description
                // Card description uses caption/small text (12–14px)
                font.pixelSize: Theme.fontSizeCaption
                color: Theme.textSecondary
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: 2
            }
        }
        
        // Ripple effect - visual feedback within fast animation budget (150ms)
        Rectangle {
            id: ripple
            anchors.centerIn: parent
            width: 0
            height: width
            radius: width / 2
            color: Theme.primary
            opacity: 0
            
            ParallelAnimation {
                id: rippleAnimation
                // Fast ripple for quick visual feedback (150ms matches animationFeedback)
                NumberAnimation {
                    target: ripple
                    property: "width"
                    from: 0
                    to: background.width * 2
                    duration: Theme.animationFeedback
                }
                NumberAnimation {
                    target: ripple
                    property: "opacity"
                    from: 0.3
                    to: 0
                    duration: Theme.animationFeedback
                }
            }
        }
    }
    
    Connections {
        target: mouseArea
        function onPressed() {
            rippleAnimation.start()
        }
    }
}
