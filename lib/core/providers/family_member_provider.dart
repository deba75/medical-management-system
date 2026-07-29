import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/family_member_model.dart';
import '../services/family_member_service.dart';
import 'auth_provider.dart';

final familyMemberServiceProvider = Provider<FamilyMemberService>((ref) {
  return FamilyMemberService();
});

final familyMembersStreamProvider = StreamProvider<List<FamilyMemberModel>>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return Stream.value([]);
  final service = ref.watch(familyMemberServiceProvider);
  return service.getFamilyMembers(authUser.uid);
});

final selectedFamilyMemberProvider = StateProvider<FamilyMemberModel?>((ref) => null);
