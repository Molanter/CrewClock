//
//  LoggedInView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 5/28/25.
//

import SwiftUI
import GoogleSignIn

struct LoggedInView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @EnvironmentObject var sheetViewModel: SpreadSheetViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("👤 User Info")
                .font(.title2)

            if let name = viewModel.userName {
                Text("Name: \(name)")
            }
            if let email = viewModel.userEmail {
                Text("Email: \(email)")
            }

            Button("Log Out") {
                viewModel.signOut()
            }
            .foregroundColor(.red)
            .padding(.top)

            Divider()
                .padding(.vertical)

            Text("🔗 Add your Google Spreadsheet URL")
                .font(.headline)

            TextField("Paste Spreadsheet URL here", text: $sheetViewModel.spreadsheetUrl)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button("Submit") {
                if !sheetViewModel.spreadsheetUrl.isEmpty {
                    if let id = extractSpreadsheetId(from: sheetViewModel.spreadsheetUrl) {
                        sheetViewModel.saveSpreadsheetId(id: id)
                    } else {
                        sheetViewModel.errorMessage = "❌ Invalid spreadsheet URL."
                    }
                } else {
                    sheetViewModel.fetchSavedSpreadsheetId { id in
                        if let existingId = id {
                            print("✅ Using saved spreadsheet ID: \(existingId)")
                            sheetViewModel.submitLog()
                        } else {
                            sheetViewModel.errorMessage = "❌ Please paste a spreadsheet URL first."
                        }
                    }
                }
            }
            .padding(.top)
            
            if let errorMessage = sheetViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.top, 5)
            }
        }
        .padding()
    }

    func extractSpreadsheetId(from url: String) -> String? {
        guard let range = url.range(of: "/d/") else { return nil }
        let afterD = url[range.upperBound...]
        return afterD.split(separator: "/").first.map(String.init)
    }
}

#Preview {
    LoggedInView()
}
