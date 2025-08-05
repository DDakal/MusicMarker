import SwiftUI

struct WatchMarkerEditView: View {
    
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var viewModel: WatchViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var isButtonEnabled = false
    @State var data: TimeInterval
    @State private var count = 0
    @State private var initialData: TimeInterval
    private var index: Int
    @State private var showingAlert = false
    @Binding var isPresented: Bool
    
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
                
                // 시간 조정 컨트롤
                MarkerTimeControl(
                    data: $data,
                    maxDuration: viewModel.duration,
                    onIncrement: incrementMarkerTime,
                    onDecrement: decrementMarkerTime,
                    formattedTime: formattedTime(data)
                )
                Spacer()
                
                // 저장 버튼
                MarkerSaveButton(
                    currentTime: data,
                    initialTime: initialData,
                    index: index,
                    onSave: handleSave
                )
            }
            .navigationTitle {
                Text("Local_MarkerEdit")
                    .font(.system(size: 14, weight: .semibold))
                    .fixedSize()
                    .foregroundStyle(.accent)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: handleCancel) {
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
}

extension WatchMarkerEditView {
    
    // MARK: - Time Adjustment Logic
    
    func incrementMarkerTime() {
        DispatchQueue.main.async {
            count += 1
            data += 1
        }
    }
    
    func decrementMarkerTime() {
        DispatchQueue.main.async {
            count -= 1
            data -= 1
        }
    }
    
    func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Action Handlers
    
    func handleSave(_ finalTime: Int) {
        viewModel.connectivityManager.sendMarkerEditSuccessToIOS(forEdit: [index, finalTime])
        dismiss()
        navigationPath.removeLast(navigationPath.count)
    }
    
    func handleCancel() {
        if data != initialData {
            showingAlert = true
        } else {
            dismiss()
        }
    }
}
