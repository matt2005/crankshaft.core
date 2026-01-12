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
 * @brief Reusable toggle component for theme mode selection (Light/Dark).
 *
 * Properties:
 * - currentMode: Current theme mode ("LIGHT" or "DARK")
 * - onModeChanged: Signal emitted when user selects a theme
 */
ColumnLayout {
    id: themeToggle
    spacing: 8
    
    property string currentMode: "DARK"
    
    signal modeChanged(string newMode)
    
    Label {
        text: qsTr("Theme", "ThemeToggle")
        font.pointSize: 12
        font.bold: true
    }
    
    RowLayout {
        Layout.fillWidth: true
        spacing: 16
        
        Button {
            text: qsTr("Light", "ThemeToggle")
            Layout.fillWidth: true
            checkable: true
            checked: themeToggle.currentMode === "LIGHT"
            
            onClicked: {
                if (checked) {
                    themeToggle.currentMode = "LIGHT"
                    themeToggle.modeChanged("LIGHT")
                }
            }
        }
        
        Button {
            text: qsTr("Dark", "ThemeToggle")
            Layout.fillWidth: true
            checkable: true
            checked: themeToggle.currentMode === "DARK"
            
            onClicked: {
                if (checked) {
                    themeToggle.currentMode = "DARK"
                    themeToggle.modeChanged("DARK")
                }
            }
        }
    }
}
