//
//  TextMarquee.swift
//  DancingMarker
//
//  Created by Woowon Kang on 2/5/25.
//

import SwiftUI

enum MarqueeType {
    case title
    case artist
}

struct TextMarquee: View {
    let title: String
    let artist: String
    let titleFont: UIFont
    let artistFont: UIFont
    var delayTime: Double = 1.2
    var speedPerSecond: CGFloat = 30.0

    private let spaceCount = 7
    private var spacedTitle: String { title + String(repeating: " ", count: spaceCount) }
    private var spacedArtist: String { artist + String(repeating: " ", count: spaceCount) }

    @State private var titleOffset: CGFloat = 0
    @State private var artistOffset: CGFloat = 0
    @State private var titleWidth: CGFloat = 0
    @State private var artistWidth: CGFloat = 0
    @State private var titleFullWidth: CGFloat = 0
    @State private var artistFullWidth: CGFloat = 0
    @State private var shouldAnimateTitle: Bool = true
    @State private var shouldAnimateArtist: Bool = true

    @State private var titleTimer: Timer? = nil
    @State private var artistTimer: Timer? = nil
    @State private var titleStepSize: CGFloat = 0.5
    @State private var artistStepSize: CGFloat = 0.5

    @State private var isTitlePaused: Bool = false
    @State private var isArtistPaused: Bool = false

    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading) {
                Spacer()
                if shouldAnimateTitle {
                    HStack(spacing: 0) {
                        Text(spacedTitle + title)
                            .font(.init(titleFont))
                            .lineLimit(1)
                            .fixedSize()
                            .background(
                                GeometryReader { titleGeo in
                                    Color.clear.onAppear {
                                        titleWidth = measureTextWidth(spacedTitle, font: titleFont)
                                        titleFullWidth = titleGeo.size.width // ✅ 실제 렌더링된 텍스트 너비
                                        checkIfShouldAnimate(
                                            for: .title,
                                            fullWidth: titleFullWidth,
                                            offset: &titleOffset,
                                            shouldAnimate: &shouldAnimateTitle,
                                            start: { startMarqueeTitle() },
                                            stop: { stopMarqueeTitle() }
                                        )
                                    }
                                }
                            )
                    }
                    .offset(x: titleOffset)
                    .clipped()
                    .onAppear { startMarqueeTitle() }
                    .onDisappear { stopMarqueeTitle() }
                    .padding(.bottom, 6)
                    //.border(Color.green, width: 1)
                } else {
                    Text(title)
                        .font(.init(titleFont))
                        .lineLimit(1)
                        .onAppear {
                            checkIfShouldAnimate(
                                for: .title,
                                fullWidth: titleFullWidth,
                                offset: &titleOffset,
                                shouldAnimate: &shouldAnimateTitle,
                                start: { startMarqueeTitle() },
                                stop: { stopMarqueeTitle() }
                            )
                        }
                        .padding(.bottom, 6)
                }

                if shouldAnimateArtist {
                    HStack(spacing: 0) {
                        Text(spacedArtist + artist)
                            .font(.init(artistFont))
                            .lineLimit(1)
                            .fixedSize()
                            .background(
                                GeometryReader { artistGeo in
                                    Color.clear.onAppear {
                                        artistWidth = measureTextWidth(spacedArtist, font: artistFont)
                                        artistFullWidth = artistGeo.size.width // ✅ 실제 렌더링된 텍스트 너비
                                        
                                        checkIfShouldAnimate(
                                            for: .artist,
                                            fullWidth: artistFullWidth,
                                            offset: &artistOffset,
                                            shouldAnimate: &shouldAnimateArtist,
                                            start: { startMarqueeArtist() },
                                            stop: { stopMarqueeArtist() }
                                        )
                                    }
                                }
                            )
                    }
                    .offset(x: artistOffset)
                    .clipped()
                    .onAppear { startMarqueeArtist() }
                    .onDisappear { stopMarqueeArtist() }
                    .padding(.bottom, 6)
                    //.border(Color.blue, width: 1)
                } else {
                    Text(artist)
                        .font(.init(artistFont))
                        .lineLimit(1)
                        .onAppear {
                            checkIfShouldAnimate(
                                for: .artist,
                                fullWidth: artistFullWidth,
                                offset: &artistOffset,
                                shouldAnimate: &shouldAnimateArtist,
                                start: { startMarqueeArtist() },
                                stop: { stopMarqueeArtist() }
                            )
                        }
                        .padding(.bottom, 6)
                }
                Spacer()
            }
            .onChange(of: title) { _ in restartMarqueeTitle() }
            .onChange(of: artist) { _ in restartMarqueeArtist() }
        }
        
    }
}

// MARK: - Marquee Logic
extension TextMarquee {
    private func checkIfShouldAnimate(for type: MarqueeType, fullWidth: CGFloat, offset: inout CGFloat, shouldAnimate: inout Bool, start: () -> Void, stop: () -> Void) {
        let fixedWidth: CGFloat = UIScreen.main.bounds.width * 0.85
        shouldAnimate = fullWidth > fixedWidth
        if shouldAnimate {
            titleStepSize = speedPerSecond / 60.0
            start()
        } else {
            offset = 0
            stop()
        }
    }

    private func restartMarqueeTitle() {
        stopMarqueeTitle()
        titleOffset = 0
        shouldAnimateTitle = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            checkIfShouldAnimate(
                for: .title,
                fullWidth: titleFullWidth,
                offset: &titleOffset,
                shouldAnimate: &shouldAnimateTitle,
                start: { startMarqueeTitle() },
                stop: { stopMarqueeTitle() }
            )
        }
    }

    private func restartMarqueeArtist() {
        stopMarqueeArtist()
        artistOffset = 0
        shouldAnimateArtist = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            
            checkIfShouldAnimate(
                for: .artist,
                fullWidth: artistFullWidth,
                offset: &artistOffset,
                shouldAnimate: &shouldAnimateArtist,
                start: { startMarqueeArtist() },
                stop: { stopMarqueeArtist() }
            )
        }
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
        if titleOffset <= -titleWidth {
            titleOffset += titleWidth
            isTitlePaused = true
            checkAndResumeMarquees() // 두 텍스트 모두 멈췄는지 확인
        } else {
            titleOffset -= titleStepSize
        }
    }

    private func updateMarqueeArtist() {
        if artistOffset <= -artistWidth {
            artistOffset += artistWidth
            isArtistPaused = true
            checkAndResumeMarquees() // 두 텍스트 모두 멈췄는지 확인
        } else {
            artistOffset -= artistStepSize
        }
    }

    private func measureTextWidth(_ text: String, font: UIFont) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font
        ]
        return (text as NSString).size(withAttributes: attributes).width
    }
    
    private func checkAndResumeMarquees() {
        if isTitlePaused && isArtistPaused {
            DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
                isTitlePaused = false
                isArtistPaused = false
            }
        }
    }
}
