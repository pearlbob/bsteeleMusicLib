import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/grid.dart';
import 'package:bsteeleMusicLib/songs/key.dart';
import 'package:bsteeleMusicLib/songs/song.dart';
import 'package:bsteeleMusicLib/songs/songBase.dart';
import 'package:bsteeleMusicLib/songs/songMoment.dart';
import 'package:bsteeleMusicLib/util/util.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('test After Midnight', () {
    //  Create the song
    SongBase a = SongBase.createSongBase('After Midnight', 'Eric Clapton', 'BMG', Key.get(KeyEnum.D), 110, 4, 4, '''I:
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

    bool genCode = false; //  true false

    if (genCode) {
      for (SongMoment songMoment in a.songMoments) {
        logger.i('${songMoment.toString()}');
        logger.i('    "${songMoment.lyrics}"');
      }

      int rows = grid.getRowCount();
      for (int r = 0; r < rows; r++) {
        List<SongMoment?>? row = grid.getRow(r);
        if (row == null) throw 'row == null';
        int cols = row.length;
        for (int c = 0; c < cols; c++) {
          SongMoment? songMoment = grid.get(r, c);
          if (songMoment == null) continue;
          if (c >= 1) {
            String s = Util.quote(songMoment.lyrics) ?? 'isNull';
            s = s.isEmpty ? 'isEmpty' : s;
            logger.i('expect( grid.get($r,$c)?.lyrics, $s);');
          }
        }
      }
    }

    //  generated code here:
    expect(grid.get(0, 1)?.lyrics, '(instrumental)');
    expect(grid.get(0, 2)?.lyrics, isEmpty);
    expect(grid.get(0, 3)?.lyrics, isEmpty);
    expect(grid.get(0, 4)?.lyrics, isEmpty);
    expect(grid.get(1, 1)?.lyrics, isEmpty);
    expect(grid.get(1, 2)?.lyrics, isEmpty);
    expect(grid.get(1, 3)?.lyrics, isEmpty);
    expect(grid.get(1, 4)?.lyrics, isEmpty);
    expect(grid.get(2, 1)?.lyrics, 'After midnight We');
    expect(grid.get(2, 2)?.lyrics, 'gonna let it');
    expect(grid.get(2, 3)?.lyrics, 'all hang down');
    expect(grid.get(2, 4)?.lyrics, 'After midnight');
    expect(grid.get(3, 1)?.lyrics, 'We gonna chugalug');
    expect(grid.get(3, 2)?.lyrics, 'and shout');
    expect(grid.get(3, 3)?.lyrics, 'Gonna stimulate');
    expect(grid.get(3, 4)?.lyrics, 'some action');
    expect(grid.get(4, 1)?.lyrics, 'We gonna get some');
    expect(grid.get(4, 2)?.lyrics, 'satisfaction We gonna find');
    expect(grid.get(4, 3)?.lyrics, 'out what it');
    expect(grid.get(4, 4)?.lyrics, 'is all about');
    expect(grid.get(5, 1)?.lyrics, 'After midnight We');
    expect(grid.get(5, 2)?.lyrics, 'gonna let it');
    expect(grid.get(5, 3)?.lyrics, 'all hang down');
    expect(grid.get(5, 4)?.lyrics, 'After midnight');
    expect(grid.get(6, 1)?.lyrics, 'We gonna shake your');
    expect(grid.get(6, 2)?.lyrics, 'tambourine After midnight');
    expect(grid.get(6, 3)?.lyrics, 'Soul gonna be');
    expect(grid.get(6, 4)?.lyrics, 'peaches & cream');
    expect(grid.get(7, 1)?.lyrics, 'Gonna cause talk and suspicion');
    expect(grid.get(7, 2)?.lyrics, 'We gonna give an exhibition');
    expect(grid.get(7, 3)?.lyrics, 'We gonna find out what');
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
    expect(grid.get(11, 1)?.lyrics, 'After midnight We');
    expect(grid.get(11, 2)?.lyrics, 'gonna let it');
    expect(grid.get(11, 3)?.lyrics, 'all hang down');
    expect(grid.get(11, 4)?.lyrics, 'After midnight');
    expect(grid.get(12, 1)?.lyrics, 'We gonna shake your');
    expect(grid.get(12, 2)?.lyrics, 'tambourine After midnight');
    expect(grid.get(12, 3)?.lyrics, 'Soul gonna be');
    expect(grid.get(12, 4)?.lyrics, 'peaches & cream');
    expect(grid.get(13, 1)?.lyrics, 'Gonna cause talk and suspicion');
    expect(grid.get(13, 2)?.lyrics, 'We gonna give an exhibition');
    expect(grid.get(13, 3)?.lyrics, 'We gonna find out what');
    expect(grid.get(13, 4)?.lyrics, 'it is all about');
    expect(grid.get(14, 1)?.lyrics, 'After midnight We');
    expect(grid.get(14, 2)?.lyrics, 'gonna let it');
    expect(grid.get(14, 3)?.lyrics, 'all hang down');
    expect(grid.get(14, 4)?.lyrics, 'After midnight');
    expect(grid.get(15, 1)?.lyrics, 'We gonna let it');
    expect(grid.get(15, 2)?.lyrics, 'all hang down After');
    expect(grid.get(15, 3)?.lyrics, 'midnight We gonna let');
    expect(grid.get(15, 4)?.lyrics, 'it all hang down');
    expect(grid.get(16, 1)?.lyrics, 'After midnight We');
    expect(grid.get(16, 2)?.lyrics, 'gonna let');
    expect(grid.get(16, 3)?.lyrics, 'it all');
    expect(grid.get(16, 4)?.lyrics, 'hang down');
  });

  test('test Allison Road', () {
    //  Create the song
    SongBase a =
        SongBase.createSongBase('Allison Road', 'Gin Blossoms, The', '1994 A&M', Key.get(KeyEnum.C), 120, 4, 4, '''I1:
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
    expect(grid.get(2, 1)?.lyrics, 'I’ve lost my mind');
    expect(grid.get(2, 2)?.lyrics, 'on what I’d find');
    expect(grid.get(2, 3)?.lyrics, 'All of the pressure');
    expect(grid.get(2, 4)?.lyrics, 'that I left behind');
    expect(grid.get(3, 1)?.lyrics, 'On Allison Road');
    expect(grid.get(4, 1)?.lyrics, 'Fire’s in the');
    expect(grid.get(5, 1)?.lyrics, 'On');
    expect(grid.get(6, 1)?.lyrics, 'Dark clouds fall when');
    expect(grid.get(6, 2)?.lyrics, 'the moon was near');
    expect(grid.get(7, 1)?.lyrics, 'There’s no');
    expect(grid.get(8, 1)?.lyrics, 'And I couldn’t see I was lost at the time...');
    expect(grid.get(9, 1)?.lyrics, '(Break)');
    expect(grid.get(10, 1)?.lyrics, 'Yeah I didn’t know');
    expect(grid.get(11, 1)?.lyrics, 'So she fills up her sails');
    expect(grid.get(11, 2)?.lyrics, 'with my wasted breath And');
    expect(grid.get(11, 3)?.lyrics, 'each one’s more wasted that');
    expect(grid.get(11, 4)?.lyrics, 'the others you can bet');
    expect(grid.get(12, 1)?.lyrics, 'On Allison Road');
    expect(grid.get(13, 1)?.lyrics, 'So why not drive, on');
    expect(grid.get(14, 1)?.lyrics, 'On');
    expect(grid.get(15, 1)?.lyrics, 'And I didn’t know I');
    expect(grid.get(16, 1)?.lyrics, 'And I');
    expect(grid.get(17, 1)?.lyrics, 'All I wanted to find her tonight');
    expect(grid.get(17, 2)?.lyrics, isNull);
    expect(grid.get(17, 3)?.lyrics, isNull);
    expect(grid.get(17, 4)?.lyrics, isNull);
    expect(grid.get(18, 1)?.lyrics, '(Break)');
    expect(grid.get(18, 2)?.lyrics, 'On');
    expect(grid.get(18, 3)?.lyrics, 'Allison');
    expect(grid.get(18, 4)?.lyrics, 'Road');
    expect(grid.get(19, 1)?.lyrics, 'Yeah I didn’t know');
    expect(grid.get(20, 1)?.lyrics, '(Instrumental)');
    expect(grid.get(21, 1)?.lyrics, '');
    expect(grid.get(22, 1)?.lyrics, '(Instrumental)');
    expect(grid.get(23, 1)?.lyrics, '');
    expect(grid.get(24, 1)?.lyrics, 'I’ve lost my');
    expect(grid.get(25, 1)?.lyrics, 'Fire’s in the');
    expect(grid.get(26, 1)?.lyrics, 'On Allison Road,');
    expect(grid.get(27, 1)?.lyrics, 'On');
    expect(grid.get(27, 2)?.lyrics, 'Allison');
    expect(grid.get(27, 3)?.lyrics, 'Road');
    expect(grid.get(27, 4)?.lyrics, '');
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
    expect(grid.get(2, 1)?.lyrics, 'I’ve lost my mind');
    expect(grid.get(2, 2)?.lyrics, 'on what I’d find');
    expect(grid.get(2, 3)?.lyrics, 'All of the pressure');
    expect(grid.get(2, 4)?.lyrics, 'that I left behind');
    expect(grid.get(3, 1)?.lyrics, 'On Allison Road');
    expect(grid.get(4, 1)?.lyrics, 'Fire’s in the');
    expect(grid.get(5, 1)?.lyrics, 'On');
    expect(grid.get(6, 1)?.lyrics, 'Dark clouds fall when');
    expect(grid.get(6, 2)?.lyrics, 'the moon was near');
    expect(grid.get(7, 1)?.lyrics, 'There’s no');
    expect(grid.get(8, 1)?.lyrics, 'And I couldn’t see I was lost at the time...');
    expect(grid.get(9, 1)?.lyrics, '(Break)');
    expect(grid.get(10, 1)?.lyrics, 'Yeah I didn’t know');
    expect(grid.get(11, 1)?.lyrics, 'So she fills up her sails');
    expect(grid.get(11, 2)?.lyrics, 'with my wasted breath And');
    expect(grid.get(11, 3)?.lyrics, 'each one’s more wasted that');
    expect(grid.get(11, 4)?.lyrics, 'the others you can bet');
    expect(grid.get(12, 1)?.lyrics, 'On Allison Road');
    expect(grid.get(13, 1)?.lyrics, 'So why not drive, on');
    expect(grid.get(14, 1)?.lyrics, 'On');
    expect(grid.get(15, 1)?.lyrics, 'And I didn’t know I');
    expect(grid.get(16, 1)?.lyrics, 'And I');
    expect(grid.get(17, 1)?.lyrics, 'All I wanted to find her tonight');
    expect(grid.get(17, 2)?.lyrics, isNull);
    expect(grid.get(17, 3)?.lyrics, isNull);
    expect(grid.get(17, 4)?.lyrics, isNull);
    expect(grid.get(18, 1)?.lyrics, '(Break)');
    expect(grid.get(18, 2)?.lyrics, 'On');
    expect(grid.get(18, 3)?.lyrics, 'Allison');
    expect(grid.get(18, 4)?.lyrics, 'Road');
    expect(grid.get(19, 1)?.lyrics, 'Yeah I didn’t know');
    expect(grid.get(20, 1)?.lyrics, '(Instrumental)');
    expect(grid.get(21, 1)?.lyrics, '');
    expect(grid.get(22, 1)?.lyrics, '(Instrumental)');
    expect(grid.get(23, 1)?.lyrics, '');
    expect(grid.get(24, 1)?.lyrics, 'I’ve lost my');
    expect(grid.get(25, 1)?.lyrics, 'Fire’s in the');
    expect(grid.get(26, 1)?.lyrics, 'On Allison Road,');
    expect(grid.get(27, 1)?.lyrics, 'On');
    expect(grid.get(27, 2)?.lyrics, 'Allison');
    expect(grid.get(27, 3)?.lyrics, 'Road');
    expect(grid.get(27, 4)?.lyrics, '');
  });
}
