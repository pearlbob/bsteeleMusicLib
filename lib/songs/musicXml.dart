import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/chord.dart';
import 'package:bsteeleMusicLib/songs/chordDescriptor.dart';
import 'package:bsteeleMusicLib/songs/key.dart' as music_key;
import 'package:bsteeleMusicLib/songs/pitch.dart';
import 'package:bsteeleMusicLib/songs/scaleChord.dart';
import 'package:bsteeleMusicLib/songs/scaleNote.dart';
import 'package:bsteeleMusicLib/songs/song.dart';
import 'package:bsteeleMusicLib/songs/songMoment.dart';
import 'package:xml/xml.dart';

import 'musicConstants.dart';

class MusicXml {
  static XmlDocument parse(String musicXml) {
    return XmlDocument.parse(musicXml);
  }

  String songAsMusicXml(Song song) {
    _song = song;
    music_key.Key key = _song.key;

    StringBuffer sb = StringBuffer();

    sb.write('''
<?xml version="1.0" encoding="UTF-8" standalone="no"?><!DOCTYPE score-partwise PUBLIC
    "-//Recordare//DTD MusicXML 3.1 Partwise//EN"
    "http://www.musicxml.org/dtds/partwise.dtd">
<score-partwise version="3.1">
    <credit page="1">
        <credit-words default-x="500" default-y="150" font-size="24" justify="center" valign="top">
            ${song.title}
        </credit-words>
    </credit>
    <credit page="1">
        <credit-words default-x="400" default-y="50" font-size="12" justify="right" valign="bottom">
            ${song.artist}, Copyright ${song.copyright}
        </credit-words>
    </credit>
<part-list>
        <score-part id="P1">
            <part-name>Piano</part-name>
        </score-part>
    </part-list>
    
<part id="P1">
''');

    {
      int beats = song.beatsPerBar;
      int unitsPerMeasure = song.unitsPerMeasure;
      Pitch lowRoot = Pitch.get(PitchEnum.E2); //  bass staff
      lowRoot = key.mappedPitch(lowRoot); // required once only
      Pitch highRoot = Pitch.get(PitchEnum.C3); //  treble staff
      highRoot = key.mappedPitch(highRoot); // required once only

      for (SongMoment songMoment in song.songMoments) {
        int measureNumber = songMoment.momentNumber;

        //  List<String>  lines =    songMoment.getLyricSection().getLyricsLines();
        String lyric = 'oh baby';

        //  start the measure
        sb.write('''

<!--   $songMoment   -->
<measure number="$measureNumber">
''');

        //  first measure gets the attributes
        if (measureNumber == 0) {
          sb.write('''
    <attributes>
          <!--    allow up to 16th notes  -->
          <divisions>$divisionsPerBeat</divisions>
          <key>
              <fifths>${key.getKeyValue()}</fifths>
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

        {
          for (Chord chord in songMoment.getMeasure().chords) {
            sb.write('''
  <!--   $chord for ${chord.beats} beats  -->
''');
            sb.write('${_chordAsMusicXml(songMoment, chord, lyric)}\n');
            lyric = null;
          }
        }

        //  next note
//         sb.write(
//             '''<backup> <duration>16</duration> </backup>
// <note><!--  bass note: $lowRoot    -->
//     ${MusicXml.pitchAsMusicXml(lowRoot)}
//     <duration>${beatDuration}</duration>
//     <voice>1</voice>
//     <staff>2</staff>
//     </note>
//
// ''');
        //  end the measure
        sb.write('''
</measure>
''');
      }
    }

    sb.write('''
</part>
</score-partwise>
''');

    return sb.toString();
  }

  String _scaleNoteAsMusicXml(ScaleNote scaleNote) {
    String ret = '<step>${scaleNote.scaleString}</step>';
    if (scaleNote.isSharp) {
      return ret + '<alter>1</alter>';
    }
    if (scaleNote.isFlat) {
      return ret + '<alter>-1</alter>';
    }
    return ret;
  }

  String _pitchAsMusicXml(Pitch pitch) {
    String ret = '<pitch>'
        '${_scaleNoteAsMusicXml(pitch.scaleNote)}'
        '<octave>${pitch.octaveNumber}</octave>'
        '</pitch>';
    return ret;
  }

  String _chordAsMusicXml(SongMoment songMoment, Chord chord, String lyrics) {
    ScaleNote scaleNote = chord.scaleChord.scaleNote;

    String ret = '\t<harmony><root>'
        '<root-step>${scaleNote.scaleString}'
        '</root-step>';
    if (scaleNote.isSharp) {
      ret += '<root-alter>1</root-alter>';
    }
    if (scaleNote.isFlat) {
      ret += '<root-alter>-1</root-alter>';
    }
    String name = _getChordDescriptorName(chord.scaleChord);
    ret += '</root><kind>$name</kind></harmony>'
        '\n';

//  draw the chord notes
    bool first = true;
    for (Pitch pitch in chord.getPitches(_chordBase)) {
      pitch = _song.key.mappedPitch(pitch);
      ret += '''
\t<note><!--    ${pitch}   -->
''';
      if (first) {
        first = false;
      } else {
        ret += '\t\t<chord/>\n';
      }

      String type;
      switch (chord.beats) {
        case 1:
          type = 'quarter';
          break;
        case 2:
          type = 'half';
          break;
        case 4:
          type = 'whole';
          break;
        default:
          //  fixme: dotted
          //  fixme: 6/8 time
          break;
      }
      ret += '''\t\t${_pitchAsMusicXml(pitch)}
\t\t<duration>${chord.beats * divisionsPerBeat}</duration>
\t\t<type>$type</type>
\t\t<staff>1</staff>
''';
      if (lyrics != null) {
        ret += '''
\t\t<lyric name="${songMoment.lyricSection.sectionVersion.getFormalName()}" number="1">
\t\t\t<text>$lyrics</text>
\t\t</lyric>
''';
        lyrics = null;  //  use on first chord for the measure
      }

      ret += '''
\t\t</note>
''';
    }

    return ret;
  }

  String _getChordDescriptorName(ScaleChord scaleChord) {
    //  lazy eval, map internal names to musicXml names
    if (chordDescriptorMap.isEmpty) {
      for (ChordDescriptor cd in ChordDescriptor.values) {
        String value = cd.name;
        switch (cd.name) {
          // case 'add9':
          // case 'augmented5':
          // case 'jazz7b9':
          // case 'mmaj7':
          // case 'minor7b5':
          // case 'msus2':
          // case 'msus4':
          // case 'flat5':
          // case 'sevenFlat5':
          // case 'sevenFlat9':
          // case 'sevenSharp5':
          // case 'sevenSharp9':
          //
          // case 'suspended7':
          // case 'sevenSus':
          // case 'sevenSus2':
          // case 'sevenSus4':
          // case 'six9':

          case 'minor':
          case 'major':
          case 'augmented':
          case 'diminished':
            //  identity map
            value = cd.name;
            break;
          case 'dominant7':
            value = 'dominant';
            break;
          case 'dominant11':
            value = 'dominant-11th';
            break;
          case 'dominant13':
            value = 'dominant-13th';
            break;
          case 'major7':
          case 'majorSeven':
            value = 'major-seventh';
            break;
          case 'minor7':
            value = 'minor-seventh';
            break;
          case 'diminished7':
            value = 'diminished-seventh';
            break;
          case 'augmented7':
            value = 'augmented-seventh';
            break;
          case 'major6':
            value = 'major-sixth';
            break;
          case 'minor6':
            value = 'minor-sixth';
            break;
          case 'dominant9':
            value = 'dominant-ninth';
            break;
          case 'major9':
          case 'majorNine':
            value = 'major-ninth';
            break;
          case 'minor9':
            value = 'minor-ninth';
            break;
          case 'minor11':
            value = 'minor-11th';
            break;
          case 'minor13':
            value = 'minor-13th';
            break;
          case 'suspended2':
            value = 'suspended-second';
            break;
          case 'suspended4':
          case 'suspendedFourth':
            value = 'suspended-fourth';
            break;
          case 'power5':
          case 'suspended':
            value = 'power';
            break;
          default:
            logger.w('unknown chord descriptor: case \'${cd.name}\':');
            value = 'other';
            break;
        }
        chordDescriptorMap[cd.name] = value;

        // <xs:enumeration value="half-diminished" />
        //<xs:enumeration value="major-minor" />
        // <xs:enumeration value="major-11th" />
        // <xs:enumeration value="major-13th" />
      }
    }
    return chordDescriptorMap[scaleChord.chordDescriptor.name];
  }

  Song _song;

  static const int divisionsPerBeat = 4; //  16th note resolution only
  static final Pitch _chordBase = Pitch.get(PitchEnum.C4);
  static Map<String, String> chordDescriptorMap = {};
}
