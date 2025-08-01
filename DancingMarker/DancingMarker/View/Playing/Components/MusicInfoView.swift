//
//  SwiftUIView.swift
//  DancingMarker
//
//  Created by Woowon Kang on 8/1/25.
//

import SwiftUI

struct MusicInfoView: View {
    let music: MusicData?
    
    var body: some View {
        HStack(spacing: 10) {
            if let music = music {
                albumArtView(for: music)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(music.title)
                        .font(.title3)
                        .bold()
                    Text(music.artist)
                        .font(.body)
                }
                Spacer()
            } else {
                Text("Local_EmptyMusic")
            }
        }
        .padding(.vertical, 12)
    }
    
    @ViewBuilder
    private func albumArtView(for music: MusicData) -> some View {
        if let albumArtData = music.albumArt,
           let albumArt = UIImage(data: albumArtData) {
            Image(uiImage: albumArt)
                .resizable()
                .frame(width: 66, height: 66)
                .cornerRadius(13)
        } else {
            RoundedRectangle(cornerRadius: 13)
                .fill(.textLightGray)
                .frame(width: 66, height: 66)
                .overlay {
                    Image(systemName: "music.note")
                        .resizable()
                        .padding()
                        .scaledToFit()
                        .foregroundColor(.gray)
                }
        }
    }
}
