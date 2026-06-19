import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RequestAccessScreen extends ConsumerStatefulWidget {
  const RequestAccessScreen({super.key});

  @override
  ConsumerState<RequestAccessScreen> createState() => _RequestAccessScreenState();
}

class _RequestAccessScreenState extends ConsumerState<RequestAccessScreen> {
  final _patientIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _sendAccessRequest() async {
    if (_formKey.currentState!.validate()) {
      final patientId = _patientIdController.text.trim();
      final doctorId = FirebaseAuth.instance.currentUser!.uid;

      // Check if patient exists
      final patientQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('patientId', isEqualTo: patientId)
          .where('role', isEqualTo: 'patient')
          .get();

      if (patientQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient with this ID does not exist.')),
        );
        return;
      }

      final patientUid = patientQuery.docs.first.id;

      // Check if a request already exists
      final requestQuery = await FirebaseFirestore.instance
          .collection('accessRequests')
          .where('doctorId', isEqualTo: doctorId)
          .where('patientId', isEqualTo: patientUid)
          .get();

      if (requestQuery.docs.isNotEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access request already sent.')),
        );
        return;
      }

      // Create a new access request
      await FirebaseFirestore.instance.collection('accessRequests').add({
        'doctorId': doctorId,
        'patientId': patientUid,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access request sent successfully.')),
      );
      _patientIdController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Patient Access'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _patientIdController,
                decoration: const InputDecoration(
                  labelText: 'Patient ID',
                  hintText: 'Enter the 6-digit patient ID',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a patient ID.';
                  }
                  if (value.length != 6) {
                    return 'Patient ID must be 6 digits.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _sendAccessRequest,
                child: const Text('Send Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
