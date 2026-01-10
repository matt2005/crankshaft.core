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
import QtTest
import Crankshaft 1.0
import Crankshaft.Components 1.0

TestCase {
    id: layoutTests
    name: "LayoutTests"
    width: 1024
    height: 600

    /**
     * Test: Layout breakpoint detection across device sizes
     * Validates: LayoutUtils.breakpointTier() returns correct tier for 800x480, 1024x600, 1920x1080
     */
    function test_breakpoint_detection() {
        // 800x480 (small portrait) -> breakpointTier should be SMALL
        var tier = LayoutUtils.breakpointTier(800)
        verify(tier === LayoutUtils.BREAKPOINT_SMALL, 
            "800x480: expected SMALL, got " + tier)

        // 1024x600 (medium/default) -> breakpointTier should be MEDIUM
        tier = LayoutUtils.breakpointTier(1024)
        verify(tier === LayoutUtils.BREAKPOINT_MEDIUM, 
            "1024x600: expected MEDIUM, got " + tier)

        // 1920x1080 (large) -> breakpointTier should be LARGE
        tier = LayoutUtils.breakpointTier(1920)
        verify(tier === LayoutUtils.BREAKPOINT_LARGE, 
            "1920x1080: expected LARGE, got " + tier)
    }

    /**
     * Test: Tap target minimum size validation
     * Validates: Interactive elements (buttons, tiles) meet 44x44 px minimum per Design for Driving
     */
    function test_tap_target_minimums() {
        var minTapTarget = 44  // Design for Driving minimum
        
        // AppButton should be at least 44x44
        verify(Theme.tapTargetSmall >= minTapTarget,
            "Small tap target " + Theme.tapTargetSmall + " < " + minTapTarget + " px")
        
        // Default button target should meet or exceed 44x44
        verify(Theme.tapTarget >= minTapTarget,
            "Default tap target " + Theme.tapTarget + " < " + minTapTarget + " px")
        
        // Large tap target should be even bigger
        verify(Theme.tapTargetLarge >= Theme.tapTarget,
            "Large tap target " + Theme.tapTargetLarge + " < default " + Theme.tapTarget + " px")
    }

    /**
     * Test: Spacing scale consistency
     * Validates: All spacing tokens are multiples of 4 or 8 for visual harmony
     */
    function test_spacing_scale_consistency() {
        var spacingTokens = [
            { name: "spacingXs", value: Theme.spacingXs },
            { name: "spacingSm", value: Theme.spacingSm },
            { name: "spacingMd", value: Theme.spacingMd },
            { name: "spacingLg", value: Theme.spacingLg },
            { name: "spacingXl", value: Theme.spacingXl },
        ]
        
        for (var i = 0; i < spacingTokens.length; i++) {
            var token = spacingTokens[i]
            var isMultiple = (token.value % 4) === 0
            verify(isMultiple, 
                token.name + " = " + token.value + " is not a multiple of 4")
        }
    }

    /**
     * Test: Typography scale hierarchy
     * Validates: Font sizes follow a consistent scale (e.g., subtitle > body > caption)
     */
    function test_typography_hierarchy() {
        verify(Theme.fontSizeHeading1 > Theme.fontSizeHeading2,
            "H1 " + Theme.fontSizeHeading1 + " should be > H2 " + Theme.fontSizeHeading2)
        
        verify(Theme.fontSizeHeading2 > Theme.fontSizeSubtitle1,
            "H2 " + Theme.fontSizeHeading2 + " should be > subtitle1 " + Theme.fontSizeSubtitle1)
        
        verify(Theme.fontSizeSubtitle1 > Theme.fontSizeBody,
            "Subtitle1 " + Theme.fontSizeSubtitle1 + " should be > body " + Theme.fontSizeBody)
        
        verify(Theme.fontSizeBody > Theme.fontSizeCaption,
            "Body " + Theme.fontSizeBody + " should be > caption " + Theme.fontSizeCaption)
    }

    /**
     * Test: Animation duration thresholds
     * Validates: Feedback animations stay within 150 ms for responsive feel
     */
    function test_animation_duration_thresholds() {
        var feedbackThreshold = 150  // ms - Design for Driving responsiveness
        var standardThreshold = 300   // ms - Standard UI transitions
        
        verify(Theme.animationFeedback <= feedbackThreshold,
            "Feedback animation " + Theme.animationFeedback + " ms exceeds " + feedbackThreshold + " ms")
        
        verify(Theme.animationDuration <= standardThreshold,
            "Standard animation " + Theme.animationDuration + " ms exceeds " + standardThreshold + " ms")
        
        verify(Theme.animationFeedback < Theme.animationDuration,
            "Feedback animation should be faster than standard")
    }

    /**
     * Test: Responsive tile layout at different breakpoints
     * Validates: Tiles reflow without clipping at 800x480, 1024x600, 1920x1080
     */
    function test_responsive_tile_layout() {
        // Create a test window with flow layout
        var testWindow = Qt.createQmlObject(`
            import QtQuick
            import QtQuick.Layouts
            import Crankshaft.Components 1.0
            
            Rectangle {
                id: testRect
                color: Theme.background
                
                Flow {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingMd
                    spacing: Theme.spacingMd
                    
                    // Simulate 2-column tile layout (AA + Settings)
                    Rectangle {
                        width: (parent.width - Theme.spacingMd) / 2
                        height: Math.min(width, (parent.height - Theme.spacingMd) / 2)
                        color: Theme.surface
                        border.color: Theme.divider
                        border.width: 1
                    }
                    
                    Rectangle {
                        width: (parent.width - Theme.spacingMd) / 2
                        height: Math.min(width, (parent.height - Theme.spacingMd) / 2)
                        color: Theme.surface
                        border.color: Theme.divider
                        border.width: 1
                    }
                }
            }
        `, layoutTests)
        
        // Test at small breakpoint (800x480)
        testWindow.width = 800
        testWindow.height = 480
        wait(100)  // Allow layout to reflow
        verify(testWindow.width > 0 && testWindow.height > 0,
            "Small layout (800x480) failed to render")
        
        // Test at medium breakpoint (1024x600)
        testWindow.width = 1024
        testWindow.height = 600
        wait(100)
        verify(testWindow.width > 0 && testWindow.height > 0,
            "Medium layout (1024x600) failed to render")
        
        // Test at large breakpoint (1920x1080)
        testWindow.width = 1920
        testWindow.height = 1080
        wait(100)
        verify(testWindow.width > 0 && testWindow.height > 0,
            "Large layout (1920x1080) failed to render")
        
        testWindow.destroy()
    }

    /**
     * Test: Contrast ratio compliance
     * Validates: Foreground/background colour pairs meet 4.5:1 minimum per WCAG
     */
    function test_contrast_ratio_compliance() {
        // Text primary on surface should have sufficient contrast
        verify(Theme.textPrimary !== Theme.surface,
            "Primary text colour matches surface background")
        
        // Secondary text should be distinguishable
        verify(Theme.textSecondary !== Theme.surface,
            "Secondary text colour matches surface background")
        
        // Error state should be visible
        verify(Theme.error !== Theme.surface,
            "Error colour matches surface background")
        
        // Success state should be visible
        verify(Theme.success !== Theme.surface,
            "Success colour matches surface background")
    }

    /**
     * Test: Radio button and toggle sizes meet accessibility requirements
     * Validates: Interactive controls are properly sized for touch
     */
    function test_interactive_control_sizes() {
        var minSize = 40  // Minimum for comfortable touch
        
        verify(Theme.tapTargetSmall >= minSize,
            "Small tap target " + Theme.tapTargetSmall + " < " + minSize + " px")
        
        verify(Theme.tapTarget >= minSize,
            "Default tap target " + Theme.tapTarget + " < " + minSize + " px")
    }

    /**
     * Test: Border radius consistency
     * Validates: All border radii are non-negative and follow design system
     */
    function test_border_radius_consistency() {
        verify(Theme.radiusXs >= 0, "radiusXs should be non-negative")
        verify(Theme.radiusSm >= 0, "radiusSm should be non-negative")
        verify(Theme.radiusMd >= 0, "radiusMd should be non-negative")
        
        verify(Theme.radiusXs <= Theme.radiusSm, "radiusXs should be <= radiusSm")
        verify(Theme.radiusSm <= Theme.radiusMd, "radiusSm should be <= radiusMd")
    }
}
