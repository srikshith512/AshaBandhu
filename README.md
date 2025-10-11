<<<<<<< HEAD
# ASHA Bandhu

A Flutter-based offline-first health application for ASHA workers and PHC staff, designed to digitize rural healthcare delivery with advanced features like voice-based form filling, OCR auto-fetch, and AI-driven priority alerts.

## Features

### ASHA Worker Features
- Offline-first patient data management
- Voice-based form filling with regional language support
- QR code scanning for ABHA ID verification
- AI-driven priority alerts for high-risk cases
- Automatic background sync when connectivity is restored
- Visit reminders and scheduling

### PHC Staff Features
- Real-time dashboard with analytics
- Patient data oversight and approval
- Conflict resolution for data discrepancies
- System integration monitoring
- Geographical health heatmaps

## Tech Stack

### Frontend (Flutter/Dart)
- **Framework**: Flutter with Dart
- **State Management**: Provider
- **Local Storage**: Hive (fast NoSQL database)
- **Voice Recognition**: speech_to_text plugin
- **OCR**: TensorFlow Lite for offline OCR
- **AI Models**: TensorFlow Lite for risk prediction
- **QR Scanning**: mobile_scanner
- **Background Sync**: WorkManager

### Backend (Node.js/Express)
- **API Server**: Node.js with Express.js
- **Database**: PostgreSQL with PostGIS
- **FHIR Compliance**: Custom ABDM integration
- **Authentication**: JWT with bcrypt
- **Analytics Dashboard**: React.js/Next.js


## Project Structure

```
lib/
├── main.dart
├── models/          # Data models and Hive adapters
├── providers/       # State management providers
├── screens/         # UI screens
│   ├── auth/       # Authentication screens
│   ├── asha/       # ASHA worker screens
│   └── phc/        # PHC staff screens
├── widgets/         # Reusable UI components
├── services/        # Business logic and API services
├── utils/           # Utilities and helpers
└── constants/       # App constants and themes
## Offline-First Architecture

The app uses Hive for local storage and implements a robust sync mechanism:
1. All data operations work offline by default
2. Changes are tracked with timestamps and version numbers
3. Background WorkManager handles sync when connectivity is restored
4. Conflict resolution at PHC level for data discrepancies

## ABDM/FHIR Compliance

The backend implements ABDM-compliant FHIR resource mapping for:
- Patient demographics
- Vital observations (BP, hemoglobin, etc.)
- Immunization records
- ANC/PNC care records

## License

This project is part of a healthcare innovation initiative.
=======
# AshaBandhu
>>>>>>> 5e90fa0e2f8801ec49974eca679d7acf82f70393
