import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/key.dart' as music_key;
import 'package:bsteeleMusicLib/songs/song.dart';
import 'package:bsteeleMusicLib/songs/songBase.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('test SongId', () {
    final int beatsPerBar = 4;
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

      expect(a.songId.toString(), 'Song_ive_go_the_blanks_by_bob');
      expect(a.songId.toUnderScorelessString(), 'ive go the blanks by bob');
    }
    {
      var a = Song.createSong(
          'I\'ve got the blanks',
          'bob',
          'bob',
          music_key.Key.get(music_key.KeyEnum.C),
          bpm,
          beatsPerBar,
          4,
          'pearl bob',
          'i: A B C D  v: G G G G, C C G G o: C C G G',
          'i: (instrumental)\nv: line 1\no:\n');

      expect(a.songId.toString(), 'Song_Ive_got_the_blanks_by_bob');
      expect(a.songId.toUnderScorelessString(), 'Ive got the blanks by bob');
    }
  });
}
