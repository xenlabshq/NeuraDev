import 'package:flutter_test/flutter_test.dart';
import 'package:neuroup/core/env/feature_flags.dart';

void main() {
  test(
    'all feature flags default to off when not passed via --dart-define',
    () {
      expect(FeatureFlags.geminiChatEnabled, isFalse);
      expect(FeatureFlags.sentryPerformanceEnabled, isFalse);
    },
  );
}
