//
//  UIImage+.swift
//  DancingMarker
//
//  Created by Woowon Kang on 3/21/25.
//

import UIKit

extension UIImage {
    func croppedToSquare() -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        
        let aspectRatio = width / height
        var rect: CGRect
        
        if aspectRatio > 1 {
            // 가로가 더 긴 경우 → 가운데를 기준으로 정방형으로 자르기
            rect = CGRect(x: (width - height) / 2, y: 0, width: height, height: height)
        } else {
            // 세로가 더 긴 경우 → 가운데를 기준으로 정방형으로 자르기
            rect = CGRect(x: 0, y: (height - width) / 2, width: width, height: width)
        }
        
        guard let croppedCGImage = cgImage.cropping(to: rect) else { return nil }
        
        return UIImage(cgImage: croppedCGImage, scale: self.scale, orientation: self.imageOrientation)
    }
}
