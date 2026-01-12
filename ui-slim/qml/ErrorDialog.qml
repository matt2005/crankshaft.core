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

/**
 * ErrorDialog - Modal dialog for displaying errors and warnings
 * 
 * Displays error messages with optional retry functionality
 * Supports different severity levels with appropriate styling
 */
Dialog {
    id: errorDialog
    
    // Properties
    property string errorCode: ""
    property string errorMessage: ""
    property int severity: 2  // 0=Info, 1=Warning, 2=Error, 3=Critical
    property bool retryable: false
    
    // Dialog configuration
    modal: true
    closePolicy: Popup.CloseOnEscape
    
    width: Math.min(500, parent.width * 0.9)
    height: Math.min(300, parent.height * 0.7)
    
    anchors.centerIn: parent
    
    // Signals
    signal retryRequested()
    signal dismissed()
    
    // Background
    background: Rectangle {
        color: theme.colors.surface
        border.color: getSeverityColor()
        border.width: 2
        radius: theme.dimensions.borderRadiusLarge
        
        layer.enabled: true
        layer.effect: theme.effects.dropShadow
    }
    
    // Header with icon and title
    header: Item {
        height: 80
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: theme.spacing.large
            spacing: theme.spacing.medium
            
            // Severity icon
            Text {
                Layout.alignment: Qt.AlignVCenter
                text: getSeverityIcon()
                color: getSeverityColor()
                font.pixelSize: 48
            }
            
            // Title
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: theme.spacing.small
                
                Text {
                    Layout.fillWidth: true
                    text: getSeverityTitle()
                    color: theme.colors.textPrimary
                    font.pixelSize: theme.typography.h4
                    font.family: theme.typography.fontFamily
                    font.weight: Font.Medium
                }
                
                Text {
                    Layout.fillWidth: true
                    text: errorCode
                    color: theme.colors.textSecondary
                    font.pixelSize: theme.typography.caption
                    font.family: theme.typography.fontFamilyMono
                    visible: errorCode !== ""
                }
            }
        }
    }
    
    // Content - error message
    contentItem: Item {
        ScrollView {
            anchors.fill: parent
            anchors.margins: theme.spacing.medium
            clip: true
            
            Text {
                width: parent.width
                text: errorMessage
                color: theme.colors.textPrimary
                font.pixelSize: theme.typography.body1
                font.family: theme.typography.fontFamily
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignLeft
            }
        }
    }
    
    // Footer with action buttons
    footer: Item {
        height: 80
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: theme.spacing.large
            spacing: theme.spacing.medium
            
            Item {
                Layout.fillWidth: true
            }
            
            // Retry button (if retryable)
            Button {
                visible: retryable
                Layout.preferredWidth: 120
                Layout.preferredHeight: theme.dimensions.recommendedTouchTarget
                
                text: qsTr("Retry")
                font.pixelSize: theme.typography.button
                font.family: theme.typography.fontFamily
                
                onClicked: {
                    errorDialog.retryRequested()
                    errorDialog.close()
                }
                
                background: Rectangle {
                    color: parent.pressed ? theme.colors.primaryVariant : theme.colors.primary
                    radius: theme.dimensions.borderRadiusMedium
                }
                
                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    color: theme.colors.onPrimary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            
            // OK/Dismiss button
            Button {
                Layout.preferredWidth: 120
                Layout.preferredHeight: theme.dimensions.recommendedTouchTarget
                
                text: retryable ? qsTr("Cancel") : qsTr("OK")
                font.pixelSize: theme.typography.button
                font.family: theme.typography.fontFamily
                
                onClicked: {
                    errorDialog.dismissed()
                    errorDialog.close()
                }
                
                background: Rectangle {
                    color: parent.pressed ? theme.colors.surfaceVariant : theme.colors.surface
                    border.color: theme.colors.border
                    border.width: 1
                    radius: theme.dimensions.borderRadiusMedium
                }
                
                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    color: theme.colors.textPrimary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
    
    // Helper functions
    function getSeverityIcon() {
        switch (severity) {
            case 0: return "ℹ️"  // Info
            case 1: return "⚠️"  // Warning
            case 2: return "❌"  // Error
            case 3: return "🛑"  // Critical
            default: return "❓"
        }
    }
    
    function getSeverityTitle() {
        switch (severity) {
            case 0: return qsTr("Information")
            case 1: return qsTr("Warning")
            case 2: return qsTr("Error")
            case 3: return qsTr("Critical Error")
            default: return qsTr("Error")
        }
    }
    
    function getSeverityColor() {
        switch (severity) {
            case 0: return theme.colors.info || "#2196F3"     // Info - blue
            case 1: return theme.colors.warning || "#FF9800"  // Warning - orange
            case 2: return theme.colors.error || "#F44336"    // Error - red
            case 3: return theme.colors.error || "#D32F2F"    // Critical - dark red
            default: return theme.colors.error || "#F44336"
        }
    }
    
    /**
     * Show error dialog with specified parameters
     */
    function showError(code, message, severityLevel, isRetryable) {
        errorCode = code
        errorMessage = message
        severity = severityLevel
        retryable = isRetryable
        open()
    }
}
