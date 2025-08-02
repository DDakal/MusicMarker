//
//  MarkerListView.swift
//  DancingMarker
//
//  Created by Woowon Kang on 8/1/25.
//

import SwiftUI

struct MarkerListView: View {
    @EnvironmentObject var playerViewModel: PlayerViewModel
    
    var body: some View {
        VStack {
            HStack {
                Text("Local_MarkerList")
                    .font(.headline)
                Spacer()
                
                TipButtonView()
            }
            
            VStack(spacing: 16) {
                if let music = playerViewModel.currentMusic {
                    ForEach(0..<3, id: \.self) { index in
                        if music.markers[index] != -1 {
                            if playerViewModel.isEditingMarker && playerViewModel.editingMarkerIndex == index {
                                // 편집 모드
                                EditMarkerButton(
                                    index: index,
                                    formattedTime: formattedEditingTime(index: index),
                                    canDecrease: playerViewModel.canDecreaseEditingMarker,
                                    canIncrease: playerViewModel.canIncreaseEditingMarker,
                                    onDecrease: { playerViewModel.decreaseEditingMarkerTime() },
                                    onIncrease: { playerViewModel.increaseEditingMarkerTime() },
                                    onSave: { await playerViewModel.saveEditingMarker() }
                                )
                            } else {
                                // 일반 모드
                                MarkerButton(
                                    time: music.markers[index],
                                    index: index,
                                    formattedTime: playerViewModel.formattedTime(music.markers[index]),
                                    onTap: { index in await playerViewModel.moveToMarker(at: index) },
                                    onEdit: { index in playerViewModel.startMarkerEditing(at: index) },
                                    onDelete: { index in await playerViewModel.deleteMarker(at: index) }
                                )
                            }
                        } else {
                            AddMarkerButton(index: index) { index in
                                await playerViewModel.addMarkerAtCurrentTime(at: index)
                            }
                        }
                    }
                } else {
                    Text("No music loaded")
                }
            }
            .padding(.bottom, 8)
        }
    }
    
    /// 편집 중인 마커의 포맷된 시간을 반환합니다
    private func formattedEditingTime(index: Int) -> String {
        if let currentEditingTime = playerViewModel.currentEditingTime,
           playerViewModel.isEditingMarker && playerViewModel.editingMarkerIndex == index {
            return playerViewModel.formattedTime(currentEditingTime)
        }
        return playerViewModel.formattedTime(playerViewModel.markers[index])
    }
}
