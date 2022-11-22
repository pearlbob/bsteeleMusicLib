import 'package:bsteeleMusicLib/app_logger.dart';
import 'package:bsteeleMusicLib/songs/song_base.dart';
import 'package:bsteeleMusicLib/songs/key.dart';
import 'package:bsteeleMusicLib/util/util.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.debug;

  test('testEquals', () {
    {
      SongBase a = SongBase.createSongBase('A', 'bobby', 'bsteele.com', Key.getDefault(),
          100, 4, 4, 'i1: D D D D v: A B C D', 'v: bob, bob, bob berand');
      SongBase b = SongBase.createSongBase('A', 'bobby', 'bsteele.com', Key.getDefault(),
          100, 4, 4, 'i1: D D D D D D D D v: A B C D', 'v: bob, bob, bob berand');

      List<StringTriple> diffs = SongBase.diff(a, b);
      logger.i(diffs.toString());
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
      SongBase a = SongBase.createSongBase('A', 'bobby', 'bsteele.com', Key.getDefault(),
          100, 4, 4, 'v: A B C D', 'v: bob, bob, bob berand');
      SongBase b = SongBase.createSongBase('A', 'bob', 'bsteele.com', Key.getDefault(),
          100, 4, 4, 'v: A B D D O: D', 'v: bob, bob, Barbara Ann');

      List<StringTriple> diffs = SongBase.diff(a, b);
      logger.d(diffs.toString());
//      logger.i(StringTripleToHtmlTable.toHtmlTable(new StringTriple("fields", "a", "b"), diffs));
//      expect("[(artist:: \"bobby\", \"bob\")," +
//          " (chords:: \"V: A B C D \", \"V: A B D D \")," +
//          " (chords missing:: \"\", \"O: D \")," +
//          " (lyrics V:: \"bob, bob, bob berand\", \"bob, bob, Barbara Ann\")]"
//          , diffs.toString());
    }

  });

}