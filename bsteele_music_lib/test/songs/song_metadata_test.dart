import 'dart:collection';

import 'package:bsteeleMusicLib/app_logger.dart';
import 'package:bsteeleMusicLib/songs/key.dart';
import 'package:bsteeleMusicLib/songs/song.dart';
import 'package:bsteeleMusicLib/songs/song_id.dart';
import 'package:bsteeleMusicLib/songs/song_metadata.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

var jamBest = NameValue('Jam', 'Best');

void main() {
  Logger.level = Level.info;

  test('test basic Metadata', () {
    SongMetadata.clear();

    const String id0 = 'id0';
    {
      expect(SongIdMetadata(id0, metadata: [NameValue('Genre', 'Rock')]).toJson(),
          '{"id":"id0","metadata":[{"name":"Genre","value":"Rock"}]}');
      expect(SongIdMetadata(id0, metadata: [NameValue('Genre', 'Rock'), NameValue('Genre', 'Rock')]).toJson(),
          '{"id":"id0","metadata":[{"name":"Genre","value":"Rock"}]}');

      SongIdMetadata md = SongIdMetadata(id0, metadata: [NameValue('Genre', 'Rock'), NameValue('Jam', 'casual')]);
      expect(md.toJson(), '{"id":"id0","metadata":[{"name":"Genre","value":"Rock"},{"name":"Jam","value":"Casual"}]}');
      md.remove(NameValue('Jam', 'casual'));
      expect(md.toJson(), '{"id":"id0","metadata":[{"name":"Genre","value":"Rock"}]}');
      md.add(NameValue('Jam', 'casual'));
      expect(md.toJson(), '{"id":"id0","metadata":[{"name":"Genre","value":"Rock"},{"name":"Jam","value":"Casual"}]}');
    }

    //  metadata
    SongIdMetadata md0 = SongIdMetadata(id0, metadata: [NameValue('Genre', 'Rock'), NameValue('Jam', 'Casual')]);
    SongIdMetadata md1 = SongIdMetadata('id1', metadata: [NameValue('Genre', 'Rock'), NameValue('Jam', 'Advanced')]);
    SongIdMetadata md2 = SongIdMetadata('id2', metadata: [NameValue('Jam', 'Advanced')]);
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

    set = SongMetadata.where(nameIsLike: 'Genre');
    expect(set.isEmpty, false);
    expect(set.length, 2);
    expect(set.contains(md0), true);
    expect(set.contains(md1), true);
    expect(set.contains(md2), false);

    set = SongMetadata.where(nameIsLike: 'Jam', valueIsLike: 'ad');
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
	{"Genre":"Rock"},
	{"Jam":"Advanced"}
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

    //  verify there are no christmas Genre songs
    set = SongMetadata.where(nameIsLike: 'Genre', valueIsLike: 'christmas');
    expect(set.isEmpty, true);

    //  set songs with christmas in the title or artist to be the christmas Genre
    String christmasGenreValue = 'Christmas';
    set = SongMetadata.where(idIsLike: christmasGenreValue);
    for (SongIdMetadata idm in set) {
      idm.add(NameValue('Genre', christmasGenreValue));
    }

    //  verify there are christmas Genre songs
    set = SongMetadata.where(nameIsLike: 'Genre', valueIsLike: christmasGenreValue);
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
      for (SongIdMetadata songIdMetadata in SongMetadata.idMetadata) {
        logger.d(songIdMetadata.toString());
      }
    }
  });

  test('test Metadata exact matches', () {
    SongMetadata.clear();

    const String id0 = 'id0';
    {
      expect(SongIdMetadata(id0, metadata: [NameValue('Genre', 'Rock')]).toJson(),
          '{"id":"id0","metadata":[{"name":"Genre","value":"Rock"}]}');
      expect(SongIdMetadata(id0, metadata: [NameValue('Genre', 'Rock'), NameValue('Genre', 'Rock')]).toJson(),
          '{"id":"id0","metadata":[{"name":"Genre","value":"Rock"}]}');

      SongIdMetadata md = SongIdMetadata(id0, metadata: [NameValue('Genre', 'Rock'), NameValue('Jam', 'casual')]);
      expect(md.toJson(), '{"id":"id0","metadata":[{"name":"Genre","value":"Rock"},{"name":"Jam","value":"Casual"}]}');
      md.remove(NameValue('Jam', 'casual'));
      expect(md.toJson(), '{"id":"id0","metadata":[{"name":"Genre","value":"Rock"}]}');
      md.add(NameValue('Jam', 'casual'));
      expect(md.toJson(), '{"id":"id0","metadata":[{"name":"Genre","value":"Rock"},{"name":"Jam","value":"Casual"}]}');
    }

    //  metadata
    SongIdMetadata md0 = SongIdMetadata(id0, metadata: [NameValue('Genre', 'Rock'), NameValue('Jam', 'Casual')]);
    SongIdMetadata md1 = SongIdMetadata('id1', metadata: [NameValue('Genre', 'Rock'), NameValue('Jam', 'Advanced')]);
    SongIdMetadata md2 = SongIdMetadata('id2', metadata: [NameValue('Jam', 'Advanced')]);
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

    set = SongMetadata.where(nameIs: 'Genre');
    expect(set.isEmpty, false);
    expect(set.length, 2);
    expect(set.contains(md0), true);
    expect(set.contains(md1), true);
    expect(set.contains(md2), false);

    set = SongMetadata.where(nameIs: 'Jam', valueIs: 'Advanced');
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

    //  verify there are no christmas Genre songs
    set = SongMetadata.where(nameIs: 'Genre', valueIs: 'christmas');
    expect(set.isEmpty, true);

    //  set songs with christmas in the title or artist to be the christmas Genre
    String christmasGenreValue = 'Christmas';
    set = SongMetadata.where(idIs: christmasGenreValue);
    for (SongIdMetadata idm in set) {
      idm.add(NameValue('Genre', christmasGenreValue));
    }

    //  verify there are christmas Genre songs
    set = SongMetadata.where(nameIs: 'Genre', valueIs: christmasGenreValue);
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
    SongIdMetadata md0 = SongIdMetadata(id0, metadata: [NameValue('Genre', 'Rock'), NameValue('Jam', 'casual')]);
    SongIdMetadata md1 = SongIdMetadata(SongId.computeSongId('\'39', 'Queen', null).songId,
        metadata: [NameValue('Genre', 'Rock'), NameValue('Jam', 'advanced')]);
    SongIdMetadata md2 = SongIdMetadata(SongId.computeSongId('Boxer, The', 'Boxer, The', null).songId,
        metadata: [NameValue('Jam', 'advanced')]);
    SongIdMetadata md3 = SongIdMetadata(SongId.computeSongId('Holly Jolly Christmas', 'Burl Ives', null).songId,
        metadata: [NameValue('christmas', '')]);
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
  //       SongIdMetadata(id0, metadata: [NameValue('Genre', 'Rock'), NameValue('Jam', 'casual')]);
  //   SongIdMetadata md1 = SongIdMetadata(SongId.computeSongId('\'39', 'Queen', null).songId,
  //       metadata: [NameValue('Genre', 'Rock'), NameValue('Jam', 'advanced')]);
  //   SongIdMetadata md2 = SongIdMetadata(SongId.computeSongId('Boxer, The', 'Boxer, The', null).songId,
  //       metadata: [NameValue('Jam', 'advanced')]);
  //   SongIdMetadata md3 = SongIdMetadata(SongId.computeSongId('Holly Jolly Christmas', 'Burl Ives', null).songId,
  //       metadata: [NameValue('christmas', '')]);
  //   SongMetadata.clear();
  //   SongMetadata.set(md0);
  //   SongMetadata.set(md1);
  //   SongMetadata.set(md2);
  //   SongMetadata.set(md3);
  //
  // expect(
  //     SongMetadata.toJsonAt(nameValue: NameValue('Genre', 'Rock')),
  //     '[{"id":"Song_39_by_Queen","metadata":[{"name":"Genre","value":"Rock"}]},\n'
  //     '{"id":"Song_Hey_Joe_by_Jimi_Hendrix","metadata":[{"name":"Genre","value":"Rock"}]}]');
  // expect(
  //     SongMetadata.toJsonAt(nameValue: NameValue('Jam', 'advanced')),
  //     '[{"id":"Song_39_by_Queen","metadata":[{"name":"Jam","value":"advanced"}]},\n'
  //     '{"id":"Song_Boxer_The_by_Boxer_The","metadata":[{"name":"Jam","value":"advanced"}]}]');
  // expect(SongMetadata.toJsonAt(nameValue: NameValue('christmas', '')),
  //     '[{"id":"Song_Holly_Jolly_Christmas_by_Burl_Ives","metadata":[{"name":"christmas","value":""}]}]');
  //
  // //  wrong name: Jams not Jam
  // expect(SongMetadata.toJsonAt(nameValue: NameValue('Jams', 'advanced')), '[]');
  //
  // //  wrong value: something not Jam
  // expect(SongMetadata.toJsonAt(nameValue: NameValue('Jam', 'somethingElse')), '[]');
  //});

  bool rockMatch(SongIdMetadata idMetadata) {
    for (NameValue nameValue in idMetadata.nameValues) {
      if (nameValue.name == 'Genre' && nameValue.value == 'Rock') return true;
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
    return idMetadata.contains(jamBest);
  }

  test('test match', () {
    //  metadata
    SongMetadata.clear();
    SplayTreeSet<SongIdMetadata> matches = SongMetadata.match(rockMatch);
    expect(matches, isNotNull);
    expect(matches, isEmpty);

    var rock = NameValue('Genre', 'Rock');
    var jamOk = NameValue('Jam', 'Ok');

    SongMetadata.set(SongIdMetadata(SongId.computeSongId('Dead Flowers', 'Stones, The', null).songId, metadata: [
      rock,
      jamBest /*ha!*/
    ]));
    SongMetadata.set(
        SongIdMetadata(SongId.computeSongId('Hey Joe', 'Jimi Hendrix', null).songId, metadata: [rock, jamBest]));
    SongMetadata.set(SongIdMetadata(SongId.computeSongId('\'39', 'Queen', null).songId, metadata: [rock, jamOk]));
    SongMetadata.set(
        SongIdMetadata(SongId.computeSongId('Boxer, The', 'Simon & Garfunkel', null).songId, metadata: [jamBest]));
    SongMetadata.set(SongIdMetadata(SongId.computeSongId('Holly Jolly Christmas', 'Burl Ives', null).songId,
        metadata: [NameValue('christmas', '')]));

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

    matches = SongMetadata.filterMatch([rock, jamBest]);
    expect(matches, isNotNull);
    expect(matches.length, 2);
    expect(matches.first.id, 'Song_Dead_Flowers_by_Stones_The');
    expect(matches.last.id, 'Song_Hey_Joe_by_Jimi_Hendrix');

    matches = SongMetadata.filterMatch([]);
    expect(matches, isNotNull);
    expect(matches.length, 0);

    matches = SongMetadata.filterMatch([jamOk, jamBest]); //  should never match
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
    var firstNv = NameValue('test', 'first');
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
    expect(
        SongMetadata.where(idIs: b.songId.toString()).first.toString(), //
        '''{ "id": "Song_b_song_by_bob", "metadata": [
	{"Test":"First"}
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
    expect(idmA.contains(NameValue('Decade', '20\'s')), isTrue);

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
    expect(idmB.contains(NameValue('Decade', '60\'s')), isTrue);
  });

  test('test isOr', () {
    NameValueFilter filter;
    final userBob = NameValue('user', 'bob');
    final userShari = NameValue('user', 'Shari');
    final userBodhi = NameValue('user', 'Bodhi');

    filter = NameValueFilter([]);
    expect(filter.test(userBob), false);
    expect(filter.test(userShari), false);
    expect(filter.test(userBodhi), false);
    expect(filter.isOr(userBob), false);
    expect(filter.isOr(userShari), false);
    expect(filter.isOr(userBodhi), false);
    expect(filter.matchers().toList().toString(), '[]');

    filter = NameValueFilter([NameValueMatcher.value(userBob)]);
    expect(filter.test(userBob), true);
    expect(filter.test(userShari), false);
    expect(filter.test(userBodhi), false);
    expect(filter.isOr(userBob), false);
    expect(filter.isOr(userShari), false);
    expect(filter.isOr(userBodhi), false);
    logger.i(filter.matchers().toList().toString());
    expect(filter.matchers().toList().toString(), '[{"User":"Bob"}]');

    filter = NameValueFilter([NameValueMatcher.value(userBob), NameValueMatcher.value(userShari)]);
    expect(filter.test(userBob), true);
    expect(filter.test(userShari), true);
    expect(filter.test(userBodhi), false);
    expect(filter.isOr(userBob), true);
    expect(filter.isOr(userShari), true);
    expect(filter.isOr(userBodhi), false);
    logger.i(filter.matchers().toList().toString());
    expect(filter.matchers().toList().toString(), '[{"User":"Bob"}, {"User":"Shari"}]');
  });

  test('test NameValueFilter testAll', () {
    NameValueFilter filter;
    final userBob = NameValue('User', 'bob');
    final userShari = NameValue('User', 'Shari');
    final userBodhi = NameValue('User', 'Bodhi');

    filter = NameValueFilter([
      NameValueMatcher.value(userBob),
      NameValueMatcher.value(userShari),
      NameValueMatcher.value(NameValue('foo', 'bar'))
    ]);
    expect(filter.testAll([userBob]), false);
    expect(filter.testAll([userShari]), false);
    expect(filter.testAll([userBodhi]), false);

    filter = NameValueFilter([NameValueMatcher.value(NameValue('foo', 'bar'))]);
    expect(filter.testAll([userBob]), false);
    expect(filter.testAll([userShari]), false);
    expect(filter.testAll([userBodhi]), false);

    filter = NameValueFilter([NameValueMatcher.value(userBob), NameValueMatcher.value(userShari)]);
    expect(filter.testAll([userBob]), true);
    expect(filter.testAll([userShari]), true);
    expect(filter.testAll([userBodhi]), false);

    filter = NameValueFilter([
      NameValueMatcher.value(userBob),
      NameValueMatcher.value(userShari),
      NameValueMatcher.value(NameValue('foo', 'bar'))
    ]);
    expect(filter.testAll([userBob, NameValue('foo', 'bar')]), true);
    expect(filter.testAll([userShari, NameValue('foo', 'bar')]), true);
    expect(filter.testAll([userBodhi, NameValue('foo', 'bar')]), false);
  });

  test('test NameValueTypes', () {
    final userBob = NameValue('User', 'bob');
    final userShari = NameValue('User', 'Shari');
    final userBodhi = NameValue('User', 'Bodhi');
    final rock = NameValue('Genre', 'Rock');
    final blues = NameValue('Genre', 'Blues');

    expect(blues.name, 'Genre');
    expect(blues.value, 'Blues');

    NameValueFilter filter;

    filter = NameValueFilter([NameValueMatcher.value(userBob), NameValueMatcher.value(userShari)]);
    expect(filter.test(userBob), true);
    expect(filter.test(userShari), true);
    expect(filter.test(userBodhi), false);
    expect(filter.test(rock), false);
    expect(filter.test(blues), false);

    filter = NameValueFilter([NameValueMatcher.value(rock)]);
    expect(filter.test(userBob), false);
    expect(filter.test(userShari), false);
    expect(filter.test(userBodhi), false);
    expect(filter.test(rock), true);
    expect(filter.test(blues), false);

    filter = NameValueFilter([NameValueMatcher.noValue(blues.name)]);
    expect(filter.testAll([userBob]), true);
    expect(filter.testAll([userShari]), true);
    expect(filter.testAll([userBodhi]), true);
    expect(filter.testAll([rock]), false);
    expect(filter.testAll([blues]), false);

    filter = NameValueFilter([NameValueMatcher.value(rock), NameValueMatcher.value(userBob)]);
    expect(filter.testAll([userBob]), false);
    expect(filter.testAll([userShari]), false);
    expect(filter.testAll([userBodhi]), false);
    expect(filter.testAll([userBob, rock]), true);
    expect(filter.testAll([userShari, rock]), false);
    expect(filter.testAll([userBodhi, rock]), false);
    expect(filter.testAll([userBob, blues]), false);
    expect(filter.testAll([userShari, blues]), false);
    expect(filter.testAll([userBodhi, blues]), false);
    expect(filter.testAll([rock]), false);
    expect(filter.testAll([blues]), false);

    filter = NameValueFilter(
        [NameValueMatcher.value(userShari), NameValueMatcher.value(rock), NameValueMatcher.value(userBob)]);
    expect(filter.testAll([userBob]), false);
    expect(filter.testAll([userShari]), false);
    expect(filter.testAll([userBodhi]), false);
    expect(filter.testAll([userBob, rock]), true);
    expect(filter.testAll([userShari, rock]), true);
    expect(filter.testAll([userBodhi, rock]), false);
    expect(filter.testAll([userBob, blues]), false);
    expect(filter.testAll([userShari, blues]), false);
    expect(filter.testAll([userBodhi, blues]), false);
    expect(filter.testAll([rock]), false);
    expect(filter.testAll([blues]), false);

    filter = NameValueFilter(
        //  user intentionally out of order
        [NameValueMatcher.value(userShari), NameValueMatcher.value(userBodhi), NameValueMatcher.value(userBob)]);
    expect(filter.testAll([userBob]), true);
    expect(filter.testAll([userShari]), true);
    expect(filter.testAll([userBodhi]), true);
    expect(filter.testAll([userBob, rock]), true);
    expect(filter.testAll([userShari, rock]), true);
    expect(filter.testAll([userBodhi, rock]), true);
    expect(filter.testAll([userBob, blues]), true);
    expect(filter.testAll([userShari, blues]), true);
    expect(filter.testAll([userBodhi, blues]), true);
    expect(filter.testAll([rock]), false);
    expect(filter.testAll([blues]), false);

    filter = NameValueFilter(
        [NameValueMatcher.value(userShari), NameValueMatcher.anyValue(rock.name), NameValueMatcher.value(userBob)]);
    expect(filter.testAll([userBob]), false);
    expect(filter.testAll([userShari]), false);
    expect(filter.testAll([userBodhi]), false);
    expect(filter.testAll([userBob, rock]), true);
    expect(filter.testAll([userShari, rock]), true);
    expect(filter.testAll([userBodhi, rock]), false);
    expect(filter.testAll([userBob, blues]), true);
    expect(filter.testAll([userShari, blues]), true);
    expect(filter.testAll([userBodhi, blues]), false);
    expect(filter.testAll([rock]), false);
    expect(filter.testAll([blues]), false);

    filter = NameValueFilter(
        [NameValueMatcher.value(userShari), NameValueMatcher.noValue(rock.name), NameValueMatcher.value(userBob)]);
    expect(filter.testAll([userBob]), true);
    expect(filter.testAll([userShari]), true);
    expect(filter.testAll([userBodhi]), false);
    expect(filter.testAll([userBob, rock]), false);
    expect(filter.testAll([userShari, rock]), false);
    expect(filter.testAll([userBodhi, rock]), false);
    expect(filter.testAll([userBob, blues]), false);
    expect(filter.testAll([userShari, blues]), false);
    expect(filter.testAll([userBodhi, blues]), false);
    expect(filter.testAll([rock]), false);
    expect(filter.testAll([blues]), false);
  });
}

final RegExp christmasRegExp = RegExp(r'.*christmas.*', caseSensitive: false);
