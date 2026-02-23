import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/songs/chord.dart';
import 'package:bsteele_music_lib/songs/chord_section.dart';
import 'package:bsteele_music_lib/songs/chord_section_location.dart';
import 'package:bsteele_music_lib/songs/key.dart';
import 'package:bsteele_music_lib/songs/measure.dart';
import 'package:bsteele_music_lib/songs/measure_node.dart';
import 'package:bsteele_music_lib/songs/song.dart';
import 'package:bsteele_music_lib/songs/song_edit_manager.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('test edit manager appends', () {
    {
      ChordSectionLocation? location;
      Song a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'i: A B C D, D C G G v: E F G G o: G G G G',
          rawLyrics: 'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');

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

    {
      //  basic measure append
      var a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'v: A B C D, D C G G ',
          rawLyrics: 'v: bob, bob, bob berand');

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
        {
      var a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'v: A B C D, [D C G G] x2 ',
          rawLyrics: 'v: bob, bob, bob berand');

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
        {
      var a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'v: A B C D, [D C G G] x2 ',
          rawLyrics: 'v: bob, bob, bob berand');

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
        {
      var a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'v: A B C D, [D C G G, G E C D] x2 ',
          rawLyrics: 'v: bob, bob, bob berand');

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
        {
      var a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'v: A B C D, [D C G G, G E C D] x2 ',
          rawLyrics: 'v: bob, bob, bob berand');

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
        {
      var a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'v: A B C D, [D C G G, G E C D] x2 ',
          rawLyrics: 'v: bob, bob, bob berand');

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
        {
      var a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'v: A B C D, [D C G G, G E C D] x2 ',
          rawLyrics: 'v: bob, bob, bob berand');

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
        {
      var a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'v: A B C D, [D C G G, G E C D] x2 ',
          rawLyrics: 'v: bob, bob, bob berand');

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
    {
      var a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'v: A B C D, [D C G G, G E C D] x2 ',
          rawLyrics: 'v: bob, bob, bob berand');

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
        {
      var a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'v: A B C D, [D C G G] x2 [G E C D] x3 ',
          rawLyrics: 'v: bob, bob, bob berand');

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
        {
      var a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'v: A B C D, [D C G G] x2 [G E C D] x3 ',
          rawLyrics: 'v: bob, bob, bob berand');

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
    {
      const beatsPerBar = 4;
      var a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'v: A B C D, [D C G G] x2 [G E C D] x3 ',
          rawLyrics: 'v: bob, bob, bob berand');

      var safeCopySong = a.copySong();
      var manager = SongEditManager(a.copySong());
      expect(manager.preEditSong.toMarkup(), 'V: A B C D [D C G G ] x2 [G E C D ] x3  ');
      var b = manager.preEdit(EditPoint.byChordSection(ChordSection.parseString('v:', beatsPerBar),
          measureEditType: MeasureEditType.append, onEndOfRow: false));
      expect(b.toMarkup(), 'V: A B C D [D C G G ] x2 [G E C D ] x3  C: []  ');
      expect(manager.preEditSong.toMarkup(), b.toMarkup());
      expect(manager.editPoint.location, ChordSectionLocation.fromString('c:'));
      expect(a.toMarkup(), safeCopySong.toMarkup());
      expect(manager.reset().toMarkup(), safeCopySong.toMarkup());
    }

    {
      var a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'I: V: D, Am Am/G Am/F# FE  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ',
          rawLyrics: 'v: bob, bob, bob berand');

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
        {
      var a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'V: [Am Am/G Am/F# FE ] x4  C: F F C C, G G F F ',
          rawLyrics: 'v: bob, bob, bob berand');

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

    {
      //  new row after a repeat, no new row
      var a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F, F  O: Dm C B Bb, A',
          rawLyrics: 'v: bob, bob, bob berand');

      var manager = SongEditManager(a.copySong());
      expect(manager.preEditSong.toMarkup(),
          'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F, F  O: Dm C B Bb, A  ');
      var location = ChordSectionLocation.fromString('I2:0'); //  the append location
      var b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.append, onEndOfRow: false));
      expect(b.toMarkup(),
          'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2 Am  C: F F C C, G G F F, F  O: Dm C B Bb, A  ');
      expect(manager.preEditSong.toMarkup(), b.toMarkup());
      expect(manager.editPoint.location, ChordSectionLocation.fromString('I2:1:0'));
    }
    {
      //  new row after a repeat with new row   fixme:???
      var a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F, F  O: Dm C B Bb, A',
          rawLyrics: 'v: bob, bob, bob berand');

      var manager = SongEditManager(a.copySong());
      expect(manager.preEditSong.toMarkup(),
          'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F, F  O: Dm C B Bb, A  ');
      var location = ChordSectionLocation.fromString('I2:0'); //  the append location
      var b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.append, onEndOfRow: true));
      expect(b.toMarkup(),
          'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2 Am,  C: F F C C, G G F F, F  O: Dm C B Bb, A  ');
      expect(manager.preEditSong.toMarkup(), b.toMarkup());
      expect(manager.editPoint.location, ChordSectionLocation.fromString('I2:1:0'));
    }
  });

  test('test edit manager inserts', () {
    {
      ChordSectionLocation? location;
      Song a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'i: A B C D, D C G G v: E F G G o: G G G G',
          rawLyrics: 'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');

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

    {
      ChordSectionLocation? location;
      Song a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'i: A B C D, D C G G v: E F G G o: G G G G',
          rawLyrics: 'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');

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
      expect(manager.editPoint.location, ChordSectionLocation.fromString('v:0:0'));
    }

    {
      const beatsPerBar = 4;
      Song a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'i: A B C D, D C G G v: E F G G o: G G G G',
          rawLyrics: 'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');

      var manager = SongEditManager(a);
      var safeCopySong = a.copySong();
      Song b;

      logger.d('a.chords: \'${a.toMarkup()}\'');

      expect(a.toMarkup(), safeCopySong.toMarkup());
      b = manager.preEdit(EditPoint.defaultInstance);
      expect(b.toMarkup(), safeCopySong.toMarkup());
      b = manager.preEdit(EditPoint.byChordSection(ChordSection.parseString('c:', beatsPerBar),
          measureEditType: MeasureEditType.insert));
      expect(b.toMarkup(), 'I: A B C D, D C G G  V: E F G G  C: []  O: G G G G  ');
      expect(manager.editPoint.location, ChordSectionLocation.fromString('C:'));
    }
  });

  test('test edit manager adding sections', () {
    {
      const beatsPerBar = 4;
      var a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'V: [Am Am/G Am/F# FE ] x4  C: F F C C, G G F F ',
          rawLyrics: 'v: bob, bob, bob berand');

      var manager = SongEditManager(a);
      expect(manager.preEditSong.toMarkup(), 'V: [Am Am/G Am/F# FE ] x4  C: F F C C, G G F F  ');
      var b = manager.preEdit(EditPoint.byChordSection(ChordSection.parseString('Br:', beatsPerBar),
          measureEditType: MeasureEditType.append, onEndOfRow: false));
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
      expect(b.toMarkup(), 'V: [Am Am/G Am/F# FE ] x4  C: F F C C, G G F F  Br: A  ');
    }
    {
      var a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A',
          rawLyrics: 'v: bob, bob, bob berand');

      var manager = SongEditManager(a.copySong());
      var location = ChordSectionLocation.fromString('c:0:7');
      var b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.append, onEndOfRow: true));
      expect(b.toMarkup(),
          'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F, F,  O: Dm C B Bb, A  ');
      expect(manager.editPoint, EditPoint(ChordSectionLocation.fromString('c:0:8'), onEndOfRow: true));
    }
    {
      var a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A',
          rawLyrics: 'v: bob, bob, bob berand');

      var manager = SongEditManager(a.copySong());
      var location = ChordSectionLocation.fromString('c:1');
      var b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.append, onEndOfRow: true));
      expect(b.toMarkup(),
          'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F, C,  O: Dm C B Bb, A  ');
      expect(manager.editPoint, EditPoint(ChordSectionLocation.fromString('c:0:8'), onEndOfRow: true));
    }
  });

  test('test edit manager start of row', () {
    {
      //  insert a default row in front of a repeat
      var a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A',
          rawLyrics: 'v: bob, bob, bob berand');

      var manager = SongEditManager(a.copySong());
      expect(manager.reset().toMarkup(),
          'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
      var location = ChordSectionLocation.fromString('I:0');
      var b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.insert, onEndOfRow: false));
      expect(b.toMarkup(),
          'I: V: Am [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: F F C C, G G F F  O: Dm C B Bb, A  ');
      expect(
          manager.editPoint,
          EditPoint(ChordSectionLocation.fromString('I:0:0'),
              measureEditType: MeasureEditType.replace, onEndOfRow: false));
    }
    {
      //  insert a default row at the start of an empty section
      var a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: []  O: Dm C B Bb, A',
          rawLyrics: 'v: bob, bob, bob berand');

      var manager = SongEditManager(a.copySong());
      expect(manager.reset().toMarkup(),
          'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: []  O: Dm C B Bb, A  ');
      var location = ChordSectionLocation.fromString('c:0');
      var b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.insert, onEndOfRow: false));
      expect(b.toMarkup(), 'I: V: [Am Am/G Am/F# FE ] x4  I2: [Am Am/G Am/F# FE ] x2  C: C  O: Dm C B Bb, A  ');
      expect(
          manager.editPoint,
          EditPoint(ChordSectionLocation.fromString('C:0:0'),
              measureEditType: MeasureEditType.replace, onEndOfRow: false));
    }

    {
      //  insert a default row at the start of an empty section
      var a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'V: [] x4',
          rawLyrics: 'v: bob, bob, bob berand');

      var manager = SongEditManager(a.copySong());
      expect(manager.reset().toMarkup(), 'V: []  ');
      var location = ChordSectionLocation.fromString('v:');
      var b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.append, onEndOfRow: false));
      expect(b.toMarkup(), 'V: C  ');
      expect(
          manager.editPoint,
          EditPoint(ChordSectionLocation.fromString('V:0:0'),
              measureEditType: MeasureEditType.replace, onEndOfRow: false));
    }
  });

  test('test edit manager end of row', () {
    {
      //  basic measure append
      var a = Song(
          title: 'A',
          artist: 'bob',
          copyright: 'copyright bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'v: A B C D, D C G G ',
          rawLyrics: 'v: bob, bob, bob berand');

      var safeCopySong = a.copySong();
      var manager = SongEditManager(a.copySong());
      expect(manager.reset().toMarkup(), 'V: A B C D, D C G G  ');
      var location = ChordSectionLocation.fromString('v:0:1');
      var b = manager.preEdit(EditPoint(location, measureEditType: MeasureEditType.append, onEndOfRow: true));
      expect(b.toMarkup(), 'V: A B, B, C D, D C G G  ');
      expect(manager.editPoint, EditPoint(ChordSectionLocation.fromString('v:0:2'), onEndOfRow: true));
      expect(a.toMarkup(), safeCopySong.toMarkup());
      expect(manager.reset().toMarkup(), safeCopySong.toMarkup());
    }
  });
}
