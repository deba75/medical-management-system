# Quick Start Guide - TeleMedicine App

## 🚀 Getting Started in 3 Steps

### Step 1: Verify Flutter Installation
```bash
flutter doctor
```
Make sure all checkmarks are green (✓)

### Step 2: Install Dependencies
```bash
cd f:/flutter_projects/Defense/telimedicine
flutter pub get
```

### Step 3: Run the App
```bash
# For mobile (Android/iOS)
flutter run

# For web
flutter run -d chrome

# For Windows desktop
flutter run -d windows
```

## 📱 Testing the App (With Mock Data)

### Test Patient Flow

1. **Launch App** → See splash screen → Auto-navigate to login
2. **Sign Up** → Select "Patient" role → Fill form → Sign up
3. **Home Screen** → Explore quick actions and specializations
4. **Search Doctors** → Apply filters → View doctor profiles
5. **Book Appointment** → Select date → Choose time slot → Confirm
6. **My Appointments** → View booked appointments
7. **Medical History** → See past records
8. **Prescriptions** → View prescriptions
9. **Emergency** → Book ambulance with form

### Test Doctor Flow

1. **Launch App** → Login screen
2. **Sign Up** → Select "Doctor" role → Complete registration
3. **Dashboard** → View today's appointments and stats
4. **Appointments** → Browse upcoming/completed appointments
5. **Schedule** → View and edit weekly schedule
6. **Appointment Detail** → View patient information

## 🎨 UI Testing Points

### Navigation
- ✅ Bottom navigation bar works
- ✅ Screen transitions are smooth
- ✅ Back button navigation works

### Forms
- ✅ Input validation works
- ✅ Error messages display correctly
- ✅ Submit buttons show loading state

### Lists
- ✅ Scroll performance is smooth
- ✅ Pull-to-refresh works
- ✅ Empty states show appropriate messages

### Interactive Elements
- ✅ Buttons respond to taps
- ✅ Cards are tappable
- ✅ Filters apply correctly

## 🐛 Common Issues & Solutions

### Issue: Dependencies not installing
```bash
flutter clean
flutter pub get
```

### Issue: App not launching
```bash
# Check connected devices
flutter devices

# Run with verbose
flutter run -v
```

### Issue: Hot reload not working
```bash
# Use hot restart instead
# Press 'R' in terminal or use IDE button
```

## 📁 Key Files to Know

### Main Entry Points
- `lib/main.dart` - App entry, routing, splash screen
- `lib/screens/auth/login_screen.dart` - Login screen
- `lib/screens/patient/home/patient_home_screen.dart` - Patient home
- `lib/screens/doctor/home/doctor_home_screen.dart` - Doctor home

### Configuration
- `lib/core/theme/app_theme.dart` - Colors, typography, theme
- `lib/core/constants/app_constants.dart` - App-wide constants
- `pubspec.yaml` - Dependencies and assets

### Models
- `lib/models/` - All data models

## 🎯 Demo Scenarios

### Scenario 1: Patient Books Appointment (5 min)
1. Login as patient
2. Navigate to "Find Doctors"
3. Filter by "Cardiologist"
4. Select "Dr. Sarah Johnson"
5. View profile and fees
6. Book appointment for tomorrow
7. Select 9:00 AM slot
8. Confirm booking
9. View in "My Appointments"

### Scenario 2: Emergency Ambulance (2 min)
1. From patient home
2. Click emergency button
3. Select "Basic Ambulance"
4. Enter pickup: "123 Main St"
5. Enter hospital: "City General"
6. Enter phone number
7. Submit request
8. See confirmation

### Scenario 3: Doctor Views Schedule (3 min)
1. Login as doctor
2. View dashboard stats
3. See today's appointments
4. Navigate to Schedule tab
5. View weekly schedule
6. Edit Monday slots
7. Save changes

## 📊 Mock Data Overview

The app uses realistic mock data for demo purposes:

- **3 Mock Doctors** (Cardiologist, Dermatologist, Pediatrician)
- **2 Mock Appointments** per user
- **2 Mock Prescriptions**
- **2 Mock Medical History** records
- **Available Time Slots** (9:00 AM - 6:00 PM)
- **3 Ambulance Types** (Basic, ICU, Neonatal)

## 🔧 Development Tips

### Hot Reload
- Press `r` in terminal for hot reload
- Press `R` for hot restart
- Press `q` to quit

### Debug Mode
- Use Flutter DevTools for debugging
- View widget tree and performance
- Check network calls (when Firebase added)

### Code Organization
- Each feature has its own folder
- Shared widgets in `core/widgets`
- Models in `models/` folder
- Screens in `screens/` folder

## 📝 Next Steps After Demo

1. **Get Feedback** on UI/UX
2. **Finalize Requirements** based on demo
3. **Setup Firebase** project
4. **Integrate Backend** following TODO comments
5. **Add Real Data** from Firestore
6. **Test End-to-End** with real users
7. **Deploy to Stores** (Google Play, App Store)

## 🆘 Need Help?

- Check `PROJECT_STRUCTURE.md` for architecture details
- Check `COMPLETION_SUMMARY.md` for feature list
- Look for `// TODO:` comments for integration points
- Review models in `lib/models/` for data structure

---

**Quick Start Complete! 🎉**

You're now ready to demo the TeleMedicine app with full UI functionality!
