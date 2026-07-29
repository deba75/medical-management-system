import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';

class FavoriteMedicineItem {
  final String name;
  final String dosage;
  final String instruction;
  final String duration;

  FavoriteMedicineItem({
    required this.name,
    this.dosage = '1-0-1',
    this.instruction = 'After meal',
    this.duration = '5 days',
  });

  factory FavoriteMedicineItem.fromJson(Map<String, dynamic> json) {
    return FavoriteMedicineItem(
      name: json['name'] ?? '',
      dosage: json['dosage'] ?? '1-0-1',
      instruction: json['instruction'] ?? 'After meal',
      duration: json['duration'] ?? '5 days',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'instruction': instruction,
      'duration': duration,
    };
  }
}

class ManageFavoriteMedicinesDialog extends StatefulWidget {
  const ManageFavoriteMedicinesDialog({super.key});

  @override
  State<ManageFavoriteMedicinesDialog> createState() =>
      _ManageFavoriteMedicinesDialogState();
}

class _ManageFavoriteMedicinesDialogState
    extends State<ManageFavoriteMedicinesDialog> {
  final String? _doctorId = FirebaseAuth.instance.currentUser?.uid;
  List<FavoriteMedicineItem> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (_doctorId == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(_doctorId)
          .get();

      if (doc.exists && doc.data()?['favoriteMedicines'] != null) {
        final list = doc.data()!['favoriteMedicines'] as List;
        setState(() {
          _favorites = list
              .map((e) => FavoriteMedicineItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          _isLoading = false;
        });
      } else {
        // Default common medicines if empty
        setState(() {
          _favorites = [
            FavoriteMedicineItem(name: 'Tab. Napa 500mg', dosage: '1-1-1', instruction: 'After meal', duration: '5 days'),
            FavoriteMedicineItem(name: 'Cap. Seclo 20mg', dosage: '1-0-1', instruction: 'Before meal', duration: '7 days'),
            FavoriteMedicineItem(name: 'Tab. Alatrol 10mg', dosage: '0-0-1', instruction: 'At bedtime', duration: '5 days'),
            FavoriteMedicineItem(name: 'Tab. Ace 500mg', dosage: '1-1-1', instruction: 'After meal', duration: '3 days'),
          ];
          _isLoading = false;
        });
        _saveFavorites();
      }
    } catch (e) {
      debugPrint('Error loading favorite medicines: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveFavorites() async {
    if (_doctorId == null) return;
    try {
      await FirebaseFirestore.instance.collection('doctors').doc(_doctorId).set({
        'favoriteMedicines': _favorites.map((e) => e.toJson()).toList(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving favorite medicines: $e');
    }
  }

  void _addOrEditMedicine({FavoriteMedicineItem? existing, int? index}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final dosageController = TextEditingController(text: existing?.dosage ?? '1-0-1');
    final instructionController = TextEditingController(text: existing?.instruction ?? 'After meal');
    final durationController = TextEditingController(text: existing?.duration ?? '5 days');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(existing == null ? 'Add Favorite Medicine' : 'Edit Favorite Medicine'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Medicine Name & Strength',
                  hintText: 'e.g., Tab. Napa 500mg',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dosageController,
                decoration: const InputDecoration(
                  labelText: 'Default Dosage',
                  hintText: 'e.g., 1-0-1 or 1-1-1',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: instructionController,
                decoration: const InputDecoration(
                  labelText: 'Timing / Instruction',
                  hintText: 'e.g., After meal or Before meal',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  hintText: 'e.g., 5 days or 1 week',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              final item = FavoriteMedicineItem(
                name: name,
                dosage: dosageController.text.trim(),
                instruction: instructionController.text.trim(),
                duration: durationController.text.trim(),
              );

              setState(() {
                if (index != null) {
                  _favorites[index] = item;
                } else {
                  _favorites.add(item);
                }
              });

              _saveFavorites();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width > 600 ? 550.0 : screenSize.width * 0.92;
    final dialogHeight = screenSize.height * 0.82;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Common / Favorite Medicines'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close',
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addOrEditMedicine(),
                  tooltip: 'Add Favorite Medicine',
                ),
              ],
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // Top Header Action Bar
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Favorite Medicines List:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _addOrEditMedicine(),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('+ Add New Favorite'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _favorites.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.medication_outlined, size: 64, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No favorite medicines added yet',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed: () => _addOrEditMedicine(),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add Common Medicine'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _favorites.length,
                                itemBuilder: (context, index) {
                                  final item = _favorites[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                        child: Icon(Icons.check_box, color: AppTheme.primaryColor),
                                      ),
                                      title: Text(
                                        item.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        'Dosage: ${item.dosage} • ${item.instruction} • ${item.duration}',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                            onPressed: () => _addOrEditMedicine(existing: item, index: index),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                            onPressed: () {
                                              setState(() => _favorites.removeAt(index));
                                              _saveFavorites();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _addOrEditMedicine(),
              backgroundColor: AppTheme.primaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Medicine', style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}
