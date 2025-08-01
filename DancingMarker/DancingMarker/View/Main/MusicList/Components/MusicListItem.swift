//
//  MusicListItem.swift
//  DancingMarker
//
//  Created by Woowon Kang on 8/1/25.
//

import SwiftUI

struct MusicListItem: View {
    let music: Music
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            albumArtView
            
            VStack(alignment: .leading, spacing: 12) {
                Text(music.title)
                    .font(.title3)
                    .bold()
                Text(music.artist)
                    .font(.body)
            }
            .lineLimit(1)
            .contextMenu {
                contextMenu
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    // MARK: - Private Views
    
    private var albumArtView: some View {
        Group {
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
                            .foregroundStyle(.gray)
                    }
            }
        }
    }
    
    private var contextMenu: some View {
        Group {
            Button(action: onEdit) {
                Text("Local_Edit")
                Image(systemName: "pencil")
            }
            
            Button(role: .destructive, action: onDelete) {
                Text("Local_Delete")
                Image(systemName: "trash")
            }
        }
    }
}
