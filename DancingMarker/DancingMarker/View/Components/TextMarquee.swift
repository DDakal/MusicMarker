//
//  TextMarquee.swift
//  DancingMarker
//
//  Created by Woowon Kang on 2/5/25.
//

import SwiftUI

struct TextMarquee: View {
    let originalTitle: String
    
    // 폰트, 멈춤 시간
    var font: UIFont
    var delayTime: Double = 0.5        // ✅ 공백을 지난 후 멈추는 시간
    var speedPerSecond: CGFloat = 30.0 // ✅ 1초 동안 이동할 픽셀 수 (일정한 속도)
    
    // 내부 상태
    @State private var textWidth: CGFloat = 0    // 원본 텍스트의 너비 + 공백
    @State private var fullWidth: CGFloat = 0    // ✅ 공백 포함한 전체 길이
    @State private var offset: CGFloat = 0       // 현재 이동 상태
    @State private var isPaused: Bool = false    // ✅ 멈춤 상태 여부

    // 타이머 설정
    @State private var timer: Timer? = nil
    @State private var stepSize: CGFloat = 1.0   // 매 프레임 이동 픽셀 수 (speedPerSecond 기반 계산)

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                Text(originalTitle + "     " + originalTitle)
                    .font(.init(font))
                    .lineLimit(1)
                    .fixedSize()
                    .background(
                        GeometryReader { textGeo in
                            Color.clear.onAppear {
                                textWidth = measureTextWidth(originalTitle + "     ")
                                fullWidth = textGeo.size.width  // ✅ 공백 포함한 전체 길이 저장
                                setupMarquee()
                            }
                        }
                    )
            }
            .offset(x: offset)
            .clipped()
            .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)

        }
        .onAppear {
            startMarquee()
        }
        .onDisappear {
            stopMarquee()
        }
    }
}

// MARK: - Marquee Core Logic
extension TextMarquee {
    /// 마키 텍스트 초기화
    private func setupMarquee() {
        stepSize = speedPerSecond / 60.0  // 1/60초당 이동할 픽셀 수
        offset = 0  // ✅ 초기 위치를 첫 번째 텍스트의 시작점으로 설정
        isPaused = false
    }
    
    /// 마키 애니메이션 시작
    private func startMarquee() {
        stopMarquee() // 기존 타이머 중지
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            if !isPaused {
                updateMarquee()
            }
        }
    }
    
    /// 마키 애니메이션을 멈춤
    private func stopMarquee() {
        timer?.invalidate()
        timer = nil
    }
    
    /// 매 프레임마다 실행되는 함수 (offset을 이동)
    private func updateMarquee() {
        if offset <= -textWidth {
            // ✅ 부드럽게 공백을 지나가도록 유지
            offset += textWidth
            
            // ✅ 멈춤 타이머 시작 (공백이 지나간 후 멈추는 효과)
            isPaused = true
            DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
                isPaused = false
            }
        } else {
            // ✅ 일정 속도로 이동
            offset -= stepSize
        }
    }
    
    /// 특정 문자열의 너비 측정
    private func measureTextWidth(_ string: String) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font
        ]
        return (string as NSString).size(withAttributes: attributes).width
    }
}
