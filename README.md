<div align="center">

<img src="assets/shareplate_logo.png" alt="SharePlate logo" width="150" />

# SharePlate

### Smart Food Donation, Allocation & Distribution Platform

A Flutter-based mobile application designed to connect food donors, NGOs, receivers, volunteers, and administrators through a centralized donation and distribution workflow.

![Flutter](https://img.shields.io/badge/Flutter-Framework-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-Language-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase&logoColor=black)
![Status](https://img.shields.io/badge/Project-In%20Development-orange)

</div>

---

## About the Project

SharePlate is an academic mobile application project that aims to make surplus-food donation and distribution more organized. It provides a common platform for people and organizations that have food to donate and communities or organizations that need food.

The application is being developed with separate workflows for donors, NGOs, receivers, volunteers, and administrators. Firebase services are used for authentication and cloud data storage.

> **Development status:** SharePlate is currently under development. The features described below reflect the functionality present in this repository. Additional ideas such as cloth donations, machine-learning-assisted food assessment, QR-based verification, and advanced route optimization are planned concepts and are not represented as completed features in this code snapshot.

## Current Features

- **User registration and login** using Firebase Authentication.
- **Role-based navigation** for Donor, NGO, Receiver, and Volunteer accounts, with an Admin dashboard.
- **Donor workflow** to submit food donations with item details, food type, quantity, pickup information, pickup date/time, expiry information, description, and an optional image.
- **Receiver workflow** to submit food requests and view relevant donation/allocation information.
- **NGO dashboard** to review available donations and receiver requests and manage allocations.
- **Volunteer workflow** to view and accept delivery tasks and update task progress.
- **Admin dashboard** to view and manage user information.
- **Profile management** for user details.
- **Location support** using device location services where permission is granted.
- **Cloud data storage** with Cloud Firestore.

## Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform mobile application UI |
| Dart | Application programming language |
| Firebase Authentication | User registration and sign-in |
| Cloud Firestore | Cloud database for users, donations, requests, allocations, and tasks |
| Shared Preferences | Local storage for selected app/session information |
| Geolocator | Device location and location permissions |
| Image Picker | Selecting or capturing donation images |
| Google Maps Flutter package | Mapping dependency included in the project |

## User Roles

| Role | Main responsibility |
|---|---|
| Donor | Adds food donations and pickup details |
| NGO | Reviews donations and receiver requests and manages allocations |
| Receiver | Submits food requests and views allocation information |
| Volunteer | Accepts assigned delivery tasks and updates their progress |
| Admin | Views and manages user information through the admin dashboard |

## Project Structure

```text
shareplate_app/
├── android/                 # Android platform files
├── ios/                     # iOS platform files
├── assets/
│   └── shareplate_logo.png  # Application logo
├── lib/
│   ├── main.dart
│   ├── home_screen.dart
│   ├── login_screen.dart
│   ├── onboarding.dart
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
├── pubspec.yaml
└── README.md
```

## Getting Started

### Prerequisites

Install the following tools before running the project:

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart) (included with Flutter)
- [Android Studio](https://developer.android.com/studio) or [Visual Studio Code](https://code.visualstudio.com/)
- An Android emulator or a physical Android device
- A Firebase project with the required services enabled

### Installation

1. Clone this repository:

   ```bash
   git clone <YOUR_GITHUB_REPOSITORY_URL>
   ```

2. Move into the project directory:

   ```bash
   cd <PROJECT_FOLDER>
   ```

3. Install Flutter dependencies:

   ```bash
   flutter pub get
   ```

4. Configure Firebase for your own Firebase project.

   If you are using a different Firebase project, configure the Flutter app with FlutterFire CLI:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   Make sure the generated Firebase configuration matches your project. For Android, verify that the appropriate `google-services.json` file is present in `android/app/`.

5. Enable **Email/Password** sign-in in Firebase Authentication and create a Cloud Firestore database.

6. Configure Firestore Security Rules for the application's data model before testing with real users. Do not use open read/write rules in a deployed application.

7. Run the application:

   ```bash
   flutter run
   ```

### Useful Flutter Commands

```bash
# Check Flutter installation
flutter doctor

# Install dependencies
flutter pub get

# Check for code issues
flutter analyze

# Run tests
flutter test

# Build an Android APK
flutter build apk --release
```

## Firebase Configuration & Security

This project uses Firebase Authentication and Cloud Firestore. To run it with your own Firebase environment:

- Create or select a Firebase project.
- Register the required app platforms in Firebase.
- Generate the platform configuration using FlutterFire CLI.
- Enable Email/Password authentication.
- Create the Firestore database and configure access rules for the collections used by the app.

**Important:** Firebase client configuration files are included in this repository snapshot. Before publishing or reusing the project, review Firebase API-key restrictions, Firebase project settings, and Firestore Security Rules. Never commit service-account private keys, admin credentials, or other server-side secrets. Firestore rules must enforce the correct access for each user role.

## Demo

**Live demo:** Not available yet — the project is a mobile application and is still under development.

A demonstration video, screenshots, or an APK download link can be added here when they are ready.

## Screenshots

Screenshots will be added as the application UI and workflows are finalized.

<!--
To add screenshots later:
1. Create a folder named screenshots in the repository root.
2. Add your images to that folder.
3. Replace this note with Markdown image links, for example:
   ![Login screen](screenshots/login.png)
-->

## Planned Enhancements

The following are proposed extensions and should be treated as planned work until implemented and tested:

- Support for cloth donations in addition to food donations.
- Machine-learning-assisted food suitability or freshness assessment.
- QR-code-based pickup and delivery verification.
- More advanced distance- and urgency-aware allocation.
- Improved route planning and delivery tracking.
- Additional analytics and reporting.

## Academic Project Team

- Anjitha S
- Darius Joe
- Niranjan K
- Parvathy A

**Department of Computer Engineering**  
College of Engineering Chengannur  
APJ Abdul Kalam Technological University, Kerala, India

## Contributing

This repository is maintained as an academic project. Suggestions and improvements are welcome. If you plan to contribute, create a branch for your changes and submit a pull request for review.

## License

No license has been specified for this repository yet. Unless a license is added, the project should be treated as all rights reserved.

---

<div align="center">

**SharePlate — Share more. Waste less.**

</div>
