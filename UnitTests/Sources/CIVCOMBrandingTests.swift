// Copyright 2026 KG PSP.
// SPDX-License-Identifier: AGPL-3.0-only

import Compound
@testable import ElementX
import SwiftUI
import Testing

struct CIVCOMBrandingTests {
    @Test func canonicalPaletteAndReadableContrast() throws {
        DefaultCompoundHook().override(colors: Color.compound, uiColors: UIColor.compound)
        for style in [UIUserInterfaceStyle.dark, .light] {
            let dark = style == .dark
            let roles: [(UIColor, UInt32)] = [
                (.compound.bgCanvasDefault, dark ? 0x0B1523 : 0xF7F9FB),
                (.compound.bgSubtlePrimary, dark ? 0x101D30 : 0xEDF1F6),
                (.compound.bgSubtleSecondary, dark ? 0x16263D : 0xEDF1F6),
                (.compound.bgSubtleTertiary, dark ? 0x0A1420 : 0xEDF1F6),
                (.compound.borderInteractiveSecondary, dark ? 0x223650 : 0xC9D4E0),
                (.compound.textPrimary, dark ? 0xE8EEF5 : 0x14212F),
                (.compound.textSecondary, dark ? 0x8CA0B8 : 0x5C6E82),
                (.compound.textActionAccent, dark ? 0x4C8FD6 : 0x1D5FAE),
                (.compound.bgActionPrimaryRest, dark ? 0xD22730 : 0xC01F2A),
                (.compound.iconSuccessPrimary, dark ? 0x2F9E63 : 0x22794B)
            ]
            for (color, expected) in roles {
                #expect(try hex(color, style) == expected)
            }
            for (foreground, background) in [(UIColor.compound.textPrimary, UIColor.compound.bgCanvasDefault),
                                             (.compound.textSecondary, .compound.bgSubtlePrimary),
                                             (.compound.textActionAccent, .compound.bgCanvasDefault),
                                             (.compound.textOnSolidPrimary, .compound.bgActionPrimaryRest),
                                             (.compound.textOnSolidPrimary, .compound.bgActionPrimaryPressed)] {
                let first = try luminance(foreground, style)
                let second = try luminance(background, style)
                #expect((max(first, second) + 0.05) / (min(first, second) + 0.05) >= 4.5)
            }
        }
    }
    
    @Test func darkDefaultPreservesExistingChoice() {
        let store = VolatileUserDefaults()
        let settings = AppSettings(store: store)
        #expect(settings.appAppearance == .dark)
        settings.appAppearance = .light
        #expect(AppSettings(store: store).appAppearance == .light)
        settings.appAppearance = .system
        #expect(AppSettings(store: store).appAppearance == .system)
    }
    
    @Test func condensedHeadingAvailableAndScales() throws {
        let font = try #require(UIFont(name: "AvenirNextCondensed-Bold", size: 36))
        let scaled = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: font, compatibleWith: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge))
        #expect(scaled.pointSize > font.pointSize)
    }
    
    private func components(_ color: UIColor, _ style: UIUserInterfaceStyle) throws -> [Double] {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        #expect(color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style)).getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        #expect(alpha == 1)
        return [Double(red), Double(green), Double(blue)]
    }
    
    private func hex(_ color: UIColor, _ style: UIUserInterfaceStyle) throws -> UInt32 {
        let values = try components(color, style).map { UInt32(($0 * 255).rounded()) }
        return values[0] << 16 | values[1] << 8 | values[2]
    }
    
    private func luminance(_ color: UIColor, _ style: UIUserInterfaceStyle) throws -> Double {
        let values = try components(color, style).map { $0 <= 0.04045 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4) }
        return values[0] * 0.2126 + values[1] * 0.7152 + values[2] * 0.0722
    }
}
