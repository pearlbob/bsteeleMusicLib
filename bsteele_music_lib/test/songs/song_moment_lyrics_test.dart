import 'package:bsteeleMusicLib/app_logger.dart';
import 'package:bsteeleMusicLib/grid.dart';
import 'package:bsteeleMusicLib/songs/key.dart';
import 'package:bsteeleMusicLib/songs/song.dart';
import 'package:bsteeleMusicLib/songs/song_base.dart';
import 'package:bsteeleMusicLib/songs/song_moment.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('test songmoment.lyrics', () {
    //  Create the song
    SongBase a = SongBase.createSongBase('After Midnight', 'Eric Clapton', 'BMG', Key.D, 110, 4, 4, '''I:
D FG D D x2
V:
D FG D D x2
D G G A
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

    List<SongMoment> songMoments = a.songMoments;

    // {
    //   for (SongMoment songMoment in a.songMoments) {
    //     logger.i('${songMoment.toString()}');
    //     logger.i('    "${songMoment.lyrics}"');
    //   }
    //
    //   int rows = grid.getRowCount();
    //   for (int r = 0; r < rows; r++) {
    //     List<SongMoment?>? row = grid.getRow(r);
    //     if (row == null) throw 'row == null';
    //     int cols = row.length;
    //     for (int c = 0; c < cols; c++) {
    //       SongMoment? songMoment = grid.get(r, c);
    //       if (songMoment == null) continue;
    //       if (c >= 1) {
    //         String s = Util.quote(songMoment.lyrics) ?? 'isNull';
    //         s = s.isEmpty ? 'isEmpty' : s;
    //         logger.i('expect( grid.get($r,$c)?.lyrics, $s);');
    //       }
    //     }
    //   }
    // }

    //  generated code here:
    expect(songMoments[0].lyrics, '(instrumental)');
    expect(songMoments[1].lyrics, '');
    expect(songMoments[2].lyrics, '');
    expect(songMoments[3].lyrics, '');
    expect(songMoments[4].lyrics, '');
    expect(songMoments[5].lyrics, '');
    expect(songMoments[6].lyrics, '');
    expect(songMoments[7].lyrics, '');
    expect(
        songMoments[8].lyrics,
        'After midnight\n'
        'We gonna');
    expect(songMoments[9].lyrics, 'let it');
    expect(songMoments[10].lyrics, 'all hang');
    expect(songMoments[11].lyrics, 'down\n'
        'After midnight');
    expect(songMoments[12].lyrics, 'We gonna');
    expect(songMoments[13].lyrics, 'chugalug and');
    expect(songMoments[14].lyrics, 'shout\n''Gonna stimulate');
    expect(songMoments[15].lyrics, 'some action');
    expect(songMoments[16].lyrics, 'We gonna get some');
    expect(songMoments[17].lyrics, 'satisfaction\n'
        'We gonna find');
    expect(songMoments[18].lyrics, 'out what it');
    expect(songMoments[19].lyrics, 'is all about');
    expect(songMoments[20].lyrics, 'After midnight\n'
        'We gonna');
    expect(songMoments[21].lyrics, 'let it');
    expect(songMoments[22].lyrics, 'all hang');
    expect(songMoments[23].lyrics, 'down\n'
        'After midnight');
    expect(songMoments[24].lyrics, 'We gonna shake');
    expect(songMoments[25].lyrics, 'your tambourine\n'
        'After midnight\n'
        'Soul');
    expect(songMoments[26].lyrics, 'gonna be peaches');
    expect(songMoments[27].lyrics, '& cream');
    expect(songMoments[28].lyrics, 'Gonna cause talk and suspicion\n'
        'We');
    expect(songMoments[28].lyrics, 'Gonna cause talk and suspicion\n'
        'We');
    expect(songMoments[30].lyrics, 'gonna find out what');
    expect(songMoments[31].lyrics, 'it is all about');
    expect(songMoments[32].lyrics, '(instrumental)');
    expect(songMoments[33].lyrics, isEmpty);
    expect(songMoments[34].lyrics, isEmpty);
    expect(songMoments[35].lyrics, isEmpty);
    expect(songMoments[36].lyrics, isEmpty);
    expect(songMoments[37].lyrics, isEmpty);
    expect(songMoments[38].lyrics, isEmpty);
    expect(songMoments[39].lyrics, isEmpty);
    expect(songMoments[40].lyrics, isEmpty);
    expect(songMoments[41].lyrics, isEmpty);
    expect(songMoments[42].lyrics, isEmpty);
    expect(songMoments[43].lyrics, isEmpty);
    expect(songMoments[44].lyrics, 'After midnight\n'
        'We gonna');
    expect(songMoments[45].lyrics, 'let it');
    expect(songMoments[46].lyrics, 'all hang');
    expect(songMoments[47].lyrics, 'down\n'
             'After midnight');
    expect(songMoments[48].lyrics, 'We gonna shake');
    expect(songMoments[49].lyrics, 'your tambourine\n'
        'After midnight\n'
        'Soul');
    expect(songMoments[50].lyrics, 'gonna be peaches');
    expect(songMoments[51].lyrics, '& cream');
    expect(songMoments[52].lyrics, 'Gonna cause talk and suspicion\n'
        'We');
    expect(songMoments[53].lyrics, 'gonna give an exhibition\n'
        'We');
    expect(songMoments[54].lyrics, 'gonna find out what');
    expect(songMoments[55].lyrics, 'it is all about');
    expect(songMoments[56].lyrics, 'After midnight\n'
        'We gonna');
    expect(songMoments[57].lyrics, 'let it');
    expect(songMoments[58].lyrics, 'all hang');
    expect(songMoments[59].lyrics, 'down\n'
        'After midnight');
    expect(songMoments[60].lyrics, 'We gonna let it');
    expect(songMoments[61].lyrics, 'all hang down\n'
        'After midnight\n'
        'We');
    expect(songMoments[62].lyrics, 'gonna let it'
    );
    expect(songMoments[63].lyrics, 'all hang down');
    expect(songMoments[64].lyrics, 'After midnight\n'
        'We'
    );
    expect(songMoments[65].lyrics, 'gonna let');
    expect(songMoments[66].lyrics, 'it all');
    expect(songMoments[67].lyrics, 'hang down');
    expect(songMoments.length, 68);

  });

  test('test After Midnight', () {
    //  Create the song
    SongBase a = SongBase.createSongBase('After Midnight', 'Eric Clapton', 'BMG', Key.D, 110, 4, 4, '''I:
D FG D D x2
V:
D FG D D x2
D G G A
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

    // {
    //   for (SongMoment songMoment in a.songMoments) {
    //     logger.i('${songMoment.toString()}');
    //     logger.i('    "${songMoment.lyrics}"');
    //   }
    //
    //   int rows = grid.getRowCount();
    //   for (int r = 0; r < rows; r++) {
    //     List<SongMoment?>? row = grid.getRow(r);
    //     if (row == null) throw 'row == null';
    //     int cols = row.length;
    //     for (int c = 0; c < cols; c++) {
    //       SongMoment? songMoment = grid.get(r, c);
    //       if (songMoment == null) continue;
    //       if (c >= 1) {
    //         String s = Util.quote(songMoment.lyrics) ?? 'isNull';
    //         s = s.isEmpty ? 'isEmpty' : s;
    //         logger.i('expect( grid.get($r,$c)?.lyrics, $s);');
    //       }
    //     }
    //   }
    // }

    //  generated code here:
    expect(grid.get(0, 1)?.lyrics, '(instrumental)');
    expect(grid.get(0, 2)?.lyrics, isEmpty);
    expect(grid.get(0, 3)?.lyrics, isEmpty);
    expect(grid.get(0, 4)?.lyrics, isEmpty);
    expect(grid.get(1, 1)?.lyrics, isEmpty);
    expect(grid.get(1, 2)?.lyrics, isEmpty);
    expect(grid.get(1, 3)?.lyrics, isEmpty);
    expect(grid.get(1, 4)?.lyrics, isEmpty);
    expect(
        grid.get(2, 1)?.lyrics,
        'After midnight\n'
        'We gonna');
    expect(grid.get(2, 2)?.lyrics, 'let it');
    expect(grid.get(2, 3)?.lyrics, 'all hang');
    expect(
        grid.get(2, 4)?.lyrics,
        'down\n'
        'After midnight');
    expect(grid.get(3, 1)?.lyrics, 'We gonna');
    expect(grid.get(3, 2)?.lyrics, 'chugalug and');
    expect(
        grid.get(3, 3)?.lyrics,
        'shout\n'
        'Gonna stimulate');
    expect(grid.get(3, 4)?.lyrics, 'some action');
    expect(grid.get(4, 1)?.lyrics, 'We gonna get some');
    expect(
        grid.get(4, 2)?.lyrics,
        'satisfaction\n'
        'We gonna find');
    expect(grid.get(4, 3)?.lyrics, 'out what it');
    expect(grid.get(4, 4)?.lyrics, 'is all about');
    expect(
        grid.get(5, 1)?.lyrics,
        'After midnight\n'
        'We gonna');
    expect(grid.get(5, 2)?.lyrics, 'let it');
    expect(grid.get(5, 3)?.lyrics, 'all hang');
    expect(
        grid.get(5, 4)?.lyrics,
        'down\n'
        'After midnight');
    expect(grid.get(6, 1)?.lyrics, 'We gonna shake');
    expect(
        grid.get(6, 2)?.lyrics,
        'your tambourine\n'
        'After midnight\n'
        'Soul');
    expect(grid.get(6, 3)?.lyrics, 'gonna be peaches');
    expect(grid.get(6, 4)?.lyrics, '& cream');
    expect(
        grid.get(7, 1)?.lyrics,
        'Gonna cause talk and suspicion\n'
        'We');
    expect(
        grid.get(7, 2)?.lyrics,
        'gonna give an exhibition\n'
        'We');
    expect(grid.get(7, 3)?.lyrics, 'gonna find out what');
    expect(grid.get(7, 4)?.lyrics, 'it is all about');
    expect(grid.get(8, 1)?.lyrics, '(instrumental)');
    expect(grid.get(8, 2)?.lyrics, isEmpty);
    expect(grid.get(8, 3)?.lyrics, isEmpty);
    expect(grid.get(8, 4)?.lyrics, isEmpty);
    expect(grid.get(9, 1)?.lyrics, isEmpty);
    expect(grid.get(9, 2)?.lyrics, isEmpty);
    expect(grid.get(9, 3)?.lyrics, isEmpty);
    expect(grid.get(9, 4)?.lyrics, isEmpty);
    expect(grid.get(10, 1)?.lyrics, isEmpty);
    expect(grid.get(10, 2)?.lyrics, isEmpty);
    expect(grid.get(10, 3)?.lyrics, isEmpty);
    expect(grid.get(10, 4)?.lyrics, isEmpty);
    expect(
        grid.get(11, 1)?.lyrics,
        'After midnight\n'
        'We gonna');
    expect(grid.get(11, 2)?.lyrics, 'let it');
    expect(grid.get(11, 3)?.lyrics, 'all hang');
    expect(
        grid.get(11, 4)?.lyrics,
        'down\n'
        'After midnight');
    expect(grid.get(12, 1)?.lyrics, 'We gonna shake');
    expect(
        grid.get(12, 2)?.lyrics,
        'your tambourine\n'
        'After midnight\n'
        'Soul');
    expect(grid.get(12, 3)?.lyrics, 'gonna be peaches');
    expect(grid.get(12, 4)?.lyrics, '& cream');
    expect(
        grid.get(13, 1)?.lyrics,
        'Gonna cause talk and suspicion\n'
        'We');
    expect(
        grid.get(13, 2)?.lyrics,
        'gonna give an exhibition\n'
        'We');
    expect(grid.get(13, 3)?.lyrics, 'gonna find out what');
    expect(grid.get(13, 4)?.lyrics, 'it is all about');
    expect(
        grid.get(14, 1)?.lyrics,
        'After midnight\n'
        'We gonna');
    expect(grid.get(14, 2)?.lyrics, 'let it');
    expect(grid.get(14, 3)?.lyrics, 'all hang');
    expect(
        grid.get(14, 4)?.lyrics,
        'down\n'
        'After midnight');
    expect(grid.get(15, 1)?.lyrics, 'We gonna let it');
    expect(
        grid.get(15, 2)?.lyrics,
        'all hang down\n'
        'After midnight\n'
        'We');
    expect(grid.get(15, 3)?.lyrics, 'gonna let it');
    expect(grid.get(15, 4)?.lyrics, 'all hang down');
    expect(
        grid.get(16, 1)?.lyrics,
        'After midnight\n'
        'We');
    expect(grid.get(16, 2)?.lyrics, 'gonna let');
    expect(grid.get(16, 3)?.lyrics, 'it all');
    expect(grid.get(16, 4)?.lyrics, 'hang down');
  });

  test('test Allison Road', () {
    //  Create the song
    SongBase a =
    SongBase.createSongBase('Allison Road', 'Gin Blossoms, The', '1994 A&M', Key.C, 120, 4, 4, '''I1:
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

    if (Logger.level.index <= Level.debug.index) {
      logger.i('=======');
      for (SongMoment songMoment in a.songMoments) {
        logger.i(songMoment.toString());
      }
      logger.i('=======');
    }

    Grid<SongMoment> grid = a.songMomentGrid;

    // {
    //   //  generate code for this test
    //   int rows = grid.getRowCount();
    //
    //   for (int r = 0; r < rows; r++) {
    //     List<SongMoment?>? row = grid.getRow(r);
    //     if (row == null) {
    //       continue;
    //     }
    //     int cols = row.length;
    //     for (int c = 0; c < cols; c++) {
    //       var songMoment = grid.get(r, c);
    //       if (songMoment == null) continue;
    //       if (c == 1) {
    //         logger.i('expect( grid.get($r,$c)?.lyrics, ${Util.quote(songMoment.lyrics)});');
    //       }
    //     }
    //   }
    // }

    if (Logger.level.index <= Level.debug.index) {
      logger.i('grid: -------');
      for (var r = 0; r < grid.getRowCount(); r++) {
        var row = grid.getRow(r);
        if (row != null) {
          for (var c = 0; c < row.length; c++) {
            var songMoment = grid.get(r, c);
            if (songMoment != null) {
              logger.i('($r,$c): ${songMoment.toString()}: ${songMoment.lyricSection} "${songMoment.lyrics}"');
            }
          }
        }
        logger.i('-------');
      }
    }

    expect(grid.get(0, 1)?.lyrics, '(Instrumental)');
    expect(grid.get(1, 1)?.lyrics, '');
    expect(grid.get(2, 1)?.lyrics, 'I’ve lost my mind');
    expect(
        grid.get(3, 1)?.lyrics,
        'On Allison Road\n'
        'Fools');
    expect(grid.get(4, 1)?.lyrics, 'Fire’s in the');
    expect(grid.get(5, 1)?.lyrics, 'On');
    expect(grid.get(6, 1)?.lyrics, 'Dark clouds fall when');
    expect(grid.get(7, 1)?.lyrics, 'There’s no');
    expect(grid.get(8, 1)?.lyrics, 'And I couldn’t see I was lost at the time...');
    expect(
        grid.get(9, 1)?.lyrics,
        '(Break)\n'
        'On');
    expect(grid.get(10, 1)?.lyrics, 'Yeah I didn’t');
    expect(grid.get(11, 1)?.lyrics, 'So she fills up her');
    expect(
        grid.get(12, 1)?.lyrics,
        'On Allison Road\n'
        'Now');
    expect(grid.get(13, 1)?.lyrics, 'So why not drive,');
    expect(grid.get(14, 1)?.lyrics, 'On');
    expect(grid.get(15, 1)?.lyrics, 'And I didn’t know');
    expect(grid.get(16, 1)?.lyrics, 'And I');
    expect(grid.get(17, 1)?.lyrics, 'All I wanted to find her tonight');
    expect(
        grid.get(18, 1)?.lyrics,
        '(Break)\n'
        'On');
    expect(grid.get(19, 1)?.lyrics, 'Yeah I didn’t');
    expect(grid.get(20, 1)?.lyrics, '(Instrumental)');
    expect(grid.get(21, 1)?.lyrics, '');
    expect(grid.get(22, 1)?.lyrics, '(Instrumental)');
    expect(grid.get(23, 1)?.lyrics, '');
    expect(grid.get(24, 1)?.lyrics, 'I’ve lost');
    expect(grid.get(25, 1)?.lyrics, 'Fire’s in the');
    expect(grid.get(26, 1)?.lyrics, 'On Allison');
    expect(grid.get(27, 1)?.lyrics, 'On');
  });

  test('test Allison Road from json', () {
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
	"BR:",
	"Dark clouds fall when the moon was near",
	"Birds fly by a.m. in her bedroom stare",
	"There’s no telling what I might find",
	"And I couldn’t see I was lost at the time...",
	"C: ",
	"(Break)",
	"On Allison Road",
	"Yeah I didn’t know I was lost at the time",
	"On Allison Road",
	"V:",
	"So she fills up her sails with my wasted breath",
	"And each one’s more wasted that the others you can bet",
	"On Allison Road",
	"Now I can’t hide, on Allison Road",
	"So why not drive, on Allison Road",
	"I know I wanna love her but I can’t decide",
	"On Allison Road",
	"BR:",
	"And I didn’t know I was lost at the time",
	"Eyes in the sun, road wasn’t wide",
	"And I went looking for an exit sign",
	"All I wanted to find her tonight",
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
        logger.d(songMoment.toString());
      }
      logger.d('=======');
    }

    //  pirated from above:
    expect(grid.get(0, 1)?.lyrics, '(Instrumental)');
    expect(grid.get(1, 1)?.lyrics, '');
    expect(grid.get(2, 1)?.lyrics, 'I’ve lost my mind');
    expect(
        grid.get(3, 1)?.lyrics,
        'On Allison Road\n'
        'Fools');
    expect(grid.get(4, 1)?.lyrics, 'Fire’s in the');
    expect(grid.get(5, 1)?.lyrics, 'On');
    expect(grid.get(6, 1)?.lyrics, 'Dark clouds fall when');
    expect(grid.get(7, 1)?.lyrics, 'There’s no');
    expect(grid.get(8, 1)?.lyrics, 'And I couldn’t see I was lost at the time...');
    expect(
        grid.get(9, 1)?.lyrics,
        '(Break)\n'
        'On');
    expect(grid.get(10, 1)?.lyrics, 'Yeah I didn’t');
    expect(grid.get(11, 1)?.lyrics, 'So she fills up her');
    expect(
        grid.get(12, 1)?.lyrics,
        'On Allison Road\n'
        'Now');
    expect(grid.get(13, 1)?.lyrics, 'So why not drive,');
    expect(grid.get(14, 1)?.lyrics, 'On');
    expect(grid.get(15, 1)?.lyrics, 'And I didn’t know');
    expect(grid.get(16, 1)?.lyrics, 'And I');
    expect(grid.get(17, 1)?.lyrics, 'All I wanted to find her tonight');
    expect(
        grid.get(18, 1)?.lyrics,
        '(Break)\n'
        'On');
    expect(grid.get(19, 1)?.lyrics, 'Yeah I didn’t');
    expect(grid.get(20, 1)?.lyrics, '(Instrumental)');
    expect(grid.get(21, 1)?.lyrics, '');
    expect(grid.get(22, 1)?.lyrics, '(Instrumental)');
    expect(grid.get(23, 1)?.lyrics, '');
    expect(grid.get(24, 1)?.lyrics, 'I’ve lost');
    expect(grid.get(25, 1)?.lyrics, 'Fire’s in the');
    expect(grid.get(26, 1)?.lyrics, 'On Allison');
    expect(grid.get(27, 1)?.lyrics, 'On');
  });
}
