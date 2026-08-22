import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:neuroup/app/theme/colors.dart';
import 'package:neuroup/features/chat/presentation/providers/chat_providers.dart'
    show currentAuthUserProvider;
import 'package:neuroup/l10n/gen/app_localizations.dart';
import 'package:neuroup/shared/models/user_profile.dart';
import 'package:neuroup/shared/utils/user_role_labels.dart';
import '../providers/admin_providers.dart';

/// Kullanıcı rollerini yönetmek için admin-only sayfa. Erişim ve gerçek
/// yetkilendirme firestore.rules'da zorunlu kılınıyor (sadece isAdmin()
/// bir kullanıcının rolünü değiştirebilir); bu sayfa sadece istemci
/// tarafı kolaylık, geri kalan tüm yazma işlemleri sunucuda doğrulanır.
class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final _searchCtl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersStreamProvider);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAdminTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtl,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: l10n.adminSearchByEmailHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() {
                          _searchCtl.clear();
                          _query = '';
                        }),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: usersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return Center(child: Text(l10n.adminNoUsersFound));
                }
                final filtered = _query.isEmpty
                    ? users
                    : users
                          .where(
                            (u) =>
                                u.email.toLowerCase().contains(_query) ||
                                u.displayName.toLowerCase().contains(_query),
                          )
                          .toList();
                if (filtered.isEmpty) {
                  return Center(child: Text(l10n.adminNoUsersMatchSearch));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _UserTile(user: filtered[i]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text(l10n.adminLoadFailed(e.toString()))),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  const _UserTile({required this.user});
  final UserProfile user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isSelf = ref.watch(currentAuthUserProvider)?.id == user.id;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: user.banned
              ? AppColors.error.withValues(alpha: 0.6)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
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
        subtitle: Text(
          user.banned ? '${user.email} · ${l10n.adminBannedLabel}' : user.email,
          style: user.banned
              ? TextStyle(color: AppColors.error.withValues(alpha: 0.9))
              : null,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<UserRole>(
              value: user.role,
              underline: const SizedBox.shrink(),
              items: UserRole.values
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.localizedLabel(l10n)),
                    ),
                  )
                  .toList(),
              onChanged: (role) async {
                if (role == null || role == user.role) return;
                final confirmed = await _confirmRoleChange(
                  context,
                  user,
                  role,
                );
                if (confirmed != true) return;
                await ref
                    .read(userAdminRepositoryProvider)
                    .updateUserRole(user.id, role);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.adminRoleChanged(
                          user.displayName,
                          role.localizedLabel(l10n),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
            IconButton(
              tooltip: isSelf
                  ? l10n.adminCannotBanSelf
                  : user.banned
                  ? l10n.adminUnbanAction
                  : l10n.adminBanAction,
              icon: Icon(
                user.banned
                    ? Icons.lock_open_rounded
                    : Icons.block_rounded,
                color: isSelf
                    ? Theme.of(context).disabledColor
                    : AppColors.error,
              ),
              onPressed: isSelf
                  ? null
                  : () => _confirmBanToggle(context, ref, user),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmBanToggle(
    BuildContext context,
    WidgetRef ref,
    UserProfile user,
  ) async {
    final l10n = AppLocalizations.of(context);
    final nextBanned = !user.banned;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          nextBanned ? l10n.adminBanConfirmTitle : l10n.adminUnbanConfirmTitle,
        ),
        content: Text(
          nextBanned
              ? l10n.adminBanConfirmMessage(user.displayName)
              : l10n.adminUnbanConfirmMessage(user.displayName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionGiveUp),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(nextBanned ? l10n.adminBanAction : l10n.adminUnbanAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(userAdminRepositoryProvider).setBanned(user.id, nextBanned);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nextBanned
              ? l10n.adminUserBanned(user.displayName)
              : l10n.adminUserUnbanned(user.displayName),
        ),
      ),
    );
  }

  Future<bool?> _confirmRoleChange(
    BuildContext context,
    UserProfile user,
    UserRole newRole,
  ) {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminChangeRoleTitle),
        content: Text(
          l10n.adminChangeRoleConfirm(
            user.displayName,
            user.role.localizedLabel(l10n),
            newRole.localizedLabel(l10n),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionGiveUp),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.actionChange),
          ),
        ],
      ),
    );
  }
}
