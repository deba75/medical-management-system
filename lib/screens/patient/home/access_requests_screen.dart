import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccessRequestsScreen extends StatelessWidget {
  const AccessRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final patientId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Requests'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('accessRequests')
            .where('patientId', isEqualTo: patientId)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pending access requests.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final request = snapshot.data!.docs[index];
              final doctorId = request['doctorId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(doctorId).get(),
                builder: (context, doctorSnapshot) {
                  if (!doctorSnapshot.hasData) {
                    return const ListTile(title: Text('Loading...'));
                  }
                  final doctorData = doctorSnapshot.data!.data() as Map<String, dynamic>;
                  final doctorName = doctorData['name'] ?? 'Unknown Doctor';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text('Dr. $doctorName'),
                      subtitle: const Text('Wants to access your records.'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () => _updateRequestStatus(request.id, 'approved'),
                            child: const Text('Approve'),
                          ),
                          TextButton(
                            onPressed: () => _updateRequestStatus(request.id, 'denied'),
                            child: const Text('Deny', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _updateRequestStatus(String requestId, String status) {
    FirebaseFirestore.instance
        .collection('accessRequests')
        .doc(requestId)
        .update({'status': status});
  }
}
