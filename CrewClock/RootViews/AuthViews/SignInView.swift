import SwiftUI

struct SignInView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewModel: AuthViewModel
    @FocusState private var focus: LoginField?

    @State private var email = ""
    @State private var password = ""
    @State private var emailEmpty = false
    @State private var passwordEmpty = false
    @State private var showEmailSignIn = false

    private var sheetStrokeColor: Color {
        colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.3)
    }

    private var dvdImage: Image? {
        // Prevent preview crash when the asset is missing in the preview bundle
        #if canImport(UIKit)
        if UIImage(named: "dvd.logo") == nil { return nil }
        #endif
        return Image("dvd.logo")
    }

    private var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Preview-safe background: animation schedule is lighter for previews
            DVDScreensaverBackground(
                image: Image("dvd.logo"),
                logoSize: .init(width: 110, height: 80),
                speed: 125,
                background: colorScheme == .dark ? .black : .white,
                useAnimationSchedule: isPreview // true for previews
            )

            sheet
                .background {
                    ZStack {
                        // Guard custom blur in previews to avoid crashes on some Xcode builds
                        GlassBlur(removeAllFilters: false, blur: 5)
                            .cornerRadius(K.UI.cornerRadius)

                        UnevenRoundedRectangle(
                            topLeadingRadius: K.UI.cornerRadius,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: K.UI.cornerRadius,
                            style: .continuous
                        )
                        .stroke(sheetStrokeColor, lineWidth: 1.5)
                        .mask(
                            LinearGradient(stops: [
                                .init(color: .white, location: 0.0),
                                .init(color: .white, location: 0.98),
                                .init(color: .clear, location: 1.0)
                            ], startPoint: .top, endPoint: .bottom)
                        )
                    }
                }
                .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea()
    }

    // MARK: - Subviews
    private var sheet: some View {
        VStack(spacing: K.UI.padding) {
            welcomeText
            if showEmailSignIn {
                emailField
                passwordField
                mainButton
            }
            buttons
        }
        .padding(K.UI.padding * 2)
    }

    private var welcomeText: some View {
        VStack(spacing: 5) {
            Text("Welcome to:").foregroundStyle(.secondary)
            Text("Crew's Clock").font(.title.bold())
            Text("Sign In to use the app features.").foregroundStyle(.secondary)
                .padding(.bottom, K.UI.padding*2)
        }
    }

    private var emailField: some View {
        VStack {
            HStack { Text("Email"); Spacer() }
            RoundedTextField(
                focus: $focus,
                text: $email,
                field: .loginEmail,
                promtText: "email@example.com",
                submitLabel: .next,
                onSubmit: { focus = .loginPass },
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                showRed: $emailEmpty
            )
        }
    }

    private var passwordField: some View {
        VStack {
            HStack { Text("Password"); Spacer() }
                .padding(.top, K.UI.padding)
            RoundedTextField(
                focus: $focus,
                text: $password,
                field: .loginPass,
                promtText: "••••••••••••",
                submitLabel: .continue,
                onSubmit: {},
                keyboardType: .default,
                textContentType: .password,
                showRed: $passwordEmpty
            )
        }
    }

    private var mainButton: some View {
        SignInButtonView(text: "SignIn", image: "", colored: true) { emailSignIn() }
    }

    private var buttons: some View {
        VStack(spacing: K.UI.padding) {
            if !showEmailSignIn {
                SignInButtonView(text: "Continue with Email", image: "envelope", colored: false) {
                    withAnimation(.easeInOut) { showEmailSignIn.toggle() }
                }
                .bold()
            }
            SignInButtonView(text: "Continue with Apple", image: "apple.logo", colored: false) {
                viewModel.handleAppleSignIn()
            }
            SignInButtonView(text: "Continue with Google", image: "google.g.logo", colored: false) {
                viewModel.signInWithGoogle()
            }
        }
    }

    private func emailSignIn() {
        guard !email.isEmpty, !password.isEmpty else {
            emailEmpty = email.isEmpty
            passwordEmpty = password.isEmpty
            return
        }
        emailEmpty = false
        passwordEmpty = false
        viewModel.signInWithEmail(email: email, password: password) { result in
            switch result {
            case .success(let user): print("Signed in as \(user.email ?? "")")
            case .failure(let error): print("Error signing in: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Preview
#Preview("Light") {
    SignInView()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SignInView()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
}
