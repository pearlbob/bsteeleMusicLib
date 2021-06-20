import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/chord.dart';
import 'package:bsteeleMusicLib/songs/chordDescriptor.dart';
import 'package:bsteeleMusicLib/songs/key.dart' as music_key;
import 'package:bsteeleMusicLib/songs/pitch.dart';
import 'package:bsteeleMusicLib/songs/scaleChord.dart';
import 'package:bsteeleMusicLib/songs/scaleNote.dart';
import 'package:bsteeleMusicLib/songs/song.dart';
import 'package:bsteeleMusicLib/songs/songMoment.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';

class MusicXml {
  static XmlDocument parse(String musicXml) {
    return XmlDocument.parse(musicXml);
  }

  String songAsMusicXml(Song song) {
    _song = song;
    music_key.Key key = _song.key;

    StringBuffer sb = StringBuffer();

    // <page-layout>
    // <page-height>1955</page-height> <!-- 11" -->
    // <page-width>1511</page-width> <!-- 8.5" -->
    // <page-margins type="even">
    // <left-margin>50</left-margin>
    // <right-margin>5</right-margin>
    // <top-margin>5</top-margin>
    // <bottom-margin>110</bottom-margin>
    // </page-margins>
    // <page-margins type="odd">
    // <left-margin>50</left-margin>
    // <right-margin>5</right-margin>
    // <top-margin>5</top-margin>
    // <bottom-margin>110</bottom-margin>
    // </page-margins>
    // </page-layout>

    sb.write('''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 3.1 Partwise//EN" "http://www.musicxml.org/dtds/partwise.dtd">
<score-partwise version="3.1">
  <work>
    <work-title>${_song.getTitle()}</work-title>
    </work>
<identification>
    <creator type="composer">Composer</creator>
    <encoding>
      <software>bsteeleMusicLib</software>
      <encoding-date>${DateFormat('yyyy-MM-dd').format(DateTime.now())}</encoding-date>
      <supports element="accidental" type="yes"/>
      <supports element="beam" type="yes"/>
      <supports element="print" attribute="new-page" type="yes" value="yes"/>
      <supports element="print" attribute="new-system" type="yes" value="yes"/>
      <supports element="stem" type="yes"/>
      </encoding>
    </identification>
  <defaults>
      <scaling>
      <millimeters>7.05556</millimeters>
        <tenths>40</tenths>
        </scaling>
      <page-layout>
        <page-height>1683.78</page-height>
      <page-width>1190.55</page-width>
        <page-margins type="even">
        <left-margin>56.6929</left-margin>
        <right-margin>56.6929</right-margin>
        <top-margin>56.6929</top-margin>
        <bottom-margin>113.386</bottom-margin>
          </page-margins>
        <page-margins type="odd">
        <left-margin>56.6929</left-margin>
        <right-margin>56.6929</right-margin>
        <top-margin>56.6929</top-margin>
        <bottom-margin>113.386</bottom-margin>
          </page-margins>
        </page-layout>
      <word-font font-family="FreeSerif" font-size="10"/>
      <lyric-font font-family="FreeSerif" font-size="11"/>
      </defaults>
    <credit page="1">
       <credit-words default-x="595.275" default-y="1627.09" justify="center" valign="top" font-size="24">Weight, The</credit-words>
    </credit>
    <credit page="1">
         <credit-words default-x="1133.86" default-y="1527.09" justify="right" valign="bottom" font-size="12">
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
      int beats = song.timeSignature.beatsPerBar;
      Pitch lowRoot = Pitch.get(PitchEnum.E2); //  bass staff
      lowRoot = key.mappedPitch(lowRoot); // required once only
      Pitch highRoot = Pitch.get(PitchEnum.C3); //  treble staff
      highRoot = key.mappedPitch(highRoot); // required once only

      song.songMomentGrid; //  fixme: shouldn't be required!

      for (SongMoment songMoment in song.songMoments) {
        int measureNumber = songMoment.momentNumber;
        _lyricsHaveBeenWritten = false;

        //  start the measure
        sb.write('''

<!--   $songMoment   -->
<measure number="${measureNumber + 1}" width="200">
''');

        //  first measure gets the attributes
        if (measureNumber == 0) {
          sb.write('''
    <print>
        <system-layout>
          <system-margins>
            <left-margin>0.00</left-margin>
            <right-margin>-0.00</right-margin>
            </system-margins>
          <top-system-distance>170.00</top-system-distance>
          </system-layout>
        </print>
    <attributes>
          <!--    allow up to 16th notes  -->
          <divisions>$_divisionsPerBeat</divisions>
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
            sb.write('${_chordAsMusicXml(songMoment, chord)}\n');
          }
        }

        //  bass
        sb.write('\t<backup> <duration>16</duration> </backup>');

        for (Chord chord in songMoment.getMeasure().chords) {
          Pitch? p = Pitch.findPitch(chord.slashScaleNote ?? chord.scaleChord.scaleNote, lowRoot);
          if (p != null) {
            Pitch pitch = key.mappedPitch(p);
            sb.write('''
  <note><!--  bass note: $pitch    -->
    ${_pitchAsMusicXml(pitch)}
    ${_noteDuration(chord.beats)}
    <staff>2</staff>
    </note>
''');
          }
        }

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

  String _rootStep(ScaleNote scaleNote) {
    return _step(scaleNote, basis: 'root');
  }

  String _bassStep(ScaleNote? scaleNote) {
    if (scaleNote == null) {
      return '';
    }
    return _step(scaleNote, basis: 'bass');
  }

  String _step(ScaleNote scaleNote, {String? basis}) {
    String mod = '${basis != null ? basis + '-' : ''}';
    String ret = '<${mod}step>${scaleNote.scaleString}</${mod}step>';
    if (scaleNote.isSharp) {
      ret += '<${mod}alter>1</${mod}alter>';
    }
    if (scaleNote.isFlat) {
      ret += '<${mod}alter>-1</${mod}alter>';
    }
    return ret;
  }

  String _noteDuration(int beats) {
    String type;
    switch (beats) {
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
        type = 'quarter';
        break;
    }
    return '''
\t\t<duration>${beats * _divisionsPerBeat}</duration>
\t\t<type>$type</type>
''';
  }

  String _chordAsMusicXml(SongMoment songMoment, Chord chord) {
    ScaleNote scaleNote = chord.scaleChord.scaleNote;

    String ret = '\t<harmony><root>' + _rootStep(scaleNote);

    String? name = _getChordDescriptorName(chord.scaleChord);
    ret += '</root><kind halign="center" text="7">${name ?? chord.scaleChord}</kind>';
    if (chord.slashScaleNote != null) {
      ret += '\n\t\t<bass>${_bassStep(chord.slashScaleNote)}</bass>';
    }
    ret += '</harmony>\n';

    //  draw the chord notes
    bool first = true;
    for (Pitch pitch in chord.getPitches(_chordBase)) {
      Pitch p = _song.key.mappedPitch(pitch);
      ret += '''
\t<note><!--    ${p}   -->
''';
      if (first) {
        first = false;
      } else {
        ret += '\t\t<chord/>\n';
      }

      ret += '\t\t${_pitchAsMusicXml(p)}';
      ret += _noteDuration(chord.beats);
      ret += '\t\t<staff>1</staff>';

      if (!_lyricsHaveBeenWritten && songMoment.lyrics != null && songMoment.lyrics!.isNotEmpty) {
        ret += '''
\t\t<lyric name="${songMoment.lyricSection.sectionVersion.getFormalName()}" number="1">
\t\t\t<text>${songMoment.lyrics}</text>
\t\t</lyric>
''';
        _lyricsHaveBeenWritten = true;
      }

      ret += '''
\t\t</note>
''';
    }

    return ret;
  }

  String? _getChordDescriptorName(ScaleChord scaleChord) {
    //  lazy eval, map internal names to musicXml names
    if (_chordDescriptorMap.isEmpty) {
      for (ChordDescriptor cd in ChordDescriptor.values) {
        String value = cd.name;
        switch (cd.name) {
          case 'add9':
          case 'augmented5':
          case 'jazz7b9':
          case 'mmaj7':
          case 'minor7b5':
          case 'msus2':
          case 'msus4':
          case 'flat5':
          case 'sevenFlat5':
          case 'sevenFlat9':
          case 'sevenSharp5':
          case 'sevenSharp9':
          case 'suspended7':
          case 'sevenSus':
          case 'sevenSus2':
          case 'sevenSus4':
          case 'six9':
          case 'minor':
          case 'major':
          case 'augmented':
          case 'diminished':
          case 'suspendedSecond':
          case 'maj':
          case 'capMajor':
          case 'capMajor7':
          case 'deltaMajor7':
          case 'dimMasculineOrdinalIndicator':
          case 'dimMasculineOrdinalIndicator7':
          case 'diminishedAsCircle':
          case 'maug':
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
        _chordDescriptorMap[cd.name] = value;

        // <xs:enumeration value="half-diminished" />
        //<xs:enumeration value="major-minor" />
        // <xs:enumeration value="major-11th" />
        // <xs:enumeration value="major-13th" />
      }
    }
    return _chordDescriptorMap[scaleChord.chordDescriptor.name];
  }

  ///  throws an [XmlParserException] if the input is invalid.
  static Song songFromMusicXml(String songAsMusicXml) {
    Song song = Song.createEmptySong();

    XmlDocument doc = XmlDocument.parse(songAsMusicXml);

    XmlElement? scorePartwise = doc.getElement('score-partwise');
    if ( scorePartwise!= null ) {
      XmlElement? work = scorePartwise.getElement('work');
      if (work != null) {
        XmlElement? workTitle = work.getElement('work-title');
        if (workTitle != null) {
          song.title = workTitle.innerText;
        }
      }
    }
    return song;
  }

  late Song _song;

  bool _lyricsHaveBeenWritten = false;

  static const int _divisionsPerBeat = 4; //  16th note resolution only, funny timing concept from MusicXml
  static final Pitch _chordBase = Pitch.get(PitchEnum.C4);
  static final Map<String, String> _chordDescriptorMap = {};
}
