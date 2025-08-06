import SwiftUI
import SwiftData

struct WatchMusicListView: View {
    
    @EnvironmentObject var viewModel: WatchViewModel
    @State private var navigationManager = WatchNavigationManager()
    @Environment(\.scenePhase) var scenePhase
    
    @State private var hasInitialized = false
    @State private var afterOnAppear = true
    
    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            VStack {
                if viewModel.musicList.filter({ $0 != ["",""] }).isEmpty {
                    WatchEmptyMusicView()
                } else {
                    WatchMusicGrid(
                        musicList: viewModel.musicList,
                        onMusicTap: handleMusicTap
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.musicList.isEmpty && viewModel.hasSelectedMusic {
                        WatchPlayingIndicator(
                            isPlaying: viewModel.isPlaying,
                            onTap: { navigationManager.push(to: .playing) }
                        )
                    }
                }
            }
            .navigationDestination(for: WatchPathType.self) { pathType in
                pathType.NavigatingView()
            }
        }
        .environment(navigationManager)
        .onAppear {
            afterOnAppear = true
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                handleSceneActivation()
            }
        }
        .onChange(of: afterOnAppear) { _, afterAppear in
            if afterAppear {
                handleOnAppear()
            }
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleMusicTap(_ musicID: String) {
        DispatchQueue.main.async {
            viewModel.sendUUID(id: musicID)
            navigationManager.push(to: .playing)
        }
    }
    
    private func handleSceneActivation() {
        print("onActive")
        requestMusicListSync()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            requestMusicListSync()
        }
    }
    
    private func handleOnAppear() {
        print("onAppear")
        requestMusicListSync()
        afterOnAppear = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            requestMusicListSync()
            afterOnAppear = false
        }
    }
    
    private func requestMusicListSync() {
        DispatchQueue.main.async {
            // ✅ 새로운 방식 - ViewModel의 깔끔한 인터페이스 사용
            viewModel.requestMusicList()
            print("음악 목록 요청 - 현재 목록: \(viewModel.musicList)")
        }
    }
}

// MARK: - Sync Methods Extension
extension WatchMusicListView {
    
    func performInitialSync() async {
        print("🎯 앱 시작 - 초기 음악 목록 동기화")
        await syncMusicList()
        hasInitialized = true
    }
    
    func syncMusicList() async {
        // ✅ 새로운 방식 - ViewModel의 깔끔한 인터페이스 사용
        guard viewModel.isConnected else {
            print("⚠️ 워치 연결 안됨 - 동기화 건너뜀")
            return
        }
        
        viewModel.requestMusicList()
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        viewModel.requestMusicList()
        
        print("✅ 음악 목록 동기화 요청 완료")
    }
    
    func syncMusicListOnAppear() async {
        print("🎯 syncMusicListOnAppear 시작")
        await viewModel.syncMusicListOnAppear()
    }
}

#Preview {
    WatchMusicListView()
}
