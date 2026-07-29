# MediConnect - Telemedicine & Diagnostic Management System

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Integrated-FFCA28?logo=firebase)](https://firebase.google.com)
[![Python Flask](https://img.shields.io/badge/Flask-Admin_Portal-000000?logo=flask)](https://flask.palletsprojects.com/)
[![AI Assistant](https://img.shields.io/badge/MediBot-Gemini_AI-8E44AD?logo=google)](https://ai.google.dev/)
[![License](https://img.shields.io/badge/License-Academic_Defense-green)](#)

MediConnect is a comprehensive, production-grade Telemedicine and Diagnostic Management platform built with **Flutter**, **Firebase**, **Python Flask**, and **Google Gemini AI**. The platform seamlessly bridges the gap between **Patients**, **Doctors**, **Diagnostic Centres**, and **System Administrators**, offering real-time appointment booking, AI-assisted health triage, interactive lab test management, automated PDF report generation, and official credential verification.

---

## 📑 Table of Contents

- [System Architecture & Stack](#-system-architecture--stack)
- [Key Features by User Role](#-key-features-by-user-role)
  - [1. Patient Portal](#1-patient-portal)
  - [2. Doctor Portal](#2-doctor-portal)
  - [3. Diagnostic Centre Portal](#3-diagnostic-centre-portal)
  - [4. Admin Verification Portal](#4-admin-verification-portal)
- [Lab Test Sequential Lifecycle](#-lab-test-sequential-lifecycle)
- [Project Directory Structure](#-project-directory-structure)
- [Data Models & Schema](#-data-models--schema)
- [AI Health Assistant (MediBot)](#-ai-health-assistant-medibot)
- [Health Monitoring & Smart Wearable Integration](#-health-monitoring--smart-wearable-integration)
- [Installation & Setup Guide](#-installation--setup-guide)
  - [Mobile & Web Application (Flutter)](#mobile--web-application-flutter)
  - [Admin Verification Web App (Python Flask)](#admin-verification-web-app-python-flask)
- [Academic Defense & Presentation Summary](#-academic-defense--presentation-summary)

---

## 🏗 System Architecture & Stack

MediConnect uses a modular, decoupled architecture following clean design principles and role-based access control (RBAC).

```
                      ┌─────────────────────────────────────────┐
                      │              MediConnect                │
                      └────────────────────┬────────────────────┘
                                           │
         ┌───────────────────┬─────────────┴───────┬────────────────────┐
         │                   │                     │                    │
┌────────▼────────┐ ┌────────▼────────┐ ┌──────────▼─────────┐ ┌─────────▼────────┐
│  Patient App    │ │   Doctor App    │ │ Diagnostic Centre │ │ Admin Web Portal │
│ (Flutter Multi) │ │ (Flutter Multi) │ │  (Flutter Multi)  │ │  (Python Flask)  │
└────────┬────────┘ └────────┬────────┘ └──────────┬──────────┘ └────────┬────────┘
         │                   │                     │                     │
         └───────────────────┴──────────┬──────────┴─────────────────────┘
                                        │
                         ┌──────────────▼──────────────┐
                         │   Firebase Cloud Backend    │
                         │ ├─ Firebase Authentication  │
                         │ ├─ Cloud Firestore DB       │
                         │ └─ Firebase Storage         │
                         └──────────────┬──────────────┘
                                        │
                         ┌──────────────▼──────────────┐
                         │   Google Gemini 1.5 Flash   │
                         │ (MediBot AI Health Engine)  │
                         └─────────────────────────────┘
```

### Technology Highlights
- **Frontend**: Flutter 3.x (Dart), Material Design 3, Provider State Management, Google Fonts (Plus Jakarta Sans).
- **Backend & Cloud Services**: Firebase Authentication, Cloud Firestore (Real-time DB), Firebase Storage (Encrypted Base64/PDF Storage).
- **AI Integration**: Google Gemini API via `ChatbotService` for intelligent patient symptom analysis, doctor recommendations, and triage.
- **Document Engine**: Custom PDF compilation pipeline via `pdf` and `printing` packages supporting high-resolution lab reports and digital prescriptions with interactive in-app previewers (`PdfPreview`).
- **Admin Backend**: Python Flask with REST endpoints and Bootstrap HTML5 portal.

---

## ✨ Key Features by User Role

### 1. Patient Portal
- **Dashboard & Search**: Real-time doctor search filtered by specialization, rating, hospital affiliation, and consultation fees.
- **MediBot AI Assistant**: Interactive AI assistant that evaluates patient symptoms, answers medical queries, and suggests appropriate specialists.
- **Appointment Booking**: Calendar slot picker supporting online digital payment, manual cash on visit, or pay-later options.
- **Digital Prescriptions**: Upload and view prescriptions in interactive PDF format (`PdfPreview`). Camera/image fallbacks replaced with clean, dedicated PDF handling.
- **Lab Test Booking & Tracking**: Book lab tests with home sample collection or center walk-in options. Real-time stage tracking (`Pending` → `Collector Assigned` → `Sample Collected` → `Report Issued`).
- **Vital Health Monitoring**: Real-time heart rate and blood pressure monitoring widget with color-coded warning thresholds (High/Normal/Low) refreshing dynamically.
- **Emergency Ambulance**: One-tap ambulance request for Basic, ICU, and Neonatal emergency transport with pickup/drop-off routing.
- **Family Member Management**: Add and manage profiles for family members to book appointments and track medical history on their behalf.

### 2. Doctor Portal
- **Executive Dashboard**: Daily appointment queue, patient statistics, total earnings metrics, and quick action cards.
- **BMDC Verification Flow**: Secure signup requiring official **BMDC Registration Number**. Profile status remains `Pending Verification` until verified by Administrator.
- **Digital Prescription Writer**: Build prescriptions with favorite medicine templates, custom dosages, diagnostic test recommendations, and auto-compiled downloadable PDF outputs.
- **Schedule Management**: Configure weekly availability, custom time slots, and toggle slot lockouts.
- **Patient Electronic Health Records (EHR)**: Request and review patient medical history, previous diagnoses, and attached lab test PDFs.
- **Diagnostic Referrals**: Send direct lab test orders to verified diagnostic centers for patient testing.

### 3. Diagnostic Centre Portal
- **DGHS & Pathologist Verification**: Verified using **DGHS License Code** and **Pathologist BMDC Registration Number**.
- **Test Catalog & Dynamic Pricing**: Add, edit, and manage tests offered (e.g., CBC, Lipid Profile, Dengue NS1), custom test pricing, preparation instructions (e.g., 12-hour fasting), and Turnaround Time (TAT).
- **Sequential Sample & Report Pipeline**: Strict stage-gated workflow preventing unauthorized report generation prior to sample processing.
- **Interactive Result Entry**: Input exact numerical test measurements, reference ranges, and pathologist remarks into custom form modals prior to generating official PDFs.
- **Report Preview & Issuance**: Preview compiled lab test PDF reports before finalizing and delivering them directly to the patient's mobile app.

### 4. Admin Verification Portal
- **Official Credentials Audit**: Dedicated Python Flask Web Portal for administrators to inspect submitted BMDC doctor numbers and DGHS diagnostic codes.
- **One-Click Approval/Rejection**: Instantly verify or reject healthcare providers, updating Firestore records in real-time.
- **Security Audit Logs**: Track platform activity, user roles, and verification status across all system entities.

---

## 🔄 Lab Test Sequential Lifecycle

MediConnect enforces a strict 5-stage sequential pipeline for all diagnostic procedures:

```
┌─────────────┐     ┌──────────────┐     ┌────────────────────┐     ┌──────────────────┐     ┌─────────────┐
│ 1. PENDING  ├────►│ 2. APPROVED  ├────►│ 3. COLLECTOR       ├────►│ 4. SAMPLE        ├────►│ 5. REPORT   │
│   Patient   │     │ Centre accepts│    │    ASSIGNED        │     │    COLLECTED     │     │    ISSUED   │
│  books test │     │ order        │     │ Staff assigned     │     │ Results entered  │     │ PDF to app  │
└─────────────┘     └──────────────┘     └────────────────────┘     └──────────────────┘     └─────────────┘
```

1. **Pending**: Patient submits test request choosing Home Collection or Center Walk-In.
2. **Approved**: Diagnostic centre reviews and approves the request.
3. **Collector Assigned**: Centre assigns a certified sample collector to the order.
4. **Sample Collected / Processing**: Collector returns sample to lab. Centre staff inputs measured values, reference ranges, and pathologist notes via the result entry modal.
5. **Report Issued**: Staff previews the auto-generated PDF and issues it. The PDF instantly becomes available on the patient's mobile dashboard for viewing and downloading.

---

## 📁 Project Directory Structure

```
telemedicine/
├── Admin/                              # Python Flask Admin Web Portal
│   ├── app.py                          # Flask server & verification logic
│   ├── templates/                      # Bootstrap HTML5 admin views
│   └── static/                         # Admin CSS & JS assets
├── lib/
│   ├── main.dart                       # App entry point & route definitions
│   ├── core/
│   │   ├── config/                     # API keys & global configurations
│   │   ├── constants/                  # App constants (specializations, etc.)
│   │   ├── services/                   # Business logic & services
│   │   │   ├── auth_service.dart       # Firebase Authentication
│   │   │   ├── chatbot_service.dart    # Gemini AI integration engine
│   │   │   └── pdf_generator_service.dart # PDF compilation engine
│   │   ├── theme/                      # Executive Clinical Design System
│   │   └── widgets/                    # Reusable UI component library
│   ├── models/                         # Strongly-typed Dart data models
│   │   ├── user_model.dart             # System user & role schemas
│   │   ├── doctor_model.dart           # Doctor profile schema
│   │   ├── diagnostic_centre_model.dart # Diagnostic centre schema
│   │   ├── appointment_model.dart      # Appointment schema
│   │   ├── lab_test_model.dart         # Diagnostic test & order schema
│   │   ├── prescription_model.dart     # Digital prescription schema
│   │   ├── health_metrics_model.dart   # Vital health monitoring schema
│   │   └── ambulance_model.dart        # Emergency request schema
│   └── screens/                        # UI Screens grouped by domain
│       ├── admin/                      # Admin verification screens
│       ├── auth/                       # Login & Signup with role selection
│       ├── diagnostic_centre/          # Diagnostic dashboard & test catalog
│       ├── doctor/                     # Doctor dashboard, schedule, & EHR
│       └── patient/                    # Patient dashboard, AI chat, & booking
├── firestore.rules                     # Firebase Firestore Security Rules
├── storage.rules                       # Firebase Storage Security Rules
├── pubspec.yaml                        # Flutter package manifest
└── README.md                           # Master Project Documentation
```

---

## 📊 Data Models & Schema

The application employs 9 primary data models designed for seamless Firestore serialization:

| Model | Primary Fields | Description |
| :--- | :--- | :--- |
| `UserModel` | `uid`, `email`, `role`, `displayName`, `isApproved`, `createdAt` | Core user identity & RBAC authorization |
| `DoctorModel` | `id`, `name`, `specialization`, `bmdcRegNumber`, `isApproved`, `consultationFee` | Doctor professional profile & verification credentials |
| `DiagnosticCentreModel`| `id`, `name`, `dghsCode`, `pathologistBmdc`, `isApproved`, `offeredTests` | Diagnostic centre catalog & license codes |
| `LabTestModel` | `id`, `patientId`, `centreId`, `testName`, `status`, `testResults`, `pdfUrl` | Stage-gated diagnostic test order lifecycle |
| `AppointmentModel` | `id`, `patientId`, `doctorId`, `appointmentDate`, `timeSlot`, `status`, `fee` | Patient-Doctor consultation scheduling |
| `PrescriptionModel` | `id`, `doctorId`, `patientId`, `medicines`, `diagnosis`, `pdfBase64` | Digital prescription record & PDF document |
| `HealthMetricsModel` | `userId`, `heartRate`, `systolicBP`, `diastolicBP`, `status`, `timestamp` | Patient real-time vital health indicators |
| `AmbulanceModel` | `id`, `patientId`, `pickupLocation`, `hospital`, `ambulanceType`, `status` | Emergency transport dispatch request |

---

## 🤖 AI Health Assistant (MediBot)

MediBot is powered by **Google's Gemini 1.5 Flash API**. It functions as an intelligent triage system:

```dart
// Core Gemini AI Chatbot Call
final response = await _model.generateContent([
  Content.text('''
    You are MediBot, an AI Health Assistant. 
    Analyze symptoms described by the patient, suggest possible non-definitive health insights, 
    recommend appropriate doctor specializations, and advise on medical consultation.
  '''),
  Content.text(userQuery),
]);
```

### Key AI Functionalities:
- **Symptom Triage**: Analyzes patient symptom descriptions and directs them to the correct specialty (e.g., Cardiology, Dermatology, Pediatrics).
- **In-Chat Doctor Recommendations**: Dynamically presents tappable doctor recommendation cards within the chat interface.
- **Safety Guidelines**: Embedded disclaimer enforcement ensuring AI advice complements rather than replaces licensed medical consultation.

---

## ⌚ Health Monitoring & Smart Wearable Integration

The platform features a real-time Health Monitoring module displaying live Heart Rate (bpm) and Blood Pressure (mmHg).

```
   ┌─────────────────────────────────────────────────────────────┐
   │ 🫀 Heart Rate: 72 bpm (Normal)  |  🩸 BP: 120/80 (Normal)   │
   │ Status: 🟢 Connected            |  Auto-refreshes: 5s       │
   └─────────────────────────────────────────────────────────────┘
```

### Production Wearable Integration Architecture
While the current version includes a simulated real-time stream for demonstration, the codebase is architected for instant integration with physical wearables:

1. **Option 1: Health Connect / Apple Health API (Recommended)**
   Using the `health` package to sync metrics directly from Xiaomi Mi Band, Honor Band, Apple Watch, or Galaxy Watch:
   ```yaml
   dependencies:
     health: ^10.2.0
   ```
2. **Option 2: Direct Bluetooth Low Energy (BLE)**
   Using `flutter_blue_plus` to read Standard GATT GATT Heart Rate Characteristics (`0x2A37`).

---

## 💻 Installation & Setup Guide

### Mobile & Web Application (Flutter)

#### 1. Prerequisites
- **Flutter SDK**: `>= 3.2.0`
- **Dart SDK**: `>= 3.0.0`
- **Android Studio / VS Code** with Flutter extension installed.

#### 2. Clone & Install Dependencies
```bash
# Clone repository
git clone https://github.com/your-repo/telemedicine.git
cd telemedicine

# Fetch Flutter dependencies
flutter pub get
```

#### 3. Configure Firebase
Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are placed in their respective platform directories:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

#### 4. Run the Application
```bash
# Run on connected Android/iOS device or emulator
flutter run

# Run on Web (Chrome)
flutter run -d chrome
```

---

### Admin Verification Web App (Python Flask)

#### 1. Prerequisites
- **Python**: `>= 3.9`

#### 2. Install Dependencies & Run
```bash
# Navigate to Admin portal directory
cd Admin

# Install required Python packages
pip install flask firebase-admin

# Start Flask server
python app.py
```
The Admin Web Portal will run locally at `http://127.0.0.1:5000`.

---

## 🎓 Academic Defense & Presentation Summary

When presenting MediConnect for academic defense or project evaluation, highlight the following technical milestones:

1. **End-to-End Healthcare Architecture**: Complete integration of 4 distinct user roles (Patient, Doctor, Diagnostic Centre, Admin) with role-based Firestore security rules.
2. **Sequential Diagnostic Lifecycle**: Elimination of unverified or premature PDF issuance through a 5-stage sample tracking pipeline.
3. **Generative AI Triage**: Deployment of Gemini AI (`MediBot`) for instant patient assistance and specialty routing.
4. **Clean PDF Compilation Engine**: In-memory PDF compilation and interactive previewing (`PdfPreview`) eliminating static or placeholder documents.
5. **Dual Regulatory Verification**: Dual BMDC (Doctors) and DGHS/BMDC (Diagnostic Centres) verification via an independent Admin portal.

---

### 📄 License
This project is developed for academic evaluation and defense. All rights reserved.
