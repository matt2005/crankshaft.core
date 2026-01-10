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
    id: layoutUtils

    // Responsive breakpoints (width in pixels)
    readonly property int breakpointSmall: 800   // 800×480
    readonly property int breakpointMedium: 1024  // 1024×600
    readonly property int breakpointLarge: 1920   // 1920×1080

    // Determine breakpoint tier from width
    function breakpointTier(width) {
        if (width < breakpointSmall) return "xs"
        if (width < breakpointMedium) return "sm"
        if (width < breakpointLarge) return "md"
        return "lg"
    }

    // Compute responsive margins based on tier
    function responsiveMargin(width) {
        const tier = breakpointTier(width)
        switch (tier) {
            case "xs": return 8
            case "sm": return 16
            case "md": return 24
            case "lg": return 32
            default: return 16
        }
    }

    // Compute responsive padding based on tier
    function responsivePadding(width) {
        const tier = breakpointTier(width)
        switch (tier) {
            case "xs": return 8
            case "sm": return 12
            case "md": return 16
            case "lg": return 24
            default: return 12
        }
    }

    // Tile grid columns based on width
    function tileColumns(width) {
        const tier = breakpointTier(width)
        switch (tier) {
            case "xs": return 1
            case "sm": return 2
            case "md": return 3
            case "lg": return 4
            default: return 2
        }
    }

    // Check if reflow is needed (for orientation/size change)
    function shouldReflow(oldWidth, newWidth) {
        return breakpointTier(oldWidth) !== breakpointTier(newWidth)
    }
}
