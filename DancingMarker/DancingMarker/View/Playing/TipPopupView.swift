//
//  TipPopupView.swift
//  DancingMarker
//
//  Created by Woowon Kang on 7/21/24.
//

import SwiftUI

struct TipPopupView: View {
    @Binding var isTipButtonPresented: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.buttonDarkGray)
            .frame(width: 360, height: 240)
            .overlay {
                VStack {
                    HStack{
                        Spacer()
                        
                        Button(action: {
                            isTipButtonPresented = false
                        }) {
                            // 닫기
                            Text("Local_TipViewClose")
                                .foregroundStyle(.accent)
                                .padding(.vertical, 11)
                                .padding(.trailing, 16)
                        }
                       
                    }
                    Image("editTip")
                        .padding(.bottom, 31)
                        .padding(.top, 23)
                    
                    VStack(spacing: 4) {
                        Text("Local_TipViewMessage1")
                        Text("Local_TipViewMessage2")
                    }
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 14))
                    .fontWeight(.medium)
                    
                    Spacer()
                }
            }
    }
}
