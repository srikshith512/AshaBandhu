# ASHA Bandhu - Setup Guide

## Prerequisites

Ensure you have the following installed:
- **Flutter SDK** (version 3.0.0 or higher)
- **Dart SDK** (comes with Flutter)
- **Android Studio** or **VS Code** with Flutter extensions
- **Android SDK** for building Android apps

## Installation Steps

### 1. Navigate to Project Directory

```bash
cd "c:\Users\srikshith rao\OneDrive\Projects\ASHA Bandhu"
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Check Flutter Setup

```bash
flutter doctor
```

Fix any issues reported by `flutter doctor` before proceeding.

### 4. Run the App

For development:
```bash
flutter run
```

For specific device:
```bash
flutter devices  # List available devices
flutter run -d <device-id>
```

### 5. Build for Production

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle (for Play Store):**
```bash
flutter build appbundle --release
```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── constants/
│   ├── app_colors.dart         # Color palette
│   └── app_theme.dart          # Theme configuration
├── models/
│   ├── patient_model.dart      # Patient data model
│   ├── worker_model.dart       # Worker data model
│   └── conflict_model.dart     # Conflict data model
├── providers/
│   ├── auth_provider.dart      # Authentication state
│   ├── patient_provider.dart   # Patient data state
│   └── sync_provider.dart      # Sync state
├── screens/
│   ├── auth/                   # Authentication screens
│   ├── asha/                   # ASHA worker screens
│   └── phc/                    # PHC staff screens
├── services/
│   ├── api_service.dart        # API communication
│   └── hive_service.dart       # Local database setup
├── widgets/                    # Reusable UI components
└── utils/                      # Utility functions
```

## Testing the App

### Test Credentials

**ASHA Worker:**
- Worker ID: `ASHA001`
- Password: (any password you set during registration)
- PIN: (4-digit PIN you set)
- Role: ASHA Worker

**PHC Staff:**
- Worker ID: `PHC001`
- Password: (any password you set during registration)
- PIN: (4-digit PIN you set)
- Role: PHC Staff

### First Time Setup

1. Launch the app
2. Select your role (ASHA Worker or PHC Staff)
3. Fill in registration details:
   - Worker ID (e.g., ASHA001)
   - Password (min 6 characters)
   - Full Name
   - Village/Area
   - 4-digit PIN (for quick access)
4. Click "Login & Create PIN"

## Features Overview

### ASHA Worker Features
- ✅ View patient dashboard with stats
- ✅ Add/Edit/Delete patients
- ✅ Search patients by name or village
- ✅ View overdue visit alerts
- ✅ Sync data with server
- ✅ Offline-first data storage
- 🚧 QR code scanning (placeholder)
- 🚧 Voice-based form filling (placeholder)
- 🚧 OCR document scanning (placeholder)

### PHC Staff Features
- ✅ View analytics dashboard
- ✅ Monitor all patients across ASHAs
- ✅ Resolve data conflicts
- ✅ View system integration status
- ✅ Manage pending approvals

## Backend Integration

The app is currently configured for **offline-first** operation. To integrate with a real backend:

1. **Update API Base URL** in `lib/services/api_service.dart`:
   ```dart
   static const String baseUrl = 'https://your-api-url.com';
   ```

2. **Implement Authentication Token Storage**
   - Store JWT tokens securely
   - Add token to API request headers

3. **Configure ABDM Integration**
   - Add ABDM API credentials
   - Implement FHIR resource mapping

4. **Setup Background Sync**
   - Configure WorkManager for periodic sync
   - Handle conflict resolution

## Adding Sample Data

To test with sample patients, you can use the sample data generator:

1. Open `lib/utils/sample_data.dart`
2. The `SampleData.generateSamplePatients()` method creates sample patients
3. Call this in your development environment to populate test data

## Troubleshooting

### Common Issues

**1. Build errors with Hive**
```bash
# The Hive adapters are already generated
# If you modify models, regenerate with:
flutter pub run build_runner build --delete-conflicting-outputs
```

**2. Package conflicts**
```bash
flutter clean
flutter pub get
```

**3. Android build issues**
```bash
cd android
./gradlew clean
cd ..
flutter build apk
```

**4. Hot reload not working**
- Restart the app completely
- Check if there are syntax errors

### Performance Optimization

For low-end devices:
- The app is already optimized with offline-first architecture
- Uses lightweight Hive database instead of SQLite
- Lazy loading for patient lists
- Minimal animations

## Next Steps

1. **Implement Voice Recognition**
   - Configure regional language support
   - Download offline STT models

2. **Add OCR Functionality**
   - Train custom TFLite model for form recognition
   - Integrate with camera

3. **Setup QR Code Scanning**
   - Configure ABHA ID verification
   - Implement QR code generation

4. **Backend Development**
   - Setup Node.js/Express API
   - Configure PostgreSQL database
   - Implement FHIR mapping

5. **Testing**
   - Add unit tests
   - Add integration tests
   - Conduct field testing with ASHA workers

## Support

For issues or questions:
- Check the README.md for general information
- Review code comments for implementation details
- Test on actual Android devices for real-world performance

## License

This project is part of a healthcare innovation initiative.
