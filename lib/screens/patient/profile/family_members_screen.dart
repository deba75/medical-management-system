import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/family_member_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/family_member_model.dart';

class FamilyMembersScreen extends ConsumerStatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  ConsumerState<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends ConsumerState<FamilyMembersScreen> {
  void _showAddEditBottomSheet([FamilyMemberModel? existingMember]) {
    final authUser = ref.read(authStateProvider).value;
    if (authUser == null) return;

    final nameController = TextEditingController(text: existingMember?.name ?? '');
    final allergiesController = TextEditingController(text: existingMember?.allergies ?? '');
    final chronicController = TextEditingController(text: existingMember?.chronicConditions ?? '');

    String relationship = existingMember?.relationship ?? 'Parent';
    String gender = existingMember?.gender ?? 'Male';
    String bloodGroup = existingMember?.bloodGroup ?? 'O+';
    DateTime selectedDob = existingMember?.dateOfBirth ?? DateTime(1980, 1, 1);

    final relationships = ['Parent', 'Spouse', 'Child', 'Sibling', 'Other'];
    final genders = ['Male', 'Female', 'Other'];
    final bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-', 'Unknown'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existingMember == null ? 'Add Family Member' : 'Edit Family Member',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Full Name',
                    hint: 'Enter family member name',
                    controller: nameController,
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Relationship', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: relationship,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: relationships
                                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => relationship = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Gender', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: gender,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: genders
                                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => gender = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Date of Birth', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDob,
                                  firstDate: DateTime(1920),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setModalState(() => selectedDob = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat('yyyy-MM-dd').format(selectedDob),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const Icon(Icons.calendar_today, size: 18, color: AppTheme.primaryColor),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Blood Group', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: bloodGroup,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: bloodGroups
                                  .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => bloodGroup = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Known Allergies (Optional)',
                    hint: 'e.g. Penicillin, Dust, Nuts',
                    controller: allergiesController,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Chronic Conditions (Optional)',
                    hint: 'e.g. Diabetes, Hypertension, Asthma',
                    controller: chronicController,
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: existingMember == null ? 'Save Family Member' : 'Update Family Member',
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter family member name')),
                        );
                        return;
                      }

                      final service = ref.read(familyMemberServiceProvider);
                      final member = FamilyMemberModel(
                        id: existingMember?.id ?? '',
                        userId: authUser.uid,
                        name: nameController.text.trim(),
                        relationship: relationship,
                        gender: gender,
                        dateOfBirth: selectedDob,
                        bloodGroup: bloodGroup,
                        allergies: allergiesController.text.trim(),
                        chronicConditions: chronicController.text.trim(),
                        createdAt: existingMember?.createdAt ?? DateTime.now(),
                      );

                      if (existingMember == null) {
                        await service.addFamilyMember(member);
                      } else {
                        await service.updateFamilyMember(member);
                      }

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(existingMember == null ? 'Family member added' : 'Family member updated'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final familyMembersAsync = ref.watch(familyMembersStreamProvider);
    final authUser = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Members'),
        centerTitle: true,
      ),
      body: familyMembersAsync.when(
        data: (members) {
          if (members.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.family_restroom,
                        size: 64,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No Family Members Added',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add dependent profiles for parents, children, or spouse to manage their doctor appointments and medical records.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: '+ Add Family Member',
                      width: 220,
                      onPressed: () => _showAddEditBottomSheet(),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            child: Text(
                              member.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                                Text(
                                  '${member.relationship} • ${member.age} yrs (${member.gender})',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              member.bloodGroup,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _showAddEditBottomSheet(member),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Profile'),
                                  content: Text('Are you sure you want to remove ${member.name}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true && authUser != null) {
                                await ref
                                    .read(familyMemberServiceProvider)
                                    .deleteFamilyMember(authUser.uid, member.id);
                              }
                            },
                          ),
                        ],
                      ),
                      if (member.allergies.isNotEmpty || member.chronicConditions.isNotEmpty) ...[
                        const Divider(height: 24),
                        if (member.allergies.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Allergies: ${member.allergies}',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (member.chronicConditions.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.medical_information_outlined, size: 14, color: AppTheme.primaryColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Conditions: ${member.chronicConditions}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading family members: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditBottomSheet(),
        icon: const Icon(Icons.add),
        label: const Text('Add Member'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}
