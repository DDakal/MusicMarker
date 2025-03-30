//
//  View+.swift
//  DancingMarker
//
//  Created by Woowon Kang on 3/30/25.
//

import SwiftUI

struct SwipeBackModifier: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        DispatchQueue.main.async {
            if let navController = viewController.navigationController {
                navController.interactivePopGestureRecognizer?.delegate = context.coordinator
                navController.interactivePopGestureRecognizer?.isEnabled = true
            }
        }
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}

extension View {
    func enableSwipeBack() -> some View {
        self.background(SwipeBackModifier())
    }
}
