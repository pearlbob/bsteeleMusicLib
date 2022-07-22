import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/chordSection.dart';
import 'package:bsteeleMusicLib/songs/key.dart' as music_key;
import 'package:bsteeleMusicLib/songs/key.dart';
import 'package:bsteeleMusicLib/songs/measure.dart';
import 'package:bsteeleMusicLib/songs/nashvilleNote.dart';
import 'package:bsteeleMusicLib/songs/song.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('nashville experiments', () {
    final int beatsPerBar = 4;
    int bpm = 106;
    {
      var a = Song.createSong('a simple song', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.G), bpm, beatsPerBar,
          4, 'pearl bob', 'i: D C G G x2  v: G G G G, C C G G o: C C G G', 'i: (instrumental)\nv: line 1\no:\n');

      logger.i(roughNashvilleTranspose(a));
    }

    {
      List<Song> list = Song.songListFromJson(sampleSongString);
      Song a = list[0];

      logger.i(roughNashvilleTranspose(a));
    }
  });
}

String roughNashvilleTranspose(Song song) {
  var grid = song.songMomentGrid;
  var sb = StringBuffer();
  sb.writeln();
  sb.writeln('song "${song.title}" in key of ${song.key}');
  ChordSection? lastChordSection;
  for (int r = 0; r < grid.getRowCount(); r++) {
    var row = grid.getRow(r);

    for (int c = 1; //  fixme: why is the first column always null?
        c < (row?.length ?? 0);
        c++) {
      var songMoment = grid.get(r, c);
      var chordSection = songMoment?.chordSection;
      if (chordSection != null && chordSection != lastChordSection) {
        lastChordSection = chordSection;
        sb.writeln(chordSection.toMarkup());
      }
      sb.write('\t');
      sb.write(nashvilleMeasure(song.key, songMoment?.measure));
    }
    sb.writeln();
  }
  return sb.toString();
}

String nashvilleMeasure(Key key, Measure? measure) {
  if (measure == null) {
    return '';
  }
  var sb = StringBuffer();
  var keyOffset = key.getHalfStep();
  for (var chord in measure.chords) {
    sb.write('${NashvilleNote.byHalfStep(chord.scaleChord.scaleNote.halfStep - keyOffset)}'
        '${chord.scaleChord.chordDescriptor.toNashville()}'
        '${chord.slashScaleNote != null ? '/${NashvilleNote.byHalfStep(chord.slashScaleNote!.halfStep - keyOffset)}' : ''}'
        ' ');
  }
  return sb.toString();
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
	"He just grinned and shook my hand, \\\"No\\\" was all he said.",
	"c:",
	"Take a load off Fanny, take a load for free",
	"Take a load off Fanny, and you put the load right on me",
	"v:",
	"I picked up my bags, I went looking for a place to hide",
	"When I saw old Carmen and the Devil, walking side by side",
	"I said, \\\"Hey, Carmen, c'mon, let's go downtown\\\"",
	"She said, \\\"I gotta go, but my friend can stick around\\\"",
	"",
	"c:",
	"Take a load off Fanny, take a load for free",
	"Take a load off Fanny, and you put the load right on me",
	"V:",
	"Go down, Miss Moses, ain't nothin' you can say",
	"It's just old Luke, and Luke's waiting on the judgment day",
	"Well, Luke, my friend, what about young Annalee",
	"He said, \\\"Do me a favor, son, won't you stay and keep Annalee company\\\"",
	"c:",
	"Take a load off Fanny, take a load for free",
	"Take a load off Fanny, and you put the load right on me",
	"v:",
	"Crazy Chester followed me, and he caught me in the fog",
	"Said, \\\"I will fix your rag, if you'll take Jack, my dog\\\"",
	"I said, \\\"Wait a minute Chester, you know, I'm a peaceful man\\\"",
	"He said, \\\"That's okay, boy, won't you feed him when you can\\\"",
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
