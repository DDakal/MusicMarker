import SwiftUI

struct WatchMarkerEditView: View {
    
    @Binding var navigationPath: NavigationPath // 네비게이션 경로 관리 변수
    @EnvironmentObject var viewModel: WatchViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var isButtonEnabled = false // 저장하기 버튼 Enabled/Disabled
    
    @State var data: TimeInterval // 음악 시간 데이터
    @State private var count = 0 // 1초 증가/감소 변수
    @State private var initialData: TimeInterval // 음악시간 초기값 저장
    private var index: Int
    
    @State private var showingAlert = false // EditAlert 띄우기
    @Binding var isPresented: Bool // modal 상태관리 변수
    
    init(data: TimeInterval, isPresented: Binding<Bool>, index: Int, navigationPath: Binding<NavigationPath>) {
        self.data = data
        self.index = index
        self._initialData = State(initialValue: data)
        self._isPresented = isPresented
        self._navigationPath = navigationPath
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                HStack {
                    // MARK: 1초 감소 버튼
                    ZStack {
                        Circle()
                            .fill(.gray.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image("backward1SecIcon")
                            .colorMultiply(data < 1 ? .inactiveGray : .white)
                    }
                    .onTapGesture {
                        if data > 1 {
                            decrementMarkerTime()
                        }
                    }
                    
                    Spacer()
                    
                    // MARK: 현재 마커 시간
                    Text("\(formattedTime(data))")
                        .font(.system(size: 22, weight: .regular))
                        .fixedSize()
                    
                    Spacer()
                    
                    // MARK: 1초 증가 버튼
                    ZStack {
                        Circle()
                            .fill(.gray.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image("forward1SecIcon")
                            .colorMultiply(self.data > self.viewModel.duration - 1 ? .inactiveGray : .white)
                    }
                    .onTapGesture {
                        if self.data < self.viewModel.duration - 1 {
                            incrementMarkerTime()
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // MARK: 저장하기 버튼
                HStack{
                    Button {
                        // 마커 시간 수정한 후 저장
                        viewModel.connectivityManager.sendMarkerEditSuccessToIOS(forEdit: [index, count])
                        dismiss()
                        navigationPath.removeLast(navigationPath.count) // 루트로 이동
                    } label: {
                        Text("저장하기")
                            .font(.system(size: 17, weight: .regular))
                            .fixedSize()
                            .foregroundColor(data != initialData ? .white : .inactiveGray) // 처음의 시간이 아니라면 색상으로 활성화/비활성화 여부
                    }
                    .buttonStyle(
                        CommonButtonStyle(
                            backgroundColor: .gray.opacity(0.2),
                            foregroundColor: .white)
                    )
                    .disabled(data == initialData)
                }
            }
            .navigationTitle {
                Text("수정하기")
                    .font(.system(size: 14, weight: .semibold))
                    .fixedSize()
                    .foregroundStyle(.accent)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if data != initialData {
                            showingAlert = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .fullScreenCover(isPresented: $showingAlert) {
                MarkerEditAlert(isPresented: $isPresented)
            }
        }
    }
    
    // 1초 증가 함수
    private func incrementMarkerTime() {
        DispatchQueue.main.async{
            count += 1
            data += 1
            viewModel.connectivityManager.sendMarkerEditToIOS(forEdit: [index, count])
        }
    }
    
    // 1초 감소 함수
    private func decrementMarkerTime() {
        DispatchQueue.main.async{
            count -= 1
            data -= 1
            viewModel.connectivityManager.sendMarkerEditToIOS(forEdit: [index, count])
        }
    }
    
    private func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
