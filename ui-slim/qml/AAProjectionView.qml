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
import QtMultimedia
import SlimUI

Item {
    id: projectionView
    
    // AndroidAutoFacade reference (set by parent)
    property var androidAutoFacade: null
    
    // TouchEventForwarder reference (set by parent or use global _touchForwarder)
    property var touchForwarder: _touchForwarder
    
    // Update touch forwarder display size when view size changes
    onWidthChanged: {
        if (touchForwarder) {
            touchForwarder.displaySize = Qt.size(width, height)
        }
    }
    
    onHeightChanged: {
        if (touchForwarder) {
            touchForwarder.displaySize = Qt.size(width, height)
        }
    }
    
    // Video output
    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectFit
        
        // TODO: Connect to actual video source from core AndroidAutoService
        // source: androidAutoFacade ? androidAutoFacade.videoSource : null
        
        // Placeholder background when no video
        Rectangle {
            anchors.fill: parent
            color: Theme.backgroundColor
            visible: !videoOutput.source || !androidAutoFacade || !androidAutoFacade.isVideoActive
            
            Text {
                anchors.centerIn: parent
                text: qsTr("Android Auto\n\nAwaiting video stream...")
                font.pixelSize: Theme.fontSizeHeading
                color: Theme.textSecondaryColor
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.5
            }
        }
    }
    
    // Touch area for forwarding input to AndroidAuto
    MultiPointTouchArea {
        id: touchArea
        anchors.fill: parent
        
        // Enable multi-touch (required for gestures like pinch-zoom)
        minimumTouchPoints: 1
        maximumTouchPoints: 10
        
        onPressed: (touchPoints) => {
            forwardTouchEvent("press", touchPoints)
        }
        
        onUpdated: (touchPoints) => {
            forwardTouchEvent("move", touchPoints)
        }
        
        onReleased: (touchPoints) => {
            forwardTouchEvent("release", touchPoints)
        }
        
        onCanceled: (touchPoints) => {
            forwardTouchEvent("cancel", touchPoints)
        }
        
        function forwardTouchEvent(eventType, touchPoints) {
            if (!touchForwarder) {
                console.warn("TouchEventForwarder not available")
                return
            }
            
            // Convert touch points to array of objects
            var points = []
            for (var i = 0; i < touchPoints.length; i++) {
                var tp = touchPoints[i]
                points.push({
                    id: tp.pointId,
                    x: tp.x,
                    y: tp.y,
                    pressure: tp.pressure,
                    areaWidth: tp.area.width,
                    areaHeight: tp.area.height
                })
            }
            
            // Forward to TouchEventForwarder
            touchForwarder.forwardTouchEvent(eventType, points)
        }
    }
    
    // Mouse area for desktop testing (single-point touch simulation)
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: !touchArea.enabled // Only active if touch is not available
        
        property bool isPressed: false
        
        onPressed: (mouse) => {
            isPressed = true
            sendMouseAsTouchEvent("press", mouse)
        }
        
        onPositionChanged: (mouse) => {
            if (isPressed) {
                sendMouseAsTouchEvent("move", mouse)
            }
        }
        
        onReleased: (mouse) => {
            isPressed = false
            sendMouseAsTouchEvent("release", mouse)
        }
        
        function sendMouseAsTouchEvent(eventType, mouse) {
            if (!touchForwarder) {
                console.warn("TouchEventForwarder not available")
                return
            }
            
            // Forward to TouchEventForwarder as mouse event
            touchForwarder.forwardMouseEvent(eventType, mouse.x, mouse.y)
        }
    }
    
    // Video state indicator (top-right corner)
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Theme.spacingMedium
        width: 80
        height: 30
        radius: Theme.radiusSmall
        color: androidAutoFacade && androidAutoFacade.isVideoActive 
               ? Qt.rgba(0.3, 0.8, 0.3, 0.8)  // Green
               : Qt.rgba(0.5, 0.5, 0.5, 0.8)  // Gray
        visible: androidAutoFacade !== null
        
        Text {
            anchors.centerIn: parent
            text: parent.parent.androidAutoFacade && parent.parent.androidAutoFacade.isVideoActive 
                  ? qsTr("VIDEO ON") 
                  : qsTr("NO VIDEO")
            font.pixelSize: Theme.fontSizeSmall
            color: "white"
            font.bold: true
        }
    }
    
    // Audio state indicator (top-left corner)
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: Theme.spacingMedium
        width: 80
        height: 30
        radius: Theme.radiusSmall
        color: androidAutoFacade && androidAutoFacade.isAudioActive 
               ? Qt.rgba(0.3, 0.8, 0.3, 0.8)  // Green
               : Qt.rgba(0.5, 0.5, 0.5, 0.8)  // Gray
        visible: androidAutoFacade !== null
        
        Text {
            anchors.centerIn: parent
            text: parent.parent.androidAutoFacade && parent.parent.androidAutoFacade.isAudioActive 
                  ? qsTr("AUDIO ON") 
                  : qsTr("NO AUDIO")
            font.pixelSize: Theme.fontSizeSmall
            color: "white"
            font.bold: true
        }
    }
    
    Component.onCompleted: {
        console.log("AAProjectionView loaded")
    }
}
