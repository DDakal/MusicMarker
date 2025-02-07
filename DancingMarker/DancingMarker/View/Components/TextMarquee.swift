//
//  TextMarquee.swift
//  DancingMarker
//
//  Created by Woowon Kang on 2/5/25.
//

import SwiftUI

struct TextMarquee: View {
    let originalTitle: String

    // 폰트, 애니메이션 설정
    var font: UIFont
    var delayTime: Double = 1.2        // ✅ 공백을 지난 후 멈추는 시간
    var speedPerSecond: CGFloat = 30.0 // ✅ 1초 동안 이동할 픽셀 수 (일정한 속도)
    
    private let spaceCount = 7
    private var spacedTitle: String {
        originalTitle + String(repeating: " ", count: spaceCount)
    }

    // 내부 상태
    @State private var textWidth: CGFloat = 0    // 원본 텍스트의 너비 + 공백
    @State private var fullWidth: CGFloat = 0    // ✅ 공백 포함한 전체 길이
    @State private var offset: CGFloat = 0       // 현재 이동 상태
    @State private var isPaused: Bool = false    // ✅ 멈춤 상태 여부
    @State private var shouldAnimate: Bool = true // ✅ 애니메이션 여부

    // 타이머 설정
    @State private var timer: Timer? = nil
    @State private var stepSize: CGFloat = 0.5   // 매 프레임 이동 픽셀 수 (speedPerSecond 기반 계산)

    var body: some View {
        GeometryReader { geo in
            if shouldAnimate {
                HStack(spacing: 0) {
                    Text(spacedTitle + originalTitle) // ✅ 공백 포함된 문자열 사용
                        .font(.init(font))
                        .lineLimit(1)
                        .fixedSize()
                        .background(
                            GeometryReader { textGeo in
                                Color.clear.onAppear {
                                    textWidth = measureTextWidth(spacedTitle) // ✅ 동일한 공백 포함
                                    fullWidth = textGeo.size.width
                                    checkIfShouldAnimate(containerWidth: geo.size.width)
                                }
                            }
                        )
                }
                .offset(x: offset)
                .clipped()
                .onAppear { startMarquee() }
                .onDisappear { stopMarquee() }
            } else {
                // ✅ 짧은 텍스트일 경우 정지 상태로 표시
                Text(originalTitle)
                    .font(.init(font))
                    .lineLimit(1)
                    .onAppear {
                        checkIfShouldAnimate(containerWidth: geo.size.width)
                    }
            }
        }
        .onChange(of: originalTitle) { _ in restartMarquee() }
        .frame(height: 20)
    }
}

// MARK: - Marquee Logic
extension TextMarquee {
    /// 📌 **텍스트가 화면보다 작으면 애니메이션 비활성화**
    private func checkIfShouldAnimate(containerWidth: CGFloat) {
        let threshold = containerWidth * 0.85 // ✅ 컨테이너 크기의 85%보다 작으면 정적 표시
        shouldAnimate = textWidth > threshold

        if shouldAnimate {
            stepSize = speedPerSecond / 60.0
            startMarquee()
        } else {
            offset = 0
            stopMarquee()
        }
    }

    /// ✅ **제목이 바뀔 때 애니메이션 리셋 후 다시 시작**
    private func restartMarquee() {
        stopMarquee()
        offset = 0
        shouldAnimate = true // ✅ 항상 다시 체크하게 설정
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            checkIfShouldAnimate(containerWidth: UIScreen.main.bounds.width)
        }
    }

    /// 마키 애니메이션 시작
    private func startMarquee() {
        if !shouldAnimate { return }
        
        stopMarquee()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            if !isPaused {
                updateMarquee()
            }
        }
    }

    /// 마키 애니메이션 정지
    private func stopMarquee() {
        timer?.invalidate()
        timer = nil
        isPaused = false
    }

    /// 매 프레임마다 실행되는 애니메이션 업데이트
    private func updateMarquee() {
        if offset <= -textWidth {
            offset += textWidth
            
            isPaused = true
            DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
                isPaused = false
            }
        } else {
            offset -= stepSize
        }
    }

    /// 📌 **텍스트 길이 측정 함수**
    private func measureTextWidth(_ text: String) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font
        ]
        return (text as NSString).size(withAttributes: attributes).width
    }
}
