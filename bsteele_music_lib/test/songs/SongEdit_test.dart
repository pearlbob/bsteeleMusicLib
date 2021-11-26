import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/chordSection.dart';
import 'package:bsteeleMusicLib/songs/chordSectionLocation.dart';
import 'package:bsteeleMusicLib/songs/key.dart';
import 'package:bsteeleMusicLib/songs/measure.dart';
import 'package:bsteeleMusicLib/songs/measureNode.dart';
import 'package:bsteeleMusicLib/songs/measureRepeat.dart';
import 'package:bsteeleMusicLib/songs/phrase.dart';
import 'package:bsteeleMusicLib/songs/section.dart';
import 'package:bsteeleMusicLib/songs/sectionVersion.dart';
import 'package:bsteeleMusicLib/songs/songBase.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

SongBase _a = SongBase();

class TestSong {
  void startingChords(String chords) {
    _a = SongBase.createSongBase('A', 'bob', 'bsteele.com', Key.getDefault(), 100, 4, 4, chords,
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    _myA = _a;
  }

  void edit(MeasureEditType type, String? locationString, String? measureNodeString, String? editEntry) {
    //  de-music character the result
    measureNodeString = deMusic(measureNodeString);

    //  setup for edit as requested
    _myA.setCurrentMeasureEditType(type);
    if (locationString != null && locationString.isNotEmpty) {
      _myA.setCurrentChordSectionLocation(ChordSectionLocation.parseString(locationString));

      expect(_myA.getCurrentChordSectionLocation().toString(), locationString);

      if (measureNodeString != null) {
        expect(_myA.getCurrentMeasureNode()!.toMarkup().trim(), measureNodeString.trim());
      }
    }

    //  process the edits
    logger.d('editEntry: ' + (editEntry ?? 'null'));
    logger.v('edit loc: ' + _myA.getCurrentChordSectionLocation().toString());
    List<MeasureNode> measureNodes = _myA.parseChordEntry(editEntry);
    if (measureNodes.isEmpty && (editEntry == null || editEntry.isEmpty) && type == MeasureEditType.delete) {
      expect(_myA.deleteCurrentSelection(), isTrue);
    } else {
      for (MeasureNode measureNode in measureNodes) {
        logger.d('edit: ' + measureNode.toMarkup());
      }
      //  the edit is here:
      expect(_myA.editList(measureNodes), isTrue);
    }
    logger.v('after edit loc: ' + _myA.getCurrentChordSectionLocation().toString());
  }

  void resultChords(String chords) {
    expect(_myA.toMarkup().trim(), deMusic(chords)!.trim());
  }

  void post(MeasureEditType type, String currentLocationString, String? currentMeasureNodeString) {
    currentMeasureNodeString = deMusic(currentMeasureNodeString);

    expect(_myA.currentMeasureEditType, type);
    expect(_myA.getCurrentChordSectionLocation().toString(), currentLocationString);

    logger.d('getCurrentMeasureNode(): ' + _myA.getCurrentMeasureNode().toString());
    if (currentMeasureNodeString == null) {
      logger.d('measureNodeString: null');
      expect(_myA.getCurrentMeasureNode(), isNull);
    } else {
      logger.d('measureNodeString: ' + currentMeasureNodeString);
      expect(_myA.getCurrentMeasureNode(), isNotNull);
      expect(_myA.getCurrentMeasureNode()!.toMarkup().trim(), currentMeasureNodeString.trim());
    }
  }

  void setRepeat(ChordSectionLocation chordSectionLocation, int repeats) {
    _myA.setRepeat(chordSectionLocation, repeats);
  }

  static String? deMusic(String? s) {
    if (s == null) return null;

    //  de-music characters in the string
    s = s.replaceAll('♯', '#');
    s = s.replaceAll('♭', 'b');
    return s;
  }

  SongBase get myA => _myA;

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
    ts.edit(MeasureEditType.append, '', '', 'i: [A B C D]');
    ts.resultChords('I: A B C D ');
    ts.post(MeasureEditType.append, 'I:', 'I: A B C D');

    ts.startingChords('');
    ts.edit(MeasureEditType.append, '', '', SongBase.entryToUppercase('i: [a b c d]'));
    ts.resultChords('I: A B C D ');
    ts.post(MeasureEditType.append, 'I:', 'I: A B C D');

    ts.startingChords('I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G F F  O: Dm C B B♭ A  ');
    ts.edit(MeasureEditType.replace, 'C:', 'C: F F C C G G F F ', 'C: F F C C G G C B F F ');
    ts.resultChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C, G G C B, F F  O: Dm C B B♭ A  ');
    ts.post(MeasureEditType.append, 'C:', 'C: F F C C, G G C B, F F ');

    ts.startingChords(
        'I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G C B F F  O: Dm C B B♭ A  ');
    ts.edit(MeasureEditType.delete, 'C:0:7', 'B,', 'null');
    ts.resultChords(
        'I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C, G G C F F  O: Dm C B B♭ A  ');
    ts.post(MeasureEditType.delete, 'C:0:7', 'F');

    ts.startingChords(
        'I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G C F F  O: Dm C B B♭ A  ');
    ts.edit(MeasureEditType.delete, 'C:0:7', 'F,', 'null');
    ts.resultChords('I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C, G G C F  O: Dm C B B♭ A  ');
    ts.post(MeasureEditType.delete, 'C:0:7', 'F');

    ts.startingChords('I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G C F  O: Dm C B B♭ A  ');
    ts.edit(MeasureEditType.delete, 'C:0:7', 'F', 'null');
    ts.resultChords('I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G C  O: Dm C B B♭ A  ');
    ts.post(MeasureEditType.delete, 'C:0:6', 'C');

    ts.startingChords('I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G C  O: Dm C B B♭ A  ');
    ts.edit(MeasureEditType.append, 'C:0:6', 'C', 'G G ');
    ts.resultChords('I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G C G G  O: Dm C B B♭ A  ');
    ts.post(MeasureEditType.append, 'C:0:8', 'G');

    ts.startingChords(
        'I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G C G G  O: Dm C B B♭ A  ');
    ts.edit(MeasureEditType.replace, 'I2:0', '[Am Am/G Am/F♯ FE ] x2 ', '[] x3 ');
    ts.resultChords(
        'I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x3  C: F F C C, G G C G, G  O: Dm C B B♭ A  ');
    ts.post(MeasureEditType.append, 'I2:0', '[Am Am/G Am/F♯ FE ] x3 ');

    ts.startingChords(
        'I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x3  C: F F C C G G C G G  O: Dm C B B♭ A  ');
    ts.edit(MeasureEditType.replace, 'I2:0', '[Am Am/G Am/F♯ FE ] x3 ', '[] x1 ');
    ts.resultChords('I: V: [Am Am/G Am/F♯ FE ] x4  I2: Am Am/G Am/F♯ FE  C: F F C C, G G C G, G  O: Dm C B B♭ A  ');
    ts.post(MeasureEditType.append, 'I2:0:3', 'FE');

    //  allow more chords on a row if there is at least one end of row
    ts.startingChords(
        'I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x3  C: F F C C, G G C G G  O: Dm C B B♭ A  ');
    ts.edit(MeasureEditType.replace, 'I2:0', '[Am Am/G Am/F♯ FE ] x3 ', '[] x1 ');
    ts.resultChords('I: V: [Am Am/G Am/F♯ FE ] x4  I2: Am Am/G Am/F♯ FE  C: F F C C, G G C G G  O: Dm C B B♭ A  ');
    ts.post(MeasureEditType.append, 'I2:0:3', 'FE');

    ts.startingChords('I: A G D  V: D C G G  V1: Dm  V2: Em  PC: D C G D  C: F7 G7 G Am  ');
    ts.edit(MeasureEditType.delete, 'I:0:1', 'G', 'null');
    ts.resultChords('I: A D  V: D C G G  V1: Dm  V2: Em  PC: D C G D  C: F7 G7 G Am  ');
    ts.post(MeasureEditType.delete, 'I:0:1', 'D');

    ts.startingChords('I: A G D  V: D C G G  V1: Dm  V2: Em  PC: D C G D  C: F7 G7 G Am  ');
    ts.edit(MeasureEditType.replace, 'I:0:1', 'G', 'B C');
    ts.resultChords('I: A B C D  V: D C G G  V1: Dm  V2: Em  PC: D C G D  C: F7 G7 G Am  ');
    ts.post(MeasureEditType.append, 'I:0:2', 'C');

    ts.startingChords('V: C F C C F F C C G F C G  ');
    ts.edit(MeasureEditType.append, 'V:0:11', 'G', 'PC: []');
    ts.resultChords('V: C F C C, F F C C, G F C G  PC: [] ');
    ts.post(MeasureEditType.append, 'PC:', 'PC: []');
    ts.startingChords('V: C F C C F F C C G F C G  PC: [] ');
    ts.edit(MeasureEditType.replace, 'PC:', 'PC: []', 'PC: []');
    ts.resultChords('V: C F C C, F F C C, G F C G  PC: [] ');
    ts.post(MeasureEditType.append, 'PC:', 'PC: []');
    ts.startingChords('V: C F C C, F F C C, G F C G  PC:  ');
    ts.edit(MeasureEditType.append, 'PC:', 'PC: []', 'O: []');
    ts.resultChords('V: C F C C, F F C C, G F C G  PC: []  O: [] ');
    ts.post(MeasureEditType.append, 'O:', 'O: []');
    ts.startingChords('V: C F C C, F F C C, G F C G  PC: []  O: [] ');
    ts.edit(MeasureEditType.replace, 'O:', 'O: []', 'O: []');
    ts.resultChords('V: C F C C, F F C C, G F C G  PC: []  O: [] ');
    ts.post(MeasureEditType.append, 'O:', 'O: []');

    //  delete the section
    ts.startingChords('V: [C♯m A♭ F A♭ ] x4 C  C: [C G B♭ F ] x4  ');
    ts.edit(MeasureEditType.delete, 'V:', 'V: [C♯m A♭ F A♭ ] x4 C ', 'null');
    ts.resultChords('C: [C G B♭ F ] x4  ');
    ts.post(MeasureEditType.delete, 'C:', 'C: [C G B♭ F ] x4 ');

    ts.startingChords('C: [C G B♭ F ] x4  ');
    ts.edit(MeasureEditType.delete, 'C:', 'C: [C G B♭ F ] x4 ', 'null');
    ts.resultChords('');
    ts.post(MeasureEditType.append, 'V:', null);

    ts.startingChords('V: [C♯m A♭ F A♭ ] x4 C  PC2:  C: T: [C G B♭ F ] x4  ');
    ts.edit(MeasureEditType.delete, 'PC2:', 'PC2: [C G B♭ F ] x4', 'null');
    ts.resultChords('V: [C♯m A♭ F A♭ ] x4 C  C: T: [C G B♭ F ] x4  ');
    ts.post(MeasureEditType.delete, 'V:', 'V: [C♯m A♭ F A♭ ] x4 C ');

    ts.startingChords('V: [C♯m A♭ F A♭ ] x4 C  C: T: [C G B♭ F ] x4  ');
    ts.edit(MeasureEditType.delete, 'V:', 'V: [C♯m A♭ F A♭ ] x4 C ', 'null');
    ts.resultChords('C: T: [C G B♭ F ] x4  ');
    ts.post(MeasureEditType.delete, 'C:', 'C: [C G B♭ F ] x4 ');

    ts.startingChords('C: T: [C G B♭ F ] x4  ');
    ts.edit(MeasureEditType.delete, 'C:', 'C: [C G B♭ F ] x4 ', 'null');
    ts.resultChords('T: [C G B♭ F ] x4  ');
    ts.post(MeasureEditType.delete, 'T:', 'T: [C G B♭ F ] x4 ');

    ts.startingChords('T: [C G B♭ F ] x4  ');
    ts.edit(MeasureEditType.delete, 'T:', 'T: [C G B♭ F ] x4 ', 'null');
    ts.resultChords('');
    ts.post(MeasureEditType.append, 'V:', null);

    ts.startingChords('V: C F C C F F C C G F C G  ');
    ts.edit(MeasureEditType.append, 'V:0:7', 'C,', 'C PC:');
    ts.resultChords('V: C F C C, F F C C, C G F C G  PC: []');
    ts.post(MeasureEditType.append, 'PC:', 'PC: []');
    ts.startingChords('V: C F C C F F C C G F C G  ');
    ts.edit(MeasureEditType.append, 'V:0:7', 'C,', 'PC:');
    ts.resultChords('V: C F C C, F F C C, G F C G  PC: []');
    ts.post(MeasureEditType.append, 'PC:', 'PC: []');

    ts.startingChords('V: (Prechorus) C (C/) (chorus) [C G B♭ F ] x4 (Tag Chorus)  ');
    ts.edit(MeasureEditType.delete, 'V:0:0', '(Prechorus)', 'null');
    ts.resultChords('V: C (C/) (chorus) [C G B♭ F ] x4 (Tag Chorus)  ');

    ts.startingChords('V: (Verse) [C♯m A♭ F A♭ ] x4 (Prechorus) C (C/) (chorus) [C G B♭ F ] x4 (Tag Chorus)  ');
    ts.edit(MeasureEditType.delete, 'V:0:0', '(Verse)', 'null');
    ts.resultChords('V: [C♯m A♭ F A♭ ] x4 (Prechorus) C (C/) (chorus) [C G B♭ F ] x4 (Tag Chorus)  ');
    ts.post(MeasureEditType.delete, 'V:0:0', 'C♯m');
    _a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('V:0'));
    expect(_a.getCurrentChordSectionLocationMeasureNode()!.toMarkup(), TestSong.deMusic('[C♯m A♭ F A♭ ] x4 '));
    _a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('V:1:0'));
    expect(_a.getCurrentChordSectionLocationMeasureNode()!.toMarkup(), '(Prechorus)');

    ts.edit(MeasureEditType.delete, 'V:1:0', '(Prechorus)', 'null');
    ts.resultChords('V: [C♯m A♭ F A♭ ] x4 C (C/) (chorus) [C G B♭ F ] x4 (Tag Chorus)  ');
    ts.post(MeasureEditType.delete, 'V:1:0', 'C');

    ts.edit(MeasureEditType.delete, 'V:1:1', '(C/)', 'null');
    ts.resultChords('V: [C♯m A♭ F A♭ ] x4 C (chorus) [C G B♭ F ] x4 (Tag Chorus)  ');
    ts.post(MeasureEditType.delete, 'V:1:1', '(chorus)');

    ts.edit(MeasureEditType.delete, 'V:1:1', '(chorus)', 'null');
    ts.resultChords('V: [C♯m A♭ F A♭ ] x4 C [C G B♭ F ] x4 (Tag Chorus)  ');
    ts.post(MeasureEditType.delete, 'V:1:0', 'C');

    ts.edit(MeasureEditType.delete, 'V:3:0', '(Tag Chorus)', 'null');
    ts.resultChords('V: [C♯m A♭ F A♭ ] x4 C [C G B♭ F ] x4  ');
    ts.post(MeasureEditType.delete, 'V:2:3', 'F');

    ts.startingChords(
        'I: CXCC XCCC CXCC XCCC (bass-only)  V: Cmaj7 Cmaj7 Cmaj7 Cmaj7 Cmaj7 C7 F F Dm G Em Am F G Cmaj7 Cmaj7'
        '  C: A♭ A♭ E♭ E♭ B♭ B♭ G G'
        '  O: Cmaj7 Cmaj7 Cmaj7 Cmaj7 Cmaj7 C7 F F Dm G Em Am F G Em A7'
        ' F F G G Cmaj7 Cmaj7 Cmaj7 Cmaj7 Cmaj7 Cmaj7 (fade)  ');
    ts.edit(MeasureEditType.append, 'I:0:4', '(bass-only)', 'XCCC ');
    ts.resultChords(
        'I: CXCC XCCC CXCC XCCC (bass-only) XCCC  V: Cmaj7 Cmaj7 Cmaj7 Cmaj7, Cmaj7 C7 F F, Dm G Em Am, F G Cmaj7 Cmaj7'
        '  C: Ab Ab Eb Eb Bb Bb G G'
        '  O: Cmaj7 Cmaj7 Cmaj7 Cmaj7, Cmaj7 C7 F F, Dm G Em Am, F G Em A7,'
        ' F F G G, Cmaj7 Cmaj7 Cmaj7 Cmaj7, Cmaj7 Cmaj7 (fade)');
    ts.post(MeasureEditType.append, 'I:0:5', 'XCCC');

    ts.startingChords('I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G F F  O: Dm C B B♭ A  ');
    ts.edit(MeasureEditType.append, 'I:0', '[Am Am/G Am/F♯ FE ] x4 ', 'E ');
    ts.resultChords('I: V: [Am Am/G Am/F♯ FE ] x4 E  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G F F  O: Dm C B B♭ A  ');
    ts.post(MeasureEditType.append, 'I:1:0', 'E');

    ts.startingChords('I: V: O: E♭sus2 B♭ Gm7 Em F F7 G7 G Em Em Em Em Em Em Em Em Em C  C: [Cm F B♭ E♭ ] x3 Cm F  ');
    ts.edit(MeasureEditType.delete, 'I:0:14', 'Em', 'null');
    //  note: one Em has been deleted:
    ts.resultChords('I: V: O: E♭sus2 B♭ Gm7 Em, F F7 G7 G, Em Em Em Em, Em Em Em, Em C  C: [Cm F B♭ E♭ ] x3 Cm F  ');
    ts.post(MeasureEditType.delete, 'I:0:14', 'Em,');

    ts.startingChords('I: V: O: E♭sus2 B♭ Gm7 C  C: [Cm F B♭ E♭ ] x3 Cm F  ');
    ts.edit(MeasureEditType.append, 'I:0:2', 'Gm7', 'Em7 ');
    ts.resultChords('I: V: O: E♭sus2 B♭ Gm7 Em7 C  C: [Cm F B♭ E♭ ] x3 Cm F  ');
    ts.post(MeasureEditType.append, 'I:0:3', 'Em7');

    ts.startingChords('I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G F F  O: Dm C B B♭ A  ');
    ts.edit(MeasureEditType.replace, 'V:0:2', 'Am/F♯', 'Am/G ');
    ts.resultChords('I: V: [Am Am/G Am/G FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G F F  O: Dm C B B♭ A  ');
    ts.post(MeasureEditType.append, 'V:0:2', 'Am/G');

    ts.startingChords('V: C F C C F F C C G F C G  ');
    ts.edit(MeasureEditType.replace, 'V:0:3', 'C,', '[] x1 ');
    ts.resultChords('V: C F C C, F F C C, G F C G  ');
    ts.post(MeasureEditType.replace, 'V:0:3', 'C,');

    ts.startingChords('V: C F C C F F C C G F C G  ');
    //                    0 1 2 3  4 5 6 7 8 9 0 1
    ts.edit(MeasureEditType.replace, 'V:0:6', 'C', '[] x2 ');
    ts.resultChords('V: C F C C [F F C C ] x2 G F C G ');
    //               0 1 2 3  4 5 6 7      8 9 0 1
    //               0 1 2 3  0 1 2 3      0 1 2 3
    ts.post(MeasureEditType.append, 'V:1', '[F F C C ] x2');

    ts.startingChords('V: C F C C F F C C G F C G  ');
    //                 0 1 2 3 4 5 6 7 8 9 0 1
    ts.edit(MeasureEditType.replace, 'V:0:6', 'C', '[] x3 ');
    ts.resultChords('V: C F C C [F F C C ] x3 G F C G  ');
    ts.post(MeasureEditType.append, 'V:1', '[F F C C ] x3');

    ts.startingChords('I:  V:  ');
    ts.edit(MeasureEditType.append, 'V:', 'V: []', 'Dm ');
    ts.resultChords('I: []  V: Dm  ');
    ts.post(MeasureEditType.append, 'V:0:0', 'Dm');

    ts.startingChords('I:  V:  ');
    ts.edit(MeasureEditType.replace, 'V:', 'V: []', 'Dm ');
    ts.resultChords('I: []  V: Dm  ');
    ts.post(MeasureEditType.append, 'V:0:0', 'Dm');

    ts.startingChords('V: C F F C C F F C C G F C G  ');
    ts.edit(MeasureEditType.delete, 'V:', 'V: C F F C, C F F C, C G F C, G ', null);
    ts.resultChords('');
    ts.post(MeasureEditType.append, 'V:', null);

    ts.startingChords('V: C F C C F F C C G F C G  ');
    ts.edit(MeasureEditType.append, 'V:0:11', 'G', '- ');
    ts.resultChords('V: C F C C, F F C C, G F C G G  ');
    ts.post(MeasureEditType.append, 'V:0:12', 'G');

    ts.startingChords('V: C F C C F F C C G F C G G  ');
    ts.edit(MeasureEditType.append, 'V:0:1', 'F', '-');
    ts.resultChords('V: C F F C C, F F C C, G F C G, G  ');
    ts.post(MeasureEditType.append, 'V:0:2', 'F');

    ts.startingChords('V: C F F C C F F C C G F C G G  ');
    ts.edit(MeasureEditType.append, 'V:0:2', 'F', '  -  ');
    ts.resultChords('V: C F F F C, C F F C, C G F C, G G  ');
    ts.post(MeasureEditType.append, 'V:0:3', 'F');

    ts.startingChords('V: C F C C F F C C G F C G  ');
    ts.edit(MeasureEditType.append, 'V:0:1', 'F', '-');
    ts.resultChords('V: C F F C C, F F C C, G F C G  ');
    ts.post(MeasureEditType.append, 'V:0:2', 'F');

    ts.startingChords('I:  V:  ');
    ts.edit(MeasureEditType.append, 'V:', 'V: []', 'T: ');
    ts.resultChords('I: []  V: []  T: [] '); //  fixme: why is this?
    ts.post(MeasureEditType.append, 'T:', 'T: [] ');

    ts.startingChords('V: C F C C F F C C [G F C G ] x4  ');
    ts.edit(MeasureEditType.replace, 'V:1', '[G F C G ] x4 ', 'B ');
    ts.resultChords('V: C F C C F F C C, B  ');
    //               0 1 2 3 4 5 6 7 8
    ts.post(MeasureEditType.append, 'V:0:8', 'B');

    //  insert into a repeat
    ts.startingChords('V: [C F C C ] x2 F F C C G F C G  ');
    ts.edit(MeasureEditType.insert, 'V:0:1', 'F', 'Dm ');
    ts.resultChords('V: [C Dm F C C ] x2 F F C C G F C G  ');
    ts.post(MeasureEditType.append, 'V:0:1', 'Dm');

    //  append into the middle
    ts.startingChords('V: C Dm C C F F C C G F C G  ');
    ts.edit(MeasureEditType.append, 'V:0:1', 'Dm', 'Em ');
    ts.resultChords('V: C Dm Em C C, F F C C, G F C G  ');
    ts.post(MeasureEditType.append, 'V:0:2', 'Em');

    //  replace second measure
    ts.startingChords('V: C F C C F F C C G F C G  '); //
    ts.edit(MeasureEditType.replace, 'V:0:1', 'F', 'Dm '); //
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
        _a.currentMeasureEditType.toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    newPhrase = Phrase.parseString('Db C B A', 0, beatsPerBar, null);
    expect(_a.editMeasureNode(newPhrase), isTrue);
    logger.d(_a.toMarkup());
    expect(_a.toMarkup().trim(), TestSong.deMusic('I: A B C D D♭ C B A  V: D E F F♯  C: D C G G'));
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
    logger.i(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.currentMeasureEditType.toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    newRepeat = MeasureRepeat.parseString('[]x1', 0, beatsPerBar, null);
    expect(_a.editMeasureNode(newRepeat), isTrue);
    logger.d(_a.toMarkup());
    expect(
      _a.toMarkup().trim(),
      'V: C F C C, GB F C Dm7, G F C G',
    );
    //                        0 1 2 3 4  5 6 7   8 9 0 1
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(_a.getCurrentChordSectionLocation().toString(), 'V:0:7');
    expect(_a.getCurrentMeasureNode()!.toMarkup(), 'Dm7,');

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
        _a.currentMeasureEditType.toString() +
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
        _a.currentMeasureEditType.toString() +
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
        _a.currentMeasureEditType.toString() +
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
        _a.currentMeasureEditType.toString() +
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
        _a.currentMeasureEditType.toString() +
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
        _a.currentMeasureEditType.toString() +
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
        _a.currentMeasureEditType.toString() +
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
        _a.currentMeasureEditType.toString() +
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
        _a.currentMeasureEditType.toString() +
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
        _a.currentMeasureEditType.toString() +
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
        _a.currentMeasureEditType.toString() +
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
        _a.currentMeasureEditType.toString() +
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
        _a.currentMeasureEditType.toString() +
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
        _a.currentMeasureEditType.toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(_a.editMeasureNode(ChordSection.parseString('v: A D C D', beatsPerBar)), isTrue);
    logger.d(_a.toMarkup());
    expect(_a.toMarkup().trim(), TestSong.deMusic('V: D E F F♯  C: D C G G'));
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
        _a.currentMeasureEditType.toString() +
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
        _a.currentMeasureEditType.toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    _a.setCurrentMeasureEditType(MeasureEditType.delete);
    expect(_a.deleteCurrentSelection(), isTrue);
    logger.d(_a.toMarkup());
    expect(_a.toMarkup().trim(), TestSong.deMusic('I: A B C D  V: D E F F♯  C: D C G G'));
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
        _a.currentMeasureEditType.toString() +
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
        _a.currentMeasureEditType.toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(_a.deleteCurrentSelection(), isTrue);
    logger.d(_a.toMarkup());
    expect(_a.toMarkup().trim(), TestSong.deMusic('I: A B C D  V: D F F♯ [D C B A ] x2  C: D C G G'));
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
        _a.currentMeasureEditType.toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    newRepeat = MeasureRepeat.parseString('[ A D C D ] x3', 0, beatsPerBar, null);
    expect(_a.editMeasureNode(newRepeat), isTrue);
    logger.d(_a.toMarkup());
    expect(_a.toMarkup().trim(), TestSong.deMusic('I: A B C D  V: D E F F♯ [A D C D ] x3  C: D C G G'));
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
        _a.currentMeasureEditType.toString() +
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
        _a.currentMeasureEditType.toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    newRepeat = MeasureRepeat.parseString('[] x1', 0, beatsPerBar, null);
    expect(_a.editMeasureNode(newRepeat), isTrue);
    logger.d(_a.toMarkup());
    expect(_a.toMarkup().trim(), TestSong.deMusic('I: A B C D  V: D E F F♯  C: D C G G'));
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
        _a.currentMeasureEditType.toString() +
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
        _a.currentMeasureEditType.toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    newRepeat = MeasureRepeat.parseString('[ ] x3', 0, beatsPerBar, null);
    expect(_a.editMeasureNode(newRepeat), isTrue);
    logger.d(_a.toMarkup());
    expect(_a.toMarkup().trim(), TestSong.deMusic('I: A B C D  V: [D E F F♯ ] x3  C: D C G G'));
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
        _a.currentMeasureEditType.toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    newRepeat = MeasureRepeat.parseString('[ D C G G] x3', 0, beatsPerBar, null);
    expect(_a.editMeasureNode(newRepeat), isTrue);
    logger.d(_a.toMarkup());
    expect(_a.toMarkup().trim(), TestSong.deMusic('I: A B C D  V: D E F F♯ [D C G G ] x3  C: D C G G'));
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
    logger.i(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.findMeasureNodeByLocation(_a.getCurrentChordSectionLocation()).toString() +
        ' ' +
        _a.currentMeasureEditType.toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    newMeasure = Measure.parseString('Gm', beatsPerBar);
    expect(_a.editMeasureNode(newMeasure), isTrue);
    logger.i(_a.toMarkup());
    expect(_a.toMarkup().trim(), TestSong.deMusic('I: A B C D  V: D E Gm F F♯ [A D C D ] x3  C: D C G G'));
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
        _a.currentMeasureEditType.toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(_a.deleteCurrentSelection(), isTrue);
    logger.d(_a.toMarkup());
    expect(_a.toMarkup().trim(), TestSong.deMusic('I: A B C D  V: D E F♯  C: D C G G'));
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
        _a.currentMeasureEditType.toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(_a.deleteCurrentSelection(), isTrue);
    logger.d(_a.toMarkup());
    expect(_a.toMarkup().trim(), TestSong.deMusic('I: A B C D  V: D E F♯  C: D C G G'));
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
        _a.currentMeasureEditType.toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    newMeasure = Measure.parseString('F', beatsPerBar);
    expect(_a.editMeasureNode(newMeasure), isTrue);
    logger.d(_a.toMarkup());
    expect(_a.toMarkup().trim(), TestSong.deMusic('I: A B C D  V: D E F♯  C: D C G G'));
    logger.d(_a.getCurrentChordSectionLocation().toString() +
        ' ' +
        _a.getCurrentChordSectionLocationMeasureNode().toString());
    expect(location, _a.getCurrentChordSectionLocation());
  });

  test('test last modified time after an edit', () {
    int now = DateTime.now().millisecondsSinceEpoch;
    logger.d('now: $now');

    int beatsPerBar = 4;

    //  assure that the song can end on an empty section
    _a = SongBase.createSongBase('12 Bar Blues', 'All', 'Unknown', Key.get(KeyEnum.C), 106, beatsPerBar, 4,
        'V: C F C C,F F C C,  G F C G', 'v:');
    logger.d('a.lastModifiedTime: ${_a.lastModifiedTime}');
    int t0 = _a.lastModifiedTime;
    expect(now <= _a.lastModifiedTime, isTrue);
    now = DateTime.now().millisecondsSinceEpoch;
    logger.d('now: $now');
    expect(now >= _a.lastModifiedTime, isTrue);

    ts.startingChords('I: A G D  V: D C G G  V1: Dm  V2: Em  PC: D C G D  C: F7 G7 G Am  ');
    ts.edit(MeasureEditType.delete, 'I:0:1', 'G', 'null');
    int t1 = _a.lastModifiedTime;
    expect(t0 <= t1, isTrue);
    ts.resultChords('I: A D  V: D C G G  V1: Dm  V2: Em  PC: D C G D  C: F7 G7 G Am  ');
    ts.post(MeasureEditType.delete, 'I:0:1', 'D');
    now = DateTime.now().millisecondsSinceEpoch;
    logger.d('t1: $t1');
    logger.d('now: $now');
    expect(now >= t1, isTrue);
    expect(t1 == _a.lastModifiedTime, isTrue);
  });

  test('test edit around a repeat', () {
    //  insert repeat prior to first repeat
    ts.startingChords('i: [A B C D] x4');
    ts.edit(MeasureEditType.insert, 'I:0', null, '[A A A A] x2 ');
    ts.resultChords('I: [A A A A ] x2 [A B C D ] x4 ');
    ts.post(MeasureEditType.append, 'I:0', '[A A A A ] x2');

    //  insert repeat prior to first repeat of many
    ts.startingChords('i: [A B C D] x4 [ D C G G ] x3');
    ts.edit(MeasureEditType.insert, 'I:0', null, '[A A A A] x2');
    ts.resultChords('I: [A A A A ] x2 [A B C D ] x4 [D C G G ] x3');
    ts.post(MeasureEditType.append, 'I:0', '[A A A A ] x2');

    //  append repeat after repeat
    ts.startingChords('i: [A B C D] x4');
    ts.edit(MeasureEditType.append, 'I:0', null, '[G G G G] x2');
    ts.resultChords('I: [A B C D ] x4 [G G G G ] x2 ');
    ts.post(MeasureEditType.append, 'I:1', '[G G G G ] x2');

    //  append measure to the end of a repeat
    ts.startingChords('i: [A B C D] x4');
    ts.edit(MeasureEditType.append, null, null, 'G');
    ts.resultChords('I: [A B C D G ] x4 ');
    ts.post(MeasureEditType.append, 'I:0:4', 'G');

    //  insert phrase prior to first repeat
    ts.startingChords('i: [A B C D] x4');
    ts.edit(MeasureEditType.insert, 'I:0', null, 'E');
    ts.resultChords('I: E [A B C D ] x4 ');
    ts.post(MeasureEditType.append, 'I:0:0', 'E');

    //  insert phrase prior to first repeat of many
    ts.startingChords('i: [A B C D] x4 [ D C G G ] x3');
    ts.edit(MeasureEditType.insert, 'I:0', null, 'E');
    ts.resultChords('I: E [A B C D ] x4 [D C G G ] x3');
    ts.post(MeasureEditType.append, 'I:0:0', 'E');

    //  insert measure on first repeat
    ts.startingChords('i: [A B C D] x4');
    ts.edit(MeasureEditType.insert, 'I:0:0', null, 'G');
    ts.resultChords('I: [G A B C D ] x4 ');
    ts.post(MeasureEditType.append, 'I:0:0', 'G');
    var lastLocation = _a.findLastChordSectionLocation(
        _a.findChordSectionBySectionVersion(SectionVersion.bySection(Section.get(SectionEnum.intro))));
    logger.d('lastChordSectionLocation: $lastLocation');
    expect(lastLocation.toString(), 'I:0:4');

    //  append phrase after repeat
    ts.startingChords('i: [A B C D] x4 G');
    ts.edit(MeasureEditType.append, 'I:1:0', null, 'A');
    logger.d('_a.currentChordSectionLocation ${_a.currentChordSectionLocation}');
    ts.resultChords('I: [A B C D ] x4 G A');
    ts.post(MeasureEditType.append, 'I:1:1', 'A');

    //  append phrase after repeat, assure the phrase index works!
    ts.startingChords('i: [A B C D] x4');
    ts.edit(MeasureEditType.append, 'I:0', null, 'G');
    logger.d('_a.currentChordSectionLocation ${_a.currentChordSectionLocation}');
    ts.resultChords('I: [A B C D ] x4 G ');
    ts.post(MeasureEditType.append, 'I:1:0', 'G');
    logger.d('_a.currentChordSectionLocation ${_a.currentChordSectionLocation}');
    ts.edit(MeasureEditType.append, 'I:1:0', null, 'A');
    logger.d('_a.currentChordSectionLocation ${_a.currentChordSectionLocation}');
    ts.resultChords('I: [A B C D ] x4 G A');
    ts.post(MeasureEditType.append, 'I:1:1', 'A');

    //  append measure to the end of a repeat
    ts.startingChords('i: [A B C D] x4');
    ts.edit(MeasureEditType.append, null, null, 'G');
    ts.resultChords('I: [A B C D G ] x4 ');
    ts.post(MeasureEditType.append, 'I:0:4', 'G');

    //  append measure to the end of a second repeat
    ts.startingChords('i: [A B C D] x4 [E F G] x4');
    ts.edit(MeasureEditType.append, 'I:1:2', null, 'Ab');
    ts.resultChords('I: [A B C D ] x4 [E F G Ab ] x4 ');
    ts.post(MeasureEditType.append, 'I:1:3', 'Ab');

    //  from 20211124_155238
    ts.startingChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2 Am,  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.replace, 'I2:1:0', 'Am', SongBase.entryToUppercase('X ')); // endOfRow: true
    ts.resultChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2 X  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'I2:1:0', 'X'); // endOfRow: true
  });

  test('test edit in a repeat', () {
    //  insert repeat prior to first repeat
    for (var repeats = 2; repeats < 5; repeats++) {
      for (var measureIndex = 0; measureIndex < 4; measureIndex++) {
        ts.startingChords('V: C F C C [C7 A B C, Cm F C C ] x4 G F C G');
        ts.setRepeat(
            ChordSectionLocation(SectionVersion.bySection(Section.get(SectionEnum.verse)),
                phraseIndex: 0, measureIndex: measureIndex),
            repeats);
        ts.resultChords('V: [C F C C ] x$repeats [C7 A B C, Cm F C C ] x4 G F C G');
      }
    }

    //  adjust a repeat from within a repeat
    for (var repeats = 2; repeats < 5; repeats++) {
      for (var measureIndex = 0; measureIndex < 8; measureIndex++) {
        ts.startingChords('V: C F C C [C7 A B C, Cm F C C ] x4 G F C G');
        ts.setRepeat(
            ChordSectionLocation(SectionVersion.bySection(Section.get(SectionEnum.verse)),
                phraseIndex: 1, measureIndex: measureIndex),
            repeats);
        ts.resultChords('V: C F C C [C7 A B C, Cm F C C ] x$repeats G F C G');
      }
    }

    // adjust a repeat from within a repeat
    ts.startingChords('V: C F C C [C7 A B C, Cm F C C ] x4 G F C G');
    ts.edit(MeasureEditType.replace, 'V:1:0', 'C7', 'Abm7/G');
    ts.resultChords('V: C F C C [Abm7/G A B C, Cm F C C ] x4 G F C G');

    ts.startingChords('V: C F C C [C7 A B C, Cm F C C ] x4 G F C G');
    ts.edit(MeasureEditType.replace, 'V:1:0', 'C7', 'Abm7/G, D E');
    ts.resultChords('V: C F C C [Abm7/G, D E A B C, Cm F C C ] x4 G F C G');

    //  include a new row
    ts.startingChords('V: C F C C [C7 A B C, Cm F C C ] x4 G F C G');
    ts.edit(MeasureEditType.replace, 'V:1:0', 'C7', 'Abm7/G, D E,');
    ts.resultChords('V: C F C C [Abm7/G, D E, A B C, Cm F C C ] x4 G F C G');
  });

  test('test edit at end of section', () {
    //  append after end of section
    ts.startingChords('i: A B C D');
    ts.edit(MeasureEditType.append, 'I:0', null, 'X');
    ts.resultChords('I: A B C D, X ');
    ts.post(MeasureEditType.append, 'I:0:4', 'X ');
  });

  test('test edit insert measure near front of a section', () {
    ts.startingChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, Ab  ');
    ts.edit(MeasureEditType.insert, 'I:0:0', 'Am', SongBase.entryToUppercase('A'));
    ts.resultChords(
        'I: V: [A Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, Ab');
    ts.post(MeasureEditType.append, 'I:0:0', 'A');

    ts.startingChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, Ab  ');
    ts.edit(MeasureEditType.insert, 'I:0', '[Am Am/G Am/F# FE ] x4', SongBase.entryToUppercase('A'));
    ts.resultChords(
        'I: V: A [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, Ab');
    ts.post(MeasureEditType.append, 'I:0:0', 'A');

    ts.startingChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, Ab  ');
    ts.edit(MeasureEditType.insert, 'I:', 'I: [Am Am/G Am/F# FE ] x4', SongBase.entryToUppercase('A'));
    ts.resultChords(
        'I: V: A [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, Ab');
    ts.post(MeasureEditType.append, 'I:0:0', 'A');

    //  from 20211106_025839
    ts.startingChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.insert, 'I:', 'I: [Am Am/G Am/F# FE ] x4 ', SongBase.entryToUppercase('C.CmC7'));
    ts.resultChords(
        'I: V: C.CmC7 [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'I:0:0', 'C.CmC7');
  });

  test('test edit from edit screen log', () {
    ts.startingChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.replace, 'I:0:2', 'Am/F#', SongBase.entryToUppercase('Cm '));
    ts.resultChords('I: V: [Am Am/G Cm FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'I:0:2', 'Cm');

    //  from 20211105_184124
    ts.startingChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.append, 'I:0:3', 'FE', SongBase.entryToUppercase('C '));
    ts.resultChords(
        'I: V: [Am Am/G Am/F# FE C ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'I:0:4', 'C');
    //  from 20211105_184126
    ts.startingChords(
        'I: V: [Am Am/G Am/F# FE, C ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.append, 'I:0:4', 'C', SongBase.entryToUppercase('Cm '));
    ts.resultChords(
        'I: V: [Am Am/G Am/F# FE, C Cm ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'I:0:5', 'Cm');
    //  from 20211105_184128
    ts.startingChords(
        'I: V: [Am Am/G Am/F# FE, C Cm ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.append, 'I:0:5', 'Cm', SongBase.entryToUppercase('C7 '));
    ts.resultChords(
        'I: V: [Am Am/G Am/F# FE, C Cm C7 ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'I:0:6', 'C7');
    //  from 20211105_184143
    ts.startingChords(
        'I: V: [Am Am/G Am/F# FE, C Cm C7 ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.append, 'I:0:6', 'C7', SongBase.entryToUppercase('D '));
    ts.resultChords(
        'I: V: [Am Am/G Am/F# FE, C Cm C7 D ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'I:0:7', 'D');
    //  from 20211105_184242
    ts.startingChords(
        'I: V: [Am Am/G Am/F# FE, C Cm C7 D ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.insert, 'C:0:0', 'F', SongBase.entryToUppercase('A '));
    ts.resultChords(
        'I: V: [Am Am/G Am/F# FE, C Cm C7 D ] x4  I2: [Am Am/G Am/F# FE ] x2  C: A F F C C G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'C:0:0', 'A');

    //  from 20211105_235654
    ts.startingChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.replace, 'I:0:0', 'Am', SongBase.entryToUppercase('CCm '));
    ts.resultChords(
        'I: V: [CCm Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'I:0:0', 'CCm');

    //  from 20211105_235808
    ts.startingChords(
        'I: V: [CCm Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.replace, 'I:0:3', 'FE', SongBase.entryToUppercase('Absus7/G '));
    ts.resultChords(
        'I: V: [CCm Am/G Am/F# Absus7/G ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'I:0:3', 'Absus7/G');

    //  from 20211105_235921
    ts.startingChords(
        'I: V: [CCm Am/G, Am/F# Absus7/G ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.append, 'I:0:3', 'Absus7/G', SongBase.entryToUppercase('Cm '));
    ts.resultChords(
        'I: V: [CCm Am/G, Am/F# Absus7/G Cm ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'I:0:4', 'Cm');
    //  from 20211106_000018
    ts.startingChords(
        'I: V: [CCm Am/G, Am/F# Absus7/G Cm ] x2  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.insert, 'I:0:0', 'CCm', SongBase.entryToUppercase('A '));
    ts.resultChords(
        'I: V: [A CCm Am/G, Am/F# Absus7/G Cm ] x2  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'I:0:0', 'A');
    //  from 20211106_000044
    ts.startingChords(
        'I: V: [A CCm Am/G, Am/F# Absus7/G Cm ] x2  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.append, 'I2:0:3', 'FE', SongBase.entryToUppercase('C7 '));
    ts.resultChords(
        'I: V: [A CCm Am/G, Am/F# Absus7/G Cm ] x2  I2: [Am Am/G Am/F# FE C7 ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'I2:0:4', 'C7');
    //  from 20211106_000047
    ts.startingChords(
        'I: V: [A CCm Am/G, Am/F# Absus7/G Cm ] x2  I2: [Am Am/G Am/F# FE, C7 ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.append, 'I2:0:4', 'C7', SongBase.entryToUppercase('C '));
    ts.resultChords(
        'I: V: [A CCm Am/G, Am/F# Absus7/G Cm ] x2  I2: [Am Am/G Am/F# FE, C7 C ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'I2:0:5', 'C');
    //  from 20211106_000056
    ts.startingChords(
        'I: V: [A CCm Am/G, Am/F# Absus7/G Cm ] x2  I2: [Am Am/G Am/F# FE, C7 C ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.append, 'I2:0:5', 'C', SongBase.entryToUppercase('Gm7 '));
    ts.resultChords(
        'I: V: [A CCm Am/G, Am/F# Absus7/G Cm ] x2  I2: [Am Am/G Am/F# FE, C7 C Gm7 ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'I2:0:6', 'Gm7');
    //  from 20211106_000107
    ts.startingChords(
        'I: V: [A CCm Am/G, Am/F# Absus7/G Cm ] x2  I2: [Am Am/G Am/F# FE, C7 C Gm7 ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.append, 'I2:0:6', 'Gm7', SongBase.entryToUppercase('A5 '));
    ts.resultChords(
        'I: V: [A CCm Am/G, Am/F# Absus7/G Cm ] x2  I2: [Am Am/G Am/F# FE, C7 C Gm7 A5 ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'I2:0:7', 'A5');
    //  from 20211106_000148
    ts.startingChords(
        'I: V: [A CCm Am/G, Am/F# Absus7/G Cm ] x2  I2: [Am Am/F# FE, C7 C Gm7 A5 ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.replace, 'C:0:1', 'F', SongBase.entryToUppercase('Cm '));
    ts.resultChords(
        'I: V: [A CCm Am/G, Am/F# Absus7/G Cm ] x2  I2: [Am Am/F# FE, C7 C Gm7 A5 ] x2  C: F Cm C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'C:0:1', 'Cm');
    //  from 20211106_000156
    ts.startingChords(
        'I: V: [A CCm Am/G, Am/F# Absus7/G Cm ] x2  I2: [Am Am/F# FE, C7 C Gm7 A5 ] x2  C: F Cm C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.insert, 'C:0:0', 'F', SongBase.entryToUppercase('C7 '));
    ts.resultChords(
        'I: V: [A CCm Am/G, Am/F# Absus7/G Cm ] x2  I2: [Am Am/F# FE, C7 C Gm7 A5 ] x2  C: C7 F Cm C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'C:0:0', 'C7');
    //  from 20211106_000219
    ts.startingChords(
        'I: V: [A CCm Am/G, Am/F# Absus7/G Cm ] x2  I2: [Am Am/F# FE, C7 C Gm7 A5 ] x2  C: C7 F Cm C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.replace, 'C:0:7', 'F', SongBase.entryToUppercase('Gb '));
    ts.resultChords(
        'I: V: [A CCm Am/G, Am/F# Absus7/G Cm ] x2  I2: [Am Am/F# FE, C7 C Gm7 A5 ] x2  C: C7 F Cm C, G G F Gb  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'C:0:7', 'Gb');
    //  from 20211106_000231
    ts.startingChords(
        'I: V: [A CCm Am/G, Am/F# Absus7/G Cm ] x2  I2: [Am Am/F# FE, C7 C Gm7 A5 ] x2  C: C7 F Cm C, G G F Gb  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.append, 'C:0:7', 'Gb', SongBase.entryToUppercase('X '));
    ts.resultChords(
        'I: V: [A CCm Am/G, Am/F# Absus7/G Cm ] x2  I2: [Am Am/F# FE, C7 C Gm7 A5 ] x2  C: C7 F Cm C, G G F Gb X  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'C:0:8', 'X');
    //  from 20211106_000231
    ts.startingChords(
        'I: V: [A CCm Am/G, Am/F# Absus7/G Cm ] x2  I2: [Am Am/F# FE, C7 C Gm7 A5 ] x2  C: C7 F Cm C, G G F Gb, X  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.append, 'C:0:8', 'X', SongBase.entryToUppercase('X '));
    ts.resultChords(
        'I: V: [A CCm Am/G, Am/F# Absus7/G Cm ] x2  I2: [Am Am/F# FE, C7 C Gm7 A5 ] x2  C: C7 F Cm C, G G F Gb, X X  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'C:0:9', 'X');
    //  from 20211106_000244
    ts.startingChords(
        'I: V: [A CCm Am/G, Am/F# Absus7/G Cm ] x2  I2: [Am Am/F# FE, C7 C Gm7 A5 ] x2  C: C7 F Cm C, G G F Gb, X X  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.append, 'C:0:9', 'X', SongBase.entryToUppercase('B '));
    ts.resultChords(
        'I: V: [A CCm Am/G, Am/F# Absus7/G Cm ] x2  I2: [Am Am/F# FE, C7 C Gm7 A5 ] x2  C: C7 F Cm C, G G F Gb, X X B  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'C:0:10', 'B');
    //  from 20211106_000248
    ts.startingChords(
        'I: V: [A CCm Am/G, Am/F# Absus7/G Cm ] x2  I2: [Am Am/F# FE, C7 C Gm7 A5 ] x2  C: C7 F Cm C, G G F Gb, X X B  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.append, 'C:0:10', 'B', SongBase.entryToUppercase('C '));
    ts.resultChords(
        'I: V: [A CCm Am/G, Am/F# Absus7/G Cm ] x2  I2: [Am Am/F# FE, C7 C Gm7 A5 ] x2  C: C7 F Cm C, G G F Gb, X X B C  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'C:0:11', 'C');

    //  append a phrase after a repeat
    ts.startingChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.append, 'I:0', '[Am Am/G Am/F# FE ] x4 ', SongBase.entryToUppercase('C7'));
    ts.resultChords(
        'I: V: [Am Am/G Am/F# FE ] x4 C7  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'I:1:0', 'C7');

    //  append a phrase after a repeat
    ts.startingChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.append, 'I:0', '[Am Am/G Am/F# FE ] x4 ', SongBase.entryToUppercase('C7 A b c'));
    ts.resultChords(
        'I: V: [Am Am/G Am/F# FE ] x4 C7 A B C  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'I:1:3', 'C');

    //  append a phrase after a section that ends in a repeat
    ts.startingChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.append, 'I:', 'I: [Am Am/G Am/F# FE ] x4 ', SongBase.entryToUppercase('C7'));
    ts.resultChords(
        'I: V: [Am Am/G Am/F# FE ] x4 C7  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'I:1:0', 'C7');

    //  append a phrase after a section that ends in a repeat
    ts.startingChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.append, 'I:', 'I: [Am Am/G Am/F# FE ] x4 ', SongBase.entryToUppercase('C7 A b c9'));
    ts.resultChords(
        'I: V: [Am Am/G Am/F# FE ] x4 C7 A B C9  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'I:1:3', 'C9');

    ts.startingChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.replace, 'I:0:1', 'Am/G', SongBase.entryToUppercase('C '));
    ts.resultChords('I: V: [Am C Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'I:0:1', 'C');

    //  from 20211108_055955
    ts.startingChords(
        'I: V: C [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.insert, 'I:1:0', 'Am', SongBase.entryToUppercase('F '));
    ts.resultChords(
        'I: V: C [F Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'I:1:0', 'F');

    //  from 20211118_182608
    ts.startingChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.replace, 'O:0:3', 'Bb,', SongBase.entryToUppercase('Bb,'));
    ts.resultChords('I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'O:0:3', 'Bb,');

    //  insert measure at start of repeat at start of section
    ts.startingChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.insert, 'V:0:0', 'Am', SongBase.entryToUppercase('D'));
    ts.resultChords(
        'I: V: [D Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'V:0:0', 'D');

    //  insert measure before repeat at start of section
    ts.startingChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.insert, 'V:', 'V: [Am Am/G Am/F# FE ] x4', SongBase.entryToUppercase('D'));
    ts.resultChords(
        'I: V: D [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'V:0:0', 'D');

    //  insert measure before repeat at start of section
    ts.startingChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.insert, 'V:0', '[Am Am/G Am/F# FE ] x4', SongBase.entryToUppercase('D'));
    ts.resultChords(
        'I: V: D [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'V:0:0', 'D');

    //  insert measure before phrase at start of section
    ts.startingChords('I: V: Am Am/G Am/F# FE I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.insert, 'V:0', 'Am Am/G Am/F# FE ', SongBase.entryToUppercase('D'));
    ts.resultChords('I: V: D Am Am/G Am/F# FE  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'V:0:0', 'D');

    //  insert measure before phrase at start of section
    ts.startingChords('I: V: Am Am/G Am/F# FE I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.insert, 'V:0', 'Am Am/G Am/F# FE ', SongBase.entryToUppercase('D'));
    ts.resultChords('I: V: D Am Am/G Am/F# FE  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'V:0:0', 'D');

    //  add new row
    ts.myA.setChordSectionLocationMeasureEndOfRow(ts.myA.currentChordSectionLocation, true);
    expect(
        ts.myA.toMarkup().trim(),
        TestSong.deMusic(
                'I: V: D, Am Am/G Am/F# FE  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ')!
            .trim());

    //  from 20211123_004759
    ts.startingChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.append, 'C:0:0', 'F', SongBase.entryToUppercase('X '));
    ts.resultChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F X F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'C:0:1', 'X');

    //  from 20211123_155557
    ts.startingChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: C C7 Cm C, X G G F F  Br: []  T: []  O: Dm C B Bb, Bb, A  ');
    ts.edit(MeasureEditType.replace, 'O:0:4', 'Bb,', SongBase.entryToUppercase('C7, '));
    ts.resultChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: C C7 Cm C, X G G F F  Br: []  T: []  O: Dm C B Bb, C7, A  ');
    ts.post(MeasureEditType.append, 'O:0:4', 'C7,');

    //  from 20211124_142104
    ts.startingChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.append, 'I2:0', '[Am Am/G Am/F# FE ] x2', SongBase.entryToUppercase('C7 '));
    ts.resultChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2 C7  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'I2:1:0', 'C7');

    //  from 20211124_142104
    ts.startingChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2 Am  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.edit(MeasureEditType.replace, 'I2:1:0', 'Am', SongBase.entryToUppercase('C7 '));
    ts.resultChords(
        'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2 C7  C: F F C C, G G F F  O: Dm C B Bb, A  ');
    ts.post(MeasureEditType.append, 'I2:1:0', 'C7');
  });
}
