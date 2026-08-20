import 'package:neuroup/shared/models/user_profile.dart';

abstract class UserAdminRepository {
  Stream<List<UserProfile>> watchAllUsers();
  Future<void> updateUserRole(String userId, UserRole role);
}
