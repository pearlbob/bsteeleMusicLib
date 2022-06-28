import 'package:bsteeleMusicLib/songs/key.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

import '../Chord_test.dart';

void main() {
  Logger.level = Level.warning;

  Key key = Key.Fs;

  group('testChordTranspose', () {
    test('testChordTranspose $key', () {
      testChordTranspose(key);
    });
  });
}
