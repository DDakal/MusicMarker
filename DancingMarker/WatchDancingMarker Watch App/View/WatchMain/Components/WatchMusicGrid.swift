//
//  WatchMusicGrid.swift
//  WatchDancingMarker Watch App
//
//  Created by Woowon Kang on 8/5/25.
//

import SwiftUI

struct WatchMusicGrid: View {
    let musicList: [[String]]
    let onMusicTap: (String) -> Void
    
    private let columns = [GridItem(.flexible())]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(musicList.indices, id: \.self) { index in
                    if musicList[index][0] != "" {
                        WatchMusicGridItem(
                            title: musicList[index][0],
                            onTap: {
                                onMusicTap(musicList[index][1])
                            }
                        )
                    }
                }
            }
        }
    }
}

struct WatchMusicGridItem: View {
    let title: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 17, weight: .regular))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .buttonBorderShape(.roundedRectangle)
        .frame(height: 40)
        .padding(.bottom, 5)
    }
}
