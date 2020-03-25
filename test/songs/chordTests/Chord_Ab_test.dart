import 'package:bsteeleMusicLib/songs/key.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

import '../Chord_test.dart';

void main() {
  Logger.level = Level.warning;

  KeyEnum keyEnum = KeyEnum.Ab;

  test('testChordTranspose $keyEnum', () {
    testChordTranspose(Key.get(keyEnum));
  });

}
