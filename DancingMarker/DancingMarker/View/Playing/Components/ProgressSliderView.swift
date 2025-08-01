//
//  ProgressSliderView.swift
//  DancingMarker
//
//  Created by Woowon Kang on 8/1/25.
//

import SwiftUI

struct ProgressSliderView: View {
    @EnvironmentObject var playerViewModel: PlayerViewModel
    @State private var dragProgress: Double = 0.0
    @State private var isDragging: Bool = false
    
    var body: some View {
        VStack {
            // 슬라이더
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .foregroundStyle(.inactiveGray)
                    
                    Rectangle()
                        .foregroundStyle(.white)
                        .frame(width: geometry.size.width * CGFloat(isDragging ? dragProgress : playerViewModel.progress))
                }
                .cornerRadius(12)
                .contentShape(Rectangle().inset(by: -6))
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // 드래그 중: 로컬 상태만 업데이트 (즉시 반응)
                            isDragging = true
                            dragProgress = min(max(0, Double(value.location.x / geometry.size.width)), 1.0)
                            
                            // 시간 표시만 업데이트 (실제 seek는 안함)
                            let newTime = dragProgress * playerViewModel.duration
                            playerViewModel.updateSliderUI(newTime: newTime)
                        }
                        .onEnded { value in
                            // 손가락을 뗐을 때만 실제 seek 연산
                            let newProgress = min(max(0, Double(value.location.x / geometry.size.width)), 1.0)
                            let newTime = newProgress * playerViewModel.duration
                            
                            Task {
                                do {
                                    try await playerViewModel.seek(to: newTime)
                                    isDragging = false
                                    playerViewModel.setDragging(false)
                                } catch {
                                    print("시간 이동 중 오류: \(error)")
                                    isDragging = false
                                    playerViewModel.setDragging(false)
                                }
                            }
                        }
                )
            }
            .frame(height: 8)
            .padding(.bottom, 3)
            
            // 시간 표시
            HStack {
                Text(playerViewModel.formattedProgress)
                Spacer()
                Text(playerViewModel.formattedDuration)
            }
        }
    }
}
