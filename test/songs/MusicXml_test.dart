import 'dart:io';

import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/musicXml.dart';
import 'package:system_info/system_info.dart';
import 'package:xml/xml.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';
import 'package:bsteeleMusicLib/songs/key.dart' as musicKey;

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
          String id = xmlScorePart.getAttribute('id');
          partMap[id] = xmlScorPartwise
              .findElements('part')
              .firstWhere((element) => element.getAttribute('id') == id);
        }
      }

      for (String scorePart in partMap.keys) {
        XmlElement part = partMap[scorePart];
        logger.v('    scorePart: ${part}');

        for (XmlElement xmlMeasure in part.findElements('measure')) {
          int m = int.parse(xmlMeasure.getAttribute('number'));
          logger.i('measure $m:');

          for (XmlElement child in xmlMeasure.children
              .where((c) => c.nodeType == XmlNodeType.ELEMENT)) {
            switch (child.name.toString()) {
              case 'attributes':
                //  process the attributes
                XmlElement xmlMeasureAttributes = child;
                for (XmlElement xmlAttribute
                    in xmlMeasureAttributes.findElements('divisions')) {
                  logger.i('   divisions: ${int.parse(xmlAttribute.text)}');
                }
                for (XmlElement xmlAttribute
                    in xmlMeasureAttributes.findElements('key')) {
                  for (XmlElement xmlfifths
                      in xmlAttribute.findElements('fifths')) {
                    logger.i('   fifths: ${int.parse(xmlfifths.text)}');
                  }
                }
                for (XmlElement xmlAttribute
                    in xmlMeasureAttributes.findElements('time')) {
                  for (XmlElement xmlbeats
                      in xmlAttribute.findElements('beats')) {
                    logger.i('   beats: ${int.parse(xmlbeats.text)}');
                  }
                  for (XmlElement xmlbeatType
                      in xmlAttribute.findElements('beat-type')) {
                    logger.i('   beatType: ${int.parse(xmlbeatType.text)}');
                  }
                }
                for (XmlElement e
                    in xmlMeasureAttributes.findElements('staves')) {
                  logger.i('   staves: ${int.parse(e.text)}');
                }
                for (XmlElement e
                    in xmlMeasureAttributes.findElements('staves')) {
                  logger.i('   staves: ${int.parse(e.text)}');
                }
                for (XmlElement xmlClef
                    in xmlMeasureAttributes.findElements('clef')) {
                  int clefNumber = int.parse(xmlMeasure.getAttribute('number'));
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

    musicKey.Key key = musicKey.Key.get(musicKey.KeyEnum.C);
    String xmlString = """
<?xml version="1.0" encoding="UTF-8" standalone="no"?><!DOCTYPE score-partwise PUBLIC
    "-//Recordare//DTD MusicXML 3.1 Partwise//EN"
    "http://www.musicxml.org/dtds/partwise.dtd">
<score-partwise version="3.1">
    <credit page="1">
        <credit-words default-x="500" default-y="150" font-size="24" justify="center" valign="top">
            generated test song
        </credit-words>
    </credit>
    <credit page="1">
        <credit-words default-x="400" default-y="50" font-size="12" justify="right" valign="bottom">
            bob
        </credit-words>
    </credit>
<part-list>
        <score-part id="P1">
            <part-name>Piano</part-name>
        </score-part>
    </part-list>
<part id="P1">
    <!--    the following is not by hand!   -->

""";


    {
      //  fill the measures
      int halfStep = 0;
      StringBuffer sb = StringBuffer();
      const divisions = 4;
      int measureNumber = 0;
      int beatDuration = divisions;
      int beats = 4;
      for (int i = 0; i < 16; i++) {
        if (i % beats == 0) {
          if (measureNumber > 0) {
            //  end the prior measure
            sb.write('''
</measure>
''');
          }

          //  start the next measure
          measureNumber++;
          sb.write('''

<measure number="$measureNumber">
''');


        //  first measure gets the attributes
        if (measureNumber == 1) {
          sb.write('''
    <attributes>
          <!--    allow up to 16th notes  -->
          <divisions>$divisions</divisions>
          <key>
              <fifths>0</fifths>
          </key>
          <time>
              <beats>$beats</beats>
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
''');
        }
        }

        //  next note
        sb.write('''
<note>
    <pitch>
    ${key.getKeyScaleNoteByHalfStep(halfStep++).asMusicXml()}
    <octave>4</octave>
    </pitch>
    <duration>${beatDuration}</duration>
    <voice>1</voice>
    <staff>1</staff>
    </note>
''');
      }

      //  end the last measure
      if (measureNumber > 0) {
        sb.write('''
</measure>
''');
      }

      xmlString +=  sb.toString();
    }

    xmlString += '''
</part>
</score-partwise>
''';

    final filename = '${SysInfo.userDirectory}/junk/genTest.musicxml';
    File(filename).writeAsString(xmlString).then((File file) {
      logger.i('done');
      // Do something with the file.
    });
  });
}
