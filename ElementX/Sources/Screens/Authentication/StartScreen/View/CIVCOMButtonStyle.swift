// Copyright 2026 KG PSP.
// SPDX-License-Identifier: AGPL-3.0-only

import Compound
import SwiftUI

struct CIVCOMButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary }
    let kind: Kind
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body).weight(.semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(kind == .primary ? Color.white : Color.compound.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(fill(configuration.isPressed), in: RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(kind == .secondary ? Color.compound.borderInteractiveSecondary : .clear, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 4))
            .opacity(isEnabled ? 1 : 0.5)
    }
    
    private func fill(_ pressed: Bool) -> Color {
        switch kind {
        case .primary: pressed ? .compound.bgActionPrimaryPressed : .compound.bgActionPrimaryRest
        case .secondary: pressed ? .compound.bgSubtleSecondary : .clear
        }
    }
}

extension Font {
    static func civcomHeading(size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        if UIFont(name: "AvenirNextCondensed-Bold", size: size) != nil {
            .custom("AvenirNextCondensed-Bold", size: size, relativeTo: style)
        } else {
            .system(style).weight(.bold)
        }
    }
}
