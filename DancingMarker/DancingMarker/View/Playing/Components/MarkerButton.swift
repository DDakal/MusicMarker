//
//  MarkerButton.swift
//  DancingMarker
//
//  Created by Woowon Kang on 8/1/25.
//

import SwiftUI

struct MarkerButton: View {
    let time: TimeInterval
    let index: Int
    let formattedTime: String
    let onTap: (Int) async -> Void
    let onDelete: (Int) async -> Void
    
    var body: some View {
        Button(action: {
            Task {
                await onTap(index)
            }
        }) {
            HStack(spacing: 8) {
                Image("addedMarker")
                Text(formattedTime)
                    .font(.title3)
                    .italic()
                    .foregroundColor(.black)
            }
            .frame(width: 360, height: 60)
            .background(.accent)
            .cornerRadius(12)
        }
        .contextMenu {
            // 편집 버튼 제거, 삭제 버튼만 유지
            Button(role: .destructive, action: {
                Task {
                    await onDelete(index)
                }
            }) {
                Text("Local_MarkerReset")
                Image(systemName: "eraser")
            }
        }
    }
}
