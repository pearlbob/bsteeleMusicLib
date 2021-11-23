import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/chord.dart';
import 'package:bsteeleMusicLib/songs/chordSectionLocation.dart';
import 'package:bsteeleMusicLib/songs/key.dart';
import 'package:bsteeleMusicLib/songs/measure.dart';
import 'package:bsteeleMusicLib/songs/measureNode.dart';
import 'package:bsteeleMusicLib/songs/song.dart';
import 'package:bsteeleMusicLib/songs/songEditManager.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('test edit manager appends', () {
    const bool all = true;

    if (all) {
      ChordSectionLocation? location;
      Song a = Song.createSong(
          'A',
          'bob',
          'copyright bsteele.com',
          Key.getDefault(),
          100,
          4,
          4,
          'bob',
          'i: A B C D, D C G G v: E F G G o: G G G G',
          'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
      var manager = SongEditManager(a);
      var safeCopySong = a.copySong();
      Song b;

      logger.d('a.chords: \'${a.toMarkup()}\'');

      expect(a.toMarkup(), safeCopySong.toMarkup());
      b = manager.preEdit(EditPoint.defaultInstance);
      expect(b.toMarkup(), safeCopySong.toMarkup());
      location = ChordSectionLocation.fromString('v:0:1');
      b = manager.preEdit(EditPoint(location));
      expect(b.toMarkup(), safeCopySong.toMarkup());
      b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.delete));
      expect(b.toMarkup(), safeCopySong.toMarkup());
      b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.replace));
      expect(b.toMarkup(), safeCopySong.toMarkup());
      location = ChordSectionLocation.fromString('v:0:1');
      b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.insert));
      expect(b.toMarkup(), 'I: A B C D, D C G G  V: E F F G G  O: G G G G  ');
      expect(manager.editPoint.location, location);
      expect(manager.reset().toMarkup(), 'I: A B C D, D C G G  V: E F G G  O: G G G G  ');
      expect(manager.editPoint.location, location);
    }

    if (all) {
      //  basic measure append
      var a = Song.createSong('A', 'bob', 'copyright bsteele.com', Key.getDefault(), 100, 4, 4, 'bob',
          'v: A B C D, D C G G ', 'v: bob, bob, bob berand');
      var safeCopySong = a.copySong();
      var manager = SongEditManager(a.copySong());
      expect(manager.reset().toMarkup(), 'V: A B C D, D C G G  ');
      var location = ChordSectionLocation.fromString('v:0:1');
      var b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.append));
      expect(b.toMarkup(), 'V: A B B C D, D C G G  ');
      expect(manager.editPoint.location, ChordSectionLocation.fromString('v:0:2'));
      expect(a.toMarkup(), safeCopySong.toMarkup());
      expect(manager.reset().toMarkup(), safeCopySong.toMarkup());

      //  measure append at end of row, with extension
      manager = SongEditManager(a.copySong());
      location = ChordSectionLocation.fromString('v:0:3');
      b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.append, onEndOfRow: false));
      expect(b.toMarkup(), 'V: A B C D D, D C G G  ');
      expect(manager.editPoint.location, ChordSectionLocation.fromString('v:0:4'));
      expect(a.toMarkup(), safeCopySong.toMarkup());

      //  measure append at end of row, with new row
      manager = SongEditManager(a.copySong());
      location = ChordSectionLocation.fromString('v:0:3');
      b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.append, onEndOfRow: true));
      expect(b.toMarkup(), 'V: A B C D, D, D C G G  ');
      expect(manager.editPoint.location, ChordSectionLocation.fromString('v:0:4'));
      expect(a.toMarkup(), safeCopySong.toMarkup());
    }

    //  measure append in middle of row, with extension of repeat in the middle of the repeat
    if (all) {
      var a = Song.createSong('A', 'bob', 'copyright bsteele.com', Key.getDefault(), 100, 4, 4, 'bob',
          'v: A B C D, [D C G G] x2 ', 'v: bob, bob, bob berand');
      var safeCopySong = a.copySong();
      var manager = SongEditManager(a.copySong());
      expect(manager.reset().toMarkup(), 'V: A B C D [D C G G ] x2  ');
      var location = ChordSectionLocation.fromString('v:1:1');
      var b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.append));
      expect(b.toMarkup(), 'V: A B C D [D C C G G ] x2  ');
      expect(manager.editPoint.location, ChordSectionLocation.fromString('v:1:2'));
      expect(a.toMarkup(), safeCopySong.toMarkup());
      expect(manager.reset().toMarkup(), safeCopySong.toMarkup());
    }

    //  measure append in middle of row, with new row of repeat in the middle of the repeat
    if (all) {
      var a = Song.createSong('A', 'bob', 'copyright bsteele.com', Key.getDefault(), 100, 4, 4, 'bob',
          'v: A B C D, [D C G G] x2 ', 'v: bob, bob, bob berand');
      var safeCopySong = a.copySong();
      var manager = SongEditManager(a.copySong());
      expect(manager.reset().toMarkup(), 'V: A B C D [D C G G ] x2  ');
      var location = ChordSectionLocation.fromString('v:1:1');
      var b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.append, onEndOfRow: true));
      expect(b.toMarkup(), 'V: A B C D [D C, C, G G ] x2  ');
      expect(manager.editPoint.location, ChordSectionLocation.fromString('v:1:2'));
      expect(a.toMarkup(), safeCopySong.toMarkup());
      expect(manager.reset().toMarkup(), safeCopySong.toMarkup());
    }

    //  measure append at end of row, with extension of repeat in the middle of the repeat
    if (all) {
      var a = Song.createSong('A', 'bob', 'copyright bsteele.com', Key.getDefault(), 100, 4, 4, 'bob',
          'v: A B C D, [D C G G, G E C D] x2 ', 'v: bob, bob, bob berand');
      var safeCopySong = a.copySong();
      var manager = SongEditManager(a.copySong());
      expect(manager.reset().toMarkup(), 'V: A B C D [D C G G, G E C D ] x2  ');
      var location = ChordSectionLocation.fromString('v:1:3');
      var b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.append, onEndOfRow: false));
      expect(b.toMarkup(), 'V: A B C D [D C G G G, G E C D ] x2  ');
      expect(manager.editPoint.location, ChordSectionLocation.fromString('v:1:4'));
      expect(a.toMarkup(), safeCopySong.toMarkup());
      expect(manager.reset().toMarkup(), safeCopySong.toMarkup());
    }

    //  measure append at end of row, with new row of repeat in the middle of the repeat
    if (all) {
      var a = Song.createSong('A', 'bob', 'copyright bsteele.com', Key.getDefault(), 100, 4, 4, 'bob',
          'v: A B C D, [D C G G, G E C D] x2 ', 'v: bob, bob, bob berand');
      var safeCopySong = a.copySong();
      var manager = SongEditManager(a.copySong());
      expect(manager.reset().toMarkup(), 'V: A B C D [D C G G, G E C D ] x2  ');
      var location = ChordSectionLocation.fromString('v:1:3');
      var b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.append, onEndOfRow: true));
      expect(b.toMarkup(), 'V: A B C D [D C G G, G, G E C D ] x2  ');
      expect(manager.editPoint.location, ChordSectionLocation.fromString('v:1:4'));
      expect(a.toMarkup(), safeCopySong.toMarkup());
      expect(manager.reset().toMarkup(), safeCopySong.toMarkup());
    }

    //  measure append at end of row, with extension of repeat at the end at the end of the repeat
    if (all) {
      var a = Song.createSong('A', 'bob', 'copyright bsteele.com', Key.getDefault(), 100, 4, 4, 'bob',
          'v: A B C D, [D C G G, G E C D] x2 ', 'v: bob, bob, bob berand');
      var safeCopySong = a.copySong();
      var manager = SongEditManager(a.copySong());
      expect(manager.reset().toMarkup(), 'V: A B C D [D C G G, G E C D ] x2  ');
      var location = ChordSectionLocation.fromString('v:1:7');
      var b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.append));
      expect(b.toMarkup(), 'V: A B C D [D C G G, G E C D D ] x2  ');
      expect(manager.editPoint.location, ChordSectionLocation.fromString('v:1:8'));
      expect(a.toMarkup(), safeCopySong.toMarkup());
      expect(manager.reset().toMarkup(), safeCopySong.toMarkup());
    }

    //  measure append at end of row, with new row of repeat at the end of the repeat
    if (all) {
      var a = Song.createSong('A', 'bob', 'copyright bsteele.com', Key.getDefault(), 100, 4, 4, 'bob',
          'v: A B C D, [D C G G, G E C D] x2 ', 'v: bob, bob, bob berand');
      var safeCopySong = a.copySong();
      var manager = SongEditManager(a.copySong());
      expect(manager.reset().toMarkup(), 'V: A B C D [D C G G, G E C D ] x2  ');
      var location = ChordSectionLocation.fromString('v:1:7');
      var b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.append, onEndOfRow: true));
      expect(b.toMarkup(), 'V: A B C D [D C G G, G E C D, D, ] x2  ');
      expect(manager.editPoint.location, ChordSectionLocation.fromString('v:1:8'));
      expect(a.toMarkup(), safeCopySong.toMarkup());
      expect(manager.reset().toMarkup(), safeCopySong.toMarkup());
    }

    //  measure append at end of row, with new row after a repeat
    if (all) {
      var a = Song.createSong('A', 'bob', 'copyright bsteele.com', Key.getDefault(), 100, 4, 4, 'bob',
          'v: A B C D, [D C G G, G E C D] x2 ', 'v: bob, bob, bob berand');
      var safeCopySong = a.copySong();
      var manager = SongEditManager(a.copySong());
      expect(manager.reset().toMarkup(), 'V: A B C D [D C G G, G E C D ] x2  ');
      var location = ChordSectionLocation.fromString('v:2');
      var b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.append, onEndOfRow: true));
      expect(b.toMarkup(), 'V: A B C D [D C G G, G E C D ] x2 C,  ');
      expect(manager.editPoint.location, ChordSectionLocation.fromString('v:2:0'));
      expect(a.toMarkup(), safeCopySong.toMarkup());
      expect(manager.reset().toMarkup(), safeCopySong.toMarkup());
    }
    if (all) {
      var a = Song.createSong('A', 'bob', 'copyright bsteele.com', Key.getDefault(), 100, 4, 4, 'bob',
          'v: A B C D, [D C G G, G E C D] x2 ', 'v: bob, bob, bob berand');
      var safeCopySong = a.copySong();
      var manager = SongEditManager(a.copySong());
      expect(manager.reset().toMarkup(), 'V: A B C D [D C G G, G E C D ] x2  ');
      var location = ChordSectionLocation.fromString('v:2');
      var b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.append, onEndOfRow: false));
      expect(b.toMarkup(), 'V: A B C D [D C G G, G E C D ] x2 C  ');
      expect(manager.editPoint.location, ChordSectionLocation.fromString('v:2:0'));
      expect(a.toMarkup(), safeCopySong.toMarkup());
      expect(manager.reset().toMarkup(), safeCopySong.toMarkup());
    }

    //  measure append at end of row, with new row between repeats
    if (all) {
      var a = Song.createSong('A', 'bob', 'copyright bsteele.com', Key.getDefault(), 100, 4, 4, 'bob',
          'v: A B C D, [D C G G] x2 [G E C D] x3 ', 'v: bob, bob, bob berand');
      var safeCopySong = a.copySong();
      var manager = SongEditManager(a.copySong());
      expect(manager.reset().toMarkup(), 'V: A B C D [D C G G ] x2 [G E C D ] x3  ');
      var location = ChordSectionLocation.fromString('v:1'); //  the append location
      var b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.append, onEndOfRow: false));
      expect(b.toMarkup(), 'V: A B C D [D C G G ] x2 D [G E C D ] x3  ');
      expect(manager.editPoint.location, ChordSectionLocation.fromString('v:2:0'));
      expect(a.toMarkup(), safeCopySong.toMarkup());
      expect(manager.reset().toMarkup(), safeCopySong.toMarkup());
    }

    //  measure append at end of row, with new row after the last repeat of section
    if (all) {
      var a = Song.createSong('A', 'bob', 'copyright bsteele.com', Key.getDefault(), 100, 4, 4, 'bob',
          'v: A B C D, [D C G G] x2 [G E C D] x3 ', 'v: bob, bob, bob berand');
      var safeCopySong = a.copySong();
      var manager = SongEditManager(a.copySong());
      expect(manager.reset().toMarkup(), 'V: A B C D [D C G G ] x2 [G E C D ] x3  ');
      var location = ChordSectionLocation.fromString('v:2'); //  the append location
      var b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.append, onEndOfRow: false));
      expect(b.toMarkup(), 'V: A B C D [D C G G ] x2 [G E C D ] x3 G  ');
      expect(manager.editPoint.location, ChordSectionLocation.fromString('v:3:0'));
      expect(a.toMarkup(), safeCopySong.toMarkup());
      expect(manager.reset().toMarkup(), safeCopySong.toMarkup());
    }

    //  new section add
    if (all) {
      var a = Song.createSong('A', 'bob', 'copyright bsteele.com', Key.getDefault(), 100, 4, 4, 'bob',
          'v: A B C D, [D C G G] x2 [G E C D] x3 ', 'v: bob, bob, bob berand');
      var safeCopySong = a.copySong();
      var manager = SongEditManager(a.copySong());
      expect(manager.preEditSong.toMarkup(), 'V: A B C D [D C G G ] x2 [G E C D ] x3  ');
      var location = ChordSectionLocation.fromString('v:'); //  the append location
      var b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.append, onEndOfRow: false));
      expect(b.toMarkup(), 'V: A B C D [D C G G ] x2 [G E C D ] x3  C: []  ');
      expect(manager.preEditSong.toMarkup(), b.toMarkup());
      expect(manager.editPoint.location, ChordSectionLocation.fromString('c:'));
      expect(a.toMarkup(), safeCopySong.toMarkup());
      expect(manager.reset().toMarkup(), safeCopySong.toMarkup());
    }

    {
      var a = Song.createSong(
          'A',
          'bob',
          'copyright bsteele.com',
          Key.getDefault(),
          100,
          4,
          4,
          'bob',
          'I: V: D, Am Am/G Am/F# FE  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ',
          'v: bob, bob, bob berand');
      var safeCopySong = a.copySong();
      var manager = SongEditManager(a.copySong());
      expect(manager.preEditSong.toMarkup(),
          'I: V: D, Am Am/G Am/F# FE  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
      var location = ChordSectionLocation.fromString('c:0:1'); //  the append location
      var b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.append, onEndOfRow: false));
      expect(b.toMarkup(),
          'I: V: D, Am Am/G Am/F# FE  I2: [Am Am/G Am/F# FE ] x2  C: F F F C C, G G F F  O: Dm C B Bb, A  ');
      expect(manager.preEditSong.toMarkup(), b.toMarkup());
      expect(manager.editPoint.location, ChordSectionLocation.fromString('c:0:2'));
      expect(a.toMarkup(), safeCopySong.toMarkup());
      expect(manager.reset().toMarkup(), safeCopySong.toMarkup());
    }

    //
    if (all) {
      var a = Song.createSong('A', 'bob', 'copyright bsteele.com', Key.getDefault(), 100, 4, 4, 'bob',
          'V: [Am Am/G Am/F# FE ] x4  C: F F C C, G G F F ', 'v: bob, bob, bob berand');
      var safeCopySong = a.copySong();
      var manager = SongEditManager(a.copySong());
      expect(manager.preEditSong.toMarkup(), 'V: [Am Am/G Am/F# FE ] x4  C: F F C C, G G F F  ');
      var location = ChordSectionLocation.fromString('C:0:0'); //  the append location
      var b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.append, onEndOfRow: false));
      expect(b.toMarkup(), 'V: [Am Am/G Am/F# FE ] x4  C: F F F C C, G G F F  ');
      expect(manager.preEditSong.toMarkup(), b.toMarkup());
      expect(manager.editPoint.location, ChordSectionLocation.fromString('c:0:1'));
      expect(a.toMarkup(), safeCopySong.toMarkup());

      //  second pass
      var editPoint = manager.editPoint; //  the new edit point
      manager = SongEditManager(b);
      b = manager.preEdit(editPoint);
      expect(b.toMarkup(), 'V: [Am Am/G Am/F# FE ] x4  C: F F F C C, G G F F  ');
      expect(manager.preEditSong.toMarkup(), b.toMarkup());
      expect(
          manager.editPoint,
          EditPoint(ChordSectionLocation.fromString('c:0:1'),
              measureEditType: MeasureEditType.replace, onEndOfRow: false));
      expect(a.toMarkup(), safeCopySong.toMarkup());
      b.setCurrentChordSectionLocation(manager.editPoint.location);
      b.currentMeasureEditType = manager.editPoint.measureEditType;
      var measureNode = Measure(4, [Chord.parseString('A', 4)!]);
      b.editMeasureNode(measureNode);
      expect(b.toMarkup(), 'V: [Am Am/G Am/F# FE ] x4  C: F A F C C, G G F F  ');
    }
  });

  test('test edit manager inserts', () {
    const bool all = true;

    if (all) {
      ChordSectionLocation? location;
      Song a = Song.createSong(
          'A',
          'bob',
          'copyright bsteele.com',
          Key.getDefault(),
          100,
          4,
          4,
          'bob',
          'i: A B C D, D C G G v: E F G G o: G G G G',
          'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
      var manager = SongEditManager(a);
      var safeCopySong = a.copySong();
      Song b;

      logger.d('a.chords: \'${a.toMarkup()}\'');

      expect(a.toMarkup(), safeCopySong.toMarkup());
      b = manager.preEdit(EditPoint.defaultInstance);
      expect(b.toMarkup(), safeCopySong.toMarkup());
      location = ChordSectionLocation.fromString('v:0:0');
      b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.insert));
      expect(b.toMarkup(), 'I: A B C D, D C G G  V: E E F G G  O: G G G G  ');
      expect(manager.editPoint.location, location);

      b.setCurrentChordSectionLocation(manager.editPoint.location);
      b.currentMeasureEditType = manager.editPoint.measureEditType;
      var measureNode = Measure(4, [Chord.parseString('A', 4)!]);
      b.editMeasureNode(measureNode);
      expect(b.toMarkup(), 'I: A B C D, D C G G  V: A E F G G  O: G G G G  ');
    }

    if (all) {
      ChordSectionLocation? location;
      Song a = Song.createSong(
          'A',
          'bob',
          'copyright bsteele.com',
          Key.getDefault(),
          100,
          4,
          4,
          'bob',
          'i: A B C D, D C G G v: E F G G o: G G G G',
          'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
      var manager = SongEditManager(a);
      var safeCopySong = a.copySong();
      Song b;

      logger.d('a.chords: \'${a.toMarkup()}\'');

      expect(a.toMarkup(), safeCopySong.toMarkup());
      b = manager.preEdit(EditPoint.defaultInstance);
      expect(b.toMarkup(), safeCopySong.toMarkup());
      location = ChordSectionLocation.fromString('v:0');
      b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.insert));
      expect(b.toMarkup(), 'I: A B C D, D C G G  V: E, E F G G  O: G G G G  ');
      expect(manager.editPoint.location, location);
    }

    if (all) {
      ChordSectionLocation? location;
      Song a = Song.createSong(
          'A',
          'bob',
          'copyright bsteele.com',
          Key.getDefault(),
          100,
          4,
          4,
          'bob',
          'i: A B C D, D C G G v: E F G G o: G G G G',
          'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
      var manager = SongEditManager(a);
      var safeCopySong = a.copySong();
      Song b;

      logger.d('a.chords: \'${a.toMarkup()}\'');

      expect(a.toMarkup(), safeCopySong.toMarkup());
      b = manager.preEdit(EditPoint.defaultInstance);
      expect(b.toMarkup(), safeCopySong.toMarkup());
      location = ChordSectionLocation.fromString('v:');
      b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.insert));
      expect(b.toMarkup(), 'I: A B C D, D C G G  V: E F G G  C: []  O: G G G G  ');
      expect(manager.editPoint.location, ChordSectionLocation.fromString('C:'));
    }
  });

  test('test edit manager adding sections', () {
    {
      var a = Song.createSong('A', 'bob', 'copyright bsteele.com', Key.getDefault(), 100, 4, 4, 'bob',
          'V: [Am Am/G Am/F# FE ] x4  C: F F C C, G G F F ', 'v: bob, bob, bob berand');
      var manager = SongEditManager(a);
      expect(manager.preEditSong.toMarkup(), 'V: [Am Am/G Am/F# FE ] x4  C: F F C C, G G F F  ');
      var location = ChordSectionLocation.fromString('Br:'); //  the append location
      var b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.append, onEndOfRow: false));
      expect(b.toMarkup(), 'V: [Am Am/G Am/F# FE ] x4  C: F F C C, G G F F  Br: []  ');
      expect(manager.preEditSong.toMarkup(), b.toMarkup());
      expect(manager.editPoint.location, ChordSectionLocation.fromString('Br:'));

      //  second pass
      var editPoint = manager.editPoint; //  the new edit point
      manager = SongEditManager(b);
      b = manager.preEdit(editPoint);
      expect(b.toMarkup(), 'V: [Am Am/G Am/F# FE ] x4  C: F F C C, G G F F  Br: []  ');
      expect(manager.preEditSong.toMarkup(), b.toMarkup());
      expect(
          manager.editPoint,
          EditPoint(ChordSectionLocation.fromString('Br:'),
              measureEditType: MeasureEditType.replace, onEndOfRow: false));
      b.setCurrentChordSectionLocation(manager.editPoint.location);
      b.currentMeasureEditType = manager.editPoint.measureEditType;
      var measureNode = Measure(4, [Chord.parseString('A', 4)!]);
      b.editMeasureNode(measureNode);
      expect(b.toMarkup(), 'V: [Am Am/G Am/F# FE ] x4  C: F F C C, G G F F  Br: []  ');
    }
  });
}
