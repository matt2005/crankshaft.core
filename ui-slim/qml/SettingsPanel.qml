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
 * @brief Settings panel modal providing UI for adjusting display, audio, and connection settings.
 *
 * Features:
 * - Tabbed layout for Display, Audio, Connection sections
 * - All controls bound 2-way to PreferencesFacade properties
 * - Factory reset button for resetting to defaults
 * - Responsive layout adapting to any screen size
 */
Dialog {
    id: settingsPanel
    title: qsTr("Settings", "SettingsPanel")
    modal: true
    width: Math.min(600, parent.width * 0.8)
    height: Math.min(500, parent.height * 0.8)
    
    // Position dialog in center of parent
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    
    // Ensure dialog is on top
    z: 1000
    
    standardButtons: Dialog.Close
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16
        
        // Tab bar for section selection
        TabBar {
            id: tabBar
            Layout.fillWidth: true
            
            TabButton {
                text: qsTr("Display", "SettingsPanel")
            }
            TabButton {
                text: qsTr("Audio", "SettingsPanel")
            }
            TabButton {
                text: qsTr("Connection", "SettingsPanel")
            }
        }
        
        // Tab content stack
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex
            
            // Display tab
            ColumnLayout {
                spacing: 20
                
                // Brightness control
                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    
                    Label {
                        text: qsTr("Brightness", "SettingsPanel")
                        font.pointSize: 12
                        font.bold: true
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16
                        
                        Slider {
                            Layout.fillWidth: true
                            from: 0
                            to: 100
                            stepSize: 1
                            value: _preferencesFacade.displayBrightness
                            
                            onMoved: {
                                _preferencesFacade.displayBrightness = Math.round(value)
                            }
                        }
                        
                        Label {
                            text: _preferencesFacade.displayBrightness + "%"
                            font.pointSize: 11
                            Layout.minimumWidth: 40
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
                
                // Theme mode toggle
                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    
                    Label {
                        text: qsTr("Theme", "SettingsPanel")
                        font.pointSize: 12
                        font.bold: true
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16
                        
                        Button {
                            text: qsTr("Light", "SettingsPanel")
                            Layout.fillWidth: true
                            checkable: true
                            checked: _preferencesFacade.themeMode === "LIGHT"
                            
                            onClicked: {
                                if (checked) {
                                    _preferencesFacade.themeMode = "LIGHT"
                                }
                            }
                        }
                        
                        Button {
                            text: qsTr("Dark", "SettingsPanel")
                            Layout.fillWidth: true
                            checkable: true
                            checked: _preferencesFacade.themeMode === "DARK"
                            
                            onClicked: {
                                if (checked) {
                                    _preferencesFacade.themeMode = "DARK"
                                }
                            }
                        }
                    }
                }
                
                Item { Layout.fillHeight: true }
            }
            
            // Audio tab
            ColumnLayout {
                spacing: 20
                
                // Volume control
                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    
                    Label {
                        text: qsTr("Volume", "SettingsPanel")
                        font.pointSize: 12
                        font.bold: true
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16
                        
                        Slider {
                            Layout.fillWidth: true
                            from: 0
                            to: 100
                            stepSize: 1
                            value: _preferencesFacade.audioVolume
                            
                            onMoved: {
                                _preferencesFacade.audioVolume = Math.round(value)
                            }
                        }
                        
                        Label {
                            text: _preferencesFacade.audioVolume + "%"
                            font.pointSize: 11
                            Layout.minimumWidth: 40
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
                
                Item { Layout.fillHeight: true }
            }
            
            // Connection tab
            ColumnLayout {
                spacing: 20
                
                // Connection preference toggle
                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    
                    Label {
                        text: qsTr("Connection Preference", "SettingsPanel")
                        font.pointSize: 12
                        font.bold: true
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16
                        
                        Button {
                            text: qsTr("USB", "SettingsPanel")
                            Layout.fillWidth: true
                            checkable: true
                            checked: _preferencesFacade.connectionPreference === "USB"
                            
                            onClicked: {
                                if (checked) {
                                    _preferencesFacade.connectionPreference = "USB"
                                }
                            }
                        }
                        
                        Button {
                            text: qsTr("Wireless", "SettingsPanel")
                            Layout.fillWidth: true
                            checkable: true
                            checked: _preferencesFacade.connectionPreference === "WIRELESS"
                            
                            onClicked: {
                                if (checked) {
                                    _preferencesFacade.connectionPreference = "WIRELESS"
                                }
                            }
                        }
                    }
                }
                
                // Factory reset button
                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignBottom
                    
                    Button {
                        Layout.fillWidth: true
                        text: qsTr("Reset to Factory Defaults", "SettingsPanel")
                        Material.foreground: Material.red
                        
                        onClicked: {
                            resetConfirmationDialog.open()
                        }
                    }
                }
                
                Item { Layout.fillHeight: true }
            }
        }
    }
    
    // Factory reset confirmation dialog
    Dialog {
        id: resetConfirmationDialog
        title: qsTr("Confirm Reset", "SettingsPanel")
        modal: true
        parent: settingsPanel.parent
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        z: 1001
        
        standardButtons: Dialog.Ok | Dialog.Cancel
        
        Label {
            text: qsTr("Reset all settings to factory defaults?\n\nBrightness: 50%\nVolume: 50%\nConnection: USB\nTheme: Dark", "SettingsPanel")
            wrapMode: Text.WordWrap
        }
        
        onAccepted: {
            _preferencesFacade.resetToDefaults()
            _preferencesFacade.saveSettings()
        }
    }
}
