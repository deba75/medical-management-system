# MediConnect - Unified Telemedicine & Diagnostic Management Platform

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Cloud_Firestore-FFCA28?logo=firebase)](https://firebase.google.com)
[![Python Flask](https://img.shields.io/badge/Flask-Web_Portals-000000?logo=flask)](https://flask.palletsprojects.com/)
[![Google Gemini AI](https://img.shields.io/badge/MediBot-Gemini_AI-8E44AD?logo=google)](https://ai.google.dev/)
[![Currency](https://img.shields.io/badge/Currency-BDT_%28%E0%A7%B3%29-green)](#)

**MediConnect** is an enterprise-grade, end-to-end Telemedicine and Diagnostic Lab Management ecosystem designed for **Patients**, **Doctors**, **Diagnostic Centres**, and **System Administrators**. Built with **Flutter (Mobile & Web)**, **Firebase (Firestore & Auth)**, **Python Flask (Web Portals)**, and **Google Gemini AI**, MediConnect powers real-time doctor appointments, digital e-prescriptions, isolated diagnostic lab test ordering, 5-stage sample tracking, and automated PDF medical report generation with official DGHS & BMDC credential verification.

---

## 📑 Table of Contents
- [System Architecture](#-system-architecture)
- [Complete Feature Matrix by Role](#-complete-feature-matrix-by-role)
  - [1. Patient Portal (Flutter Mobile & Web)](#1-patient-portal-flutter-mobile--web)
  - [2. Doctor Portal (Flutter Mobile & Web)](#2-doctor-portal-flutter-mobile--web)
  - [3. Diagnostic Centre Portal (Flutter Mobile & Web)](#3-diagnostic-centre-portal-flutter-mobile--web)
  - [4. Super Admin Web Portal (Python Flask)](#4-super-admin-web-portal-python-flask)
- [5-Stage Diagnostic Lab Test Pipeline](#-5-stage-diagnostic-lab-test-pipeline)
- [Database Schema & Data Architecture](#-database-schema--data-architecture)
- [PDF Generation & E-Prescription Engine](#-pdf-generation--e-prescription-engine)
- [Project Directory Structure](#-project-directory-structure)
- [Installation & Setup Guide](#-installation--setup-guide)
  - [Flutter Mobile App](#flutter-mobile-app)
  - [Python Flask Web Server](#python-flask-web-server)
- [Cloud Deployment & GitHub Workflow](#-cloud-deployment--github-workflow)

---

## 🏗 System Architecture

```
                                  ┌──────────────────────────────────────────────┐
                                  │          MediConnect Platform                │
                                  └──────────────────────┬───────────────────────┘
                                                         │
               ┌─────────────────────────────────────────┼────────────────────────────────────────┐
               ▼                                         ▼                                        ▼
    ┌──────────────────────┐                  ┌─────────────────────┐                 ┌──────────────────────┐
    │ Flutter Mobile/Web   │                  │  Python Flask Web   │                 │   Google Gemini AI   │
    │  (Patient/Doc/Diag)  │                  │  (Unified Portals)  │                 │ (MediBot Assistant)  │
    └──────────┬───────────┘                  └──────────┬──────────┘                 └──────────┬───────────┘
               │                                         │                                       │
               └────────────────────┬────────────────────┘                                       │
                                    ▼                                                            │
                       ┌─────────────────────────┐                                               │
                       │   Firebase Cloud Services│◄─────────────────────────────────────────────┘
                       │ (Firestore / Auth / Storage)
                       └─────────────────────────┘
```

---

## 🌟 Complete Feature Matrix by Role

### 1. Patient Portal (Flutter Mobile & Web)
- **Account Management**: Signup/login with personal details, blood group, emergency contact, and Date of Birth.
- **Doctor Discovery**: Filter specialist doctors by name, hospital, and medical specialization (Cardiology, Neurology, Pediatrics, Gynecology, Medicine, etc.).
- **Chamber & Schedule View**: Inspect doctor qualifications, BMDC registration numbers, practice chambers, visiting hours, and consultation fees in Bangladeshi Taka (**৳ / BDT**).
- **Appointment Booking**: Select chamber, date, time slot, consultation mode (In-Person / Online), and payment method (Cash on Visit / Online bKash/Nagad).
- **Overdue Appointment Evaluator**: Automatically evaluates appointment schedules; overdue appointments shift from "Upcoming" to **"Missed"** status with distinct badge indicators.
- **Digital E-Prescriptions**: View issued digital prescriptions online with dosage schedules (e.g. `1-0-1`), duration, doctor notes, and printable PDF report generation.
- **Diagnostic Centres**: Browse verified diagnostic centers in Bangladesh with isolated test catalogs and prices.
- **5-Stage Lab Test Booking**: Order lab tests with sample collection mode selection (**Home Visit Biohazard Collection** vs. **Walk-in Centre Visit**).
- **Live Status Tracking**: Monitor test orders in real-time across 5 stages:
  1. `Stage 1: Pending` (Booking submitted by patient)
  2. `Stage 2: Approved` (Diagnostic Centre approves booking)
  3. `Stage 3: Collector Assigned` (Phlebotomist dispatched for sample collection)
  4. `Stage 4: Sample Processing` (Lab analyzer testing in progress)
  5. `Stage 5: Report Issued / Completed` (Diagnostic report published)
- **Frictionless PDF Report Viewing**: Direct access to view and print official diagnostic PDF reports without any login redirection.
- **MediBot AI Assistant**: Interactive symptom checker and preliminary health triage powered by Google Gemini AI.

---

### 2. Doctor Portal (Flutter Mobile & Web)
- **Doctor Verification Workflow**: Secure registration requiring full name, email, phone, BMDC license registration number, workplace hospital, and qualifications. Accounts are submitted for Super Admin verification.
- **Chamber & Availability Settings**: Add/edit practice chambers, visiting hours, consultation fees (**৳**), and active appointment days.
- **Appointment Dashboard**: Real-time view of daily appointment queues, patient symptoms, and booking status (`Pending`, `Confirmed`, `Completed`, `Missed`).
- **Digital E-Prescription Authoring Engine**:
  - Prescribe medicines with dosage (e.g. `1+0+1`), duration, and instructions (Before/After meals).
  - Add recommended diagnostic tests (CBC, Lipid Profile, USG, X-Ray, etc.).
  - Include clinical notes and follow-up advice.
  - Automatically generates an official printable PDF E-Prescription signed with the doctor's BMDC credentials.

---

### 3. Diagnostic Centre Portal (Flutter Mobile & Web)
- **Facility Verification Workflow**: Registration requiring DGHS license code, Chief Pathologist name, Pathologist BMDC registration code, trade license, operating hours, and home sample collection fees (**৳150**).
- **Isolated Test Catalog Management**:
  - Add and remove lab tests with test name, category (Pathology, Biochemistry, Radiology, Cardiology, Hormones), preparation instructions, turnaround time, and price in BDT (**৳**).
  - Dual-synced with Cloud Firestore so tests added on web immediately populate inside the center's profile in the Flutter Patient App.
- **5-Stage Order Operations**:
  - Accept/Approve patient lab test requests.
  - Assign certified phlebotomists/sample collectors.
  - Process samples and input structured parameter test results.
  - Publish official diagnostic PDF reports.
- **Dynamic Action Status Handling**: Action buttons transition from `Manage` to **`Done`** once a lab request reaches completed status.
- **Sample Collector Management**: Add/remove phlebotomist staff with name, contact number, and motorcycle/vehicle registration.

---

### 4. Super Admin Web Portal (Python Flask)
- **System Executive Dashboard**: Real-time analytics on registered patients, verified doctors, approved diagnostic centers, total appointments, and platform revenue.
- **Credential Verification Engine**:
  - Review doctor BMDC license credentials and approve/reject accounts.
  - Audit diagnostic centre DGHS codes and pathologist BMDC numbers before granting platform access.
- **Patient Account Controls**: Monitor patient list, view booking histories, and restrict/activate accounts.
- **Health Knowledge Base & Articles**: Publish, edit, and moderate verified medical articles for patient education.

---

## 🧪 5-Stage Diagnostic Lab Test Pipeline

```
  ┌──────────────────────────┐      ┌──────────────────────────┐      ┌──────────────────────────┐
  │   Stage 1: Booking       │─────►│   Stage 2: Verification  │─────►│   Stage 3: Dispatch      │
  │  Patient selects test &  │      │ Diagnostic Centre Admin  │      │ Assign Certified         │
  │  collection mode (Home)  │      │ Approves Request         │      │ Phlebotomist / Collector │
  └──────────────────────────┘      └──────────────────────────┘      └────────────┬─────────────┘
                                                                                   │
  ┌──────────────────────────┐      ┌──────────────────────────┐                   │
  │   Stage 5: PDF Report    │◄─────│   Stage 4: Lab Testing   │◄──────────────────┘
  │ Diagnostic Report Issued │      │ Sample Analyzed & Results│
  │ Patient Views PDF Report │      │ Entered into System      │
  └──────────────────────────┘      └──────────────────────────┘
```

---

## 🗄 Database Schema & Data Architecture

MediConnect relies on **Cloud Firestore** structured document collections:

| Collection Name | Document Key | Key Fields & Schema |
| :--- | :--- | :--- |
| `users` | `userId` | `name`, `email`, `phone`, `role` (`patient`/`doctor`/`diagnostic_centre`/`admin`), `dob`, `gender`, `blood_group`, `emergency_contact`, `verificationStatus` |
| `doctors` | `doctorId` | `name`, `email`, `phone`, `bmdcNumber`, `specialization`, `workplaceHospital`, `qualifications`, `consultationFee`, `chambers`, `availability`, `verificationStatus` |
| `diagnostic_centres` | `centreId` | `name`, `email`, `phone`, `city`, `address`, `dghsCode`, `pathologistName`, `pathologistBmdcNumber`, `tests` (embedded list), `collectors`, `verificationStatus` |
| `available_lab_tests` | `testId` | `testName`, `name`, `category`, `price`, `preparation`, `turnaroundTime`, `centreId`, `isAvailable` |
| `appointments` | `appointmentId` | `patientId`, `patientName`, `doctorId`, `doctorName`, `date`, `timeSlot`, `fee`, `symptoms`, `status` (`pending`/`confirmed`/`completed`/`missed`), `prescription` |
| `lab_test_bookings` | `bookingId` | `patientId`, `patientName`, `diagnosticCentreId`, `diagnosticCentreName`, `tests`, `collectionType`, `status` (`pending`/`approved`/`collectorAssigned`/`sampleCollected`/`processing`/`completed`), `totalAmount`, `reportResults` |
| `health_articles` | `articleId` | `title`, `authorName`, `category`, `content`, `status` (`published`/`draft`/`restricted`) |

---

## 📄 PDF Generation & E-Prescription Engine

MediConnect generates official, print-ready PDF documents formatted with CSS `@media print`:

1. **Digital E-Prescription PDF**:
   - Header with doctor's name, specialization, qualifications, and BMDC registration code.
   - Patient information strip (Name, Date, Prescription ID).
   - Clinical notes, symptoms, and recommended diagnostic tests.
   - Formatted Rx medicine table with dosages (`1-0-1`), duration, and instructions.
   - Doctor's authorized digital signature block.

2. **Diagnostic Lab Report PDF**:
   - Header with diagnostic facility name, DGHS license code, address, and Chief Pathologist details.
   - Patient demographics, specimen collection date, and mode.
   - Test parameter result table showing measured values, unit, and reference ranges.
   - Pathologist signature and official verification QR/barcode data.

---

## 📁 Project Directory Structure

```
telemedicine/
├── Admin/                          # Python Flask Unified Web Portals
│   ├── app.py                      # Flask Application Server (Routes & Logic)
│   ├── serviceAccountKey.json      # Firebase Admin SDK Credentials
│   └── templates/                  # Jinja2 HTML Templates
│       ├── login.html              # Unified Gateway (Doctor / Diagnostic / Patient Tabs)
│       ├── register_patient.html   # Patient Web Signup
│       ├── register_doctor.html    # Doctor Web Signup
│       ├── register_diagnostic.html# Diagnostic Centre Web Signup
│       ├── patient/                # Patient Web Portal
│       │   ├── base.html           # Emerald Sidebar Base Template
│       │   ├── dashboard.html      # Patient Dashboard & Metrics
│       │   ├── find_doctors.html   # Doctor Search & Specialty Filter
│       │   ├── doctor_profile.html # Doctor Profile & Chambers
│       │   ├── book_appointment.html# Appointment Booking Form
│       │   ├── appointments.html   # Appointments History
│       │   ├── appointment_detail.html # Appointment Detail & Digital Prescription
│       │   ├── prescriptions.html  # Prescriptions List
│       │   ├── prescription_print.html # Printable PDF Prescription
│       │   ├── diagnostic_centres.html # Diagnostic Centre Discovery
│       │   ├── diagnostic_detail.html  # Centre Test Catalog & Booking Modal
│       │   ├── lab_tests.html      # 5-Stage Lab Order Tracker
│       │   └── profile.html        # Patient Profile Settings
│       ├── doctor/                 # Doctor Web Portal Templates
│       └── diagnostic/             # Diagnostic Centre Web Portal Templates
├── lib/                            # Flutter Mobile & Web App
│   ├── main.dart                   # Application Entry Point
│   ├── core/                       # Services, Theme, Utility Helpers
│   ├── models/                     # Data Models (DiagnosticCentreModel, Appointment, etc.)
│   └── screens/                    # Flutter UI Screens (Patient, Doctor, Diagnostic)
├── README.md                       # Comprehensive Project Documentation
└── pubspec.yaml                    # Flutter Dependencies
```

---

## ⚡ Installation & Setup Guide

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`v3.19.0` or higher)
- [Python 3.10+](https://www.python.org/downloads/)
- [Firebase Account & CLI](https://firebase.google.com/)

---

### Mobile & Web App (Flutter)

1. **Clone Repository**:
   ```bash
   git clone https://github.com/deba75/medical-management-system.git
   cd telemedicine
   ```

2. **Install Flutter Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run Mobile / Web App**:
   ```bash
   # Run on Chrome
   flutter run -d chrome

   # Run on Connected Android Device / Emulator
   flutter run -d android
   ```

---

### Web Admin & Doctor/Diagnostic Portal (Python Flask)

1. **Navigate to Admin Directory**:
   ```bash
   cd Admin
   ```

2. **Install Python Dependencies**:
   ```bash
   pip install flask firebase-admin werkzeug
   ```

3. **Start Flask Web Server**:
   ```bash
   python app.py
   ```
   *Access Web Portal at: `http://localhost:5000`*

---

## ☁ Deployment & Cloud Host Setup

- **GitHub Repository**: [deba75/medical-management-system](https://github.com/deba75/medical-management-system.git)
- **Main Branch**: `main`
- **Currency**: Standardized in Bangladeshi Taka (**৳ / BDT**)
