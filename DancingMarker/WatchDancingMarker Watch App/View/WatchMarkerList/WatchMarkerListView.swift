import SwiftUI

struct WatchMarkerListView: View {
    
    @State private var navigationPath = NavigationPath()
    let columns = [ GridItem(.flexible()) ]
    
    @EnvironmentObject var viewModel: WatchViewModel
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                ScrollView {
                    HStack {
                        Text("Local_Watch_ManagementMarker")
                            .font(.system(size: 14, weight: .bold))
                            .fixedSize()
                            .padding([.leading, .bottom])
                        Spacer()
                    }
                    // 여기서 임시데이터가 아닌 스위프트에 저장되어있는 data를 cell 변수로 넣어서 보여주기
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.timeintervalMarkers.indices, id: \.self) { index in
                            if viewModel.timeintervalMarkers[index] != -1{
                                NavigationLink(value: index) {
                                    WatchMarkerListCellView(data: viewModel.timeintervalMarkers[index])
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else{
                                ZStack {
                                    Rectangle()
                                        .fill(.gray.opacity(0.2))
                                        .cornerRadius(4)
                                        .frame(height: 44)
                                    HStack {
                                        Image("emptyMarker")
                                            .resizable()
                                            .frame(width: 12, height: 20)
                                            .padding()
                                        Text("Local_Watch_MarkerNone")
                                            .font(.system(size: 14, weight: .regular))
                                            .fixedSize()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationDestination(for: Int.self) { index in
                WatchMarkerDetailView(navigationPath: $navigationPath, index: index)
            }
        }
    }
}

// 여기서 marker 데이터가 있을경우 없을경우 나눠서 CellView 다르게 나오게
struct WatchMarkerListCellView: View {
    
    let data: TimeInterval
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.accent)
                .cornerRadius(4)
                .frame(height: 44)
            HStack {
                markerImage()
                markerTime()
            }
        }
    }
    
    private func markerImage() -> some View {
        Image("addedMarker")
            .resizable()
            .frame(width: 12, height: 20)
            .padding()
    }
    
    private func markerTime() -> some View {
        Text("\(formattedTime(data))")
            .font(.system(size: 14, weight: .regular))
            .fixedSize()
            .foregroundStyle(.black)
            .italic()
    }
    
    // TODO: - 중복, 기능 분리 필요 mvvm
    private func formattedTime(_ time: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: time)!
    }
}

#Preview {
    WatchMarkerListView()
}
