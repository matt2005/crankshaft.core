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
 * @brief Reusable slider component for settings with label and value display.
 *
 * Properties:
 * - label: Display text for the setting
 * - value: Current slider value (0-100)
 * - onValueChanged: Signal emitted when user adjusts slider
 */
ColumnLayout {
    id: settingsSlider
    spacing: 8
    
    property alias label: labelText.text
    property int value: 50
    property int from: 0
    property int to: 100
    
    signal valueChanged(int newValue)
    
    Label {
        id: labelText
        font.pointSize: 12
        font.bold: true
    }
    
    RowLayout {
        Layout.fillWidth: true
        spacing: 16
        
        Slider {
            Layout.fillWidth: true
            from: settingsSlider.from
            to: settingsSlider.to
            stepSize: 1
            value: settingsSlider.value
            
            onMoved: {
                const newValue = Math.round(value)
                settingsSlider.value = newValue
                settingsSlider.valueChanged(newValue)
            }
        }
        
        Label {
            text: settingsSlider.value + "%"
            font.pointSize: 11
            Layout.minimumWidth: 40
            horizontalAlignment: Text.AlignRight
        }
    }
}
