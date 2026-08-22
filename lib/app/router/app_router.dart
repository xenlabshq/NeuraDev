import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/chat/presentation/pages/chat_room_page.dart';
import '../../features/chat/presentation/pages/unified_support_page.dart';
import '../../features/chat/presentation/providers/chat_providers.dart';
import '../../features/learning/presentation/pages/island_map_page.dart';
import '../../features/news/presentation/pages/news_detail_page.dart';
import '../../features/news/presentation/pages/news_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/reels/presentation/pages/reels_page.dart';
import 'home_shell.dart';

/// go_router'ın `redirect` callback'i senkron çalışır; auth durumu
/// değiştiğinde (stream event'i) router'ı yeniden değerlendirmeye
/// zorlamak için bu ChangeNotifier kullanılır (`refreshListenable`).
class _AuthRefreshNotifier extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// Giriş yapmadan da gezilebilecek rotalar. Reels bilinçli olarak herkese
/// açık — yeni ziyaretçi kendi hesabı olmadan da içeriğe göz atabilsin.
/// Reels'e kendi oyununu göndermek ise (bkz. ReelSubmitPage) hâlâ giriş
/// gerektiriyor, ayrıca oradan kontrol ediliyor.
const _publicPaths = {'/reels', '/login', '/register'};

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier();
  ref.listen(currentAuthUserProvider, (_, _) => refresh.ping());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/lessons',
    debugLogDiagnostics: false,
    refreshListenable: refresh,
    redirect: (context, state) {
      final isAuthed = ref.read(currentAuthUserProvider) != null;
      final target = state.matchedLocation;
      final isAuthRoute = target == '/login' || target == '/register';

      if (!isAuthed && !_publicPaths.contains(target)) return '/login';
      if (isAuthed && isAuthRoute) return '/lessons';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/lessons',
            builder: (_, __) => const IslandMapPage(),
          ),
          GoRoute(
            path: '/reels',
            builder: (_, __) => const ReelsPage(),
          ),
          GoRoute(
            path: '/news',
            builder: (_, __) => const NewsPage(),
            routes: [
              GoRoute(
                path: ':newsId',
                builder: (_, state) => NewsDetailPage(
                  newsId: state.pathParameters['newsId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/support',
            builder: (_, __) => const UnifiedSupportPage(),
            routes: [
              GoRoute(
                path: ':channelId',
                builder: (_, state) => ChatRoomPage(
                  channelId: state.pathParameters['channelId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfilePage(),
          ),
        ],
      ),
    ],
  );
});
