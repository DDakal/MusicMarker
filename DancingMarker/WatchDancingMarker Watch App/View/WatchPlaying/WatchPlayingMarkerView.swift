import SwiftUI
import Mixpanel

struct WatchPlayingMarkerView: View {
    
    @EnvironmentObject var viewModel: WatchViewModel
    
    var body: some View {
        HStack{
            // MARK: 마커 1
            MarkerButton(
                markerIndex: 0,
                viewModel: viewModel,
                onSave: saveMixpanelMarker,
                onPlay: playMixpanelMarker1
            )
            
            // MARK: 마커 2  
            MarkerButton(
                markerIndex: 1,
                viewModel: viewModel,
                onSave: saveMixpanelMarker,
                onPlay: playMixpanelMarker2
            )
            
            // MARK: 마커 3
            MarkerButton(
                markerIndex: 2,
                viewModel: viewModel,
                onSave: saveMixpanelMarker,
                onPlay: playMixpanelMarker3
            )
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

// MARK: - MarkerButton Component

struct MarkerButton: View {
    let markerIndex: Int
    let viewModel: WatchViewModel
    let onSave: () -> Void
    let onPlay: () -> Void
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(viewModel.isMarkerEmpty(at: markerIndex) ? .gray.opacity(0.2) : .accentColor)
                .cornerRadius(4)
                .frame(height: 52)
            
            VStack {
                Image(viewModel.isMarkerEmpty(at: markerIndex) ? "emptyMarker" : "addedMarker")
                
                if viewModel.isMarkerEmpty(at: markerIndex) {
                    Text("Local_MarkerAdd")
                        .foregroundStyle(.white)
                        .font(.system(size: 12, weight: .regular))
                        .fixedSize()
                        .italic()
                } else {
                    Text(viewModel.markers[markerIndex])
                        .foregroundStyle(.black)
                        .font(.system(size: 12, weight: .regular))
                        .fixedSize()
                        .italic()
                }
            }
        }
        .onTapGesture {
            if viewModel.isMarkerEmpty(at: markerIndex) {
                viewModel.saveMarker(at: markerIndex)
                onSave()
            } else {
                viewModel.playMarker(at: markerIndex)
                onPlay()
            }
        }
    }
}
