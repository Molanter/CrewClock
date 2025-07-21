# 🕒 CrewClock

**CrewClock** is a time-tracking and project management app designed for crews working on various projects. It helps teams track working hours, manage project checklists, and organize crews efficiently.

Built with **SwiftUI** and **Firebase** (Firestore, Authentication, Cloud Functions) and integrated with **Google Sheets** for optional reporting.

---

## 🚀 Features

✅ Track project progress with customizable checklists
✅ Assign crews to projects
✅ Track time logs with start and end times
✅ Store data securely with Firebase
✅ Optional sync with Google Sheets for reporting
✅ Modern and clean SwiftUI interface
✅ User-friendly project and log management
✅ Support for Google Sign-In

---

## 📂 Project Structure

```
CrewClock
├── Models
│   ├── UserModel.swift
│   ├── ProjectModel.swift
│   └── LogModel.swift
├── ViewModels
│   ├── UserViewModel.swift
│   ├── ProjectViewModel.swift
│   └── LogsViewModel.swift
├── Views
│   ├── Main Tab Views
│   ├── ProjectLookView.swift
│   ├── AddLogView.swift
│   └── AddProjectView.swift
└── Utilities
    ├── ProjectColorHelper.swift
    ├── FirebaseManager.swift
    └── Constants.swift
```

---

## 🛠️ Technologies

- **SwiftUI**
- **Firebase Firestore**
- **Firebase Authentication**
- **Firebase Cloud Functions**
- **Google Sheets API**
- **MVVM Architecture**

---

## 🔧 Setup

1. Clone this repository:
```bash
git clone https://github.com/Molanter/CrewClock.git
```

2. Open `CrewClock.xcodeproj` in Xcode.

3. Configure Firebase:
   - Add your `GoogleService-Info.plist`
   - Ensure Firestore, Auth, and Functions are enabled.

4. Configure Google Sheets API (if desired):
   - Set up your Cloud Function with your Google Service Account.

---

## 💡 Future Plans

- Admin dashboard for managing crews and logs
- Analytics dashboard for project insights
- Push notifications for shift changes or deadlines
- iCloud support as an alternative to Firebase

---

## ✨ Screenshots

<!--  screenshots here to showcase UI._ -->

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
