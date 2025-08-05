//
//  WatchMusicTimeDisplay.swift
//  WatchDancingMarker Watch App
//
//  Created by Woowon Kang on 8/5/25.
//

import SwiftUI

struct WatchMusicTimeDisplay: View {
    let formattedTime: String
    
    var body: some View {
        HStack {
            Text(formattedTime)
                .font(.system(size: 10, weight: .light))
                .fixedSize()
        }
        .padding(.bottom, 10)
    }
}
