//
//  WatchMusicInfoHeader.swift
//  WatchDancingMarker Watch App
//
//  Created by Woowon Kang on 8/5/25.
//

import SwiftUI

struct WatchMusicInfoHeader: View {
    let musicTitle: String
    
    var body: some View {
        HStack {
            Text(musicTitle)
                .font(.system(size: 12, weight: .regular))
                .fixedSize()
        }
    }
}
