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
    property string mode: "dark"  // "light" or "dark"
    
    readonly property bool isDark: mode === "dark"
    readonly property bool isLight: mode === "light"
    
    // Colour palette - Design for Driving compliant
    property color backgroundColor: isDark ? "#1e1e1e" : "#f5f5f5"
    property color foregroundColor: isDark ? "#ffffff" : "#212121"
    property color surfaceColor: isDark ? "#2d2d2d" : "#ffffff"
    property color borderColor: isDark ? "#404040" : "#e0e0e0"
    
    // Accent colours
    property color accentColor: "#2196F3"
    property color accentLightColor: "#64B5F6"
    property color accentDarkColor: "#1976D2"
    
    // Semantic colours
    property color errorColor: "#f44336"
    property color successColor: "#4caf50"
    property color warningColor: "#ff9800"
    property color infoColor: "#2196F3"
    
    // Text colours
    property color textPrimaryColor: foregroundColor
    property color textSecondaryColor: isDark ? "#b0b0b0" : "#757575"
    property color textDisabledColor: isDark ? "#606060" : "#bdbdbd"
    
    // Spacing constants (Design for Driving - touch targets)
    readonly property int spacing: 16
    readonly property int spacingSmall: 8
    readonly property int spacingLarge: 24
    readonly property int spacingXLarge: 32
    
    readonly property int touchTargetMinimum: 44  // Minimum touch target size
    readonly property int touchTargetRecommended: 64  // Recommended for driving
    
    // Typography
    readonly property int titleSize: 28
    readonly property int headingSize: 24
    readonly property int bodySize: 16
    readonly property int captionSize: 14
    readonly property int smallSize: 12
    
    readonly property string fontFamily: "Roboto"
    
    // Border radius
    readonly property int radiusSmall: 4
    readonly property int radiusMedium: 8
    readonly property int radiusLarge: 16
    
    // Animation durations (ms)
    readonly property int animationFast: 150
    readonly property int animationNormal: 300
    readonly property int animationSlow: 500
    
    // Z-index layers
    readonly property int zBackground: 0
    readonly property int zContent: 1
    readonly property int zOverlay: 10
    readonly property int zDialog: 20
    readonly property int zTooltip: 30
    
    // Function to toggle theme
    function toggleTheme() {
        mode = (mode === "dark") ? "light" : "dark"
    }
    
    // Function to set theme explicitly
    function setTheme(newMode) {
        if (newMode === "light" || newMode === "dark") {
            mode = newMode
        }
    }
}

