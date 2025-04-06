
import SwiftUI

struct WatchPlayingSpeedView: View {
    
    @EnvironmentObject var viewModel: WatchViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            // MARK: - 버튼
            HStack {
                Text("-")
                    .font(.system(size: 17, weight: .regular))
                    .fixedSize()
                    .foregroundStyle(viewModel.speed < 0.55 ? .inactiveGray : .white) // 0.5배가 되면 Gray색상으로
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(.gray.opacity(0.2))
            .clipShape(RoundedCorner(radius: 4, corners: [.topLeft, .bottomLeft]))
            .onTapGesture {
                print("Tapped: 배속 - 버튼눌렀습니다.")
                viewModel.decreasePlaybackRate()
            }
            .disabled(viewModel.speed < 0.55) // 배속이 0.5 이하일 때 버튼 비활성화
            
            // MARK: 배속 Text & 원배로 돌아가는 버튼
            HStack {
                Text(String(format: "%.1fx", viewModel.speed))
                    .font(.system(size: 17, weight: .regular))
                    .fixedSize()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(.gray.opacity(0.2))
            .onTapGesture {
                print("Tapped: 원배 버튼눌렀습니다.")
                viewModel.originalPlaybckRate()
            }
            
            // MARK: + 버튼
            HStack {
                Text("+")
                    .font(.system(size: 17, weight: .regular))
                    .fixedSize()
                    .foregroundStyle(viewModel.speed > 1.45 ? .inactiveGray : .white) // 1.5배가 되면 Gray색상으로
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(.gray.opacity(0.2))
            .clipShape(RoundedCorner(radius: 4, corners: [.topRight, .bottomRight]))
            .onTapGesture {
                print("Tapped: 배속 + 버튼눌렀습니다.")
                viewModel.increasePlaybackRate()
            }
            .disabled(viewModel.speed > 1.45) // 배속이 1.5 이상일 때 버튼 비활성화
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom)
    }
}

// MARK: View -> 특정 모서리만 둥글게
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    WatchPlayingSpeedView()
}
