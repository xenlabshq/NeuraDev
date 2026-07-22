import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/env/env.dart';
import '../../features/chat/presentation/pages/chat_room_page.dart';
import '../../features/chat/presentation/pages/unified_support_page.dart';
import '../../features/learning/presentation/pages/island_map_page.dart';
import '../../features/news/presentation/pages/news_detail_page.dart';
import '../../features/news/presentation/pages/news_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/reels/presentation/pages/reels_page.dart';
import '../pages/demo_landing_page.dart';
import 'home_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final initial = Env.firebaseConfigured ? '/lessons' : '/demo';

  return GoRouter(
    initialLocation: initial,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/demo',
        builder: (_, __) => const DemoLandingPage(),
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
