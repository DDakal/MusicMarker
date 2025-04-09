//
//  MusicEditView.swift
//  DancingMarker
//
//  Created by 변준섭 on 6/27/24.
//

import SwiftUI
import SwiftData
import AVFoundation

struct MusicEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var playerModel: PlayerModel
    
    @Query var musicList: [Music] = []
    
    // 편집 모드: 기존 음원 수정 시 music이 전달되고,
    // 새 음원 추가 시에는 fileURL이 전달됩니다.
    let music: Music?
    let fileURL: URL?
    // 새 음원 추가용 binding (기존 음원 수정 시엔 사용하지 않음)
    @Binding var didSaveMusic: Bool
    
    @State private var selectedImgData: Data?
    @State private var title: String = ""
    @State private var artist: String = ""
    @State private var albumArt: UIImage? = nil
    @State private var isImagePickerPresented: Bool = false
    
    init(music: Music, didSaveMusic: Binding<Bool>) {
        self.music = music
        self.fileURL = nil
        self._didSaveMusic = didSaveMusic
        _title = State(initialValue: music.title)
        _artist = State(initialValue: music.artist)
        if let artData = music.albumArt, let image = UIImage(data: artData) {
            _albumArt = State(initialValue: image)
        }
    }
    
    init(fileURL: URL, didSaveMusic: Binding<Bool>) {
        self.music = nil
        self.fileURL = fileURL
        self._didSaveMusic = didSaveMusic
        // 초기값은 onAppear에서 fileURL 기반으로 불러옵니다.
    }
    
    var body: some View {
        ZStack {
            Color.editViewBGBlack.edgesIgnoringSafeArea(.all)
            
            VStack {
                VStack {
                    if let albumArt = albumArt {
                        Image(uiImage: albumArt)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 160, height: 160)
                            .cornerRadius(12)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .foregroundStyle(.editViewAlbumGray)  // 배경 색 적용
                            .frame(width: 160, height: 160)
                            .overlay {
                                Image(systemName: "music.note")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)  // 사이즈 조정
                                    .foregroundStyle(.white)  // 흰색 아이콘
                            }
                        
                    }
                    
                    Button("커버이미지 변경하기") {
                        isImagePickerPresented = true
                    }
                    .font(.caption)
                    .foregroundStyle(.markerPurple)
                    .underline(true, color: .markerPurple)
                    .buttonStyle(.plain)
                }
                .padding(.top, 67)
                .padding(.bottom, 43)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("음원 제목")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)  // 제목 스타일
                    
                    HStack {
                        TextField("음원의 제목을 입력해주세요", text: $title)
                            .frame(height: 34)
                            .background(.clear)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                        
                        if !title.isEmpty {
                            Button(action: { title = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.gray)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.bottom, 16)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("아티스트")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)  // 제목 스타일
                    
                    HStack {
                        TextField("아티스트 정보를 입력해주세요", text: $artist)
                            .frame(height: 34)
                            .background(Color.clear)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                        
                        if !artist.isEmpty {
                            Button(action: { artist = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.gray)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Spacer()
                
                Button(action: {
                    guard !title.isEmpty, !artist.isEmpty else { return }
                    Task {
                        if let existingMusic = music {
                            // 기존 음원 수정: Music 객체 업데이트
                            existingMusic.title = title
                            existingMusic.artist = artist
                            existingMusic.albumArt = albumArt?.pngData()
                            do {
                                try modelContext.save()
                            } catch {
                                print("음원 수정 실패: \(error.localizedDescription)")
                            }
                        } else if let fileURL = fileURL {
                            // 새 음원 추가: 파일 복사 후 새 Music 객체 생성
                            await addMusic(from: fileURL)
                            didSaveMusic = true
                        }
                        dismiss()
                    }
                }) {
                    HStack {
                        Spacer()
                        Text("저장하기")
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .frame(height: 49)
                    .frame(maxWidth: .infinity)
                    .background(title.isEmpty || artist.isEmpty ? Color.gray.opacity(0.3) : Color.accentColor)
                    .foregroundColor(title.isEmpty || artist.isEmpty ? Color.white : Color.black)
                    .cornerRadius(12)
                    .padding(.bottom, 53)
                }
                .buttonStyle(.plain)
                .disabled(title.isEmpty || artist.isEmpty)
            }
            .padding(.horizontal, 16)
            .navigationTitle("음악 수정하기")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("취소하기")
                    .foregroundStyle(.accent)
                    .onTapGesture {
                        dismiss()
                    }
                }
            }}
        .sheet(isPresented: $isImagePickerPresented) {
            SelectGalleryView(selectedImgData: $selectedImgData)
        }
        .onChange(of: selectedImgData) {
            if let data = selectedImgData, let image = UIImage(data: data) {
                albumArt = image 
            }
        }
        .onAppear {
            if music == nil, let fileURL = fileURL {
                Task {
                    do {
                        let (metaTitle, metaArtist, metaAlbumArtData) = try await fetchMusicMetadata(from: fileURL)
                        await MainActor.run {
                            if title.isEmpty { title = metaTitle }
                            if artist.isEmpty { artist = metaArtist }
                            if albumArt == nil, let data = metaAlbumArtData, let image = UIImage(data: data) {
                                albumArt = image
                            }
                        }
                    } catch {
                        print("메타데이터 로드 실패: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func addMusic(from url: URL) async {
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to start accessing security scoped resource at \(url)")
            return
        }
        
        do {
            // AVAsset에서 메타데이터를 가져오되, 사용자 입력을 우선적으로 사용할 예정
            let (metadataTitle, metadataArtist, metadataAlbumArt) = try await fetchMusicMetadata(from: url)
            
            // 사용자가 입력한 값이 있다면 그것을, 아니면 메타데이터를 사용하도록 결정
            let finalTitle = title.isEmpty ? metadataTitle : title
            let finalArtist = artist.isEmpty ? metadataArtist : artist
            let finalAlbumArt: Data?
            if let userAlbumArt = albumArt {
                finalAlbumArt = userAlbumArt.pngData()
            } else {
                finalAlbumArt = metadataAlbumArt
            }
            
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let uniqueFileURL = documentsDirectory.appendingUniquePathComponent(url.lastPathComponent)
            
            try FileManager.default.copyItem(at: url, to: uniqueFileURL)
            
            let newMusic = Music(
                title: finalTitle,
                artist: finalArtist,
                fileName: uniqueFileURL.lastPathComponent,
                markers: [-1, -1, -1],
                albumArt: finalAlbumArt
            )
            
            modelContext.insert(newMusic)
            try modelContext.save()
            
            playerModel.sendMusicListToWatch(with: musicList)
        } catch {
            print("Failed to add music: \(error.localizedDescription)")
        }
    }
    
    private func fetchMusicMetadata(from url: URL) async throws -> (String, String, Data?) {
        let asset = AVAsset(url: url)
        let metadata = try await asset.load(.commonMetadata)
        
        var title: String = "Unknown Title"
        var artist: String = "Unknown Artist"
        var albumArt: Data? = nil
        
        for item in metadata {
            if item.commonKey == .commonKeyTitle {
                title = try await item.load(.stringValue) ?? "Unknown Title"
            }
            if item.commonKey == .commonKeyArtist {
                artist = try await item.load(.stringValue) ?? "Unknown Artist"
            }
            if item.commonKey == .commonKeyArtwork {
                albumArt = try await item.load(.dataValue)
            }
        }
        
        return (title, artist, albumArt)
    }
}
