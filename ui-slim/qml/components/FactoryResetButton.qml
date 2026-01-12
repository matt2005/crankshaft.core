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
 * @brief Factory reset button with confirmation dialog.
 *
 * Shows a button that opens a confirmation dialog before resetting settings
 * to factory defaults (brightness 50%, volume 50%, USB, dark theme).
 *
 * Properties:
 * - onReset: Signal emitted when user confirms factory reset
 */
ColumnLayout {
    id: factoryResetButton
    spacing: 8
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignBottom
    
    signal reset()
    
    Button {
        Layout.fillWidth: true
        text: qsTr("Reset to Factory Defaults", "FactoryResetButton")
        Material.foreground: Material.red
        
        onClicked: {
            resetConfirmationDialog.open()
        }
    }
    
    // Confirmation dialog
    Dialog {
        id: resetConfirmationDialog
        title: qsTr("Confirm Reset", "FactoryResetButton")
        modal: true
        parent: factoryResetButton.parent
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
        z: 1001
        
        standardButtons: Dialog.Ok | Dialog.Cancel
        
        Label {
            text: qsTr("Reset all settings to factory defaults?\n\nBrightness: 50%\nVolume: 50%\nConnection: USB\nTheme: Dark", "FactoryResetButton")
            wrapMode: Text.WordWrap
        }
        
        onAccepted: {
            factoryResetButton.reset()
        }
    }
}
