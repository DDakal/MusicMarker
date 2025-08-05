import SwiftUI
import SwiftData
// import Mixpanel  // ❌ 제거 - watchOS에 없음

struct WatchPlayingView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(WatchNavigationManager.self) var navigationManager
    @EnvironmentObject var viewModel: WatchViewModel
    @Query var musicList: [Music] = []
    
    @State var showMarkerListOverlay: Bool = false
    @State var progress: Double = 0.25  
    @State private var isIdle = true
    
    var body: some View {
        VStack {
            // 음악 제목
            WatchMusicInfoHeader(musicTitle: viewModel.musicTitle)
            
            // 마커/스피드 TabView
            HStack {
                TabView {
                    WatchPlayingMarkerView()
                    WatchPlayingSpeedView()
                }
            }
            
            // 재생 컨트롤
            WatchPlaybackControls(
                isPlaying: viewModel.isPlaying,
                progress: viewModel.progress,
                onBackward: {                    
                    try await performBackward()
                },
                onPlayToggle: {
                    await performPlayToggle()
                },
                onForward: {
                    try await performForward()
                }
            )
            
            // 현재 시간 표시
            WatchMusicTimeDisplay(formattedTime: viewModel.formattedProgress)
        }
        .focusable(true)
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarBackButtonHidden(true)
        .scrollIndicators(.hidden)
        .digitalCrownRotation(
            detent: $viewModel.crownVolume,
            from: 0, through: 60, by: 3,
            sensitivity: .low,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: viewModel.crownVolume) { _, newValue in
            viewModel.handleCrownValueChange(newValue)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.accent)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showMarkerListOverlay = true }) {
                    Image(systemName: "list.bullet")
                        .foregroundStyle(.accent)
                }
            }
        }
        .fullScreenCover(isPresented: $showMarkerListOverlay) {
            WatchMarkerListView()
                .background(Color.black)
        }
    }
}

// MARK: - Playback Actions Extension
extension WatchPlayingView {
    
    private func performBackward() async throws {
        viewModel.playBackward()
        viewModel.requestSyncWithDebounce()
    }
    
    private func performForward() async throws {
        viewModel.playForward()
        viewModel.requestSyncWithDebounce()
    }
    
    private func performPlayToggle() async {
        let wasPlaying = viewModel.isPlaying
        viewModel.playToggle()
        viewModel.requestImmediateSync()
        
        if !wasPlaying {
            trackPlayEvent()
        }
    }
    
    private func trackPlayEvent() {
        print("📊 워치에서 노래 재생됨")
    }
}

// MARK: - CircleProgressView
struct CircleProgressView: View {
    var progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(.gray.opacity(0.2), lineWidth: 4)
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(.white, lineWidth: 3)
                .rotationEffect(Angle(degrees: -90))
        }
    }
}

#Preview {
    WatchPlayingView()
        .environment(WatchNavigationManager())
}
