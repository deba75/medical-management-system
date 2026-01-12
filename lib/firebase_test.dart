import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

/// Firebase Connection Test Screen
/// 
/// This screen verifies that Firebase is properly configured and connected.
/// Run this to test your Firebase setup before using it in production.
class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  String _status = 'Testing Firebase Connection...';
  bool _isLoading = true;
  final List<String> _testResults = [];

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  Future<void> _runTests() async {
    setState(() {
      _isLoading = true;
      _testResults.clear();
    });

    try {
      // Test 1: Check Firebase initialization
      _addResult('✅ Firebase initialized successfully');
      _addResult('📦 Project ID: ${Firebase.app().options.projectId}');
      
      // Test 2: Check Auth instance
      final auth = FirebaseAuth.instance;
      _addResult('✅ Firebase Auth instance created');
      _addResult('👤 Current user: ${auth.currentUser?.email ?? "Not signed in"}');
      
      // Test 3: Check Firestore instance
      final firestore = FirebaseFirestore.instance;
      _addResult('✅ Firestore instance created');
      
      // Test 4: Test Firestore connection
      await firestore.collection('_test_').doc('connection_test').set({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Firebase connection test',
        'platform': Theme.of(context).platform.toString(),
      });
      _addResult('✅ Firestore write successful');
      
      // Test 5: Read back the test document
      final doc = await firestore.collection('_test_').doc('connection_test').get();
      if (doc.exists) {
        _addResult('✅ Firestore read successful');
        _addResult('📄 Test document data: ${doc.data()}');
      }
      
      // Test 6: Delete test document
      await firestore.collection('_test_').doc('connection_test').delete();
      _addResult('✅ Firestore delete successful');
      
      setState(() {
        _status = '🎉 All Firebase tests passed!';
        _isLoading = false;
      });
      
    } catch (e) {
      _addResult('❌ Error: $e');
      setState(() {
        _status = '⚠️ Firebase connection failed';
        _isLoading = false;
      });
    }
  }

  void _addResult(String result) {
    setState(() {
      _testResults.add(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Connection Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              color: _isLoading 
                  ? Colors.orange.shade50 
                  : _status.contains('failed')
                      ? Colors.red.shade50
                      : Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        _status.contains('failed')
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        color: _status.contains('failed')
                            ? Colors.red
                            : Colors.green,
                        size: 24,
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _status,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Test Results
            const Text(
              'Test Results:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Expanded(
              child: _testResults.isEmpty
                  ? const Center(child: Text('Running tests...'))
                  : ListView.builder(
                      itemCount: _testResults.length,
                      itemBuilder: (context, index) {
                        final result = _testResults[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${index + 1}. ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  result,
                                  style: TextStyle(
                                    color: result.startsWith('❌')
                                        ? Colors.red
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            
            const SizedBox(height: 20),
            
            // Retry Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _runTests,
                icon: const Icon(Icons.refresh),
                label: const Text('Run Tests Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Main function to run Firebase tests
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FirebaseTestScreen(),
  ));
}
