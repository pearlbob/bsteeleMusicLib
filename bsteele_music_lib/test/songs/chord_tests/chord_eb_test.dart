import 'package:bsteeleMusicLib/songs/key.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

import '../chord_test.dart';

void main() {
  Logger.level = Level.warning;

  Key key = Key.Eb;

  group('testChordTranspose', () {
    test('testChordTranspose $key', () {
      testChordTranspose(key);
    });
  });
}
