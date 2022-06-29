import 'dart:collection';

import 'package:bsteeleMusicLib/songs/key.dart' as music_key;
import 'package:bsteeleMusicLib/songs/key.dart';
import 'package:bsteeleMusicLib/songs/song.dart';
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

  test('song delete songs that are very similar', () {
    int beatsPerBar = 4;
    int bpm = 106;

    final SplayTreeSet<Song> allSongs = SplayTreeSet();

    var song1 = Song.createSong(
        'A song',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        bpm,
        beatsPerBar,
        4,
        'bob',
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    allSongs.add(song1);
    expect(allSongs.length, 1);
    var song2 = Song.createSong(
        'A Song',
        //  capitalization change!
        'bob',
        'bsteele.com',
        Key.getDefault(),
        bpm,
        beatsPerBar,
        4,
        'bob',
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    allSongs.add(song2);
    expect(allSongs.length, 2);

    allSongs.remove(song2);
    expect(allSongs.length, 1);

    //  duplicate should not be listed
    allSongs.add(song1);
    expect(allSongs.length, 1);

    //  duplicate should not be listed
    var song3 = song1.copySong();
    allSongs.add(song3);
    expect(allSongs.length, 1);

    //  change of cover artist makes new song
    song3.coverArtist = 'Joe';
    allSongs.add(song3);
    expect(allSongs.length, 2);

    allSongs.remove(song1);
    expect(allSongs.length, 1);

    allSongs.remove(song3);
    expect(allSongs.length, 0);
  });
}
