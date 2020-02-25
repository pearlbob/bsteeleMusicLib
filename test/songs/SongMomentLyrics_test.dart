import 'package:bsteeleMusicLib/grid.dart';
import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/ChordSection.dart';
import 'package:bsteeleMusicLib/songs/Key.dart';
import 'package:bsteeleMusicLib/songs/Song.dart';
import 'package:bsteeleMusicLib/songs/SongBase.dart';
import 'package:bsteeleMusicLib/songs/SongMoment.dart';
import 'package:bsteeleMusicLib/util/util.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test("test song moment lyrics distribution", () {
    List<String> lyricsData = [
      'bob, bob, bob berand',
      'please take my hand',
      'you got me rockn and rolln',
      'bob berand',
      'dude',
      '',
      'when and saw',
      'betty lew',
      "i don't know more",
    ];
    for (int lines = 0; lines < lyricsData.length; lines++) {
      //  Generate the lyrics lines for the given number of lines
      String lyrics = '';
      for (int i = 0; i < lines; i++) {
        lyrics = (lyrics.isEmpty
            ? 'v:\n$i ${lyricsData[i]}'
            : '$lyrics\n$i ${lyricsData[i]}');
      }
      logger.i('\nlines: $lines\n$lyrics');

      //  Create the song
      SongBase a = SongBase.createSongBase("A", "bob", "bsteele.com",
          Key.getDefault(), 100, 4, 4, "v: A B C D x2", lyrics);
      logger.d('lines: $lines');
      logger.d('lyrics: ${a.rawLyrics}');

      Grid<SongMoment> grid = a.songMomentGrid;
      int rows = grid.getRowCount();
      ChordSection chordSection;
      for (int r = 0; r < rows; r++) {
        List<SongMoment> row = grid.getRow(r);
        int cols = row.length;
        String rowLyrics;
        for (int c = 0; c < cols; c++) {
          SongMoment songMoment = grid.get(r, c);
          if (songMoment == null) continue;

          //  Change of section is a change in lyrics... typically.
          if (songMoment.chordSection != chordSection) {
            chordSection = songMoment.chordSection;
            rowLyrics = null;
          }

          //  All moments in the row have the same lyrics
          if (rowLyrics == null)
            rowLyrics = songMoment.lyrics;
          else
            expect(songMoment.lyrics, rowLyrics);
          logger.d('($r,$c) ${songMoment.toString()}: ${songMoment.lyrics}');
        }
      }
    }
  });

  test("test After Midnight", () {
    //  Create the song
    SongBase a = SongBase.createSongBase("After Midnight", "Eric Clapton",
        "BMG", Key.get(KeyEnum.D), 110, 4, 4, '''I:
D FG D D x2
V:
D FG D D x2
D G G A
A
O:
D FG D D x3''', '''I: (instrumental)

V:
After midnight
We gonna let it all hang down
After midnight
We gonna chugalug and shout
Gonna stimulate some action
We gonna get some satisfaction
We gonna find out what it is all about

V: After midnight
We gonna let it all hang down
After midnight
We gonna shake your tambourine
After midnight
Soul gonna be peaches & cream
Gonna cause talk and suspicion
We gonna give an exhibition
We gonna find out what it is all about

V: (instrumental)

V: After midnight
We gonna let it all hang down
After midnight
We gonna shake your tambourine
After midnight
Soul gonna be peaches & cream
Gonna cause talk and suspicion
We gonna give an exhibition
We gonna find out what it is all about


O: After midnight
We gonna let it all hang down
After midnight
We gonna let it all hang down
After midnight
We gonna let it all hang down
After midnight
We gonna let it all hang down
''');

    Grid<SongMoment> grid = a.songMomentGrid;

    bool genCode = false;

    if (genCode) {
      {
        for (SongMoment songMoment in a.songMoments) {
          logger.i('${songMoment.toString()}');
        }
      }

      int rows = grid.getRowCount();

      for (int r = 0; r < rows; r++) {
        List<SongMoment> row = grid.getRow(r);
        int cols = row.length;
        for (int c = 0; c < cols; c++) {
          SongMoment songMoment = grid.get(r, c);
          if (songMoment == null) continue;
          if (c == 1)
            logger.i(
                'expect( grid.get($r,$c)?.lyrics, ${Util.quote(songMoment.lyrics)});');
        }
      }
    }

    expect(grid.get(0, 1)?.lyrics, '(instrumental)');
    expect(grid.get(1, 1)?.lyrics, '');
    expect(
        grid.get(2, 1)?.lyrics,
        'After midnight\n'
        'We gonna let it all hang down');
    expect(
        grid.get(3, 1)?.lyrics,
        'After midnight\n'
        'We gonna chugalug and shout');
    expect(
        grid.get(4, 1)?.lyrics,
        'Gonna stimulate some action\n'
        'We gonna get some satisfaction');
    expect(grid.get(5, 1)?.lyrics, 'We gonna find out what it is all about');
    expect(
        grid.get(6, 1)?.lyrics,
        'After midnight\n'
        'We gonna let it all hang down\n'
        'After midnight');
    expect(
        grid.get(7, 1)?.lyrics,
        'We gonna shake your tambourine\n'
        'After midnight');
    expect(
        grid.get(8, 1)?.lyrics,
        'Soul gonna be peaches & cream\n'
        'Gonna cause talk and suspicion');
    expect(
        grid.get(9, 1)?.lyrics,
        'We gonna give an exhibition\n'
        'We gonna find out what it is all about');
    expect(grid.get(10, 1)?.lyrics, '(instrumental)');
    expect(grid.get(11, 1)?.lyrics, '');
    expect(grid.get(12, 1)?.lyrics, '');
    expect(grid.get(13, 1)?.lyrics, '');
    expect(
        grid.get(14, 1)?.lyrics,
        'After midnight\n'
        'We gonna let it all hang down\n'
        'After midnight');
    expect(
        grid.get(15, 1)?.lyrics,
        'We gonna shake your tambourine\n'
        'After midnight');
    expect(
        grid.get(16, 1)?.lyrics,
        'Soul gonna be peaches & cream\n'
        'Gonna cause talk and suspicion');
    expect(
        grid.get(17, 1)?.lyrics,
        'We gonna give an exhibition\n'
        'We gonna find out what it is all about');
    expect(
        grid.get(18, 1)?.lyrics,
        'After midnight\n'
        'We gonna let it all hang down\n'
        'After midnight');
    expect(
        grid.get(19, 1)?.lyrics,
        'We gonna let it all hang down\n'
        'After midnight\n'
        'We gonna let it all hang down');
    expect(
        grid.get(20, 1)?.lyrics,
        'After midnight\n'
        'We gonna let it all hang down\n'
        '');
  });

  test("test Allison Road", () {
    //  Create the song
    SongBase a = SongBase.createSongBase("Allison Road", "Gin Blossoms, The",
        "1994 A&M", Key.get(KeyEnum.C), 120, 4, 4, '''I1:
AE DA AE DA
AE DA G G
I2:
G D G D
G D A A
V:
AE DA AE DA x4
C:
AE DA AE DA x2
Br:
Bm D A E
Bm D A G
G
        ''', '''I1: (Instrumental)
V:
I’ve lost my mind on what I’d find
All of the pressure that I left behind
On Allison Road
Fools in the rain if the sun gets through
Fire’s in the heaven of the eyes I knew
On Allison Road

BR:
Dark clouds fall when the moon was near
Birds fly by a.m. in her bedroom stare
There’s no telling what I might find
And I couldn’t see I was lost at the time...

C: 
(Break)
On Allison Road
Yeah I didn’t know I was lost at the time
On Allison Road

V:
So she fills up her sails with my wasted breath
And each one’s more wasted that the others you can bet
On Allison Road
Now I can’t hide, on Allison Road
So why not drive, on Allison Road
I know I wanna love her but I can’t decide
On Allison Road

BR:
And I didn’t know I was lost at the time
Eyes in the sun, road wasn’t wide
And I went looking for an exit sign
All I wanted to find her tonight

C: 
(Break)
On Allison Road
Yeah I didn’t know I was lost at the time
On Allison Road
I2: (Instrumental)
I1: (Instrumental)
V:
I’ve lost my mind
If the sun gets through
Fire’s in the heaven of the eyes I knew
On Allison Road
On Allison Road, Allison Road
I left to know
On Allison Road
''');

    Grid<SongMoment> grid = a.songMomentGrid;

    {
      logger.d('=======');
      for (SongMoment songMoment in a.songMoments) {
        logger.d('${songMoment.toString()}');
      }
      logger.d('=======');
    }

//    {
//    //  generate code for this test
//    int rows = grid.getRowCount();
//
//    for (int r = 0; r < rows; r++) {
//      List<SongMoment> row = grid.getRow(r);
//      int cols = row.length;
//      for (int c = 0; c < cols; c++) {
//        SongMoment songMoment = grid.get(r, c);
//        if (songMoment == null) continue;
//        if (c == 1)
//          logger.i('expect( grid.get($r,$c)?.lyrics, ${Util.quote(
//              songMoment.lyrics)});');
//      }
//    }
//    }

    expect(grid.get(0, 1)?.lyrics, '(Instrumental)');
    expect(grid.get(1, 1)?.lyrics, '');
    expect(
        grid.get(2, 1)?.lyrics,
        'I’ve lost my mind on what I’d find\n'
        'All of the pressure that I left behind');
    expect(
        grid.get(3, 1)?.lyrics,
        'On Allison Road\n'
        'Fools in the rain if the sun gets through');
    expect(grid.get(4, 1)?.lyrics, 'Fire’s in the heaven of the eyes I knew');
    expect(grid.get(5, 1)?.lyrics, 'On Allison Road');
    expect(
        grid.get(6, 1)?.lyrics,
        'Dark clouds fall when the moon was near\n'
        'Birds fly by a.m. in her bedroom stare');
    expect(grid.get(7, 1)?.lyrics, 'There’s no telling what I might find');
    expect(
        grid.get(8, 1)?.lyrics, 'And I couldn’t see I was lost at the time...');
    expect(
        grid.get(9, 1)?.lyrics,
        '(Break)\n'
        'On Allison Road');
    expect(
        grid.get(10, 1)?.lyrics,
        'Yeah I didn’t know I was lost at the time\n'
        'On Allison Road');
    expect(
        grid.get(11, 1)?.lyrics,
        'So she fills up her sails with my wasted breath\n'
        'And each one’s more wasted that the others you can bet');
    expect(
        grid.get(12, 1)?.lyrics,
        'On Allison Road\n'
        'Now I can’t hide, on Allison Road');
    expect(
        grid.get(13, 1)?.lyrics,
        'So why not drive, on Allison Road\n'
        'I know I wanna love her but I can’t decide');
    expect(grid.get(14, 1)?.lyrics, 'On Allison Road');
    expect(
        grid.get(15, 1)?.lyrics,
        'And I didn’t know I was lost at the time\n'
        'Eyes in the sun, road wasn’t wide');
    expect(grid.get(16, 1)?.lyrics, 'And I went looking for an exit sign');
    expect(grid.get(17, 1)?.lyrics, 'All I wanted to find her tonight');
    expect(
        grid.get(18, 1)?.lyrics,
        '(Break)\n'
        'On Allison Road');
    expect(
        grid.get(19, 1)?.lyrics,
        'Yeah I didn’t know I was lost at the time\n'
        'On Allison Road');
    expect(grid.get(20, 1)?.lyrics, '(Instrumental)');
    expect(grid.get(21, 1)?.lyrics, '');
    expect(grid.get(22, 1)?.lyrics, '(Instrumental)');
    expect(grid.get(23, 1)?.lyrics, '');
    expect(
        grid.get(24, 1)?.lyrics,
        'I’ve lost my mind\n'
        'If the sun gets through');
    expect(
        grid.get(25, 1)?.lyrics,
        'Fire’s in the heaven of the eyes I knew\n'
        'On Allison Road');
    expect(
        grid.get(26, 1)?.lyrics,
        'On Allison Road, Allison Road\n'
        'I left to know');
    expect(
        grid.get(27, 1)?.lyrics,
        'On Allison Road\n'
        '');
  });

  test("test Allison Road from json", () {
    //  Create the song
    String jsonString = '''
{ "file": "Allison Road.songlyrics", "lastModifiedDate": 1541287717212, "song": 
{
"title": "Allison Road",
"artist": "Gin Blossoms, The",
"user": "Unknown",
"lastModifiedDate": 1541287717212,
"copyright": "1994 A&M",
"key": "C",
"defaultBpm": 120,
"timeSignature": "4/4",
"chords": 
    [
	"I1:",
	"AE DA AE DA",
	"AE DA G G",
	"I2:",
	"G D G D",
	"G D A A",
	"V:",
	"AE DA AE DA x4",
	"C:",
	"AE DA AE DA x2",
	"Br:",
	"Bm D A E",
	"Bm D A G",
	"G"
    ],
"lyrics": 
    [
	"I1: (Instrumental)",
	"V:",
	"I’ve lost my mind on what I’d find",
	"All of the pressure that I left behind",
	"On Allison Road",
	"Fools in the rain if the sun gets through",
	"Fire’s in the heaven of the eyes I knew",
	"On Allison Road",
	"",
	"BR:",
	"Dark clouds fall when the moon was near",
	"Birds fly by a.m. in her bedroom stare",
	"There’s no telling what I might find",
	"And I couldn’t see I was lost at the time...",
	"",
	"C: ",
	"(Break)",
	"On Allison Road",
	"Yeah I didn’t know I was lost at the time",
	"On Allison Road",
	"",
	"V:",
	"So she fills up her sails with my wasted breath",
	"And each one’s more wasted that the others you can bet",
	"On Allison Road",
	"Now I can’t hide, on Allison Road",
	"So why not drive, on Allison Road",
	"I know I wanna love her but I can’t decide",
	"On Allison Road",
	"",
	"BR:",
	"And I didn’t know I was lost at the time",
	"Eyes in the sun, road wasn’t wide",
	"And I went looking for an exit sign",
	"All I wanted to find her tonight",
	"",
	"C: ",
	"(Break)",
	"On Allison Road",
	"Yeah I didn’t know I was lost at the time",
	"On Allison Road",
	"I2: (Instrumental)",
	"I1: (Instrumental)",
	"V:",
	"I’ve lost my mind",
	"If the sun gets through",
	"Fire’s in the heaven of the eyes I knew",
	"On Allison Road",
	"On Allison Road, Allison Road",
	"I left to know",
	"On Allison Road"
    ]
}
}
    ''';
    List<Song> shortList = Song.songListFromJson(jsonString);
    expect(shortList, isNotNull);
    expect(shortList.isNotEmpty, isTrue);
    SongBase a = shortList[0];

    Grid<SongMoment> grid = a.songMomentGrid;

    {
      logger.d('=======');
      for (SongMoment songMoment in a.songMoments) {
        logger.d('${songMoment.toString()}');
      }
      logger.d('=======');
    }

    //  pirated from above:
    expect(grid.get(0, 1)?.lyrics, '(Instrumental)');
    expect(grid.get(1, 1)?.lyrics, '');
    expect(
        grid.get(2, 1)?.lyrics,
        'I’ve lost my mind on what I’d find\n'
        'All of the pressure that I left behind');
    expect(
        grid.get(3, 1)?.lyrics,
        'On Allison Road\n'
        'Fools in the rain if the sun gets through');
    expect(grid.get(4, 1)?.lyrics, 'Fire’s in the heaven of the eyes I knew');
    expect(grid.get(5, 1)?.lyrics, 'On Allison Road');
    expect(
        grid.get(6, 1)?.lyrics,
        'Dark clouds fall when the moon was near\n'
        'Birds fly by a.m. in her bedroom stare');
    expect(grid.get(7, 1)?.lyrics, 'There’s no telling what I might find');
    expect(
        grid.get(8, 1)?.lyrics, 'And I couldn’t see I was lost at the time...');
    expect(
        grid.get(9, 1)?.lyrics,
        '(Break)\n'
        'On Allison Road');
    expect(
        grid.get(10, 1)?.lyrics,
        'Yeah I didn’t know I was lost at the time\n'
        'On Allison Road');
    expect(
        grid.get(11, 1)?.lyrics,
        'So she fills up her sails with my wasted breath\n'
        'And each one’s more wasted that the others you can bet');
    expect(
        grid.get(12, 1)?.lyrics,
        'On Allison Road\n'
        'Now I can’t hide, on Allison Road');
    expect(
        grid.get(13, 1)?.lyrics,
        'So why not drive, on Allison Road\n'
        'I know I wanna love her but I can’t decide');
    expect(grid.get(14, 1)?.lyrics, 'On Allison Road');
    expect(
        grid.get(15, 1)?.lyrics,
        'And I didn’t know I was lost at the time\n'
        'Eyes in the sun, road wasn’t wide');
    expect(grid.get(16, 1)?.lyrics, 'And I went looking for an exit sign');
    expect(grid.get(17, 1)?.lyrics, 'All I wanted to find her tonight');
    expect(
        grid.get(18, 1)?.lyrics,
        '(Break)\n'
        'On Allison Road');
    expect(
        grid.get(19, 1)?.lyrics,
        'Yeah I didn’t know I was lost at the time\n'
        'On Allison Road');
    expect(grid.get(20, 1)?.lyrics, '(Instrumental)');
    expect(grid.get(21, 1)?.lyrics, '');
    expect(grid.get(22, 1)?.lyrics, '(Instrumental)');
    expect(grid.get(23, 1)?.lyrics, '');
    expect(
        grid.get(24, 1)?.lyrics,
        'I’ve lost my mind\n'
        'If the sun gets through');
    expect(
        grid.get(25, 1)?.lyrics,
        'Fire’s in the heaven of the eyes I knew\n'
        'On Allison Road');
    expect(
        grid.get(26, 1)?.lyrics,
        'On Allison Road, Allison Road\n'
        'I left to know');
    expect(
        grid.get(27, 1)?.lyrics,
        'On Allison Road\n'
        '');
  });
}
