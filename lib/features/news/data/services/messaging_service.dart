import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:neuroup/core/env/env.dart';
import 'package:neuroup/core/services/logger_service.dart';

final _messagingProvider = Provider<FirebaseMessaging>(
  (ref) => FirebaseMessaging.instance,
);

final firebaseMessagingServiceProvider = Provider<MessagingService>(
  MessagingService.new,
);

final fcmTokenProvider = FutureProvider<String?>((ref) async {
  return ref.read(_messagingProvider).getToken();
});

class MessagingService {
  MessagingService(this._ref);
  final Ref _ref;

  static const _topicAll = 'all';
  static const _topicBreaking = 'news_breaking';
  static const _topicEducation = 'news_education';

  Future<void> initialize() async {
    final messaging = _ref.read(_messagingProvider);
    final settings = await messaging.requestPermission(
      badge: true,
    );
    LoggerService.info(
      'FCM permission: ${settings.authorizationStatus.name}',
    );

    FirebaseMessaging.onMessage.listen(_onForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);

    final token = await messaging.getToken();
    LoggerService.info('FCM token: $token');

    await subscribeToDefaultTopics();
  }

  Future<void> subscribeToDefaultTopics() async {
    if (!Env.firebaseConfigured) {
      LoggerService.warn(
        'FCM skipped: Firebase not configured (running in offline mode)',
      );
      return;
    }
    final messaging = _ref.read(_messagingProvider);
    try {
      await messaging.subscribeToTopic(_topicAll);
      await messaging.subscribeToTopic(_topicBreaking);
      await messaging.subscribeToTopic(_topicEducation);
    } catch (e, st) {
      LoggerService.error('FCM subscribe failed', e, st);
    }
  }

  Future<void> subscribe(String topic) async {
    await _ref.read(_messagingProvider).subscribeToTopic(topic);
  }

  Future<void> unsubscribe(String topic) async {
    await _ref.read(_messagingProvider).unsubscribeFromTopic(topic);
  }

  void _onForeground(RemoteMessage message) {
    LoggerService.info(
      'FCM foreground: ${message.notification?.title} '
      '${message.notification?.body}',
    );
  }

  void _onOpened(RemoteMessage message) {
    LoggerService.info('FCM opened: ${message.data}');
  }
}
