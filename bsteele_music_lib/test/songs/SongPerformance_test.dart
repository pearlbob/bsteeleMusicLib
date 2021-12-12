import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/key.dart';
import 'package:bsteeleMusicLib/songs/song.dart';
import 'package:bsteeleMusicLib/songs/songPerformance.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.debug;

  test('song performance', () {
    var a = Song.createSong('A', 'bob', 'bsteele.com', Key.getDefault(), 100, 4, 4, 'pearlbob',
        'i: A B C D V: D E F F# [ D C B A ]x2 c: D C G G', 'i:\nv: bob, bob, bob berand\nc: sing chorus here');
    var b = Song.createSong('B', 'bob', 'bsteele.com', Key.get(KeyEnum.G), 120, 4, 4, 'pearlbob',
        'i: B B B B V: [ A B C D ]x2 ', 'i:\nv: bob, bob, bob berand\nV: sing verse here');

    var singer1 = 'bodhi';
    for (var song in [a, b]) {
      for (var key in Key.values) {
        if (key == Key.get(KeyEnum.Fs)) {
          continue; //  skip the duplicate
        }
        SongPerformance songPerformance = SongPerformance(song.songId.toString(), singer1, key);
        logger.d('songPerformance.toJson: \'${songPerformance.toJsonString()}\'');

        var songPerformanceFromJson = SongPerformance.fromJsonString(songPerformance.toJsonString());
        expect(songPerformanceFromJson, songPerformance);
      }
    }
    var allSongPerformances = AllSongPerformances();
    var songs = [a, b];
    allSongPerformances.loadSongs(songs);
    for (var song in [a, b]) {
      for (var key in Key.values.toList().reversed) {
        if (key == Key.get(KeyEnum.Fs)) {
          continue; //  skip the duplicate
        }
        SongPerformance songPerformance = SongPerformance.fromSong(song, singer1, key);
        logger.d('songPerformance.toJson: \'${songPerformance.toJsonString()}\'');

        var songPerformanceFromJson = SongPerformance.fromJsonString(songPerformance.toJsonString());
        expect(songPerformanceFromJson, songPerformance);
        allSongPerformances.addSongPerformance(songPerformanceFromJson);
        expect(songPerformanceFromJson.song, song);
      }
    }
    {
      expect(allSongPerformances.bySinger(singer1).length, 2);
      var singer2 = 'vicki';
      expect(allSongPerformances.bySinger(singer2).length, 0);
      SongPerformance songPerformance = SongPerformance.fromSong(a, singer2, Key.get(KeyEnum.A), bpm: 120);
      expect(songPerformance.toString(),
          'SongPerformance{song: A by bob, _songId: Song_A_by_bob, _singer: \'vicki\', _key: A, _bpm: 120}');
      logger.d('songPerformance: $songPerformance');
      allSongPerformances.addSongPerformance(songPerformance);
      expect(allSongPerformances.bySinger(singer2).length, 1);

      expect(allSongPerformances.setOfSingers().toList(), [singer1, singer2]);

      logger.d('allSongPerformances:         ${allSongPerformances.toJsonString()}');
      String asJsonString = allSongPerformances.toJsonString();
      allSongPerformances.fromJsonString(allSongPerformances.toJsonString());
      logger.d('allSongPerformancesFromJson: ${allSongPerformances.toJsonString()}');
      expect(asJsonString, allSongPerformances.toJsonString());
      allSongPerformances.loadSongs(songs);
      expect(
          allSongPerformances.bySinger(singer1).toString(),
          '[SongPerformance{song: A by bob, _songId: Song_A_by_bob, _singer: \'$singer1\', _key: G♭, _bpm: 100}'
          ', SongPerformance{song: B by bob, _songId: Song_B_by_bob, _singer: \'bodhi\', _key: G♭, _bpm: 120}]');
      expect(allSongPerformances.bySinger(singer2).toString(),
          '[SongPerformance{song: A by bob, _songId: Song_A_by_bob, _singer: \'$singer2\', _key: A, _bpm: 120}]');

      logger.i('String toJsonStringFor($singer1): \'${allSongPerformances.toJsonStringFor(singer1)}\'');
      expect(
          allSongPerformances.toJsonStringFor(singer1),
          '[{"songId":"Song_A_by_bob","singer":"bodhi","key":9,"bpm":100}'
          ',{"songId":"Song_B_by_bob","singer":"bodhi","key":9,"bpm":120}]');
      logger.i('String toJsonStringFor($singer2): \'${allSongPerformances.toJsonStringFor(singer2)}\'');
      expect(allSongPerformances.toJsonStringFor(singer2),
          '[{"songId":"Song_A_by_bob","singer":"vicki","key":0,"bpm":120}]');

      logger.i('$singer1: ${allSongPerformances.bySinger(singer1).map((e) {
        return '${e.song?.title} by ${e.song?.artist} in ${e.key}';
      })}');
      logger.i('$singer2: ${allSongPerformances.bySinger(singer2).map((e) {
        return '${e.song?.title} by ${e.song?.artist} in ${e.key}';
      })}');

      expect(
          allSongPerformances.bySinger(singer1).map((e) {
            return '${e.song?.title} by ${e.song?.artist} in ${e.key}';
          }).toString(),
          '(A by bob in G♭, B by bob in G♭)');
      expect(
          allSongPerformances.bySinger(singer2).map((e) {
            return '${e.song?.title} by ${e.song?.artist} in ${e.key}';
          }).toString(),
          '(A by bob in A)');

      allSongPerformances.removeSingerSong(
        singer1,
        'Song_B_by_bob',
      );
      expect(
          allSongPerformances.bySinger(singer1).map((e) {
            return '${e.song?.title} by ${e.song?.artist} in ${e.key}';
          }).toString(),
          '(A by bob in G♭)');
      allSongPerformances.addSongPerformance(SongPerformance('Song_B_by_bob', singer1, Key.get(KeyEnum.G)));
      expect(
          allSongPerformances.bySinger(singer1).map((e) {
            return '${e.song?.title} by ${e.song?.artist} in ${e.key}';
          }).toString(),
          '(A by bob in G♭, B by bob in G)');

      expect(allSongPerformances.length, 3);
      allSongPerformances.removeSinger('bob');
      expect(allSongPerformances.length, 3);
      allSongPerformances.removeSinger(singer1);
      expect(allSongPerformances.length, 1);
      allSongPerformances.removeSinger(singer2);
      expect(allSongPerformances.length, 0);
    }
  });
}
