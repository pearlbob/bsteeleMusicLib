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
    var allSongPerformances = AllSongPerformances()..clear();
    var songs = [a, b];
    const int lastSung = 1639852279322;
    allSongPerformances.loadSongs(songs);
    for (var song in [a, b]) {
      for (var key in Key.values.toList().reversed) {
        if (key == Key.get(KeyEnum.Fs)) {
          continue; //  skip the duplicate
        }
        SongPerformance songPerformance = SongPerformance.fromSong(song, singer1, key, lastSung: lastSung);
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
      SongPerformance songPerformance =
          SongPerformance.fromSong(a, singer2, Key.get(KeyEnum.A), bpm: 120, lastSung: lastSung);
      expect(
          songPerformance.toString(),
          'SongPerformance{song: A by bob, _songId: Song_A_by_bob,'
          ' _singer: \'vicki\', _key: A, _bpm: 120, sung: 12/18/2021}');
      expect(songPerformance.songIdAsString, 'Song_A_by_bob');
      expect(songPerformance.singer, 'vicki');
      expect(songPerformance.key, Key.get(KeyEnum.A));
      expect(songPerformance.bpm, 120);
      expect(songPerformance.lastSung, lastSung);
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
          '[SongPerformance{song: A by bob, _songId: Song_A_by_bob, _singer: \'$singer1\', _key: G♭, _bpm: 100, sung: 12/18/2021}'
          ', SongPerformance{song: B by bob, _songId: Song_B_by_bob, _singer: \'bodhi\', _key: G♭, _bpm: 120, sung: 12/18/2021}]');
      expect(allSongPerformances.bySinger(singer2).toString(),
          '[SongPerformance{song: A by bob, _songId: Song_A_by_bob, _singer: \'$singer2\', _key: A, _bpm: 120, sung: 12/18/2021}]');

      logger.i('String toJsonStringFor($singer1): \'${allSongPerformances.toJsonStringFor(singer1)}\'');
      expect(
          allSongPerformances.toJsonStringFor(singer1),
          '[{"songId":"Song_A_by_bob","singer":"bodhi","key":9,"bpm":100,"lastSung":1639852279322},'
          '\n{"songId":"Song_B_by_bob","singer":"bodhi","key":9,"bpm":120,"lastSung":1639852279322}]\n');
      logger.i('String toJsonStringFor($singer2): \'${allSongPerformances.toJsonStringFor(singer2)}\'');
      expect(allSongPerformances.toJsonStringFor(singer2),
          '[{"songId":"Song_A_by_bob","singer":"vicki","key":0,"bpm":120,"lastSung":1639852279322}]\n');

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

      allSongPerformances.addSongPerformance(SongPerformance('Song_B_by_bob', singer1, Key.get(KeyEnum.G)));
      allSongPerformances.addSongPerformance(SongPerformance('Song_A_by_bob', singer1, Key.get(KeyEnum.F)));
      expect(allSongPerformances.length, 2);
      allSongPerformances.clear();
      expect(allSongPerformances.length, 0);
    }
  });

  test('song performance dates', () async {
    var a = Song.createSong('A', 'bob', 'bsteele.com', Key.getDefault(), 100, 4, 4, 'pearlbob',
        'i: A B C D V: D E F F# [ D C B A ]x2 c: D C G G', 'i:\nv: bob, bob, bob berand\nc: sing chorus here');

    var singer1 = 'bodhi';
    SongPerformance songPerformance = SongPerformance.fromSong(a, singer1, Key.get(KeyEnum.A));
    logger.d('${songPerformance}');
    expect(songPerformance.lastSungDateString, matches(r'^\d{1,2}/\d{1,2}/202\d$'));

    var next = SongPerformance.fromSong(a, singer1, Key.get(KeyEnum.A));
    await Future.delayed(const Duration(milliseconds: 2));
    expect(next.lastSung > songPerformance.lastSung, true);

    songPerformance = SongPerformance.fromJsonString(
        '{"songId":"Song_A_by_bob","singer":"bodhi","key":0,"bpm":100,"lastSung":1639848618406}');
    expect(songPerformance.lastSungDateString, '12/18/2021');

    songPerformance = SongPerformance.fromJsonString(
        '{"songId":"Song_A_by_bob","singer":"bodhi","key":0,"bpm":100,"lastSung":1548296878134}');
    expect(songPerformance.lastSungDateString, '1/23/2019');

    var allSongPerformances = AllSongPerformances()..clear();
    expect(allSongPerformances.length, 0);
    allSongPerformances.addSongPerformance(songPerformance);
    expect(allSongPerformances.length, 1);
    //  duplicate songs should not be duplicated
    allSongPerformances.addSongPerformance(songPerformance);
    expect(allSongPerformances.length, 1);
    allSongPerformances.addSongPerformance(songPerformance.update());
    expect(allSongPerformances.length, 1);
    allSongPerformances.addSongPerformance(songPerformance);
    expect(allSongPerformances.length, 1);

    allSongPerformances.loadSongs([a]);
    expect(
        allSongPerformances.bySong(a).toString(),
        '[SongPerformance{song: A by bob, _songId: Song_A_by_bob,'
        ' _singer: \'bodhi\', _key: A, _bpm: 100, sung: 1/23/2019}]');
  });

  test('song all performances', () async {
    var allSongPerformances = AllSongPerformances()..clear();
    expect(allSongPerformances.length, 0);
    allSongPerformances.addFromJsonString(
        '''[{"songId":"Song_All_I_Have_to_Do_Is_Dream_by_Everly_Brothers","singer":"Jill","key":3,"bpm":106,"lastSung":1639854884818},
{"songId":"Song_All_You_Need_is_Love_by_Beatles_The","singer":"Jill","key":6,"bpm":106,"lastSung":0},
{"songId":"Song_Angie_by_Rolling_Stones_The","singer":"Jill","key":6,"bpm":106,"lastSung":0},
{"songId":"Song_Back_in_the_USSR_by_Beatles_The","singer":"Bob","key":7,"bpm":106,"lastSung":0},
{"songId":"Song_Dont_Let_Me_Down_by_Beatles_The","singer":"Jill","key":0,"bpm":106,"lastSung":0}]
    ''');
    expect(allSongPerformances.length, 5);
    expect(allSongPerformances.bySinger('Jill').length, 4);
  });

  test('song performance updates', () async {
    var allSongPerformances = AllSongPerformances()..clear();

    allSongPerformances.addFromJsonString(
        '''[{"songId":"Song_All_I_Have_to_Do_Is_Dream_by_Everly_Brothers","singer":"Jill","key":3,"bpm":106,"lastSung":1439854884818},
{"songId":"Song_All_You_Need_is_Love_by_Beatles_The","singer":"Jill","key":6,"bpm":106,"lastSung":0},
{"songId":"Song_Angie_by_Rolling_Stones_The","singer":"Jill","key":6,"bpm":106,"lastSung":0},
{"songId":"Song_Back_in_the_USSR_by_Beatles_The","singer":"Bob","key":7,"bpm":106,"lastSung":0},
{"songId":"Song_Dont_Let_Me_Down_by_Beatles_The","singer":"Jill","key":0,"bpm":106,"lastSung":0}]
    ''');

    {
      //  update to a newer performance
      var performance = SongPerformance.fromJsonString('{"songId":"Song_All_I_Have_to_Do_Is_Dream_by_Everly_Brothers"'
          ',"singer":"Jill","key":3,"bpm":120,"lastSung":1639854884818}');
      expect(allSongPerformances.updateSongPerformance(performance), true);
      expect(allSongPerformances.updateSongPerformance(performance), false);
      for (var p in allSongPerformances.bySinger('Jill')) {
        if (p.songIdAsString == 'Song_All_I_Have_to_Do_Is_Dream_by_Everly_Brothers') {
          expect(p.lastSung, 1639854884818);
          expect(p.bpm, 120);
        }
      }
      expect(allSongPerformances.updateSongPerformance(performance), false);

      //  don't update to an older performance
      performance = SongPerformance.fromJsonString('{"songId":"Song_All_I_Have_to_Do_Is_Dream_by_Everly_Brothers"'
          ',"singer":"Jill","key":3,"bpm":110,"lastSung":1539854884818}'); //  older performance
      expect(allSongPerformances.updateSongPerformance(performance), false);
      for (var p in allSongPerformances.bySinger('Jill')) {
        if (p.songIdAsString == 'Song_All_I_Have_to_Do_Is_Dream_by_Everly_Brothers') {
          //  not updated since update was older
          expect(p.lastSung, 1639854884818);
          expect(p.bpm, 120);
        }
      }
    }

    {
      var a = Song.createSong('A', 'bob', 'bsteele.com', Key.getDefault(), 100, 4, 4, 'pearlbob',
          'i: A B C D V: D E F F# [ D C B A ]x2 c: D C G G', 'i:\nv: bob, bob, bob berand\nc: sing chorus here');
      var singer1 = 'bodhi';
      var performance = SongPerformance.fromSong(a, singer1, Key.get(KeyEnum.A));
      expect(allSongPerformances.updateSongPerformance(performance), true);
      expect(allSongPerformances.updateSongPerformance(performance), false);
      await Future.delayed(const Duration(milliseconds: 2));
      expect(allSongPerformances.updateSongPerformance(performance), false);
      performance = SongPerformance.fromSong(a, singer1, Key.get(KeyEnum.A));
      expect(allSongPerformances.updateSongPerformance(performance), true);
      expect(allSongPerformances.updateSongPerformance(performance), false);
      await Future.delayed(const Duration(milliseconds: 2));
      expect(allSongPerformances.updateSongPerformance(performance), false);
      performance = SongPerformance.fromSong(a, singer1, Key.get(KeyEnum.B));
      expect(allSongPerformances.updateSongPerformance(performance), true);
      expect(allSongPerformances.updateSongPerformance(performance), false);
      await Future.delayed(const Duration(milliseconds: 2));
      performance = SongPerformance.fromSong(a, singer1, Key.get(KeyEnum.B));
      expect(allSongPerformances.updateSongPerformance(performance), true);
      expect(allSongPerformances.updateSongPerformance(performance), false);
      expect(allSongPerformances.updateSongPerformance(performance), false);
      await Future.delayed(const Duration(milliseconds: 2));
      expect(allSongPerformances.updateSongPerformance(performance), false);
      expect(allSongPerformances.updateSongPerformance(performance), false);
    }
  });
}
