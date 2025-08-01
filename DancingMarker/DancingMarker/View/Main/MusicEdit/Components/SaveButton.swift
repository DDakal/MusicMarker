//
//  SaveButton.swift
//  DancingMarker
//
//  Created by Woowon Kang on 8/1/25.
//

import SwiftUI

struct SaveButton: View {
    let canSave: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text("Local_Done")
                    .fontWeight(.bold)
                Spacer()
            }
            .frame(height: 49)
            .frame(maxWidth: .infinity)
            .background(canSave ? Color.accentColor : Color.gray.opacity(0.3))
            .foregroundColor(canSave ? Color.black : Color.white)
            .cornerRadius(12)
            .padding(.bottom, 53)
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
    }
}
