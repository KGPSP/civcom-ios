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
        colors.override(\.bgCanvasDefault, with: Color(adaptive(0xF7F9FB, 0x121F33)))
        colors.override(\.bgSubtlePrimary, with: Color(adaptive(0xEDF1F6, 0x0E1928)))
        colors.override(\.textPrimary, with: Color(adaptive(0x14212F, 0xE8EEF5)))
        colors.override(\.textSecondary, with: Color(adaptive(0x5C6E82, 0x8CA0B8)))
        colors.override(\.bgActionPrimaryRest, with: Color(adaptive(0xC01F2A, 0xD22730)))
        colors.override(\.textActionAccent, with: Color(adaptive(0x1D5FAE, 0x4C8FD6)))
        colors.override(\.bgActionPrimaryPressed, with: Color(adaptive(0xC01F2A, 0xD22730)).opacity(0.85))
        colors.override(\.textOnSolidPrimary, with: .white)
        colors.override(\.iconOnSolidPrimary, with: .white)
        uiColors.override(\.bgCanvasDefault, with: adaptive(0xF7F9FB, 0x121F33))
        uiColors.override(\.bgSubtlePrimary, with: adaptive(0xEDF1F6, 0x0E1928))
        uiColors.override(\.textPrimary, with: adaptive(0x14212F, 0xE8EEF5))
        uiColors.override(\.textSecondary, with: adaptive(0x5C6E82, 0x8CA0B8))
        uiColors.override(\.bgActionPrimaryRest, with: adaptive(0xC01F2A, 0xD22730))
        uiColors.override(\.bgActionPrimaryPressed, with: adaptive(0xC01F2A, 0xD22730).withAlphaComponent(0.85))
        uiColors.override(\.textActionAccent, with: adaptive(0x1D5FAE, 0x4C8FD6))
        uiColors.override(\.textOnSolidPrimary, with: .white)
        uiColors.override(\.iconOnSolidPrimary, with: .white)
    }
}
