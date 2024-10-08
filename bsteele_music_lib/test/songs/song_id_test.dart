import 'dart:collection';

import 'package:bsteele_music_lib/songs/key.dart';
import 'package:bsteele_music_lib/songs/song.dart';
import 'package:bsteele_music_lib/songs/song_id.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('test SongId', () {
    const int beatsPerBar = 4;
    int bpm = 106;
    {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bsteele.com',
          key: Key.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'i: A B C D  v: G G G G, C C G G o: C C G G',
          rawLyrics: 'i: (instrumental)\nv: line 1\no:\n');

      expect(a.songId.toString(), 'Song_ive_go_the_blanks_by_bob');
      expect(a.songId.toUnderScorelessString(), 'ive go the blanks by bob');
    }
    {
      var a = Song(
          title: 'I\'ve got the blanks',
          artist: 'bob',
          copyright: 'bsteele.com',
          key: Key.C,
          beatsPerMinute: bpm,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D  v: G G G G, C C G G o: C C G G',
          rawLyrics: 'i: (instrumental)\nv: line 1\no:\n');

      expect(a.songId.toString(), 'Song_Ive_got_the_blanks_by_bob');
      expect(a.songId.toUnderScorelessString(), 'Ive got the blanks by bob');
    }
  });

  test('test SongId format', () {
    SongId.fromString('Song_ive_go_the_blanks_by_bob');
    SongId.fromString('Song_ive_go_the_blanks_by_bob_cover_by_George');

    try {
      SongId.fromString('Song_i\'ve_go_the_blanks_by_bob_cover_by_George'); //  bad id
      throw Exception('bad SongId format checking');
    } on AssertionError catch (_) {
      //  failure is correct
    }

    try {
      SongId.fromString('song_ive_go_the_blanks_by_bob_cover_by_George'); //  bad id
      throw Exception('bad SongId format checking');
    } on AssertionError catch (_) {
      //  failure is correct
    }
  });

  test('song delete songs that are very similar', () {
    int beatsPerBar = 4;
    int bpm = 106;

    final SplayTreeSet<Song> allSongs = SplayTreeSet();

    var song1 = Song(
        title: 'A song',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: Key.C,
        beatsPerMinute: bpm,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        user: 'pearl bob',
        chords: 'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ',
        rawLyrics: 'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');

    allSongs.add(song1);
    expect(allSongs.length, 1);
    var song2 = Song(
        title: 'A Song',
        //  capitalization change!
        artist: 'bob',
        copyright: 'bsteele.com',
        key: Key.C,
        beatsPerMinute: bpm,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        user: 'pearl bob',
        chords: 'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ',
        rawLyrics: 'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');

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
