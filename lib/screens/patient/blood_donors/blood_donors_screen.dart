import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BloodDonorsScreen extends ConsumerStatefulWidget {
  const BloodDonorsScreen({super.key});

  @override
  ConsumerState<BloodDonorsScreen> createState() => _BloodDonorsScreenState();
}

class _BloodDonorsScreenState extends ConsumerState<BloodDonorsScreen> {
  String _selectedBloodGroup = 'All';
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  final List<String> _bloodGroups = [
    'All',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Donors'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header with blood group filter
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[600],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Find Blood Donors',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select blood group to filter donors',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                // Blood group filter chips
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _bloodGroups.length,
                    itemBuilder: (context, index) {
                      final group = _bloodGroups[index];
                      final isSelected = _selectedBloodGroup == group;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(group),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedBloodGroup = group;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.red[600] : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          checkmarkColor: Colors.red[600],
                          showCheckmark: isSelected,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Donors list
          Expanded(
            child: _buildDonorsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDonorsList() {
    // Get all users from the collection - filter client-side to include all patients
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users');

    // Only filter by blood group if a specific one is selected
    if (_selectedBloodGroup != 'All') {
      query = query.where('bloodGroup', isEqualTo: _selectedBloodGroup);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading donors',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final donors = snapshot.data?.docs ?? [];
        
        // Filter out current user and doctors, show all patients
        final filteredDonors = donors.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final role = data['role'] as String?;
          // Exclude current user and doctors
          return doc.id != _currentUserId && role != 'doctor';
        }).toList();

        if (filteredDonors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bloodtype_outlined,
                  size: 80,
                  color: Colors.red[200],
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedBloodGroup == 'All'
                      ? 'No donors available'
                      : 'No $_selectedBloodGroup donors found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later or try a different blood group',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDonors.length,
          itemBuilder: (context, index) {
            final data = filteredDonors[index].data() as Map<String, dynamic>;
            final donorId = filteredDonors[index].id;
            return _buildDonorCard(data, donorId);
          },
        );
      },
    );
  }

  Widget _buildDonorCard(Map<String, dynamic> data, String donorId) {
    final name = data['name'] as String? ?? 'Anonymous';
    final bloodGroup = data['bloodGroup'] as String? ?? 'U';
    final phone = data['phone'] as String? ?? '';
    final lastDonationRaw = data['lastDonationDate'];
    final isEligible = _checkEligibility(lastDonationRaw);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Blood group badge
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red[200]!,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bloodtype,
                    color: Colors.red[600],
                    size: 20,
                  ),
                  Text(
                    bloodGroup,
                    style: TextStyle(
                      color: Colors.red[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Donor info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  if (phone.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          phone,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isEligible ? Colors.green[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isEligible ? 'Eligible to donate' : 'Not eligible yet',
                      style: TextStyle(
                        color: isEligible ? Colors.green[700] : Colors.orange[700],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Action buttons
            Column(
              children: [
                // Copy phone button
                if (phone.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.copy, color: Colors.grey[600]),
                    tooltip: 'Copy phone number',
                    onPressed: () => _copyPhoneNumber(phone),
                  ),
                // Request blood button
                IconButton(
                  icon: Icon(Icons.send, color: Colors.red[600]),
                  tooltip: 'Request blood',
                  onPressed: () => _requestBlood(donorId, name, bloodGroup),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _checkEligibility(dynamic lastDonation) {
    if (lastDonation == null) return true;
    
    DateTime? lastDate;
    if (lastDonation is Timestamp) {
      lastDate = lastDonation.toDate();
    } else if (lastDonation is String) {
      try {
        lastDate = DateTime.parse(lastDonation);
      } catch (e) {
        return true; // If parsing fails, assume eligible
      }
    }
    
    if (lastDate == null) return true;
    
    final daysSinceDonation = DateTime.now().difference(lastDate).inDays;
    return daysSinceDonation >= 120; // 120 days eligibility
  }

  void _copyPhoneNumber(String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Phone number copied!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _requestBlood(String donorId, String donorName, String bloodGroup) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Get current user's info
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final requesterName = userDoc.data()?['name'] ?? 'Someone';
    final requesterPhone = userDoc.data()?['phone'] ?? '';

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Blood'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send blood request to $donorName?'),
            const SizedBox(height: 8),
            Text(
              'Blood group: $bloodGroup',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            const Text(
              'The donor will receive a notification with your contact details.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Create notification for the donor
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': donorId,
        'type': 'blood_request',
        'title': 'Blood Request',
        'message': '$requesterName needs $bloodGroup blood. Please contact if you can help.',
        'requesterName': requesterName,
        'requesterPhone': requesterPhone,
        'requesterId': currentUser.uid,
        'bloodGroup': bloodGroup,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Blood request sent successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
