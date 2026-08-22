import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:neuroup/shared/models/user_profile.dart';
import 'package:neuroup/features/admin/domain/repositories/user_admin_repository.dart';

class UserAdminRepositoryImpl implements UserAdminRepository {
  UserAdminRepositoryImpl(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  @override
  Stream<List<UserProfile>> watchAllUsers() {
    return _users
        .orderBy('displayName')
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  @override
  Future<void> updateUserRole(String userId, UserRole role) async {
    await _users.doc(userId).update({'role': role.name});
  }

  @override
  Future<void> setBanned(String userId, bool banned) async {
    await _users.doc(userId).update({'banned': banned});
  }

  UserProfile _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserProfile(
      id: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == data['role'],
        orElse: () => UserRole.student,
      ),
      banned: data['banned'] as bool? ?? false,
    );
  }
}
