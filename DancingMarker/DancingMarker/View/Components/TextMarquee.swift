//
//  TextMarquee.swift
//  DancingMarker
//
//  Created by Woowon Kang on 2/5/25.
//

import SwiftUI

struct TextMarquee: View {
    @State var storedSize: CGSize = .zero
    @State var offset: CGFloat = 0
    @State var text: String
    var font: UIFont
    var animationSpeed: Double = 0.06  // 포인트당 걸리는 시간
    var delayTime: Double = 0.5        // 멈추는 시간 (초)
    
    @Environment(\.colorScheme) var scheme
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(text)
                .font(Font(font))
                .offset(x: offset)
        }
        .overlay(
            HStack {
                let color: Color = .nowPlayingGray
                
                LinearGradient(colors: [color, color.opacity(0.7), color.opacity(0.5), color.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                    .frame(width: 10)
                
                Spacer()
                
                LinearGradient(colors: [color, color.opacity(0.7), color.opacity(0.5), color.opacity(0.3)].reversed(), startPoint: .leading, endPoint: .trailing)
                    .frame(width: 10)
            }
        )
        .disabled(true)
        .onAppear {
            let baseText = text
            
            // 텍스트와 텍스트 사이의 공백 추가
            (1...15).forEach { _ in
                text.append(" ")
            }
            
            storedSize = textSize()
            text.append(baseText)
            
            // 약간의 초기 지연 후 애니메이션 시작
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                startMarqueeAnimation()
            }
        }
    }
    
    func startMarqueeAnimation() {
        // 텍스트가 스크롤되어야 할 거리 만큼의 애니메이션 시간 계산
        let timing = animationSpeed * storedSize.width
        
        // 텍스트를 왼쪽으로 애니메이션하여 스크롤 효과 적용
        withAnimation(.linear(duration: timing)) {
            offset = -storedSize.width
        }
        
        // 애니메이션이 끝난 후, delayTime 만큼 멈춘 후에
        DispatchQueue.main.asyncAfter(deadline: .now() + timing) {
            DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
                offset = 0
                startMarqueeAnimation()
            }
        }
    }
    
    func textSize() -> CGSize {
        let attributes = [NSAttributedString.Key.font: font]
        let size = (text as NSString).size(withAttributes: attributes)
        return size
    }
}
