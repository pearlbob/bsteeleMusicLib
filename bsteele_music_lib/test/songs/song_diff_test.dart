import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/songs/key.dart';
import 'package:bsteele_music_lib/songs/song_base.dart';
import 'package:bsteele_music_lib/util/util.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.debug;

  test('testEquals', () {
    {
      SongBase a = SongBase(
          title: 'A',
          artist: 'bob',
          copyright: 'bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          chords: 'i1: D D D D v: A B C D',
          rawLyrics: 'v: bob, bob, bob berand');

      SongBase b = SongBase(
          title: 'A',
          artist: 'bobby',
          copyright: 'bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          chords: 'i1: D D D D D D D D v: A B C D',
          rawLyrics: 'v: bob, bob, bob berand');

      List<StringTriple> diffs = SongBase.diff(a, b);
      logger.i('diffs: $diffs');
      expect(diffs.toString(), '[(artist:: "bob", "bobby"), (chords:: "I1: D D D D ", "I1: D D D D D D D D ")]');
//      logger.i(SongBase.StringTripleToHtmlTable.toHtmlTable(new StringTriple("fields", "a", "b"), diffs));
//      diffs = SongBase.diff( b,a);
//      logger.i(diffs.toString());
//      logger.i(SongBase.StringTripleToHtmlTable.toHtmlTable(new StringTriple("fields", "b", "a"), diffs));
//            assertEquals("[(artist:: \"bobby\", \"bob\")," +
//                            " (chords:: \"V: A B C D \", \"V: A B D D \")," +
//                            " (chords missing:: \"\", \"O: D \")," +
//                            " (lyrics V::: \"bob, bob, bob berand\", \"bob, bob, Barbara Ann\")]"
//                    , diffs.toString());
    }
    {
      SongBase a = SongBase(
          title: 'A',
          artist: 'bobby',
          copyright: 'bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          chords: 'v: A B C D',
          rawLyrics: 'v: bob, bob, bob berand');

      SongBase b = SongBase(
          title: 'A',
          artist: 'bob',
          copyright: 'bsteele.com',
          key: MajorKey.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          chords: 'v: A B D D O: D',
          rawLyrics: 'v: bob, bob, Barbara Ann');

      List<StringTriple> diffs = SongBase.diff(a, b);
      logger.i(diffs.toString());
      expect(
          diffs.toString(),
          '[(artist:: "bobby", "bob"), (chords:: "V: A B C D ", "V: A B D D ")'
          ', (chords missing:: "", "O: D "), (lyrics V:: "bob, bob, bob berand", "bob, bob, Barbara Ann")]');
//      logger.i(StringTripleToHtmlTable.toHtmlTable(new StringTriple("fields", "a", "b"), diffs));
//      expect("[(artist:: \"bobby\", \"bob\")," +
//          " (chords:: \"V: A B C D \", \"V: A B D D \")," +
//          " (chords missing:: \"\", \"O: D \")," +
//          " (lyrics V:: \"bob, bob, bob berand\", \"bob, bob, Barbara Ann\")]"
//          , diffs.toString());
    }

  });

}