//
//  DependencyContainer.swift
//  DancingMarker
//
//  Created by Woowon Kang on 6/5/25.
//

import Foundation
import SwiftData

/// 의존성 주입 컨테이너
///
/// 앱 전체에서 사용되는 서비스들을 중앙에서 관리하고,
/// 필요한 곳에서 의존성을 주입받을 수 있도록 해주는 컨테이너입니다.
@MainActor
final class DependencyContainer: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = DependencyContainer()
    
    // MARK: - Services (Lazy Initialization)
    
    private lazy var _audioService: AudioService = {
        AudioService()
    }()
    
    private lazy var _markerService: MarkerService = {
        MarkerService() // 파라미터 없이 생성
    }()
    
    private lazy var _watchService: WatchService = {
        WatchService() // 파라미터 없이 생성
    }()
    
    private lazy var _liveActivityService: LiveActivityService = {
        LiveActivityService()
    }()
    
    // MARK: - Model Container
    
    let modelContainer: ModelContainer = {
        let schema = Schema([Music.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    // MARK: - Initialization
    
    private init() {
        // 초기화 작업
        setupServices()
    }
    
    // MARK: - Public Service Access
    
    /// AudioService 인스턴스를 반환합니다
    var audioService: any AudioPlayable {
        return _audioService
    }
    
    /// MarkerService 인스턴스를 반환합니다
    var markerService: any MarkerManageable {
        return _markerService
    }
    
    /// WatchService 인스턴스를 반환합니다
    var watchService: any WatchConnectivityManageable {
        return _watchService
    }
    
    /// LiveActivityService 인스턴스를 반환합니다
    var liveActivityService: any ControlCenterManageable {
        return _liveActivityService
    }
    
    // MARK: - PlayerViewModel Factory
    
    /// 의존성이 주입된 PlayerViewModel을 생성합니다
    func makePlayerViewModel() -> PlayerViewModel {
        return PlayerViewModel(
            audioService: audioService,
            markerService: markerService,
            watchService: watchService,
            liveActivityService: liveActivityService
        )
    }
}

// MARK: - Private Setup Methods

private extension DependencyContainer {
    
    func setupServices() {
        // 서비스들이 모두 독립적이므로 추가 설정 불필요
        // 향후 서비스 간 의존성이 생기면 여기서 설정
        
        print("🚀 DependencyContainer 초기화 완료")
        print("📱 AudioService, MarkerService, WatchService, LiveActivityService 준비됨")
    }
}

// MARK: - Testing Support

#if DEBUG
extension DependencyContainer {
    
    /// 테스트용 DependencyContainer 생성
    static func makeForTesting(
        audioService: (any AudioPlayable)? = nil,
        markerService: (any MarkerManageable)? = nil,
        watchService: (any WatchConnectivityManageable)? = nil,
        liveActivityService: (any ControlCenterManageable)? = nil
    ) -> DependencyContainer {
        let container = DependencyContainer()
        
        // Mock 서비스들로 교체 (향후 테스트 시 사용)
        // TODO: Mock 서비스들이 구현되면 여기서 교체
        
        return container
    }
}
#endif
