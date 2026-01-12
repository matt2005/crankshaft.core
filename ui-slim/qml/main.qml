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
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: root
    visible: true
    width: 800
    height: 480
    title: qsTr("Crankshaft Slim UI - AndroidAuto")
    
    // Theme Manager - centralized theme control
    ThemeManager {
        id: theme
    }
    
    // View Navigation Controller - manages AA/Settings/Connection views
    ViewNavigationController {
        id: navigationController
    }
    
    // Error Dialog - displays errors from ErrorHandler
    ErrorDialog {
        id: errorDialog
    }
    
    // Watch for theme mode changes from PreferencesFacade
    Connections {
        target: _preferencesFacade
        function onThemeModeChanged(mode) {
            theme.setTheme(mode)
        }
    }
    
    // Watch for errors from ErrorHandler
    Connections {
        target: _errorHandler
        function onErrorOccurred(code, message, severity, retryable) {
            errorDialog.showError(code, message, severity, retryable)
        }
    }
    
    // Initialize theme from preferences on startup
    Component.onCompleted: {
        if (_preferencesFacade) {
            theme.setTheme(_preferencesFacade.themeMode)
        }
    }
    
    color: theme.colors.background
    
    
    // Main content area with state-based view switching
    Item {
        anchors.fill: parent
        
        // Background
        Rectangle {
            anchors.fill: parent
            color: theme.colors.background
        }
        
        // Loading/Connection view
        Rectangle {
            id: loadingView
            anchors.fill: parent
            color: theme.colors.background
            visible: navigationController.currentViewState === ViewNavigationController.ViewState.Loading ||
                     navigationController.currentViewState === ViewNavigationController.ViewState.ConnectionStatus
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: theme.spacing.large
                
                // Loading indicator
                BusyIndicator {
                    Layout.alignment: Qt.AlignHCenter
                    running: navigationController.currentViewState === ViewNavigationController.ViewState.Loading
                    width: 64
                    height: 64
                }
                
                // Status text
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Slim AndroidAuto UI")
                    color: theme.colors.textPrimary
                    font.pixelSize: theme.typography.h3
                    font.family: theme.typography.fontFamily
                }
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: navigationController.currentViewState === ViewNavigationController.ViewState.Loading ?
                          "Initializing..." : "Waiting for connection..."
                    color: theme.colors.textSecondary
                    font.pixelSize: theme.typography.body1
                    font.family: theme.typography.fontFamily
                }
            }
        }
        
        // AndroidAuto Projection View (primary)
        Rectangle {
            id: aaProjectionView
            anchors.fill: parent
            color: theme.colors.background
            visible: navigationController.currentViewState === ViewNavigationController.ViewState.AAProjection ||
                     navigationController.currentViewState === ViewNavigationController.ViewState.Settings
            
            // Placeholder for actual AA projection content
            ColumnLayout {
                anchors.fill: parent
                spacing: 0
                
                // Toolbar
                Rectangle {
                    Layout.fillWidth: true
                    height: theme.dimensions.toolbarHeight
                    color: theme.colors.surface
                    border.color: theme.colors.border
                    border.width: 1
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: theme.spacing.small
                        spacing: theme.spacing.medium
                        
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("AndroidAuto Projection")
                            color: theme.colors.textPrimary
                            font.pixelSize: theme.typography.body1
                            font.family: theme.typography.fontFamily
                        }
                    }
                }
                
                // AA Content area (would show actual projection here)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: theme.colors.background
                    
                    // Settings button (top-right corner - T061)
                    Button {
                        id: settingsButton
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: theme.spacing.medium
                        
                        width: theme.dimensions.recommendedTouchTarget
                        height: theme.dimensions.recommendedTouchTarget
                        
                        text: "⚙️"
                        font.pixelSize: 28
                        
                        ToolTip.visible: hovered
                        ToolTip.text: qsTr("Settings")
                        
                        onClicked: navigationController.toggleSettings()
                        
                        background: Rectangle {
                            color: settingsButton.pressed ? theme.colors.primaryVariant : theme.colors.surface
                            border.color: theme.colors.border
                            border.width: 1
                            radius: theme.dimensions.borderRadiusMedium
                        }
                    }
                    
                    // Placeholder AA content
                    Text {
                        anchors.centerIn: parent
                        text: qsTr("AndroidAuto Projection Area\n(placeholder)")
                        color: theme.colors.textSecondary
                        font.pixelSize: theme.typography.h4
                        font.family: theme.typography.fontFamily
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
        
        // Settings Panel Overlay (T054-T055)
        SettingsPanel {
            id: settingsPanel
            anchors.centerIn: parent
            width: Math.min(600, parent.width * 0.9)
            height: Math.min(500, parent.height * 0.9)
            visible: navigationController.settingsPanelVisible
            
            onClosed: navigationController.closeSettings()
        }
    }
}

