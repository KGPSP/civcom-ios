//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// The unchanged transmitter mark with its protective clear space.
struct AuthenticationStartLogo: View {
    var size: CGFloat?
    let hideBrandChrome: Bool
    let isOnGradient: Bool
    
    var body: some View {
        Image(asset: Asset.Images.appLogo)
            .resizable()
            .scaledToFit()
            .frame(width: size ?? 112, height: size ?? 112)
            .padding((size ?? 112) / 4)
            .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 0) {
        HStack(spacing: 0) {
            AuthenticationStartLogo(hideBrandChrome: false, isOnGradient: false)
                .padding()
            AuthenticationStartLogo(hideBrandChrome: false, isOnGradient: true)
                .padding()
                .background {
                    AuthenticationStartScreenBackgroundImage().offset(y: 70)
                }
                .clipped()
        }
        .background(.compound.bgCanvasDefault)
        
        HStack(spacing: 0) {
            AuthenticationStartLogo(hideBrandChrome: false, isOnGradient: false)
                .padding()
            AuthenticationStartLogo(hideBrandChrome: false, isOnGradient: true)
                .padding()
                .background {
                    AuthenticationStartScreenBackgroundImage().offset(y: 70)
                }
                .clipped()
        }
        .background(.compound.bgCanvasDefault)
        .colorScheme(.dark)
        
        HStack(spacing: 0) {
            AuthenticationStartLogo(size: 54, hideBrandChrome: false, isOnGradient: false)
                .padding()
                .background(.compound.bgCanvasDefault)
            AuthenticationStartLogo(size: 54, hideBrandChrome: false, isOnGradient: false)
                .padding()
                .background(.compound.bgCanvasDefault)
                .colorScheme(.dark)
        }
        .padding(.top)
    }
}
