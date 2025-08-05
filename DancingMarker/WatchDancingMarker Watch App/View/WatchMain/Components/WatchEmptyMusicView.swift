//
//  WatchEmptyMusicView.swift
//  WatchDancingMarker Watch App
//
//  Created by Woowon Kang on 8/5/25.
//

import SwiftUI

struct WatchEmptyMusicView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Local_Watch_FirstAtMobileMessage")
                .font(.system(size: 16, weight: .regular))
                .fixedSize()
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

#Preview {
    WatchEmptyMusicView()
}
