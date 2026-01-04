# Health Monitoring Feature

## Current Implementation

The health monitoring feature currently uses **simulated real-time data** that updates every 5 seconds to demonstrate the UI and functionality.

### Features:
- ✅ Real-time BP and Heart Rate display
- ✅ Status indicators (Normal/High/Low)
- ✅ Color-coded metrics
- ✅ Auto-refresh every 5 seconds
- ✅ Live connection status indicator
- ✅ Available in both Patient and Doctor dashboards

### Displayed Metrics:
1. **Heart Rate** (bpm)
   - Normal: 60-100 bpm
   - High: > 100 bpm
   - Low: < 60 bpm

2. **Blood Pressure** (mmHg)
   - Normal: 90-140 / 60-90
   - High: > 140/90
   - Low: < 90/60

---

## Future: Connecting Real Fitness Bands

To connect actual fitness bands (Honor Band, Mi Band, Apple Watch, etc.), you'll need to:

### Option 1: Bluetooth LE Integration (Complex)

#### Required Packages:
```yaml
dependencies:
  flutter_blue_plus: ^1.32.12  # Bluetooth Low Energy
  permission_handler: ^11.3.1  # Already added
```

#### Steps:
1. **Request Bluetooth Permissions**
   - Add to AndroidManifest.xml:
     ```xml
     <uses-permission android:name="android.permission.BLUETOOTH"/>
     <uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
     <uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
     <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
     ```

2. **Scan for Devices**
   ```dart
   import 'package:flutter_blue_plus/flutter_blue_plus.dart';
   
   Future<void> scanForDevices() async {
     FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
     
     FlutterBluePlus.scanResults.listen((results) {
       for (ScanResult r in results) {
         if (r.device.name.contains('Honor') || r.device.name.contains('Band')) {
           // Found fitness band
         }
       }
     });
   }
   ```

3. **Connect to Device**
   ```dart
   Future<void> connectToDevice(BluetoothDevice device) async {
     await device.connect();
     List<BluetoothService> services = await device.discoverServices();
     
     for (BluetoothService service in services) {
       for (BluetoothCharacteristic characteristic in service.characteristics) {
         // Read heart rate characteristic
         if (characteristic.uuid.toString().contains('2A37')) { // Heart Rate
           List<int> value = await characteristic.read();
           int heartRate = value[1]; // Parse heart rate
         }
       }
     }
   }
   ```

4. **Listen for Real-time Updates**
   ```dart
   await characteristic.setNotifyValue(true);
   characteristic.onValueReceived.listen((value) {
     // Update UI with real data
     setState(() {
       _currentMetrics = HealthMetrics(
         heartRate: value[1],
         systolicBP: value[2],
         diastolicBP: value[3],
         timestamp: DateTime.now(),
         status: 'normal',
       );
     });
   });
   ```

### Option 2: Google Fit / Apple Health Integration (Easier)

#### For Android (Google Fit):
```yaml
dependencies:
  health: ^10.2.0
```

```dart
import 'package:health/health.dart';

Future<void> fetchHealthData() async {
  Health health = Health();
  
  bool requested = await health.requestAuthorization([
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
  ]);
  
  if (requested) {
    List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
      DateTime.now().subtract(Duration(hours: 1)),
      DateTime.now(),
      [HealthDataType.HEART_RATE],
    );
    
    for (var data in healthData) {
      print('Heart Rate: ${data.value}');
    }
  }
}
```

### Option 3: Firebase Integration with Mobile App

1. Create a companion mobile app that reads from fitness band
2. Send data to Firebase Firestore
3. This Flutter app listens to Firestore changes

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

Stream<HealthMetrics> getHealthStream(String userId) {
  return FirebaseFirestore.instance
      .collection('health_metrics')
      .doc(userId)
      .snapshots()
      .map((doc) => HealthMetrics.fromJson(doc.data()!));
}

// In your widget:
StreamBuilder<HealthMetrics>(
  stream: getHealthStream(currentUserId),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return HealthMonitorWidget(metrics: snapshot.data);
    }
    return CircularProgressIndicator();
  },
)
```

---

## Recommended Approach

**For Production: Use Google Fit/Apple Health API** (Option 2)
- ✅ Works with all fitness bands that sync to Google Fit/Apple Health
- ✅ No need to handle Bluetooth complexity
- ✅ Battery efficient
- ✅ Official APIs with better support
- ✅ Users already sync their bands to these platforms

**To Enable:**
1. Replace mock data generator in `health_monitor_widget.dart`
2. Add `health` package
3. Request health permissions
4. Fetch data from Google Fit/Apple Health
5. Update UI with real values

---

## Files Modified

1. `lib/models/health_metrics_model.dart` - Health data model
2. `lib/core/widgets/health_monitor_widget.dart` - UI widget with mock data
3. `lib/screens/patient/home/patient_home_screen.dart` - Added to patient dashboard
4. `lib/screens/doctor/home/enhanced_doctor_dashboard.dart` - Added to doctor dashboard

## Testing

The feature is currently working with **simulated data**. You'll see:
- Heart rate updating between 68-80 bpm
- Blood pressure updating between 115-130 / 75-85 mmHg
- Values refresh every 5 seconds
- Status indicators showing Normal/High/Low

Replace the `_generateMetrics()` function in `health_monitor_widget.dart` with real data source when ready!
