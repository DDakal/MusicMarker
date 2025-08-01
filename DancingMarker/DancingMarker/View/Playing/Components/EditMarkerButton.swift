//
//  EditMarkerButton.swift
//  DancingMarker
//
//  Created by Woowon Kang on 8/1/25.
//

import SwiftUI

struct EditMarkerButton: View {
    let index: Int
    let formattedTime: String
    let canDecrease: Bool
    let canIncrease: Bool
    let onDecrease: () -> Void
    let onIncrease: () -> Void
    let onSave: () async -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            // 뒤로 버튼
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    onDecrease()
                }
            }) {
                Circle()
                    .fill(canDecrease ? Color.gray.opacity(0.6) : Color.gray.opacity(0.9))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image("backward1SecIcon")
                            .opacity(canDecrease ? 1.0 : 0.3)
                    }
            }
            .disabled(!canDecrease)
            .scaleEffect(canDecrease ? 1.0 : 0.9)
            
            // 시간 표시
            HStack(spacing: 8) {
                Text(formattedTime)
                    .font(.title3)
                    .italic()
                    .foregroundColor(.black)
            }
            .frame(width: 200, height: 60)
            .background(Color.yellow)  // .accent 대신
            .cornerRadius(12)
            .padding(.horizontal, 6)
            
            // 앞으로 버튼
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    onIncrease()
                }
            }) {
                Circle()
                    .fill(canIncrease ? Color.gray.opacity(0.6) : Color.gray.opacity(0.9))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image("forward1SecIcon")
                            .opacity(canIncrease ? 1.0 : 0.3)
                    }
            }
            .disabled(!canIncrease)
            .scaleEffect(canIncrease ? 1.0 : 0.9)
            
            // 저장 버튼
            Button(action: {
                Task {
                    print("마커 편집 저장 버튼 클릭")
                    await onSave()
                }
            }) {
                Circle()
                    .fill(Color.gray.opacity(0.9))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "checkmark")
                            .foregroundColor(Color.green)
                    }
            }
            .padding(.leading, 10)
        }
    }
}
