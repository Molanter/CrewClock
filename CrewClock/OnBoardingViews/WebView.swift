//
//  WebView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 8/5/25.
//

import SwiftUI
import WebKit

struct WebView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    let url: URL

    
    var body: some View {
        Text(url.absoluteString)
            .onAppear {
                if #available(iOS 26.0, *) {
                    openURL(url, prefersInApp: true)
                    dismiss()
                } else {
                    UIApplication.shared.open(url)
                }
            }
    }
//    func makeUIView(context: Context) -> WKWebView {
//        return WKWebView()
//    }
//
//    func updateUIView(_ webView: WKWebView, context: Context) {
//        let request = URLRequest(url: url)
//        webView.load(request)
//    }
}
