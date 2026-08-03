import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:neuroup/core/env/env.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final firebaseStorageProvider = Provider<FirebaseStorage>(
  (ref) => FirebaseStorage.instance,
);

final firebaseMessagingProvider = Provider<FirebaseMessaging>(
  (ref) => FirebaseMessaging.instance,
);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {'Content-Type': 'application/json'},
    ),
  );
  return dio;
});

/// SharedPreferences instance — `FutureProvider` çünkü asenkron
/// başlatılıyor. Uygulama genelinde `ref.watch(sharedPrefsProvider).value`
/// olarak tüketilir.
final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs;
});

/// Hive kutu isimleri — merkezi registry, yanlış isim riskini önler.
class HiveBoxes {
  HiveBoxes._();
  static const String appSettings = 'app_settings_box';
  static const String learningProgress = 'learning_progress_box';
  static const String newsCache = 'news_cache_box';
}

/// Açılmış Hive kutularına erişim. `bootstrap.dart`'ta
/// `Hive.initFlutter()` ve ilgili kutular `openBox` ile açılır.
final appSettingsBoxProvider = Provider<Box>(
  (ref) => Hive.box(HiveBoxes.appSettings),
);
final learningProgressBoxProvider = Provider<Box>(
  (ref) => Hive.box(HiveBoxes.learningProgress),
);
final newsCacheBoxProvider = Provider<Box>(
  (ref) => Hive.box(HiveBoxes.newsCache),
);
