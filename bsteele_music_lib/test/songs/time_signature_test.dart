
import 'package:bsteele_music_lib/songs/song_base.dart';
import 'package:bsteele_music_lib/songs/time_signature.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('time signature test', () {
    {
      SongBase a;
      for (var timeSignature in knownTimeSignatures) {
        a = SongBase(
          title: 'bob song',
          artist: 'bob',
          beatsPerBar: timeSignature.beatsPerBar,
          unitsPerMeasure: timeSignature.unitsPerMeasure,
        );
        expect(a.timeSignature, timeSignature);
      }
    }
  });

}
