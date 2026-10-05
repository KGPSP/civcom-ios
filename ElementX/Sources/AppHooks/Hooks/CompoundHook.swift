//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

nonisolated protocol CompoundHookProtocol: Sendable {
    @MainActor func override(colors: CompoundColors, uiColors: CompoundUIColors)
}

struct DefaultCompoundHook: CompoundHookProtocol {
    func override(colors: CompoundColors, uiColors: CompoundUIColors) {
        func adaptive(_ light: UInt32, _ dark: UInt32) -> UIColor {
            UIColor { traits in
                let hex = traits.userInterfaceStyle == .dark ? dark : light
                return UIColor(red: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
            }
        }
        colors.override(\.bgCanvasDefault, with: Color(adaptive(0xF7F9FB, 0x0B1523)))
        uiColors.override(\.bgCanvasDefault, with: adaptive(0xF7F9FB, 0x0B1523))
        colors.override(\.bgCanvasDefaultLevel1, with: Color(adaptive(0xEDF1F6, 0x101D30)))
        uiColors.override(\.bgCanvasDefaultLevel1, with: adaptive(0xEDF1F6, 0x101D30))
        colors.override(\.bgSubtlePrimary, with: Color(adaptive(0xEDF1F6, 0x101D30)))
        uiColors.override(\.bgSubtlePrimary, with: adaptive(0xEDF1F6, 0x101D30))
        colors.override(\.bgSubtleSecondary, with: Color(adaptive(0xEDF1F6, 0x16263D)))
        uiColors.override(\.bgSubtleSecondary, with: adaptive(0xEDF1F6, 0x16263D))
        colors.override(\.bgSubtleTertiary, with: Color(adaptive(0xEDF1F6, 0x0A1420)))
        uiColors.override(\.bgSubtleTertiary, with: adaptive(0xEDF1F6, 0x0A1420))
        colors.override(\.bgActionSecondaryRest, with: Color(adaptive(0xEDF1F6, 0x101D30)))
        uiColors.override(\.bgActionSecondaryRest, with: adaptive(0xEDF1F6, 0x101D30))
        colors.override(\.bgActionSecondaryHovered, with: Color(adaptive(0xEDF1F6, 0x16263D)))
        uiColors.override(\.bgActionSecondaryHovered, with: adaptive(0xEDF1F6, 0x16263D))
        colors.override(\.bgActionSecondaryPressed, with: Color(adaptive(0xEDF1F6, 0x16263D)))
        uiColors.override(\.bgActionSecondaryPressed, with: adaptive(0xEDF1F6, 0x16263D))
        colors.override(\.bgActionPrimaryRest, with: Color(adaptive(0xC01F2A, 0xD22730)))
        uiColors.override(\.bgActionPrimaryRest, with: adaptive(0xC01F2A, 0xD22730))
        colors.override(\.bgActionPrimaryPressed, with: Color(adaptive(0xA51B25, 0xB82129)))
        uiColors.override(\.bgActionPrimaryPressed, with: adaptive(0xA51B25, 0xB82129))
        colors.override(\.bgActionPrimaryHovered, with: Color(adaptive(0xC01F2A, 0xD22730)))
        uiColors.override(\.bgActionPrimaryHovered, with: adaptive(0xC01F2A, 0xD22730))
        colors.override(\.textPrimary, with: Color(adaptive(0x14212F, 0xE8EEF5)))
        uiColors.override(\.textPrimary, with: adaptive(0x14212F, 0xE8EEF5))
        colors.override(\.textActionPrimary, with: Color(adaptive(0x14212F, 0xE8EEF5)))
        uiColors.override(\.textActionPrimary, with: adaptive(0x14212F, 0xE8EEF5))
        colors.override(\.iconPrimary, with: Color(adaptive(0x14212F, 0xE8EEF5)))
        uiColors.override(\.iconPrimary, with: adaptive(0x14212F, 0xE8EEF5))
        colors.override(\.textSecondary, with: Color(adaptive(0x5C6E82, 0x8CA0B8)))
        uiColors.override(\.textSecondary, with: adaptive(0x5C6E82, 0x8CA0B8))
        colors.override(\.iconSecondary, with: Color(adaptive(0x5C6E82, 0x8CA0B8)))
        uiColors.override(\.iconSecondary, with: adaptive(0x5C6E82, 0x8CA0B8))
        colors.override(\.textActionAccent, with: Color(adaptive(0x1D5FAE, 0x4C8FD6)))
        uiColors.override(\.textActionAccent, with: adaptive(0x1D5FAE, 0x4C8FD6))
        colors.override(\.textLinkExternal, with: Color(adaptive(0x1D5FAE, 0x4C8FD6)))
        uiColors.override(\.textLinkExternal, with: adaptive(0x1D5FAE, 0x4C8FD6))
        colors.override(\.iconAccentPrimary, with: Color(adaptive(0x1D5FAE, 0x4C8FD6)))
        uiColors.override(\.iconAccentPrimary, with: adaptive(0x1D5FAE, 0x4C8FD6))
        colors.override(\.borderAccentPrimary, with: Color(adaptive(0x1D5FAE, 0x4C8FD6)))
        uiColors.override(\.borderAccentPrimary, with: adaptive(0x1D5FAE, 0x4C8FD6))
        colors.override(\.borderFocused, with: Color(adaptive(0x1D5FAE, 0x4C8FD6)))
        uiColors.override(\.borderFocused, with: adaptive(0x1D5FAE, 0x4C8FD6))
        colors.override(\.borderInteractivePrimary, with: Color(adaptive(0xC9D4E0, 0x223650)))
        uiColors.override(\.borderInteractivePrimary, with: adaptive(0xC9D4E0, 0x223650))
        colors.override(\.borderInteractiveSecondary, with: Color(adaptive(0xC9D4E0, 0x223650)))
        uiColors.override(\.borderInteractiveSecondary, with: adaptive(0xC9D4E0, 0x223650))
        colors.override(\.separatorPrimary, with: Color(adaptive(0xC9D4E0, 0x223650)))
        uiColors.override(\.separatorPrimary, with: adaptive(0xC9D4E0, 0x223650))
        colors.override(\.separatorSecondary, with: Color(adaptive(0xC9D4E0, 0x223650)))
        uiColors.override(\.separatorSecondary, with: adaptive(0xC9D4E0, 0x223650))
        colors.override(\.textWarningPrimary, with: Color(adaptive(0xD97A00, 0xF08A00)))
        uiColors.override(\.textWarningPrimary, with: adaptive(0xD97A00, 0xF08A00))
        colors.override(\.iconWarningPrimary, with: Color(adaptive(0xD97A00, 0xF08A00)))
        uiColors.override(\.iconWarningPrimary, with: adaptive(0xD97A00, 0xF08A00))
        colors.override(\.textSuccessPrimary, with: Color(adaptive(0x22794B, 0x2F9E63)))
        uiColors.override(\.textSuccessPrimary, with: adaptive(0x22794B, 0x2F9E63))
        colors.override(\.iconSuccessPrimary, with: Color(adaptive(0x22794B, 0x2F9E63)))
        uiColors.override(\.iconSuccessPrimary, with: adaptive(0x22794B, 0x2F9E63))
        colors.override(\.borderSuccessPrimary, with: Color(adaptive(0x22794B, 0x2F9E63)))
        uiColors.override(\.borderSuccessPrimary, with: adaptive(0x22794B, 0x2F9E63))
        colors.override(\.bgSuccessRest, with: Color(adaptive(0x22794B, 0x2F9E63)))
        uiColors.override(\.bgSuccessRest, with: adaptive(0x22794B, 0x2F9E63))
        colors.override(\.textOnSolidPrimary, with: .white)
        uiColors.override(\.textOnSolidPrimary, with: .white)
        colors.override(\.iconOnSolidPrimary, with: .white)
        uiColors.override(\.iconOnSolidPrimary, with: .white)
    }
}
