import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/songs/bass.dart';
import 'package:bsteele_music_lib/songs/pitch.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('pitch mapping testing', () {
    for (Pitch pitch in Pitch.flats) {
      logger.i('${pitch.toString()}: ${Bass.mapPitchToBassFret(pitch)}');
    }
  });
}
