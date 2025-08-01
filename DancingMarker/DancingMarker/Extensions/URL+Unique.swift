//
//  URL+Unique.swift
//  DancingMarker
//
//  Created by Woowon Kang on 8/1/25.
//

import Foundation

extension URL {
    /// 중복되지 않는 고유한 파일 경로를 생성합니다.
    ///
    /// 동일한 파일명이 존재하는 경우 UUID를 추가하여 고유한 이름을 만듭니다.
    ///
    /// - Parameter component: 추가할 파일명
    /// - Returns: 고유한 파일 경로 URL
    func appendingUniquePathComponent(_ component: String) -> URL {
        var newURL = self.appendingPathComponent(component)
        let fileManager = FileManager.default
        var fileExists = fileManager.fileExists(atPath: newURL.path)
        
        while fileExists {
            let baseName = newURL.deletingPathExtension().lastPathComponent
            let extensionName = newURL.pathExtension
            let uniqueName = "\(baseName)-\(UUID().uuidString).\(extensionName)"
            newURL = self.appendingPathComponent(uniqueName)
            fileExists = fileManager.fileExists(atPath: newURL.path)
        }
        
        return newURL
    }
}
