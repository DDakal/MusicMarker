//
//  MarkerResetAlert.swift
//  WatchDancingMarker Watch App
//
//  Created by 이상도 on 2/5/25.
//

import SwiftUI

// MARK: 마커 초기화 Alert
// WatchMarkerDetailView에서 사용
struct MarkerResetAlert: View {
    
    @Environment(\.dismiss) var dismiss
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var viewModel: WatchViewModel
    
    let index: Int
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                HStack {
                    Text("Local_Watch_ClearMarkerMessage")
                        .font(.system(size: 14, weight: .regular))
                        .fixedSize()
                        .padding()
                        .padding(.bottom, 20)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                
                Button {
                    viewModel.timeintervalMarkers[index] = -1
                    viewModel.markers[index] = "99:59"
                    viewModel.deletemarker(index: index)
                    navigationPath.removeLast(navigationPath.count) // 초기화 되면서 뷰 이동
                } label: {
                    Text("Local_MarkerReset")
                        .font(.system(size: 17, weight: .regular))
                        .fixedSize()
                }
                .buttonStyle(
                    CommonButtonStyle(
                        backgroundColor: .red.opacity(0.4),
                        foregroundColor: .red)
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
