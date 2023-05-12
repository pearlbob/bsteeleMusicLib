import 'package:bsteele_music_lib/app_logger.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

import 'package:bsteele_music_lib/songs/chord_descriptor.dart';
import 'package:bsteele_music_lib/songs/key.dart' as music_key;
import 'package:bsteele_music_lib/songs/key.dart';
import 'package:bsteele_music_lib/songs/music_constants.dart';
import 'package:bsteele_music_lib/songs/song.dart';

void main() {
  Logger.level = Level.info;

  test('nashville Chord Number details', () {
    var key = Key.C;
    for (var halfStep = 0; halfStep <= MusicConstants.halfStepsPerOctave; halfStep++) {
      var scaleNote = key.getKeyScaleNoteByHalfStep(halfStep);
      logger.i('${halfStep + 1}: $scaleNote  ${scaleNote.getNashvilleNote(key)}');
    }
  });

  test('nashville ChordDescriptor details', () {
    //  generate the code:
    // for ( var cd in ChordDescriptor.values){
    //  // logger.i('cd: "$cd" => "${cd.toNashville()}"');
    //   logger.i('expect(ChordDescriptor.${cd.name}.toNashville(),\'${cd.toNashville()}\');');
    // }

    expect(ChordDescriptor.major.toNashville(), '');
    expect(ChordDescriptor.minor.toNashville(), '-');
    expect(ChordDescriptor.dominant7.toNashville(), '7');
    expect(ChordDescriptor.minor7.toNashville(), 'm7');
    expect(ChordDescriptor.power5.toNashville(), '5');
    expect(ChordDescriptor.major7.toNashville(), 'Δ');
    expect(ChordDescriptor.major6.toNashville(), '6');
    expect(ChordDescriptor.suspended2.toNashville(), 'sus2');
    expect(ChordDescriptor.suspended4.toNashville(), 'sus4');
    expect(ChordDescriptor.add9.toNashville(), 'add9');
    expect(ChordDescriptor.majorSeven.toNashville(), 'Δ');
    expect(ChordDescriptor.dominant9.toNashville(), '9');
    expect(ChordDescriptor.sevenSus4.toNashville(), '7sus4');
    expect(ChordDescriptor.diminished.toNashville(), '°');
    expect(ChordDescriptor.minor6.toNashville(), 'm6');
    expect(ChordDescriptor.major9.toNashville(), 'maj9');
    expect(ChordDescriptor.suspendedSecond.toNashville(), '2');
    expect(ChordDescriptor.minor9.toNashville(), 'm9');
    expect(ChordDescriptor.augmented.toNashville(), 'aug');
    expect(ChordDescriptor.suspended.toNashville(), 'sus');
    expect(ChordDescriptor.suspendedFourth.toNashville(), '4');
    expect(ChordDescriptor.sevenSharp5.toNashville(), '7#5');
    expect(ChordDescriptor.maj.toNashville(), '');
    expect(ChordDescriptor.minor7b5.toNashville(), 'm7b5');
    expect(ChordDescriptor.diminished7.toNashville(), '°7');
    expect(ChordDescriptor.minor11.toNashville(), 'm11');
    expect(ChordDescriptor.six9.toNashville(), '69');
    expect(ChordDescriptor.msus4.toNashville(), 'msus4');
    expect(ChordDescriptor.dominant11.toNashville(), '11');
    expect(ChordDescriptor.sevenSus.toNashville(), '7sus');
    expect(ChordDescriptor.augmented7.toNashville(), '+7');
    expect(ChordDescriptor.capMajor.toNashville(), 'M');
    expect(ChordDescriptor.mmaj7.toNashville(), 'mmaj7');
    expect(ChordDescriptor.dominant13.toNashville(), '13');
    expect(ChordDescriptor.msus2.toNashville(), 'msus2');
    expect(ChordDescriptor.sevenSharp9.toNashville(), '7#9');
    expect(ChordDescriptor.sevenFlat9.toNashville(), '7b9');
    expect(ChordDescriptor.sevenFlat5.toNashville(), '7b5');
    expect(ChordDescriptor.suspended7.toNashville(), 'sus7');
    expect(ChordDescriptor.minor13.toNashville(), 'm13');
    expect(ChordDescriptor.augmented5.toNashville(), '+');
    expect(ChordDescriptor.jazz7b9.toNashville(), 'jazz7b9');
    expect(ChordDescriptor.capMajor7.toNashville(), 'Maj7');
    expect(ChordDescriptor.deltaMajor7.toNashville(), 'Δ');
    expect(ChordDescriptor.dimMasculineOrdinalIndicator.toNashville(), 'º');
    expect(ChordDescriptor.dimMasculineOrdinalIndicator7.toNashville(), 'º7');
    expect(ChordDescriptor.diminishedAsCircle.toNashville(), '°');
    expect(ChordDescriptor.madd9.toNashville(), 'madd9');
    expect(ChordDescriptor.maug.toNashville(), 'maug');
    expect(ChordDescriptor.majorNine.toNashville(), 'M9');
    expect(ChordDescriptor.nineSus4.toNashville(), '9sus4');
    expect(ChordDescriptor.flat5.toNashville(), 'flat5');
    expect(ChordDescriptor.sevenSus2.toNashville(), '7sus2');
  });

  test('nashville experiments', () {
    const int beatsPerBar = 4;
    int bpm = 106;
    {
      var a = Song.createSong('a simple song', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.G), bpm, beatsPerBar,
          4, 'pearl bob', 'i: D C G G x2  v: G G G G, C C G G o: C C G G', 'i: (instrumental)\nv: line 1\no:\n');

      logger.i(a.toNashville());
      expect(a.toNashville(), '''I:  |  5 4 1 1    x2
V:  |  1 1 1 1     4 4 1 1
O:  |  4 4 1 1''');
    }

    {
      List<Song> list = Song.songListFromJson(sampleSongString);
      Song a = list[0];

      //logger.i(a.toJsonAsFile());
      logger.i(a.toNashville());
      expect(a.toNashville(), '''I:  |  1 3-/7 6- 5 4 4
V:  |  1 3- 4 1    x4
C:  |  1 4 1 4     1 4     4 4 4 4     1 3-/7 6- 5 4 4
V:  |  1 3- 4 1    x4
C:  |  1 4 1 4     1 4     4 4 4 4     1 3-/7 6- 5 4 4
V:  |  1 3- 4 1    x4
C:  |  1 4 1 4     1 4     4 4 4 4     1 3-/7 6- 5 4 4
V:  |  1 3- 4 1    x4
C:  |  1 4 1 4     1 4     4 4 4 4     1 3-/7 6- 5 4 4
V:  |  1 3- 4 1    x4
C:  |  1 4 1 4     1 4     4 4 4 4     1 3-/7 6- 5 4 4
O:  |  1 3-/7 6- 5 4 4''');
    }
  });
}

const String sampleSongString = '''
{
"title": "Weight, The",
"artist": "Band, The",
"user": "Unknown",
"lastModifiedDate": 1548220620527,
"copyright": "Bob Dylan Music Obo Dwarf Music",
"key": "A",
"defaultBpm": 100,
"timeSignature": "4/4",
"chords": 
    [
	"I:",
	"AC♯m/G♯ F♯mE D D",
	"V:",
	"A C♯m D A x4",
	"C:",
	"A D A D",
	"A D",
	"D D D D.",
	"AC♯m/G♯ F♯mE D D",
	"O:",
	"AC♯m/G♯ F♯mE D D"
    ],
"lyrics": 
    [
	"i:",
	"v:",
	"I pulled into Nazareth, was feeling 'bout half past dead",
	"I just need some place where I can lay my head",
	"Hey, mister, can you tell me, where a man might find a bed?",
	"He just grinned and shook my hand, \\"No\\" was all he said.",
	"c:",
	"Take a load off Fanny, take a load for free",
	"Take a load off Fanny, and you put the load right on me",
	"v:",
	"I picked up my bags, I went looking for a place to hide",
	"When I saw old Carmen and the Devil, walking side by side",
	"I said, \\"Hey, Carmen, c'mon, let's go downtown\\"",
	"She said, \\"I gotta go, but my friend can stick around\\"",
	"",
	"c:",
	"Take a load off Fanny, take a load for free",
	"Take a load off Fanny, and you put the load right on me",
	"V:",
	"Go down, Miss Moses, ain't nothin' you can say",
	"It's just old Luke, and Luke's waiting on the judgment day",
	"Well, Luke, my friend, what about young Annalee",
	"He said, \\"Do me a favor, son, won't you stay and keep Annalee company\\"",
	"c:",
	"Take a load off Fanny, take a load for free",
	"Take a load off Fanny, and you put the load right on me",
	"v:",
	"Crazy Chester followed me, and he caught me in the fog",
	"Said, \\"I will fix your rag, if you'll take Jack, my dog\\"",
	"I said, \\"Wait a minute Chester, you know, I'm a peaceful man\\"",
	"He said, \\"That's okay, boy, won't you feed him when you can\\"",
	"c:",
	"Take a load off Fanny, take a load for free",
	"Take a load off Fanny, and you put the load right on me",
	"v:",
	"Catch the cannonball, now to take me down the line",
	"My bag is sinking low, and I do believe it's time",
	"To get back to Miss Fanny, you know she's the only one",
	"Who sent me here, with her regards for everyone",
	"c:",
	"Take a load off Fanny, take a load for free",
	"Take a load off Fanny, and you put the load right on me",
	"o:"
    ]
}
''';
