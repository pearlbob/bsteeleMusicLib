import 'dart:collection';

import 'package:bsteeleMusicLib/app_logger.dart';
import 'package:bsteeleMusicLib/songs/section.dart';
import 'package:bsteeleMusicLib/songs/section_version.dart';
import 'package:bsteeleMusicLib/util/util.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('parseString', () {
    for (Section section in Section.values) {
      for (int i = 0; i < 10; i++) {
        SectionVersion sectionVersionExpected = SectionVersion.bySection(section);
        SectionVersion sectionVersion;

        sectionVersion = SectionVersion.parseString('$section:');

        expect(sectionVersionExpected, sectionVersion);
        sectionVersion = SectionVersion.parseString('${section.abbreviation}:  ');
        expect(sectionVersionExpected, sectionVersion);
        sectionVersion = SectionVersion.parseString('${section.formalName}: A B C');
        logger.d(sectionVersion.toString());
        expect(sectionVersionExpected, sectionVersion);
        try {
          sectionVersion = SectionVersion.parseString('${section.formalName}asdf');
          fail('bad section name should not pass the test');
        } catch (e) {
          //  expected
        }
      }
    }
  });

  test('parseInContext', () {
    for (Section section in Section.values) {
      logger.i(section.toString());
      for (int i = 0; i < 10; i++) {
        String chords = ' D C G G ';
        MarkedString markedString = MarkedString('$section${i > 0 ? i.toString() : ''}:$chords');
        logger.d(markedString.toString());
        SectionVersion sectionVersion;

        sectionVersion = SectionVersion.parse(markedString);

        expect(chords.trim(), markedString.toString().trim());
        expect(sectionVersion, isNotNull);
        expect(section, sectionVersion.section);
        expect(i, sectionVersion.version);

        chords = chords.trim();
        markedString = MarkedString('$section${i > 0 ? i.toString() : ''}:$chords');
        sectionVersion = SectionVersion.parse(markedString);
        expect(chords, markedString.toString());
        expect(sectionVersion, isNotNull);
        expect(section, sectionVersion.section);
        expect(i, sectionVersion.version);
      }
    }
  });

  test('hashcode', () {
    SectionVersion sectionVersionV = SectionVersion.defaultInstance;
    for (Section section in Section.values) {
      logger.i(section.toString());
      for (int i = 0; i < 10; i++) {
        SectionVersion sectionVersion = SectionVersion(section, i);
        logger.i('section: $section, version: $i');
        expect(
            sectionVersion == sectionVersionV,
            (section != Section.get(SectionEnum.verse) || i != 0) // depends on the default!
                ? isFalse
                : isTrue);
      }
    }
  });

  test('weight', () {
    Map<SectionVersion,int> map = {};
    for (Section section in Section.values) {
      logger.d(section.toString());
      for (int i = 0; i < 10; i++) {
        SectionVersion sectionVersion = SectionVersion(section, i);
        logger.d('$sectionVersion $i, weight: ${sectionVersion.weight}');
        map[sectionVersion]=sectionVersion.weight;
      }
    }
    SplayTreeSet<int> set = SplayTreeSet.from(map.values);
    for ( int i in set ){
      logger.i('$i:');
      for ( SectionVersion sectionVersion in map.keys){
        if ( sectionVersion.weight == i ){
          logger.i('   $sectionVersion');
        }
      }
    }
  });
}
