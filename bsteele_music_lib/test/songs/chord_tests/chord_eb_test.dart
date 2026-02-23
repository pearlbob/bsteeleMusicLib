import 'package:bsteele_music_lib/songs/key.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

import '../chord_test.dart';

void main() {
  Logger.level = Level.warning;

  MajorKey key = MajorKey.Eb;

  group('testChordTranspose', () {
    test('testChordTranspose $key', () {
      testChordTranspose(key);
    });
  });
}
