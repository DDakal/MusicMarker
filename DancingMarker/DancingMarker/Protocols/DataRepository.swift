//
//  DataRepository.swift
//  DancingMarker
//
//  Created by Woowon Kang on 6/5/25.
//

import Foundation

/// 데이터 영속성을 관리하는 프로토콜
///
/// iOS 버전에 따라 Core Data(iOS 16) 또는 SwiftData(iOS 17+)를 사용하여
/// 일관된 데이터 액세스 인터페이스를 제공합니다.
protocol DataRepository {
    
    /// 모든 음악을 가져옵니다
    /// - Returns: 음악 목록
    func fetchAllMusic() async throws -> [MusicData]
    
    /// 음악을 저장합니다
    /// - Parameter music: 저장할 음악 데이터
    func saveMusic(_ music: MusicData) async throws
    
    /// 음악을 업데이트합니다
    /// - Parameter music: 업데이트할 음악 데이터
    func updateMusic(_ music: MusicData) async throws
    
    /// 음악을 삭제합니다
    /// - Parameter id: 삭제할 음악의 ID
    func deleteMusic(id: UUID) async throws
    
    /// 특정 음악을 찾습니다
    /// - Parameter id: 음악 ID
    /// - Returns: 음악 데이터 또는 nil
    func findMusic(id: UUID) async throws -> MusicData?
}

/// 버전 독립적인 음악 데이터 모델
struct MusicData: Identifiable, Equatable {
    let id: UUID
    var title: String
    var artist: String
    var fileName: String
    var markers: [TimeInterval]
    var albumArt: Data?
    
    init(id: UUID = UUID(), title: String, artist: String, fileName: String, markers: [TimeInterval], albumArt: Data? = nil) {
        self.id = id
        self.title = title
        self.artist = artist
        self.fileName = fileName
        self.markers = markers
        self.albumArt = albumArt
    }
    
    /// 파일 URL을 반환합니다
    var fileURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent(fileName)
    }
}
