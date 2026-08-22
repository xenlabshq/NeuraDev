import 'package:flutter_test/flutter_test.dart';
import 'package:neuroup/features/admin/data/in_memory_user_admin_repository.dart';
import 'package:neuroup/shared/models/user_profile.dart';

void main() {
  test('watchAllUsers returns the 3 seeded demo users', () async {
    final repo = InMemoryUserAdminRepository();
    final users = await repo.watchAllUsers().first;
    expect(users.length, 3);
  });

  test('updateUserRole changes the role of the matching user', () async {
    final repo = InMemoryUserAdminRepository();
    final users = await repo.watchAllUsers().first;
    final target = users.first;

    await repo.updateUserRole(target.id, UserRole.admin);
    final updated = await repo.watchAllUsers().first;

    expect(updated.firstWhere((u) => u.id == target.id).role, UserRole.admin);
  });

  test('updateUserRole on an unknown id is a no-op', () async {
    final repo = InMemoryUserAdminRepository();
    final before = await repo.watchAllUsers().first;

    await repo.updateUserRole('does-not-exist', UserRole.admin);
    final after = await repo.watchAllUsers().first;

    expect(after, before);
  });

  test('setBanned(true) marks the matching user as banned', () async {
    final repo = InMemoryUserAdminRepository();
    final users = await repo.watchAllUsers().first;
    final target = users.first;
    expect(target.banned, isFalse);

    await repo.setBanned(target.id, true);
    final updated = await repo.watchAllUsers().first;

    expect(updated.firstWhere((u) => u.id == target.id).banned, isTrue);
  });

  test('setBanned(false) lifts a ban', () async {
    final repo = InMemoryUserAdminRepository();
    final users = await repo.watchAllUsers().first;
    final target = users.first;
    await repo.setBanned(target.id, true);

    await repo.setBanned(target.id, false);
    final updated = await repo.watchAllUsers().first;

    expect(updated.firstWhere((u) => u.id == target.id).banned, isFalse);
  });
}
