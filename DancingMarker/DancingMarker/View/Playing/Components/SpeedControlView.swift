//
//  SpeedControlView.swift
//  DancingMarker
//
//  Created by Woowon Kang on 8/1/25.
//

import SwiftUI

struct SpeedControlView: View {
    let currentRate: Float
    let onDecrease: () async -> Void
    let onReset: () async -> Void
    let onIncrease: () async -> Void
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .frame(width: 360, height: 50)
            .foregroundStyle(.buttonDarkGray)
            .overlay(
                HStack(spacing: 10) {
                    // 감소 버튼
                    Button(action: {
                        Task { await onDecrease() }
                    }) {
                        Image(systemName: "minus")
                            .frame(width: 30, height: 30)
                            .foregroundStyle(currentRate <= 0.5 ? .inactiveGray : .white)
                    }
                    .padding(10)
                    .disabled(currentRate <= 0.5)
                    
                    Spacer()
                    
                    // 현재 배속 표시 & 리셋
                    Button(action: {
                        Task { await onReset() }
                    }) {
                        Text(String(format: "x%.1f", currentRate))
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                    
                    // 증가 버튼
                    Button(action: {
                        Task { await onIncrease() }
                    }) {
                        Image(systemName: "plus")
                            .frame(width: 30, height: 30)
                            .foregroundStyle(currentRate >= 1.5 ? .inactiveGray : .white)
                    }
                    .padding(10)
                    .disabled(currentRate >= 1.5)
                }
                .padding(.horizontal, 20)
            )
    }
}
