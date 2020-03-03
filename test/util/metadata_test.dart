import 'dart:collection';

import 'package:bsteeleMusicLib/util/metadata.dart';
import 'package:test/test.dart';

void main() {
  test('test Metadata', () {
    final String id0 = 'id0';
    {
      expect(IdMetadata(id0, metadata: [NameValue('genre', 'rock')]).toString(),
          '{ "id": "id0", "metadata": [ { "genre": "rock" } ] }');
      expect(IdMetadata(id0, metadata: [NameValue('genre', 'rock'), NameValue('genre', 'rock')]).toString(),
          '{ "id": "id0", "metadata": [ { "genre": "rock" } ] }');

      IdMetadata md = IdMetadata(id0, metadata: [NameValue('genre', 'rock'), NameValue('jam', 'casual')]);
      expect(
          md.toString(),
          '{ "id": "id0", "metadata": [ { "genre": "rock" },\n'
          '\t{ "jam": "casual" } ] }');
      md.remove(NameValue('jam', 'casual'));
      expect(md.toString(), '{ "id": "id0", "metadata": [ { "genre": "rock" } ] }');
      md.add(NameValue('jam', 'casual'));
      expect(
          md.toString(),
          '{ "id": "id0", "metadata": [ { "genre": "rock" },\n'
          '\t{ "jam": "casual" } ] }');
    }

    //  metadata
    IdMetadata md0 = IdMetadata(id0, metadata: [NameValue('genre', 'rock'), NameValue('jam', 'casual')]);
    IdMetadata md1 = IdMetadata('id1', metadata: [NameValue('genre', 'rock'), NameValue('jam', 'advanced')]);
    IdMetadata md2 = IdMetadata('id2', metadata: [NameValue('jam', 'advanced')]);
    IdMetadata md3 = IdMetadata('id3 christmas');

    SplayTreeSet<IdMetadata> set = Metadata.where(idIsLike: id0);
    expect(set.isEmpty, true);

    Metadata.add(md0);
    Metadata.add(md1);
    Metadata.add(md2);
    Metadata.add(md3);
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

    SplayTreeSet<String> names = Metadata.namesOf(set);
    for (String name in names) {
      print('name: $name');
      SplayTreeSet<String> values = Metadata.valuesOf(set, name);
      for (String value in values) {
        print('\tvalue: $value');
      }
    }
  });
}
