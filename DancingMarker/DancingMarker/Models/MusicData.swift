//
//  MusicData.swift
//  DancingMarker
//
//  Created by Woowon Kang on 6/5/25.
//

import Foundation

/// 버전 독립적인 음악 데이터 모델
///
/// Core Data와 SwiftData 간의 공통 인터페이스 역할을 합니다.
/// UI 레이어에서는 이 구조체만 사용하여 데이터 저장 방식에 독립적입니다.
struct MusicData: Identifiable, Equatable, Hashable {
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
