//
//  RoundedTextField.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/31/25.
//

import SwiftUI

struct RoundedTextField: View {
    var focus: FocusState<LoginField?>.Binding
    @Binding var text: String
    var field: LoginField
    var promtText: String
    var submitLabel: SubmitLabel = .next
    var onSubmit: (() -> Void)? = nil
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    @Binding var showRed: Bool
    
    var body: some View {
        TextField(promtText, text: $text)
            .submitLabel(submitLabel)
            .focused(focus, equals: field)
            .disableAutocorrection(true)
            .textInputAutocapitalization(.never)
            .keyboardType(keyboardType)
            .textContentType(textContentType)
            .onSubmit { onSubmit?() }
            .padding(K.UI.padding)
            .background {
                if showRed {
                    TransparentBlurView(removeAllFilters: false)
                        .blur(radius: 5, opaque: true)
                        .background(.red.opacity(0.15))
                        .cornerRadius(K.UI.cornerRadius)
                }else {
                    GlassBlur(removeAllFilters: false)
                        .cornerRadius(K.UI.cornerRadius)
                }
            }
    }
}
