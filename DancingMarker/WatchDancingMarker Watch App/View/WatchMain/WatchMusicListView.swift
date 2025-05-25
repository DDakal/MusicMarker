import SwiftUI
import SwiftData

struct WatchMusicListView: View {
    
    @State private var navigationManager = WatchNavigationManager()
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var viewModel: WatchViewModel
    
    @State private var drawingHeight = true
    @State private var afterOnAppear: Bool = true
    
    //    @Query var musicList: [watchMusic] = []
    let columns = [ GridItem(.flexible()) ]
    
    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            VStack {
//                HStack{
//                    Text("Music Marker")
//                        .font(.system(size:14, weight:.semibold))
//                        .fixedSize()
//                        .foregroundStyle(.accent)
//                        .padding(.leading, 11)
//                    Spacer()
//                }
//                .padding(.top, 0)
                
                if viewModel.musicList.filter{ $0 != ["",""] }.count == 0 {
                    VStack {
                        Spacer()
                        Text("Local_Watch_FirstAtMobileMessage")
                            .font(.system(size: 16, weight: .regular))
                            .fixedSize()
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns) {
                            ForEach(viewModel.musicList.indices, id:\.self) { index in
                                if  viewModel.musicList[index][0] != ""{
                                    Button {
                                        DispatchQueue.main.async{
                                            viewModel.sendUUID(id: viewModel.musicList[index][1])
                                            navigationManager.push(to: .playing)
                                        }
                                    } label: {
                                        Text(viewModel.musicList[index][0])
                                            .font(.system(size: 17, weight: .regular))
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding()
                                    }
                                    .buttonBorderShape(.roundedRectangle)
                                    .frame(height: 40)
                                    .padding(.bottom, 5)
                                }
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing){
                    if viewModel.musicTitle != "" {
                        Button {
                            navigationManager.push(to: .playing)
                        } label: {
                            if viewModel.isPlaying {
                                HStack(spacing:1.6) {
                                    bar(low: 0.4)
                                        .animation(animation.speed(1.5), value: drawingHeight)
                                    bar(low: 0.3)
                                        .animation(animation.speed(1.2), value: drawingHeight)
                                    bar(low: 0.5)
                                        .animation(animation.speed(1.0), value: drawingHeight)
                                    bar(low: 0.3)
                                        .animation(animation.speed(1.7), value: drawingHeight)
                                    bar(low: 0.3)
                                        .animation(animation.speed(1.3), value: drawingHeight)
                                }
                                .frame(width:20)
                                .onAppear{
                                    drawingHeight.toggle()
                                }
                            } else{
                                HStack(spacing:1.6) {
                                    stopBar()
                                    stopBar()
                                    stopBar()
                                    stopBar()
                                    stopBar()
                                }
                                .frame(width:20)
                            }
                        }
                        .frame(width: 32, height: 32)
                    }
                }
            }
            .navigationDestination(for: WatchPathType.self) { pathType in
                pathType.NavigatingView()
            }
        }
        .environment(navigationManager)
        .task {
            if viewModel.connectivityManager.isReachable {
                viewModel.connectivityManager.sendRequireMusicListToIOS()
            } else {
                viewModel.connectivityManager.sendRequireMusicListToIOS()
                print("WatchConnectivity session is not reachable.")
                
            }
            afterOnAppear = true
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                print("onActive")
                DispatchQueue.main.async {
                    viewModel.connectivityManager.sendRequireMusicListToIOS()
                    print("\(viewModel.musicList)")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                    viewModel.connectivityManager.sendRequireMusicListToIOS()
                    print("\(viewModel.musicList)")
                }
            }
        }
        .onChange(of: afterOnAppear) { beforeAppear, afterAppear in
            if afterAppear == true {
                print("onAppear")
                DispatchQueue.main.async {
                    viewModel.connectivityManager.sendRequireMusicListToIOS()
                    afterOnAppear = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                    viewModel.connectivityManager.sendRequireMusicListToIOS()
                    afterOnAppear = false
                }
            }
        }
    }
    
    private func bar(low: CGFloat = 0.0, high: CGFloat = 1.0) -> some View {
        RoundedRectangle(cornerRadius: 1.2)
            .fill(.accent)
            .frame(height: (drawingHeight ? high : low) * 18)
            .frame(width:1.6, height: 18, alignment: .center)
    }
    
    private func stopBar() -> some View {
        RoundedRectangle(cornerRadius: 1.2)
            .fill(.accent)
            .frame(width:1.6, height: 2.5, alignment: .center)
    }
    
    var animation: Animation {
        return .linear(duration: 0.5).repeatForever()
    }
}
