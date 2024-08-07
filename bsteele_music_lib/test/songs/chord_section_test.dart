import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/grid.dart';
import 'package:bsteele_music_lib/songs/chord_section.dart';
import 'package:bsteele_music_lib/songs/key.dart';
import 'package:bsteele_music_lib/songs/measure.dart';
import 'package:bsteele_music_lib/songs/measure_node.dart';
import 'package:bsteele_music_lib/songs/phrase.dart';
import 'package:bsteele_music_lib/songs/scale_note.dart';
import 'package:bsteele_music_lib/songs/section.dart';
import 'package:bsteele_music_lib/songs/section_version.dart';
import 'package:bsteele_music_lib/util/util.dart';
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
  const int beatsPerBar = 4;

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
        'I4: G D Em7 Cadd9, G D Em7 Cadd9 ',
      );
    }

    {
      //  repeat row
      ChordSection chordSection = ChordSection.parseString('I4:, G D Em7 Cadd9, G D Em7 Cadd9, ', beatsPerBar);
      expect(chordSection, isNotNull);
      logger.d(chordSection.toMarkup());
      expect(
        chordSection.toMarkup(),
        'I4: G D Em7 Cadd9, G D Em7 Cadd9 ',
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
      expect(chordSection.toMarkup(), 'V: D G D D [D G D D ] x3 C A C A, C..A D D ');
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
      assert(m.toMarkup() == 'A');
    }
    try {
      //  invented garbage is comment, verse is presumed
      ChordSection chordSection = ChordSection.parseString('ia: EDCB (single notes rapid)', 4);
      logger.i(chordSection.toMarkup());
      expect('V: (ia:) EDCB (single notes rapid)', chordSection.toMarkup().trim());
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
      expect(measures.length, 4);
      Measure m = measures[3];
      Measure mExpected = Measure.parseString('AmDm', beatsPerBar);
      mExpected.endOfRow = false;
      expect(m, mExpected);
      m = measures[measures.length - 1];
      expect(Measure.parseString('AmDm', beatsPerBar), m);
      measures = chordSection.phrases[1].measures;
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
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.A, measures, 0, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.B, measures, 1, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.C, measures, 2, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.D, measures, 3, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.Ab, measures, 4, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.Bb, measures, 4, 1);
      checkMeasureNodesSlashScaleNoteByMeasure(null, measures, 4, 0);
      checkMeasureNodesSlashScaleNoteByMeasure(ScaleNote.Gs, measures, 4, 1);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.A, measures, 5, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.Eb, measures, 6, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.C, measures, 7, 0);
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
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.A, measures, 0, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.A, measures, 1, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.A, measures, 2, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.A, measures, 3, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.Ab, measures, 4, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.Ab, measures, 5, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.Ab, measures, 6, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.G, measures, 7, 0);
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
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.A, measures, 0, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.A, measures, 1, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.A, measures, 2, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.A, measures, 3, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.Ab, measures, 4, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.Ab, measures, 5, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.Ab, measures, 6, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.X, measures, 7, 0);

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

      checkMeasureNodesScaleNoteByMeasure(ScaleNote.A, measures, 0, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.B, measures, 1, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.C, measures, 2, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.D, measures, 3, 0);

      phrase = chordSection.phrases[1]; //    the repeat
      expect(16, phrase.getTotalMoments());
      measures = phrase.measures;
      expect(4, measures.length);

      expect(4, measures.length);
      expect(2, measures[0].chords.length);
      expect(ScaleNote.Ab, measures[0].chords[0].scaleChord.scaleNote);
      expect(ScaleNote.Bb, measures[0].chords[1].scaleChord.scaleNote);
      expect(ScaleNote.A, measures[1].chords[0].scaleChord.scaleNote);
      expect(ScaleNote.Eb, measures[2].chords[0].scaleChord.scaleNote);
      expect(ScaleNote.C, measures[3].chords[0].scaleChord.scaleNote);
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
      expect(ScaleNote.A, measures[0].chords[0].scaleChord.scaleNote);
      expect(ScaleNote.B, measures[1].chords[0].scaleChord.scaleNote);
      expect(ScaleNote.E, measures[2].chords[0].scaleChord.scaleNote);
      expect(ScaleNote.D, measures[3].chords[0].scaleChord.scaleNote);
    }
    {
      MarkedString markedString = MarkedString('\nT:D\n');
      ChordSection chordSection = ChordSection.parse(markedString, 4, false);
      expect(markedString, isEmpty);
      logger.i(chordSection.toString());
      expect(chordSection.isEmpty, isFalse);
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

      checkMeasureNodesScaleNoteByMeasure(ScaleNote.D, measures, 0, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.C, measures, 1, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.A, measures, 2, 0);
      checkMeasureNodesScaleNoteByMeasure(ScaleNote.D, measures, 3, 0);
    }
    {
      ChordSection chordSection = ChordSection.parseString('I:       A B C D\n\n', 4);
      expect(4, chordSection.getTotalMoments());
      chordSection = ChordSection.parseString('\n\tI:\n       A B C D\n\n', 4);
      expect(4, chordSection.getTotalMoments());
      chordSection = ChordSection.parseString(
          'v: A B C D\n'
          'AbBb/G# Am7 Ebsus4 C7/Bb\n',
          4);
      expect(8, chordSection.getTotalMoments());
      chordSection = ChordSection.parseString(
          'v: A B C D\n'
          'AbBb/G# Am7 Ebsus4 C7/Bb x4\n',
          4);
      expect(4 + 4 * 4, chordSection.getTotalMoments());
      chordSection = ChordSection.parseString(
          'v: \n'
          'AbBb/G# Am7 Ebsus4 C7/Bb x4\n',
          4);
      expect(4 * 4, chordSection.getTotalMoments());
      chordSection = ChordSection.parseString(
          'v: A B C D\n\n'
          'AbBb/G# Am7 Ebsus4 C7/Bb x4\n',
          4);
      expect(4 + 4 * 4, chordSection.getTotalMoments());
      chordSection = ChordSection.parseString(
          'v: A B C D\n\n'
          'AbBb/G# Am7 Ebsus4 C7/Bb x4\n'
          'G F F# E',
          4);
      expect(4 + 4 * 4 + 4, chordSection.getTotalMoments());
    }
  });

  test('test empty chord sections', () {
    {
      ChordSection chordSection1 = ChordSection.parseString('I:       A B C D\n\n', 4);
      ChordSection chordSection2 = ChordSection.parseString('I:       A B C D\n\n', 4);
      expect(chordSection1 == chordSection1, isTrue);
      expect(chordSection1 == chordSection2, isTrue);

      chordSection2 = ChordSection.parseString('I:A B C D\n', 4);
      expect(chordSection1 == chordSection2, isTrue);
      chordSection2 = ChordSection.parseString('I:', 4);
      expect(chordSection1 == chordSection2, isFalse);
      chordSection1 = ChordSection.parseString('I:', 4);
      expect(chordSection1 == chordSection2, isTrue);
      chordSection2 = ChordSection.parseString('I:[]', 4);
      logger.d('chordSection1: "${chordSection1.toMarkup()}"');
      logger.d('chordSection2: "${chordSection2.toMarkup()}"');
      expect(chordSection1 == chordSection2, isTrue);
    }
  });

  test('test ChordSection measureAt', () {
    {
      const beatsPerBar = 4;
      ChordSection chordSection =
          ChordSection.parseString('I:       A B C D\n[Ab Bb\n Db Eb ]x2\nE F G\n', beatsPerBar);
      expect(chordSection.measureAt(0), Measure.parseString('A', beatsPerBar));
      expect(chordSection.measureAt(1), Measure.parseString('B', beatsPerBar));
      expect(chordSection.measureAt(2), Measure.parseString('C', beatsPerBar));
      expect(chordSection.measureAt(3), Measure.parseString('D', beatsPerBar));
      expect(chordSection.measureAt(7), Measure.parseString('Eb', beatsPerBar));
      expect(chordSection.measureAt(10), Measure.parseString('Db', beatsPerBar));
      expect(chordSection.measureAt(14), Measure.parseString('G', beatsPerBar));
      expect(chordSection.measureAt(15), null);
      expect(chordSection.measureAt(-3), null);

      expect(chordSection.measureAt(0), Measure.parseString('A', beatsPerBar));
      expect(chordSection.measureAt(1), Measure.parseString('B', beatsPerBar));
      expect(chordSection.measureAt(2), Measure.parseString('C', beatsPerBar));
      expect(chordSection.measureAt(3), Measure.parseString('D', beatsPerBar));
      expect(chordSection.measureAt(4), Measure.parseString('Ab', beatsPerBar));
      expect(chordSection.measureAt(5), Measure.parseString('Bb,', beatsPerBar));
      expect(chordSection.measureAt(7), Measure.parseString('Eb', beatsPerBar));
      expect(chordSection.measureAt(10), Measure.parseString('Db', beatsPerBar));
      expect(chordSection.measureAt(11), Measure.parseString('Eb', beatsPerBar));
      expect(chordSection.measureAt(12), Measure.parseString('E', beatsPerBar));
      expect(chordSection.measureAt(14), Measure.parseString('G', beatsPerBar));
      expect(chordSection.measureAt(15), null);
    }
  });

  test('test ChordSection rowAt for editing', () {
    {
      Logger.level = Level.info;

      const beatsPerBar = 4;
      ChordSection chordSection = ChordSection.parseString(
          'I:'
          '       A B C D\n'
          '[Ab Bb\n Db Eb ]x2\n'
          '[  D C G G  ]x3\n'
          'C G E E x3\n'
          '[A\n B\n D\n E\n ]x3\n'
          'A G F E x3\n'
          'E F G\n',
          beatsPerBar);

      logger.i(chordSection.toString());

      if (Logger.level.index <= Level.debug.index) {
        //  generate tests:
        for (var i = 0; i < 100; i++) {
          var row = chordSection.rowAt(i);
          if (row.isEmpty) {
            break;
          }
          logger.i('expect(chordSection.rowAt($i).toString(), \'$row\');');
        }
      }

      expect(chordSection.chordRowMaxLength(), 5);

      expect(chordSection.phraseRowCount, 11);
      expect(chordSection.repeatRowCount, 27);

      //  generated from above
      expect(chordSection.rowAt(0).toString(), '[A, B, C, D]');
      expect(chordSection.rowAt(1).toString(), '[Ab, Bb,, ⎤]');
      expect(chordSection.rowAt(2).toString(), '[Db, Eb, ⎦, x1/2]');
      expect(chordSection.rowAt(3).toString(), '[Ab, Bb,, ⎤]');
      expect(chordSection.rowAt(4).toString(), '[Db, Eb, ⎦, x2/2]');
      expect(chordSection.rowAt(5).toString(), '[D, C, G, G, x1/3]');
      expect(chordSection.rowAt(6).toString(), '[D, C, G, G, x2/3]');
      expect(chordSection.rowAt(7).toString(), '[D, C, G, G, x3/3]');
      expect(chordSection.rowAt(8).toString(), '[C, G, E, E, x1/3]');
      expect(chordSection.rowAt(9).toString(), '[C, G, E, E, x2/3]');
      expect(chordSection.rowAt(10).toString(), '[C, G, E, E, x3/3]');
      expect(chordSection.rowAt(11).toString(), '[A,, ⎤]');
      expect(chordSection.rowAt(12).toString(), '[B,, ⎥]');
      expect(chordSection.rowAt(13).toString(), '[D,, ⎥]');
      expect(chordSection.rowAt(14).toString(), '[E, ⎦, x1/3]');
      expect(chordSection.rowAt(15).toString(), '[A,, ⎤]');
      expect(chordSection.rowAt(16).toString(), '[B,, ⎥]');
      expect(chordSection.rowAt(17).toString(), '[D,, ⎥]');
      expect(chordSection.rowAt(18).toString(), '[E, ⎦, x2/3]');
      expect(chordSection.rowAt(19).toString(), '[A,, ⎤]');
      expect(chordSection.rowAt(20).toString(), '[B,, ⎥]');
      expect(chordSection.rowAt(21).toString(), '[D,, ⎥]');
      expect(chordSection.rowAt(22).toString(), '[E, ⎦, x3/3]');
      expect(chordSection.rowAt(23).toString(), '[A, G, F, E, x1/3]');
      expect(chordSection.rowAt(24).toString(), '[A, G, F, E, x2/3]');
      expect(chordSection.rowAt(25).toString(), '[A, G, F, E, x3/3]');
      expect(chordSection.rowAt(26).toString(), '[E, F, G]');
    }
  });

  test('test ChordSection chordRowMaxLength', () {
    {
      ChordSection chordSection;

      chordSection = ChordSection.parseString(
          'I:'
          'A B C D E F G G#\n'
          'A B C D \n'
          'A B \n',
          beatsPerBar);
      expect(chordSection.chordRowMaxLength(), 8);
      chordSection = ChordSection.parseString(
          'I:'
          'A B \n'
          'A B C D \n'
          'A B C D E F G G#\n',
          beatsPerBar);
      expect(chordSection.chordRowMaxLength(), 8);
      chordSection = ChordSection.parseString(
          'I:'
          'A B \n'
          'A B C D \n'
          'A B C D E F G G# x2\n',
          beatsPerBar);
      expect(chordSection.chordRowMaxLength(), 9);
      chordSection = ChordSection.parseString(
          'I:'
          'A B \n'
          'A B C D \n'
          '[A B C D, E F G G#] x2\n',
          beatsPerBar);
      expect(chordSection.chordRowMaxLength(), 6);
      chordSection = ChordSection.parseString(
          'I:'
          'A B \n'
          'A B C D \n'
          'A B C D E F G G# A# Bb x2\n',
          beatsPerBar);
      expect(chordSection.chordRowMaxLength(), 6); //  last row forced to max 4 per row
      chordSection = ChordSection.parseString(
          'I:'
          'A B \n'
          'A B C D \n'
          'A B C D, E F G G#, A# Bb x2\n', //  x2 repeats only two measures here
          beatsPerBar);
      expect(chordSection.chordRowMaxLength(), 4);
      chordSection = ChordSection.parseString(
          'I:'
          'A B \n'
          'A B C D \n'
          '[A B C D, E F G G#, A# Bb ]x2\n',
          beatsPerBar);
      expect(chordSection.chordRowMaxLength(), 6);
    }
  });

  test('test ChordSection toGrid()', () {
    ChordSection chordSection;
    Grid<MeasureNode> grid;

    chordSection = ChordSection.parseString(
        'I:'
        'A B,'
        'A B C D',
        beatsPerBar);
    grid = chordSection.toGrid();
    expect(grid.getRowCount(), 3);
    expect(grid.rowLength(0), 4);
    expect(grid.rowLength(1), 4);
    expect(grid.rowLength(2), 4);

    chordSection = ChordSection.parseString(
        'I:'
        'A B \n'
        'A B C D \n'
        'A B C D E F G G# x2\n',
        beatsPerBar);
    grid = chordSection.toGrid();
    expect(grid.getRowCount(), 5);
    expect(grid.rowLength(0), 9);
    expect(grid.rowLength(1), 9);
    expect(grid.rowLength(2), 9);
    expect(grid.rowLength(3), 9);

    chordSection = ChordSection.parseString(
        'I:'
        'A B C D E F G G#\n'
        'A B C D \n'
        'A B \n',
        beatsPerBar);
    grid = chordSection.toGrid();
    expect(grid.getRowCount(), 4);
    expect(grid.rowLength(1), 8);

    chordSection = ChordSection.parseString(
        'I:'
        'A B \n'
        'A B C D \n'
        'A B C D, E F G G# x2\n',
        beatsPerBar);
    grid = chordSection.toGrid();
    expect(grid.getRowCount(), 1 + 3 + 2);
    for (var r = 0; r < 5; r++) {
      expect(grid.rowLength(r), 5);
    }

    chordSection = ChordSection.parseString(
        'I:'
        'A B \n'
        'A B C D \n'
        '[A B C D, E F G G#] x2\n',
        beatsPerBar);
    grid = chordSection.toGrid();
    expect(grid.getRowCount(), 1 + 2 + 2 * 2);
    for (var r = 0; r < 5; r++) {
      expect(grid.rowLength(r), 6);
    }
  });

  test('test ChordSection toMarkupInRows()', () {
    Logger.level = Level.debug;
    ChordSection chordSection;

    chordSection = ChordSection.parseString('I: A B C D, D C G G', beatsPerBar);

    expect(chordSection.toMarkupInRows(0), 'I: A B C D, D C G G\n');
    expect(chordSection.toMarkupInRows(1), 'I: A B C D, D C G G\n');
    expect(
        chordSection.toMarkupInRows(2),
        'I:\n'
        ' A B C D, D C G G\n');
    expect(
        chordSection.toMarkupInRows(3),
        'I:\n'
        ' A B C D\n'
        ' D C G G\n');
    expect(
        chordSection.toMarkupInRows(4),
        'I:\n'
        ' A B C D\n\n'
        ' D C G G\n');
    expect(
        chordSection.toMarkupInRows(5),
        'I:\n'
        ' A B C D\n\n'
        ' D C G G\n\n');
    expect(
        chordSection.toMarkupInRows(5),
        'I:\n'
        ' A B C D\n\n'
        ' D C G G\n\n');
    expect(
        chordSection.toMarkupInRows(5),
        'I:\n'
        ' A B C D\n\n'
        ' D C G G\n\n');
    expect(
        chordSection.toMarkupInRows(6),
        'I:\n'
        ' A B C D\n\n\n'
        ' D C G G\n\n');
    expect(
        chordSection.toMarkupInRows(7),
        'I:\n'
        ' A B C D\n\n\n'
        ' D C G G\n\n\n');
    expect(
        chordSection.toMarkupInRows(8),
        'I:\n'
        ' A B C D\n\n\n\n'
        ' D C G G\n\n\n');

    chordSection = ChordSection.parseString(
        'I:'
        'A B,'
        'A B C D '
        '[A B C D, E F G G#, A# Bb ]x2',
        beatsPerBar);

    expect(
        chordSection.toMarkupInRows(0),
        'I: A B, A B C D [A B C D, E F G G#, A# Bb] x1/2'
        ' [A B C D, E F G G#, A# Bb] x2/2\n');
    expect(
        chordSection.toMarkupInRows(1),
        'I: A B, A B C D [A B C D, E F G G#, A# Bb] x1/2'
        ' [A B C D, E F G G#, A# Bb] x2/2\n');
    expect(
        chordSection.toMarkupInRows(2),
        'I:\n'
        ' A B, A B C D [A B C D, E F G G#, A# Bb] x1/2 [A B C D, E F G G#, A# Bb] x2/2\n');
    expect(
        chordSection.toMarkupInRows(3),
        'I:\n'
        ' A B\n'
        ' A B C D [A B C D, E F G G#, A# Bb] x1/2 [A B C D, E F G G#, A# Bb] x2/2\n');
    expect(
        chordSection.toMarkupInRows(4),
        'I:\n'
        ' A B\n'
        ' A B C D\n'
        '[A B C D, E F G G#, A# Bb] x1/2 [A B C D, E F G G#, A# Bb] x2/2\n');
    expect(
        chordSection.toMarkupInRows(5),
        'I:\n'
        ' A B\n'
        ' A B C D\n'
        '[A B C D\n'
        ' E F G G#, A# Bb] x1/2 [A B C D, E F G G#, A# Bb] x2/2\n');
    expect(
        chordSection.toMarkupInRows(6),
        'I:\n'
        ' A B\n'
        ' A B C D\n'
        '[A B C D\n'
        ' E F G G#\n'
        ' A# Bb] x1/2 [A B C D, E F G G#, A# Bb] x2/2\n');
    expect(
        chordSection.toMarkupInRows(7),
        'I:\n'
        ' A B\n'
        ' A B C D\n'
        '[A B C D\n'
        ' E F G G#\n'
        ' A# Bb] x1/2\n'
        '[A B C D, E F G G#, A# Bb] x2/2\n');
    expect(
        chordSection.toMarkupInRows(8),
        'I:\n'
        ' A B\n'
        ' A B C D\n'
        '[A B C D\n'
        ' E F G G#\n'
        ' A# Bb] x1/2\n'
        '[A B C D\n'
        ' E F G G#, A# Bb] x2/2\n');
    expect(
        chordSection.toMarkupInRows(9),
        'I:\n'
        ' A B\n'
        ' A B C D\n'
        '[A B C D\n'
        ' E F G G#\n'
        ' A# Bb] x1/2\n'
        '[A B C D\n'
        ' E F G G#\n A# Bb] x2/2\n');
    expect(
        chordSection.toMarkupInRows(10),
        'I:\n'
        ' A B\n\n'
        ' A B C D\n'
        '[A B C D\n'
        ' E F G G#\n'
        ' A# Bb] x1/2\n'
        '[A B C D\n'
        ' E F G G#\n A# Bb] x2/2\n');
    expect(
        chordSection.toMarkupInRows(11),
        'I:\n'
        ' A B\n\n'
        ' A B C D\n\n'
        '[A B C D\n'
        ' E F G G#\n'
        ' A# Bb] x1/2\n'
        '[A B C D\n'
        ' E F G G#\n A# Bb] x2/2\n');
    expect(
        chordSection.toMarkupInRows(12),
        'I:\n'
        ' A B\n\n'
        ' A B C D\n\n'
        '[A B C D\n\n'
        ' E F G G#\n'
        ' A# Bb] x1/2\n'
        '[A B C D\n'
        ' E F G G#\n A# Bb] x2/2\n');

    expect(
        chordSection.toMarkupInRows(13),
        'I:\n'
        ' A B\n\n'
        ' A B C D\n\n'
        '[A B C D\n\n'
        ' E F G G#\n\n'
        ' A# Bb] x1/2\n'
        '[A B C D\n'
        ' E F G G#\n A# Bb] x2/2\n');

    expect(
        chordSection.toMarkupInRows(14),
        'I:\n'
        ' A B\n\n'
        ' A B C D\n\n'
        '[A B C D\n\n'
        ' E F G G#\n\n'
        ' A# Bb] x1/2\n\n'
        '[A B C D\n'
        ' E F G G#\n A# Bb] x2/2\n');
    expect(
        chordSection.toMarkupInRows(15),
        'I:\n'
        ' A B\n\n'
        ' A B C D\n\n'
        '[A B C D\n\n'
        ' E F G G#\n\n'
        ' A# Bb] x1/2\n\n'
        '[A B C D\n\n'
        ' E F G G#\n A# Bb] x2/2\n');

    expect(chordSection.toMarkupInRows(0),
        'I: A B, A B C D [A B C D, E F G G#, A# Bb] x1/2 [A B C D, E F G G#, A# Bb] x2/2\n');
    expect(chordSection.toMarkupInRows(1),
        'I: A B, A B C D [A B C D, E F G G#, A# Bb] x1/2 [A B C D, E F G G#, A# Bb] x2/2\n');
    expect(
        chordSection.toMarkupInRows(2),
        'I:\n'
        ' A B, A B C D [A B C D, E F G G#, A# Bb] x1/2 [A B C D, E F G G#, A# Bb] x2/2\n');
    expect(
        chordSection.toMarkupInRows(3),
        'I:\n'
        ' A B\n'
        ' A B C D [A B C D, E F G G#, A# Bb] x1/2 [A B C D, E F G G#, A# Bb] x2/2\n');
    expect(
        chordSection.toMarkupInRows(4),
        'I:\n'
        ' A B\n'
        ' A B C D\n'
        '[A B C D, E F G G#, A# Bb] x1/2 [A B C D, E F G G#, A# Bb] x2/2\n');
    expect(
        chordSection.toMarkupInRows(5),
        'I:\n'
        ' A B\n'
        ' A B C D\n'
        '[A B C D\n'
        ' E F G G#, A# Bb] x1/2 [A B C D, E F G G#, A# Bb] x2/2\n');
    expect(
        chordSection.toMarkupInRows(6),
        'I:\n'
        ' A B\n'
        ' A B C D\n'
        '[A B C D\n'
        ' E F G G#\n'
        ' A# Bb] x1/2 [A B C D, E F G G#, A# Bb] x2/2\n');
    expect(
        chordSection.toMarkupInRows(7),
        'I:\n'
        ' A B\n'
        ' A B C D\n'
        '[A B C D\n'
        ' E F G G#\n'
        ' A# Bb] x1/2\n'
        '[A B C D, E F G G#, A# Bb] x2/2\n');
    expect(
        chordSection.toMarkupInRows(8),
        'I:\n'
        ' A B\n'
        ' A B C D\n'
        '[A B C D\n'
        ' E F G G#\n'
        ' A# Bb] x1/2\n'
        '[A B C D\n'
        ' E F G G#, A# Bb] x2/2\n');
    expect(
        chordSection.toMarkupInRows(9),
        'I:\n'
        ' A B\n'
        ' A B C D\n'
        '[A B C D\n'
        ' E F G G#\n'
        ' A# Bb] x1/2\n'
        '[A B C D\n'
        ' E F G G#\n'
        ' A# Bb] x2/2\n');
    expect(
        chordSection.toMarkupInRows(10),
        'I:\n'
        ' A B\n'
        '\n'
        ' A B C D\n'
        '[A B C D\n'
        ' E F G G#\n'
        ' A# Bb] x1/2\n'
        '[A B C D\n'
        ' E F G G#\n'
        ' A# Bb] x2/2\n');
    expect(
        chordSection.toMarkupInRows(11),
        'I:\n'
        ' A B\n'
        '\n'
        ' A B C D\n'
        '\n'
        '[A B C D\n'
        ' E F G G#\n'
        ' A# Bb] x1/2\n'
        '[A B C D\n'
        ' E F G G#\n'
        ' A# Bb] x2/2\n');
    expect(
        chordSection.toMarkupInRows(12),
        'I:\n'
        ' A B\n'
        '\n'
        ' A B C D\n'
        '\n'
        '[A B C D\n'
        '\n'
        ' E F G G#\n'
        ' A# Bb] x1/2\n'
        '[A B C D\n'
        ' E F G G#\n'
        ' A# Bb] x2/2\n');

    expect(
        chordSection.toMarkupInRows(13),
        'I:\n'
        ' A B\n'
        '\n'
        ' A B C D\n'
        '\n'
        '[A B C D\n'
        '\n'
        ' E F G G#\n'
        '\n'
        ' A# Bb] x1/2\n'
        '[A B C D\n'
        ' E F G G#\n'
        ' A# Bb] x2/2\n');

    expect(
        chordSection.toMarkupInRows(14),
        'I:\n'
        ' A B\n'
        '\n'
        ' A B C D\n'
        '\n'
        '[A B C D\n'
        '\n'
        ' E F G G#\n'
        '\n'
        ' A# Bb] x1/2\n'
        '\n'
        '[A B C D\n'
        ' E F G G#\n'
        ' A# Bb] x2/2\n');
    expect(
        chordSection.toMarkupInRows(15),
        'I:\n'
        ' A B\n'
        '\n'
        ' A B C D\n'
        '\n'
        '[A B C D\n'
        '\n'
        ' E F G G#\n'
        '\n'
        ' A# Bb] x1/2\n'
        '\n'
        '[A B C D\n'
        '\n'
        ' E F G G#\n'
        ' A# Bb] x2/2\n');
  });

  test('test ChordSection transpose()', () {
    Logger.level = Level.debug;
    ChordSection chordSection;

    chordSection = ChordSection.parseString('I: A B C D, D C G G', beatsPerBar);
    logger.i(chordSection.phrasesToMarkup());
    expect(chordSection.transpose(Key.C, 0), 'A B C D, D C G G ');
    expect(chordSection.transpose(Key.C, 1), 'Bb C Db Eb, Eb Db Ab Ab ');
    expect(chordSection.transpose(Key.C, 2), 'B Db D E, E D A A ');
    expect(chordSection.transpose(Key.F, 1), 'Bb C Db Eb, Eb Db Ab Ab ');
    expect(chordSection.transpose(Key.G, 1), 'A# C C# D#, D# C# G# G# ');

    chordSection = ChordSection.parseString('I: A B C X x2, D C G G x3', beatsPerBar);
    logger.i(chordSection.phrasesToMarkup());
    expect(chordSection.transpose(Key.C, 0), '[A B C X ] x2 [D C G G ] x3 ');
    expect(chordSection.transpose(Key.C, 1), '[Bb C Db X ] x2 [Eb Db Ab Ab ] x3 ');
    expect(chordSection.transpose(Key.C, 2), '[B Db D X ] x2 [E D A A ] x3 ');
    expect(chordSection.transpose(Key.F, 1), '[Bb C Db X ] x2 [Eb Db Ab Ab ] x3 ');
    expect(chordSection.transpose(Key.G, 1), '[A# C C# X ] x2 [D# C# G# G# ] x3 ');
  });
}
