//
//  TipButtonView.swift
//  DancingMarker
//
//  Created by Woowon Kang on 8/1/25.
//

import SwiftUI

struct TipButtonView: View {
    @State private var isTipButtonPresented = false
    
    var body: some View {
        Button(action: {
            isTipButtonPresented = true
        }) {
            Image(systemName: "questionmark.circle")
                .foregroundStyle(.markerPurple)
                .padding([.top, .bottom, .leading], 10)
        }
        .fullScreenCover(isPresented: $isTipButtonPresented) {
            TipPopupView(isTipButtonPresented: $isTipButtonPresented)
                .presentationBackground(.black.opacity(0.6))
        }
        .transaction { $0.disablesAnimations = true }
    }
}
