//
//  MarkerSaveButton.swift
//  WatchDancingMarker Watch App
//
//  Created by Woowon Kang on 8/6/25.
//

import SwiftUI

struct MarkerSaveButton: View {
    let currentTime: TimeInterval
    let initialTime: TimeInterval
    let index: Int
    let onSave: (Int) -> Void
    
    private var hasChanged: Bool {
        currentTime != initialTime
    }
    
    var body: some View {
        HStack {
            Button(action: {
                let finalTime = Int(currentTime)
                onSave(finalTime)
            }) {
                Text("Local_Done")
                    .font(.system(size: 17, weight: .regular))
                    .fixedSize()
                    .foregroundColor(hasChanged ? .white : .inactiveGray)
            }
            .buttonStyle(
                CommonButtonStyle(
                    backgroundColor: .gray.opacity(0.2),
                    foregroundColor: .white
                )
            )
            .disabled(!hasChanged)
        }
    }
}
