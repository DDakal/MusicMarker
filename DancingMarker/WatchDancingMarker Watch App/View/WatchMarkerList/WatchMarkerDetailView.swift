import SwiftUI

struct WatchMarkerDetailView: View {
    
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var viewModel: WatchViewModel
    
    @State private var isShowingEditView = false // 수정하기 Bool 변수
    @State private var isShownResetAlert = false // 초기화하기 Bool 변수
    
    let index: Int
    
    var body: some View {
        VStack(spacing: 10) {
            Text("\(viewModel.markers[index])")
                .font(.system(size: 17, weight: .regular))
                .fixedSize()
                .padding(.bottom)
            
            Button {
                self.isShowingEditView.toggle()
            } label: {
                Text("수정하기")
                    .font(.system(size: 17, weight: .regular))
                    .fixedSize()
            }
            .buttonStyle(
                CommonButtonStyle(
                    backgroundColor: .gray.opacity(0.2),
                    foregroundColor: .white)
            )
            .fullScreenCover(isPresented: $isShowingEditView) {
                WatchMarkerEditView(data: viewModel.timeintervalMarkers[index], isPresented: $isShowingEditView, index: index, navigationPath: $navigationPath)
            }
            
            Button {
                self.isShownResetAlert.toggle()
            } label: {
                Text("지우기")
                    .font(.system(size: 17, weight: .regular))
                    .fixedSize()
            }
            .buttonStyle(
                CommonButtonStyle(
                    backgroundColor: .red.opacity(0.4),
                    foregroundColor: .red)
            )
            .fullScreenCover(isPresented: $isShownResetAlert) {
                MarkerResetAlert(navigationPath: $navigationPath, index: index)
            }
        }
        .padding()
    }
    
    private func convertTime(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

// MARK: 마커 초기화 Alert
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
                    Text("이 마커에 저장된\n정보를 지우시겠습니까?")
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
                    Text("지우기")
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

// MARK: 마커 수정 Alert
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

//#Preview {
//    //    WatchMarkerDetailView(data: "임시 데이터")
//    MarkerResetAlert(navigationPath: Binding<NavigationPath>)
//}
