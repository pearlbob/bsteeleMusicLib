import 'package:bsteeleMusicLib/songs/key.dart';
import 'package:bsteeleMusicLib/songs/ninjam.dart';
import 'package:bsteeleMusicLib/songs/song.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('test NinJam', () {
    {
      var a = Song.createSong('A blues classic', 'bob', 'copyright nobody', Key.getDefault(), 106, 4, 4, 'bob',
          'v: G C G G, C C G G, D C G D c: G C G G, C C G G, D C G D', 'v: bob, bob, bob berand');

      var ninJam = NinJam(a, keyOffset:  0 );
      expect(ninJam.isNinJamReady, true);
      expect(ninJam.bpi, 48);
      expect(ninJam.bpm, 106);
      expect(ninJam.toMarkup(), 'G C G G, C C G G, D C G D ');

      ninJam = NinJam(a, keyOffset: 1);
      expect(ninJam.isNinJamReady, true);
      expect(ninJam.bpi, 48);
      expect(ninJam.bpm, 106);
      expect(ninJam.toMarkup(), 'A♭ D♭ A♭ A♭, D♭ D♭ A♭ A♭, E♭ D♭ A♭ E♭ ');

      ninJam = NinJam(a, keyOffset: 2);
      expect(ninJam.isNinJamReady, true);
      expect(ninJam.bpi, 48);
      expect(ninJam.bpm, 106);
      expect(ninJam.toMarkup(), 'A D A A, D D A A, E D A E ');

      ninJam = NinJam(a, keyOffset: -1);
      expect(ninJam.isNinJamReady, true);
      expect(ninJam.bpi, 48);
      expect(ninJam.bpm, 106);
      expect(ninJam.toMarkup(), 'G♭ B G♭ G♭, B B G♭ G♭, D♭ B G♭ D♭ ');

      ninJam = NinJam(a, keyOffset: -2);
      expect(ninJam.isNinJamReady, true);
      expect(ninJam.bpi, 48);
      expect(ninJam.bpm, 106);
      expect(ninJam.toMarkup(), 'F B♭ F F, B♭ B♭ F F, C B♭ F C ');
    }

    {
      var a = Song.createSong('A', 'bob', 'copyright bsteele.com', Key.getDefault(), 100, 4, 4, 'bob', 'v: A B C D',
          'v: bob, bob, bob berand');

      var ninJam = NinJam(a);
      expect(ninJam.isNinJamReady, true);
      expect(ninJam.bpi, 16);
      expect(ninJam.bpm, 100);
      expect(ninJam.toMarkup(), 'A B C D ');
    }
    {
      var a = Song.createSong('A', 'bob', 'copyright bsteele.com', Key.getDefault(), 100, 4, 4, 'bob', 'v: A B C D x4',
          'v: bob, bob, bob berand');

      var ninJam = NinJam(a);
      expect(ninJam.isNinJamReady, true);
      expect(ninJam.bpi, 16);
      expect(ninJam.bpm, 100);
      expect(ninJam.toMarkup(), 'A B C D ');
    }
    {
      var a = Song.createSong('A blues classic', 'bob', 'copyright nobody', Key.getDefault(), 106, 4, 4, 'bob',
          'v: G C G G, C C G G, D C G D', 'v: bob, bob, bob berand');

      var ninJam = NinJam(a);
      expect(ninJam.isNinJamReady, true);
      expect(ninJam.bpi, 48);
      expect(ninJam.bpm, 106);
      expect(ninJam.toMarkup(), 'G C G G, C C G G, D C G D ');
    }
    {
      var a = Song.createSong('A blues classic', 'bob', 'copyright nobody', Key.getDefault(), 106, 4, 4, 'bob',
          'v: G C G G, C C G G, D C G D c: G G G G', 'v: bob, bob, bob berand');

      var ninJam = NinJam(a);
      expect(ninJam.isNinJamReady, false);
      expect(ninJam.bpi, 0);
      expect(ninJam.bpm, 106);
      expect(ninJam.toMarkup(), '');
    }
    {
      var a = Song.createSong('A blues classic', 'bob', 'copyright nobody', Key.getDefault(), 106, 4, 4, 'bob',
          'v: G C G G, C C G G, D C G D c: G C G G, C C G G, D C G D', 'v: bob, bob, bob berand');

      var ninJam = NinJam(a);
      expect(ninJam.isNinJamReady, true);
      expect(ninJam.bpi, 48);
      expect(ninJam.bpm, 106);
      expect(ninJam.toMarkup(), 'G C G G, C C G G, D C G D ');
    }



  });
}
