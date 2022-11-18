import 'dart:collection';

import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/key.dart';
import 'package:bsteeleMusicLib/songs/song.dart';
import 'package:bsteeleMusicLib/songs/songId.dart';
import 'package:bsteeleMusicLib/songs/songMetadata.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

var cjBest = const NameValue('cj', 'best');

void main() {
  Logger.level = Level.info;

  test('test basic Metadata', () {
    SongMetadata.clear();

    const String id0 = 'id0';
    {
      expect(SongIdMetadata(id0, metadata: [const NameValue('genre', 'rock')]).toJson(),
          '{"id":"id0","metadata":[{"name":"genre","value":"rock"}]}');
      expect(
          SongIdMetadata(id0, metadata: [const NameValue('genre', 'rock'), const NameValue('genre', 'rock')]).toJson(),
          '{"id":"id0","metadata":[{"name":"genre","value":"rock"}]}');

      SongIdMetadata md =
          SongIdMetadata(id0, metadata: [const NameValue('genre', 'rock'), const NameValue('jam', 'casual')]);
      expect(md.toJson(), '{"id":"id0","metadata":[{"name":"genre","value":"rock"},{"name":"jam","value":"casual"}]}');
      md.remove(const NameValue('jam', 'casual'));
      expect(md.toJson(), '{"id":"id0","metadata":[{"name":"genre","value":"rock"}]}');
      md.add(const NameValue('jam', 'casual'));
      expect(md.toJson(), '{"id":"id0","metadata":[{"name":"genre","value":"rock"},{"name":"jam","value":"casual"}]}');
    }

    //  metadata
    SongIdMetadata md0 =
        SongIdMetadata(id0, metadata: [const NameValue('genre', 'rock'), const NameValue('jam', 'casual')]);
    SongIdMetadata md1 =
        SongIdMetadata('id1', metadata: [const NameValue('genre', 'rock'), const NameValue('jam', 'advanced')]);
    SongIdMetadata md2 = SongIdMetadata('id2', metadata: [const NameValue('jam', 'advanced')]);
    SongIdMetadata md3 = SongIdMetadata('id3 christmas');

    SplayTreeSet<SongIdMetadata> set = SplayTreeSet();

    set = SongMetadata.where(idIsLike: id0);
    expect(set.isEmpty, true);

    logger.i('SongMetadata.staticHashCode: ${SongMetadata.staticHashCode}');
    SongMetadata.set(md0);
    logger.i('SongMetadata.staticHashCode: ${SongMetadata.staticHashCode}');
    SongMetadata.set(md1);
    logger.i('SongMetadata.staticHashCode: ${SongMetadata.staticHashCode}');
    SongMetadata.set(md2);
    logger.i('SongMetadata.staticHashCode: ${SongMetadata.staticHashCode}');
    SongMetadata.set(md3);
    logger.i('SongMetadata.staticHashCode: ${SongMetadata.staticHashCode}');
    for (var md in [md0, md1, md2, md3]) {
      logger.i('md: $md');
      set = SongMetadata.where(idIsLike: md.id);
      logger.i('set: $set');
      expect(set.isEmpty, false);
      expect(set.length, 1);
      expect(set.contains(md), true);
    }

    set = SongMetadata.where(idIsLike: 'foo');
    expect(set.isEmpty, true);

    set = SongMetadata.where(nameIsLike: 'genre');
    expect(set.isEmpty, false);
    expect(set.length, 2);
    expect(set.contains(md0), true);
    expect(set.contains(md1), true);
    expect(set.contains(md2), false);

    set = SongMetadata.where(nameIsLike: 'jam', valueIsLike: 'ad');
    expect(set.isEmpty, false);
    expect(set.length, 2);
    expect(set.contains(md0), false);
    expect(set.contains(md1), true);
    expect(set.contains(md2), true);
    expect(set.contains(md3), false);
    logger.i(set.toString());
    var idn = SongMetadata.where(idIs: 'id1').first;
    logger.i('idn: $idn');
    expect(idn.toString(), '''{ "id": "id1", "metadata": [
	{"genre":"rock"},
	{"jam":"advanced"}
	] }''');

    //  get them all
    set = SongMetadata.where();
    expect(set.isEmpty, false);
    expect(set.length, 4);

    //  not christmas
    set = SongMetadata.where();
    set.removeAll(SongMetadata.where(idIsLike: 'christmas'));
    expect(set.isEmpty, false);
    expect(set.length, 3);
    expect(set.contains(md0), true);
    expect(set.contains(md1), true);
    expect(set.contains(md2), true);
    expect(set.contains(md3), false);

    //  verify there are no christmas genre songs
    set = SongMetadata.where(nameIsLike: 'genre', valueIsLike: 'christmas');
    expect(set.isEmpty, true);

    //  set songs with christmas in the title or artist to be the christmas genre
    String christmasGenreValue = 'Christmas';
    set = SongMetadata.where(idIsLike: christmasGenreValue);
    for (SongIdMetadata idm in set) {
      idm.add(NameValue('genre', christmasGenreValue));
    }

    //  verify there are christmas genre songs
    set = SongMetadata.where(nameIsLike: 'genre', valueIsLike: christmasGenreValue);
    expect(set.isEmpty, false);
    expect(set.length, 1);
    expect(set.contains(md0), false);
    expect(set.contains(md1), false);
    expect(set.contains(md2), false);
    expect(set.contains(md3), true);

    if (Logger.level.index <= Level.debug.index) {
      SplayTreeSet<String> names = SongMetadata.namesOf(set);
      for (String name in names) {
        logger.d('name: $name');
        SplayTreeSet<String> values = SongMetadata.valuesOf(set, name);
        for (String value in values) {
          logger.d('\tvalue: $value');
        }
      }

      //  list all
      logger.d('');
      for (SongIdMetadata idMetadata in SongMetadata.idMetadata) {
        logger.d(idMetadata.toString());
      }
    }
  });

  test('test Metadata exact matches', () {
    SongMetadata.clear();

    const String id0 = 'id0';
    {
      expect(SongIdMetadata(id0, metadata: [const NameValue('genre', 'rock')]).toJson(),
          '{"id":"id0","metadata":[{"name":"genre","value":"rock"}]}');
      expect(
          SongIdMetadata(id0, metadata: [const NameValue('genre', 'rock'), const NameValue('genre', 'rock')]).toJson(),
          '{"id":"id0","metadata":[{"name":"genre","value":"rock"}]}');

      SongIdMetadata md =
          SongIdMetadata(id0, metadata: [const NameValue('genre', 'rock'), const NameValue('jam', 'casual')]);
      expect(md.toJson(), '{"id":"id0","metadata":[{"name":"genre","value":"rock"},{"name":"jam","value":"casual"}]}');
      md.remove(const NameValue('jam', 'casual'));
      expect(md.toJson(), '{"id":"id0","metadata":[{"name":"genre","value":"rock"}]}');
      md.add(const NameValue('jam', 'casual'));
      expect(md.toJson(), '{"id":"id0","metadata":[{"name":"genre","value":"rock"},{"name":"jam","value":"casual"}]}');
    }

    //  metadata
    SongIdMetadata md0 =
        SongIdMetadata(id0, metadata: [const NameValue('genre', 'rock'), const NameValue('jam', 'casual')]);
    SongIdMetadata md1 =
        SongIdMetadata('id1', metadata: [const NameValue('genre', 'rock'), const NameValue('jam', 'advanced')]);
    SongIdMetadata md2 = SongIdMetadata('id2', metadata: [const NameValue('jam', 'advanced')]);
    SongIdMetadata md3 = SongIdMetadata('id3 christmas');

    SplayTreeSet<SongIdMetadata> set = SplayTreeSet();
    expect(set.isEmpty, true);

    set = SongMetadata.where(idIs: id0);
    logger.i('set: $set');
    expect(set.isEmpty, true);

    SongMetadata.set(md0);
    SongMetadata.set(md1);
    SongMetadata.set(md2);
    SongMetadata.set(md3);
    for (var md in [md0, md1, md2, md3]) {
      logger.i('md: $md');
      set = SongMetadata.where(idIs: md.id);
      logger.i('set: $set');
      expect(set.isEmpty, false);
      expect(set.length, 1);
      expect(set.contains(md), true);
    }

    set = SongMetadata.where(idIs: 'foo');
    expect(set.isEmpty, true);

    set = SongMetadata.where(nameIs: 'genre');
    expect(set.isEmpty, false);
    expect(set.length, 2);
    expect(set.contains(md0), true);
    expect(set.contains(md1), true);
    expect(set.contains(md2), false);

    set = SongMetadata.where(nameIs: 'jam', valueIs: 'advanced');
    logger.i('set: $set');
    expect(set.isEmpty, false);
    expect(set.length, 2);
    expect(set.contains(md0), false);
    expect(set.contains(md1), true);
    expect(set.contains(md2), true);
    expect(set.contains(md3), false);

    //  get them all
    set = SongMetadata.where();
    expect(set.isEmpty, false);
    expect(set.length, 4);

    //  not christmas
    set = SongMetadata.where();
    set.removeAll(SongMetadata.where(idIs: 'christmas'));
    expect(set.isEmpty, false);
    logger.i('set: $set');
    expect(set.length, 4); //  'id3 christmas' != 'christmas'
    expect(set.contains(md0), true);
    expect(set.contains(md1), true);
    expect(set.contains(md2), true);
    expect(set.contains(md3), true);

    //  verify there are no christmas genre songs
    set = SongMetadata.where(nameIs: 'genre', valueIs: 'christmas');
    expect(set.isEmpty, true);

    //  set songs with christmas in the title or artist to be the christmas genre
    String christmasGenreValue = 'Christmas';
    set = SongMetadata.where(idIs: christmasGenreValue);
    for (SongIdMetadata idm in set) {
      idm.add(NameValue('genre', christmasGenreValue));
    }

    //  verify there are christmas genre songs
    set = SongMetadata.where(nameIs: 'genre', valueIs: christmasGenreValue);
    logger.i('set: $set');
    // 'Christmas' != 'christmas'
    expect(set.isEmpty, true);
    expect(set.length, 0);
    expect(set.contains(md0), false);
    expect(set.contains(md1), false);
    expect(set.contains(md2), false);
    expect(set.contains(md3), false);

    if (Logger.level.index <= Level.debug.index) {
      SplayTreeSet<String> names = SongMetadata.namesOf(set);
      for (String name in names) {
        logger.d('name: $name');
        SplayTreeSet<String> values = SongMetadata.valuesOf(set, name);
        for (String value in values) {
          logger.d('\tvalue: $value');
        }
      }

      //  list all
      logger.d('');
      for (SongIdMetadata idMetadata in SongMetadata.idMetadata) {
        logger.d(idMetadata.toString());
      }
    }
  });

  test('test json', () {
    final String id0 = SongId.computeSongId('Hey Joe', 'Jimi Hendrix', null).songId;

    //  metadata
    SongIdMetadata md0 =
        SongIdMetadata(id0, metadata: [const NameValue('genre', 'rock'), const NameValue('jam', 'casual')]);
    SongIdMetadata md1 = SongIdMetadata(SongId.computeSongId('\'39', 'Queen', null).songId,
        metadata: [const NameValue('genre', 'rock'), const NameValue('jam', 'advanced')]);
    SongIdMetadata md2 = SongIdMetadata(SongId.computeSongId('Boxer, The', 'Boxer, The', null).songId,
        metadata: [const NameValue('jam', 'advanced')]);
    SongIdMetadata md3 = SongIdMetadata(SongId.computeSongId('Holly Jolly Christmas', 'Burl Ives', null).songId,
        metadata: [const NameValue('christmas', '')]);
    SongMetadata.clear();
    SongMetadata.set(md0);
    SongMetadata.set(md1);
    SongMetadata.set(md2);
    SongMetadata.set(md3);
    String original = SongMetadata.toJson();
    logger.d(original);
    {
      String s = SongMetadata.toJson();
      SongMetadata.clear();
      SongMetadata.fromJson(s);

      logger.i(original);
      //logger.d('${Metadata.toJson()}');
      expect(SongMetadata.toJson(), original);
    }
  });

  // test('test jsonAt()', () {
  //   final String id0 = SongId.computeSongId('Hey Joe', 'Jimi Hendrix', null).songId;
  //
  //   //  metadata
  //   SongIdMetadata md0 =
  //       SongIdMetadata(id0, metadata: [const NameValue('genre', 'rock'), const NameValue('jam', 'casual')]);
  //   SongIdMetadata md1 = SongIdMetadata(SongId.computeSongId('\'39', 'Queen', null).songId,
  //       metadata: [const NameValue('genre', 'rock'), const NameValue('jam', 'advanced')]);
  //   SongIdMetadata md2 = SongIdMetadata(SongId.computeSongId('Boxer, The', 'Boxer, The', null).songId,
  //       metadata: [const NameValue('jam', 'advanced')]);
  //   SongIdMetadata md3 = SongIdMetadata(SongId.computeSongId('Holly Jolly Christmas', 'Burl Ives', null).songId,
  //       metadata: [const NameValue('christmas', '')]);
  //   SongMetadata.clear();
  //   SongMetadata.set(md0);
  //   SongMetadata.set(md1);
  //   SongMetadata.set(md2);
  //   SongMetadata.set(md3);
  //
  // expect(
  //     SongMetadata.toJsonAt(nameValue: const NameValue('genre', 'rock')),
  //     '[{"id":"Song_39_by_Queen","metadata":[{"name":"genre","value":"rock"}]},\n'
  //     '{"id":"Song_Hey_Joe_by_Jimi_Hendrix","metadata":[{"name":"genre","value":"rock"}]}]');
  // expect(
  //     SongMetadata.toJsonAt(nameValue: const NameValue('jam', 'advanced')),
  //     '[{"id":"Song_39_by_Queen","metadata":[{"name":"jam","value":"advanced"}]},\n'
  //     '{"id":"Song_Boxer_The_by_Boxer_The","metadata":[{"name":"jam","value":"advanced"}]}]');
  // expect(SongMetadata.toJsonAt(nameValue: const NameValue('christmas', '')),
  //     '[{"id":"Song_Holly_Jolly_Christmas_by_Burl_Ives","metadata":[{"name":"christmas","value":""}]}]');
  //
  // //  wrong name: jams not jam
  // expect(SongMetadata.toJsonAt(nameValue: const NameValue('jams', 'advanced')), '[]');
  //
  // //  wrong value: something not jam
  // expect(SongMetadata.toJsonAt(nameValue: const NameValue('jam', 'somethingElse')), '[]');
  //});

  bool rockMatch(SongIdMetadata idMetadata) {
    for (NameValue nameValue in idMetadata.nameValues) {
      if (nameValue.name == 'genre' && nameValue.value == 'rock') return true;
    }
    return false;
  }

  bool christmasMatch(SongIdMetadata idMetadata) {
    if (christmasRegExp.hasMatch(idMetadata.id)) {
      return true;
    }
    for (NameValue nameValue in idMetadata.nameValues) {
      if (christmasRegExp.hasMatch(nameValue.name)) return true;
    }
    return false;
  }

  bool notChristmasMatch(SongIdMetadata idMetadata) {
    return !christmasMatch(idMetadata);
  }

  bool cjRankingBest(SongIdMetadata idMetadata) {
    return idMetadata.contains(cjBest);
  }

  test('test match', () {
    //  metadata
    SongMetadata.clear();
    SplayTreeSet<SongIdMetadata> matches = SongMetadata.match(rockMatch);
    expect(matches, isNotNull);
    expect(matches, isEmpty);

    var rock = const NameValue('genre', 'rock');
    var cjOk = const NameValue('cj', 'ok');

    SongMetadata.set(SongIdMetadata(SongId.computeSongId('Dead Flowers', 'Stones, The', null).songId, metadata: [
      rock,
      cjBest /*ha!*/
    ]));
    SongMetadata.set(
        SongIdMetadata(SongId.computeSongId('Hey Joe', 'Jimi Hendrix', null).songId, metadata: [rock, cjBest]));
    SongMetadata.set(SongIdMetadata(SongId.computeSongId('\'39', 'Queen', null).songId, metadata: [rock, cjOk]));
    SongMetadata.set(
        SongIdMetadata(SongId.computeSongId('Boxer, The', 'Simon & Garfunkel', null).songId, metadata: [cjBest]));
    SongMetadata.set(SongIdMetadata(SongId.computeSongId('Holly Jolly Christmas', 'Burl Ives', null).songId,
        metadata: [const NameValue('christmas', '')]));

    matches = SongMetadata.match(rockMatch);
    expect(matches, isNotNull);
    expect(matches.length, 3);
    expect(matches.first.id, 'Song_39_by_Queen');

    matches = SongMetadata.match(christmasMatch);
    expect(matches, isNotNull);
    expect(matches.length, 1);
    expect(matches.first.id, 'Song_Holly_Jolly_Christmas_by_Burl_Ives');

    matches = SongMetadata.match(cjRankingBest);
    expect(matches, isNotNull);
    expect(matches.length, 3);
    expect(matches.first.id, 'Song_Boxer_The_by_Simon_Garfunkel');

    matches = SongMetadata.match(rockMatch, from: SongMetadata.match(christmasMatch));
    expect(matches, isNotNull);
    expect(matches, isEmpty);

    matches = SongMetadata.match(rockMatch,
        from: SongMetadata.match(cjRankingBest, from: SongMetadata.match(notChristmasMatch)));
    expect(matches, isNotNull);
    expect(matches.length, 2);
    expect(matches.first.id, 'Song_Dead_Flowers_by_Stones_The');

    matches = SongMetadata.filterMatch([rock]);
    expect(matches, isNotNull);
    expect(matches.length, 3);
    expect(matches.first.id, 'Song_39_by_Queen');
    expect(matches.last.id, 'Song_Hey_Joe_by_Jimi_Hendrix');

    matches = SongMetadata.filterMatch([rock, cjBest]);
    expect(matches, isNotNull);
    expect(matches.length, 2);
    expect(matches.first.id, 'Song_Dead_Flowers_by_Stones_The');
    expect(matches.last.id, 'Song_Hey_Joe_by_Jimi_Hendrix');

    matches = SongMetadata.filterMatch([]);
    expect(matches, isNotNull);
    expect(matches.length, 0);

    matches = SongMetadata.filterMatch([cjOk, cjBest]); //  should never match
    expect(matches, isNotNull);
    expect(matches.length, 0);

    for (var metadata in SongMetadata.idMetadata) {
      logger.i(SongId.asReadableString(metadata.id));
    }
  });

  test('test song metadata', () {
    Song a = Song.createSong('a song', 'bob', 'bob', Key.get(KeyEnum.C), 104, 4, 4, 'pearl bob',
        'v: C7 C7 C7 C7, F7 F7 C7 C7, G7 F7 C7 G7', 'v:');
    Song b = Song.createSong('b song', 'bob', 'bob', Key.get(KeyEnum.C), 104, 4, 4, 'pearl bob',
        'v: C7 C7 C7 C7, F7 F7 C7 C7, G7 F7 C7 G7', 'v:');
    var firstNv = const NameValue('test', 'first');
    SongMetadata.clear();
    SongMetadata.addSong(a, firstNv);
    expect(SongMetadata.where().length, 1);
    expect(SongMetadata.where(idIs: a.songId.toString()).length, 1);
    SongMetadata.addSong(b, firstNv);
    expect(SongMetadata.where().length, 2);
    expect(SongMetadata.where(idIs: a.songId.toString()).length, 1);
    expect(SongMetadata.where(idIs: b.songId.toString()).length, 1);
    SongMetadata.removeFromSong(a, firstNv);
    expect(SongMetadata.where(idIs: a.songId.toString()).length, 0);
    expect(SongMetadata.where(idIs: b.songId.toString()).length, 1);
    logger.i(SongMetadata.where(idIs: b.songId.toString()).first.toString());
    expect(SongMetadata.where(idIs: b.songId.toString()).first.toString(), //
        '''{ "id": "Song_b_song_by_bob", "metadata": [
	{"test":"first"}
	] }''');
    expect(SongMetadata.where().length, 1);
  });

  test('test mapYearToDecade', () {
    expect(mapYearToDecade(2020), '20\'s');
    expect(mapYearToDecade(2019), '10\'s');
    expect(mapYearToDecade(2010), '10\'s');
    expect(mapYearToDecade(1980), '80\'s');
    expect(mapYearToDecade(1979), '70\'s');
    expect(mapYearToDecade(1969), '60\'s');
    expect(mapYearToDecade(1954), '50\'s');
    expect(mapYearToDecade(1944), '40\'s');
    expect(mapYearToDecade(1939), 'prior to 1940');
    expect(mapYearToDecade(1879), 'prior to 1940');
    expect(mapYearToDecade(1875), 'prior to 1940');
    expect(mapYearToDecade(1870), 'prior to 1940');
    expect(mapYearToDecade(2022), '20\'s');
    expect(mapYearToDecade(2033), '2030\'s');
  });

  test('test generateDecade(Song song)', () {
    Song a = Song.createSong('a song', 'bob', 'Copyright 2022 bob', Key.get(KeyEnum.C), 104, 4, 4, 'pearl bob',
        'v: C7 C7 C7 C7, F7 F7 C7 C7, G7 F7 C7 G7', 'v:');
    SongMetadata.clear(); //  eliminate data from other tests
    var idmA = SongMetadata.songIdMetadata(a);
    expect(idmA, isNull);
    SongMetadata.generateSongMetadata(a);
    idmA = SongMetadata.songIdMetadata(a);
    expect(idmA, isNotNull);
    idmA = idmA!;
    expect(idmA.isNotEmpty, true);
    expect(idmA.contains(const NameValue('Decade', '20\'s')), isTrue);

    Song b = Song.createSong('b song', 'bob', 'no year bob', Key.get(KeyEnum.C), 104, 4, 4, 'pearl bob',
        'v: C7 C7 C7 C7, F7 F7 C7 C7, G7 F7 C7 G7', 'v:');
    SongMetadata.clear(); //  eliminate data from other tests
    var idmB = SongMetadata.songIdMetadata(b);
    expect(idmB, isNull);
    SongMetadata.generateSongMetadata(b);
    idmB = SongMetadata.songIdMetadata(b);
    expect(idmB, isNotNull);
    logger.i('idmB: $idmB');
    b.copyright = '1969';
    logger.i('b.copyright: "${b.copyright}"');
    SongMetadata.generateMetadata([a, b]);
    idmB = SongMetadata.songIdMetadata(b);
    expect(idmB, isNotNull);
    idmB = idmB!;
    expect(idmB.isNotEmpty, true);
    expect(idmB.contains(const NameValue('Decade', '60\'s')), isTrue);
  });

  test('test NameValueFilter', () {
    const userBob = NameValue('user', 'bob');
    const userShari = NameValue('user', 'Shari');
    const userBodhi = NameValue('user', 'Bodhi');

    var filter = NameValueFilter([]);
    expect(filter.test(userBob), false);
    expect(filter.test(userShari), false);
    expect(filter.test(userBodhi), false);
    expect(filter.isOr(userBob), false);
    expect(filter.isOr(userShari), false);
    expect(filter.isOr(userBodhi), false);
    expect(filter.nameValues().toList().toString(), '[]');

    filter = NameValueFilter([userBob]);
    expect(filter.test(userBob), true);
    expect(filter.test(userShari), false);
    expect(filter.test(userBodhi), false);
    expect(filter.isOr(userBob), false);
    expect(filter.isOr(userShari), false);
    expect(filter.isOr(userBodhi), false);
    logger.i(filter.nameValues().toList().toString());
    expect(filter.nameValues().toList().toString(), '[{"user":"bob"}]');

    filter = NameValueFilter([userBob, userShari]);
    expect(filter.test(userBob), true);
    expect(filter.test(userShari), true);
    expect(filter.test(userBodhi), false);
    expect(filter.isOr(userBob), true);
    expect(filter.isOr(userShari), true);
    expect(filter.isOr(userBodhi), false);
    logger.i(filter.nameValues().toList().toString());
    expect(filter.nameValues().toList().toString(), '[{"user":"Shari"}, {"user":"bob"}]');
  });

  test('test NameValueFilter testAll', () {
    const userBob = NameValue('user', 'bob');
    const userShari = NameValue('user', 'Shari');
    const userBodhi = NameValue('user', 'Bodhi');

    var filter = NameValueFilter([userBob, userShari]);
    expect(filter.testAll(SplayTreeSet<NameValue>()..addAll([userBob])), true);
    expect(filter.testAll(SplayTreeSet<NameValue>()..addAll([userShari])), true);
    expect(filter.testAll(SplayTreeSet<NameValue>()..addAll([userBodhi])), false);

    filter = NameValueFilter([userBob, userShari, const NameValue('foo', 'bar')]);
    expect(filter.testAll(SplayTreeSet<NameValue>()..addAll([userBob])), false);
    expect(filter.testAll(SplayTreeSet<NameValue>()..addAll([userShari])), false);
    expect(filter.testAll(SplayTreeSet<NameValue>()..addAll([userBodhi])), false);

    filter = NameValueFilter([const NameValue('foo', 'bar')]);
    expect(filter.testAll(SplayTreeSet<NameValue>()..addAll([userBob])), false);
    expect(filter.testAll(SplayTreeSet<NameValue>()..addAll([userShari])), false);
    expect(filter.testAll(SplayTreeSet<NameValue>()..addAll([userBodhi])), false);

    filter = NameValueFilter([userBob, userShari, const NameValue('foo', 'bar')]);
    expect(filter.testAll(SplayTreeSet<NameValue>()..addAll([userBob, const NameValue('foo', 'bar')])), true);
    expect(filter.testAll(SplayTreeSet<NameValue>()..addAll([userShari, const NameValue('foo', 'bar')])), true);
    expect(filter.testAll(SplayTreeSet<NameValue>()..addAll([userBodhi, const NameValue('foo', 'bar')])), false);
  });
}

final RegExp christmasRegExp = RegExp(r'.*christmas.*', caseSensitive: false);
