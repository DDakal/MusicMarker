//
//  AddMarkerButton.swift
//  DancingMarker
//
//  Created by Woowon Kang on 8/1/25.
//

import SwiftUI

struct AddMarkerButton: View {
    let index: Int
    let onTap: (Int) async -> Void
    
    var body: some View {
        Button(action: {
            Task {
                await onTap(index)
            }
        }) {
            HStack(spacing: 8) {
                Image("emptyMarker")
                Text("Local_MarkerAdd")
                    .font(.title3)
                    .foregroundColor(.white)
            }
            .frame(width: 360, height: 60)
            .background(.buttonDarkGray)
            .cornerRadius(12)
        }
    }
}
