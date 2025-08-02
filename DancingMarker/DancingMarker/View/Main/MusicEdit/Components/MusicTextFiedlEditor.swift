//
//  MusicTextFiedlEditor.swift
//  DancingMarker
//
//  Created by Woowon Kang on 8/1/25.
//

import SwiftUI

struct MusicTextFieldEditor: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack {
                TextField(placeholder, text: $text)
                    .frame(height: 34)
                    .background(.clear)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                
                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
