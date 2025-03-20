//
//  SelectGalleryView.swift
//  DancingMarker
//
//  Created by Woowon Kang on 3/21/25.
//

import SwiftUI

struct SelectGalleryView: UIViewControllerRepresentable {
    @Binding var selectedImgData: Data?

        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.navigationBar.isTranslucent = false
            picker.sourceType = .photoLibrary
            picker.delegate = context.coordinator
            return picker
        }

        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
            var galleryPicker: SelectGalleryView

            init(_ parent: SelectGalleryView) {
                self.galleryPicker = parent
            }

            func imagePickerController(
                _ picker: UIImagePickerController,
                didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
            ) {
                picker.dismiss(animated: true)
                
                // 이미지 선택 시 정방형으로 크롭 후 jpeg 압축
                guard let image = info[.originalImage] as? UIImage,
                      let croppedImage = image.croppedToSquare() else {
                    print("이미지 크롭, 압축 실패")
                    return
                }
                galleryPicker.selectedImgData = croppedImage.jpegData(compressionQuality: 0.2)
            }

            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                picker.dismiss(animated: true)
            }
        }
    
}
