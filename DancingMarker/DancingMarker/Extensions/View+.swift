//
//  View+.swift
//  DancingMarker
//
//  Created by Woowon Kang on 3/30/25.
//

import SwiftUI

struct EnableSwipeBack: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(EnableSwipeBackRepresentable())
    }
}

private struct EnableSwipeBackRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        DispatchQueue.main.async {
            if let nav = controller.parentNavigationController {
                nav.interactivePopGestureRecognizer?.delegate = context.coordinator
                nav.interactivePopGestureRecognizer?.isEnabled = true
            }
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            // 뒤로가기 제스처가 항상 동작하도록 허용
            return true
        }
    }
}

// UINavigationController를 안전하게 찾는 extension
private extension UIViewController {
    var parentNavigationController: UINavigationController? {
        var parentVC = self.parent
        while parentVC != nil {
            if let nav = parentVC as? UINavigationController {
                return nav
            }
            parentVC = parentVC?.parent
        }
        return nil
    }
}

extension View {
    func enableSwipeBack() -> some View {
        self.modifier(EnableSwipeBack())
    }
}
