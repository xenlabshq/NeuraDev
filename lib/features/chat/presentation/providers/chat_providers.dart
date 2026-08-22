import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../shared/models/user_profile.dart';
import '../../data/repositories/support_chat_repository_impl.dart';
import '../../domain/entities/support_chat.dart';
import '../../domain/entities/support_message.dart';
import '../../domain/repositories/support_chat_repository.dart';

final supportChatRepositoryProvider = Provider<SupportChatRepository>(
  (ref) => SupportChatRepositoryImpl(ref.watch(firestoreProvider)),
);

/// Firebase Auth durumu + Firestore'daki gerçek rol.
/// AuthRepositoryImpl.authStateChanges() rolü users/{uid}.role'den okur;
/// burada FirebaseAuth'u doğrudan kullanmıyoruz çünkü role bilgisi
/// FirebaseAuth üzerinde tutulmuyor — eskiden burası rolü sabit `student`
/// dönerdi, bu yüzden Firebase'e gerçekten bağlandıktan sonra hiçbir
/// moderatör/admin kendi rolünü göremiyordu (haber yönetimi FAB'ı dahil).
final resolvedAuthUserProvider = StreamProvider<UserProfile?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Aktif kullanıcı.
final currentAuthUserProvider = Provider<UserProfile?>((ref) {
  return ref
      .watch(resolvedAuthUserProvider)
      .maybeWhen(data: (u) => u, orElse: () => null);
});

final mySupportChatStreamProvider = StreamProvider<List<SupportChat>>((ref) {
  final repo = ref.watch(supportChatRepositoryProvider);
  final user = ref.watch(currentAuthUserProvider);
  if (user == null) return const Stream.empty();
  return repo.watchChatsForUser(user.id);
});

final openChatsForModeratorsProvider = StreamProvider<List<SupportChat>>((ref) {
  final repo = ref.watch(supportChatRepositoryProvider);
  return repo.watchOpenChatsForModerators();
});

final chatMessagesStreamProvider =
    StreamProvider.family<List<SupportMessage>, String>((ref, chatId) {
      final repo = ref.watch(supportChatRepositoryProvider);
      return repo.watchMessages(chatId);
    });
