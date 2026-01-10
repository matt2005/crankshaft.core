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

pragma Singleton
import QtQuick

QtObject {
    id: theme

    // Theme mode
    property bool isDark: false

    // Spacing scale (8px base)
    readonly property int spacing1: 8
    readonly property int spacing2: 16
    readonly property int spacing3: 24
    readonly property int spacing4: 32
    readonly property int spacing5: 40
    readonly property int spacing6: 48

    // Typography
    readonly property int fontSizeMin: 14
    readonly property int fontSizeBody: 16
    readonly property int fontSizeLarge: 20
    readonly property int fontSizeTitle: 24
    readonly property int fontSizeMax: 28

    readonly property string fontFamily: "Roboto"

    // Tap targets
    readonly property int minTapTarget: 44

    // Palette - Light
    readonly property color lightBackground: "#FFFFFF"
    readonly property color lightSurface: "#F5F5F5"
    readonly property color lightPrimary: "#1976D2"
    readonly property color lightSecondary: "#424242"
    readonly property color lightText: "#212121"
    readonly property color lightTextSecondary: "#757575"
    readonly property color lightBorder: "#E0E0E0"

    // Palette - Dark
    readonly property color darkBackground: "#121212"
    readonly property color darkSurface: "#1E1E1E"
    readonly property color darkPrimary: "#90CAF9"
    readonly property color darkSecondary: "#B0B0B0"
    readonly property color darkText: "#FFFFFF"
    readonly property color darkTextSecondary: "#AAAAAA"
    readonly property color darkBorder: "#303030"

    // Status colors (same for light/dark)
    readonly property color success: "#4CAF50"
    readonly property color warning: "#FF9800"
    readonly property color error: "#F44336"
    readonly property color info: "#2196F3"

    // Active palette (derived from isDark)
    readonly property color background: isDark ? darkBackground : lightBackground
    readonly property color surface: isDark ? darkSurface : lightSurface
    readonly property color primary: isDark ? darkPrimary : lightPrimary
    readonly property color secondary: isDark ? darkSecondary : lightSecondary
    readonly property color text: isDark ? darkText : lightText
    readonly property color textSecondary: isDark ? darkTextSecondary : lightTextSecondary
    readonly property color border: isDark ? darkBorder : lightBorder

    // Contrast ratio validation (informational; actual contrast should be verified with tooling)
    // Light text on light background: #212121 on #FFFFFF = 16.1:1 ✓
    // Dark text on dark background: #FFFFFF on #121212 = 17.5:1 ✓
    // Both exceed WCAG AAA (7:1) and target 4.5:1
}
