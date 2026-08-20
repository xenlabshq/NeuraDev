import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:neuroup/app/theme/colors.dart';
import 'package:neuroup/shared/models/user_profile.dart';
import '../providers/admin_providers.dart';

/// Kullanıcı rollerini yönetmek için admin-only sayfa. Erişim ve gerçek
/// yetkilendirme firestore.rules'da zorunlu kılınıyor (sadece isAdmin()
/// bir kullanıcının rolünü değiştirebilir); bu sayfa sadece istemci
/// tarafı kolaylık, geri kalan tüm yazma işlemleri sunucuda doğrulanır.
class AdminUsersPage extends ConsumerWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Yönetim Paneli')),
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('Kullanıcı bulunamadı'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _UserTile(user: users[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Yüklenemedi: $e')),
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  const _UserTile({required this.user});
  final UserProfile user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: Text(
            user.displayName.isNotEmpty
                ? user.displayName.substring(0, 1).toUpperCase()
                : '?',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(user.displayName),
        subtitle: Text(user.email),
        trailing: DropdownButton<UserRole>(
          value: user.role,
          underline: const SizedBox.shrink(),
          items: UserRole.values
              .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
              .toList(),
          onChanged: (role) async {
            if (role == null || role == user.role) return;
            final confirmed = await _confirmRoleChange(context, user, role);
            if (confirmed != true) return;
            await ref
                .read(userAdminRepositoryProvider)
                .updateUserRole(user.id, role);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${user.displayName} artık ${role.label}',
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<bool?> _confirmRoleChange(
    BuildContext context,
    UserProfile user,
    UserRole newRole,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rolü değiştir'),
        content: Text(
          '${user.displayName} kullanıcısının rolünü '
          '${user.role.label} → ${newRole.label} olarak değiştirmek '
          'istediğine emin misin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );
  }
}
