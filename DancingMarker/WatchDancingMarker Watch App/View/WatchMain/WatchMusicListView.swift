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
                            onTap: { 
                                viewModel.requestImmediateSync()
                                navigationManager.push(to: .playing) 
                            }
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
                viewModel.handleAppActivation()
            }
        }
        .onChange(of: afterOnAppear) { _, afterAppear in
            if afterAppear {
                viewModel.handleViewAppear()
                afterOnAppear = false
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
}

#Preview {
    WatchMusicListView()
}
