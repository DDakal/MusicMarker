//
//  MarkerTimeControl.swift
//  WatchDancingMarker Watch App
//
//  Created by Woowon Kang on 8/6/25.
//

import SwiftUI

struct MarkerTimeControl: View {
    @Binding var data: TimeInterval
    let maxDuration: TimeInterval
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let formattedTime: String
    
    var body: some View {
        HStack {
            // MARK: 1초 감소 버튼
            DecrementButton(
                isEnabled: data >= 1,
                onTap: onDecrement
            )
            
            Spacer()
            
            // MARK: 현재 마커 시간
            MarkerTimeDisplay(formattedTime: formattedTime)
            
            Spacer()
            
            // MARK: 1초 증가 버튼
            IncrementButton(
                isEnabled: data < maxDuration - 1,
                onTap: onIncrement
            )
        }
        .padding(.horizontal)
    }
}

// MARK: - Sub Components

struct DecrementButton: View {
    let isEnabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.gray.opacity(0.2))
                .frame(width: 40, height: 40)
            
            Image("backward1SecIcon")
                .colorMultiply(isEnabled ? .white : .inactiveGray)
        }
        .onTapGesture {
            if isEnabled {
                onTap()
            }
        }
    }
}

struct IncrementButton: View {
    let isEnabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.gray.opacity(0.2))
                .frame(width: 40, height: 40)
            
            Image("forward1SecIcon")
                .colorMultiply(isEnabled ? .white : .inactiveGray)
        }
        .onTapGesture {
            if isEnabled {
                onTap()
            }
        }
    }
}

struct MarkerTimeDisplay: View {
    let formattedTime: String
    
    var body: some View {
        Text(formattedTime)
            .font(.system(size: 22, weight: .regular))
            .fixedSize()
    }
}
