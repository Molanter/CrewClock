//
//  OnboardingView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 8/5/25.
//


import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    @Binding var isShowing: Bool
    
    @State private var currentPage: Int = 0
    
    @State private var showPolicy: Bool = false
    @State private var showTermsOfUse: Bool = false
    
    private let pages = OnBoardingPages.allCases
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \ .self) { idx in
                    page(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .interactive))
            
            footerButtons
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .sheet(isPresented: $showPolicy) {
            WebView(url: K.Links.privacyPolicy).edgesIgnoringSafeArea(.bottom).tint(K.Colors.accent)
        }
        .sheet(isPresented: $showTermsOfUse) {
            WebView(url: K.Links.termsOfUse).edgesIgnoringSafeArea(.bottom).tint(K.Colors.accent)
        }
    }
    
    private var footerButtons: some View {
        HStack {
            if currentPage < pages.count - 1 {
                Button("Skip") { dismiss() }
                    .padding(.leading)
            }
            Spacer()
            Button(currentPage == pages.count - 1 ? "Get Started" : "Next") {
                if currentPage < pages.count - 1 {
                    currentPage += 1
                } else {
                    dismiss()
                }
            }
            .padding(.trailing)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground).opacity(0.8))
    }
    
    @ViewBuilder
    private func page(_ idx: Int) -> some View {
        Group {
            let page = pages[idx]
            VStack(spacing: 24) {
                Spacer()
                Text(page.image)
                    .font(.system(size: 80))
                Text(page.title)
                    .font(.title.bold())
                Text(page.text)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                Spacer()
                footerPS(page: page)
            }
            .padding()
            .tag(idx)
        }
    }
    
    @ViewBuilder
    private func footerPS(page: OnBoardingPages) -> some View {
        Group {
            if page == .welcome {
                welcomePS
            }else {
                Text("PS: \(page.ps)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(alignment: .center)
                    .padding(.bottom, K.UI.padding*2)
            }
        }
    }
    
    private var welcomePS: some View {
        HStack(spacing: 0) {
            Text("By continuing, you agree to our ")
                .foregroundColor(.secondary)
            
            Text("Privacy Policy")
                .underline()
                .foregroundColor(K.Colors.accent)
                .onTapGesture {
                    showPolicy.toggle()
                }
            
            Text(" and ")
                .foregroundColor(.secondary)
            
            Text("Terms of Use")
                .underline()
                .foregroundColor(K.Colors.accent)
                .onTapGesture {
                    self.showTermsOfUse.toggle()
                }
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .frame(alignment: .center)
        .padding(.bottom, K.UI.padding*2)
    }
    
    private func dismiss() {
        isShowing = false
        hasSeenOnboarding = true
    }
}
