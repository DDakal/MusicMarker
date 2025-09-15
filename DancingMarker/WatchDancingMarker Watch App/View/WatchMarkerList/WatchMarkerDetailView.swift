import SwiftUI

struct WatchMarkerDetailView: View {
    
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var viewModel: WatchViewModel
    
    @State private var isShownResetAlert = false // 초기화하기 Bool 변수
    
    let index: Int
    
    var body: some View {
        VStack(spacing: 10) {
            Text("\(viewModel.markers[index])")
                .font(.system(size: 17, weight: .regular))
                .fixedSize()
                .padding(.bottom)
            
            Button {
                self.isShownResetAlert.toggle()
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

//#Preview {
//    //    WatchMarkerDetailView(data: "임시 데이터")
//    MarkerResetAlert(navigationPath: Binding<NavigationPath>)
//}
