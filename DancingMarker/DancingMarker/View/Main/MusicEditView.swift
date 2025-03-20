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
    @Environment(NavigationManager.self) var navigationManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var playerModel: PlayerModel
    let fileURL: URL  // 파일 URL
    @Query var musicList: [Music] = []
    @Binding var didSaveMusic: Bool
    
    @State private var title: String = ""
    @State private var artist: String = ""
    @State private var albumArt: UIImage? = nil
    @State private var isImagePickerPresented: Bool = false
    
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
                            .background(Color.clear)
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
                
                Button("저장하기") {
                    Task {
                        await addMusic(from: fileURL)
                        didSaveMusic = true  // 저장 여부 설정
                        dismiss()  // Sheet 닫기 (FileImporter 열리지 않음)
                    }
                }
                .fontWeight(.bold)
                .frame(height: 49)
                .frame(maxWidth: .infinity)
                .background(title.isEmpty || artist.isEmpty ? Color.gray.opacity(0.3) : Color.accentColor)
                .foregroundStyle(title.isEmpty || artist.isEmpty ? Color.white : Color.black)
                .cornerRadius(12)
                .disabled(title.isEmpty || artist.isEmpty)  // ✅ 비활성화 상태 적용
                .padding(.bottom, 53)
                
            }
            .padding(.horizontal, 16)
            .navigationTitle("음악 수정하기")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Image(systemName: "chevron.left").bold()
                        Text("뒤로가기")
                    }
                    .foregroundStyle(.accent)
                    .onTapGesture {
                        dismiss()
                    }
                }
            }}
        .sheet(isPresented: $isImagePickerPresented) {
            // ImagePicker 구현 (예: ImagePicker(selectedImage: $albumArt))
            Text("ImagePicker 구현 필요")
        }
        .onAppear {
            Task {
                do {
                    let success = fileURL.startAccessingSecurityScopedResource()  // ✅ 반환 값을 변수에 저장
                    if !success {
                        print("보안 접근 권한을 얻는 데 실패했습니다.")
                    }
                    defer { fileURL.stopAccessingSecurityScopedResource() }
                    
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
