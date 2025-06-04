//
//  Music.swift
//  DancingMarker
//
//  Created by Woowon Kang on 7/4/24.
//

import Foundation
import SwiftData

@Model
class Music: Equatable, Hashable {
    static func == (lhs: Music, rhs: Music) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id: UUID
    var title: String
    var artist: String
    var fileName: String 
    var markers: [TimeInterval]
    var albumArt: Data?

    subscript(key: String) -> Any {
        switch key {
        case "title":
            return title
        case "artist":
            return artist
        case "fileName":
            return fileName
        case "markers":
            return markers
        case "albumArt":
            return albumArt ?? Data()
        default:
            return "invalid"
        }
    }

    init(title: String, artist: String, fileName: String, markers: [TimeInterval], albumArt: Data?) {
        self.id = UUID()
        self.title = title
        self.artist = artist
        self.fileName = fileName
        self.markers = markers
        self.albumArt = albumArt
    }

    // 경로를 반환하는 함수 추가
    var fileURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent(fileName)
    }
}
