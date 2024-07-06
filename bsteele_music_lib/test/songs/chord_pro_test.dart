import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/songs/chord_pro.dart';
import 'package:bsteele_music_lib/songs/song.dart';
import 'package:bsteele_music_lib/songs/time_signature.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

String _andILoveHer = '''{t:And I Love Her}
 {st:The Beatles}

 [INTRO]
 [F#m] [F#m] [E] [E]
 {sot}
 G:--------|--------|--------|--------|--------|
 D:--------|4--44---|4--44---|2--22---|2--22---|
 A:--------|--------|--------|--------|--------|
 E:--------|--------|--------|--------|--------|
 {eot}

 [VERSE]
 [F#m] I give her [C#m]all my love [F#m] That's all I [C#m]do
 [F#m] And if you [C#m]saw my love [A] You'd love her, [B7]too I [E]love her[E]
 ||
 [F#m] [C#m] [F#m] [C#m] [F#m] [C#m] [A] [B7] [E]
 {sot}
 G:--------|--------|--------|--------|--------|--------|--------|--------|---4----|
 D:4--44---|--------|4--44---|--------|4--44---|--------|------2-|---1--4-|2-------|
 A:--------|4--44---|--------|4--44---|--------|4--44---|0--4----|2-------|------2-|
 E:--------|--------|--------|--------|--------|--------|--------|--------|--------|
 {eot}

 [VERSE]
 [F#m] She gives me [C#m]everything [F#m] And tender[C#m]ly
 [F#m] The kiss my [C#m]lover brings [A] She brings to [B7]me And I [E]love her[E]
 ||
 [F#m] [C#m] [F#m] [C#m] [F#m] [C#m] [A] [B7] [E]
 {sot}
 G:--------|--------|--------|--------|--------|--------|--------|--------|---4----|
 D:4--44---|--------|4--44---|--------|4--44---|--------|------2-|---1--4-|2-------|
 A:--------|4--44---|--------|4--44---|--------|4--44---|0--4----|2-------|------2-|
 E:--------|--------|--------|--------|--------|--------|--------|--------|--------|
 {eot}

 [BRIDGE]
 [C#m] A love like [B]ours [C#m] Could never [Abm]die
 [C#m] As long as [Abm]I Have you [B7]near me

 [C#m] [B] [C#m] [Abm] [C#m] [Abm] [B7] [B7] 
 {sot}
 G:--------|--------|--------|--------|--------|--------|--------|--------|
 D:--------|--------|--------|--------|--------|--------|--------|--------|
 A:4--44---|2--22---|4--44---|--------|4--44---|--------|2--22---|2--22---|
 E:--------|--------|--------|4--44---|--------|4--44---|--------|--------|
 {eot}
 [ Tab from: http://www.guitartabs.cc/tabs/b/beatles/and_i_love_her_btab_ver_4.html ]
 [VERSE]
 [F#m] Bright are the [C#m]stars that shine [F#m] Dark is the [C#m]sky
 [F#m] I know this [C#m]love of mine [A] Will never [B7]die And I [E]love her[E]
 ||
 [F#m] [C#m] [F#m] [C#m] [F#m] [C#m] [A] [B7] [E] 
 {sot}
 G:--------|--------|--------|--------|--------|--------|--------|--------|---4----|
 D:4--44---|--------|4--44---|--------|4--44---|--------|------2-|---1--4-|2-------|
 A:--------|4--44---|--------|4--44---|--------|4--44---|0--4----|2-------|------2-|
 E:--------|--------|--------|--------|--------|--------|--------|--------|--------|
 {eot}

 [INSTRUMENTAL]
 ||
 [Gm] [Dm] [Gm] [Dm] [Gm] [Dm] [Bb] [C7] [F] 
 {sot}
 G:--------|--------|--------|--------|--------|--------|--------|--------|---5----|
 D:--------|0--00---|--------|0--00---|--------|0--00---|--------|--------|3-------|
 A:--------|--------|--------|--------|--------|--------|1--11---|3--33---|------3-|
 E:3--33---|--------|3--33---|--------|3--33---|--------|--------|--------|--------|
 {eot}

 [VERSE]
 [F#m] Bright are the [C#m]stars that shine [F#m] Dark is the [C#m]sky
 [F#m] I know this [C#m]love of mine [A] Will never [B7]die And I [E]love her[E]
 ||
 [F#m] [C#m] [F#m] [C#m] [F#m] [C#m] [A] [B7] [E] 
 {sot}
 G:--------|--------|--------|--------|--------|--------|--------|--------|---4----|
 D:4--44---|--------|4--44---|--------|4--44---|--------|------2-|---1--4-|2-------|
 A:--------|4--44---|--------|4--44---|--------|4--44---|0--4----|2-------|------2-|
 E:--------|--------|--------|--------|--------|--------|--------|--------|--------|
 {eot}

 [CODA]
 F#m F#m E E F#m F#m D (let ring)
 
 {sot}
 G:--------|--------|--------|--------|--------|--------|--------|--------|
 D:4--44---|4--44---|2--22---|2--22---|4--44---|4--44---|0~~~~~~~~~~~~~~~~|
 A:--------|--------|--------|--------|--------|--------|--------|--------|
 E:--------|--------|--------|--------|--------|--------|--------|--------|
 {eot}
 
 Tabbed by Michael Oxner
 moxner@nbnet.nb.ca
 August 11, 2011
''';

void main() {
  Logger.level = Level.info;

  test('chordPro testing', () {
    ChordPro chordPro = ChordPro();

    Song song = chordPro.parse(_andILoveHer);
    logger.i(song.toJsonString());
    expect(song.title, 'And I Love Her');
    expect(song.artist, 'Beatles, The');
    expect(song.copyright, '');
    expect(song.timeSignature, TimeSignature.defaultTimeSignature);
    expect(song.songMoments.length, 105);
    expect(
        song.rawLyrics,
        'I:\n'
        '\n'
        'V:\n'
        'I give her | all my love | That\'s all I | do\n'
        'And if you | saw my love | You\'d love her, | too I | love her |\n'
        '\n'
            'V:\n'
            'She gives me | everything | And tender | ly\n'
            'The kiss my | lover brings | She brings to | me And I | love her |\n'
            '\n'
            'Br:\n'
            'A love like | ours | Could never | die\n'
            'As long as | I Have you | near me\n'
            '\n'
            'V:\n'
            'Bright are the | stars that shine | Dark is the | sky\n'
            'I know this | love of mine | Will never | die And I | love her |\n'
            '\n'
            'I1:\n'
            '\n'
            'V:\n'
            'Bright are the | stars that shine | Dark is the | sky\n'
            'I know this | love of mine | Will never | die And I | love her |\n'
            '\n'
            'Co:\n'
            'F#m F#m E E F#m F#m D (let ring)\n'
            'Tabbed by Michael Oxner\n'
            'moxner@nbnet.nb.ca\n'
            'August 11, 2011\n'
            '');
  });
}
