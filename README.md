<div align="center">

<img src="assets/shareplate_logo.png" alt="SharePlate logo" width="150" />

# SharePlate

### AI-Based Smart Food and Cloth Donation, Allocation & Distribution System

A Flutter mobile application project focused on connecting donors, NGOs, receivers, and volunteers to help organize donation and distribution workflows.

[![Flutter](https://img.shields.io/badge/Flutter-Mobile%20App-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-Language-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com/)
[![Status](https://img.shields.io/badge/Status-In%20Development-orange)]()

**[View GitHub Repository](https://github.com/parvathyamvk/2023-2027_BATCH_C_CSD415-Project-Phase-1_REPOSITORY)**

</div>

---

## About the Project

SharePlate is an academic project being developed to make donation and distribution activities more organized. It aims to provide a common platform where donors can offer items, receivers can submit requests, NGOs can coordinate allocation, and volunteers can support delivery.

The application is built with Flutter and Dart, with Firebase services used for authentication and cloud data storage.

> **Project status:** In development. This README describes the current project structure and intended workflows. Features may change as development continues.

## Current Project Modules

The repository contains separate screens/modules for the following roles and workflows:

- **Donor:** donor dashboard, donation form, and my donations.
- **Receiver:** receiver dashboard and request-related workflow.
- **NGO:** NGO dashboard for coordination.
- **Volunteer:** volunteer dashboard and task details.
- **Admin:** admin dashboard.
- **Account:** login, onboarding, home screen, and profile editing.

The exact availability and completeness of each workflow may change during development.

## Technology Stack

| Technology / Package | Purpose |
|---|---|
| Flutter | Cross-platform application framework |
| Dart | Programming language |
| Firebase Core | Connects the Flutter app to Firebase |
| Firebase Authentication | User authentication |
| Cloud Firestore | Cloud database |
| Google Maps Flutter | Google Maps integration |
| Geolocator | Device location access |
| Image Picker | Selecting or capturing images |
| Shared Preferences | Local key-value storage |

## Repository Structure

```text
2023-2027_BATCH_C_CSD415-Project-Phase-1_REPOSITORY/
├── android/                   # Android platform configuration
├── ios/                       # iOS platform configuration
├── assets/
│   └── shareplate_logo.png    # Application logo
├── lib/
│   ├── main.dart
│   ├── home_screen.dart
│   ├── onboarding.dart
│   ├── login_screen.dart
│   ├── donor_home.dart
│   ├── donation_form.dart
│   ├── my_donations.dart
│   ├── receiver_home.dart
│   ├── ngo_home.dart
│   ├── volunteer_home.dart
│   ├── volunteer_task_details.dart
│   ├── admin_home.dart
│   ├── edit_profile.dart
│   └── firebase_options.dart
├── Reports/                   # Project reports and presentation
├── pubspec.yaml               # Flutter dependencies and assets
├── firebase.json
└── README.md
```

## Getting Started

### Prerequisites

Install the following:

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Android Studio](https://developer.android.com/studio) or [Visual Studio Code](https://code.visualstudio.com/)
- Android emulator or a physical Android device
- A Firebase project configured for your application

### 1. Clone the Repository

```bash
git clone https://github.com/parvathyamvk/2023-2027_BATCH_C_CSD415-Project-Phase-1_REPOSITORY.git
```

### 2. Open the Project Folder

```bash
cd 2023-2027_BATCH_C_CSD415-Project-Phase-1_REPOSITORY
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Configure Firebase

This project uses Firebase. To connect your own Firebase project:

1. Create a project in the [Firebase Console](https://console.firebase.google.com/).
2. Register the required Android/iOS app(s) in Firebase.
3. Configure FlutterFire for your Firebase project:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

4. Verify that the generated `lib/firebase_options.dart` matches your Firebase project.
5. Enable the authentication providers required by the app.
6. Create and configure Cloud Firestore.

**Security note:** Review Firestore Security Rules before testing with real users or deploying. Do not use unrestricted read/write rules in a production application. Do not publish service-account private keys or other server-side credentials.

### 5. Run the Application

```bash
flutter run
```

## Useful Flutter Commands

```bash
# Check Flutter and development environment
flutter doctor

# Get project dependencies
flutter pub get

# Analyze the project
flutter analyze

# Run tests
flutter test

# Build a release APK
flutter build apk --release
```

## Demo

**Live demo:** Not available yet. SharePlate is a mobile application and is currently under development.

A demo video, screenshots, or an APK download link can be added here when they are ready.

## Screenshots

Screenshots will be added as the application screens and workflows are finalized.

To add screenshots later, create a `screenshots/` folder in the repository and add images. Then include them here, for example:

```markdown
![Login Screen](screenshots/login.png)
```

## Planned Enhancements

The following are project directions that may be implemented as development progresses:

- Support for food and cloth donations.
- AI-assisted assessment or allocation features.
- QR-code-based pickup and delivery verification.
- Improved location-aware allocation and route planning.
- Enhanced delivery tracking and reporting.

These are planned enhancements and should not be considered completed features unless they are implemented in the application.

## Team

- **Anjitha S**
- **Darius Joe**
- **Niranjan K**
- **Parvathy A**

**Department of Computer Engineering**  
College of Engineering Chengannur  
APJ Abdul Kalam Technological University, Kerala, India

## License

No license has been specified for this repository. Unless a license is added, all rights remain with the copyright holder.

---

<div align="center">

**SharePlate — Making donation and distribution more organized.**

</div>
