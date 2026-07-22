import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import 'package:neuroup/app/bootstrap.dart' show talker;

class LoggerService {
  LoggerService._();

  static final _log = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      printEmojis: false,
      dateTimeFormat: DateTimeFormat.dateAndTime,
    ),
  );

  static void debug(String msg, [Object? error, StackTrace? stack]) {
    if (kDebugMode) {
      talker.debug(msg, error, stack);
    }
  }

  static void info(String msg) => talker.info(msg);
  static void warn(String msg, [Object? error]) => talker.warning(msg, error);
  static void error(String msg, [Object? error, StackTrace? stack]) =>
      talker.error(msg, error, stack);

  static void critical(String msg, [Object? error, StackTrace? stack]) {
    if (error != null) {
      talker.handle(error, stack, msg);
    } else {
      talker.warning('CRITICAL: $msg');
    }
    _log.e('CRITICAL: $msg', error: error, stackTrace: stack);
  }
}
