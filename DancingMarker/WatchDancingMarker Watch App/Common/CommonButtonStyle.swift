//
//  CommonButtonStyle.swift
//  WatchDancingMarker Watch App
//
//  Created by 이상도 on 2/5/25.
//

import SwiftUI

struct CommonButtonStyle: ButtonStyle {
    
    let backgroundColor: Color
    let foregroundColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .cornerRadius(9)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
