import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/songs/key.dart';
import 'package:bsteele_music_lib/songs/song.dart';
import 'package:bsteele_music_lib/songs/song_performance.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';
import 'package:compute/compute.dart';

void main() {
  Logger.level = Level.info;

  test('song performance', () async {
    var a = Song(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: 4,
        unitsPerMeasure: 4,
        user: 'pearl bob',
        chords: 'i: A B C D V: D E F F# [ D C B A ]x2 c: D C G G',
        rawLyrics: 'i:\nv: bob, bob, bob berand\nc: sing chorus here');

    var b = Song(
        title: 'B',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: Key.G,
        beatsPerMinute: 120,
        beatsPerBar: 4,
        unitsPerMeasure: 4,
        user: 'pearlbob',
        chords: 'i: B B B B V: [ A B C D ]x2 ',
        rawLyrics: 'i:\nv: bob, bob, bob berand\nV: sing verse here');

    var singer1 = 'bodhi';
    for (var song in [a, b]) {
      for (var key in Key.values) {
        if (key == Key.Fs) {
          continue; //  skip the duplicate
        }
        SongPerformance songPerformance = SongPerformance(song.songId.toString(), singer1, key: key);
        logger.d('songPerformance.toJson: \'${songPerformance.toJsonString()}\'');

        var songPerformanceFromJson = SongPerformance.fromJsonString(songPerformance.toJsonString());
        expect(songPerformanceFromJson, songPerformance);
      }
    }
    var allSongPerformances = AllSongPerformances.test();
    var songs = [a, b];
    const int lastSung = 1639852279322;
    allSongPerformances.loadSongs(songs);
    for (var song in [a, b]) {
      for (var key in Key.values.toList().reversed) {
        if (key == Key.Fs) {
          continue; //  skip the duplicate
        }
        SongPerformance songPerformance = SongPerformance.fromSong(song, singer1, key: key, lastSung: lastSung);
        logger.d('songPerformance.toJson: \'${songPerformance.toJsonString()}\'');

        var songPerformanceFromJson = SongPerformance.fromJsonString(songPerformance.toJsonString());
        expect(songPerformanceFromJson, songPerformance);
        songPerformanceFromJson = allSongPerformances.addSongPerformance(songPerformanceFromJson);
        expect(songPerformanceFromJson.song, song);
      }
    }
    {
      expect(allSongPerformances.bySinger(singer1).length, 2);
      var singer2 = 'vicki';
      expect(allSongPerformances.bySinger(singer2).length, 0);
      SongPerformance songPerformance = SongPerformance.fromSong(a, singer2, key: Key.A, bpm: 120, lastSung: lastSung);
      expect(
          songPerformance.toString(),
          'SongPerformance{song: A by bob, _songId: Song_A_by_bob,'
          ' _singer: \'vicki\', key: A, _bpm: 120, last sung: 12/18/2021}');
      expect(songPerformance.songId, 'Song_A_by_bob');
      expect(songPerformance.singer, 'vicki');
      expect(songPerformance.key, Key.A);
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
          '[SongPerformance{song: A by bob, _songId: Song_A_by_bob, _singer: \'$singer1\', key: G♭, _bpm: 100, last sung: 12/18/2021}'
          ', SongPerformance{song: B by bob, _songId: Song_B_by_bob, _singer: \'bodhi\', key: G♭, _bpm: 120, last sung: 12/18/2021}]');
      expect(allSongPerformances.bySinger(singer2).toString(),
          '[SongPerformance{song: A by bob, _songId: Song_A_by_bob, _singer: \'$singer2\', key: A, _bpm: 120, last sung: 12/18/2021}]');

      logger.i('String toJsonStringFor($singer1): \'${allSongPerformances.toJsonStringFor(singer1)}\'');
      expect(
          allSongPerformances.toJsonStringFor(singer1),
          '[{"songId":"Song_A_by_bob","singer":"bodhi","bpm":100,"firstSung":1639852279322,"lastSung":1639852279322,"key":"Gb"},\n'
          '{"songId":"Song_B_by_bob","singer":"bodhi","bpm":120,"firstSung":1639852279322,"lastSung":1639852279322,"key":"Gb"}]\n');
      logger.i('String toJsonStringFor($singer2): \'${allSongPerformances.toJsonStringFor(singer2)}\'');
      expect(allSongPerformances.toJsonStringFor(singer2),
          '[{"songId":"Song_A_by_bob","singer":"vicki","bpm":120,"firstSung":1639852279322,"lastSung":1639852279322,"key":"A"}]\n');

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
      allSongPerformances.addSongPerformance(SongPerformance('Song_B_by_bob', singer1, key: Key.G));
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

      allSongPerformances.addSongPerformance(SongPerformance('Song_B_by_bob', singer1, key: Key.G));
      allSongPerformances.addSongPerformance(SongPerformance('Song_A_by_bob', singer1, key: Key.F));
      expect(allSongPerformances.length, 2);
      allSongPerformances.clear();
      expect(allSongPerformances.length, 0);
    }
  });

  test('song performance dates', () async {
    await compute<void, void>((_) async {
      //  run this test in an isolate so the singleton allSongPerformances is not affected by other
      //  tests running in parallel.
      test('performance dates', () async {
        var a = Song(
            title: 'A',
            artist: 'bob',
            copyright: 'bsteele.com',
            key: Key.getDefault(),
            beatsPerMinute: 100,
            beatsPerBar: 4,
            unitsPerMeasure: 4,
            user: 'pearlbob',
            chords: 'i: A B C D V: D E F F# [ D C B A ]x2 c: D C G G',
            rawLyrics: 'i:\nv: bob, bob, bob berand\nc: sing chorus here');

        var singer1 = 'bodhi';
        SongPerformance songPerformance = SongPerformance.fromSong(a, singer1, key: Key.A);
        logger.d('$songPerformance');
        expect(songPerformance.lastSungDateString, matches(r'^\d{1,2}/\d{1,2}/202\d$'));

        var next = SongPerformance.fromSong(a, singer1, key: Key.A);
        await Future.delayed(const Duration(seconds: 2));
        logger.i('songPerformance: $songPerformance');
        logger.i('next: $next');
        expect(next.lastSung > songPerformance.lastSung, true);

        songPerformance = SongPerformance.fromJsonString(
            '{"songId":"Song_A_by_bob","singer":"bodhi","key":0,"bpm":100,"lastSung":1639848618406}');
        expect(songPerformance.lastSungDateString, '12/18/2021');

        songPerformance = SongPerformance.fromJsonString(
            '{"songId":"Song_A_by_bob","singer":"bodhi","key":0,"bpm":100,"lastSung":1548296878134}');
        expect(songPerformance.lastSungDateString, '1/23/2019');

        var allSongPerformances = AllSongPerformances.test();
        expect(allSongPerformances.length, 0);
        allSongPerformances.addSongPerformance(songPerformance);
        expect(allSongPerformances.length, 1);
        //  duplicate songs should not be duplicated
        allSongPerformances.addSongPerformance(songPerformance);
        expect(allSongPerformances.length, 1);
        allSongPerformances.addSongPerformance(songPerformance.copyWith());
        expect(allSongPerformances.length, 1);
        allSongPerformances.addSongPerformance(songPerformance);
        expect(allSongPerformances.length, 1);

        allSongPerformances.loadSongs([a]);
        expect(
            allSongPerformances.bySong(a).toString(),
            '[SongPerformance{song: A by bob, _songId: Song_A_by_bob,'
            ' _singer: \'bodhi\', _key: A, _bpm: 100, sung: 1/23/2019}]');
      });
    }, null);
  });

  test('song all performances', () async {
    var allSongPerformances = AllSongPerformances.test();
    expect(allSongPerformances.length, 0);
    var singer = 'bob';
    allSongPerformances.addFromJsonString(
        '''[{"songId":"Song_All_I_Have_to_Do_Is_Dream_by_Everly_Brothers","singer":"Jill","key":3,"bpm":106,"lastSung":1639854884818},
{"songId":"Song_All_You_Need_is_Love_by_Beatles_The","singer":"Jill","key":6,"bpm":106,"lastSung":0},
{"songId":"Song_Angie_by_Rolling_Stones_The","singer":"Jill","key":6,"bpm":106,"lastSung":0},
{"songId":"Song_Back_in_the_USSR_by_Beatles_The","singer":"$singer","key":7,"bpm":106,"lastSung":0},
{"songId":"Song_Dont_Let_Me_Down_by_Beatles_The","singer":"Jill","key":0,"bpm":106,"lastSung":0}]
    ''');
    expect(allSongPerformances.length, 5);
    expect(allSongPerformances.bySinger('Jill').length, 4);
    var performance =
        allSongPerformances.findBySingerSongId(singer: singer, songIdAsString: 'Song_Back_in_the_USSR_by_Beatles_The');
    expect(performance, isNotNull);
    expect(performance!.singer, singer);
    expect(performance.song, isNull);
    expect(performance.songId, 'Song_Back_in_the_USSR_by_Beatles_The');
    expect(allSongPerformances.length, 5);

    var a = Song(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: 4,
        unitsPerMeasure: 4,
        user: 'pearlbob',
        chords: 'i: A B C D V: D E F F# [ D C B A ]x2 c: D C G G',
        rawLyrics: 'i:\nv: bob, bob, bob berand\nc: sing chorus here');

    performance = SongPerformance(a.songId.toString(), singer);
    allSongPerformances.addSongPerformance(performance);
    allSongPerformances.loadSongs([
      a,
      Song(
          title: 'All I Have to Do Is Dream',
          artist: 'Everly Brothers',
          copyright: 'bsteele.com',
          key: Key.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'pearlbob',
          chords: 'i: A B C D V: D E F F# [ D C B A ]x2 c: D C G G',
          rawLyrics: 'i:\nv: bob, bob, bob berand\nc: sing chorus here'),
      Song(
          title: 'All You Need is Love',
          artist: 'The Beatles',
          copyright: 'bsteele.com',
          key: Key.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'pearlbob',
          chords: 'i: A B C D V: D E F F# [ D C B A ]x2 c: D C G G',
          rawLyrics: 'i:\nv: bob, bob, bob berand\nc: sing chorus here'),
      Song(
          title: 'back in the USSR',
          artist: 'The Beatles',
          copyright: 'bsteele.com',
          key: Key.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'pearlbob',
          chords: 'i: A B C D V: D E F F# [ D C B A ]x2 c: D C G G',
          rawLyrics: 'i:\nv: bob, bob, bob berand\nc: sing chorus here'),
      Song(
          title: 'don\'t let me down',
          artist: 'The Beatles',
          copyright: 'bsteele.com',
          key: Key.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'pearlbob',
          chords: 'i: A B C D V: D E F F# [ D C B A ]x2 c: D C G G',
          rawLyrics: 'i:\nv: bob, bob, bob berand\nc: sing chorus here'),
      Song(
          title: 'Angie',
          artist: 'The Stones',
          copyright: 'bsteele.com',
          key: Key.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'pearlbob',
          chords: 'i: A B C D V: D E F F# [ D C B A ]x2 c: D C G G',
          rawLyrics: 'i:\nv: bob, bob, bob berand\nc: sing chorus here'),
    ]);

    for (var p in allSongPerformances.allSongPerformances) {
      logger.i('${p.singer} sings ${p.songId}');
    }
    expect(allSongPerformances.length, 6);

    expect(allSongPerformances.bySinger(singer).length, 2);
    expect(allSongPerformances.find(singer: singer, song: a), performance);
    expect(allSongPerformances.find(singer: 'bub', song: a), isNull);
  });

  test('song performance updates', () async {
    var allSongPerformances = AllSongPerformances.test();

    var singer = 'Jill';
    allSongPerformances.addFromJsonString(
        '''[{"songId":"Song_All_I_Have_to_Do_Is_Dream_by_Everly_Brothers","singer":"$singer","key":3,"bpm":106,"lastSung":1439854884818},
{"songId":"Song_All_You_Need_is_Love_by_Beatles_The","singer":"$singer","key":6,"bpm":106,"lastSung":0},
{"songId":"Song_Angie_by_Rolling_Stones_The","singer":"$singer","key":6,"bpm":106,"lastSung":0},
{"songId":"Song_Back_in_the_USSR_by_Beatles_The","singer":"Bob","key":7,"bpm":106,"lastSung":0},
{"songId":"Song_Dont_Let_Me_Down_by_Beatles_The","singer":"$singer","key":0,"bpm":106,"lastSung":0}]
    ''');
    expect(allSongPerformances.allSongPerformances.length, 5);
    expect(allSongPerformances.allSongPerformanceHistory.length, 5);

    {
      //  update to a newer performance
      var performance = SongPerformance.fromJsonString('{"songId":"Song_All_I_Have_to_Do_Is_Dream_by_Everly_Brothers"'
          ',"singer":"$singer","key":3,"bpm":120,"lastSung":1639854884818}');
      expect(allSongPerformances.updateSongPerformance(performance), true);
      expect(allSongPerformances.updateSongPerformance(performance), false);
      expect(allSongPerformances.allSongPerformances.length, 5);
      expect(allSongPerformances.allSongPerformanceHistory.length, 6);
      for (var p in allSongPerformances.bySinger(singer)) {
        if (p.songId == 'Song_All_I_Have_to_Do_Is_Dream_by_Everly_Brothers') {
          expect(p.lastSung, 1639854884818);
          expect(p.bpm, 120);
        }
      }
      expect(allSongPerformances.updateSongPerformance(performance), false);

      //  don't update to an older performance
      performance = SongPerformance.fromJsonString('{"songId":"Song_All_I_Have_to_Do_Is_Dream_by_Everly_Brothers"'
          ',"singer":"$singer","key":3,"bpm":110,"lastSung":1539854884818}'); //  older performance
      expect(allSongPerformances.updateSongPerformance(performance), false);
      for (var p in allSongPerformances.bySinger(singer)) {
        if (p.songId == 'Song_All_I_Have_to_Do_Is_Dream_by_Everly_Brothers') {
          //  not updated since update was older
          expect(p.lastSung, 1639854884818);
          expect(p.bpm, 120);
        }
      }
      expect(allSongPerformances.allSongPerformances.length, 5);
      expect(allSongPerformances.allSongPerformanceHistory.length, 7);
      {
        int singerCount = 0;
        for (var perf in allSongPerformances.allSongPerformanceHistory) {
          if (perf.singer == singer) singerCount++;
          logger.i(perf.toString());
        }
        expect(singerCount, 4 + 2 /*repeats*/);
        logger.i(allSongPerformances.toJsonString());
        expect(
            allSongPerformances.toJsonString(prettyPrint: true),
            '{\n'
            ' "allSongPerformances": [\n'
            '  {\n'
            '   "songId": "Song_All_I_Have_to_Do_Is_Dream_by_Everly_Brothers",\n'
            '   "singer": "Jill",\n'
            '   "bpm": 120,\n'
            '   "firstSung": 1439854884818,\n'
            '   "lastSung": 1639854884818,\n'
            '   "key": "C"\n'
            '  },\n'
            '  {\n'
            '   "songId": "Song_All_You_Need_is_Love_by_Beatles_The",\n'
            '   "singer": "Jill",\n'
            '   "bpm": 106,\n'
            '   "firstSung": 0,\n'
            '   "lastSung": 0,\n'
            '   "key": "Eb"\n'
            '  },\n'
            '  {\n'
            '   "songId": "Song_Angie_by_Rolling_Stones_The",\n'
            '   "singer": "Jill",\n'
            '   "bpm": 106,\n'
            '   "firstSung": 0,\n'
            '   "lastSung": 0,\n'
            '   "key": "Eb"\n'
            '  },\n'
            '  {\n'
            '   "songId": "Song_Back_in_the_USSR_by_Beatles_The",\n'
            '   "singer": "Bob",\n'
            '   "bpm": 106,\n'
            '   "firstSung": 0,\n'
            '   "lastSung": 0,\n'
            '   "key": "E"\n'
            '  },\n'
            '  {\n'
            '   "songId": "Song_Dont_Let_Me_Down_by_Beatles_The",\n'
            '   "singer": "Jill",\n'
            '   "bpm": 106,\n'
            '   "firstSung": 0,\n'
            '   "lastSung": 0,\n'
            '   "key": "A"\n'
            '  }\n'
            ' ],\n'
            ' "allSongPerformanceHistory": [\n'
            '  {\n'
            '   "songId": "Song_All_You_Need_is_Love_by_Beatles_The",\n'
            '   "singer": "Jill",\n'
            '   "bpm": 106,\n'
            '   "firstSung": 0,\n'
            '   "lastSung": 0,\n'
            '   "key": "Eb"\n'
            '  },\n'
            '  {\n'
            '   "songId": "Song_Angie_by_Rolling_Stones_The",\n'
            '   "singer": "Jill",\n'
            '   "bpm": 106,\n'
            '   "firstSung": 0,\n'
            '   "lastSung": 0,\n'
            '   "key": "Eb"\n'
            '  },\n'
            '  {\n'
            '   "songId": "Song_Back_in_the_USSR_by_Beatles_The",\n'
            '   "singer": "Bob",\n'
            '   "bpm": 106,\n'
            '   "firstSung": 0,\n'
            '   "lastSung": 0,\n'
            '   "key": "E"\n'
            '  },\n'
            '  {\n'
            '   "songId": "Song_Dont_Let_Me_Down_by_Beatles_The",\n'
            '   "singer": "Jill",\n'
            '   "bpm": 106,\n'
            '   "firstSung": 0,\n'
            '   "lastSung": 0,\n'
            '   "key": "A"\n'
            '  },\n'
            '  {\n'
            '   "songId": "Song_All_I_Have_to_Do_Is_Dream_by_Everly_Brothers",\n'
            '   "singer": "Jill",\n'
            '   "bpm": 106,\n'
            '   "firstSung": 1439854884818,\n'
            '   "lastSung": 1439854884818,\n'
            '   "key": "C"\n'
            '  },\n'
            '  {\n'
            '   "songId": "Song_All_I_Have_to_Do_Is_Dream_by_Everly_Brothers",\n'
            '   "singer": "Jill",\n'
            '   "bpm": 110,\n'
            '   "firstSung": 1539854884818,\n'
            '   "lastSung": 1539854884818,\n'
            '   "key": "C"\n'
            '  },\n'
            '  {\n'
            '   "songId": "Song_All_I_Have_to_Do_Is_Dream_by_Everly_Brothers",\n'
            '   "singer": "Jill",\n'
            '   "bpm": 120,\n'
            '   "firstSung": 1639854884818,\n'
            '   "lastSung": 1639854884818,\n'
            '   "key": "C"\n'
            '  }\n'
            ' ],\n'
            ' "allSongPerformanceRequests": []\n'
            '}\n');
      }
    }

    {
      var a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'bsteele.com',
          key: Key.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'pearlbob',
          chords: 'i: A B C D V: D E F F# [ D C B A ]x2 c: D C G G',
          rawLyrics: 'i:\nv: bob, bob, bob berand\nc: sing chorus here');

      var singer1 = 'bodhi';
      var performance = SongPerformance.fromSong(a, singer1, key: Key.A);
      expect(allSongPerformances.updateSongPerformance(performance), true);
      expect(allSongPerformances.updateSongPerformance(performance), false);
      await Future.delayed(const Duration(milliseconds: 2));
      expect(allSongPerformances.updateSongPerformance(performance), false);
      performance = SongPerformance.fromSong(a, singer1, key: Key.A);
      expect(allSongPerformances.updateSongPerformance(performance), true);
      expect(allSongPerformances.updateSongPerformance(performance), false);
      await Future.delayed(const Duration(milliseconds: 2));
      expect(allSongPerformances.updateSongPerformance(performance), false);
      performance = SongPerformance.fromSong(a, singer1, key: Key.B);
      expect(allSongPerformances.updateSongPerformance(performance), true);
      expect(allSongPerformances.updateSongPerformance(performance), false);
      await Future.delayed(const Duration(milliseconds: 2));
      performance = SongPerformance.fromSong(a, singer1, key: Key.B);
      expect(allSongPerformances.updateSongPerformance(performance), true);
      expect(allSongPerformances.updateSongPerformance(performance), false);
      expect(allSongPerformances.updateSongPerformance(performance), false);
      await Future.delayed(const Duration(milliseconds: 2));
      expect(allSongPerformances.updateSongPerformance(performance), false);
      expect(allSongPerformances.updateSongPerformance(performance), false);
    }
  });

  test('song performances name trimming', () async {
    var allSongPerformances = AllSongPerformances.test();
    expect(allSongPerformances.length, 0);
    allSongPerformances.addFromJsonString(
        '''[{"songId":"Song_All_I_Have_to_Do_Is_Dream_by_Everly_Brothers","singer":"Jill Z. ","key":3,"bpm":106,"lastSung":1639854884818},
{"songId":"Song_All_You_Need_is_Love_by_Beatles_The","singer":" Jill Z.","key":6,"bpm":106,"lastSung":0},
{"songId":"Song_Angie_by_Rolling_Stones_The","singer":"Jill  Z.","key":6,"bpm":106,"lastSung":0},
{"songId":"Song_Back_in_the_USSR_by_Beatles_The","singer":"Bob","key":7,"bpm":106,"lastSung":0},
{"songId":"Song_Dont_Let_Me_Down_by_Beatles_The","singer":" Jill      Z.  ","key":0,"bpm":106,"lastSung":0}]
    ''');
    //  notice that the last one has a tab in the middle of Jill's name
    expect(allSongPerformances.length, 5);
    expect(allSongPerformances.bySinger('Jill Z.').length, 4);
  });

  test('song performances json extraneous fields', () async {
    var allSongPerformances = AllSongPerformances.test();
    expect(allSongPerformances.length, 0);
    allSongPerformances.updateFromJsonString('''{
        "participants":["Foo U."],
        "requests":[
        {"songId":"Song_All_Along_the_Watchtower_cover_by_Jimi_Hendrix_by_Bob_Dylan","requester":"Bob S.","lastSung":1643253035702}],
        "allSongPerformances":[{"songId":"Song_All_I_Have_to_Do_Is_Dream_by_Everly_Brothers","singer":"Jill Z. ","key":3,"bpm":106,"lastSung":1639854884818},
{"songId":"Song_All_You_Need_is_Love_by_Beatles_The","singer":" Jill Z.","key":6,"bpm":106,"lastSung":0},
{"songId":"Song_Angie_by_Rolling_Stones_The","singer":"Jill  Z.","key":6,"bpm":106,"lastSung":0},
{"songId":"Song_Back_in_the_USSR_by_Beatles_The","singer":"Bob","key":7,"bpm":106,"lastSung":0},
{"songId":"Song_Dont_Let_Me_Down_by_Beatles_The","singer":" Jill      Z.  ","key":0,"bpm":106,"lastSung":0}]
}
    ''');
    //  notice that the last one has a tab in the middle of Jill's name
    expect(allSongPerformances.length, 5);
    expect(allSongPerformances.bySinger('Jill Z.').length, 4);
    logger.i(allSongPerformances.toJsonString());
    expect(
        allSongPerformances.toJsonString(prettyPrint: true),
        '{\n'
        ' "allSongPerformances": [\n'
        '  {\n'
        '   "songId": "Song_All_I_Have_to_Do_Is_Dream_by_Everly_Brothers",\n'
        '   "singer": "Jill Z.",\n'
        '   "bpm": 106,\n'
        '   "firstSung": 1639854884818,\n'
        '   "lastSung": 1639854884818,\n'
        '   "key": "C"\n'
        '  },\n'
        '  {\n'
        '   "songId": "Song_All_You_Need_is_Love_by_Beatles_The",\n'
        '   "singer": "Jill Z.",\n'
        '   "bpm": 106,\n'
        '   "firstSung": 0,\n'
        '   "lastSung": 0,\n'
        '   "key": "Eb"\n'
        '  },\n'
        '  {\n'
        '   "songId": "Song_Angie_by_Rolling_Stones_The",\n'
        '   "singer": "Jill Z.",\n'
        '   "bpm": 106,\n'
        '   "firstSung": 0,\n'
        '   "lastSung": 0,\n'
        '   "key": "Eb"\n'
        '  },\n'
        '  {\n'
        '   "songId": "Song_Back_in_the_USSR_by_Beatles_The",\n'
        '   "singer": "Bob",\n'
        '   "bpm": 106,\n'
        '   "firstSung": 0,\n'
        '   "lastSung": 0,\n'
        '   "key": "E"\n'
        '  },\n'
        '  {\n'
        '   "songId": "Song_Dont_Let_Me_Down_by_Beatles_The",\n'
        '   "singer": "Jill Z.",\n'
        '   "bpm": 106,\n'
        '   "firstSung": 0,\n'
        '   "lastSung": 0,\n'
        '   "key": "A"\n'
        '  }\n'
        ' ],\n'
        ' "allSongPerformanceHistory": [\n'
        '  {\n'
        '   "songId": "Song_All_You_Need_is_Love_by_Beatles_The",\n'
        '   "singer": "Jill Z.",\n'
        '   "bpm": 106,\n'
        '   "firstSung": 0,\n'
        '   "lastSung": 0,\n'
        '   "key": "Eb"\n'
        '  },\n'
        '  {\n'
        '   "songId": "Song_Angie_by_Rolling_Stones_The",\n'
        '   "singer": "Jill Z.",\n'
        '   "bpm": 106,\n'
        '   "firstSung": 0,\n'
        '   "lastSung": 0,\n'
        '   "key": "Eb"\n'
        '  },\n'
        '  {\n'
        '   "songId": "Song_Back_in_the_USSR_by_Beatles_The",\n'
        '   "singer": "Bob",\n'
        '   "bpm": 106,\n'
        '   "firstSung": 0,\n'
        '   "lastSung": 0,\n'
        '   "key": "E"\n'
        '  },\n'
        '  {\n'
        '   "songId": "Song_Dont_Let_Me_Down_by_Beatles_The",\n'
        '   "singer": "Jill Z.",\n'
        '   "bpm": 106,\n'
        '   "firstSung": 0,\n'
        '   "lastSung": 0,\n'
        '   "key": "A"\n'
        '  },\n'
        '  {\n'
        '   "songId": "Song_All_I_Have_to_Do_Is_Dream_by_Everly_Brothers",\n'
        '   "singer": "Jill Z.",\n'
        '   "bpm": 106,\n'
        '   "firstSung": 1639854884818,\n'
        '   "lastSung": 1639854884818,\n'
        '   "key": "C"\n'
        '  }\n'
        ' ],\n'
        ' "allSongPerformanceRequests": []\n'
        '}\n');
  });

  test('song performance requests', () async {
    var allSongPerformances = AllSongPerformances.test();
    expect(allSongPerformances.length, 0);
    allSongPerformances.updateFromJsonString('''{
        "participants":["Foo U."],
        "allSongPerformanceRequests":[
        {"songId":"Song_All_Along_the_Watchtower_cover_by_Jimi_Hendrix_by_Bob_Dylan","requester":"Bob S."}],
        "allSongPerformances":[{"songId":"Song_All_I_Have_to_Do_Is_Dream_by_Everly_Brothers","singer":"Jill Z. ","key":3,"bpm":106,"lastSung":1639854884818},
{"songId":"Song_All_You_Need_is_Love_by_Beatles_The","singer":" Jill Z.","key":6,"bpm":106,"lastSung":0},
{"songId":"Song_Angie_by_Rolling_Stones_The","singer":"Jill  Z.","key":6,"bpm":106,"lastSung":0},
{"songId":"Song_Back_in_the_USSR_by_Beatles_The","singer":"Bob","key":7,"bpm":106,"lastSung":0},
{"songId":"Song_Dont_Let_Me_Down_by_Beatles_The","singer":" Jill      Z.  ","key":0,"bpm":106,"lastSung":0}]
}
    ''');
    //  notice that the last one has a tab in the middle of Jill's name
    expect(allSongPerformances.length, 5);
    expect(allSongPerformances.allSongPerformanceRequests.length, 1);

    logger.d(allSongPerformances.toJsonString(prettyPrint: true));
    expect(allSongPerformances.bySinger('Jill Z.').length, 4);
    expect(
        allSongPerformances.toJsonString(prettyPrint: true),
        '{\n'
        ' "allSongPerformances": [\n'
        '  {\n'
        '   "songId": "Song_All_I_Have_to_Do_Is_Dream_by_Everly_Brothers",\n'
        '   "singer": "Jill Z.",\n'
        '   "bpm": 106,\n'
        '   "firstSung": 1639854884818,\n'
        '   "lastSung": 1639854884818,\n'
        '   "key": "C"\n'
        '  },\n'
        '  {\n'
        '   "songId": "Song_All_You_Need_is_Love_by_Beatles_The",\n'
        '   "singer": "Jill Z.",\n'
        '   "bpm": 106,\n'
        '   "firstSung": 0,\n'
        '   "lastSung": 0,\n'
        '   "key": "Eb"\n'
        '  },\n'
        '  {\n'
        '   "songId": "Song_Angie_by_Rolling_Stones_The",\n'
        '   "singer": "Jill Z.",\n'
        '   "bpm": 106,\n'
        '   "firstSung": 0,\n'
        '   "lastSung": 0,\n'
        '   "key": "Eb"\n'
        '  },\n'
        '  {\n'
        '   "songId": "Song_Back_in_the_USSR_by_Beatles_The",\n'
        '   "singer": "Bob",\n'
        '   "bpm": 106,\n'
        '   "firstSung": 0,\n'
        '   "lastSung": 0,\n'
        '   "key": "E"\n'
        '  },\n'
        '  {\n'
        '   "songId": "Song_Dont_Let_Me_Down_by_Beatles_The",\n'
        '   "singer": "Jill Z.",\n'
        '   "bpm": 106,\n'
        '   "firstSung": 0,\n'
        '   "lastSung": 0,\n'
        '   "key": "A"\n'
        '  }\n'
        ' ],\n'
        ' "allSongPerformanceHistory": [\n'
        '  {\n'
        '   "songId": "Song_All_You_Need_is_Love_by_Beatles_The",\n'
        '   "singer": "Jill Z.",\n'
        '   "bpm": 106,\n'
        '   "firstSung": 0,\n'
        '   "lastSung": 0,\n'
        '   "key": "Eb"\n'
        '  },\n'
        '  {\n'
        '   "songId": "Song_Angie_by_Rolling_Stones_The",\n'
        '   "singer": "Jill Z.",\n'
        '   "bpm": 106,\n'
        '   "firstSung": 0,\n'
        '   "lastSung": 0,\n'
        '   "key": "Eb"\n'
        '  },\n'
        '  {\n'
        '   "songId": "Song_Back_in_the_USSR_by_Beatles_The",\n'
        '   "singer": "Bob",\n'
        '   "bpm": 106,\n'
        '   "firstSung": 0,\n'
        '   "lastSung": 0,\n'
        '   "key": "E"\n'
        '  },\n'
        '  {\n'
        '   "songId": "Song_Dont_Let_Me_Down_by_Beatles_The",\n'
        '   "singer": "Jill Z.",\n'
        '   "bpm": 106,\n'
        '   "firstSung": 0,\n'
        '   "lastSung": 0,\n'
        '   "key": "A"\n'
        '  },\n'
        '  {\n'
        '   "songId": "Song_All_I_Have_to_Do_Is_Dream_by_Everly_Brothers",\n'
        '   "singer": "Jill Z.",\n'
        '   "bpm": 106,\n'
        '   "firstSung": 1639854884818,\n'
        '   "lastSung": 1639854884818,\n'
        '   "key": "C"\n'
        '  }\n'
        ' ],\n'
        ' "allSongPerformanceRequests": [\n'
        '  {\n'
        '   "songId": "Song_All_Along_the_Watchtower_cover_by_Jimi_Hendrix_by_Bob_Dylan",\n'
        '   "requester": "Bob S."\n'
        '  }\n'
        ' ]\n'
        '}\n');
  });

  test('song performance keys after a key base change', () {
    int beatsPerBar = 4;
    int bpm = 106;
    var singer = 'Bob S.';
    var lastSung = DateTime.now().millisecondsSinceEpoch;

    for (var keySung in Key.values) {
      logger.i('keySung: ${keySung.toString()}');

      for (var key in Key.values) {
        var allSongPerformances = AllSongPerformances.test();
        var a = Song(
            title: 'ive go the blanks',
            artist: 'bob',
            copyright: '2022 bsteele.com',
            key: key,
            beatsPerMinute: bpm,
            beatsPerBar: beatsPerBar,
            unitsPerMeasure: 4,
            user: 'pearl bob',
            chords: 'i: A B C D  v: G G G G, C C G G o: C C G G',
            rawLyrics: 'i: (instrumental)\nv: line 1\no:\n');

        var songIdAsString = a.songId.toString();
        allSongPerformances
            .addSongPerformance(SongPerformance(songIdAsString, singer, key: keySung, bpm: bpm, lastSung: lastSung));
        allSongPerformances.loadSongs([a]);
        expect(allSongPerformances.length, 1);

        //  encode/decode to/from json
        logger.t(allSongPerformances.toJsonString(prettyPrint: true));
        allSongPerformances.fromJsonString(allSongPerformances.toJsonString());
        allSongPerformances.loadSongs([a]);

        var performance = allSongPerformances.findBySingerSongId(songIdAsString: songIdAsString, singer: singer);
        expect(performance, isNotNull);
        logger.i('  song key: ${a.key.toString()}, sung in: ${performance!.key.toString()}');
        expect(performance.key, keySung);
      }
    }
  });

  test('song performance matches', () async {
    int beatsPerBar = 4;
    int bpm = 106;
    var singer = 'Bob S.';
    var lastSung = DateTime.now().millisecondsSinceEpoch;

    var allSongPerformances = AllSongPerformances.test();
    var a = Song(
        title: 'ive go the blanks',
        artist: 'bob',
        copyright: '2022 bsteele.com',
        key: Key.C,
        beatsPerMinute: bpm,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        user: 'pearl bob',
        chords: 'i: A B C D  v: G G G G, C C G G o: C C G G',
        rawLyrics: 'i: (instrumental)\nv: line 1\no:\n');

    var performance1 = SongPerformance(a.songId.toString(), singer, key: Key.D, bpm: bpm, lastSung: lastSung);
    allSongPerformances.addSongPerformance(performance1);
    allSongPerformances.loadSongs([a]);
    var performanceA = allSongPerformances.findBySingerSongId(songIdAsString: a.songId.toString(), singer: singer);
    expect(performanceA, isNotNull);
    expect(performanceA!.song, isNotNull);

    var b = Song(
        title: 'Ive Got The Blanks',
        artist: 'bob',
        copyright: '2022 bsteele.com',
        key: Key.C,
        beatsPerMinute: bpm,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        user: 'pearl bob',
        chords: 'i: A B C D  v: G G G G, C C G G o: C C G G',
        rawLyrics: 'i: (instrumental)\nv: line 1\no:\n');

    var performance2 = SongPerformance(b.songId.toString(), singer,
        key: Key.D, bpm: bpm, lastSung: lastSung + Duration.millisecondsPerDay);
    performance2 = allSongPerformances.addSongPerformance(performance2);
    expect(allSongPerformances.allSongPerformances.length, 2);
    expect(allSongPerformances.allSongPerformanceHistory.length, 2);
    for (var h in allSongPerformances.allSongPerformanceHistory) {
      logger.i('$h');
    }
    logger.i('performanceA ${performanceA.songId} vs performance2 ${performance2.songId}');
    logger.i('performanceA.lastSung ${performanceA.lastSung} vs ${performance2.lastSung}');
    logger.i('performanceA.compareTo(performance2): ${performance1.compareTo(performance2)}');
    expect(performanceA.song?.compareTo(performance2.song!), isZero);

    logger.i('allSongPerformances:');
    for (var performance in allSongPerformances.allSongPerformances) {
      logger.i('  $performance');
    }
    expect(allSongPerformances.allSongPerformances.length, 2);
    expect(allSongPerformances.allSongPerformanceHistory.length, 2);
    allSongPerformances.removeSingerSong(singer, a.songId.toString());
    expect(allSongPerformances.allSongPerformances.length, 1);
    allSongPerformances.removeSingerSong(singer, b.songId.toString());
    expect(allSongPerformances.allSongPerformances.length, 0);
    expect(allSongPerformances.allSongPerformanceHistory.length, 2);
  });

  test('song performance performedSong', () async {
    int beatsPerBar = 4;
    int bpm = 106;
    var singer = 'Bob S.';
    var lastSung = DateTime.now().millisecondsSinceEpoch;

    Logger.level = Level.info;

    var a = Song(
        title: 'ive got the blanks',
        artist: 'bob',
        copyright: '2022 bsteele.com',
        key: Key.C,
        beatsPerMinute: bpm,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        user: 'pearl bob',
        chords: 'i: A B C D  v: G G G G, C C G G o: C C G G',
        rawLyrics: 'i: (instrumental)\nv: line 1\no:\n');

    var performance1 = SongPerformance(a.songId.toString(), singer, key: Key.D, bpm: bpm, lastSung: lastSung);
    logger.i('performedSong: "${performance1.performedSong.title}"');
    expect(performance1.performedSong.title, 'Ive Got The Blanks by Bob');

    var b = Song(
        title: 'Ive Got The Blanks',
        artist: 'bob',
        copyright: '2022 bsteele.com',
        key: Key.C,
        beatsPerMinute: bpm,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        user: 'pearl bob',
        chords: 'i: A B C D  v: G G G G, C C G G o: C C G G',
        rawLyrics: 'i: (instrumental)\nv: line 1\no:\n');

    var performance2 = SongPerformance(b.songId.toString(), singer, key: Key.D, bpm: bpm, lastSung: lastSung + 30000);
    logger.i('performedSong: "${performance2.performedSong.title}"');
    expect(performance1.performedSong.title, 'Ive Got The Blanks by Bob');
  });

  test('song first sung', () async {
    int beatsPerBar = 4;
    int bpm = 106;
    var singer = 'Bob S.';
    var firstSung = DateTime(2024, 1, 1).millisecondsSinceEpoch;
    var lastSung = DateTime(2024, 3, 1).millisecondsSinceEpoch;

    Logger.level = Level.info;

    var a = Song(
        title: 'ive got the blanks',
        artist: 'bob',
        copyright: '2022 bsteele.com',
        key: Key.C,
        beatsPerMinute: bpm,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        user: 'pearl bob',
        chords: 'i: A B C D  v: G G G G, C C G G o: C C G G',
        rawLyrics: 'i: (instrumental)\nv: line 1\no:\n');

    var allSongPerformances = AllSongPerformances.test();

    var performance1 = SongPerformance(a.songId.toString(), singer, key: Key.D, bpm: bpm, lastSung: lastSung);
    logger.i('performedSong1: $performance1');
    expect(performance1.firstSung, lastSung);
    expect(performance1.lastSung, lastSung);

    performance1 = allSongPerformances.addSongPerformance(performance1);

    var performance2 = performance1.copyWith(firstSung: firstSung, lastSung: firstSung);
    logger.i('performedSong2: $performance2');
    expect(performance2.firstSung, firstSung);
    expect(performance2.lastSung, firstSung);

    allSongPerformances.updateSongPerformance(performance2);
    for (var p in allSongPerformances.allSongPerformances) {
      logger.i('$p');
    }

    var found = allSongPerformances.find(singer: singer, song: a);
    expect(found?.firstSung, firstSung);
    expect(found?.lastSung, lastSung);
  });
}
