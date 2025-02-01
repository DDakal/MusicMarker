import SwiftUI
import Mixpanel

struct WatchPlayingMarkerView: View {
    
    @EnvironmentObject var viewModel: WatchViewModel
    
    var body: some View {
        HStack{
            // MARK: 마커 1
            ZStack {
                Rectangle()
                    .fill(viewModel.markers[0] == "99:59" ? Color.gray.opacity(0.2) : .accentColor) // 마커 추가가 되었다면 ? .yellow : Color.gray.opacity(0.2)
                    .cornerRadius(4)
                    .frame(height: 52)
                
                VStack {
                    Image(viewModel.markers[0] != "99:59" ? "addedMarker" : "emptyMarker")
                    Text(viewModel.markers[0] == "99:59" ? "추가" : viewModel.markers[0]) // 마커 추가가 되었다면 ? 마커 시간 : "추가"
                        .foregroundStyle(viewModel.markers[0] == "99:59" ? .white : .black)
                        .font(.system(size: 12, weight: .regular))
                        .fixedSize()
                        .italic()
                }
            }
            .onTapGesture {
                if viewModel.markers[0] == "99:59"{
                    viewModel.connectivityManager.sendMarkerSaveToIOS(0)
                    mixpanelSaveMarker()
                } else {
                    viewModel.connectivityManager.sendMarkerPlayToIOS(0)
                    mixpanelPlayMarker1()
                }
            }
            
            // MARK: 마커 2
            ZStack {
                Rectangle()
                    .fill(viewModel.markers[1] == "99:59" ? Color.gray.opacity(0.2) : .accentColor) // 마커 추가가 되었다면 ? .yellow : Color.gray.opacity(0.2)
                    .cornerRadius(4)
                    .frame(height: 52)
                
                VStack {
                    Image(viewModel.markers[1] != "99:59" ? "addedMarker" : "emptyMarker")
                    Text(viewModel.markers[1] == "99:59" ? "추가" : viewModel.markers[1]) // 마커 추가가 되었다면 ? 마커 시간 : "추가"\
                        .foregroundStyle(viewModel.markers[1] == "99:59" ? .white : .black)
                        .font(.system(size: 12, weight: .regular))
                        .fixedSize()
                        .italic()
                }
            }
            .onTapGesture {
                if viewModel.markers[1] == "99:59"{
                    viewModel.connectivityManager.sendMarkerSaveToIOS(1)
                    mixpanelSaveMarker()
                } else {
                    viewModel.connectivityManager.sendMarkerPlayToIOS(1)
                    mixpanelPlayMarker2()
                }
            }
            
            // MARK: 마커 3
            ZStack {
                Rectangle()
                    .fill(viewModel.markers[2] == "99:59" ? Color.gray.opacity(0.2) : .accentColor) // 마커 추가가 되었다면 ? .yellow : Color.gray.opacity(0.2)
                    .cornerRadius(4)
                    .frame(height: 52)
                
                VStack {
                    Image(viewModel.markers[2] != "99:59" ? "addedMarker" : "emptyMarker")
                    Text(viewModel.markers[2] == "99:59" ? "추가" : viewModel.markers[2]) // 마커 추가가 되었다면 ? 마커 시간 : "추가"
                        .foregroundStyle(viewModel.markers[2] == "99:59" ? .white : .black)
                        .font(.system(size: 12, weight: .regular))
                        .fixedSize()
                        .italic()
                }
            }
            .onTapGesture {
                if viewModel.markers[2] == "99:59"{
                    viewModel.connectivityManager.sendMarkerSaveToIOS(2)
                    mixpanelSaveMarker()
                } else {
                    viewModel.connectivityManager.sendMarkerPlayToIOS(2)
                    mixpanelPlayMarker3()
                }
            }
        }
        .padding(.bottom)
    }
    
    private func mixpanelSaveMarker() {
        Mixpanel.mainInstance().track(event: "마커 추가")
        Mixpanel.mainInstance().people.increment(property: "saveMarker", by: 1)
    }
    
    private func mixpanelPlayMarker1() {
        Mixpanel.mainInstance().track(event: "마커 재생1")
        Mixpanel.mainInstance().people.increment(property: "playMarker1", by: 1)
    }
    
    private func mixpanelPlayMarker2() {
        Mixpanel.mainInstance().track(event: "마커 재생2")
        Mixpanel.mainInstance().people.increment(property: "playMarker2", by: 1)
    }
    
    private func mixpanelPlayMarker3() {
        Mixpanel.mainInstance().track(event: "마커 재생3")
        Mixpanel.mainInstance().people.increment(property: "playMarker3", by: 1)
    }
}
