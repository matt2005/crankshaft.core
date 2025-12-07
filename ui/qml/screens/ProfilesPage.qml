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
import "../components"
import Crankshaft 1.0

Page {
    id: root
    
    property var stack: null
    
    background: Rectangle {
        color: Theme.background
    }
    
    // Get the profiles category
    property var profilesCategory: SettingsModel.getCategoryById("profiles")
    
    // Header
    Rectangle {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 80
        color: Theme.surface
        z: 10
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16
            
            AppButton {
                text: "←"
                implicitWidth: 76
                implicitHeight: 76
                onClicked: {
                    if (stack) {
                        stack.pop()
                    }
                }
            }
            
            Text {
                text: "Device Profiles"
                font.pixelSize: 32
                font.bold: true
                color: Theme.textPrimary
                Layout.fillWidth: true
            }
        }
    }
    
    // Settings content
    ScrollView {
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 16
        clip: true
        
        ColumnLayout {
            width: parent.width - 32
            spacing: 24
            
            // Iterate through all settings in the profiles category
            Repeater {
                model: profilesCategory ? profilesCategory.settings : []
                
                delegate: Loader {
                    Layout.fillWidth: true
                    
                    sourceComponent: {
                        switch(modelData.type) {
                            case "toggle":
                                return toggleSetting
                            case "select":
                                return selectSetting
                            case "text":
                                return textSetting
                            case "number":
                                return numberSetting
                            case "slider":
                                return sliderSetting
                            case "info":
                                return infoSetting
                            default:
                                return null
                        }
                    }
                    
                    property var settingData: modelData
                }
            }
        }
    }
    
    // Setting component templates
    Component {
        id: toggleSetting
        
        Rectangle {
            width: parent.width
            height: 80
            color: Theme.surface
            radius: 4
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    
                    Text {
                        text: settingData.label
                        font.pixelSize: 16
                        font.bold: true
                        color: Theme.textPrimary
                    }
                    
                    Text {
                        text: settingData.description
                        font.pixelSize: 14
                        color: Theme.textSecondary
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
                
                Switch {
                    checked: settingData.value
                    onToggled: {
                        settingData.value = checked
                        if (settingData.onChange) {
                            settingData.onChange(checked)
                        }
                    }
                }
            }
        }
    }
    
    Component {
        id: selectSetting
        
        Rectangle {
            width: parent.width
            height: 100
            color: Theme.surface
            radius: 4
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8
                
                Text {
                    text: settingData.label
                    font.pixelSize: 16
                    font.bold: true
                    color: Theme.textPrimary
                }
                
                Text {
                    text: settingData.description
                    font.pixelSize: 14
                    color: Theme.textSecondary
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                
                ComboBox {
                    Layout.fillWidth: true
                    model: settingData.options
                    textRole: "label"
                    valueRole: "value"
                    
                    Component.onCompleted: {
                        currentIndex = indexOfValue(settingData.value)
                    }
                    
                    onActivated: {
                        settingData.value = currentValue
                        if (settingData.onChange) {
                            settingData.onChange(currentValue)
                        }
                    }
                }
            }
        }
    }
    
    Component {
        id: textSetting
        
        Rectangle {
            width: parent.width
            height: 100
            color: Theme.surface
            radius: 4
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8
                
                Text {
                    text: settingData.label
                    font.pixelSize: 16
                    font.bold: true
                    color: Theme.textPrimary
                }
                
                Text {
                    text: settingData.description
                    font.pixelSize: 14
                    color: Theme.textSecondary
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                
                TextField {
                    Layout.fillWidth: true
                    text: settingData.value
                    onEditingFinished: {
                        settingData.value = text
                        if (settingData.onChange) {
                            settingData.onChange(text)
                        }
                    }
                }
            }
        }
    }
    
    Component {
        id: numberSetting
        
        Rectangle {
            width: parent.width
            height: 100
            color: Theme.surface
            radius: 4
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8
                
                Text {
                    text: settingData.label
                    font.pixelSize: 16
                    font.bold: true
                    color: Theme.textPrimary
                }
                
                Text {
                    text: settingData.description
                    font.pixelSize: 14
                    color: Theme.textSecondary
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                
                SpinBox {
                    Layout.fillWidth: true
                    value: settingData.value
                    from: settingData.min || 0
                    to: settingData.max || 100
                    onValueModified: {
                        settingData.value = value
                        if (settingData.onChange) {
                            settingData.onChange(value)
                        }
                    }
                }
            }
        }
    }
    
    Component {
        id: sliderSetting
        
        Rectangle {
            width: parent.width
            height: 120
            color: Theme.surface
            radius: 4
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8
                
                Text {
                    text: settingData.label
                    font.pixelSize: 16
                    font.bold: true
                    color: Theme.textPrimary
                }
                
                Text {
                    text: settingData.description
                    font.pixelSize: 14
                    color: Theme.textSecondary
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Slider {
                        Layout.fillWidth: true
                        value: settingData.value
                        from: settingData.min || 0
                        to: settingData.max || 100
                        stepSize: settingData.step || 1
                        onMoved: {
                            settingData.value = value
                            if (settingData.onChange) {
                                settingData.onChange(value)
                            }
                        }
                    }
                    
                    Text {
                        text: Math.round(settingData.value)
                        font.pixelSize: 14
                        color: Theme.textPrimary
                        Layout.preferredWidth: 40
                    }
                }
            }
        }
    }
    
    Component {
        id: infoSetting
        
        Rectangle {
            width: parent.width
            height: contentText.implicitHeight + 32
            color: Theme.surface
            radius: 4
            
            Text {
                id: contentText
                anchors.fill: parent
                anchors.margins: 16
                text: settingData.value
                font.pixelSize: 14
                color: Theme.textSecondary
                wrapMode: Text.WordWrap
            }
        }
    }
}
