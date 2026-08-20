import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:neuroup/core/env/env.dart';
import 'package:neuroup/core/providers/core_providers.dart';
import 'package:neuroup/shared/models/user_profile.dart';
import 'package:neuroup/features/admin/data/in_memory_user_admin_repository.dart';
import 'package:neuroup/features/admin/data/user_admin_repository_impl.dart';
import 'package:neuroup/features/admin/domain/repositories/user_admin_repository.dart';

final userAdminRepositoryProvider = Provider<UserAdminRepository>((ref) {
  if (!Env.firebaseConfigured) {
    return InMemoryUserAdminRepository();
  }
  return UserAdminRepositoryImpl(ref.watch(firestoreProvider));
});

final allUsersStreamProvider = StreamProvider<List<UserProfile>>((ref) {
  return ref.watch(userAdminRepositoryProvider).watchAllUsers();
});
