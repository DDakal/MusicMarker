
import SwiftUI
import SwiftData
import Mixpanel

struct WatchPlayingView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(WatchNavigationManager.self) var navigationManager
    @EnvironmentObject var viewModel: WatchViewModel
    @Query var musicList: [Music] = []
    
    @State var showMarkerListOverlay: Bool = false
    
    @State var progress: Double = 0.25 // 현재 진행 상황을 나타내는 변수
    @State private var isIdle = true
    
    var body: some View {
        VStack {
            HStack {
                Text("\(viewModel.musicTitle)")
                    .font(.system(size: 12, weight: .regular))
                    .fixedSize()
            }
            HStack {
                TabView{
                    WatchPlayingMarkerView()
                    WatchPlayingSpeedView()
                }
            }
            
            HStack{
                Spacer()
                
                Circle()
                    .fill(.gray.opacity(0.2))
                    .cornerRadius(4)
                    .frame(height: 35)
                    .overlay(
                        Button {
                            viewModel.playBackward()
                        } label: {
                            Image(systemName: "gobackward.5")
                                .resizable()
                                .frame(width: 20, height: 21)
                        }
                        .frame(width: 34, height: 35)
                        .buttonStyle(PlainButtonStyle())
                    )
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(.gray.opacity(0.2))
                        .frame(height: 44)
                        .overlay(
                            Button {
                                viewModel.playToggle()
                                if viewModel.isPlaying != true {
                                    mixpanelPlayMusic()
                                }
                            } label: {
                                // 재생 on/off에 따라 이미지 변경
                                Image(systemName: viewModel.isPlaying == true ? "pause.fill" : "play.fill")
                                .resizable()
                                .frame(width: 18, height: 18)
                            }
                            .frame(width: 44, height: 44)
                            .buttonBorderShape(.circle)
                            .buttonStyle(PlainButtonStyle())
                        )
                    CircleProgressView(progress: viewModel.progress) // 현재 노래의 길이를 value로 바꿔서 주면됨.
                        .frame(width: 42, height: 42)
                }
                
                Spacer()
                
                Circle()
                    .fill(.gray.opacity(0.2))
                    .cornerRadius(4)
                    .frame(height: 35)
                    .overlay(
                        Button {
                            viewModel.playForward()
                        } label: {
                            Image(systemName: "goforward.5")
                                .resizable()
                                .frame(width: 20, height: 21)
                        }
                        .frame(width: 34, height: 35)
                        .buttonStyle(PlainButtonStyle())
                    )
                Spacer()
            }
            
            HStack {
                Text(viewModel.formattedProgress) // 현재 재생시간 데이터 넣어주기
                    .font(.system(size: 10, weight: .light))
                    .fixedSize()
            }
            .padding(.bottom, 10)
        }
        .focusable(true)
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarBackButtonHidden(true)
        .scrollIndicators(.hidden)
        .digitalCrownRotation(detent: $viewModel.crownVolume, from: 0, through: 60, by: 3, sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true
        )
        .onChange(of: viewModel.crownVolume) { oldValue, newValue in
            viewModel.handleCrownValueChange(newValue)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading){
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.accent)
                }
            }
            ToolbarItem(placement: .topBarTrailing){
                Button {
                    showMarkerListOverlay = true
                } label: {
                    Image(systemName: "list.bullet")
                        .foregroundStyle(.accent)
                }
            }
        }
        .fullScreenCover(isPresented: $showMarkerListOverlay, content: {
            WatchMarkerListView()
                .background {
                    Color.black
                }
        })
    }
    
    private func mixpanelPlayMusic() {
        Mixpanel.mainInstance().track(event: "노래 재생")
        Mixpanel.mainInstance().people.increment(property: "playMusic", by: 1)
    }
}

// MARK: 재생 버튼 ProgressBar
struct CircleProgressView: View {
    
    //    @Binding var progress: Double
    var progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(.gray.opacity(0.2), lineWidth: 4)
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(.white, lineWidth: 3)
                .rotationEffect(Angle(degrees: -90))
        }
    }
}

#Preview {
    WatchPlayingView()
        .environment(WatchNavigationManager())
}
