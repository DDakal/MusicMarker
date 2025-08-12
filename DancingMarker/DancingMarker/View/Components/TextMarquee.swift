//
//  TextMarquee.swift
//  DancingMarker
//
//  Created by Woowon Kang on 2/5/25.
//

import SwiftUI

struct TextMarquee: View {
    let title: String
    let artist: String
    let titleFont: UIFont
    let artistFont: UIFont
    var delayTime: Double = 1.2
    var speedPerSecond: CGFloat = 30.0
    
    // MARK: - Private Properties
    private let spaceCount = 7
    private var spacedTitle: String { title + String(repeating: " ", count: spaceCount) }
    private var spacedArtist: String { artist + String(repeating: " ", count: spaceCount) }
    
    // MARK: - State Variables
    @State private var titleOffset: CGFloat = 0
    @State private var artistOffset: CGFloat = 0
    @State private var titleContentWidth: CGFloat = 0
    @State private var artistContentWidth: CGFloat = 0
    @State private var shouldAnimateTitle: Bool = false
    @State private var shouldAnimateArtist: Bool = false
    @State private var isTitlePaused: Bool = false
    @State private var isArtistPaused: Bool = false
    
    // Animation control
    @State private var titleTimer: Timer? = nil
    @State private var artistTimer: Timer? = nil
    @State private var titleStepSize: CGFloat = 0.5
    @State private var artistStepSize: CGFloat = 0.5
    
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 6) {
                Spacer().frame(height: 6)
                // Title marquee
                if shouldAnimateTitle {
                    HStack(spacing: 0) {
                        Text(spacedTitle + title)
                            .font(.init(titleFont))
                            .lineLimit(1)
                            .fixedSize()
                            .background(
                                GeometryReader { textGeo in
                                    Color.clear.onAppear {
                                        titleContentWidth = measureTextWidth(title, font: titleFont)
                                    }
                                }
                            )
                    }
                    .offset(x: titleOffset)
                    .clipped()
                    .onAppear { startMarqueeTitle() }
                    .onDisappear { stopMarqueeTitle() }
                    .padding(.bottom, 6)
                } else {
                    Text(title)
                        .font(.init(titleFont))
                        .lineLimit(1)
                        .padding(.bottom, 6)
                }
                
                // Artist marquee
                if shouldAnimateArtist {
                    HStack(spacing: 0) {
                        Text(spacedArtist + artist)
                            .font(.init(artistFont))
                            .lineLimit(1)
                            .fixedSize()
                            .background(
                                GeometryReader { textGeo in
                                    Color.clear.onAppear {
                                        artistContentWidth = measureTextWidth(artist, font: artistFont)
                                    }
                                }
                            )
                    }
                    .offset(x: artistOffset)
                    .clipped()
                    .onAppear { startMarqueeArtist() }
                    .onDisappear { stopMarqueeArtist() }
                    .padding(.bottom, 6)
                } else {
                    Text(artist)
                        .font(.init(artistFont))
                        .lineLimit(1)
                        .padding(.bottom, 6)
                }
            }
            .onAppear {
                // 화면 너비에 맞게 텍스트 길이 체크
                checkIfShouldAnimate(geo.size.width)
            }
            .onChange(of: title) { resetAndCheckAnimation(geo.size.width) }
            .onChange(of: artist) { resetAndCheckAnimation(geo.size.width) }
        }
    }
}

// MARK: - Marquee Logic
extension TextMarquee {
    private func checkIfShouldAnimate(_ availableWidth: CGFloat) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 텍스트 길이 측정
            titleContentWidth = measureTextWidth(title, font: titleFont)
            artistContentWidth = measureTextWidth(artist, font: artistFont)
            
            // 애니메이션이 필요한지 체크 (약간의 여유를 두고)
            let threshold = availableWidth - 6
            shouldAnimateTitle = titleContentWidth > threshold
            shouldAnimateArtist = artistContentWidth > threshold
            
            // 스텝 크기 설정
            titleStepSize = speedPerSecond / 60.0
            artistStepSize = speedPerSecond / 60.0
            
            // 필요한 경우에만 애니메이션 시작
            if shouldAnimateTitle {
                startMarqueeTitle()
            }
            
            if shouldAnimateArtist {
                startMarqueeArtist()
            }
        }
    }
    
    private func resetAndCheckAnimation(_ availableWidth: CGFloat) {
        // 애니메이션 멈추고 오프셋 초기화
        stopMarqueeTitle()
        stopMarqueeArtist()
        titleOffset = 0
        artistOffset = 0
        
        // 다시 체크
        checkIfShouldAnimate(availableWidth)
    }
    
    private func startMarqueeTitle() {
        guard shouldAnimateTitle else { return }
        stopMarqueeTitle()
        
        titleTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            if !isTitlePaused {
                updateMarqueeTitle()
            }
        }
    }
    
    private func startMarqueeArtist() {
        guard shouldAnimateArtist else { return }
        stopMarqueeArtist()
        
        artistTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            if !isArtistPaused {
                updateMarqueeArtist()
            }
        }
    }
    
    private func stopMarqueeTitle() {
        titleTimer?.invalidate()
        titleTimer = nil
        isTitlePaused = false
    }
    
    private func stopMarqueeArtist() {
        artistTimer?.invalidate()
        artistTimer = nil
        isArtistPaused = false
    }
    
    private func updateMarqueeTitle() {
        let spacerWidth = measureTextWidth(String(repeating: " ", count: spaceCount), font: titleFont)
        
        if titleOffset <= -titleContentWidth - spacerWidth {
            titleOffset = 0
            isTitlePaused = true
            checkAndResumeMarquees()
        } else {
            titleOffset -= titleStepSize
        }
    }
    
    private func updateMarqueeArtist() {
        let spacerWidth = measureTextWidth(String(repeating: " ", count: spaceCount), font: artistFont)
        
        if artistOffset <= -artistContentWidth - spacerWidth {
            artistOffset = 0
            isArtistPaused = true
            checkAndResumeMarquees()
        } else {
            artistOffset -= artistStepSize
        }
    }
    
    private func measureTextWidth(_ text: String, font: UIFont) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        return (text as NSString).size(withAttributes: attributes).width
    }
    
    private func checkAndResumeMarquees() {
        if isTitlePaused && isArtistPaused {
            DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
                isTitlePaused = false
                isArtistPaused = false
            }
        } else if isTitlePaused && !shouldAnimateArtist {
            // 아티스트가 애니메이션이 필요없는 경우, 타이틀만 지연 후 재개
            DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
                isTitlePaused = false
            }
        } else if isArtistPaused && !shouldAnimateTitle {
            // 타이틀이 애니메이션이 필요없는 경우, 아티스트만 지연 후 재개
            DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
                isArtistPaused = false
            }
        }
    }
}
