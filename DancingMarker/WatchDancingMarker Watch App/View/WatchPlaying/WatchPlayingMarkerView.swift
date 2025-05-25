import SwiftUI
import Mixpanel

struct WatchPlayingMarkerView: View {
    
    @EnvironmentObject var viewModel: WatchViewModel
    
    var body: some View {
        HStack{
            // MARK: 마커 1
            ZStack {
                Rectangle()
                    .fill(viewModel.markers[0] == "99:59" ? .gray.opacity(0.2) : .accentColor) // 마커 추가가 되었다면 ? .yellow : Color.gray.opacity(0.2)
                    .cornerRadius(4)
                    .frame(height: 52)
                
                VStack {
                    Image(viewModel.markers[0] != "99:59" ? "addedMarker" : "emptyMarker")
                    if viewModel.markers[0] == "99:59" {
                        Text("Local_MarkerAdd")
                            .foregroundStyle(.white)
                            .font(.system(size: 12, weight: .regular))
                            .fixedSize()
                            .italic()
                    } else {
                        Text(viewModel.markers[0])
                            .foregroundStyle(.black)
                            .font(.system(size: 12, weight: .regular))
                            .fixedSize()
                            .italic()
                    }
                }
            }
            .onTapGesture {
                if viewModel.markers[0] == "99:59"{
                    viewModel.connectivityManager.sendMarkerSaveToIOS(0)
                    saveMixpanelMarker()
                } else {
                    viewModel.connectivityManager.sendMarkerPlayToIOS(0)
                    playMixpanelMarker1()
                }
            }
            
            // MARK: 마커 2
            ZStack {
                Rectangle()
                    .fill(viewModel.markers[1] == "99:59" ? .gray.opacity(0.2) : .accentColor) // 마커 추가가 되었다면 ? .yellow : Color.gray.opacity(0.2)
                    .cornerRadius(4)
                    .frame(height: 52)
                
                VStack {
                    Image(viewModel.markers[1] != "99:59" ? "addedMarker" : "emptyMarker")
                    if viewModel.markers[1] == "99:59" {
                        Text("Local_MarkerAdd")
                            .foregroundStyle(.white)
                            .font(.system(size: 12, weight: .regular))
                            .fixedSize()
                            .italic()
                    } else {
                        Text(viewModel.markers[1])
                            .foregroundStyle(.black)
                            .font(.system(size: 12, weight: .regular))
                            .fixedSize()
                            .italic()
                    }
                }
            }
            .onTapGesture {
                if viewModel.markers[1] == "99:59"{
                    viewModel.connectivityManager.sendMarkerSaveToIOS(1)
                    saveMixpanelMarker()
                } else {
                    viewModel.connectivityManager.sendMarkerPlayToIOS(1)
                    playMixpanelMarker2()
                }
            }
            
            // MARK: 마커 3
            ZStack {
                Rectangle()
                    .fill(viewModel.markers[2] == "99:59" ? .gray.opacity(0.2) : .accentColor) // 마커 추가가 되었다면 ? .yellow : Color.gray.opacity(0.2)
                    .cornerRadius(4)
                    .frame(height: 52)
                
                VStack {
                    Image(viewModel.markers[2] != "99:59" ? "addedMarker" : "emptyMarker")
                    if viewModel.markers[2] == "99:59" {
                        Text("Local_MarkerAdd")
                            .foregroundStyle(.white)
                            .font(.system(size: 12, weight: .regular))
                            .fixedSize()
                            .italic()
                    } else {
                        Text(viewModel.markers[2])
                            .foregroundStyle(.black)
                            .font(.system(size: 12, weight: .regular))
                            .fixedSize()
                            .italic()
                    }
                }
            }
            .onTapGesture {
                if viewModel.markers[2] == "99:59"{
                    viewModel.connectivityManager.sendMarkerSaveToIOS(2)
                    saveMixpanelMarker()
                } else {
                    viewModel.connectivityManager.sendMarkerPlayToIOS(2)
                    playMixpanelMarker3()
                }
            }
        }
        .padding(.bottom)
    }
    
    private func saveMixpanelMarker() {
        Mixpanel.mainInstance().track(event: "마커 추가")
        Mixpanel.mainInstance().people.increment(property: "saveMarker", by: 1)
    }
    
    private func playMixpanelMarker1() {
        Mixpanel.mainInstance().track(event: "마커 재생1")
        Mixpanel.mainInstance().people.increment(property: "playMarker1", by: 1)
    }
    
    private func playMixpanelMarker2() {
        Mixpanel.mainInstance().track(event: "마커 재생2")
        Mixpanel.mainInstance().people.increment(property: "playMarker2", by: 1)
    }
    
    private func playMixpanelMarker3() {
        Mixpanel.mainInstance().track(event: "마커 재생3")
        Mixpanel.mainInstance().people.increment(property: "playMarker3", by: 1)
    }
}
