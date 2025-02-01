import SwiftUI

struct WatchMarkerDetailView: View {
    
    @Binding var navigationPath: NavigationPath
    @State private var isShowingEditView = false // 수정하기 Bool 변수
    @State private var isShownResetAlert = false // 초기화하기 Bool 변수
    @EnvironmentObject var viewModel: WatchViewModel
    
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
            .buttonStyle(EditButtonStyle())
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
            .buttonStyle(ResetButtonStyle())
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
    
    @Environment(\.presentationMode) var presentationMode
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
                .buttonStyle(ResetButtonStyle())
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
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
    
    @Environment(\.presentationMode) var presentationMode
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
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("변경 사항 폐기")
                        .font(.system(size: 17, weight: .regular))
                        .fixedSize()
                }
                .buttonStyle(DiscardButtonStyle())
               
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("계속 수정하기")
                        .font(.system(size: 17, weight: .regular))
                        .fixedSize()
                }
                .buttonStyle(ContinueEditButtonStyle())
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
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

// MARK: 계속 수정하기 버튼 스타일
struct ContinueEditButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .bold()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(9)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
// MARK: 변경사항 폐기 버튼 스타일
struct DiscardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .bold()
            .background(Color.red.opacity(0.4))
            .foregroundColor(.red)
            .cornerRadius(9)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
// MARK: 수정하기버튼 Button Style
struct EditButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .bold()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(9)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
// MARK: 초기화버튼 Button Style
struct ResetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .bold()
            .background(Color.red.opacity(0.4))
            .foregroundColor(.red)
            .cornerRadius(9)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

//#Preview {
//    //    WatchMarkerDetailView(data: "임시 데이터")
//    MarkerResetAlert(navigationPath: Binding<NavigationPath>)
//}
