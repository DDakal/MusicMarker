//
//  View+LiquidGlass.swift
//  DancingMarker
//
//  Created by Woowon Kang on 8/9/25.
//

import SwiftUI

// MARK: - Apply Extension for Clean Branching

extension View {
    /// 조건부 뷰 수정을 위한 apply 함수
    func apply<V: View>(@ViewBuilder _ block: (Self) -> V) -> V {
        block(self)
    }
}

// MARK: - Liquid Glass Modifiers

extension View {
    /// iOS 26/watchOS 26의 Glass Effect를 조건부로 적용
    @ViewBuilder
    func liquidGlassEffect() -> some View {
        self.apply {
            if #available(iOS 26.0, watchOS 26.0, *) {
                $0.glassEffect()
            } else {
                $0.background(.thinMaterial, in: .rect(cornerRadius: 12))
            }
        }
    }
    
    /// iOS 26/watchOS 26의 Glass Button Style을 조건부로 적용
    @ViewBuilder
    func glassButtonStyle() -> some View {
        self.apply {
            if #available(iOS 26.0, watchOS 26.0, *) {
                $0.buttonStyle(.glass)
            } else {
                $0.buttonStyle(.bordered)
            }
        }
    }
    
    /// 플랫폼별 Navigation Title 처리
//    @ViewBuilder
//    func adaptiveNavigationTitle(_ title: String) -> some View {
//        self.apply {
//            if #available(iOS 26.0, watchOS 26.0, *) {
//                $0.navigationTitle(title)
//            } else {
//                // watchOS의 경우 기존 방식 유지
//                $0.navigationTitle {
//                    Text(title)
//                        .font(.system(size: 14, weight: .semibold))
//                        .fixedSize()
//                        .foregroundStyle(.accent)
//                }
//            }
//        }
//    }
}

// MARK: - Liquid Glass Preset Styles

extension View {
    /// 마커 버튼용 Glass 스타일 (핵심 기능)
    @ViewBuilder
    func markerButtonGlassStyle() -> some View {
        self.apply {
            if #available(iOS 26.0, watchOS 26.0, *) {
                $0.buttonStyle(.glass)
                  .glassEffect()
            } else {
                $0.background(.thinMaterial)
                  .cornerRadius(8)
            }
        }
    }
    
    /// 네비게이션 버튼용 Glass 스타일
    @ViewBuilder
    func navigationButtonGlassStyle() -> some View {
        self.apply {
            if #available(iOS 26.0, watchOS 26.0, *) {
                $0.buttonStyle(.glass)
            } else {
                $0.buttonStyle(.plain)
            }
        }
    }
}
