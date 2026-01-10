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

Page {
    id: root
    
    property var stack: null
    property var settingsComponent: null
    property var androidAutoComponent: null
    
    // Navigation validation: only allow access to implemented screens
    // Currently available: HomeScreen, SettingsScreen, AndroidAutoScreen
    // Unavailable routes (disabled): Navigation, Phone, Media, Bluetooth, WiFi, Profiles, Tools
    function requestNavigation(target) {
        var validTargets = ['settings', 'androidauto', 'home']
        if (validTargets.indexOf(target) === -1) {
            console.warn('[HomeScreen] Navigation to unavailable route:', target)
            return false
        }
        return true
    }
    
    background: Rectangle {
        color: Theme.background
    }
    
    header: Rectangle {
        width: parent.width
        height: 80
        color: Theme.surface
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16
            
            Text {
                text: Strings.appTitle
                font.pixelSize: 32
                font.bold: true
                color: Theme.textPrimary
                Layout.fillWidth: true
            }
            
            AppButton {
                text: "⚙"
                implicitWidth: 76
                implicitHeight: 76
                onClicked: {
                    if (stack && settingsComponent) {
                        stack.push(settingsComponent, { stack: stack })
                    }
                }
            }
        }
    }
    
    // Main content area following Design for Driving guidelines
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingMd
        spacing: Theme.spacingMd
        
        // Status bar - Primary driving information
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            color: Theme.surface
            radius: Theme.radiusSm
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingSm
                spacing: Theme.spacingMd
                
                Text {
                    text: Strings.homeWelcome
                    font.pixelSize: Theme.fontSizeHeading2
                    font.bold: true
                    color: Theme.textPrimary
                    Layout.fillWidth: true
                }
                
                SystemClock {
                    fontSize: Theme.fontSizeBody
                    textColor: Theme.textSecondary
                    timeFormat: "hh:mm"
                }
            }
        }
        
        // Home tiles: Only AndroidAuto and Settings with responsive layout
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            
            Flow {
                anchors.fill: parent
                spacing: Theme.spacingMd
                
                // Android Auto - Primary tile
                Tile {
                    width: (parent.width - Theme.spacingMd) / 2
                    height: Math.min(width, (parent.height - Theme.spacingMd) / 2)
                    title: Strings.cardAndroidAutoTitle
                    description: Strings.cardAndroidAutoDesc
                    icon: "mdi-android-auto"
                    
                    onClicked: {
                        if (stack && root.androidAutoComponent) {
                            stack.push(root.androidAutoComponent, { stack: stack })
                        }
                    }
                }
                
                // Settings - Secondary tile
                Tile {
                    width: (parent.width - Theme.spacingMd) / 2
                    height: Math.min(width, (parent.height - Theme.spacingMd) / 2)
                    title: Strings.buttonSettings
                    description: Strings.cardSettingsDesc
                    icon: "mdi-cog"
                    
                    onClicked: {
                        if (stack && root.settingsComponent) {
                            stack.push(root.settingsComponent, { stack: stack })
                        }
                    }
                }
            }
        }
    }
}
