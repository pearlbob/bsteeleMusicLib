import 'dart:io';

import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/musicXml.dart';
import 'package:bsteeleMusicLib/songs/song.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';
import 'dart:io' show Platform;

void main() {
  Logger.level = Level.info;

  test('test musicXml parse', () {
    String musicXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="no"?><!DOCTYPE score-partwise PUBLIC
    "-//Recordare//DTD MusicXML 3.1 Partwise//EN"
    "http://www.musicxml.org/dtds/partwise.dtd">
<score-partwise version="3.1">
    <credit page="1">
        <credit-words default-x="500" default-y="150" font-size="24" justify="center"
            valign="top">test song with a really long title full of words</credit-words>
    </credit>
    <credit page="1">
        <credit-words default-x="400" default-y="50" font-size="12" justify="right"
            valign="bottom">bob</credit-words>
    </credit>
    <part-list>
        <score-part id="P1">
            <part-name>Piano</part-name>
        </score-part>
    </part-list>
    <part id="P1">
        <measure number="1">
            <attributes>
                <divisions>1</divisions>
                <key>
                    <fifths>0</fifths>
                </key>
                <time>
                    <beats>4</beats>
                    <beat-type>4</beat-type>
                </time>
                <staves>2</staves>
                <clef number="1">
                    <sign>G</sign>
                    <line>2</line>
                </clef>
                <clef number="2">
                    <sign>F</sign>
                    <line>4</line>
                </clef>
            </attributes>
            <note>
                <pitch>
                    <step>A</step>
                    <octave>4</octave>
                </pitch>
                <duration>4</duration>
                <voice>1</voice>
                <type>whole</type>
                <staff>1</staff>
            </note>
            <backup>
                <duration>4</duration>
            </backup>
            <note>
                <pitch>
                    <step>C</step>
                    <octave>3</octave>
                </pitch>
                <duration>2</duration>
                <type>half</type>
                <staff>2</staff>
            </note>
            <note>
                <pitch>
                    <step>E</step>
                    <octave>2</octave>
                </pitch>
                <duration>2</duration>
                <type>half</type>
                <staff>2</staff>
            </note>
        </measure>
        <measure number="2">
            <note>
                <pitch>
                    <step>G</step>
                    <octave>2</octave>
                </pitch>
                <duration>4</duration>
                <type>whole</type>
                <staff>2</staff>
            </note>
        </measure>
    </part>
</score-partwise>
''';
    XmlDocument doc = MusicXml.parse(musicXml);

    for (XmlElement xmlScorPartwise in doc.findElements('score-partwise')) {
      Map<String, XmlElement> partMap = {};
      for (XmlElement xmlParList in xmlScorPartwise.findElements('part-list')) {
        for (XmlElement xmlScorePart in xmlParList.findElements('score-part')) {
          String? id = xmlScorePart.getAttribute('id');
          if (id == null) {
            throw 'null from id';
          }
          partMap[id] = xmlScorPartwise.findElements('part').firstWhere((element) => element.getAttribute('id') == id);
        }
      }

      for (String scorePart in partMap.keys) {
        XmlElement? part = partMap[scorePart];
        logger.v('    scorePart: ${part}');

        for (XmlElement xmlMeasure in part?.findElements('measure') ?? []) {
          var numberAttr = xmlMeasure.getAttribute('number');
          if (numberAttr == null) {
            throw 'null number attribute';
          }
          int m = int.parse(numberAttr);
          logger.i('measure $m:');

          for (XmlNode c in xmlMeasure.children.where((c) => c.nodeType == XmlNodeType.ELEMENT)) {
            var child = c as XmlElement;
            switch (child.name.toString()) {
              case 'attributes':
                //  process the attributes
                XmlElement xmlMeasureAttributes = child;
                for (XmlElement xmlAttribute in xmlMeasureAttributes.findElements('divisions')) {
                  logger.i('   divisions: ${int.parse(xmlAttribute.text)}');
                }
                for (XmlElement xmlAttribute in xmlMeasureAttributes.findElements('key')) {
                  for (XmlElement xmlfifths in xmlAttribute.findElements('fifths')) {
                    logger.i('   fifths: ${int.parse(xmlfifths.text)}');
                  }
                }
                for (XmlElement xmlAttribute in xmlMeasureAttributes.findElements('time')) {
                  for (XmlElement xmlbeats in xmlAttribute.findElements('beats')) {
                    logger.i('   beats: ${int.parse(xmlbeats.text)}');
                  }
                  for (XmlElement xmlbeatType in xmlAttribute.findElements('beat-type')) {
                    logger.i('   beatType: ${int.parse(xmlbeatType.text)}');
                  }
                }
                for (XmlElement e in xmlMeasureAttributes.findElements('staves')) {
                  logger.i('   staves: ${int.parse(e.text)}');
                }
                for (XmlElement e in xmlMeasureAttributes.findElements('staves')) {
                  logger.i('   staves: ${int.parse(e.text)}');
                }
                for (XmlElement xmlClef in xmlMeasureAttributes.findElements('clef')) {
                  var numberAttr = xmlMeasure.getAttribute('number');
                  if (numberAttr == null) {
                    throw 'null number attribute';
                  }
                  int clefNumber = int.parse(numberAttr);
                  logger.i('   clef: $clefNumber');
                  for (XmlElement xmlSign in xmlClef.findElements('sign')) {
                    logger.i('     sign: ${xmlSign.text}');
                  }
                  for (XmlElement e in xmlClef.findElements('line')) {
                    logger.i('     line: ${int.parse(e.text)}');
                  }
                }
                break;
              case 'note':
                XmlElement xmlNote = child;
                logger.i('   note:');
                for (XmlElement xmlPitch in xmlNote.findElements('pitch')) {
                  logger.i('     pitch:');
                  for (XmlElement e in xmlPitch.findElements('step')) {
                    logger.i('       step: "${e.text}"');
                  }
                  for (XmlElement e in xmlPitch.findElements('octave')) {
                    logger.i('       octave: ${int.parse(e.text)}');
                  }
                  // logger.i('     pitch: ${int.parse(xmlPitch.text)}');
                }
                for (XmlElement e in xmlNote.findElements('duration')) {
                  logger.i('     duration: ${int.parse(e.text)}');
                }
                for (XmlElement e in xmlNote.findElements('voice')) {
                  logger.i('     voice: ${int.parse(e.text)}');
                }
                for (XmlElement e in xmlNote.findElements('type')) {
                  logger.i('     type: "${e.text}"');
                }
                for (XmlElement e in xmlNote.findElements('staff')) {
                  logger.i('     staff: ${int.parse(e.text)}');
                }
                break;
              case 'backup':
                logger.i('   backup:');
                for (XmlElement e in child.findElements('duration')) {
                  logger.i('     duration: ${int.parse(e.text)}');
                }
                break;
              default:
                logger.w('Unknown child: ${child.name}');
                break;
            }
          }
        }
      }
    }

    logger.i('done');
  });

  test('musicxml generation test', () {

    List<Song> list = Song.songListFromJson(sampleSongString);
    Song song = list[0];

    MusicXml musicXml = MusicXml();
    String songAsMusicXml = musicXml.songAsMusicXml(song);

    {
      var allMatches = RegExp(r'$', multiLine: true).allMatches(songAsMusicXml);
      expect(allMatches, isNotNull);
      expect(allMatches.length, 5186);
    }

    StringBuffer sb = StringBuffer();
    {
      logger.v(songAsMusicXml);
      var allMatches = RegExp(r'^((?!\s*<encoding-date>\d{4}-\d{2}-\d{2}</encoding-date>\s*).)*$', multiLine: true)
          .allMatches(songAsMusicXml);
      expect(allMatches, isNotNull);

      for (var m in allMatches) {
        sb.writeln(m.group(0));
      }
      logger.d('found: ${allMatches.length} lines');
      expect(allMatches.length, 5185);
    }

    logger.d('found: ${sb.toString()}');
    //fixme: expect(sb.toString().hashCode, 993339470); //  found empirically

    if (Logger.level == Level.debug) {
      Map<String, String> envVars = Platform.environment;
      logger.w('fixme: shouldn\'t be writing a file as part of a test!!!!!!!!!!!!!!!!!');
      final filename = '${envVars['HOME']}/junk/genTest.musicxml';
      File(filename).writeAsString(songAsMusicXml, flush: true).then((File file) {
        logger.i('done');
        logger.i(DateFormat.yMMMd().format(DateTime.now()));
        // Do something with the file.... try musescore
      });
    }
  });

  test('musicxml round trip test', () {

    List<Song> list = Song.songListFromJson(sampleSongString);
    Song a = list[0];

    MusicXml musicXml = MusicXml();
    String songAsMusicXml = musicXml.songAsMusicXml(a);

    Song b = MusicXml.songFromMusicXml( songAsMusicXml);
    logger.i(b.toJson());// fixme: complete this test


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
