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
                            // 일반 모드만 유지
                            MarkerButton(
                                time: music.markers[index],
                                index: index,
                                formattedTime: playerViewModel.formattedTime(music.markers[index]),
                                onTap: { index in await playerViewModel.moveToMarker(at: index) },
                                onDelete: { index in await playerViewModel.deleteMarker(at: index) }
                            )
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
    
    // formattedEditingTime 함수 제거 (편집 기능 없으므로)
}
