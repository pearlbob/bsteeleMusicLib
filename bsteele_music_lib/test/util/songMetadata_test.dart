import 'dart:collection';

import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/songId.dart';
import 'package:bsteeleMusicLib/songs/songMetadata.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('test Metadata', () {
    SongMetadata.clear();

    final String id0 = 'id0';
    {
      expect(SongIdMetadata(id0, metadata: [NameValue('genre', 'rock')]).toJson(),
          '{"id":"id0","metadata":[{"name":"genre","value":"rock"}]}');
      expect(SongIdMetadata(id0, metadata: [NameValue('genre', 'rock'), NameValue('genre', 'rock')]).toJson(),
          '{"id":"id0","metadata":[{"name":"genre","value":"rock"}]}');

      SongIdMetadata md = SongIdMetadata(id0, metadata: [NameValue('genre', 'rock'), NameValue('jam', 'casual')]);
      expect(md.toJson(), '{"id":"id0","metadata":[{"name":"genre","value":"rock"},{"name":"jam","value":"casual"}]}');
      md.remove(NameValue('jam', 'casual'));
      expect(md.toJson(), '{"id":"id0","metadata":[{"name":"genre","value":"rock"}]}');
      md.add(NameValue('jam', 'casual'));
      expect(md.toJson(), '{"id":"id0","metadata":[{"name":"genre","value":"rock"},{"name":"jam","value":"casual"}]}');
    }

    //  metadata
    SongIdMetadata md0 = SongIdMetadata(id0, metadata: [NameValue('genre', 'rock'), NameValue('jam', 'casual')]);
    SongIdMetadata md1 = SongIdMetadata('id1', metadata: [NameValue('genre', 'rock'), NameValue('jam', 'advanced')]);
    SongIdMetadata md2 = SongIdMetadata('id2', metadata: [NameValue('jam', 'advanced')]);
    SongIdMetadata md3 = SongIdMetadata('id3 christmas');

    SplayTreeSet<SongIdMetadata> set = SplayTreeSet();

    set = SongMetadata.where(idIsLike: id0);
    expect(set.isEmpty, true);

    SongMetadata.set(md0);
    SongMetadata.set(md1);
    SongMetadata.set(md2);
    SongMetadata.set(md3);
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
        logger.d('${idMetadata.toString()}');
      }
    }
  });

  test('test Metadata exact matches', () {
    SongMetadata.clear();

    final String id0 = 'id0';
    {
      expect(SongIdMetadata(id0, metadata: [NameValue('genre', 'rock')]).toJson(),
          '{"id":"id0","metadata":[{"name":"genre","value":"rock"}]}');
      expect(SongIdMetadata(id0, metadata: [NameValue('genre', 'rock'), NameValue('genre', 'rock')]).toJson(),
          '{"id":"id0","metadata":[{"name":"genre","value":"rock"}]}');

      SongIdMetadata md = SongIdMetadata(id0, metadata: [NameValue('genre', 'rock'), NameValue('jam', 'casual')]);
      expect(md.toJson(), '{"id":"id0","metadata":[{"name":"genre","value":"rock"},{"name":"jam","value":"casual"}]}');
      md.remove(NameValue('jam', 'casual'));
      expect(md.toJson(), '{"id":"id0","metadata":[{"name":"genre","value":"rock"}]}');
      md.add(NameValue('jam', 'casual'));
      expect(md.toJson(), '{"id":"id0","metadata":[{"name":"genre","value":"rock"},{"name":"jam","value":"casual"}]}');
    }

    //  metadata
    SongIdMetadata md0 = SongIdMetadata(id0, metadata: [NameValue('genre', 'rock'), NameValue('jam', 'casual')]);
    SongIdMetadata md1 = SongIdMetadata('id1', metadata: [NameValue('genre', 'rock'), NameValue('jam', 'advanced')]);
    SongIdMetadata md2 = SongIdMetadata('id2', metadata: [NameValue('jam', 'advanced')]);
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
    expect(set.length, 4);  //  'id3 christmas' != 'christmas'
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
        logger.d('${idMetadata.toString()}');
      }
    }
  });

  test('test json', () {
    final String id0 = SongId.computeSongId('Hey Joe', 'Jimi Hendrix', null).songId;

    //  metadata
    SongIdMetadata md0 = SongIdMetadata(id0, metadata: [NameValue('genre', 'rock'), NameValue('jam', 'casual')]);
    SongIdMetadata md1 = SongIdMetadata(SongId.computeSongId('\'39', 'Queen', null).songId,
        metadata: [NameValue('genre', 'rock'), NameValue('jam', 'advanced')]);
    SongIdMetadata md2 = SongIdMetadata(SongId.computeSongId('Boxer, The', 'Boxer, The', null).songId,
        metadata: [NameValue('jam', 'advanced')]);
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

      logger.i('$original');
      //logger.d('${Metadata.toJson()}');
      expect(SongMetadata.toJson(), original);
    }
  });

  bool _rockMatch(SongIdMetadata idMetadata) {
    for (NameValue nameValue in idMetadata.nameValues) {
      if (nameValue.name == 'genre' && nameValue.value == 'rock') return true;
    }
    return false;
  }

  bool _christmasMatch(SongIdMetadata idMetadata) {
    if (christmasRegExp.hasMatch(idMetadata.id)) {
      return true;
    }
    for (NameValue nameValue in idMetadata.nameValues) {
      if (christmasRegExp.hasMatch(nameValue.name)) return true;
    }
    return false;
  }

  bool _notChristmasMatch(SongIdMetadata idMetadata) {
    return !_christmasMatch(idMetadata);
  }

  bool _cjRanking(SongIdMetadata idMetadata, CjRankingEnum ranking) {
    for (NameValue nameValue in idMetadata.nameValues) {
      if (nameValue.name == 'cj') {
        CjRankingEnum r = nameValue.value.toCjRankingEnum();
        if (r.index >= ranking.index) {
          return true;
        }
      }
    }
    return false;
  }

  bool _cjRankingBest(SongIdMetadata idMetadata) {
    return _cjRanking(idMetadata, CjRankingEnum.best);
  }

  test('test match', () {
    //  metadata
    SongMetadata.clear();
    SplayTreeSet<SongIdMetadata> matches = SongMetadata.match(_rockMatch);
    expect(matches, isNotNull);
    expect(matches, isEmpty);

    SongMetadata.set(SongIdMetadata(SongId.computeSongId('Hey Joe', 'Jimi Hendrix', null).songId,
        metadata: [NameValue('genre', 'rock'), NameValue('cj', 'best')]));
    SongMetadata.set(SongIdMetadata(SongId.computeSongId('\'39', 'Queen', null).songId,
        metadata: [NameValue('genre', 'rock'), NameValue('cj', 'ok')]));
    SongMetadata.set(SongIdMetadata(SongId.computeSongId('Boxer, The', 'Boxer, The', null).songId,
        metadata: [NameValue('cj', 'best')]));
    SongMetadata.set(SongIdMetadata(SongId.computeSongId('Holly Jolly Christmas', 'Burl Ives', null).songId,
        metadata: [NameValue('christmas', '')]));

    matches = SongMetadata.match(_rockMatch);
    expect(matches, isNotNull);
    expect(matches.length, 2);
    expect(matches.first.id, 'Song_39_by_Queen');

    matches = SongMetadata.match(_christmasMatch);
    expect(matches, isNotNull);
    expect(matches.length, 1);
    expect(matches.first.id, 'Song_Holly_Jolly_Christmas_by_Burl_Ives');

    matches = SongMetadata.match(_cjRankingBest);
    expect(matches, isNotNull);
    expect(matches.length, 2);
    expect(matches.first.id, 'Song_Boxer_The_by_Boxer_The');

    matches = SongMetadata.match(_rockMatch, from: SongMetadata.match(_christmasMatch));
    expect(matches, isNotNull);
    expect(matches, isEmpty);

    matches = SongMetadata.match(_rockMatch,
        from: SongMetadata.match(_cjRankingBest, from: SongMetadata.match(_notChristmasMatch)));
    expect(matches, isNotNull);
    expect(matches.length, 1);
    expect(matches.first.id, 'Song_Hey_Joe_by_Jimi_Hendrix');
  });
}

final RegExp christmasRegExp = RegExp(r'.*christmas.*', caseSensitive: false);
