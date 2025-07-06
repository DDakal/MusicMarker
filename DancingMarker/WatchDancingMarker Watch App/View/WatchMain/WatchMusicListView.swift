import SwiftUI
import SwiftData

struct WatchMusicListView: View {
    
    @EnvironmentObject var viewModel: WatchViewModel
    @State private var navigationManager = WatchNavigationManager()
    @Environment(\.scenePhase) var scenePhase
    
    @State private var drawingHeight = true
    @State private var hasInitialized = false
    @State private var afterOnAppear = true
    
    //    @Query var musicList: [watchMusic] = []
    let columns = [ GridItem(.flexible()) ]
    
    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            VStack {
//                HStack{
//                    Text("Music Marker")
//                        .font(.system(size:14, weight:.semibold))
//                        .fixedSize()
//                        .foregroundStyle(.accent)
//                        .padding(.leading, 11)
//                    Spacer()
//                }
//                .padding(.top, 0)
                
                if viewModel.musicList.filter({ $0 != ["",""] }).count == 0 {
                    VStack {
                        Spacer()
                        Text("Local_Watch_FirstAtMobileMessage")
                            .font(.system(size: 16, weight: .regular))
                            .fixedSize()
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns) {
                            ForEach(viewModel.musicList.indices, id:\.self) { index in
                                if  viewModel.musicList[index][0] != ""{
                                    Button(action: {
                                        DispatchQueue.main.async{
                                            viewModel.sendUUID(id: viewModel.musicList[index][1])
                                            navigationManager.push(to: .playing)
                                        }
                                    }) {
                                        Text(viewModel.musicList[index][0])
                                            .font(.system(size: 17, weight: .regular))
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding()
                                    }
                                    .buttonBorderShape(.roundedRectangle)
                                    .frame(height: 40)
                                    .padding(.bottom, 5)
                                }
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.musicList.isEmpty && viewModel.hasSelectedMusic {
                        Button {
                            navigationManager.push(to: .playing)
                        } label: {
                            if viewModel.isPlaying {
                                HStack(spacing: 1.6) {
                                    bar(low: 0.4).animation(animation.speed(1.5), value: drawingHeight)
                                    bar(low: 0.3).animation(animation.speed(1.2), value: drawingHeight)
                                    bar(low: 0.5).animation(animation.speed(1.0), value: drawingHeight)
                                    bar(low: 0.3).animation(animation.speed(1.7), value: drawingHeight)
                                    bar(low: 0.3).animation(animation.speed(1.3), value: drawingHeight)
                                }
                                .frame(width: 20)
                                .onAppear { startAnimationTimer() }
                                .onDisappear { stopAnimationTimer() }
                                .onChange(of: viewModel.isPlaying) { _, newValue in
                                    newValue ? startAnimationTimer() : stopAnimationTimer()
                                }
                            } else {
                                HStack(spacing: 1.6) {
                                    stopBar(); stopBar(); stopBar(); stopBar(); stopBar()
                                }
                                .frame(width: 20)
                            }
                        }
                        .frame(width: 32, height: 32)
                    }
                }
            }
            .navigationDestination(for: WatchPathType.self) { pathType in
                pathType.NavigatingView()
            }
        }
        .environment(navigationManager)
        .onAppear {
            afterOnAppear = true  // onAppear 감지용
        }
        // 첫 번째 onChange - scenePhase 변경 감지
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                print("onActive")
                DispatchQueue.main.async {
                    viewModel.connectivityManager.sendRequireMusicListToIOS()
                    print("onActive - 음악 목록: \(viewModel.musicList)")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.connectivityManager.sendRequireMusicListToIOS()
                    print("onActive (0.5초 후) - 음악 목록: \(viewModel.musicList)")
                }
            }
        }
        // 두 번째 onChange - afterOnAppear 변경 감지
        .onChange(of: afterOnAppear) { beforeAppear, afterAppear in
            if afterAppear == true {
                print("onAppear")
                DispatchQueue.main.async {
                    viewModel.connectivityManager.sendRequireMusicListToIOS()
                    print("afterOnAppear - 음악 목록: \(viewModel.musicList)")
                    afterOnAppear = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.connectivityManager.sendRequireMusicListToIOS()
                    print("afterOnAppear (0.5초 후) - 음악 목록: \(viewModel.musicList)")
                    afterOnAppear = false
                }
            }
        }
    }
    
    private func bar(low: CGFloat = 0.0, high: CGFloat = 1.0) -> some View {
        RoundedRectangle(cornerRadius: 1.2)
            .fill(.accent)
            .frame(height: (drawingHeight ? high : low) * 18)
            .frame(width:1.6, height: 18, alignment: .center)
    }
    
    private func stopBar() -> some View {
        RoundedRectangle(cornerRadius: 1.2)
            .fill(.accent)
            .frame(width:1.6, height: 2.5, alignment: .center)
    }
    
    var animation: Animation {
        return .linear(duration: 0.5).repeatForever()
    }
    
    // MARK: - Animation Timer
    
    @State private var animationTimer: Timer?
    
    private func startAnimationTimer() {
        // 기존 타이머가 있으면 해제
        animationTimer?.invalidate()
        
        // 즉시 애니메이션 시작
        drawingHeight.toggle()
        
        // 0.5초마다 drawingHeight 토글 (애니메이션 지속)
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            DispatchQueue.main.async {
                self.drawingHeight.toggle()
            }
        }
        print("✅ 애니메이션 타이머 시작 - drawingHeight: \(drawingHeight)")
    }
    
    private func stopAnimationTimer() {
        animationTimer?.invalidate()
        animationTimer = nil
        // 정지 상태로 애니메이션 초기화
        drawingHeight = false
        print("⏸️ 애니메이션 타이머 정지")
    }
    
    // MARK: - Private Methods
    
    private func performInitialSync() async {
        print(" 앱 시작 - 초기 음악 목록 동기화")
        await syncMusicList()
        hasInitialized = true
    }
    
    private func syncMusicList() async {
        // 연결 상태 확인
        guard viewModel.connectivityManager.isReachable else {
            print("⚠️ 워치 연결 안됨 - 동기화 건너뜀")
            return
        }
        
        // 즉시 요청
        viewModel.connectivityManager.sendRequireMusicListToIOS()
        
        // 0.5초 후 재요청 (연결 안정성 확보)
        try? await Task.sleep(nanoseconds: 500_000_000)
        viewModel.connectivityManager.sendRequireMusicListToIOS()
        
        print("✅ 음악 목록 동기화 요청 완료")
    }

    // 워치 앱 시작 시 통합 동기화 실행
    private func syncMusicListOnAppear() async {
        print("🎯 syncMusicListOnAppear 시작")
        
        // ✅ WatchViewModel을 통해 통합 동기화 실행
        await viewModel.syncMusicListOnAppear()
    }
}
