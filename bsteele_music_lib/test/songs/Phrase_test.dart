import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/grid.dart';
import 'package:bsteeleMusicLib/songs/measure.dart';
import 'package:bsteeleMusicLib/songs/measureNode.dart';
import 'package:bsteeleMusicLib/songs/phrase.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.warning;

  test('testParsing', () {
    int phraseIndex = 0;
    int beatsPerBar = 4;
    String s;
    Phrase phrase;

    try {
      s = 'G F E D x2';
      phrase = Phrase.parseString(s, phraseIndex, beatsPerBar, null);
      fail('a repeat is not a phrase');
    } catch (e) {
      ;
    }

    s = 'A B C D, G F E D x2';
    phrase = Phrase.parseString(s, phraseIndex, beatsPerBar, null);
    expect(phrase.length, 4); //  phrase should not include the repeat

    s = '   A ';
    phrase = Phrase.parseString(s, phraseIndex, beatsPerBar, null);
    expect(phrase.length, 1);

    s = 'A B C D';
    phrase = Phrase.parseString(s, phraseIndex, beatsPerBar, null);
    expect(phrase.length, 4);

    s = 'A B C D A B C D A B C D';
    phrase = Phrase.parseString(s, phraseIndex, beatsPerBar, null);
    expect(phrase.length, 12);

    s = 'A B C, D A ,B C D ,A, B C D';
    phrase = Phrase.parseString(s, phraseIndex, beatsPerBar, null);
    expect(phrase.length, 12);

    s = 'A B C, D A ,B C D ,A, B C D, G G x2';
    phrase = Phrase.parseString(s, phraseIndex, beatsPerBar, null);
    logger.d(s);
    expect(phrase.length, 12);
  });

  test('test phrase grid', () {
    int phraseIndex = 0;
    int beatsPerBar = 4;
    String s;
    Phrase phrase;
    Grid<MeasureNode> grid;

    {
      s = 'A B C D';
      phrase = Phrase.parseString(s, phraseIndex, beatsPerBar, null);
      grid = phrase.toGrid(chordColumns: 6);
      expect(grid.getRowCount(), 1);
      expect(grid.rowLength(0), 6);
      expect(grid.get(0, grid.rowLength(0) - 1 - 2), Measure.parseString('D', beatsPerBar));
    }
    {
      s = 'A B C D';
      phrase = Phrase.parseString(s, phraseIndex, beatsPerBar, null);
      grid = phrase.toGrid();
      expect(grid.getRowCount(), 1);
      expect(grid.rowLength(0), 4);
      expect(grid.get(0, grid.rowLength(0) - 1), Measure.parseString('D', beatsPerBar));
    }
    {
      s = 'A B C D E F G A';
      phrase = Phrase.parseString(s, phraseIndex, beatsPerBar, null);
      grid = phrase.toGrid();
      expect(grid.getRowCount(), 1);
      expect(grid.rowLength(0), 8);
      expect(grid.get(0, grid.rowLength(0) - 1), Measure.parseString('A', beatsPerBar));
    }
    {
      s = 'A B C D, E F G A#';
      phrase = Phrase.parseString(s, phraseIndex, beatsPerBar, null);
      grid = phrase.toGrid();
      expect(grid.getRowCount(), 2);
      expect(grid.rowLength(0), 4);
      expect(grid.rowLength(1), 4);
      expect(grid.get(1, grid.rowLength(1) - 1), Measure.parseString('A#', beatsPerBar));
    }
    {
      s = 'A B C D, E F G A#, Bb CE C#';
      phrase = Phrase.parseString(s, phraseIndex, beatsPerBar, null);
      grid = phrase.toGrid();
      expect(grid.getRowCount(), 3);
      expect(grid.rowLength(0), 4);
      expect(grid.rowLength(1), 4);
      expect(grid.rowLength(2), 4);
      expect(grid.get(0, grid.rowLength(0) - 1), Measure.parseString('D,', beatsPerBar));
      expect(grid.get(1, grid.rowLength(1) - 1), Measure.parseString('A#,', beatsPerBar));
      expect(grid.get(2, 2), Measure.parseString('C#', beatsPerBar));
      expect(grid.get(2, 3), isNull);
    }
  });
}
