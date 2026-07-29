import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/family_member_model.dart';
import '../providers/family_member_provider.dart';
import '../theme/app_theme.dart';
import '../../screens/patient/profile/family_members_screen.dart';

class FamilyMemberSelector extends ConsumerWidget {
  final Function(FamilyMemberModel?)? onSelected;
  final bool showAddButton;

  const FamilyMemberSelector({
    super.key,
    this.onSelected,
    this.showAddButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyMembersAsync = ref.watch(familyMembersStreamProvider);
    final selectedMember = ref.watch(selectedFamilyMemberProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.people_alt_outlined, color: AppTheme.primaryColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Appointment For',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              if (showAddButton)
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FamilyMembersScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Manage'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          familyMembersAsync.when(
            data: (members) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Option for "Myself"
                    ChoiceChip(
                      label: const Text('Myself'),
                      selected: selectedMember == null,
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(selectedFamilyMemberProvider.notifier).state = null;
                          if (onSelected != null) onSelected!(null);
                        }
                      },
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: selectedMember == null ? Colors.white : AppTheme.textPrimaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: Colors.grey.shade100,
                      elevation: selectedMember == null ? 2 : 0,
                    ),
                    const SizedBox(width: 8),
                    // Family Members chips
                    ...members.map((member) {
                      final isSelected = selectedMember?.id == member.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          avatar: CircleAvatar(
                            backgroundColor: isSelected ? Colors.white24 : AppTheme.primaryColor.withOpacity(0.1),
                            child: Text(
                              member.name.isNotEmpty ? member.name[0].toUpperCase() : 'F',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          label: Text('${member.name} (${member.relationship})'),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              ref.read(selectedFamilyMemberProvider.notifier).state = member;
                              if (onSelected != null) onSelected!(member);
                            }
                          },
                          selectedColor: AppTheme.primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: Colors.grey.shade100,
                          elevation: isSelected ? 2 : 0,
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(
              height: 40,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (err, stack) => Text(
              'Failed to load family members',
              style: TextStyle(color: Colors.red.shade400, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
