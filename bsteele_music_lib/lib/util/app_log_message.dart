import 'package:logger/logger.dart';

import '../app_logger.dart';

const Level _logAppLogMessage = Level.debug;

int _lastMessageEpochUs = DateTime.now().microsecondsSinceEpoch;

void appLogMessage(String message) {
  var t = DateTime.now();
  var duration = Duration(microseconds: t.microsecondsSinceEpoch - _lastMessageEpochUs);
  _lastMessageEpochUs = t.microsecondsSinceEpoch;
  var m = '// $t +$duration: $message';
  logger.log(_logAppLogMessage, m);
}
