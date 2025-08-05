//
//  WatchPlayingIndicator.swift
//  WatchDancingMarker Watch App
//
//  Created by Woowon Kang on 8/5/25.
//

import SwiftUI

struct WatchPlayingIndicator: View {
    let isPlaying: Bool
    let onTap: () -> Void
    
    @State private var drawingHeight = true
    @State private var animationTimer: Timer?
    
    var body: some View {
        Button(action: onTap) {
            if isPlaying {
                HStack(spacing: 1.6) {
                    animatedBar(low: 0.4, speed: 1.5)
                    animatedBar(low: 0.3, speed: 1.2)
                    animatedBar(low: 0.5, speed: 1.0)
                    animatedBar(low: 0.3, speed: 1.7)
                    animatedBar(low: 0.3, speed: 1.3)
                }
                .frame(width: 20)
                .onAppear { startAnimation() }
                .onDisappear { stopAnimation() }
            } else {
                HStack(spacing: 1.6) {
                    ForEach(0..<5, id: \.self) { _ in
                        staticBar()
                    }
                }
                .frame(width: 20)
            }
        }
        .frame(width: 32, height: 32)
        .onChange(of: isPlaying) { _, newValue in
            newValue ? startAnimation() : stopAnimation()
        }
    }
    
    // MARK: - Private Views
    
    private func animatedBar(low: CGFloat, speed: Double) -> some View {
        RoundedRectangle(cornerRadius: 1.2)
            .fill(.accent)
            .frame(height: (drawingHeight ? 1.0 : low) * 18)
            .frame(width: 1.6, height: 18, alignment: .center)
            .animation(.linear(duration: 0.5).repeatForever().speed(speed), value: drawingHeight)
    }
    
    private func staticBar() -> some View {
        RoundedRectangle(cornerRadius: 1.2)
            .fill(.accent)
            .frame(width: 1.6, height: 2.5, alignment: .center)
    }
    
    // MARK: - Animation Control
    
    private func startAnimation() {
        animationTimer?.invalidate()
        drawingHeight.toggle()
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            DispatchQueue.main.async {
                self.drawingHeight.toggle()
            }
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        drawingHeight = false
    }
}
