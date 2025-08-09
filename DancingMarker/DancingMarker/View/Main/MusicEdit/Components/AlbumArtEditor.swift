//
//  AlbumArtEditor.swift
//  DancingMarker
//
//  Created by Woowon Kang on 8/1/25.
//

import SwiftUI

struct AlbumArtEditor: View {
    @Binding var albumArt: UIImage?
    @Binding var isImagePickerPresented: Bool
    @Binding var albumArtChanged: Bool
    
    var body: some View {
        VStack {
            if let albumArt = albumArt {
                Image(uiImage: albumArt)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .cornerRadius(12)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .foregroundStyle(.editViewAlbumGray)
                    .frame(width: 160, height: 160)
                    .overlay {
                        Image(systemName: "music.note")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundStyle(.white)
                    }
            }
            
            Button("Local_ChangeCoverImage") {
                isImagePickerPresented = true
            }
            .font(.caption)
            .bold()
            .foregroundStyle(.markerPurple)
            .buttonStyle(.borderedProminent)
            // TODO: 피드백 받고 지우기
            //.tint(.inactiveGray)
        }
        .padding(.top, 37)
        .padding(.bottom, 33)
    }
}
