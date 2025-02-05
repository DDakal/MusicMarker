//
//  MarkerEditAlert.swift
//  WatchDancingMarker Watch App
//
//  Created by 이상도 on 2/5/25.
//

import SwiftUI

// MARK: 마커 수정 Alert
// WatchMarkerDetailView에서 사용
struct MarkerEditAlert: View {
    
    @Environment(\.dismiss) var dismiss
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                HStack {
                    Text("이 변경 사항을\n폐기하시겠습니까?")
                        .font(.system(size: 14))
                        .padding()
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                
                Button {
                    self.isPresented = false
                    dismiss()
                } label: {
                    Text("변경 사항 폐기")
                        .font(.system(size: 17, weight: .regular))
                        .fixedSize()
                }
                .buttonStyle(
                    CommonButtonStyle(
                        backgroundColor: .red.opacity(0.4),
                        foregroundColor: .red)
                )
               
                Button {
                    dismiss()
                } label: {
                    Text("계속 수정하기")
                        .font(.system(size: 17, weight: .regular))
                        .fixedSize()
                }
                .buttonStyle(
                    CommonButtonStyle(
                        backgroundColor: .gray.opacity(0.2),
                        foregroundColor: .white)
                )
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
}
