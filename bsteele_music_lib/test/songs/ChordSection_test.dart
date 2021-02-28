import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/chordSection.dart';
import 'package:bsteeleMusicLib/songs/measure.dart';
import 'package:bsteeleMusicLib/songs/measureComment.dart';
import 'package:bsteeleMusicLib/songs/phrase.dart';
import 'package:bsteeleMusicLib/songs/section.dart';
import 'package:bsteeleMusicLib/songs/sectionVersion.dart';
import 'package:bsteeleMusicLib/songs/scaleNote.dart';
import 'package:bsteeleMusicLib/util/util.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void checkMeasureNodesScaleNoteByMeasure(ScaleNote scaleNote, List<Measure> measures, int measureN, int chordN) {
  expect(scaleNote, measures[measureN].chords[chordN].scaleChord.scaleNote);
}

void checkMeasureNodesSlashScaleNoteByMeasure(ScaleNote? scaleNote, List<Measure> measures, int measureN, int chordN) {
  ScaleNote? slashScaleNote = measures[measureN].chords[chordN].slashScaleNote;
  if (slashScaleNote == null) {
    expect(scaleNote, isNull);
  } else {
    expect(scaleNote, slashScaleNote);
  }
}

void main() {
  Logger.level = Level.info;

  List<Phrase> phrases;
  Phrase phrase;
  List<Measure> measures;
  final int beatsPerBar = 4;

  test('testChordSectionparseString', () {
    {
      //  repeat row
      ChordSection chordSection = ChordSection.parseString(
          ' V:'
          'AE DA AE DA x4'
          'C:'
          'AE DA AE DA x2',
          beatsPerBar);
      expect(chordSection, isNotNull);
      logger.d(chordSection.toMarkup());
      expect(
        chordSection.toMarkup(),
        'V: [AE DA AE DA ] x4 ',
      );
    }
    {
      //  repeat row
      ChordSection chordSection = ChordSection.parseString(
          ' I4:, G D Em7 Cadd9, G D Em7 Cadd9, '
          'V:, G C Am7 D7sus, G/B Em Am7 Dsus, G C Am7 D7sus, G/B Em Am7 D,',
          beatsPerBar);
      expect(chordSection, isNotNull);
      logger.d(chordSection.toMarkup());
      expect(
        chordSection.toMarkup(),
        'I4: G D Em7 Cadd9, G D Em7 Cadd9, ',
      );
    }

    {
      //  repeat row
      ChordSection chordSection = ChordSection.parseString('I4:, G D Em7 Cadd9, G D Em7 Cadd9, ', beatsPerBar);
      expect(chordSection, isNotNull);
      logger.d(chordSection.toMarkup());
      expect(
        chordSection.toMarkup(),
        'I4: G D Em7 Cadd9, G D Em7 Cadd9, ',
      );
    }

    {
      //  - at end of repeat
      ChordSection chordSection = ChordSection.parseString('V: [D G D - ] x3', beatsPerBar);
      expect(chordSection, isNotNull);
      logger.d(chordSection.toMarkup());
      expect('V: [D G D D ] x3 ', chordSection.toMarkup());
    }
    {
      //  - at end of repeat
      ChordSection chordSection = ChordSection.parseString('V: D G D - [D G D - ] x3 C A C A  C..A D - ', beatsPerBar);
      expect(chordSection, isNotNull);
      logger.d(chordSection.toMarkup());
      expect('V: D G D D [D G D D ] x3 C A C A C..A D D ', chordSection.toMarkup());
    }
    {
      //  - at end of repeat
      ChordSection chordSection = ChordSection.parseString(
          'V:\n'
          'D G D - \n'
          'D G D -  x3\n'
          'C A C A\n'
          'C..A D -\n',
          beatsPerBar);
      expect(chordSection, isNotNull);
      logger.d(chordSection.toMarkup());
      expect('V: D G D D, [D G D D ] x3 C A C A, C..A D D, ', chordSection.toMarkup());
    }
    {
      //  comment only
      ChordSection chordSection = ChordSection.parseString('V: (comment) A C#m F#m F#m/E\n', 4);
      expect(chordSection, isNotNull);
      Measure m = chordSection.phrases[0].measures[0];
      assert(m.isSingleItem());
      assert(m.isComment());
      expect('(comment)', m.toString());
      m = chordSection.phrases[0].measures[1];
      expect(Measure.parseString('A', 4), m);
    }
    {
      //  lost : ?
      ChordSection chordSection = ChordSection.parseString(
          'V: \n'
          'A C#m F#m F#m/E\n'
          'G Bm F#m G GBm  x3\n'
          'A C#m F#m F#m/E\n'
          'G G Bm Bm\n',
          4);
      expect(chordSection, isNotNull);
      Measure m = chordSection.phrases[0].measures[0];
      assert(m is Measure);
    }
    try {
      //  invented garbage is comment, verse is presumed
      ChordSection chordSection = ChordSection.parseString('ia: EDCBA (single notes rapid)', 4);
      logger.i(chordSection.toMarkup());
      expect('V: (ia:) EDCBA (single notes rapid)', chordSection.toMarkup().trim());
    } catch (e) {
      fail('parse error on comment parse');
    }
    {
      ChordSection chordSection = ChordSection.parseString(
          'v:Am Am Am AmDm\n'
          'Dm Dm Dm DmAm 2x\n' //  bad repeat marker
          '\n',
          beatsPerBar);
      expect(chordSection, isNotNull);
      logger.d(chordSection.toMarkup());
      measures = chordSection.phrases[0].measures;
      expect(measures, isNotNull);
      expect(measures, isNotEmpty);
      expect(measures.length, 8);
      Measure m = measures[3];
      Measure mExpected = Measure.parseString('AmDm', beatsPerBar);
      mExpected.endOfRow = true;
      expect(m, mExpected);
      m = measures[measures.length - 1];
      expect(Measure.parseString('DmAm', beatsPerBar), m);
      measures = chordSection.phrases[1].measures;
      m = measures[0];
      assert(m is MeasureComment);
    }
    {
      //  infinite loop?
      ChordSection chordSection = ChordSection.parseString('o:AGEDCAGEDCAGA (organ descending scale)', 4);
      SectionVersion outro = SectionVersion.bySection(Section.get(SectionEnum.outro));
      expect(chordSection.sectionVersion == outro, isTrue);
    }

    {
      //  failure to parseString a leading dot
      ChordSection chordSection = ChordSection.parseString('I: G .G Bm Bm  x2', 4);
      //  error will be thrown: expect(chordSection != null, isTrue);
      logger.d(chordSection.toMarkup());
      SectionVersion intro = SectionVersion.bySection(Section.get(SectionEnum.intro));
      expect(chordSection.sectionVersion == intro, isTrue);
      phrases = chordSection.phrases;
      expect(3, phrases.length);
      measures = phrases[1].measures;
      expect(1, measures.length);
      expect('(.G)', measures[0].toString());
    }
    {
      ChordSection chordSection = ChordSection.parseString(
          'I: A B C D\n'
          'AbBb/G# Am7 Ebsus4 C7/Bb',
          4);
      SectionVersion intro = SectionVersion.bySection(Section.get(SectionEnum.intro));
      expect(chordSection.sectionVersion, intro);
      phrases = chordSection.phrases;
      expect(1, phrases.length);

      measures = phrases[0].measures;
      expect(measures, isNotNull);
      expect(8, measures.length);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.A), measures, 0, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.B), measures, 1, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.C), measures, 2, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.D), measures, 3, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.Ab), measures, 4, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.Bb), measures, 4, 1);
      checkMeasureNodesSlashScaleNoteByMeasure(null, measures, 4, 0);
      checkMeasureNodesSlashScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.Gs), measures, 4, 1);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.A), measures, 5, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.Eb), measures, 6, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.C), measures, 7, 0);
    }
    {
      ChordSection chordSection = ChordSection.parseString(
          'I: A - - -\n'
          'Ab - - G ',
          4);
      logger.d(chordSection.toMarkup());
      SectionVersion intro = SectionVersion.bySection(Section.get(SectionEnum.intro));
      expect(chordSection.sectionVersion, intro);
      phrases = chordSection.phrases;
      expect(phrases, isNotNull);
      expect(1, phrases.length);
      measures = phrases[0].measures;
      expect(8, measures.length);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.A), measures, 0, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.A), measures, 1, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.A), measures, 2, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.A), measures, 3, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.Ab), measures, 4, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.Ab), measures, 5, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.Ab), measures, 6, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.G), measures, 7, 0);
    }
    {
      ChordSection chordSection = ChordSection.parseString(
          'I: A - - -\n'
          'Ab - - X ',
          4);
      SectionVersion intro = SectionVersion.bySection(Section.get(SectionEnum.intro));
      expect(chordSection.sectionVersion, intro);
      phrases = chordSection.phrases;
      expect(1, phrases.length);

      measures = phrases[0].measures;
      expect(measures, isNotNull);
      expect(8, measures.length);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.A), measures, 0, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.A), measures, 1, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.A), measures, 2, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.A), measures, 3, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.Ab), measures, 4, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.Ab), measures, 5, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.Ab), measures, 6, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.X), measures, 7, 0);

      Measure measure = measures[3];
      expect(1, measure.chords.length);
      expect(4, measure.beatCount);
    }
    {
      ChordSection chordSection = ChordSection.parseString('I: A B C D\n' 'AbBb/G# Am7 Ebsus4 C7/Bb x4', 4);
      logger.d(chordSection.toMarkup());
      SectionVersion intro = SectionVersion.bySection(Section.get(SectionEnum.intro));
      expect(chordSection.sectionVersion, intro);
      phrases = chordSection.phrases;
      expect(2, phrases.length);
      measures = phrases[0].measures;
      expect(4, measures.length);

      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.A), measures, 0, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.B), measures, 1, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.C), measures, 2, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.D), measures, 3, 0);

      phrase = chordSection.phrases[1]; //    the repeat
      expect(16, phrase.getTotalMoments());
      measures = phrase.measures;
      expect(4, measures.length);

      expect(4, measures.length);
      expect(2, measures[0].chords.length);
      expect(ScaleNote.get(ScaleNoteEnum.Ab), measures[0].chords[0].scaleChord.scaleNote);
      expect(ScaleNote.get(ScaleNoteEnum.Bb), measures[0].chords[1].scaleChord.scaleNote);
      expect(ScaleNote.get(ScaleNoteEnum.A), measures[1].chords[0].scaleChord.scaleNote);
      expect(ScaleNote.get(ScaleNoteEnum.Eb), measures[2].chords[0].scaleChord.scaleNote);
      expect(ScaleNote.get(ScaleNoteEnum.C), measures[3].chords[0].scaleChord.scaleNote);
      expect(4 + 4 * 4, chordSection.getTotalMoments());
    }
    {
      ChordSection chordSection = ChordSection.parseString(
          'V:\n'
          '            Am Bm7 Em Dsus2 x4\n'
          'T:\n' //  note: tag should be ignored on a single chord section parseString
          'D C AG D\n',
          4);
      SectionVersion verse = SectionVersion.bySection(Section.get(SectionEnum.verse));
      expect(chordSection.sectionVersion, verse);
      phrases = chordSection.phrases;
      phrase = phrases[0];
      measures = phrase.measures;
      expect(4, measures.length);

      expect(4 * 4, phrase.getTotalMoments());
      measures = phrases[0].measures;
      expect(4, measures.length);
      expect(ScaleNote.get(ScaleNoteEnum.A), measures[0].chords[0].scaleChord.scaleNote);
      expect(ScaleNote.get(ScaleNoteEnum.B), measures[1].chords[0].scaleChord.scaleNote);
      expect(ScaleNote.get(ScaleNoteEnum.E), measures[2].chords[0].scaleChord.scaleNote);
      expect(ScaleNote.get(ScaleNoteEnum.D), measures[3].chords[0].scaleChord.scaleNote);
    }
    {
      MarkedString markedString = MarkedString('\nT:D\n');
      ChordSection chordSection = ChordSection.parse(markedString, 4, false);
      expect(markedString, isEmpty);
      logger.i(chordSection.toString());
      expect(chordSection.isEmpty(), isFalse);
      expect(chordSection.sectionVersion, SectionVersion.bySection(Section.get(SectionEnum.tag)));
    }
    {
      MarkedString markedString = MarkedString('\nT:\n'
          'D C AG D\n');
      ChordSection chordSection = ChordSection.parse(markedString, 4, false);
      expect(markedString, isEmpty);
      expect(chordSection, isNotNull);
      SectionVersion sectionVersion = SectionVersion.bySection(Section.get(SectionEnum.tag));
      expect(chordSection.sectionVersion, sectionVersion);
      phrases = chordSection.phrases;
      expect(1, phrases.length);
      phrase = phrases[0];
      expect(4, phrase.getTotalMoments());
      measures = phrase.measures;
      expect(4, measures.length);

      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.D), measures, 0, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.C), measures, 1, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.A), measures, 2, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.get(ScaleNoteEnum.D), measures, 3, 0);
    }
    {
      ChordSection chordSection = ChordSection.parseString('I:       A B C D\n\n', 4);
      expect(4, chordSection.getTotalMoments());
      chordSection = ChordSection.parseString('\n\tI:\n       A B C D\n\n', 4);
      expect(4, chordSection.getTotalMoments());
      chordSection = ChordSection.parseString('v: A B C D\n'
          'AbBb/G# Am7 Ebsus4 C7/Bb\n', 4);
      expect(8, chordSection.getTotalMoments());
      chordSection = ChordSection.parseString('v: A B C D\n'
          'AbBb/G# Am7 Ebsus4 C7/Bb x4\n', 4);
      expect(4 + 4 * 4, chordSection.getTotalMoments());
      chordSection = ChordSection.parseString('v: \n'
          'AbBb/G# Am7 Ebsus4 C7/Bb x4\n', 4);
      expect(4 * 4, chordSection.getTotalMoments());
      chordSection = ChordSection.parseString('v: A B C D\n\n'
          'AbBb/G# Am7 Ebsus4 C7/Bb x4\n', 4);
      expect(4 + 4 * 4, chordSection.getTotalMoments());
      chordSection = ChordSection.parseString('v: A B C D\n\n'
          'AbBb/G# Am7 Ebsus4 C7/Bb x4\n'
           'G F F# E', 4);
      expect(4 + 4 * 4 + 4, chordSection.getTotalMoments());
    }
  });

  test('test empty chord sections', () {
    {
      ChordSection chordSection1 = ChordSection.parseString('I:       A B C D\n\n', 4);
      ChordSection chordSection2 = ChordSection.parseString('I:       A B C D\n\n', 4);
      expect( chordSection1 == chordSection1, isTrue);
      expect( chordSection1 == chordSection2, isTrue);

      chordSection2 = ChordSection.parseString('I:A B C D\n', 4);
      expect( chordSection1 == chordSection2, isTrue);
      chordSection2 = ChordSection.parseString('I:', 4);
      expect( chordSection1 == chordSection2, isFalse);
      chordSection1 = ChordSection.parseString('I:', 4);
     expect( chordSection1 == chordSection2, isTrue);
      chordSection2 = ChordSection.parseString('I:[]', 4);
      logger.d('chordSection1: "${chordSection1.toMarkup()}"');
      logger.d('chordSection2: "${chordSection2.toMarkup()}"');
      expect( chordSection1 == chordSection2, isTrue);
    }});
}
