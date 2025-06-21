import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/util/us_timer.dart';
import 'package:test/test.dart';

void main() {
  test('test UsTimer', () async {
    var usTimer = UsTimer();
    await Future.delayed(const Duration(milliseconds: 100));
    logger.i('usTimer: $usTimer');
    expect(usTimer.seconds > 0.1, isTrue);

    await Future.delayed(const Duration(milliseconds: 100));
    var delta = usTimer.deltaUs;
    logger.i('delta: $delta');
    expect(delta < 200 * Duration.microsecondsPerMillisecond, isTrue);

    await Future.delayed(const Duration(milliseconds: 100));
    delta = usTimer.deltaUs;
    logger.i('delta: $delta');
    expect(delta < 200 * Duration.microsecondsPerMillisecond, isTrue);

    logger.i('usTimer: $usTimer');
    expect(usTimer.seconds > 0.3, isTrue);
  });
}
