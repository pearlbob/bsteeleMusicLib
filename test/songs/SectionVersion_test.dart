import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/Section.dart';
import 'package:bsteeleMusicLib/songs/SectionVersion.dart';
import 'package:bsteeleMusicLib/util/util.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test("parseString", () {
    for (Section section in Section.values)
      for (int i = 0; i < 10; i++) {
        SectionVersion sectionVersionExpected =
            SectionVersion.bySection(section);
        SectionVersion sectionVersion;

        sectionVersion = SectionVersion.parseString(section.toString() + ":");

        expect(sectionVersionExpected, sectionVersion);
        sectionVersion =
            SectionVersion.parseString(section.abbreviation.toString() + ":  ");
        expect(sectionVersionExpected, sectionVersion);
        sectionVersion =
            SectionVersion.parseString(section.formalName + ": A B C");
        logger.d(sectionVersion.toString());
        expect(sectionVersionExpected, sectionVersion);
        try {
          sectionVersion =
              SectionVersion.parseString(section.formalName + "asdf");
          fail("bad section name should not pass the test");
        } catch (e) {
          //  expected
        }
      }
  });

  test("parseInContext", () {
    for (Section section in Section.values) {
      logger.i(section.toString());
      for (int i = 0; i < 10; i++) {
        String chords = " D C G G ";
        MarkedString markedString = new MarkedString(
            section.toString() + (i > 0 ? i.toString() : "") + ":" + chords);
        logger.d(markedString.toString());
        SectionVersion sectionVersion;

        sectionVersion = SectionVersion.parse(markedString);

        expect(chords.trim(), markedString.toString().trim());
        expect(sectionVersion, isNotNull);
        expect(section, sectionVersion.section);
        expect(i, sectionVersion.version);

        chords = chords.trim();
        markedString = new MarkedString(
            section.toString() + (i > 0 ? i.toString() : "") + ":" + chords);
        sectionVersion = SectionVersion.parse(markedString);
        expect(chords, markedString.toString());
        expect(sectionVersion, isNotNull);
        expect(section, sectionVersion.section);
        expect(i, sectionVersion.version);
      }
    }
  });
}
