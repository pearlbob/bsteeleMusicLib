import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/songs/key.dart' as music_key;
import 'package:bsteele_music_lib/songs/song.dart';
import 'package:bsteele_music_lib/songs/song_base.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('moment songTime', () {
    const int beatsPerBar = 4;
    int bpm = 106;
    {
      var a = Song.createSong(
          'ive go the blanks',
          'bob',
          'bob',
          music_key.Key.get(music_key.KeyEnum.C),
          bpm,
          beatsPerBar,
          4,
          'pearl bob',
          'i: A B C D  v: G G G G, C C G G o: C C G G',
          'i: (instrumental)\nv: line 1\no:\n');

      var beatDur = a.getSecondsPerBeat();

      for (var moment in a.songMoments) {
        logger.d('${moment.momentNumber}: ${a.getSongTimeAtMoment(moment.momentNumber)}');

        double songTime = beatDur * beatsPerBar * moment.momentNumber;
        expect(a.getSongTimeAtMoment(moment.momentNumber), songTime);
        expect(SongBase.getBeatNumberAtTime(bpm, songTime), moment.beatNumber);
      }
    }
  });
}
