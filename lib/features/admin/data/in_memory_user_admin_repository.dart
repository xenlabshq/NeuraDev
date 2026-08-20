import 'package:neuroup/shared/models/user_profile.dart';
import 'package:neuroup/features/admin/domain/repositories/user_admin_repository.dart';

/// Demo mod için sahte kullanıcı listesi — gerçek kullanıcı verisi yok,
/// sadece Yönetim Paneli arayüzünü göstermek için birkaç örnek profil.
class InMemoryUserAdminRepository implements UserAdminRepository {
  InMemoryUserAdminRepository()
    : _users = [
        const UserProfile(
          id: 'demo_admin_1',
          email: 'ayse@ornek.com',
          displayName: 'Ayşe Yılmaz',
          role: UserRole.student,
        ),
        const UserProfile(
          id: 'demo_admin_2',
          email: 'mert@ornek.com',
          displayName: 'Mert Kaya',
          role: UserRole.teacher,
        ),
        const UserProfile(
          id: 'demo_admin_3',
          email: 'zeynep@ornek.com',
          displayName: 'Zeynep Demir',
          role: UserRole.moderator,
        ),
      ];

  final List<UserProfile> _users;

  @override
  Stream<List<UserProfile>> watchAllUsers() =>
      Stream.value(List.unmodifiable(_users));

  @override
  Future<void> updateUserRole(String userId, UserRole role) async {
    final i = _users.indexWhere((u) => u.id == userId);
    if (i >= 0) _users[i] = _users[i].copyWith(role: role);
  }
}
