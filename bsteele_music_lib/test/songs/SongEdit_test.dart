import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/chordSection.dart';
import 'package:bsteeleMusicLib/songs/chordSectionLocation.dart';
import 'package:bsteeleMusicLib/songs/measure.dart';
import 'package:bsteeleMusicLib/songs/measureNode.dart';
import 'package:bsteeleMusicLib/songs/measureRepeat.dart';
import 'package:bsteeleMusicLib/songs/phrase.dart';
import 'package:bsteeleMusicLib/songs/sectionVersion.dart';
import 'package:bsteeleMusicLib/songs/songBase.dart';
import 'package:bsteeleMusicLib/songs/key.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

SongBase _a = SongBase();

class TestSong {
  void startingChords(String chords) {
    _a = SongBase.createSongBase('A', 'bob', 'bsteele.com', Key.getDefault(), 100, 4, 4, chords,
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    _myA = _a;
  }

  void pre(MeasureEditType type, String? locationString, String? measureNodeString, String? editEntry) {
    //  de-music character the result
    measureNodeString = _deMusic(measureNodeString);

    _myA.setCurrentMeasureEditType(type);
    if (locationString != null && locationString.isNotEmpty) {
      _myA.setCurrentChordSectionLocation(ChordSectionLocation.parseString(locationString));

      expect(_myA.getCurrentChordSectionLocation().toString(), locationString);

      if (measureNodeString != null) {
        expect(_myA.getCurrentMeasureNode()!.toMarkup().trim(), measureNodeString.trim());
      }
    }

    logger.d('editEntry: ' + (editEntry ?? 'null'));
    logger.v('edit loc: ' + _myA.getCurrentChordSectionLocation().toString());
    List<MeasureNode> measureNodes = _myA.parseChordEntry(editEntry);
    if (measureNodes.isEmpty && (editEntry == null || editEntry.isEmpty) && type == MeasureEditType.delete) {
      expect(_myA.deleteCurrentSelection(), isTrue);
    } else {
      for (MeasureNode measureNode in measureNodes) {
        logger.d('edit: ' + measureNode.toMarkup());
      }
      expect(_myA.editList(measureNodes), isTrue);
    }
    logger.v('after edit loc: ' + _myA.getCurrentChordSectionLocation().toString());
  }

  void resultChords(String chords) {
    expect(_myA.toMarkup().trim(), _deMusic(chords)!.trim());
  }

  void post(MeasureEditType type, String locationString, String? measureNodeString) {
    measureNodeString = _deMusic(measureNodeString);

    expect(_myA.getCurrentMeasureEditType(), type);
    expect(_myA.getCurrentChordSectionLocation().toString(), locationString);

    logger.d('getCurrentMeasureNode(): ' + _myA.getCurrentMeasureNode().toString());
    if (measureNodeString == null) {
      logger.d('measureNodeString: null');
      expect(_myA.getCurrentMeasureNode(), isNull);
    } else {
      logger.d('measureNodeString: ' + measureNodeString);
      expect(_myA.getCurrentMeasureNode(), isNotNull);
      expect(_myA.getCurrentMeasureNode()!.toMarkup().trim(), measureNodeString.trim());
    }
  }

  static String? _deMusic(String? s) {
    if (s == null) return null;

    //  de-music characters in the string
    s = s.replaceAll('♯', '#');
    s = s.replaceAll('♭', 'b');
    return s;
  }

  SongBase _myA = SongBase();
}

void main() {
  Logger.level = Level.debug;
  TestSong ts = TestSong();

  test('testEdits', () {
    SectionVersion v = SectionVersion.parseString('v:');
    SectionVersion iSection = SectionVersion.parseString('i:');
    int beatsPerBar = 4;
    ChordSectionLocation location;
    ChordSection newSection;
    MeasureRepeat newRepeat;
    Phrase newPhrase;
    Measure? newMeasure;

    ts.startingChords('');
    ts.pre(MeasureEditType.append, '', '', 'i: [A B C D]');
    ts.resultChords('I: A B C D ');
    ts.post(MeasureEditType.append, 'I:', 'I: A B C D');

    ts.startingChords('');
    ts.pre(MeasureEditType.append, '', '', SongBase.entryToUppercase('i: [a b c d]'));
    ts.resultChords('I: A B C D ');
    ts.post(MeasureEditType.append, 'I:', 'I: A B C D');

    ts.startingChords('I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G F F  O: Dm C B B♭ A  ');
    ts.pre(MeasureEditType.replace, 'C:', 'C: F F C C G G F F ', 'C: F F C C G G C B F F ');
    ts.resultChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C, G G C B, F F  O: Dm C B B♭ A  ');
    ts.post(MeasureEditType.append, 'C:', 'C: F F C C, G G C B, F F ');

    ts.startingChords(
        'I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G C B F F  O: Dm C B B♭ A  ');
    ts.pre(MeasureEditType.delete, 'C:0:7', 'B,', 'null');
    ts.resultChords('I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C, G G C F F  O: Dm C B B♭ A  ');
    ts.post(MeasureEditType.delete, 'C:0:7', 'F');

    ts.startingChords(
        'I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G C F F  O: Dm C B B♭ A  ');
    ts.pre(MeasureEditType.delete, 'C:0:7', 'F,', 'null');
    ts.resultChords('I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C, G G C F  O: Dm C B B♭ A  ');
    ts.post(MeasureEditType.delete, 'C:0:7', 'F');

    ts.startingChords('I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G C F  O: Dm C B B♭ A  ');
    ts.pre(MeasureEditType.delete, 'C:0:7', 'F', 'null');
    ts.resultChords('I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G C  O: Dm C B B♭ A  ');
    ts.post(MeasureEditType.delete, 'C:0:6', 'C');

    ts.startingChords('I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G C  O: Dm C B B♭ A  ');
    ts.pre(MeasureEditType.append, 'C:0:6', 'C', 'G G ');
    ts.resultChords('I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G C G G  O: Dm C B B♭ A  ');
    ts.post(MeasureEditType.append, 'C:0:8', 'G');

    ts.startingChords(
        'I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G C G G  O: Dm C B B♭ A  ');
    ts.pre(MeasureEditType.replace, 'I2:0', '[Am Am/G Am/F♯ FE ] x2 ', '[] x3 ');
    ts.resultChords('I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x3  C: F F C C, G G C G, G  O: Dm C B B♭ A  ');
    ts.post(MeasureEditType.append, 'I2:0', '[Am Am/G Am/F♯ FE ] x3 ');

    ts.startingChords(
        'I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x3  C: F F C C G G C G G  O: Dm C B B♭ A  ');
    ts.pre(MeasureEditType.replace, 'I2:0', '[Am Am/G Am/F♯ FE ] x3 ', '[] x1 ');
    ts.resultChords('I: V: [Am Am/G Am/F♯ FE ] x4  I2: Am Am/G Am/F♯ FE  C: F F C C, G G C G, G  O: Dm C B B♭ A  ');
    ts.post(MeasureEditType.append, 'I2:0:3', 'FE');

    //  allow more chords on a row if there is at least one end of row
    ts.startingChords(
        'I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x3  C: F F C C, G G C G G  O: Dm C B B♭ A  ');
    ts.pre(MeasureEditType.replace, 'I2:0', '[Am Am/G Am/F♯ FE ] x3 ', '[] x1 ');
    ts.resultChords('I: V: [Am Am/G Am/F♯ FE ] x4  I2: Am Am/G Am/F♯ FE  C: F F C C, G G C G G  O: Dm C B B♭ A  ');
    ts.post(MeasureEditType.append, 'I2:0:3', 'FE');

    ts.startingChords('I: A G D  V: D C G G  V1: Dm  V2: Em  PC: D C G D  C: F7 G7 G Am  ');
    ts.pre(MeasureEditType.delete, 'I:0:1', 'G', 'null');
    ts.resultChords('I: A D  V: D C G G  V1: Dm  V2: Em  PC: D C G D  C: F7 G7 G Am  ');
    ts.post(MeasureEditType.delete, 'I:0:1', 'D');

    ts.startingChords('I: A G D  V: D C G G  V1: Dm  V2: Em  PC: D C G D  C: F7 G7 G Am  ');
    ts.pre(MeasureEditType.replace, 'I:0:1', 'G', 'B C');
    ts.resultChords('I: A B C D  V: D C G G  V1: Dm  V2: Em  PC: D C G D  C: F7 G7 G Am  ');
    ts.post(MeasureEditType.append, 'I:0:2', 'C');

    ts.startingChords('V: C F C C F F C C G F C G  ');
    ts.pre(MeasureEditType.append, 'V:0:11', 'G', 'PC: []');
    ts.resultChords('V: C F C C, F F C C, G F C G  PC: [] ');
    ts.post(MeasureEditType.append, 'PC:', 'PC: []');
    ts.startingChords('V: C F C C F F C C G F C G  PC: [] ');
    ts.pre(MeasureEditType.replace, 'PC:', 'PC: []', 'PC: []');
    ts.resultChords('V: C F C C, F F C C, G F C G  PC: [] ');
    ts.post(MeasureEditType.append, 'PC:', 'PC: []');
    ts.startingChords('V: C F C C, F F C C, G F C G  PC:  ');
    ts.pre(MeasureEditType.append, 'PC:', 'PC: []', 'O: []');
    ts.resultChords('V: C F C C, F F C C, G F C G  PC: []  O: [] ');
    ts.post(MeasureEditType.append, 'O:', 'O: []');
    ts.startingChords('V: C F C C, F F C C, G F C G  PC: []  O: [] ');
    ts.pre(MeasureEditType.replace, 'O:', 'O: []', 'O: []');
    ts.resultChords('V: C F C C, F F C C, G F C G  PC: []  O: [] ');
    ts.post(MeasureEditType.append, 'O:', 'O: []');

    //  delete the section
    ts.startingChords('V: [C♯m A♭ F A♭ ] x4 C  C: [C G B♭ F ] x4  ');
    ts.pre(MeasureEditType.delete, 'V:', 'V: [C♯m A♭ F A♭ ] x4 C ', 'null');
    ts.resultChords('C: [C G B♭ F ] x4  ');
    ts.post(MeasureEditType.delete, 'C:', 'C: [C G B♭ F ] x4 ');

    ts.startingChords('C: [C G B♭ F ] x4  ');
    ts.pre(MeasureEditType.delete, 'C:', 'C: [C G B♭ F ] x4 ', 'null');
    ts.resultChords('');
    ts.post(MeasureEditType.append, 'V:', null);

    ts.startingChords('V: [C♯m A♭ F A♭ ] x4 C  PC2:  C: T: [C G B♭ F ] x4  ');
    ts.pre(MeasureEditType.delete, 'PC2:', 'PC2: [C G B♭ F ] x4', 'null');
    ts.resultChords('V: [C♯m A♭ F A♭ ] x4 C  C: T: [C G B♭ F ] x4  ');
    ts.post(MeasureEditType.delete, 'V:', 'V: [C♯m A♭ F A♭ ] x4 C ');

    ts.startingChords('V: [C♯m A♭ F A♭ ] x4 C  C: T: [C G B♭ F ] x4  ');
    ts.pre(MeasureEditType.delete, 'V:', 'V: [C♯m A♭ F A♭ ] x4 C ', 'null');
    ts.resultChords('C: T: [C G B♭ F ] x4  ');
    ts.post(MeasureEditType.delete, 'C:', 'C: [C G B♭ F ] x4 ');

    ts.startingChords('C: T: [C G B♭ F ] x4  ');
    ts.pre(MeasureEditType.delete, 'C:', 'C: [C G B♭ F ] x4 ', 'null');
    ts.resultChords('T: [C G B♭ F ] x4  ');
    ts.post(MeasureEditType.delete, 'T:', 'T: [C G B♭ F ] x4 ');

    ts.startingChords('T: [C G B♭ F ] x4  ');
    ts.pre(MeasureEditType.delete, 'T:', 'T: [C G B♭ F ] x4 ', 'null');
    ts.resultChords('');
    ts.post(MeasureEditType.append, 'V:', null);

    ts.startingChords('V: C F C C F F C C G F C G  ');
    ts.pre(MeasureEditType.append, 'V:0:7', 'C,', 'C PC:');
    ts.resultChords('V: C F C C, F F C C, C G F C G  PC: []');
    ts.post(MeasureEditType.append, 'PC:', 'PC: []');
    ts.startingChords('V: C F C C F F C C G F C G  ');
    ts.pre(MeasureEditType.append, 'V:0:7', 'C,', 'PC:');
    ts.resultChords('V: C F C C, F F C C, G F C G  PC: []');
    ts.post(MeasureEditType.append, 'PC:', 'PC: []');

    ts.startingChords('V: (Prechorus) C (C/) (chorus) [C G B♭ F ] x4 (Tag Chorus)  ');
    ts.pre(MeasureEditType.delete, 'V:0:0', '(Prechorus)', 'null');
    ts.resultChords('V: C (C/) (chorus) [C G B♭ F ] x4 (Tag Chorus)  ');

    ts.startingChords('V: (Verse) [C♯m A♭ F A♭ ] x4 (Prechorus) C (C/) (chorus) [C G B♭ F ] x4 (Tag Chorus)  ');
    ts.pre(MeasureEditType.delete, 'V:0:0', '(Verse)', 'null');
    ts.resultChords('V: [C♯m A♭ F A♭ ] x4 (Prechorus) C (C/) (chorus) [C G B♭ F ] x4 (Tag Chorus)  ');
    ts.post(MeasureEditType.delete, 'V:0:0', 'C♯m');
    _a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('V:0'));
    expect(_a.getCurrentChordSectionLocationMeasureNode()!.toMarkup(), TestSong._deMusic('[C♯m A♭ F A♭ ] x4 '));
    _a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('V:1:0'));
    expect(_a.getCurrentChordSectionLocationMeasureNode()!.toMarkup(), '(Prechorus)');
    ts.pre(MeasureEditType.delete, 'V:1:0', '(Prechorus)', 'null');
    ts.resultChords('V: [C♯m A♭ F A♭ ] x4 C (C/) (chorus) [C G B♭ F ] x4 (Tag Chorus)  ');
    ts.post(MeasureEditType.delete, 'V:1:0', 'C');
    ts.pre(MeasureEditType.delete, 'V:1:1', '(C/)', 'null');
    ts.resultChords('V: [C♯m A♭ F A♭ ] x4 C (chorus) [C G B♭ F ] x4 (Tag Chorus)  ');
    ts.post(MeasureEditType.delete, 'V:1:1', '(chorus)');
    ts.pre(MeasureEditType.delete, 'V:1:1', '(chorus)', 'null');
    ts.resultChords('V: [C♯m A♭ F A♭ ] x4 C [C G B♭ F ] x4 (Tag Chorus)  ');
    ts.post(MeasureEditType.delete, 'V:2:0', 'C');
    ts.pre(MeasureEditType.delete, 'V:3:0', '(Tag Chorus)', 'null');
    ts.resultChords('V: [C♯m A♭ F A♭ ] x4 C [C G B♭ F ] x4  ');
    ts.post(MeasureEditType.delete, 'V:2:3', 'F');

    ts.startingChords(
        'I: CXCC XCCC CXCC XCCC (bass-only)  V: Cmaj7 Cmaj7 Cmaj7 Cmaj7 Cmaj7 C7 F F Dm G Em Am F G Cmaj7 Cmaj7'
            '  C: A♭ A♭ E♭ E♭ B♭ B♭ G G'
            '  O: Cmaj7 Cmaj7 Cmaj7 Cmaj7 Cmaj7 C7 F F Dm G Em Am F G Em A7'
            ' F F G G Cmaj7 Cmaj7 Cmaj7 Cmaj7 Cmaj7 Cmaj7 (fade)  ');
    ts.pre(MeasureEditType.append, 'I:0:4', '(bass-only)', 'XCCC ');
    ts.resultChords(
        'I: CXCC XCCC CXCC XCCC (bass-only) XCCC  V: Cmaj7 Cmaj7 Cmaj7 Cmaj7, Cmaj7 C7 F F, Dm G Em Am, F G Cmaj7 Cmaj7'
            '  C: Ab Ab Eb Eb Bb Bb G G'
            '  O: Cmaj7 Cmaj7 Cmaj7 Cmaj7, Cmaj7 C7 F F, Dm G Em Am, F G Em A7,'
            ' F F G G, Cmaj7 Cmaj7 Cmaj7 Cmaj7, Cmaj7 Cmaj7 (fade)');
    ts.post(MeasureEditType.append, 'I:0:5', 'XCCC');

    ts.startingChords('I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G F F  O: Dm C B B♭ A  ');
    ts.pre(MeasureEditType.append, 'I:0', '[Am Am/G Am/F♯ FE ] x4 ', 'E ');
    ts.resultChords('I: V: [Am Am/G Am/F♯ FE ] x4 E  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G F F  O: Dm C B B♭ A  ');
    ts.post(MeasureEditType.append, 'I:1:0', 'E');

    ts.startingChords('I: V: O: E♭sus2 B♭ Gm7 Em F F7 G7 G Em Em Em Em Em Em Em Em Em C  C: [Cm F B♭ E♭ ] x3 Cm F  ');
    ts.pre(MeasureEditType.delete, 'I:0:14', 'Em', 'null');
    //  note: one Em has been deleted:
    ts.resultChords('I: V: O: E♭sus2 B♭ Gm7 Em, F F7 G7 G, Em Em Em Em, Em Em Em, Em C  C: [Cm F B♭ E♭ ] x3 Cm F  ');
    ts.post(MeasureEditType.delete, 'I:0:14', 'Em,');

    ts.startingChords('I: V: O: E♭sus2 B♭ Gm7 C  C: [Cm F B♭ E♭ ] x3 Cm F  ');
    ts.pre(MeasureEditType.append, 'I:0:2', 'Gm7', 'Em7 ');
    ts.resultChords('I: V: O: E♭sus2 B♭ Gm7 Em7 C  C: [Cm F B♭ E♭ ] x3 Cm F  ');
    ts.post(MeasureEditType.append, 'I:0:3', 'Em7');

    ts.startingChords('I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G F F  O: Dm C B B♭ A  ');
    ts.pre(MeasureEditType.replace, 'V:0:2', 'Am/F♯', 'Am/G ');
    ts.resultChords('I: V: [Am Am/G Am/G FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G F F  O: Dm C B B♭ A  ');
    ts.post(MeasureEditType.append, 'V:0:2', 'Am/G');

    ts.startingChords('V: C F C C F F C C G F C G  ');
    ts.pre(MeasureEditType.replace, 'V:0:3', 'C,', '[] x1 ');
    ts.resultChords('V: C F C C, F F C C, G F C G  ');
    ts.post(MeasureEditType.replace, 'V:0:3', 'C,');

    ts.startingChords('V: C F C C F F C C G F C G  ');
    //                    0 1 2 3  4 5 6 7 8 9 0 1
    ts.pre(MeasureEditType.replace, 'V:0:6', 'C', '[] x2 ');
    ts.resultChords('V: C F C C [F F C C ] x2 G F C G ');
    //               0 1 2 3  4 5 6 7      8 9 0 1
    //               0 1 2 3  0 1 2 3      0 1 2 3
    ts.post(MeasureEditType.append, 'V:1', '[F F C C ] x2');

    ts.startingChords('V: C F C C F F C C G F C G  ');
    //                 0 1 2 3 4 5 6 7 8 9 0 1
    ts.pre(MeasureEditType.replace, 'V:0:6', 'C', '[] x3 ');
    ts.resultChords('V: C F C C [F F C C ] x3 G F C G  ');
    ts.post(MeasureEditType.append, 'V:1', '[F F C C ] x3');

    ts.startingChords('I:  V:  ');
    ts.pre(MeasureEditType.append, 'V:', 'V: []', 'Dm ');
    ts.resultChords('I: []  V: Dm  ');
    ts.post(MeasureEditType.append, 'V:0:0', 'Dm');

    ts.startingChords('I:  V:  ');
    ts.pre(MeasureEditType.replace, 'V:', 'V: []', 'Dm ');
    ts.resultChords('I: []  V: Dm  ');
    ts.post(MeasureEditType.append, 'V:0:0', 'Dm');

    ts.startingChords('V: C F F C C F F C C G F C G  ');
    ts.pre(MeasureEditType.delete, 'V:', 'V: C F F C, C F F C, C G F C, G ', null);
    ts.resultChords('');
    ts.post(MeasureEditType.append, 'V:', null);

    ts.startingChords('V: C F C C F F C C G F C G  ');
    ts.pre(MeasureEditType.append, 'V:0:11', 'G', '- ');
    ts.resultChords('V: C F C C, F F C C, G F C G G  ');
    ts.post(MeasureEditType.append, 'V:0:12', 'G');

    ts.startingChords('V: C F C C F F C C G F C G G  ');
    ts.pre(MeasureEditType.append, 'V:0:1', 'F', '-');
    ts.resultChords('V: C F F C C, F F C C, G F C G, G  ');
    ts.post(MeasureEditType.append, 'V:0:2', 'F');

    ts.startingChords('V: C F F C C F F C C G F C G G  ');
    ts.pre(MeasureEditType.append, 'V:0:2', 'F', '  -  ');
    ts.resultChords('V: C F F F C, C F F C, C G F C, G G  ');
    ts.post(MeasureEditType.append, 'V:0:3', 'F');

    ts.startingChords('V: C F C C F F C C G F C G  ');
    ts.pre(MeasureEditType.append, 'V:0:1', 'F', '-');
    ts.resultChords('V: C F F C C, F F C C, G F C G  ');
    ts.post(MeasureEditType.append, 'V:0:2', 'F');

    ts.startingChords('I:  V:  ');
    ts.pre(MeasureEditType.append, 'V:', 'V: []', 'T: ');
    ts.resultChords('I: []  V: []  T: [] '); //  fixme: why is this?
    ts.post(MeasureEditType.append, 'T:', 'T: [] ');

    ts.startingChords('V: C F C C F F C C [G F C G ] x4  ');
    ts.pre(MeasureEditType.replace, 'V:1', '[G F C G ] x4 ', 'B ');
    ts.resultChords('V: C F C C F F C C B  ');
    //               0 1 2 3 4 5 6 7 8
    ts.post(MeasureEditType.append, 'V:0:8', 'B');

    //  insert into a repeat
    ts.startingChords('V: [C F C C ] x2 F F C C G F C G  ');
    ts.pre(MeasureEditType.insert, 'V:0:1', 'F', 'Dm ');
    ts.resultChords('V: [C Dm F C C ] x2 F F C C G F C G  ');
    ts.post(MeasureEditType.append, 'V:0:1', 'Dm');

    //  append into the middle
    ts.startingChords('V: C Dm C C F F C C G F C G  ');
    ts.pre(MeasureEditType.append, 'V:0:1', 'Dm', 'Em ');
    ts.resultChords('V: C Dm Em C C, F F C C, G F C G  ');
    ts.post(MeasureEditType.append, 'V:0:2', 'Em');

    //  replace second measure
    ts.startingChords('V: C F C C F F C C G F C G  '); //
    ts.pre(MeasureEditType.replace, 'V:0:1', 'F', 'Dm '); //
    ts.resultChords('V: C Dm C C, F F C C, G F C G  '); //
    ts.post(MeasureEditType.append, 'V:0:1', 'Dm'); //

    _a = SongBase.createSongBase('A', 'bob', 'bsteele.com', Key.getDefault(), 100, 4, 4, '', '');
    logger.d(_a.toMarkup());
    newPhrase = Phrase.parseString('A B C D', 0, beatsPerBar, null);
    logger.d(newPhrase.toMarkup());
    expect(_a.editMeasureNode(newPhrase), isTrue);
    logger.d(_a.toMarkup());
    expect('V: A B C D', _a.toMarkup().trim());
    expect('V:0:3', _a.getCurrentChordSectionLocation().toString());

    _a = SongBase.createSongBase('A', 'bob', 'bsteele.com', Key.getDefault(), 100, 4, 4, '', '');
    logger.d(_a.toMarkup());
    newSection = ChordSection.parseString('v:', beatsPerBar);
    expect(_a.editMeasureNode(newSection), isTrue);
    logger.d(_a.toMarkup());
    expect('V: []', _a.toMarkup().trim());
    expect('V:', _a.getCurrentChordSectionLocation().toString());
    _a.setCurrentMeasureEditType(MeasureEditType.append);
    newPhrase = Phrase.parseString('A B C D', 0, beatsPerBar, null);
    logger.d(newPhrase.toMarkup());
    expect(_a.editMeasureNode(newPhrase), isTrue);
    logger.d(_a.toMarkup());
    expect('V: A B C D', _a.toMarkup().trim());
    expect('V:0:3', _a.getCurrentChordSectionLocation().toString());
    newMeasure = Measure.parseString('E', beatsPerBar);
    logger.d(newPhrase.toMarkup());
    expect(_a.editMeasureNode(newMeasure), isTrue);
    logger.d(_a.toMarkup());
    expect('V: A B C D E', _a.toMarkup().trim());
    expect('V:0:4', _a.getCurrentChordSectionLocation().toString());
    newPhrase = Phrase.parseString('F', 0, beatsPerBar, null);
    logger.d(newPhrase.toMarkup());
    expect(_a.editMeasureNode(newPhrase), isTrue);
    logger.d(_a.toMarkup());
    expect('V: A B C D E F', _a.toMarkup().trim());
    expect('V:0:5', _a.getCurrentChordSectionLocation().toString());

    _a = SongBase.createSongBase('A', 'bob', 'bsteele.com', Key.getDefault(), 100, 4, 4,
        'i: A B C D V: D E F F# c: D C G G', 'i:\nv: bob, bob, bob berand\nc: nope nope');
    logger.d(_a.toMarkup());
    location = ChordSectionLocation.parseString('i:0:3');
    _a.setCurrentChordSectionLocation(location);
    _a.setCurrentMeasureEditType(MeasureEditType.append);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    newPhrase = Phrase.parseString('Db C B A', 0, beatsPerBar, null);
    expect(_a.editMeasureNode(newPhrase), isTrue);
    logger.d(_a.toMarkup());
    expect(_a.toMarkup().trim(), TestSong._deMusic('I: A B C D D♭ C B A  V: D E F F♯  C: D C G G'));
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect('I:0:7', _a.getCurrentChordSectionLocation().toString());
    expect('A', _a.getCurrentMeasureNode()!.toMarkup());

    _a = SongBase.createSongBase('A', 'bob', 'bsteele.com', Key.getDefault(), 100, 4, 4,
        'V: C F C C [GB F C Dm7 ] x4 G F C G  ', 'v: bob, bob, bob berand');
    logger.d(_a.toMarkup());
    location = ChordSectionLocation.parseString('v:1');
    _a.setCurrentChordSectionLocation(location);
    _a.setCurrentMeasureEditType(MeasureEditType.replace);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    newRepeat = MeasureRepeat.parseString('[]x1', 0, beatsPerBar, null);
    expect(_a.editMeasureNode(newRepeat), isTrue);
    logger.d(_a.toMarkup());
    expect(
      _a.toMarkup().trim(),
      'V: C F C C GB F C Dm7 G F C G',
    );
    //                        0 1 2 3 4  5 6 7   8 9 0 1
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect('V:0:7', _a.getCurrentChordSectionLocation().toString());
    expect('Dm7', _a.getCurrentMeasureNode()!.toMarkup());

    //   current type	current edit loc	entry	replace entry	 edit type	 edit loc	result
    logger.d('section	append	section(s)		replace	section(s)	add or replace section(s), de-dup');
    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D V: D E F F# c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    location = ChordSectionLocation(v);
    _a.setCurrentChordSectionLocation(location);
    _a.setCurrentMeasureEditType(MeasureEditType.append);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    newSection = ChordSection.parseString('v: A D C D', beatsPerBar);
    expect(_a.editMeasureNode(newSection), isTrue);
    logger.d(_a.toMarkup());
    expect('I: A B C D  V: A D C D  C: D C G G', _a.toMarkup().trim());
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(location, _a.getCurrentChordSectionLocation());
    expect(newSection, _a.getCurrentMeasureNode());

    logger.d('repeat	append	section(s)		replace	section(s)	add or replace section(s), de-dup');
    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D V: D E F F# [ D C B A ]x2 c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    location = ChordSectionLocation(v, phraseIndex: 1);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    _a.setCurrentChordSectionLocation(location);
    _a.setCurrentMeasureEditType(MeasureEditType.append);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(_a.editMeasureNode(ChordSection.parseString('v: A D C D', beatsPerBar)), isTrue);
    logger.d(_a.toMarkup());
    expect('I: A B C D  V: A D C D  C: D C G G', _a.toMarkup().trim());
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(ChordSectionLocation(v), _a.getCurrentChordSectionLocation());
    location = ChordSectionLocation.parseString('i:0:3');
    _a.setCurrentChordSectionLocation(location);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    newMeasure = Measure.parseString('F', beatsPerBar);
    expect(_a.editMeasureNode(newMeasure), isTrue);
    logger.d(_a.toMarkup());
    expect('I: A B C D F  V: A D C D  C: D C G G', _a.toMarkup().trim());
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(ChordSectionLocation.parseString('i:0:4'), _a.getCurrentChordSectionLocation());
    expect(newMeasure.toMarkup(), _a.getCurrentChordSectionLocationMeasureNode()!.toMarkup());

    logger.d('phrase	append	section(s)		replace	section(s)	add or replace section(s), de-dup');
    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D V: D E F F# [ D C B A ]x2 c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    _a.setCurrentChordSectionLocation(ChordSectionLocation(v, phraseIndex: 0));
    _a.setCurrentMeasureEditType(MeasureEditType.append);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(_a.editMeasureNode(ChordSection.parseString('v: A D C D', beatsPerBar)), isTrue);
    logger.d(_a.toMarkup());
    expect('I: A B C D  V: A D C D  C: D C G G', _a.toMarkup().trim());
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(ChordSectionLocation(v), _a.getCurrentChordSectionLocation());

    logger.d('measure	append	section(s)		replace	section(s)	add or replace section(s), de-dup');
    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D V: D E F F# [ D C B A ]x2 c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    _a.setCurrentChordSectionLocation(ChordSectionLocation(v, phraseIndex: 0));
    _a.setCurrentMeasureEditType(MeasureEditType.append);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(_a.editMeasureNode(ChordSection.parseString('v: A D C D', beatsPerBar)), isTrue);
    logger.d(_a.toMarkup());
    expect('I: A B C D  V: A D C D  C: D C G G', _a.toMarkup().trim());
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(ChordSectionLocation(v), _a.getCurrentChordSectionLocation());

    logger.d('section	insert	section(s)		replace	section(s)	add or replace section(s), de-dup');
    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D V: D E F F# c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    location = ChordSectionLocation(v);
    _a.setCurrentChordSectionLocation(location);
    _a.setCurrentMeasureEditType(MeasureEditType.insert);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(_a.editMeasureNode(ChordSection.parseString('v: A D C D', beatsPerBar)), isTrue);
    logger.d(_a.toMarkup());
    expect('I: A B C D  V: A D C D  C: D C G G', _a.toMarkup().trim());
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(location, _a.getCurrentChordSectionLocation());

    logger.d('repeat	insert	section(s)		replace	section(s)	add or replace section(s), de-dup');
    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D V: D E F F# [ D C B A ]x2 c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    location = ChordSectionLocation(v, phraseIndex: 1);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    _a.setCurrentChordSectionLocation(location);
    _a.setCurrentMeasureEditType(MeasureEditType.insert);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(_a.editMeasureNode(ChordSection.parseString('v: A D C D', beatsPerBar)), isTrue);
    logger.d(_a.toMarkup());
    expect('I: A B C D  V: A D C D  C: D C G G', _a.toMarkup().trim());
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(ChordSectionLocation(v), _a.getCurrentChordSectionLocation());

    logger.d('phrase	insert	section(s)		replace	section(s)	add or replace section(s), de-dup');
    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D V: D E F F# [ D C B A ]x2 c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    _a.setCurrentChordSectionLocation(ChordSectionLocation(v, phraseIndex: 0));
    _a.setCurrentMeasureEditType(MeasureEditType.insert);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(_a.editMeasureNode(ChordSection.parseString('v: A D C D', beatsPerBar)), isTrue);
    logger.d(_a.toMarkup());
    expect('I: A B C D  V: A D C D  C: D C G G', _a.toMarkup().trim());
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(ChordSectionLocation(v), _a.getCurrentChordSectionLocation());

    logger.d('measure	insert	section(s)		replace	section(s)	add or replace section(s), de-dup');
    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D V: D E F F# [ D C B A ]x2 c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    _a.setCurrentChordSectionLocation(ChordSectionLocation(v, phraseIndex: 0));
    _a.setCurrentMeasureEditType(MeasureEditType.insert);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(_a.editMeasureNode(ChordSection.parseString('v: A D C D', beatsPerBar)), isTrue);
    logger.d(_a.toMarkup());
    expect('I: A B C D  V: A D C D  C: D C G G', _a.toMarkup().trim());
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(ChordSectionLocation(v), _a.getCurrentChordSectionLocation());

    logger.d('section	replace	section(s)		replace	section(s)	add or replace section(s), de-dup');
    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D V: D E F F# c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    location = ChordSectionLocation(iSection);
    _a.setCurrentChordSectionLocation(location);
    _a.setCurrentMeasureEditType(MeasureEditType.replace);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(_a.editMeasureNode(ChordSection.parseString('v: A D C D', beatsPerBar)), isTrue);
    logger.d(_a.toMarkup());
    expect('I: A B C D  V: A D C D  C: D C G G', _a.toMarkup().trim());
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(ChordSectionLocation(v), _a.getCurrentChordSectionLocation());

    logger.d('repeat	replace	section(s)		replace	section(s)	add or replace section(s), de-dup');
    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D V: D E F F# [ D C B A ]x2 c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    _a.setCurrentChordSectionLocation(ChordSectionLocation(v, phraseIndex: 1));
    _a.setCurrentMeasureEditType(MeasureEditType.replace);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(_a.editMeasureNode(ChordSection.parseString('v: A D C D', beatsPerBar)), isTrue);
    logger.d(_a.toMarkup());
    expect('I: A B C D  V: A D C D  C: D C G G', _a.toMarkup().trim());
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(ChordSectionLocation(v), _a.getCurrentChordSectionLocation());

    logger.d('phrase	replace	section(s)		replace	section(s)	add or replace section(s), de-dup');
    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D V: D E F F# [ D C B A ]x2 c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    _a.setCurrentChordSectionLocation(ChordSectionLocation(v, phraseIndex: 0));
    _a.setCurrentMeasureEditType(MeasureEditType.replace);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(_a.editMeasureNode(ChordSection.parseString('v: A D C D', beatsPerBar)), isTrue);
    logger.d(_a.toMarkup());
    expect('I: A B C D  V: A D C D  C: D C G G', _a.toMarkup().trim());
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(ChordSectionLocation(v), _a.getCurrentChordSectionLocation());

    logger.d('measure	replace	section(s)		replace	section(s)	add or replace section(s), de-dup');
    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D V: D E F F# [ D C B A ]x2 c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    _a.setCurrentChordSectionLocation(ChordSectionLocation(v, phraseIndex: 0, measureIndex: 2));
    _a.setCurrentMeasureEditType(MeasureEditType.replace);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(_a.editMeasureNode(ChordSection.parseString('v: A D C D', beatsPerBar)), isTrue);
    logger.d(_a.toMarkup());
    expect('I: A B C D  V: A D C D  C: D C G G', _a.toMarkup().trim());
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(ChordSectionLocation(v), _a.getCurrentChordSectionLocation());

    logger.d('section	delete	section(s)	yes	append	measure	delete section');
    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D V: D E F F# c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    location = ChordSectionLocation(iSection);
    _a.setCurrentChordSectionLocation(location);
    _a.setCurrentMeasureEditType(MeasureEditType.delete);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(_a.editMeasureNode(ChordSection.parseString('v: A D C D', beatsPerBar)), isTrue);
    logger.d(_a.toMarkup());
    expect(_a.toMarkup().trim(), TestSong._deMusic('V: D E F F♯  C: D C G G'));
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(_a.getCurrentChordSectionLocation(), ChordSectionLocation(v));
    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D V: D E F F# c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    location = ChordSectionLocation(v);
    _a.setCurrentChordSectionLocation(location);
    _a.setCurrentMeasureEditType(MeasureEditType.delete);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(_a.editMeasureNode(ChordSection.parseString('v: A D C D', beatsPerBar)), isTrue);
    logger.d(_a.toMarkup());
    expect('I: A B C D  C: D C G G', _a.toMarkup().trim());
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(ChordSectionLocation(iSection), _a.getCurrentChordSectionLocation());

    logger.d('repeat  delete  section(s)  yes  append  measure  delete repeat');
    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D   V: D E F F# [ D C B A ]x2  c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    location = ChordSectionLocation(v, phraseIndex: 1);
    _a.setCurrentChordSectionLocation(location);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    _a.setCurrentMeasureEditType(MeasureEditType.delete);
    expect(_a.deleteCurrentSelection(), isTrue);
    logger.d(_a.toMarkup());
    expect(_a.toMarkup().trim(), TestSong._deMusic('I: A B C D  V: D E F F♯  C: D C G G'));
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(ChordSectionLocation.parseString('V:0:3'), _a.getCurrentChordSectionLocation());

    logger.d('phrase	delete	section(s)	yes	append	measure	delete phrase');
    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D   V: D E F F# [ D C B A ]x2  c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    location = ChordSectionLocation(v);
    _a.setCurrentChordSectionLocation(location);
    _a.setCurrentMeasureEditType(MeasureEditType.delete);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(_a.editMeasureNode(ChordSection.parseString('v:', beatsPerBar)), isTrue);
    logger.d(_a.toMarkup());
    expect('I: A B C D  C: D C G G', _a.toMarkup().trim());
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(ChordSectionLocation.parseString('I:'), _a.getCurrentChordSectionLocation());

    logger.d('measure	delete	section(s)	yes	append	measure	delete measure');
    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D   V: D E F F# [ D C B A ]x2  c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    location = ChordSectionLocation(v, phraseIndex: 0, measureIndex: 1);
    _a.setCurrentChordSectionLocation(location);
    _a.setCurrentMeasureEditType(MeasureEditType.delete);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(_a.deleteCurrentSelection(), isTrue);
    logger.d(_a.toMarkup());
    expect(_a.toMarkup().trim(), TestSong._deMusic('I: A B C D  V: D F F♯ [D C B A ] x2  C: D C G G'));
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(ChordSectionLocation.parseString('V:0:1'), _a.getCurrentChordSectionLocation());

    logger.d('section  append  repeat    replace  repeat  add to start of section');
    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D V: D E F F# c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    location = ChordSectionLocation(v);
    _a.setCurrentChordSectionLocation(location);
    _a.setCurrentMeasureEditType(MeasureEditType.append);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    newRepeat = MeasureRepeat.parseString('[ A D C D ] x3', 0, beatsPerBar, null);
    expect(_a.editMeasureNode(newRepeat), isTrue);
    logger.d(_a.toMarkup());
    expect(_a.toMarkup().trim(), TestSong._deMusic('I: A B C D  V: D E F F♯ [A D C D ] x3  C: D C G G'));
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(ChordSectionLocation.parseString('V:1'), _a.getCurrentChordSectionLocation());

    //   current type	current edit loc	entry	replace entry	 edit type	 edit loc	result
    logger.d('repeat  append  repeat    replace  repeat  replace repeat');
    //  x1 repeat should be converted to phrase
    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D V: [D E F F#]x3 c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    location = ChordSectionLocation(v, phraseIndex: 0);
    _a.setCurrentChordSectionLocation(location);
    _a.setCurrentMeasureEditType(MeasureEditType.replace);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    newRepeat = MeasureRepeat.parseString('[ A D C D ] x1', 0, beatsPerBar, null);
    expect(_a.editMeasureNode(newRepeat), isTrue);
    logger.d(_a.toMarkup());
    expect('I: A B C D  V: A D C D  C: D C G G', _a.toMarkup().trim());
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(ChordSectionLocation.parseString('V:0'), _a.getCurrentChordSectionLocation());

    //  empty x1 repeat appended should be convert repeat to phrase
    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D V: [D E F F#]x3 c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    location = ChordSectionLocation(v, phraseIndex: 0);
    _a.setCurrentChordSectionLocation(location);
    _a.setCurrentMeasureEditType(MeasureEditType.append);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    newRepeat = MeasureRepeat.parseString('[] x1', 0, beatsPerBar, null);
    expect(_a.editMeasureNode(newRepeat), isTrue);
    logger.d(_a.toMarkup());
    expect(_a.toMarkup().trim(), TestSong._deMusic('I: A B C D  V: D E F F♯  C: D C G G'));
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(ChordSectionLocation.parseString('V:0:3'), _a.getCurrentChordSectionLocation());

    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D V: [D E F F#]x3 c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    location = ChordSectionLocation(v, phraseIndex: 0);
    _a.setCurrentChordSectionLocation(location);
    _a.setCurrentMeasureEditType(MeasureEditType.replace);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    newRepeat = MeasureRepeat.parseString('[ A D C D ] x4', 0, beatsPerBar, null);
    expect(_a.editMeasureNode(newRepeat), isTrue);
    logger.d(_a.toMarkup());
    expect('I: A B C D  V: [A D C D ] x4  C: D C G G', _a.toMarkup().trim());
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(ChordSectionLocation.parseString('V:0'), _a.getCurrentChordSectionLocation());

    logger.d('phrase  append  repeat    replace  repeat  append repeat');

    logger.d('measure  append  repeat    replace  repeat  append repeat');
    //  empty repeat replaces current phrase
    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D V: D E F F# c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    location = ChordSectionLocation.parseString('v:0:3');
    _a.setCurrentChordSectionLocation(location);
    _a.setCurrentMeasureEditType(MeasureEditType.append);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    newRepeat = MeasureRepeat.parseString('[ ] x3', 0, beatsPerBar, null);
    expect(_a.editMeasureNode(newRepeat), isTrue);
    logger.d(_a.toMarkup());
    expect(_a.toMarkup().trim(), TestSong._deMusic('I: A B C D  V: [D E F F♯ ] x3  C: D C G G'));
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(ChordSectionLocation.parseString('v:0'), _a.getCurrentChordSectionLocation());
    //  non-empty repeat appends to current section
    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D V: D E F F# c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    location = ChordSectionLocation.parseString('v:0:3');
    _a.setCurrentChordSectionLocation(location);
    _a.setCurrentMeasureEditType(MeasureEditType.append);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    newRepeat = MeasureRepeat.parseString('[ D C G G] x3', 0, beatsPerBar, null);
    expect(_a.editMeasureNode(newRepeat), isTrue);
    logger.d(_a.toMarkup());
    expect(_a.toMarkup().trim(), TestSong._deMusic('I: A B C D  V: D E F F♯ [D C G G ] x3  C: D C G G'));
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(ChordSectionLocation.parseString('v:1'), _a.getCurrentChordSectionLocation());

    logger.d('section  insert  repeat    replace  repeat  add to start of section');
    logger.d('repeat  insert  repeat    replace  repeat  insert repeat');
    logger.d('phrase  insert  repeat    replace  repeat  insert repeat');
    logger.d('measure  insert  repeat    replace  repeat  insert repeat');
    logger.d('section  replace  repeat    replace  repeat  replace section content');
    logger.d('repeat  replace  repeat    replace  repeat  replace repeat');
    logger.d('phrase  replace  repeat    replace  repeat  replace phrase');
    logger.d('measure  replace  repeat    replace  repeat  replace measure');
    logger.d('section  delete  repeat  yes  append  measure  delete section');
    logger.d('repeat  delete  repeat  yes  append  measure  delete repeat');
    logger.d('phrase  delete  repeat  yes  append  measure  delete phrase');
    logger.d('measure  delete  repeat  yes  append  measure  delete measure');
    logger.d('section  append  phrase       phrase  append to end of section');
    logger.d('repeat  append  phrase    replace  phrase  append to end of repeat');
    logger.d('phrase  append  phrase    replace  phrase  append to end of phrase, join phrases');
    logger.d('measure  append  phrase    replace  phrase  append to end of measure, join phrases');
    logger.d('section  insert  phrase    replace  phrase  insert to start of section');
    logger.d('repeat  insert  phrase    replace  phrase  insert to start of repeat content');
    logger.d('phrase  insert  phrase    replace  phrase  insert to start of phrase');
    logger.d('measure  insert  phrase    replace  phrase  insert at start of measure');
    logger.d('section  replace  phrase    replace  phrase  replace section content');
    logger.d('repeat  replace  phrase    replace  phrase  replace repeat content');
    logger.d('phrase  replace  phrase    replace  phrase  replace');
    logger.d('measure  replace  phrase    replace  phrase  replace');
    logger.d('section  delete  phrase  yes  append  measure  delete section');
    logger.d('repeat  delete  phrase  yes  append  measure  delete repeat');
    logger.d('phrase  delete  phrase  yes  append  measure  delete phrase');
    logger.d('measure  delete  phrase  yes  append  measure  delete measure');
    logger.d('section  append  measure    append  measure  append to end of section');
    logger.d('repeat  append  measure    append  measure  append past end of repeat');
    logger.d('phrase  append  measure    append  measure  append to end of phrase');
    logger.d('measure  append  measure    append  measure  append to end of measure');
    logger.d('section  insert  measure    append  measure  insert to start of section');
    logger.d('repeat  insert  measure    append  measure  insert prior to start of repeat');
    logger.d('phrase  insert  measure    append  measure  insert to start of phrase');

    logger.d('measure  insert  measure    append  measure  insert to start of measure');
    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D V: D E F F# [ A D C D ] x3 c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    location = ChordSectionLocation.parseString('v:0:2');
    _a.setCurrentChordSectionLocation(location);
    _a.setCurrentMeasureEditType(MeasureEditType.insert);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    newMeasure = Measure.parseString('Gm', beatsPerBar);
    expect(_a.editMeasureNode(newMeasure), isTrue);
    logger.d(_a.toMarkup());
    expect(_a.toMarkup().trim(), TestSong._deMusic('I: A B C D  V: D E Gm F F♯ [A D C D ] x3  C: D C G G'));
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(location, _a.getCurrentChordSectionLocation());

    logger.d('section  replace  measure    append  measure  replace section content');
    logger.d('repeat  replace  measure    append  measure  replace repeat');
    logger.d('phrase  replace  measure    append  measure  replace phrase');
    logger.d('measure  replace  measure    append  measure  replace');
    logger.d('section  delete  measure  yes  append  measure  delete section');
    logger.d('repeat  delete  measure  yes  append  measure  delete repeat');
    logger.d('phrase  delete  measure  yes  append  measure  delete phrase');
    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D V: D E F F# c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    location = ChordSectionLocation.parseString('v:0:2');
    _a.setCurrentChordSectionLocation(location);
    _a.setCurrentMeasureEditType(MeasureEditType.delete);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(_a.deleteCurrentSelection(), isTrue);
    logger.d(_a.toMarkup());
    expect(_a.toMarkup().trim(), TestSong._deMusic('I: A B C D  V: D E F♯  C: D C G G'));
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(location, _a.getCurrentChordSectionLocation());

    logger.d('measure  delete  measure  yes  append  measure  delete measure');
    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D V: D E F F# c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    location = ChordSectionLocation.parseString('v:0:2');
    _a.setCurrentChordSectionLocation(location);
    _a.setCurrentMeasureEditType(MeasureEditType.delete);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(_a.deleteCurrentSelection(), isTrue);
    logger.d(_a.toMarkup());
    expect(_a.toMarkup().trim(), TestSong._deMusic('I: A B C D  V: D E F♯  C: D C G G'));
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(location, _a.getCurrentChordSectionLocation());
    _a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D V: D E F F# c: D C G G',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    logger.d(_a.toMarkup());
    location = ChordSectionLocation.parseString('v:0:2');
    _a.setCurrentChordSectionLocation(location);
    _a.setCurrentMeasureEditType(MeasureEditType.delete);
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.getCurrentMeasureEditType().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    newMeasure = Measure.parseString('F', beatsPerBar);
    expect(_a.editMeasureNode(newMeasure), isTrue);
    logger.d(_a.toMarkup());
    expect(_a.toMarkup().trim(), TestSong._deMusic('I: A B C D  V: D E F♯  C: D C G G'));
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(location, _a.getCurrentChordSectionLocation());
  });
}
