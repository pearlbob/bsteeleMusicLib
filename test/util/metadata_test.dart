import 'dart:collection';
import 'dart:convert';

import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/songId.dart';
import 'package:bsteeleMusicLib/util/metadata.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('test Metadata', () {
    final String id0 = 'id0';
    {
      expect(IdMetadata(id0, metadata: [NameValue('genre', 'rock')]).toJson(),
          '{"id":"id0","metadata":[{"genre":"rock"}]}');
      expect(IdMetadata(id0, metadata: [NameValue('genre', 'rock'), NameValue('genre', 'rock')]).toJson(),
          '{"id":"id0","metadata":[{"genre":"rock"}]}');

      IdMetadata md = IdMetadata(id0, metadata: [NameValue('genre', 'rock'), NameValue('jam', 'casual')]);
      expect(md.toJson(), '{"id":"id0","metadata":[{"genre":"rock"},{"jam":"casual"}]}');
      md.remove(NameValue('jam', 'casual'));
      expect(md.toJson(), '{"id":"id0","metadata":[{"genre":"rock"}]}');
      md.add(NameValue('jam', 'casual'));
      expect(md.toJson(), '{"id":"id0","metadata":[{"genre":"rock"},{"jam":"casual"}]}');
    }

    //  metadata
    IdMetadata md0 = IdMetadata(id0, metadata: [NameValue('genre', 'rock'), NameValue('jam', 'casual')]);
    IdMetadata md1 = IdMetadata('id1', metadata: [NameValue('genre', 'rock'), NameValue('jam', 'advanced')]);
    IdMetadata md2 = IdMetadata('id2', metadata: [NameValue('jam', 'advanced')]);
    IdMetadata md3 = IdMetadata('id3 christmas');

    SplayTreeSet<IdMetadata> set = Metadata.where(idIsLike: id0);
    expect(set.isEmpty, true);

    Metadata.set(md0);
    Metadata.set(md1);
    Metadata.set(md2);
    Metadata.set(md3);
    set = Metadata.where(idIsLike: md0.id);
    expect(set.isEmpty, false);
    expect(set.length, 1);
    expect(set.contains(md0), true);

    set = Metadata.where(idIsLike: 'foo');
    expect(set.isEmpty, true);

    set = Metadata.where(nameIsLike: 'genre');
    expect(set.isEmpty, false);
    expect(set.length, 2);
    expect(set.contains(md0), true);
    expect(set.contains(md1), true);
    expect(set.contains(md2), false);

    set = Metadata.where(nameIsLike: 'jam', valueIsLike: 'ad');
    expect(set.isEmpty, false);
    expect(set.length, 2);
    expect(set.contains(md0), false);
    expect(set.contains(md1), true);
    expect(set.contains(md2), true);
    expect(set.contains(md3), false);

    //  get them all
    set = Metadata.where();
    expect(set.isEmpty, false);
    expect(set.length, 4);

    //  not christmas
    set = Metadata.where();
    set.removeAll(Metadata.where(idIsLike: 'christmas'));
    expect(set.isEmpty, false);
    expect(set.length, 3);
    expect(set.contains(md0), true);
    expect(set.contains(md1), true);
    expect(set.contains(md2), true);
    expect(set.contains(md3), false);

    //  verify there are no christmas genre songs
    set = Metadata.where(nameIsLike: 'genre', valueIsLike: 'christmas');
    expect(set.isEmpty, true);

    //  set songs with christmas in the title or artist to be the christmas genre
    String christmasGenreValue = 'Christmas';
    set = Metadata.where(idIsLike: christmasGenreValue);
    for (IdMetadata idm in set) {
      idm.add(NameValue('genre', christmasGenreValue));
    }

    //  verify there are christmas genre songs
    set = Metadata.where(nameIsLike: 'genre', valueIsLike: christmasGenreValue);
    expect(set.isEmpty, false);
    expect(set.length, 1);
    expect(set.contains(md0), false);
    expect(set.contains(md1), false);
    expect(set.contains(md2), false);
    expect(set.contains(md3), true);

    if (Logger.level.index <= Level.debug.index) {
      SplayTreeSet<String> names = Metadata.namesOf(set);
      for (String name in names) {
        logger.d('name: $name');
        SplayTreeSet<String> values = Metadata.valuesOf(set, name);
        for (String value in values) {
          logger.d('\tvalue: $value');
        }
      }

      //  list all
      logger.d('');
      for (IdMetadata idMetadata in Metadata.idMetadata) {
        logger.d('${idMetadata.toString()}');
      }
    }
  });

  test('test json', () {
    final String id0 = SongId.computeSongId('Hey Joe', 'Jimi Hendrix', null).songId;

    //  metadata
    IdMetadata md0 = IdMetadata(id0, metadata: [NameValue('genre', 'rock'), NameValue('jam', 'casual')]);
    IdMetadata md1 = IdMetadata(SongId.computeSongId('\'39', 'Queen', null).songId,
        metadata: [NameValue('genre', 'rock'), NameValue('jam', 'advanced')]);
    IdMetadata md2 = IdMetadata(SongId.computeSongId('Boxer, The', 'Boxer, The', null).songId,
        metadata: [NameValue('jam', 'advanced')]);
    IdMetadata md3 = IdMetadata(SongId.computeSongId('Holly Jolly Christmas', 'Burl Ives', null).songId,
        metadata: [NameValue('christmas', '')]);
    Metadata.clear();
    Metadata.set(md0);
    Metadata.set(md1);
    Metadata.set(md2);
    Metadata.set(md3);
    String original = Metadata.toJson();
    logger.d(original);
    {
      String s = Metadata.toJson();
      Metadata.clear();
      Metadata.fromJson(s);

      logger.i('$original');
      //logger.d('${Metadata.toJson()}');
      expect(Metadata.toJson(), original);
    }
  });

  bool _rockMatch(IdMetadata idMetadata) {
    for (NameValue nameValue in idMetadata.nameValues) {
      if (nameValue.name == 'genre' && nameValue.value == 'rock') return true;
    }
    return false;
  }

  bool _christmasMatch(IdMetadata idMetadata) {
    if (christmasRegExp.hasMatch(idMetadata.id)) {
      return true;
    }
    for (NameValue nameValue in idMetadata.nameValues) {
      if (christmasRegExp.hasMatch(nameValue.name)) return true;
    }
    return false;
  }

  bool _notChristmasMatch(IdMetadata idMetadata) {
    return !_christmasMatch(idMetadata);
  }

  bool _cjRanking(IdMetadata idMetadata, CjRankingEnum ranking) {
    for (NameValue nameValue in idMetadata.nameValues) {
      if (nameValue.name == 'cj') {
        CjRankingEnum r = nameValue.value.toCjRankingEnum();
        if (r != null && r.index >= ranking.index) {
          return true;
        }
      }
    }
    return false;
  }

  bool _cjRankingBest(IdMetadata idMetadata) {
    return _cjRanking(idMetadata, CjRankingEnum.best);
  }

  test('test match', () {
    //  metadata
    Metadata.clear();
    SplayTreeSet<IdMetadata> matches = Metadata.match(_rockMatch);
    expect(matches, isNotNull);
    expect(matches, isEmpty);

    Metadata.set(IdMetadata(SongId.computeSongId('Hey Joe', 'Jimi Hendrix', null).songId,
        metadata: [NameValue('genre', 'rock'), NameValue('cj', 'best')]));
    Metadata.set(IdMetadata(SongId.computeSongId('\'39', 'Queen', null).songId,
        metadata: [NameValue('genre', 'rock'), NameValue('cj', 'ok')]));
    Metadata.set(
        IdMetadata(SongId.computeSongId('Boxer, The', 'Boxer, The', null).songId, metadata: [NameValue('cj', 'best')]));
    Metadata.set(IdMetadata(SongId.computeSongId('Holly Jolly Christmas', 'Burl Ives', null).songId,
        metadata: [NameValue('christmas', '')]));

    matches = Metadata.match(_rockMatch);
    expect(matches, isNotNull);
    expect(matches.length, 2);
    expect(matches.first.id, 'Song_39_by_Queen');

    matches = Metadata.match(_christmasMatch);
    expect(matches, isNotNull);
    expect(matches.length, 1);
    expect(matches.first.id, 'Song_Holly_Jolly_Christmas_by_Burl_Ives');

    matches = Metadata.match(_cjRankingBest);
    expect(matches, isNotNull);
    expect(matches.length, 2);
    expect(matches.first.id, 'Song_Boxer_The_by_Boxer_The');

    matches = Metadata.match(_rockMatch, from: Metadata.match(_christmasMatch));
    expect(matches, isNotNull);
    expect(matches, isEmpty);

    matches =
        Metadata.match(_rockMatch, from: Metadata.match(_cjRankingBest, from: Metadata.match(_notChristmasMatch)));
    expect(matches, isNotNull);
    expect(matches.length, 1);
    expect(matches.first.id, 'Song_Hey_Joe_by_Jimi_Hendrix');
  });
}

final RegExp christmasRegExp = RegExp(r'.*christmas.*', caseSensitive: false);
