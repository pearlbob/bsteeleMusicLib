import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/songs/mode.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('test modes', () {
    logger.i('modes:');
    for (var mode in Mode.values) {
      logger.i('    ${mode.name}');
    }
  });
}
