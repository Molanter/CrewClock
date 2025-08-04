# ⏳ CrewClock

CrewClock is a SwiftUI-based time tracking app designed specifically for contract workers and small teams. It offers an intuitive interface to clock in/out, organize work by projects, and store time logs securely using Firebase.

---

## 🚀 Features

* 🔐 **Google Sign-In** for fast and secure login
* 🗕️ **Weekly Timesheet View** for easy time tracking
* ✍️ **Project-Based Logging** — log hours per project or task
* ☁️ **Firebase Integration** — real-time sync and cloud storage
* 🔔 **FCM Notifications** for invites and updates
* 🌙 Clean, modern UI built with **SwiftUI**
* 🔄 Offline-ready with local caching (planned)

---

## 📸 Screenshots

> *Coming soon — UI previews and flow diagrams*

---

## 🧑‍💻 Technologies

* **SwiftUI** for modern, declarative UI
* **Firebase Auth** for user authentication (Google Sign-In)
* **Firestore** for project/time log storage
* **Firebase Cloud Functions** for backend automation
* **Firebase Cloud Messaging (FCM)** for push notifications

---

## 📦 Folder Structure (WIP)

```
CrewClock/
├── Models/           # Data models (Project, Log, User, Notification)
├── Views/            # SwiftUI views for each feature/screen
├── ViewModels/       # Business logic and Firebase interaction
├── Services/         # Firebase, Notifications, and Utility services
└── Resources/        # Assets, Extensions, Constants
```

---

## 💠 Setup Instructions

1. **Clone the repo:**

```bash
git clone https://github.com/Molanter/CrewClock.git
cd CrewClock
```

2. **Install dependencies:**

   * Xcode 15+
   * Firebase SDK (via Swift Package Manager)

3. **Configure Firebase:**

   * Create a Firebase project
   * Download `GoogleService-Info.plist` and add it to your Xcode project
   * Enable: Authentication (Google), Firestore, Cloud Messaging

4. **Run the app:**

   * Open `CrewClock.xcodeproj`
   * Build and run on a simulator or device

---

## 🤝 Contributing

Contributions, ideas, and feedback are welcome!
To contribute:

1. Fork the repo
2. Create a branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "Add your feature"`
4. Push and open a Pull Request

---

## 📬 Contact

Have questions or want to collaborate?

* GitHub: [Molanter](https://github.com/Molanter)
* Email: \[e.yarmolatiy@gmail.com]

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
