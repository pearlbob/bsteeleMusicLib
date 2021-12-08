import 'dart:collection';

import 'package:bsteeleMusicLib/songs/chordSection.dart';
import 'package:bsteeleMusicLib/songs/key.dart' as music_key;
import 'package:bsteeleMusicLib/songs/measure.dart';
import 'package:bsteeleMusicLib/songs/phrase.dart';
import 'package:bsteeleMusicLib/songs/section.dart';
import 'package:bsteeleMusicLib/songs/sectionVersion.dart';
import 'package:bsteeleMusicLib/songs/song.dart';
import 'package:bsteeleMusicLib/songs/timeSignature.dart';

import '../appLogger.dart';

final RegExp verticalBarRegExp = RegExp(r'\|');
final RegExp allBarsRegExp = RegExp(r'^(\s*\|)*\s*$');
final RegExp verticalBarEndRegExp = RegExp(r'\s*\|\s*$');
final RegExp endOfLyricLineCleanupRegExp = RegExp(r'\s*\|\s*$');
final RegExp slashSlashRegExp = RegExp(r'//');
final RegExp chordRegExp = RegExp(r'\[([^\]]+)\]([^\[]*)');
final RegExp defineDirectiveRegexp = RegExp(r'^\{define:');
final RegExp chordDirectiveRegexp = RegExp(r'^\{chord:');
final RegExp annotationRegexp = RegExp(r'^\[\*(.*)\]');
//textfont, textsize, textcolour
//chordfont, chordsize, chordcolour
//tabfont, tabsize, tabcolour
final RegExp standardMetaDataDirectiveRegexp = RegExp(r'^\{(\w+)+:\s*(.*)\s*}\s*$');
final RegExp metaDataDirectiveRegexp = RegExp(r'^\{meta:\s*(\w+)\s+(.*)\s*}\s*$');
final RegExp experimentalDirectiveRegexp = RegExp(r'^\{x_');
final RegExp environmentDirectiveRegexp = RegExp(r'^\{(\w+)}$');
final RegExp endOfTabRegexp = RegExp(r'^\{\s*(end_of_tab|eot)}');

enum _ChordProState {
  normal,
  start_of_tab,
}

class _ChordSectionAndLyrics {
  _ChordSectionAndLyrics(this._chordSection, this._lyricsLines);

  ChordSection _chordSection;
  final List<String> _lyricsLines;
}

class ChordPro {
  Song parse(String songAsChordPro) {
    _song = Song.createEmptySong();

    //  parse the chordpro lines
    for (var line in songAsChordPro.split('\n')) {
      logger.d('parseLine: <$line>');
      parseLine(line);
    }
    _enterCurrentChordSection(null); //  finish the last chord section

    StringBuffer lyrics = StringBuffer();

    //  map the identical sections together
    //  add a version number when required
    {
      Map<Section, int> sectionCounts = {};
      SplayTreeSet<ChordSection> chordSections = SplayTreeSet();

      for (var csl in _chordSectionAndLyricsList) {
        ChordSection? chordSectionMatch;
        for (var cs in chordSections) {
          if (cs.sectionVersion.section == csl._chordSection.sectionVersion.section &&
              cs.phrases.first == csl._chordSection.phrases.first) {
            chordSectionMatch = csl._chordSection;
            break;
          }
        }

        if (chordSectionMatch != null) {
          csl._chordSection = chordSectionMatch;
        } else {
          //  find a new version number
          int? version = sectionCounts[csl._chordSection.sectionVersion.section];
          if (version == null) {
            sectionCounts[csl._chordSection.sectionVersion.section] = 0;
            version = 0;
          } else {
            version++;
            sectionCounts[csl._chordSection.sectionVersion.section] = version;
          }
          csl._chordSection = ChordSection(
              SectionVersion(csl._chordSection.sectionVersion.section, version), csl._chordSection.phrases);
          chordSections.add(csl._chordSection);
        }
        logger.d('cs: ${csl._chordSection.sectionVersion.toString()}');

        lyrics.write(csl._chordSection.sectionVersion.toString());
        lyrics.write('\n');
        for (var line in csl._lyricsLines) {
          if (allBarsRegExp.hasMatch(line)) {
            lyrics.write('\n');
          } else {
            lyrics.write(line);
            lyrics.write('\n');
          }
        }
      }

      //  give all the chords to the song
      StringBuffer sb = StringBuffer();
      for (var cs in chordSections) {
        //  deal with empty sections
        if (cs.isEmpty) {
          //  put in an blank measure just to get the lyics out
          sb.write('${cs.sectionVersion}\n\tX\n');
        } else {
          sb.write(cs);
        }
        logger.d(cs.toString());
      }
      _song.setChords(sb.toString());
    }
    _song.rawLyrics = lyrics.toString();
    return _song;
  }

  void parseLine(String line) {
    line = line.trim();
    if (line.trim().isNotEmpty) {
      switch (state) {
        case _ChordProState.normal:
          parseNonEmptyLine(line);
          break;
        case _ChordProState.start_of_tab:
          consumeToEndOfTab(line);
          break;
      }
    }
  }

  void parseNonEmptyLine(String line) {
    //  comment
    if (line[0] == '#') {
      logger.d('comment: <$line>');
      return;
    }
    //  extension!  // comment
    if (slashSlashRegExp.hasMatch(line)) {
      logger.d('comment: <$line>');
      return;
    }

    RegExpMatch? m = defineDirectiveRegexp.firstMatch(line);
    if (m != null) {
      logger.d('define: ${m.group(1)}: <$line>');
      return;
    }

    m = chordDirectiveRegexp.firstMatch(line);
    if (m != null) {
      logger.d('chord: ${m.group(1)}: <$line>');
      return;
    }

    m = annotationRegexp.firstMatch(line);
    if (m != null) {
      logger.d('annotation: ${m.group(1)}: <$line>');
      return;
    }

    m = metaDataDirectiveRegexp.firstMatch(line);
    if (m != null) {
      logger.d('meta: ${m.group(1)}: <$line>');
      var name = m.group(1);
      var value = m.group(2);
      switch (name) {
        case 'title':
        case 't':
        case 'sorttitle':
        case 'subtitle':
        case 'st':
        case 'artist':
        case 'composer':
        case 'lyricist':
        case 'copyright':
        case 'album':
        case 'year':
        case 'key':
        case 'time':
        case 'tempo':
        case 'duration':
        case 'capo':
        case 'meta':
          logger.d('meta: ${name}: $value,  <$line>');
          break;
        default:
          logger.d('unknown meta: $value,  <$line>');
          break;
      }
      //  {meta: name value}
      return;
    }

    m = standardMetaDataDirectiveRegexp.firstMatch(line);
    if (m != null) {
      var name = m.group(1);
      var value = m.group(2) ?? '';
      switch (name) {
        case 'title':
        case 't':
          _song.title = value;
          break;
        case 'sorttitle':
          break;
        case 'subtitle':
        case 'st':
          if (_song.artist.isEmpty) {
            _song.artist = value; //  fixme: temp workaround for sloppy chordpro songs
          }
          break;
        case 'artist':
          _song.artist = value;
          break;
        case 'composer':
        case 'lyricist':
          break;
        case 'copyright':
          _song.copyright = value;
          break;
        case 'album':
        case 'year':
          break;
        case 'key':
          _song.key = music_key.Key.parseString(value) ?? music_key.Key.getDefault();
          break;
        case 'time':
          _song.timeSignature = TimeSignature.parse(value);
          break;
        case 'tempo':
        case 'duration':
        case 'capo':
          break;
        case 'meta':
          logger.d('standard meta: ${name}: $value,  <$line>');
          break;
        default:
          logger.d('unknown standard meta: $value,  <$line>');
          break;
      }
      //  {meta: name value}
      return;
    }

    m = experimentalDirectiveRegexp.firstMatch(line);
    if (m != null) {
      logger.d('experimental: <$line>');
      return;
    }

    m = environmentDirectiveRegexp.firstMatch(line);
    if (m != null) {
      var env = m.group(1);
      logger.d('env: ${env}: <$line>');

      switch (m.group(1)) {
        case 'new_song':
        case 'ns':
        // comment (short: c)
        // comment_italic (short: ci)
        // comment_box (short: cb)
        // image

        case 'start_of_chorus':
        case 'soc':
        case 'end_of_chorus':
        case 'eoc':
        case 'chorus':
        case 'start_of_verse':
        case 'sov':
        case 'end_of_verse':
        case 'eov':
        case 'start_of_bridge':
        case 'sob':
        case 'end_of_bridge':
        case 'eob':
          break;
        case 'start_of_tab':
        case 'sot':
          state = _ChordProState.start_of_tab;
          break;
        case 'end_of_tab':
        case 'eot':
        case 'start_of_grid':
        case 'sog':
        case 'end_of_grid':
        case 'eog':
        case 'new_page':
        case 'np':
        case 'new_physical_page':
        case 'npp':
        case 'column_break':
        case 'cb':
        //  legacy:
        case 'grid':
        case 'g':
        case 'no_grid':
        case 'ng':
        case 'titles':
        case 'columns':
        case 'col':
          break;
        default:
          logger.d('unknown env: ${env}: <$line>');
          break;
      }
      return;
    }

    //  strip all vertical bars from the input
    line = line.replaceAll(verticalBarRegExp, '');

    Iterable<RegExpMatch> allMatches = chordRegExp.allMatches(line);
    if (allMatches.isNotEmpty) {
      logger.d('chord line: <$line>');
      List<Measure> lineMeasures = [];
      StringBuffer lineLyrics = StringBuffer();

      //  test for a section
      if (allMatches.length == 1) {
        Section? section = Section.parseString(allMatches.first.group(1) ?? '');
        if (section != null) {
          logger.d('   section: ${section.toString()} <${allMatches.first.group(1)}>');
          _enterCurrentChordSection(section);
          return;
        }
      }

      {
        for (var match in allMatches) {
          try {
            Measure measure =
                Measure.parseString(match.group(1) ?? '', _song.timeSignature.beatsPerBar, endOfRow: false);
            lineMeasures.add(measure);
            logger.d('   measure: ${measure.toMarkup()} <${match.group(1)}>,<${match.group(2)}>');
            lineLyrics.write('${match.group(2).toString().trim()} | ');
          } catch (e) {
            //  not looking like a section or measures, punt it to the user as lyrics
            logger.i('   NOT measure: <${match.group(1)}>, <${match.group(2)}>');
            lineLyrics.write(line);
            break;
          }
        }
      }

      lyricsLines.add(lineLyrics.toString().replaceAll(verticalBarEndRegExp, ''));
      if (lineMeasures.isNotEmpty) {
        lineMeasures.last.endOfRow = true;
        measures.addAll(lineMeasures);
      }
      return;
    } else {
      line = line.trim().replaceAll(verticalBarEndRegExp, '');
      if (line.isNotEmpty) {
        lyricsLines.add(line);
        logger.d('unknown: <$line>');
      }
    }
  }

  void _enterCurrentChordSection(Section? section) {
    if (currentChordSection != null) {
      currentChordSection!.add(0, Phrase(measures, 0));

      _chordSectionAndLyricsList.add(_ChordSectionAndLyrics(currentChordSection!, lyricsLines));

      currentChordSection = null;
    }

    measures = [];
    lyricsLines = [];

    if (section != null) {
      currentChordSection = ChordSection(SectionVersion(section, 0), []);
    }
  }

  void consumeToEndOfTab(String line) {
    RegExpMatch? m = endOfTabRegexp.firstMatch(line);
    if (m != null) {
      state = _ChordProState.normal;
    }

    logger.d('tabbing: <$line>');
  }

  final List<_ChordSectionAndLyrics> _chordSectionAndLyricsList = [];
  List<String> lyricsLines = [];
  List<Measure> measures = [];
  ChordSection? currentChordSection;
  _ChordProState state = _ChordProState.normal;
  Song _song = Song.createEmptySong();
}
