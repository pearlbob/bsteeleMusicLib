import 'dart:collection';
import 'dart:core';
import 'dart:math';

import 'package:bsteeleMusicLib/songs/timeSignature.dart';
import 'package:logger/logger.dart';
import 'package:meta/meta.dart';
import 'package:quiver/collection.dart';
import 'package:quiver/core.dart';

import '../appLogger.dart';
import '../grid.dart';
import '../gridCoordinate.dart';
import '../util/util.dart';
import 'chord.dart';
import 'chordDescriptor.dart';
import 'chordSection.dart';
import 'chordSectionGridData.dart';
import 'chordSectionLocation.dart';
import 'key.dart';
import 'lyricSection.dart';
import 'measure.dart';
import 'measureComment.dart';
import 'measureNode.dart';
import 'measureRepeat.dart';
import 'measureRepeatExtension.dart';
import 'measureRepeatMarker.dart';
import 'musicConstants.dart';
import 'phrase.dart';
import 'scaleChord.dart';
import 'section.dart';
import 'sectionVersion.dart';
import 'song.dart';
import 'songId.dart';
import 'songMoment.dart';

enum UpperCaseState {
  initial,
  flatIsPossible,
  comment,
  normal,
}

/// A piece of music to be played according to the structure it contains.
///  The song base class has been separated from the song class to allow most of the song
///  mechanics to be tested in the a code environment where debugging is easier.

class SongBase {
  ///  Not to be used externally
  SongBase() {
    title = '';
    artist = '';
    coverArtist = '';
    copyright = '';
    key = Key.C;
    timeSignature = TimeSignature.defaultTimeSignature;
    rawLyrics = '';
    setChords('');
    setBeatsPerMinute(100);
  }

  /// Constructor from a set of named arguments.
  SongBase.from(
      {String title = 'unknown',
      String artist = 'unknown',
      String coverArtist = '',
      String copyright = 'unknown',
      Key? key,
      int beatsPerMinute = MusicConstants.defaultBpm,
      int beatsPerBar = 4,
      int unitsPerMeasure = 4,
      String chords = '',
      String rawLyrics = ''}) {
    this.title = title;
    this.artist = artist;
    this.coverArtist = coverArtist;
    this.copyright = copyright;
    this.key = key ?? Key.getDefault();
    this.beatsPerMinute = beatsPerMinute;
    timeSignature = TimeSignature(beatsPerBar, unitsPerMeasure);
    setChords(chords);
    this.rawLyrics = rawLyrics;
  }

  /// A convenience constructor used to enforce the minimum requirements for a song.
  ///
  /// Note that this is the base class for a song object.
  /// The split from Song was done for testability reasons.
  static SongBase createSongBase(String title, String artist, String copyright, Key key, int bpm, int beatsPerBar,
      int unitsPerMeasure, String chords, String rawLyrics) {
    SongBase song = SongBase();
    song.title = title;
    song.artist = artist;
    song.copyright = copyright;
    song.key = key;
    song.timeSignature = TimeSignature(beatsPerBar, unitsPerMeasure);
    song.setChords(chords);
    song.rawLyrics = rawLyrics;
    song.setBeatsPerMinute(bpm);
    song.resetLastModifiedDateToNow();

    return song;
  }

  /// Compute the song moments list given the song's current state.
  /// Moments are the temporal sequence of measures as the song is to be played.
  /// All repeats are expanded.  Measure node such as comments,
  /// repeat ends, repeat counts, section headers, etc. are ignored.
  void _computeSongMoments() {
    if (_songMoments.isNotEmpty) {
      return;
    }

    //  force the chord parse
    _getChordSectionMap();

    _songMoments = [];
    _beatsToMoment = HashMap();

    _parseLyrics();
    if (lyricSections.isEmpty) {
      return;
    }

    logger.d('lyricSections size: ' + lyricSections.length.toString());
    int sectionCount;
    HashMap<SectionVersion, int> sectionVersionCountMap = HashMap<SectionVersion, int>();
    _chordSectionBeats = HashMap<SectionVersion, int>();
    int beatNumber = 0;
    for (LyricSection lyricSection in lyricSections) {
      ChordSection? chordSection = findChordSectionByLyricSection(lyricSection);
      if (chordSection == null) {
        continue;
      }

      //  compute section count
      SectionVersion? sectionVersion = chordSection.sectionVersion;
      sectionCount = sectionVersionCountMap[sectionVersion] ?? 0;
      sectionCount++;
      sectionVersionCountMap[sectionVersion] = sectionCount;

      List<Phrase> phrases = chordSection.phrases;
      //  song moment number for the start of this section
      int chordSectionSongMomentNumber = _songMoments.length;
      {
        int phraseIndex = 0;
        int sectionVersionBeats = 0;
        for (Phrase phrase in phrases) {
          if (phrase.isRepeat()) {
            MeasureRepeat measureRepeat = phrase as MeasureRepeat;
            int limit = measureRepeat.repeats;
            for (int repeat = 0; repeat < limit; repeat++) {
              List<Measure> measures = measureRepeat.measures;
              if (measures.isNotEmpty) {
                int repeatCycleBeats = 0;
                for (Measure measure in measures) {
                  repeatCycleBeats += measure.beatCount;
                }
                int measureIndex = 0;
                for (Measure measure in measures) {
                  _songMoments.add(SongMoment(
                      _songMoments.length,
                      //  size prior to add
                      beatNumber,
                      sectionVersionBeats,
                      lyricSection,
                      chordSection,
                      phraseIndex,
                      phrase,
                      measureIndex,
                      measure,
                      repeat,
                      repeatCycleBeats,
                      limit,
                      sectionCount,
                      chordSectionSongMomentNumber));
                  measureIndex++;
                  beatNumber += measure.beatCount;
                  sectionVersionBeats += measure.beatCount;
                }
              }
            }
          } else {
            //  phrase is not a repeat
            List<Measure> measures = phrase.measures;
            if (measures.isNotEmpty) {
              int measureIndex = 0;
              for (Measure measure in measures) {
                _songMoments.add(SongMoment(
                    _songMoments.length,
                    //  size prior to add
                    beatNumber,
                    sectionVersionBeats,
                    lyricSection,
                    chordSection,
                    phraseIndex,
                    phrase,
                    measureIndex,
                    measure,
                    0,
                    0,
                    0,
                    sectionCount,
                    chordSectionSongMomentNumber));
                measureIndex++;
                beatNumber += measure.beatCount;
                sectionVersionBeats += measure.beatCount;
              }
            }
          }
          phraseIndex++;
        }

        //  remember chord beats
        for (SectionVersion sv in matchingSectionVersions(sectionVersion)) {
          _chordSectionBeats[sv] = sectionVersionBeats;
        }
      }
    }

    {
      //  Generate song moment grid coordinate map for play to display purposes.
      _songMomentGridCoordinateHashMap = HashMap();

      int row = 0;
      GridCoordinate? lastGridCoordinate;
      for (SongMoment songMoment in _songMoments) {
        //  increment the row based on the chord section change
        GridCoordinate? gridCoordinate = getGridCoordinate(songMoment.getChordSectionLocation());
        if (gridCoordinate == null) {
          continue; //  fixme: declare error here?
        }
        if (lastGridCoordinate != null &&
            (gridCoordinate.row != lastGridCoordinate.row || gridCoordinate.col != lastGridCoordinate.col + 1)) {
          row++;
        }
        lastGridCoordinate = gridCoordinate;

        GridCoordinate momentGridCoordinate = GridCoordinate(row, gridCoordinate.col);
        logger.d(songMoment.toString() + ': ' + momentGridCoordinate.toString());
        songMoment.row = momentGridCoordinate.row; //  convenience for later
        songMoment.col = momentGridCoordinate.col; //  convenience for later
        _songMomentGridCoordinateHashMap[songMoment] = momentGridCoordinate;

//        logger.d("moment: " +
//            songMoment.getMomentNumber().toString() +
//            ": " +
//            songMoment.getChordSectionLocation().toString() +
//            "#" +
//            songMoment.getSectionCount().toString() +
//            " m:" +
//            momentGridCoordinate.toString() +
//            " " +
//            songMoment.getMeasure().toMarkup() +
//            (songMoment.getRepeatMax() > 1
//                ? " " +
//                    (songMoment.getRepeat() + 1).toString() +
//                    "/" +
//                    songMoment.getRepeatMax().toString()
//                : ""));
      }
    }

    {
      //  install the beats to moment lookup entries
      int beat = 0;
      for (SongMoment songMoment in _songMoments) {
        int limit = songMoment.getMeasure().beatCount;
        for (int b = 0; b < limit; b++) {
          _beatsToMoment[beat++] = songMoment;
        }
      }
    }
  }

  ///   Return a grid for the song moments in play order.
  ///   Note that the grid will only be filled with song moments.
  ///   Nulls will fill other grid positions intended for section versions
  ///   and filler to an even, minimum right grid boundary.
  Grid<SongMoment> get songMomentGrid {
    //  lazy eval
    if (_songMomentGrid != null) {
      return _songMomentGrid!;
    }

    _computeSongMoments();

    _songMomentGrid = Grid();

    //  find the maximum number of cols in the rows
    int maxCol = 0;
    for (SongMoment songMoment in songMoments) {
      GridCoordinate? momentGridCoordinate = getMomentGridCoordinate(songMoment);
      if (momentGridCoordinate == null) {
        continue;
      }
      logger.v('add ${songMoment.toString()}  at (${momentGridCoordinate.row},${momentGridCoordinate.col})');
      _songMomentGrid!.set(momentGridCoordinate.row, momentGridCoordinate.col, songMoment);
      maxCol = max(maxCol, momentGridCoordinate.col);
    }

    //  Pre-fill the rows to a common maximum length,
    //  even if you have to fill with null.
    //  This is done in preparation for the flutter table.
    for (int row = 0; row < _songMomentGrid!.getRowCount(); row++) {
      if ((_songMomentGrid!.getRow(row)?.length ?? 0) <= maxCol) {
        _songMomentGrid!.set(row, maxCol, null);
      }
    }

    if (lyricSections.isNotEmpty) {
      {
        if (_debugging) {
          int i = 0;
          for (LyricSection ls in lyricSections) {
            logger.d('lyricSection $i: ${ls.toString()}');
            for (String lyricsLine in ls.lyricsLines) {
              logger.d('     $i: ${lyricsLine.toString()}');
              i++;
            }
          }
        }

        {
          int? lastRow;
          String? rowLyrics;
          for (SongMoment songMoment in songMoments) {
            //  compute lyrics for this row, when required
            if (songMoment.row != lastRow) {
              lastRow = songMoment.row;
              rowLyrics = shareLinesToRow(
                  songMoment.chordSection.chordRowCount,
                  (songMoment.row ?? 0) - (getSongMoment(songMoment.chordSectionSongMomentNumber)?.row ?? 0),
                  songMoment.lyricSection.lyricsLines);
            }

            int measureCountInRow = 0;
            {
              for (SongMoment? sm in songMomentGrid.getRow(songMoment.row ?? -1) ?? []) {
                if (sm != null && (sm.col ?? 0) > 0) {
                  measureCountInRow++;
                }
              }
            }

            String lyrics = _splitWordsToMeasure(measureCountInRow, (songMoment.col ?? 1) - 1, rowLyrics);
            songMoment.lyrics = lyrics; //  fixme: should not be changing a value of an object already in a hashmap!
          }
        }
      }
    }

    return _songMomentGrid!;
  }

  /// share the given lines to the given row.
  /// extra lines go to the early measures until depleted.
  static String shareLinesToRow(
      int rowCount,
      int sectionRowNumber, //  measure number - section start measure number
      List<String> lines) {
    StringBuffer ret = StringBuffer();
    int lineCount = lines.length;

    int linesPerMeasure = lineCount ~/ rowCount;
    int extraLines = lineCount.remainder(rowCount);
    int line = sectionRowNumber *
            (linesPerMeasure +
                //  all early lines have an extra one
                (sectionRowNumber < extraLines ? 1 : 0) //
            ) +
        //  all later lines have to skip over the early lines
        (sectionRowNumber >= extraLines ? extraLines : 0);

    for (int i = 0; i < linesPerMeasure; i++) {
      if (line + i >= lines.length) {
        break;
      }
      ret.write(lines[line + i] + '\n');
    }
    if (sectionRowNumber < extraLines && line + linesPerMeasure < lines.length) {
      ret.write(lines[line + linesPerMeasure] + '\n');
    }

    return ret.toString();
  }

  /// split the given line to the given measure.
  /// extra lines go to the early measures until depleted.
  String _splitWordsToMeasure(
      int measureCountInRow,
      int rowMeasureNumber, //  measure number - row start measure number
      String? line) {
    if (line == null || line.isEmpty) {
      return '';
    }

    //  there are more measures than rows!
    List<String> words = line.split(_spaceRegexp);
    if (words.isEmpty) {
      return rowMeasureNumber == 0 ? line : '';
    }
    int wordCount = words.length;
    StringBuffer ret = StringBuffer();
    int wordsPerMeasure = wordCount ~/ measureCountInRow;
    int extraWords = wordCount.remainder(measureCountInRow);
    int wordIndex = rowMeasureNumber *
            (wordsPerMeasure +
                //  all early lines have an extra one
                (rowMeasureNumber < extraWords ? 1 : 0) //
            ) +
        //  all later lines have to skip over the early lines
        (rowMeasureNumber >= extraWords ? extraWords : 0);
    for (int i = 0; i < wordsPerMeasure; i++) {
      ret.write(words[wordIndex + i] + ' ');
    }
    if (rowMeasureNumber < extraWords) {
      ret.write(words[wordIndex + wordsPerMeasure] + ' ');
    }

    return ret.toString().trimRight();
  }

  GridCoordinate? getMomentGridCoordinate(SongMoment songMoment) {
    _computeSongMoments();
    return _songMomentGridCoordinateHashMap[songMoment];
  }

  GridCoordinate? getMomentGridCoordinateFromMomentNumber(int momentNumber) {
    SongMoment? songMoment = getSongMoment(momentNumber);
    if (songMoment == null) {
      return null;
    }
    return _songMomentGridCoordinateHashMap[songMoment];
  }

  void debugSongMoments() {
    _computeSongMoments();

    for (SongMoment songMoment in _songMoments) {
      GridCoordinate? momentGridCoordinate = getMomentGridCoordinateFromMomentNumber(songMoment.getMomentNumber());
      logger.d(songMoment.getMomentNumber().toString() +
          ': ' +
          songMoment.getChordSectionLocation().toString() +
          '#' +
          songMoment.getSectionCount().toString() +
          ' m:' +
          (momentGridCoordinate?.toString() ?? '') +
          ' ' +
          songMoment.getMeasure().toMarkup() +
          (songMoment.getRepeatMax() > 1
              ? ' ' + (songMoment.getRepeat() + 1).toString() + '/' + songMoment.repeatMax.toString()
              : ''));
    }
  }

  String songMomentMeasure(int momentNumber, Key key, int halfStepOffset) {
    _computeSongMoments();
    if (momentNumber < 0 || _songMoments.isEmpty || momentNumber >= _songMoments.length) {
      return '';
    }
    return _songMoments[momentNumber].getMeasure().transpose(key, halfStepOffset);
  }

  String songNextMomentMeasure(int momentNumber, Key key, int halfStepOffset) {
    _computeSongMoments();
    //  assure there is a next moment
    if (momentNumber < -1 || _songMoments.isEmpty || momentNumber >= _songMoments.length - 1 // room for one more index
        ) {
      return '';
    }
    return _songMoments[momentNumber + 1].getMeasure().transpose(key, halfStepOffset);
  }

  String songMomentStatus(int beatNumber, int momentNumber) {
    _computeSongMoments();
    if (_songMoments.isEmpty) {
      return 'unknown';
    }

    if (momentNumber < 0) {
//            beatNumber %= getBeatsPerBar();
//            if (beatNumber < 0)  {beatNumber += getBeatsPerBar();}
//            beatNumber++;
      return 'count in ' + (-momentNumber).toString();
    }

    SongMoment? songMoment = getSongMoment(momentNumber);
    if (songMoment == null) {
      return '';
    }

    Measure measure = songMoment.getMeasure();

    beatNumber %= measure.beatCount;
    if (beatNumber < 0) {
      beatNumber += measure.beatCount;
    }
    beatNumber++;

    String ret = songMoment.getChordSection().sectionVersion.toString() +
        (songMoment.getRepeatMax() > 1
            ? ' ' + (songMoment.getRepeat() + 1).toString() + '/' + songMoment.getRepeatMax().toString()
            : '');

//      ret = songMoment.getMomentNumber().toString() +
//          ": " +
//          songMoment.getChordSectionLocation().toString() +
//          "#" +
//          songMoment.getSectionCount().toString() +
//          " " +
//          ret.toString() +
//          " b: " +
//          (beatNumber + songMoment.getBeatNumber()).toString() +
//          " = " +
//          (beatNumber + songMoment.getSectionBeatNumber()).toString() +
//          "/" +
//          getChordSectionBeats(
//                  songMoment.getChordSectionLocation().sectionVersion)
//              .toString() +
//          " " +
//          _songMomentGridCoordinateHashMap[songMoment].toString();
    return ret;
  }

  /// Find the corresponding chord section for the given lyrics section
  ChordSection? findChordSectionByLyricSection(LyricSection? lyricSection) {
    if (lyricSection == null) {
      return null;
    }
    logger.d('chordSectionMap size: ' + _getChordSectionMap().keys.length.toString());
    return _getChordSectionMap()[lyricSection.sectionVersion];
  }

  /// Compute the duration and total beat count for the song.
  void computeDuration() {
    //  be lazy
    if (_duration != null && _duration! > 0) {
      return;
    }

    _duration = 0;
    totalBeats = 0;

    List<SongMoment>? moments = getSongMoments();
    if (timeSignature.beatsPerBar == 0 || beatsPerMinute == 0 || moments.isEmpty) {
      return;
    }

    for (SongMoment moment in moments) {
      totalBeats += moment.getMeasure().beatCount;
    }
    _duration = totalBeats * 60.0 / beatsPerMinute;
  }

  /// Find the chord section for the given section version.
  ChordSection? getChordSection(SectionVersion? sectionVersion) {
    if (sectionVersion == null) {
      return null;
    }
    return _getChordSectionMap()[sectionVersion];
  }

  ChordSection? getChordSectionByLocation(ChordSectionLocation? chordSectionLocation) {
    if (chordSectionLocation == null) {
      return null;
    }
    ChordSection? ret = _getChordSectionMap()[chordSectionLocation.sectionVersion];
    return ret;
  }

  String getUser() {
    return user;
  }

  void setUser(String user) {
    this.user = user.isEmpty ? defaultUser : user;
  }

  HashMap<SectionVersion, ChordSection> _getChordSectionMap() {
    //  lazy eval
    if (_chordSectionMap.isEmpty && _chords.isNotEmpty) {
      try {
        _parseChords(_chords);
        _invalidateChords();
      } catch (e) {
        logger.d('unexpected: ' + e.toString());
        return (_chordSectionMap = HashMap());
      }
    }
    return _chordSectionMap;
  }

  String _getChords() {
    if (_chords.isEmpty) {
      _chords = chordsToJsonTransportString();
    }
    return _chords;
  }

  /// Try to promote lower case characters to uppercase when they appear to be musical chords
  static String entryToUppercase(String entry) {
    StringBuffer sb = StringBuffer();

    UpperCaseState state = UpperCaseState.initial;
    for (int i = 0; i < entry.length; i++) {
      String c = entry[i];

      switch (state) {
        case UpperCaseState.flatIsPossible:
          if (c == 'b') {
            state = UpperCaseState.initial;
            sb.write(c);
            break;
          }
          continue toInitial; //  fall through
        toInitial:
        case UpperCaseState.initial:
          if ((c.codeUnitAt(0) >= 'A'.codeUnitAt(0) && c.codeUnitAt(0) <= 'G'.codeUnitAt(0)) ||
              (c.codeUnitAt(0) >= 'a'.codeUnitAt(0) && c.codeUnitAt(0) <= 'g'.codeUnitAt(0))) {
            if (i < entry.length - 1) {
              String? sf = entry[i + 1];
              switch (sf) {
                case 'b':
                case '#':
                case MusicConstants.flatChar:
                case MusicConstants.sharpChar:
                  i++;
                  break;
                default:
                  sf = null;
                  break;
              }
              if (i < entry.length - 1) {
                String test = entry.substring(i + 1);
                bool isChordDescriptor = false;
                String cdString = '';
                for (ChordDescriptor chordDescriptor in ChordDescriptor.parseOrderedValues) {
                  cdString = chordDescriptor.toString();
                  if (cdString.isNotEmpty && test.startsWith(cdString)) {
                    isChordDescriptor = true;
                    break;
                  }
                }
                //  a chord descriptor makes a good partition to restart capitalization
                if (isChordDescriptor) {
                  sb.write(c.toUpperCase());
                  if (sf != null) {
                    sb.write(sf);
                  }
                  sb.write(cdString);
                  i += cdString.length;
                  break;
                } else {
                  sb.write(c.toUpperCase());
                  if (sf != null) {
                    sb.write(sf);
                  }
                  break;
                }
              } else {
                sb.write(c.toUpperCase());
                if (sf != null) {
                  sb.write(sf);
                }
                break;
              }
            }
            //  map the chord to upper case
            c = c.toUpperCase();
          } else if (c == 'x') {
            if (i < entry.length - 1) {
              String d = entry[i + 1];
              if (d.codeUnitAt(0) >= '1'.codeUnitAt(0) && d.codeUnitAt(0) <= '9'.codeUnitAt(0)) {
                sb.write(c);
                break; //  don't cap a repeat repetition declaration
              }
            }
            sb.write(c.toUpperCase()); //  x to X
            break;
          } else if (c == '(') {
            sb.write(c);

            //  don't cap a comment
            state = UpperCaseState.comment;
            break;
          }
          state = (c.codeUnitAt(0) >= 'A'.codeUnitAt(0) && c.codeUnitAt(0) <= 'G'.codeUnitAt(0))
              ? UpperCaseState.flatIsPossible
              : UpperCaseState.normal;
          continue toNormal; //  fall through
        toNormal:
        case UpperCaseState.normal:
          //  reset on sequential reset characters
          if (c == ' ' ||
              c == '\n' ||
              c == '\r' ||
              c == '\t' ||
              c == '/' ||
              c == '/' ||
              c == '.' ||
              c == ',' ||
              c == ':' ||
              c == '#' ||
              c == MusicConstants.flatChar ||
              c == MusicConstants.sharpChar ||
              c == '[' ||
              c == ']') state = UpperCaseState.initial;

          sb.write(c);
          break;
        case UpperCaseState.comment:
          sb.write(c);
          if (c == ')') {
            state = UpperCaseState.initial;
          }
          break;
      }
    }
    return sb.toString();
  }

  /// Validate the string representation of a chord entry
  /// Return null if valid.  Return a marked string of the offending portion if not valid.
  static MarkedString? validateChords(final String chords, int beatsPerBar) {
    if (chords.isEmpty) {
      return null; //  valid
    }

    SplayTreeSet<ChordSection> emptyChordSections = SplayTreeSet<ChordSection>();
    MarkedString markedString = MarkedString(chords);
    ChordSection chordSection;
    while (markedString.isNotEmpty) {
      markedString.stripLeadingWhitespace();
      if (markedString.isEmpty) {
        break;
      }

      try {
        markedString.mark();
        chordSection = ChordSection.parse(markedString, beatsPerBar, true);
        if (chordSection.isEmpty) {
          emptyChordSections.add(chordSection);
        } else {
          if (emptyChordSections.isNotEmpty) {
            //  share the common measure sequence items
            for (ChordSection wasEmptyChordSection in emptyChordSections) {
              wasEmptyChordSection.setPhrases(chordSection.phrases);
            }
            emptyChordSections.clear();
          }
        }
      } catch (e) {
        markedString.resetToMark();
        return markedString; //  invalid entry
      }
    }
    if (emptyChordSections.isNotEmpty) {
      return MarkedString(emptyChordSections.first.toMarkup());
    }
    return null; //  valid
  }

  /// Validate the string representation of a potential lyrics entry for the current song.
  /// Return null if valid.  Return a marked string of the offending portion if not valid.
  LyricParseException? validateLyrics(final String lyrics) {
    if (lyrics.isEmpty) {
      return null;
    }
    List<LyricSection> lyricSections;
    try {
      lyricSections = _parseLyricSections(lyrics, strict: true);
      if (lyricSections.isEmpty) {
        throw LyricParseException('No lyric section given', MarkedString(lyrics.substring(0, min(lyrics.length, 20))));
      }
      logger.v('lyricSections: $lyricSections');
    } on LyricParseException catch (e) {
      return e;
    }

    //  look for unused sections
    {
      var sectionVersions = SplayTreeSet<SectionVersion>();
      sectionVersions.addAll(_getChordSectionMap().keys);
      for (var lyricSection in lyricSections) {
        sectionVersions.remove(lyricSection.sectionVersion);
      }
      if (sectionVersions.isNotEmpty) {
        return LyricParseException('Chord section unused:', MarkedString(sectionVersions.first.toString()));
      }
    }

    return null;
  }

  /// Parse the current string representation of the song's chords into the song internal structures.
  void _parseChords(final String? chords) {
    _chords = chords ?? ''; //  safety only
    _clearCachedValues(); //  force lazy eval

    if (_chords.isNotEmpty) {
      logger.d('parseChords for: ' + getTitle());
      SplayTreeSet<ChordSection> emptyChordSections = SplayTreeSet<ChordSection>();
      MarkedString markedString = MarkedString(_chords);
      ChordSection chordSection;
      while (markedString.isNotEmpty) {
        markedString.stripLeadingWhitespace();
        if (markedString.isEmpty) {
          break;
        }
        logger.d(markedString.toString());

        try {
          chordSection = ChordSection.parse(markedString, timeSignature.beatsPerBar, false);
          if (chordSection.phrases.isEmpty) {
            //  allow the parsing of sections with no measures
            //  otherwise it will be considered identical to the following section
            emptyChordSections.add(chordSection);
          } else if (emptyChordSections.isNotEmpty) {
            //  share the common measure sequence items
            for (ChordSection wasEmptyChordSection in emptyChordSections) {
              wasEmptyChordSection.setPhrases(chordSection.phrases);
              _chordSectionMap[wasEmptyChordSection.sectionVersion] = wasEmptyChordSection;
            }
            emptyChordSections.clear();
          }
          _chordSectionMap[chordSection.sectionVersion] = chordSection;
          _clearCachedValues();
        } catch (e) {
          //  try some repair
          _clearCachedValues();

          // logger.d(logGrid());
          rethrow;
        }
      }
      _chords = chordsToJsonTransportString();
    }

    setDefaultCurrentChordLocation();

    // logger.d(logGrid());
  }

  /// Will always return something, even if errors have to be commented out
  List<MeasureNode> parseChordEntry(final String? entry) {
    List<MeasureNode> ret = [];

    if (entry != null) {
      logger.d('parseChordEntry: ' + entry);
      SplayTreeSet<ChordSection> emptyChordSections = SplayTreeSet();
      MarkedString markedString = MarkedString(entry);
      ChordSection chordSection;
      int phaseIndex = 0;
      while (markedString.isNotEmpty) {
        markedString.stripLeadingWhitespace();
        if (markedString.isEmpty) {
          break;
        }
        logger.d('parseChordEntry: ' + markedString.toString());

        int mark = markedString.mark();

        try {
          //  if it's a full section (or multiple sections) it will all be handled here
          chordSection = ChordSection.parse(markedString, timeSignature.beatsPerBar, true);

          //  look for multiple sections defined at once
          if (chordSection.isEmpty) {
            emptyChordSections.add(chordSection);
            continue;
          } else if (emptyChordSections.isNotEmpty) {
            //  share the common measure sequence items
            for (ChordSection wasEmptyChordSection in emptyChordSections) {
              wasEmptyChordSection.setPhrases(chordSection.phrases);
              ret.add(wasEmptyChordSection);
            }
            emptyChordSections.clear();
          }
          ret.add(chordSection);
          continue;
        } catch (e) {
          markedString.resetTo(mark);
        }

        //  see if it's a complete repeat
        try {
          ret.add(MeasureRepeat.parse(markedString, phaseIndex, timeSignature.beatsPerBar, null));
          phaseIndex++;
          continue;
        } catch (e) {
          markedString.resetTo(mark);
        }
        //  see if it's a phrase
        try {
          ret.add(Phrase.parse(
              markedString, phaseIndex, timeSignature.beatsPerBar, getCurrentChordSectionLocationMeasure(),
              allowEndOfRow: true));
          phaseIndex++;
          continue;
        } catch (e) {
          markedString.resetTo(mark);
        }
        //  see if it's a single measure
        try {
          var m = Measure.parse(markedString, timeSignature.beatsPerBar, getCurrentChordSectionLocationMeasure());
          ret.add(m);
          continue;
        } catch (e) {
          markedString.resetTo(mark);
        }
        //  see if it's a comment
        try {
          ret.add(MeasureComment.parse(markedString));
          phaseIndex++;
          continue;
        } catch (e) {
          markedString.resetTo(mark);
        }
        //  the entry was not understood, force it to be a comment
        {
          int commentIndex = markedString.indexOf(' ');
          if (commentIndex < 0) {
            ret.add(MeasureComment(markedString.toString()));
            break;
          } else {
            ret.add(MeasureComment(markedString.remainingStringLimited(commentIndex)));
            markedString.consume(commentIndex);
          }
        }
      }

      //  add trailing empty sections... without a following non-empty section
      for (ChordSection wasEmptyChordSection in emptyChordSections) {
        ret.add(wasEmptyChordSection);
      }
    }

    //  try to help add row separations
    //  default to rows of 4 if there are 8 or more measures
    if (ret.isNotEmpty && ret[0] is ChordSection) {
      ChordSection chordSection = ret[0] as ChordSection;
      for (Phrase phrase in chordSection.phrases) {
        bool hasEndOfRow = false;
        for (Measure measure in phrase.measures) {
          if (measure.isComment()) {
            continue;
          }
          if (measure.endOfRow) {
            hasEndOfRow = true;
            break;
          }
        }
        if (!hasEndOfRow && phrase.length >= 8) {
          int i = 0;
          for (Measure measure in phrase.measures) {
            if (measure.isComment()) {
              continue;
            }
            i++;
            if (i % 4 == 0) {
              measure.endOfRow = true;
            }
          }
        }
      }
    }

    //  deal with sharps and flats misapplied.
    List<MeasureNode> transposed = [];
    for (MeasureNode measureNode in ret) {
      transposed.add(measureNode.transposeToKey(key));
    }
    return transposed;
  }

  void setDefaultCurrentChordLocation() {
    currentChordSectionLocation = null;

    SplayTreeSet<ChordSection> sortedChordSections = SplayTreeSet();
    var values = _getChordSectionMap().values;
    sortedChordSections.addAll(values);
    if (sortedChordSections.isEmpty) {
      return;
    }

    try {
      ChordSection chordSection = sortedChordSections.last;
      List<Phrase> measureSequenceItems = chordSection.phrases;
      if (measureSequenceItems.isNotEmpty) {
        Phrase lastPhrase = measureSequenceItems.last;
        currentChordSectionLocation = ChordSectionLocation(chordSection.sectionVersion,
            phraseIndex: measureSequenceItems.length - 1, measureIndex: lastPhrase.length - 1);
      }
    } catch (e) {
      return;
    }
  }

  HashMap<GridCoordinate, ChordSectionLocation> _getGridCoordinateChordSectionLocationMap() {
    getChordSectionGrid();
    return _gridCoordinateChordSectionLocationMap;
  }

  HashMap<ChordSectionLocation, GridCoordinate> _getGridChordSectionLocationCoordinateMap() {
    getChordSectionGrid();
    return _gridChordSectionLocationCoordinateMap;
  }

  int getChordSectionLocationGridMaxColCount() {
    int maxCols = 0;
    for (GridCoordinate gridCoordinate in _getGridCoordinateChordSectionLocationMap().keys) {
      maxCols = max(maxCols, gridCoordinate.col);
    }
    return maxCols;
  }

  HashMap<SectionVersion, SectionVersion> _getChordSectionGridMatches() {
    //  enforce lazy eval
    getChordSectionGrid();
    return _chordSectionGridMatches;
  }

  Grid<ChordSectionGridData> getChordSectionGrid() {
    //  support lazy eval
    if (_chordSectionGrid != null) {
      return _chordSectionGrid!;
    }
    if (_isLyricsParseRequired) {
      _parseLyrics();
    }

    Grid<ChordSectionGridData> grid = Grid();
    _chordSectionGridCoordinateMap = HashMap();
    _chordSectionGridMatches = HashMap();
    _gridCoordinateChordSectionLocationMap = HashMap();
    _gridChordSectionLocationCoordinateMap = HashMap();

    //  grid each section
    final int offset = 1; //  offset of phrase start from section start
    int row = 0;
    int col = offset;

    //  use a separate set to avoid modifying a set
    SplayTreeSet<SectionVersion> sectionVersionsToDo = SplayTreeSet.of(_getChordSectionMap().keys);
    SplayTreeSet<ChordSection> sortedChordSections = SplayTreeSet.of(_getChordSectionMap().values);
    for (ChordSection chordSection in sortedChordSections) {
      SectionVersion sectionVersion = chordSection.sectionVersion;

      //  only do a chord section once.  it might have a duplicate set of phrases and already be listed
      if (!sectionVersionsToDo.contains(sectionVersion)) {
        continue;
      }
      sectionVersionsToDo.remove(sectionVersion);

      //  start each section on it's own line
      if (col != offset) {
        row++;
      }
      col = 0;

      logger.v('griding: ' + sectionVersion.toString() + ' (' + row.toString() + ', ' + col.toString() + ')');

      {
        //  grid the section header
        SplayTreeSet<SectionVersion> matchingSectionVersionsSet = matchingSectionVersions(sectionVersion);
        GridCoordinate coordinate = GridCoordinate(row, col);
        for (SectionVersion matchingSectionVersion in matchingSectionVersionsSet) {
          _chordSectionGridCoordinateMap[matchingSectionVersion] = coordinate;
          ChordSectionLocation loc = ChordSectionLocation(matchingSectionVersion);
          _gridChordSectionLocationCoordinateMap[loc] = coordinate;
        }
        for (SectionVersion matchingSectionVersion in matchingSectionVersionsSet) {
          //  don't add identity mapping
          if (matchingSectionVersion == sectionVersion) {
            continue;
          }
          //  note: don't use the get function!  we're building it in this method.
          _chordSectionGridMatches[matchingSectionVersion] = sectionVersion;
        }

        ChordSectionLocation loc;
        if (matchingSectionVersionsSet.length > 1) {
          loc = ChordSectionLocation.byMultipleSectionVersion(matchingSectionVersionsSet);
        } else {
          loc = ChordSectionLocation(sectionVersion);
        }
        _gridCoordinateChordSectionLocationMap[coordinate] = loc;
        _gridChordSectionLocationCoordinateMap[loc] = coordinate;
        grid.set(row, col, ChordSectionGridData(loc, chordSection, null, null));
        col = offset;
        sectionVersionsToDo.removeAll(matchingSectionVersionsSet);
      }

      //  allow for empty sections... on entry
      if (chordSection.chordRowCount == 0) {
        row++;
        col = offset;
      } else {
        //  grid each phrase
        for (int phraseIndex = 0; phraseIndex < chordSection.phrases.length; phraseIndex++) {
          //  start each phrase on it's own line
          if (col > offset) {
            row++;
            col = offset;
          }

          Phrase? phrase = chordSection.getPhrase(phraseIndex);
          if (phrase == null) {
            continue;
          }

          //  default to max measures per row
          int measuresPerRow = MusicConstants.maxMeasuresPerChordRow;

          //  adjust the measures per row for songs without apparent control of the length
          int phraseSize = phrase.measures.length;
          {
            bool endOfRowControlled = false;
            for (int measureIndex = 0; measureIndex < phraseSize; measureIndex++) {
              if (phrase.measures[measureIndex].endOfRow) {
                endOfRowControlled = true;
                break;
              }
            }
            if (!endOfRowControlled) {
              measuresPerRow = MusicConstants.nominalMeasuresPerChordRow;
            }
          }

          //  grid each measure of the phrase
          int repeatExtensionCount = 0;
          if (phraseSize == 0 && phrase.isRepeat()) {
            //  special case: deal with empty repeat
            //  fill row to measures per line
            col = offset + measuresPerRow - 1;
            {
              //  add repeat indicator
              ChordSectionLocation loc = ChordSectionLocation(sectionVersion, phraseIndex: phraseIndex);
              GridCoordinate coordinate = GridCoordinate(row, col);
              _gridCoordinateChordSectionLocationMap[coordinate] = loc;
              _gridChordSectionLocationCoordinateMap[loc] = coordinate;
              grid.set(row, col++, ChordSectionGridData(loc, chordSection, phrase, null));
            }
          } else {
            Measure measure;

            //  compute the max number of columns for this phrase
            int maxCol = offset;
            {
              int currentCol = offset;
              for (int measureIndex = 0; measureIndex < phraseSize; measureIndex++) {
                measure = phrase.getMeasure(measureIndex);
                if (measure.isComment()) {
                  continue;
                }
                currentCol++;
                if (measure.endOfRow) {
                  if (currentCol > maxCol) {
                    maxCol = currentCol;
                  }
                  currentCol = offset;
                }
              }
              if (currentCol > maxCol) {
                maxCol = currentCol;
              }
              maxCol = min(maxCol, measuresPerRow + 1);
            }

            //  place each measure in the grid
            Measure? lastMeasure;
            for (int measureIndex = 0; measureIndex < phraseSize; measureIndex++) {
              //  place comments on their own line
              //  don't upset the col location
              //  expect the output to span the row
              measure = phrase.getMeasure(measureIndex);
              if (measure.isComment()) {
                if (col > offset && lastMeasure != null && !lastMeasure.isComment()) {
                  row++;
                }
                ChordSectionLocation loc =
                    ChordSectionLocation(sectionVersion, phraseIndex: phraseIndex, measureIndex: measureIndex);
                grid.set(row, offset, ChordSectionGridData(loc, chordSection, phrase, measure));
                GridCoordinate coordinate = GridCoordinate(row, offset);
                _gridCoordinateChordSectionLocationMap[coordinate] = loc;
                _gridChordSectionLocationCoordinateMap[loc] = coordinate;
                if (measureIndex < phraseSize - 1) {
                  row++;
                } else {
                  col = offset + measuresPerRow;
                } //  prep for next phrase
                continue;
              }

              if ((lastMeasure != null && lastMeasure.endOfRow) ||
                      col >= offset + measuresPerRow //  limit line length to the measures per line
                  ) {
                //  fill the row with nulls if the row is shorter then the others in this phrase
                while (col < maxCol) {
                  grid.set(row, col++, null);
                }

                //  put an end of line marker on multiline repeats
                if (phrase.isRepeat()) {
                  grid.set(
                      row,
                      col++,
                      ChordSectionGridData(
                          ChordSectionLocation.withMarker(
                              sectionVersion,
                              phraseIndex,
                              (repeatExtensionCount > 0
                                  ? ChordSectionLocationMarker.repeatMiddleRight
                                  : ChordSectionLocationMarker.repeatUpperRight)),
                          chordSection,
                          phrase,
                          measure));
                  repeatExtensionCount++;
                }
                if (col > offset) {
                  row++;
                  col = offset;
                }
              }

              {
                //  grid the measure with it's location
                ChordSectionLocation loc =
                    ChordSectionLocation(sectionVersion, phraseIndex: phraseIndex, measureIndex: measureIndex);
                GridCoordinate coordinate = GridCoordinate(row, col);
                _gridCoordinateChordSectionLocationMap[coordinate] = loc;
                _gridChordSectionLocationCoordinateMap[loc] = coordinate;
                grid.set(row, col++, ChordSectionGridData(loc, chordSection, phrase, measure));
              }

              //  put the repeat on the end of the last line of the repeat
              if (phrase.isRepeat() && measureIndex == phraseSize - 1) {
                col = maxCol;

                //  close the multiline repeat marker
                {
                  ChordSectionLocation loc = ChordSectionLocation.withMarker(
                      sectionVersion,
                      phraseIndex,
                      repeatExtensionCount > 0
                          ? ChordSectionLocationMarker.repeatLowerRight
                          : ChordSectionLocationMarker.repeatOnOneLineRight); //  just for the visuals
                  GridCoordinate coordinate = GridCoordinate(row, col);
                  _gridCoordinateChordSectionLocationMap[coordinate] = loc;
                  _gridChordSectionLocationCoordinateMap[loc] = coordinate;
                  grid.set(row, col++, ChordSectionGridData(loc, chordSection, phrase, measure));
                }
                repeatExtensionCount = 0;

                {
                  //  add repeat indicator after markers
                  ChordSectionLocation loc = ChordSectionLocation.withRepeatMarker(
                      sectionVersion, phraseIndex, (phrase as MeasureRepeat).repeats);
                  GridCoordinate coordinate = GridCoordinate(row, col);
                  _gridCoordinateChordSectionLocationMap[coordinate] = loc;
                  _gridChordSectionLocationCoordinateMap[loc] = coordinate;
                  grid.set(row, col++, ChordSectionGridData(loc, chordSection, phrase, measure));
                }
                row++;
                col = offset;
              }

              lastMeasure = measure;
            }
          }
        }
      }
    }

    _chordSectionGrid = grid;
    //logger.d(grid.toString());

    if (Logger.level.index >= Level.verbose.index) {
      {
        logger.d('gridCoordinateChordSectionLocationMap: ');
        SplayTreeSet set = SplayTreeSet<GridCoordinate>();
        set.addAll(_gridCoordinateChordSectionLocationMap.keys);
        for (GridCoordinate coordinate in set) {
          logger.d(' ' +
              coordinate.toString() +
              ' ' +
              _gridCoordinateChordSectionLocationMap[coordinate].toString() +
              ' -> ' +
              (findMeasureNodeByLocation(_gridCoordinateChordSectionLocationMap[coordinate])?.toMarkup().toString() ??
                  ''));
        }
      }
      {
        logger.d('gridChordSectionLocationCoordinateMap: ');
        SplayTreeSet set = SplayTreeSet<ChordSectionLocation>();
        set.addAll(_gridChordSectionLocationCoordinateMap.keys);
        for (ChordSectionLocation loc in set) {
          logger.d(' ' +
              loc.toString() +
              ' ' +
              _gridChordSectionLocationCoordinateMap[loc].toString() +
              ' -> ' +
              (findMeasureNodeByGrid(_gridChordSectionLocationCoordinateMap[loc])?.toMarkup().toString() ?? ''));
        }
      }
    }

    return _chordSectionGrid!;
  }

  /// Find all matches to the given section version, including the given section version itself
  SplayTreeSet<SectionVersion> matchingSectionVersions(SectionVersion? multipleSectionVersion) {
    SplayTreeSet<SectionVersion> ret = SplayTreeSet();
    if (multipleSectionVersion == null) {
      return ret;
    }
    ChordSection? multipleChordSection = findChordSectionBySectionVersion(multipleSectionVersion);
    if (multipleChordSection == null) {
      return ret;
    }

    {
      SplayTreeSet<ChordSection> set = SplayTreeSet();
      var values = _getChordSectionMap().values;
      set.addAll(values);
      for (ChordSection chordSection in set) {
        if (multipleSectionVersion == chordSection.sectionVersion) {
          ret.add(multipleSectionVersion);
        } else if (chordSection.phrases == multipleChordSection.phrases) {
          ret.add(chordSection.sectionVersion);
        }
      }
    }
    return ret;
  }

  ChordSectionLocation? getLastChordSectionLocation() {
    Grid<ChordSectionGridData> grid = getChordSectionGrid();
    if (grid.isEmpty) {
      return null;
    }
    List<ChordSectionGridData?>? row = grid.getRow(grid.getRowCount() - 1);
    return grid.get(grid.getRowCount() - 1, (row?.length ?? 0) - 1)?.chordSectionLocation;
  }

  ChordSectionLocation? getLastMeasureLocationOfSectionVersion(SectionVersion sectionVersion) {
    return getLastMeasureLocationOfChordSection(findChordSectionBySectionVersion(sectionVersion));
  }

  ChordSectionLocation? getLastMeasureLocationOfChordSection(ChordSection? chordSection) {
    if (chordSection == null) {
      return null;
    }

    Grid<ChordSectionGridData> grid = getChordSectionGrid();
    if (grid.isEmpty) {
      return null;
    }

    for (int r = 0; r < grid.getRowCount(); r++) {
      List<ChordSectionGridData?>? row = grid.getRow(r);
      if (row == null || row.isEmpty) {
        continue;
      }
      ChordSectionGridData? chordSectionGridData = row[0];
      if (chordSectionGridData == null ||
          !chordSectionGridData.isSection ||
          chordSectionGridData.sectionVersion != chordSection.sectionVersion) {
        continue;
      }

      //  find the last grid position of the chord section
      ChordSectionLocation lastChordSectionLocation = chordSectionGridData.chordSectionLocation;
      sectionVersionLoop:
      for (; r < grid.getRowCount(); r++) {
        List<ChordSectionGridData?>? row = grid.getRow(r);
        if (row == null) {
          continue;
        }
        for (int c = 0; c < row.length; c++) {
          ChordSectionGridData? chordSectionGridData = row[c];
          logger.v('($r,$c): $chordSectionGridData');
          if (chordSectionGridData == null) {
            continue;
          }
          if (!chordSectionGridData.isMeasure) {
            //  fixme: should be a better test for repeat
            continue;
          }
          if (chordSectionGridData.sectionVersion == chordSection.sectionVersion) {
            lastChordSectionLocation = chordSectionGridData.chordSectionLocation;
          } else if (c == 0) {
            break sectionVersionLoop; //  this row is not the correct section version
          }
        }
      }
      return lastChordSectionLocation;
    }
    return null; //  chord section not found
  }

  HashMap<SectionVersion, GridCoordinate> getChordSectionGridCoordinateMap() {
    // force grid population from lazy eval
    if (_chordSectionGrid == null) {
      getChordSectionGrid();
    }
    return _chordSectionGridCoordinateMap;
  }

  void _invalidateChords() {
    _chords = '';
    _clearCachedValues();
  }

  void _clearCachedValues() {
    logger.v('_clearCachedValues()');
    _isLyricsParseRequired = true;
    _chordSectionGrid = null;
    _complexity = 0;
    _chordsAsMarkup = null;
    _songMomentGrid = null;
    _songMoments = [];
    _duration = 0;
    totalBeats = 0;
  }

  String chordsToJsonTransportString() {
    StringBuffer sb = StringBuffer();

    SplayTreeSet<ChordSection> set = SplayTreeSet();
    set.addAll(_getChordSectionMap().values);
    for (ChordSection chordSection in set) {
      sb.write(chordSection.toJson());
    }
    return sb.toString();
  }

  String chordMarkupForLyrics() {
    var sb = StringBuffer();
    for (var lyricSection in lyricSections) {
      var chordSection = findChordSectionByLyricSection(lyricSection);
      assert(chordSection != null);
      sb.write(chordSection?.toMarkupInRows(lyricSection.lyricsLines.length + 1));
    }
    return sb.toString();
  }

  String toMarkup({bool asEntry = false}) {
    //  lazy shortcut
    if (!asEntry && _chordsAsMarkup != null) {
      return _chordsAsMarkup!;
    }

    StringBuffer sb = StringBuffer();

    SplayTreeSet<SectionVersion> sortedSectionVersions = SplayTreeSet.of(_getChordSectionMap().keys);
    SplayTreeSet<SectionVersion> completedSectionVersions = SplayTreeSet();

    //  markup by section version order
    for (SectionVersion sectionVersion in sortedSectionVersions) {
      //  don't repeat anything
      if (completedSectionVersions.contains(sectionVersion)) {
        continue;
      }
      completedSectionVersions.add(sectionVersion);

      //  find all section versions with the same chords
      ChordSection? chordSection = _getChordSectionMap()[sectionVersion];
      if (chordSection == null || chordSection.isEmpty) {
        //  empty sections stand alone
        sb.write(sectionVersion.toString());
        sb.write(' ');
      } else {
        SplayTreeSet<SectionVersion> currentSectionVersions = SplayTreeSet();
        for (SectionVersion otherSectionVersion in sortedSectionVersions) {
          if (listsEqual(chordSection.phrases, _getChordSectionMap()[otherSectionVersion]?.phrases)) {
            currentSectionVersions.add(otherSectionVersion);
            completedSectionVersions.add(otherSectionVersion);
          }
        }

        //  list the section versions for this chord section
        for (SectionVersion currentSectionVersion in currentSectionVersions) {
          sb.write(currentSectionVersion.toString());
          sb.write(' ');
        }
      }
      sb.write(asEntry ? '\n' : '');

      //  chord section phrases (only) to output
      if (chordSection != null) {
        sb.write(asEntry ? chordSection.phrasesToEntry() : chordSection.phrasesToMarkup());
      }
      sb.write(asEntry ? '\n' : ' '); //  for human readability only
    }
    _chordsAsMarkup = sb.toString();
    return _chordsAsMarkup!;
  }

  String? toMarkupByLocation(ChordSectionLocation? location) {
    StringBuffer sb = StringBuffer();
    if (location != null) {
      if (location.isSection) {
        sb.write(location.toString());
        sb.write(' ');
        sb.write(getChordSectionByLocation(location)?.phrasesToMarkup());
        return sb.toString();
      } else {
        MeasureNode? measureNode = findMeasureNodeByLocation(location);
        if (measureNode != null) {
          return measureNode.toMarkup();
        }
      }
    }
    return null;
  }

  String? toEntry(ChordSectionLocation? location) {
    StringBuffer sb = StringBuffer();
    if (location != null) {
      if (location.isSection) {
        sb.write(getChordSectionByLocation(location)?.transposeToKey(key).toEntry());
        return sb.toString();
      } else {
        MeasureNode? measureNode = findMeasureNodeByLocation(location);
        if (measureNode != null) {
          return measureNode.transposeToKey(key).toEntry();
        }
      }
    }
    return null;
  }

  /// Add the given section version to the song chords
  bool addSectionVersion(SectionVersion? sectionVersion) {
    if (sectionVersion == null || _getChordSectionMap().containsKey(sectionVersion)) {
      return false;
    }
    _getChordSectionMap()[sectionVersion] = ChordSection(sectionVersion, null);
    _invalidateChords();
    setCurrentChordSectionLocation(ChordSectionLocation(sectionVersion));
    setCurrentMeasureEditType(MeasureEditType.append);
    return true;
  }

  bool deleteCurrentChordSectionLocation() {
    setCurrentMeasureEditType(MeasureEditType.delete); //  tell the world

    preMod(null);

    //  deal with deletes
    ChordSectionLocation? location = getCurrentChordSectionLocation();
    if (location == null) {
      postMod();
      return false;
    }

    //  find the named chord section
    ChordSection? chordSection = getChordSectionByLocation(location);
    if (chordSection == null) {
      postMod();
      return false;
    }

    if (chordSection.phrases.isEmpty) {
      chordSection.phrases.add(Phrase([], 0));
    }

    Phrase? phrase;
    if (location.hasPhraseIndex) {
      try {
        phrase = chordSection.getPhrase(location.phraseIndex);
      } catch (e) {
        ;
      }
    }
    phrase ??= chordSection.phrases[0]; //  use the default empty list

    bool ret = false;

    if (location.isMeasure) {
      ret = phrase.edit(MeasureEditType.delete, location.measureIndex, null);
      if (ret && phrase.isEmpty) {
        return deleteCurrentChordSectionPhrase();
      }
    } else if (location.isPhrase) {
      return deleteCurrentChordSectionPhrase();
    } else if (location.isSection) {
      //  find the section prior to the one being deleted
      SectionVersion? nextSectionVersion = _priorSectionVersion(chordSection.sectionVersion);
      if (chordSection.sectionVersion == nextSectionVersion) {
        nextSectionVersion = _nextSectionVersion(chordSection.sectionVersion);
      }
      logger.d('nextSectionVersion: ' + nextSectionVersion.toString());

      ret = (_getChordSectionMap().remove(chordSection.sectionVersion) != null);
      if (ret) {
        _invalidateChords(); //  force lazy re-compute of markup when required, after and edit

        //  move deleted current to end of previous section
        nextSectionVersion ??= _firstSectionVersion();
        if (nextSectionVersion != null) {
          location = ChordSectionLocation(nextSectionVersion);
        }
      }
    }
    return standardEditCleanup(ret, location);
  }

  bool deleteCurrentChordSectionPhrase() {
    ChordSectionLocation? location = getCurrentChordSectionLocation();
    ChordSection? chordSection = getChordSectionByLocation(location);
    if (location == null || chordSection == null) {
      return false;
    }
    bool ret = chordSection.deletePhrase(location.phraseIndex);
    if (ret) {
      //  move the current location if required
      if (location.phraseIndex >= chordSection.phrases.length) {
        if (chordSection.phrases.isEmpty) {
          location = ChordSectionLocation(chordSection.sectionVersion);
        } else {
          int i = chordSection.phrases.length - 1;
          Phrase? phrase = chordSection.getPhrase(i);
          if (phrase != null) {
            int m = phrase.measures.length - 1;
            location = ChordSectionLocation(chordSection.sectionVersion, phraseIndex: i, measureIndex: m);
          }
        }
      }
    }
    return standardEditCleanup(ret, location);
  }

  void preMod(MeasureNode? measureNode) {
    logger.d('startingChords(\"' + toMarkup() + '\");');
    logger.d(' pre(MeasureEditType.' +
        currentMeasureEditType.toString() +
        ', \"' +
        getCurrentChordSectionLocation().toString() +
        '\"' +
        ', \"' +
        (getCurrentChordSectionLocationMeasureNode() == null
            ? 'null'
            : (getCurrentChordSectionLocationMeasureNode()?.toMarkup() ?? 'null')) +
        '\"' +
        ', \"' +
        (measureNode == null ? 'null' : measureNode.toMarkup()) +
        '\");');
  }

  void postMod() {
    logger.d('resultChords(\"' + toMarkup() + '\");');
    logger.d('post(MeasureEditType.' +
        currentMeasureEditType.toString() +
        ', \"' +
        getCurrentChordSectionLocation().toString() +
        '\"' +
        ', \"' +
        (getCurrentChordSectionLocationMeasureNode() == null
            ? 'null'
            : (getCurrentChordSectionLocationMeasureNode()?.toMarkup() ?? 'null')) +
        '\");');
  }

  bool editList(List<MeasureNode> measureNodes) {
    if (measureNodes.isEmpty) {
      return false;
    }

    for (MeasureNode measureNode in measureNodes) {
      //  process each measure node
      if (!editMeasureNode(measureNode)) {
        return false;
      }
    }
    return true;
  }

  bool deleteCurrentSelection() {
    setCurrentMeasureEditType(MeasureEditType.delete);
    return editMeasureNode(null);
  }

  /// Edit the given measure in or out of the song based on the data from the edit location.
  bool editMeasureNode(MeasureNode? measureNode) {
    MeasureEditType editType = currentMeasureEditType;

    if (editType == MeasureEditType.delete) {
      return deleteCurrentChordSectionLocation();
    }

    preMod(measureNode);

    if (measureNode == null) {
      postMod();
      return false;
    }

    ChordSectionLocation? location = getCurrentChordSectionLocation();

    //  find the named chord section
    ChordSection? chordSection = getChordSectionByLocation(location);
    if (chordSection == null) {
      switch (measureNode.measureNodeType) {
        case MeasureNodeType.section:
          chordSection = measureNode as ChordSection;
          break;
        default:
          chordSection = _getChordSectionMap()[SectionVersion.defaultInstance];
          if (chordSection == null) {
            chordSection = ChordSection.getDefault();
            _getChordSectionMap()[chordSection.sectionVersion] = chordSection;
            _invalidateChords();
          }
          break;
      }
    }

    //  all chord sections should have at least an empty phrase
    if (chordSection.phrases.isEmpty) {
      chordSection.phrases.add(Phrase([], 0));
    }

    //  find the phrase
    Phrase? phrase;
    if (location != null && location.hasPhraseIndex) {
      try {
        phrase = chordSection.getPhrase(location.phraseIndex);
      } catch (e) {
        ;
      }
    }
    phrase ??= chordSection.phrases.last; //  use the default empty list

    bool ret = false;

    //  handle situations by the type of measure node being added
    ChordSectionLocation newLocation;
    ChordSection newChordSection;
    MeasureRepeat newRepeat;
    Phrase newPhrase;
    switch (measureNode.measureNodeType) {
      case MeasureNodeType.section:
        switch (editType) {
          case MeasureEditType.delete:
            //  find the section prior to the one being deleted
            SectionVersion? nextSectionVersion = _priorSectionVersion(chordSection.sectionVersion);
            ret = (_getChordSectionMap().remove(chordSection.sectionVersion) != null);
            if (ret) {
              _invalidateChords();

              //  move deleted current to end of previous section
              nextSectionVersion ??= _firstSectionVersion();
              if (nextSectionVersion != null) {
                location = ChordSectionLocation(nextSectionVersion);
              }
              //else ; // fixme: set location to empty location
            }
            break;
          default:
            //  all sections replace themselves
            newChordSection = measureNode as ChordSection;
            _getChordSectionMap()[newChordSection.sectionVersion] = newChordSection;
            ret = true;
            location = ChordSectionLocation(newChordSection.sectionVersion);
            break;
        }
        return standardEditCleanup(ret, location);

      case MeasureNodeType.repeat:
        newRepeat = measureNode as MeasureRepeat;
        if (newRepeat.isEmpty) {
          //  empty repeat
          if (location != null && phrase.isRepeat()) {
            //  change repeats
            MeasureRepeat repeat = phrase as MeasureRepeat;
            if (newRepeat.repeats < 2) {
              setCurrentMeasureEditType(MeasureEditType.append);

              //  convert repeat to phrase
              newPhrase = Phrase(repeat.measures, location.phraseIndex);
              int phaseIndex = location.phraseIndex;
              if (phaseIndex > 0 && chordSection.getPhrase(phaseIndex - 1)?.measureNodeType == MeasureNodeType.phrase) {
                //  expect combination of the two phrases
                int newPhraseIndex = phaseIndex - 1;
                Phrase? priorPhrase = chordSection.getPhrase(newPhraseIndex);
                location = ChordSectionLocation(chordSection.sectionVersion,
                    phraseIndex: newPhraseIndex,
                    measureIndex: (priorPhrase?.measures.length ?? 0) + newPhrase.measures.length - 1);
                return standardEditCleanup(
                    chordSection.deletePhrase(phaseIndex) && chordSection.add(phaseIndex, newPhrase), location);
              }
              location = ChordSectionLocation(chordSection.sectionVersion,
                  phraseIndex: location.phraseIndex, measureIndex: newPhrase.measures.length - 1);
              logger.d('new loc: ' + location.toString());
              return standardEditCleanup(
                  chordSection.deletePhrase(newPhrase.phraseIndex) &&
                      chordSection.add(newPhrase.phraseIndex, newPhrase),
                  location);
            }
            repeat.repeats = newRepeat.repeats;
            return standardEditCleanup(true, location);
          }
          if (newRepeat.repeats <= 1) {
            return true; //  no change but no change was asked for
          }

          if (!phrase.isEmpty) {
            //  convert phrase line to a repeat
            GridCoordinate? minGridCoordinate = getGridCoordinate(location);
            if (minGridCoordinate != null) {
              minGridCoordinate = GridCoordinate(minGridCoordinate.row, 1);
            }
            MeasureNode? minMeasureNode = findMeasureNodeByGrid(minGridCoordinate);
            ChordSectionLocation? minLocation = getChordSectionLocation(minGridCoordinate);

            GridCoordinate? maxGridCoordinate = getGridCoordinate(location);
            if (maxGridCoordinate != null) {
              maxGridCoordinate = GridCoordinate(
                  maxGridCoordinate.row, (_chordSectionGrid?.getRow(maxGridCoordinate.row)?.length ?? -1) - 1);
            }
            MeasureNode? maxMeasureNode = findMeasureNodeByGrid(maxGridCoordinate);
            ChordSectionLocation? maxLocation = getChordSectionLocation(maxGridCoordinate);
            logger.d('min: ' +
                minGridCoordinate.toString() +
                ' ' +
                (minMeasureNode?.toMarkup() ?? 'unknown') +
                ' ' +
                (minLocation?.measureIndex.toString() ?? 'unknown'));
            logger.d('max: ' +
                maxGridCoordinate.toString() +
                ' ' +
                (maxMeasureNode?.toMarkup() ?? 'unknown') +
                ' ' +
                (maxLocation?.measureIndex.toString() ?? 'unknown'));

            //  delete the old
            int phraseIndex = phrase.phraseIndex;
            chordSection.deletePhrase(phraseIndex);
            //  replace the old early part
            if (minLocation != null && minLocation.measureIndex > 0) {
              List<Measure> range = [];
              range.addAll(phrase.measures.getRange(0, minLocation.measureIndex));
              chordSection.add(phraseIndex, Phrase(range, phraseIndex));
              phraseIndex++;
            }
            //  replace the sub-phrase with a repeat
            if (minLocation != null && maxLocation != null) {
              List<Measure> range = [];
              range.addAll(phrase.measures.getRange(minLocation.measureIndex, maxLocation.measureIndex + 1));
              MeasureRepeat repeat = MeasureRepeat(range, phraseIndex, newRepeat.repeats);
              chordSection.add(phraseIndex, repeat);
              location = ChordSectionLocation(chordSection.sectionVersion, phraseIndex: phraseIndex);
              phraseIndex++;
            }
            //  replace the old late part
            if (maxLocation != null && maxLocation.measureIndex < phrase.measures.length - 1) {
              List<Measure> range = [];
              List<Measure> measures = phrase.measures;
              range.addAll(measures.getRange(maxLocation.measureIndex + 1, measures.length));
              chordSection.add(phraseIndex, Phrase(range, phraseIndex));
              //phraseIndex++;
            }
            return standardEditCleanup(true, location);
          }
        } else {
          newPhrase = newRepeat;

          //  demote x1 repeat to phrase
          if (newRepeat.repeats < 2) {
            newPhrase = Phrase(newRepeat.measures, newRepeat.phraseIndex);
          }

          //  non-empty repeat
          switch (editType) {
            case MeasureEditType.delete:
              return standardEditCleanup(chordSection.deletePhrase(phrase.phraseIndex), location);
            case MeasureEditType.append:
              newPhrase.setPhraseIndex(phrase.phraseIndex + 1);
              return standardEditCleanup(chordSection.add(phrase.phraseIndex + 1, newPhrase),
                  ChordSectionLocation(chordSection.sectionVersion, phraseIndex: phrase.phraseIndex + 1));
            case MeasureEditType.insert:
              newPhrase.setPhraseIndex(phrase.phraseIndex);
              return standardEditCleanup(chordSection.insert(phrase.phraseIndex, newPhrase), location);
            case MeasureEditType.replace:
              newPhrase.setPhraseIndex(phrase.phraseIndex);
              return standardEditCleanup(
                  chordSection.deletePhrase(phrase.phraseIndex) && chordSection.add(newPhrase.phraseIndex, newPhrase),
                  location);
          }
        }
        break;

      case MeasureNodeType.phrase:
        newPhrase = measureNode as Phrase;
        int phraseIndex = 0;
        switch (editType) {
          case MeasureEditType.append:
            if (location == null) {
              if (chordSection.getPhraseCount() == 0) {
                //  append as first phrase
                location = ChordSectionLocation(chordSection.sectionVersion,
                    phraseIndex: 0, measureIndex: newPhrase.length - 1);
                newPhrase.setPhraseIndex(phraseIndex);
                return standardEditCleanup(chordSection.add(phraseIndex, newPhrase), location);
              }

              //  last of section
              Phrase? lastPhrase = chordSection.lastPhrase();
              if (lastPhrase != null) {
                switch (lastPhrase.measureNodeType) {
                  case MeasureNodeType.phrase:
                    location = ChordSectionLocation(chordSection.sectionVersion,
                        phraseIndex: lastPhrase.phraseIndex, measureIndex: lastPhrase.length + newPhrase.length - 1);
                    return standardEditCleanup(lastPhrase.add(newPhrase.measures), location);
                  default:
                    break;
                }

                phraseIndex = chordSection.getPhraseCount();
                location = ChordSectionLocation(chordSection.sectionVersion,
                    phraseIndex: phraseIndex, measureIndex: lastPhrase.length);
                newPhrase.setPhraseIndex(phraseIndex);
                return standardEditCleanup(chordSection.add(phraseIndex, newPhrase), location);
              }
            }
            if (chordSection.isEmpty) {
              location = ChordSectionLocation(chordSection.sectionVersion,
                  phraseIndex: phraseIndex, measureIndex: newPhrase.length - 1);
              newPhrase.setPhraseIndex(phraseIndex);
              return standardEditCleanup(chordSection.add(phraseIndex, newPhrase), location);
            }

            if (location != null) {
              if (location.hasMeasureIndex) {
                newLocation = ChordSectionLocation(chordSection.sectionVersion,
                    phraseIndex: phrase.phraseIndex, measureIndex: location.measureIndex + newPhrase.length);
                return standardEditCleanup(phrase.edit(editType, location.measureIndex, newPhrase), newLocation);
              }
              if (location.hasPhraseIndex) {
                //  assure prior end of row if appending to the end of a phrase
                if (!phrase.isEmpty && !phrase.isRepeat()) {
                  var priorLocation = ChordSectionLocation(chordSection.sectionVersion,
                      phraseIndex: phraseIndex, measureIndex: phrase.length - 1);
                  setChordSectionLocationMeasureEndOfRow(priorLocation, true);
                }

                phraseIndex = location.phraseIndex + 1;
                newPhrase.setPhraseIndex(phraseIndex);
                newLocation = ChordSectionLocation(chordSection.sectionVersion,
                    phraseIndex: phraseIndex, measureIndex: newPhrase.length - 1);
                return standardEditCleanup(chordSection.add(phraseIndex, newPhrase), newLocation);
              }
            }

            newLocation = ChordSectionLocation(chordSection.sectionVersion,
                phraseIndex: phrase.phraseIndex + 1, measureIndex: newPhrase.length - 1);
            //  rely on the clean up to join to adjacent phrases
            newPhrase.setPhraseIndex(phraseIndex + 1);
            return standardEditCleanup(chordSection.add(newPhrase.phraseIndex, newPhrase), newLocation);

          case MeasureEditType.insert:
            if (location == null) {
              if (chordSection.getPhraseCount() == 0) {
                //  append as first phrase
                location = ChordSectionLocation(chordSection.sectionVersion,
                    phraseIndex: 0, measureIndex: newPhrase.length - 1);
                newPhrase.setPhraseIndex(phraseIndex);
                return standardEditCleanup(chordSection.add(phraseIndex, newPhrase), location);
              }

              //  first of section
              Phrase? firstPhrase = chordSection.getPhrase(0);
              if (firstPhrase != null) {
                switch (firstPhrase.measureNodeType) {
                  case MeasureNodeType.phrase:
                    location = ChordSectionLocation(chordSection.sectionVersion,
                        phraseIndex: firstPhrase.phraseIndex, measureIndex: 0);
                    return standardEditCleanup(firstPhrase.add(newPhrase.measures), location);
                  default:
                    break;
                }

                phraseIndex = 0;
                location = ChordSectionLocation(chordSection.sectionVersion,
                    phraseIndex: phraseIndex, measureIndex: firstPhrase.length);
                newPhrase.setPhraseIndex(phraseIndex);
                return standardEditCleanup(chordSection.add(phraseIndex, newPhrase), location);
              }
            }
            if (chordSection.isEmpty) {
              location = ChordSectionLocation(chordSection.sectionVersion,
                  phraseIndex: phraseIndex, measureIndex: newPhrase.length - 1);
              newPhrase.setPhraseIndex(phraseIndex);
              return standardEditCleanup(chordSection.add(phraseIndex, newPhrase), location);
            }

            if (location != null) {
              //  insert new measures at the given measure location
              if (location.hasMeasureIndex) {
                newLocation = ChordSectionLocation(chordSection.sectionVersion,
                    phraseIndex: phrase.phraseIndex, measureIndex: location.measureIndex + newPhrase.length - 1);
                return standardEditCleanup(phrase.edit(editType, location.measureIndex, newPhrase), newLocation);
              } else if (phrase is MeasureRepeat) {
                //  insert new phrase of new measures in front of a repeat
                newLocation = ChordSectionLocation(chordSection.sectionVersion,
                    phraseIndex: location.hasPhraseIndex ? location.phraseIndex : 0,
                    measureIndex: newPhrase.length - 1);
                return standardEditCleanup(chordSection.insert(0, newPhrase), newLocation);
              }
              //  else insert the new measures at the front of the existing phrase measures with the code below
            }

            //  insert new phrase measures in front of existing phrase measures
            newLocation = ChordSectionLocation(chordSection.sectionVersion,
                phraseIndex: phrase.phraseIndex, measureIndex: newPhrase.length - 1);
            return standardEditCleanup(phrase.addAllAt(0, newPhrase.measures), newLocation);

          case MeasureEditType.replace:
            if (location != null) {
              if (location.hasPhraseIndex) {
                if (location.hasMeasureIndex) {
                  newLocation = ChordSectionLocation(chordSection.sectionVersion,
                      phraseIndex: location.phraseIndex, measureIndex: location.measureIndex + newPhrase.length - 1);

                  //     fixme here??: should be add to sectionVersion, not add of measures to phrase
                  return standardEditCleanup(phrase.edit(editType, location.measureIndex, newPhrase), newLocation);
                }
                //  delete the phrase before replacing it
                phraseIndex = location.phraseIndex;
                Phrase? priorPhrase = chordSection.getPhrase(phraseIndex - 1);
                if (priorPhrase != null && phraseIndex > 0 && priorPhrase.measureNodeType == MeasureNodeType.phrase) {
                  //  expect combination of the two phrases

                  location = ChordSectionLocation(chordSection.sectionVersion,
                      phraseIndex: phraseIndex - 1,
                      measureIndex: priorPhrase.measures.length + newPhrase.measures.length);
                  return standardEditCleanup(
                      chordSection.deletePhrase(phraseIndex) && chordSection.add(phraseIndex, newPhrase), location);
                } else {
                  location = ChordSectionLocation(chordSection.sectionVersion,
                      phraseIndex: phraseIndex, measureIndex: newPhrase.measures.length - 1);
                  return standardEditCleanup(
                      chordSection.deletePhrase(phraseIndex) && chordSection.add(phraseIndex, newPhrase), location);
                }
              }
              break;
            }
            phraseIndex = (location != null && location.hasPhraseIndex ? location.phraseIndex : 0);
            break;
          default:
            phraseIndex = (location != null && location.hasPhraseIndex ? location.phraseIndex : 0);
            break;
        }
        newPhrase.setPhraseIndex(phraseIndex);
        location = ChordSectionLocation(chordSection.sectionVersion,
            phraseIndex: phraseIndex, measureIndex: newPhrase.length - 1);
        return standardEditCleanup(chordSection.add(phraseIndex, newPhrase), location);

      case MeasureNodeType.measure:
      case MeasureNodeType.comment:
        //  add measure to current phrase
        if (location != null) {
          if (location.hasMeasureIndex) {
            newLocation = location;
            switch (editType) {
              case MeasureEditType.append:
                newLocation = location.nextMeasureIndexLocation();
                break;
              case MeasureEditType.replace:
                //  deal with a change of endOfRow
                Measure newMeasure = measureNode as Measure;
                Measure oldMeasure = phrase.measures[newLocation.measureIndex];
                if (newMeasure.endOfRow != oldMeasure.endOfRow) {
                  _invalidateChords();
                }
                break;
              default:
                break;
            }
            return standardEditCleanup(phrase.edit(editType, location.measureIndex, measureNode), newLocation);
          }

          //  add measure to chord section by creating a new phase
          if (location.hasPhraseIndex) {
            List<Measure> measures = [];
            measures.add(measureNode as Measure);
            newPhrase = Phrase(measures, location.phraseIndex);
            switch (editType) {
              case MeasureEditType.delete:
                break;
              case MeasureEditType.append:
                newPhrase.setPhraseIndex(location.phraseIndex + 1);
                return standardEditCleanup(chordSection.add(newPhrase.phraseIndex, newPhrase),
                    ChordSectionLocation(location.sectionVersion, phraseIndex: newPhrase.phraseIndex, measureIndex: 0));
              case MeasureEditType.insert:
                newLocation =
                    ChordSectionLocation(location.sectionVersion, phraseIndex: newPhrase.phraseIndex, measureIndex: 0);
                newPhrase.setPhraseIndex(phrase.phraseIndex);
                return standardEditCleanup(chordSection.add(phrase.phraseIndex, newPhrase), newLocation);
              case MeasureEditType.replace:
                newPhrase.setPhraseIndex(phrase.phraseIndex);
                return standardEditCleanup(
                    chordSection.deletePhrase(phrase.phraseIndex) && chordSection.add(newPhrase.phraseIndex, newPhrase),
                    location);
            }
          }

          //  add measure to an empty chord section
          newPhrase = Phrase([measureNode as Measure], 0);
          newLocation =
              ChordSectionLocation(location.sectionVersion, phraseIndex: newPhrase.phraseIndex, measureIndex: 0);
          newPhrase.setPhraseIndex(phrase.phraseIndex);
          return standardEditCleanup(chordSection.add(phrase.phraseIndex, newPhrase), newLocation);
        }
        break;
      case MeasureNodeType.decoration:
      case MeasureNodeType.lyric:
        return false;
    }

    //  edit measure node into location
    switch (editType) {
      case MeasureEditType.insert:
        if (location != null) {
          switch (measureNode.measureNodeType) {
            case MeasureNodeType.repeat:
            case MeasureNodeType.phrase:
              ret = chordSection.insert(location.phraseIndex, measureNode);
              break;
            default:
              break;
          }
          //  no location change
          standardEditCleanup(ret, location);
        }
        break;

      case MeasureEditType.append:
        //  promote marker to repeat
        if (location != null) {
          try {
            Measure refMeasure = phrase.getMeasure(location.measureIndex);
            if (refMeasure is MeasureRepeatMarker && phrase.isRepeat()) {
              MeasureRepeat measureRepeat = phrase as MeasureRepeat;
              if (refMeasure == measureRepeat.getRepeatMarker()) {
                //  appending at the repeat marker forces the section to add a sequenceItem list after the repeat
                int phraseIndex = chordSection.indexOf(measureRepeat) + 1;
                newPhrase = Phrase([], phraseIndex);
                chordSection.phrases.insert(phraseIndex + 1, newPhrase);
                phrase = newPhrase;
              }
            }
          } catch (e) {
            //  ignore attempt
          }

          if (location.isSection) {
            switch (measureNode.measureNodeType) {
              case MeasureNodeType.section:
                SectionVersion? sectionVersion = location.sectionVersion;
                if (sectionVersion != null) {
                  _getChordSectionMap()[sectionVersion] = measureNode as ChordSection;
                  return standardEditCleanup(true, location.nextMeasureIndexLocation());
                }
                break;
              case MeasureNodeType.phrase:
              case MeasureNodeType.repeat:
                return standardEditCleanup(chordSection.add(location.phraseIndex, measureNode as Phrase), location);
              default:
                break;
            }
          }
          if (location.isPhrase) {
            switch (measureNode.measureNodeType) {
              case MeasureNodeType.repeat:
              case MeasureNodeType.phrase:
                chordSection.phrases.insert(location.phraseIndex + 1, measureNode as Phrase);
                return standardEditCleanup(true, location);
              default:
                break;
            }
            break;
          }
        }

        break;

      case MeasureEditType.delete:
        //  note: measureNode is ignored, and should be ignored
        if (location != null) {
          if (location.isMeasure) {
            ret = phrase.deleteAt(location.measureIndex);
            if (ret) {
              if (location.measureIndex < phrase.length) {
                location = ChordSectionLocation(chordSection.sectionVersion,
                    phraseIndex: location.phraseIndex, measureIndex: location.measureIndex);
                measureNode = findMeasureNodeByLocation(location);
              } else {
                if (phrase.length > 0) {
                  int index = phrase.length - 1;
                  location = ChordSectionLocation(chordSection.sectionVersion,
                      phraseIndex: location.phraseIndex, measureIndex: index);
                  measureNode = findMeasureNodeByLocation(location);
                } else {
                  chordSection.deletePhrase(location.phraseIndex);
                  if (chordSection.getPhraseCount() > 0) {
                    location = ChordSectionLocation(chordSection.sectionVersion,
                        phraseIndex: 0, measureIndex: chordSection.getPhrase(0)!.length - 1);
                    measureNode = findMeasureNodeByLocation(location);
                  } else {
                    //  last phase was deleted
                    location = ChordSectionLocation(chordSection.sectionVersion);
                    measureNode = findMeasureNodeByLocation(location);
                  }
                }
              }
            }
          } else if (location.isPhrase) {
            ret = chordSection.deletePhrase(location.phraseIndex);
            if (ret) {
              if (location.phraseIndex > 0) {
                int index = location.phraseIndex - 1;
                location = ChordSectionLocation(chordSection.sectionVersion,
                    phraseIndex: index, measureIndex: chordSection.getPhrase(index)!.length - 1);
                measureNode = findMeasureNodeByLocation(location);
              } else if (chordSection.getPhraseCount() > 0) {
                location = ChordSectionLocation(chordSection.sectionVersion,
                    phraseIndex: 0, measureIndex: chordSection.getPhrase(0)!.length - 1);
                measureNode = findMeasureNodeByLocation(location);
              } else {
                //  last one was deleted
                location = ChordSectionLocation(chordSection.sectionVersion);
                measureNode = findMeasureNodeByLocation(location);
              }
            }
          } else if (location.isSection) {
            //  fixme: what did i have in mind?
          }
          standardEditCleanup(ret, location);
        }
        break;
      default:
        break;
    }
    postMod();
    return ret;
  }

  /// Important function to clean up data conditions after an edit
  bool standardEditCleanup(bool ret, ChordSectionLocation? location) {
    if (ret) {
      _invalidateChords(); //  force lazy re-compute of markup when required, after an edit

      collapsePhrases(location);
      setCurrentChordSectionLocation(location);
      resetLastModifiedDateToNow();

      switch (currentMeasureEditType) {
        // case MeasureEditType.replace:
        case MeasureEditType.delete:
          if (getCurrentChordSectionLocationMeasureNode() == null) {
            setCurrentMeasureEditType(MeasureEditType.append);
          }
          break;
        default:
          setCurrentMeasureEditType(MeasureEditType.append);
          break;
      }
    }
    postMod();
    return ret;
  }

  /// Collapse adjacent phrases into a single phrase
  /// that have come together due to an edit.
  void collapsePhrases(ChordSectionLocation? location) {
    if (location == null) {
      return;
    }
    ChordSection? chordSection = _getChordSectionMap()[location.sectionVersion];
    if (chordSection == null) {
      return;
    }

    if (chordSection.collapsePhrases()) {
      _invalidateChords();
    }
  }

  SectionVersion? _priorSectionVersion(SectionVersion sectionVersion) {
    SplayTreeSet<SectionVersion> sortedSectionVersions = SplayTreeSet<SectionVersion>.of(_getChordSectionMap().keys);
    if (sortedSectionVersions.length < 2) {
      return null;
    }

    SectionVersion? ret;
    for (var sv in sortedSectionVersions) {
      if (sectionVersion.compareTo(sv) > 0) {
        ret = sv;
        break;
      }
    }

    logger.d('_priorSectionVersion($sectionVersion): $ret');
    logger.d(sortedSectionVersions.toList().toString());
    return ret;
  }

  SectionVersion? _nextSectionVersion(SectionVersion sectionVersion) {
    SplayTreeSet<SectionVersion> sortedSectionVersions = SplayTreeSet<SectionVersion>.of(_getChordSectionMap().keys);

    SectionVersion? ret;
    for (var sv in sortedSectionVersions) {
      if (sectionVersion.compareTo(sv) < 0) {
        ret = sv;
        break;
      }
    }
    logger.d('_nextSectionVersion($sectionVersion): $ret');
    logger.d(sortedSectionVersions.toList().toString());
    return ret;
  }

  SectionVersion? _firstSectionVersion() {
    SplayTreeSet<SectionVersion> set = SplayTreeSet.of(_getChordSectionMap().keys);
    return (set.isEmpty ? null : set.first);
  }

  ChordSectionLocation? findLastChordSectionLocation(ChordSection? chordSection) {
    if (chordSection == null || chordSection.phrases.isEmpty) {
      return null;
    }

    int phraseIndex = chordSection.phrases.length - 1;
    Phrase? phrase = chordSection.lastPhrase();
    if (phrase == null) {
      return null;
    }
    int measureIndex = phrase.length - 1;

    return ChordSectionLocation(chordSection.sectionVersion, phraseIndex: phraseIndex, measureIndex: measureIndex);
  }

  ChordSectionLocation? getChordSectionLocation(GridCoordinate? gridCoordinate) {
    return _getGridCoordinateChordSectionLocationMap()[gridCoordinate];
  }

  GridCoordinate? getGridCoordinate(ChordSectionLocation? chordSectionLocation) {
    if (chordSectionLocation == null) {
      return null;
    }
    chordSectionLocation =
        chordSectionLocation.changeSectionVersion(_getChordSectionGridMatches()[chordSectionLocation.sectionVersion]);
    return _getGridChordSectionLocationCoordinateMap()[chordSectionLocation];
  }

  /// Find the chord section for the given type of chord section
  ChordSection? findChordSectionBySectionVersion(SectionVersion? sectionVersion) {
    if (sectionVersion == null) {
      return null;
    }
    return _getChordSectionMap()[sectionVersion]; //  get not type safe!!!!
  }

  Measure? findMeasureByChordSectionLocation(ChordSectionLocation? chordSectionLocation) {
    if (chordSectionLocation == null || chordSectionLocation.sectionVersion == null) {
      return null;
    }
    SectionVersion sectionVersion = chordSectionLocation.sectionVersion!;

    try {
      if (chordSectionLocation.isMeasure) {
        return _getChordSectionMap()[sectionVersion]
            ?.getPhrase(chordSectionLocation.phraseIndex)
            ?.getMeasure(chordSectionLocation.measureIndex);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  void setChordSectionLocationMeasureEndOfRow(ChordSectionLocation? chordSectionLocation, bool? endOfRow) {
    if (chordSectionLocation == null || endOfRow == null) {
      return;
    }
    Measure? measure = findMeasureByChordSectionLocation(chordSectionLocation);
    if (measure != null && measure.endOfRow != endOfRow) {
      measure.endOfRow = endOfRow;
      _invalidateChords();
    }
  }

  /// convenience method
  void setCurrentChordSectionLocationMeasureEndOfRow(bool endOfRow) {
    setChordSectionLocationMeasureEndOfRow(getCurrentChordSectionLocation(), endOfRow);
  }

  Measure? getCurrentChordSectionLocationMeasure() {
    ChordSectionLocation? location = getCurrentChordSectionLocation();
    if (location == null) {
      return null;
    }
    if (location.hasMeasureIndex) {
      int index = location.measureIndex;
      if (index > 0) {
        location =
            ChordSectionLocation(location.sectionVersion, phraseIndex: location.phraseIndex, measureIndex: index);
        MeasureNode? measureNode = findMeasureNodeByLocation(location);
        if (measureNode != null) {
          switch (measureNode.measureNodeType) {
            case MeasureNodeType.measure:
              return measureNode as Measure;
            default:
              break;
          }
        }
      }
    }
    return null;
  }

  MeasureNode? findMeasureNodeByGrid(GridCoordinate? coordinate) {
    MeasureNode? ret = findMeasureNodeByLocation(_getGridCoordinateChordSectionLocationMap()[coordinate]);
    return ret;
  }

  ChordSectionLocation? findChordSectionLocationByGrid(GridCoordinate? coordinate) {
    return _getGridCoordinateChordSectionLocationMap()[coordinate];
  }

  Phrase? _findPhraseByLocation(ChordSectionLocation chordSectionLocation) {
    ChordSection? chordSection = _getChordSectionMap()[chordSectionLocation.sectionVersion];
    return chordSection?.getPhrase(chordSectionLocation.phraseIndex);
  }

  MeasureNode? findMeasureNodeByLocation(ChordSectionLocation? chordSectionLocation) {
    if (chordSectionLocation == null) {
      return null;
    }
    //
    ChordSection? chordSection = _getChordSectionMap()[chordSectionLocation.sectionVersion];
    if (chordSection == null) {
      return null;
    }
    if (chordSectionLocation.isSection) {
      return chordSection;
    }

    try {
      Phrase? phrase = chordSection.getPhrase(chordSectionLocation.phraseIndex);
      if (chordSectionLocation.isPhrase) {
        switch (chordSectionLocation.marker) {
          case ChordSectionLocationMarker.none:
            return phrase;
          default:
            return MeasureRepeatExtension.get(chordSectionLocation.marker);
        }
      }

      return phrase?.getMeasure(chordSectionLocation.measureIndex);
    } catch (rangeError) {
      return null;
    }
  }

  MeasureNode? getCurrentMeasureNode() {
    return findMeasureNodeByLocation(currentChordSectionLocation);
  }

  ChordSection? findChordSectionByString(String s) {
    SectionVersion sectionVersion = SectionVersion.parseString(s);
    return _getChordSectionMap()[sectionVersion];
  }

  ChordSection? findChordSectionByMarkedString(MarkedString markedString) {
    SectionVersion sectionVersion = SectionVersion.parse(markedString);
    return _getChordSectionMap()[sectionVersion];
  }

  bool chordSectionLocationDelete(ChordSectionLocation chordSectionLocation) {
    try {
      ChordSection? chordSection = getChordSection(chordSectionLocation.sectionVersion);
      if (chordSection != null &&
          chordSection.deleteMeasure(chordSectionLocation.phraseIndex, chordSectionLocation.measureIndex)) {
        _clearCachedValues();
        setCurrentChordSectionLocation(chordSectionLocation);
        return true;
      }
    } catch (e) {
      ;
    }
    return false;
  }

  bool chordSectionDelete(ChordSection? chordSection) {
    if (chordSection == null) {
      return false;
    }
    bool ret = _getChordSectionMap().remove(chordSection.sectionVersion) != null;

    return ret;
  }

  void guessTheKey() {
    //  fixme: key guess based on chords section or lyrics?
    key = Key.guessKey(findScaleChordsUsed().keys);
  }

  HashMap<ScaleChord, int> findScaleChordsUsed() {
    HashMap<ScaleChord, int> ret = HashMap();
    for (ChordSection chordSection in _getChordSectionMap().values) {
      for (Phrase msi in chordSection.phrases) {
        for (Measure m in msi.measures) {
          for (Chord chord in m.chords) {
            ScaleChord scaleChord = chord.scaleChord;
            int chordCount = ret[scaleChord] ?? 0;
            ret[scaleChord] = chordCount + 1;
          }
        }
      }
    }
    return ret;
  }

  void _parseLyrics() {
    if (!_isLyricsParseRequired) {
      return;
    }

    _lyricSections = _parseLyricSections(_rawLyrics);

    //  safety with lazy eval
    _clearCachedValues();
    _isLyricsParseRequired = false;
  }

  List<LyricSection> _parseLyricSections(final String lyrics, {bool strict = false}) {
    int state = 0;
    StringBuffer lyricsBuffer = StringBuffer();
    LyricSection? lyricSection;

    List<LyricSection> lyricSections = [];

    MarkedString markedString = MarkedString(lyrics);

    //  strip initial blank lines
    markedString.stripLeadingWhitespace();

    while (markedString.isNotEmpty) {
      String c = markedString.charAt(0);

      if (c == '\r') {
        markedString.consume(1);
        continue;
      }

      //  absorb leading white space, but allow for blank lines
      if (state == 0) {
        if (!(c == ' ' || c == '\t')) {
          state = 1;
        }
      }

      //  note that fall through is possible
      if (state == 1) {
        try {
          //  try to find the section version marker
          markedString.mark();
          SectionVersion sectionVersion = SectionVersion.parse(markedString);

          //  finish any lyric section now that we have a new section version to parse
          if (lyricSection != null) {
            lyricSection.stripLastEmptyLyricLine();
            lyricSections.add(lyricSection);
          }

          var chordSection = findChordSectionBySectionVersion(sectionVersion);
          if (chordSection == null && strict) {
            markedString.resetToMark();
            throw LyricParseException('Section version not found', markedString);
          }

          lyricSection = LyricSection(sectionVersion, lyricSections.length);

          markedString.stripLeadingSpaces();

          //  consume newline if it's the only thing on the line after the section declaration
          if (markedString.charAt(0) == '\n') {
            markedString.consume(1);
          }
          state = 1; //  collect leading white space on first line
          continue;
        } on String catch (e) {
          e.length; //  used only to avoid a dart analysis complaint
          logger.v('not section: ${markedString.remainingStringLimited(25)}');
          //  ignore, this is typical of lyrics lines
        } catch (e) {
          if (strict) {
            //  rethrow the parse exception
            rethrow;
          }
        }
        state = 2;
      }

      //  note that a fall through is possible from above
      if (state == 2) {
        //  absorb all characters to a newline
        switch (c) {
          case '\n':
          case '\r':
            //  insert verse if missing the section declaration
            lyricSection ??= LyricSection(Section.getDefaultVersion(), lyricSections.length);

            //  add the lyrics
            if (lyricsBuffer.isNotEmpty) {
              lyricSection.addLine(lyricsBuffer.toString());
            } else {
              //  or a missing newline
              lyricSection.addLine('\n');
            }

            lyricsBuffer = StringBuffer();
            state = 0;
            break;
          default:
            if (strict && lyricSection == null) {
              //  if strict, we must have a section prior to non-white characters
              throw LyricParseException('Lyrics prior to section version', markedString);
            }
            lyricsBuffer.write(c);
            break;
        }
      }

      if (state < 0 || state > 2) {
        throw 'fsm broken at state: ' + state.toString();
      }

      markedString.consume(1);
    }

    //  the last one is not terminated by another section
    if (lyricSection != null) {
      if (lyricsBuffer.isNotEmpty) {
        lyricSection.addLine(lyricsBuffer.toString());
      }
      lyricSection.stripLastEmptyLyricLine();
      lyricSections.add(lyricSection);
    }

    return lyricSections;
  }

  /// Debug only!  a string form of the song chord section grid
  String logGrid() {
    StringBuffer sb = StringBuffer('\n');

    // getChordSectionGrid(); //  use location grid to force them all in lazy eval
    //  avoid ConcurrentModificationException
    for (int r = 0; r < getChordSectionGrid().getRowCount(); r++) {
      List<ChordSectionGridData?>? row = chordSectionGrid.getRow(r);
      if (row == null) {
        continue;
      }
      for (int c = 0; c < row.length; c++) {
        ChordSectionGridData? data = row[c];
        if (data == null) {
          continue;
        }
        sb.write('(');
        sb.write(r);
        sb.write(',');
        sb.write(c);
        sb.write(') ');
        sb.write(data.isMeasure ? '        ' : (data.isPhrase ? '    ' : ''));
        sb.write(data.toString());
        sb.write('  ');
        sb.write(findMeasureNodeByLocation(data.chordSectionLocation)?.toMarkup());
        sb.write('\n');
      }
    }
    return sb.toString();
  }

  void setRepeat(ChordSectionLocation chordSectionLocation, int repeats) {
    //  find the node at the location
    MeasureNode? measureNode = findMeasureNodeByLocation(chordSectionLocation);
    if (measureNode == null) {
      logger.d('null measureNode at: $chordSectionLocation');
      return;
    }
    logger.d('setRepeat: $chordSectionLocation $measureNode'
        ', current: ${currentChordSectionLocation == null ? 'null' : chordSectionLocation.compareTo(currentChordSectionLocation!)}');

    //  find if it's a phrase
    Phrase? phrase;
    if (measureNode is Measure) {
      phrase = _findPhraseByLocation(chordSectionLocation);
      if (phrase == null) {
        assert(false);
        return;
      }
    } else if (measureNode is Phrase) {
      phrase = measureNode;
    } else {
      assert(false);
      return;
    }

    if (phrase is MeasureRepeat) {
      var measureRepeat = phrase;
      if (repeats <= 1) {
        //  remove the repeat
        ChordSection? chordSection = findChordSectionBySectionVersion(chordSectionLocation.sectionVersion);
        if (chordSection != null) {
          List<Phrase> phrases = chordSection.phrases;
          if (phrases.isNotEmpty) {
            int phraseIndex = phrases.indexOf(measureRepeat);
            assert(phraseIndex >= 0);
            phrases.removeAt(phraseIndex);
            phrases.insert(phraseIndex, Phrase(measureRepeat.measures, phraseIndex));

            chordSectionDelete(chordSection);
            chordSection = ChordSection(chordSection.sectionVersion, phrases);
            {
              //  set the current chord section location to the last of the old repeat
              var measureIndex = measureRepeat.length - 1;
              if (phraseIndex > 0) {
                var priorPhrase = phrases[phraseIndex - 1];
                if (priorPhrase.runtimeType == Phrase) {
                  //  adjust for the collapse of adjacent phrases
                  phraseIndex--;
                  measureIndex += priorPhrase.length;
                }
              }
              currentChordSectionLocation = ChordSectionLocation(chordSection.sectionVersion,
                  phraseIndex: phraseIndex, measureIndex: measureIndex);
            }
            chordSection.collapsePhrases();

            _getChordSectionMap()[chordSection.sectionVersion] = chordSection;
            _invalidateChords();
          }
        }
      } else {
        //  change the count
        measureRepeat.repeats = repeats;
      }
    } else if (repeats > 1) {
      //  change phrase row to into a repeat

      //  find first and last measures in the row
      List<Phrase> newPhrases = [];
      var phraseIndex = phrase.phraseIndex;
      var repeatPhraseIndex = phraseIndex;
      if (chordSectionLocation.hasMeasureIndex) {
        //  find the current row
        var measureIndex = chordSectionLocation.measureIndex;
        var first = measureIndex;
        for (int i = first - 1; i >= 0; i--) {
          var m = phrase.measureAt(i);
          if (m?.endOfRow ?? true) {
            break;
          }
          first = i;
        }
        var last = phrase.length; //  if not end of row at last
        for (int i = measureIndex; i < phrase.length; i++) {
          var m = phrase.measureAt(i);
          if (m?.endOfRow ?? true) {
            last = i + 1;
            break;
          }
        }

        //  add rows prior to current row
        Phrase? firstPhrase;
        if (first > 0) {
          List<Measure> target = [];
          for (var i = 0; i < first; i++) {
            target.add(phrase.measures[i]);
          }
          firstPhrase = Phrase(target, phraseIndex++);
          newPhrases.add(firstPhrase);
        }
        //  add the current row as a repeat
        MeasureRepeat? measureRepeat;
        {
          List<Measure> target = [];
          for (var i = first; i < last; i++) {
            target.add(phrase.measures[i]);
          }
          if (target.isNotEmpty) {
            target[target.length - 1] = target[target.length - 1].deepCopy()..endOfRow = false;
          }
          repeatPhraseIndex = phraseIndex;
          measureRepeat = MeasureRepeat(target, phraseIndex++, repeats);
          newPhrases.add(measureRepeat);
        }
        //  add the rows past the current row
        Phrase? lastPhrase;
        if (last < phrase.length) {
          List<Measure> target = [];
          for (var i = last; i < phrase.length; i++) {
            target.add(phrase.measures[i]);
          }
          lastPhrase = Phrase(target, phraseIndex++);
          newPhrases.add(lastPhrase);
        }
        logger.d('firstPhrase: $firstPhrase, measureRepeat: $measureRepeat, last: $lastPhrase');

        //  adjust the current measure if required
        currentChordSectionLocation = ChordSectionLocation(chordSectionLocation.sectionVersion,
            phraseIndex: repeatPhraseIndex, measureIndex: measureRepeat.length - 1);
      } else {
        //  make a repeat of the whole phrase
        newPhrases.add(MeasureRepeat(phrase.measures, phrase.phraseIndex, repeats));
        //  current location remains the same
      }

      ChordSection? chordSection = findChordSectionBySectionVersion(chordSectionLocation.sectionVersion);
      if (chordSection != null) {
        //  deep copy
        List<Phrase> phrases = List.generate(chordSection.phrases.length, (index) {
          return chordSection!.phrases[index].deepCopy();
        });
        if (phrases.isNotEmpty) {
          int? i = phrases.indexOf(phrase);
          phrases.removeAt(i);
          phrases.insertAll(i, newPhrases);

          chordSectionDelete(chordSection);
          chordSection = ChordSection(chordSection.sectionVersion, phrases);
          logger.d('new chordSection: $chordSection');
          _getChordSectionMap()[chordSection.sectionVersion] = chordSection;
          logger.d(
              'new sectionVersion: ${chordSection.sectionVersion}: ${_getChordSectionMap()[chordSection.sectionVersion]}');
        }
      }
    } else {
      //  nothing to do.  repeats x1 is a phrase
    }

    _invalidateChords();
  }

  /// Set the number of measures displayed per row
  bool setMeasuresPerRow(int measuresPerRow) {
    if (measuresPerRow <= 0) {
      return false;
    }

    bool ret = false;
    SplayTreeSet<ChordSection> set = SplayTreeSet.of(_getChordSectionMap().values);
    for (ChordSection chordSection in set) {
      ret = chordSection.setMeasuresPerRow(measuresPerRow) || ret;
    }
    if (ret) {
      _invalidateChords();
    }
    return ret;
  }

  /// Checks a song for completeness.
  Song checkSong() {
    return checkSongBase(getTitle(), getArtist(), getCopyright(), getKey(), getDefaultBpm().toString(),
        getBeatsPerBar().toString(), getUnitsPerMeasure().toString(), getUser(), toMarkup(), rawLyrics);
  }

  /// Validate a song entry argument set
/*
   * @param title                the song's title
   * @param artist               the artist associated with this song or at least this song version
   * @param copyright            the copyright notice associated with the song
   * @param key                  the song's musical key
   * @param bpmEntry             the song's number of beats per minute
   * @param beatsPerBarEntry     the song's default number of beats per par
   * @param user                 the app user's name
   * @param unitsPerMeasureEntry the inverse of the note duration fraction per entry, for example if each beat is
   *                             represented by a quarter note, the units per measure would be 4.
   * @param chordsTextEntry      the string transport form of the song's chord sequence description
   * @param lyricsTextEntry      the string transport form of the song's section sequence and lyrics
   * @return a new song if the fields are valid
   * @throws ParseException exception thrown if the song's fields don't match properly.
   */
  static Song checkSongBase(
      String? title,
      String? artist,
      String? copyright,
      Key? key,
      String? bpmEntry,
      String? beatsPerBarEntry,
      String? unitsPerMeasureEntry,
      String user,
      String? chordsTextEntry,
      String? lyricsTextEntry) {
    if (title == null || title.isEmpty) {
      throw 'no song title given!';
    }

    if (artist == null || artist.isEmpty) {
      throw 'no artist given!';
    }

    if (copyright == null || copyright.isEmpty) {
      throw 'no copyright given!';
    }

    key ??= Key.C; //  punt on an error

    if (bpmEntry == null || bpmEntry.isEmpty) {
      throw 'no BPM given!';
    }

    //  check bpm
    RegExp twoOrThreeDigitsRegexp = RegExp('^\\d{2,3}\$');
    if (!twoOrThreeDigitsRegexp.hasMatch(bpmEntry)) {
      throw 'BPM has to be a number from ' +
          MusicConstants.minBpm.toString() +
          ' to ' +
          MusicConstants.maxBpm.toString();
    }
    int bpm = int.parse(bpmEntry);
    if (bpm < MusicConstants.minBpm || bpm > MusicConstants.maxBpm) {
      throw 'BPM has to be a number from ' +
          MusicConstants.minBpm.toString() +
          ' to ' +
          MusicConstants.maxBpm.toString();
    }

//  check beats per bar
    if (beatsPerBarEntry == null || beatsPerBarEntry.isEmpty) {
      throw 'no beats per bar given!';
    }
    RegExp oneOrTwoDigitRegexp = RegExp('^\\d{1,2}\$');
    if (!oneOrTwoDigitRegexp.hasMatch(beatsPerBarEntry)) {
      throw 'Beats per bar has to be 2, 3, 4, 6, or 12';
    }
    int beatsPerBar = int.parse(beatsPerBarEntry);
    switch (beatsPerBar) {
      case 2:
      case 3:
      case 4:
      case 6:
      case 12:
        break;
      default:
        throw 'Beats per bar has to be 2, 3, 4, 6, or 12';
    }

    if (chordsTextEntry == null || chordsTextEntry.isEmpty) {
      throw 'no chords given!';
    }
    if (lyricsTextEntry == null || lyricsTextEntry.isEmpty) {
      throw 'no lyrics given!';
    }

    if (unitsPerMeasureEntry == null || unitsPerMeasureEntry.isEmpty) {
      throw 'No units per measure given!';
    }
    if (!oneOrTwoDigitRegexp.hasMatch(unitsPerMeasureEntry)) {
      throw 'Units per measure has to be 2, 4, or 8';
    }
    int unitsPerMeasure = int.parse(unitsPerMeasureEntry);
    switch (unitsPerMeasure) {
      case 2:
      case 4:
      case 8:
        break;
      default:
        throw 'Units per measure has to be 2, 4, or 8';
    }

    if (user.isEmpty || user == Song.unknownUser) {
      throw 'Please enter your user name.';
    }

    Song newSong = Song.createSong(
        title, artist, copyright, key, bpm, beatsPerBar, unitsPerMeasure, user, chordsTextEntry, lyricsTextEntry);

    if (newSong.getChordSections().isEmpty) {
      throw 'The song has no chord sections! ';
    }

    for (ChordSection chordSection in newSong.getChordSections()) {
      if (chordSection.isEmpty) {
        throw 'Chord section ' + chordSection.sectionVersion.toString() + ' is empty.';
      }
    }

//  see that all chord sections have a lyric section
    for (ChordSection chordSection in newSong.getChordSections()) {
      SectionVersion chordSectionVersion = chordSection.sectionVersion;
      bool found = false;
      for (LyricSection lyricSection in newSong.lyricSections) {
        if (chordSectionVersion == lyricSection.sectionVersion) {
          found = true;
          break;
        }
      }
      if (!found) {
        throw 'no use found for the declared chord section ' + chordSectionVersion.toString();
      }
    }

//  see that all lyric sections have a chord section
    for (LyricSection lyricSection in newSong.lyricSections) {
      SectionVersion lyricSectionVersion = lyricSection.sectionVersion;
      bool found = false;
      for (ChordSection chordSection in newSong.getChordSections()) {
        if (lyricSectionVersion == chordSection.sectionVersion) {
          found = true;
          break;
        }
      }
      if (!found) {
        throw 'no chords found for the lyric section ' + lyricSectionVersion.toString();
      }
    }

    if (newSong.message == null) {
      for (ChordSection chordSection in newSong.getChordSections()) {
        for (Phrase phrase in chordSection.phrases) {
          for (Measure measure in phrase.measures) {
            if (measure.isComment()) {
              throw 'chords should not have comments: see ' + chordSection.toString();
            }
          }
        }
      }
    }

    newSong.message = null;

    if (newSong.message == null) {
      //  an early song with default (no) structure?
      if (newSong.lyricSections.isNotEmpty &&
          newSong.lyricSections.length == 1 &&
          newSong.lyricSections[0].sectionVersion == Section.getDefaultVersion()) {
        newSong.message = 'song looks too simple, is there really no structure?';
      }
    }

    return newSong;
  }

  static List<StringTriple> diff(SongBase a, SongBase b) {
    List<StringTriple> ret = [];

    if (a.getTitle().compareTo(b.getTitle()) != 0) {
      ret.add(StringTriple('title:', a.getTitle(), b.getTitle()));
    }

    if (a.getArtist().compareTo(b.getArtist()) != 0) {
      ret.add(StringTriple('artist:', a.getArtist(), b.getArtist()));
    }
    {
      var aCoverArtist = a.coverArtist;
      var bCoverArtist = b.coverArtist;
      if (aCoverArtist.compareTo(bCoverArtist) != 0 && aCoverArtist.isNotEmpty) {
        ret.add(StringTriple('cover:', aCoverArtist, bCoverArtist));
      }
    }
    if (a.getCopyright().compareTo(b.getCopyright()) != 0) {
      ret.add(StringTriple('copyright:', a.getCopyright(), b.getCopyright()));
    }
    if (a.getKey().compareTo(b.getKey()) != 0) {
      ret.add(StringTriple('key:', a.getKey().toString(), b.getKey().toString()));
    }
    if (a.beatsPerMinute != b.beatsPerMinute) {
      ret.add(StringTriple('BPM:', a.beatsPerMinute.toString(), b.beatsPerMinute.toString()));
    }
    if (a.getBeatsPerBar() != b.getBeatsPerBar()) {
      ret.add(StringTriple('per bar:', a.getBeatsPerBar().toString(), b.getBeatsPerBar().toString()));
    }
    if (a.getUnitsPerMeasure() != b.getUnitsPerMeasure()) {
      ret.add(StringTriple('units/measure:', a.getUnitsPerMeasure().toString(), b.getUnitsPerMeasure().toString()));
    }

//  chords
    for (ChordSection aChordSection in a.getChordSections()) {
      ChordSection? bChordSection = b.getChordSection(aChordSection.sectionVersion);
      if (bChordSection == null) {
        ret.add(StringTriple('chords missing:', aChordSection.toMarkup(), ''));
      } else if (aChordSection.compareTo(bChordSection) != 0) {
        ret.add(StringTriple('chords:', aChordSection.toMarkup(), bChordSection.toMarkup()));
      }
    }
    for (ChordSection bChordSection in b.getChordSections()) {
      ChordSection? aChordSection = a.getChordSection(bChordSection.sectionVersion);
      if (aChordSection == null) {
        ret.add(StringTriple('chords missing:', '', bChordSection.toMarkup()));
      }
    }

//  lyrics
    {
      int limit = min(a.lyricSections.length, b.lyricSections.length);
      for (int i = 0; i < limit; i++) {
        LyricSection aLyricSection = a.lyricSections[i];
        SectionVersion sectionVersion = aLyricSection.sectionVersion;
        LyricSection bLyricSection = b.lyricSections[i];
        int lineLimit = min(aLyricSection.lyricsLines.length, bLyricSection.lyricsLines.length);
        for (int j = 0; j < lineLimit; j++) {
          String aLine = aLyricSection.lyricsLines[j];
          String bLine = bLyricSection.lyricsLines[j];
          if (aLine.compareTo(bLine) != 0) {
            ret.add(StringTriple('lyrics ' + sectionVersion.toString(), aLine, bLine));
          }
        }
        lineLimit = aLyricSection.lyricsLines.length;
        for (int j = bLyricSection.lyricsLines.length; j < lineLimit; j++) {
          String aLine = aLyricSection.lyricsLines[j];
          ret.add(StringTriple('lyrics missing ' + sectionVersion.toString(), aLine, ''));
        }
        lineLimit = bLyricSection.lyricsLines.length;
        for (int j = aLyricSection.lyricsLines.length; j < lineLimit; j++) {
          String bLine = bLyricSection.lyricsLines[j];
          ret.add(StringTriple('lyrics missing ' + sectionVersion.toString(), '', bLine));
        }
      }
    }

    return ret;
  }

  bool hasSectionVersion(Section section, int version) {
    for (SectionVersion sectionVersion in _getChordSectionMap().keys) {
      if (sectionVersion.section == section && sectionVersion.version == version) {
        return true;
      }
    }
    return false;
  }

  /// Sets the song's title and song id from the given title. Leading "The " articles are rotated to the title end.
  String _theToTheEnd(String s) {
    if (s.length <= 4) {
      return s;
    }

    //  move the leading "The " to the end
    RegExpMatch? m = theRegExp.firstMatch(s);
    if (m != null) {
      s = m.group(2)! + ', ' + m.group(1)!;
      s = s.trim();
    }
    return s;
  }

  void computeSongIdFromSongData() {
    _songId = SongId.computeSongId(title, artist, coverArtist);
  }

  double getDefaultTimePerBar() {
    if (beatsPerMinute == 0) {
      return 1;
    }
    return timeSignature.beatsPerBar * 60.0 / beatsPerMinute;
  }

  double getSecondsPerBeat() {
    if (beatsPerMinute == 0) {
      return 1;
    }
    return 60.0 / beatsPerMinute;
  }

  /// Set the song default beats per minute.
  void setBeatsPerMinute(int bpm) {
    if (bpm < 20) {
      bpm = 20;
    } else if (bpm > 1000) {
      bpm = 1000;
    }
    beatsPerMinute = bpm;
    _duration = null;
  }

  /// Return the song's number of beats per bar
  int getBeatsPerBar() {
    return timeSignature.beatsPerBar;
  }

  /// Return an integer that represents the number of notes per measure
  /// represented in the sheet music.  Typically this is 4; meaning quarter notes.
  int getUnitsPerMeasure() {
    return timeSignature.unitsPerMeasure;
  }

  /// Return the song's copyright
  String getCopyright() {
    return copyright;
  }

  /// Return the song's key
  Key getKey() {
    return key;
  }

  /// Return the song's identification string largely consisting of the title and artist name.
  String getSongId() {
    return _songId.songId;
  }

  /// Return the song's title
  String getTitle() {
    return title;
  }

  /// Return the song's artist.
  String getArtist() {
    return artist;
  }

  /// Return the default beats per minute.
  int getDefaultBpm() {
    return beatsPerMinute;
  }

  Iterable<ChordSection> getChordSections() {
    return _getChordSectionMap().values;
  }

  String? getFileName() {
    return fileName;
  }

  void setFileName(String? fileName) {
    this.fileName = fileName;
    if (fileName == null) {
      return;
    }

    RegExp fileVersionRegExp = RegExp(r' \(([0-9]+)\).songlyrics$');
    RegExpMatch? mr = fileVersionRegExp.firstMatch(fileName);
    if (mr != null) {
      fileVersionNumber = int.parse(mr.group(1)!);
    } else {
      fileVersionNumber = 0;
    }
    //logger.info("setFileName(): "+fileVersionNumber);
  }

  int getTotalBeats() {
    computeDuration();
    return totalBeats;
  }

  int getSongMomentsSize() {
    return getSongMoments().length;
  }

  List<SongMoment> getSongMoments() {
    songMomentGrid; //  fixme: shouldn't have to compute grid just to get the lyrics on the moments!!!!!
    //_computeSongMoments();
    return _songMoments;
  }

  SongMoment? getSongMoment(int momentNumber) {
    _computeSongMoments();
    if (_songMoments.isEmpty || momentNumber < 0 || momentNumber >= _songMoments.length) {
      return null;
    }
    return _songMoments[momentNumber];
  }

  SongMoment? getFirstSongMomentInSection(int momentNumber) {
    SongMoment? songMoment = getSongMoment(momentNumber);
    if (songMoment == null) {
      return null;
    }

    SongMoment firstSongMoment = songMoment;
    String id = songMoment.getChordSection().getId();
    for (int m = momentNumber - 1; m >= 0; m--) {
      SongMoment sm = _songMoments[m];
      if (id != sm.getChordSection().getId() || sm.getSectionCount() != firstSongMoment.getSectionCount()) {
        return firstSongMoment;
      }
      firstSongMoment = sm;
    }
    return firstSongMoment;
  }

  SongMoment? getLastSongMomentInSection(int momentNumber) {
    SongMoment? songMoment = getSongMoment(momentNumber);
    if (songMoment == null) {
      return null;
    }

    SongMoment lastSongMoment = songMoment;
    String id = songMoment.getChordSection().getId();
    int limit = _songMoments.length;
    for (int m = momentNumber + 1; m < limit; m++) {
      SongMoment sm = _songMoments[m];
      if (id != sm.getChordSection().getId() || sm.getSectionCount() != lastSongMoment.getSectionCount()) {
        return lastSongMoment;
      }
      lastSongMoment = sm;
    }
    return lastSongMoment;
  }

  double getSongTimeAtMoment(int momentNumber) {
    SongMoment? songMoment = getSongMoment(momentNumber);
    if (songMoment == null) {
      return 0;
    }
    return songMoment.getBeatNumber() * 60.0 / beatsPerMinute;
  }

  static int? getBeatNumberAtTime(int bpm, double songTime) {
    if (bpm <= 0) {
      return null; //  we're done with this song play
    }

    int songBeat = (songTime * bpm / 60.0).floor();
    return songBeat;
  }

  /// determine the song's current moment given the time from the beginning to the current time
  int? getSongMomentNumberAtSongTime(double songTime) {
    if (beatsPerMinute <= 0) {
      return null;
    } //  we're done with this song play

    int? songBeat = getBeatNumberAtTime(beatsPerMinute, songTime);
    if (songBeat == null) {
      return null;
    }
    if (songBeat < 0) {
      return (songBeat - timeSignature.beatsPerBar + 1) ~/ timeSignature.beatsPerBar; //  constant measure based lead in
    }

    _computeSongMoments();
    if (songBeat >= _beatsToMoment.length) {
      return null;
    } //  we're done with the last measure of this song play

    return _beatsToMoment[songBeat]?.getMomentNumber();
  }

  /// Return the first moment on the given row
  SongMoment? getFirstSongMomentAtRow(int rowIndex) {
    if (rowIndex < 0) {
      return null;
    }
    _computeSongMoments();
    for (SongMoment songMoment in _songMoments) {
      //  return the first moment on this row
      if (rowIndex == getMomentGridCoordinate(songMoment)?.row) {
        return songMoment;
      }
    }
    return null;
  }

  ///  maximum number of measures in any chord row
  int chordRowMaxLength() {
    var ret = 0;
    for (var chordSection in getChordSections()) {
      ret = max(ret, chordSection.chordRowMaxLength());
    }
    return ret;
  }

  int rowBeats(int rowIndex) {
    int ret = 0;
    SongMoment? songMoment = getFirstSongMomentAtRow(rowIndex);
    if (songMoment != null) {
      for (int i = songMoment.getMomentNumber(); i < _songMoments.length; i++) {
        try {
          songMoment = _songMoments[i];
          if (songMoment.row != rowIndex) {
            break;
          }
          ret += songMoment.measure.beatCount;
        } catch (e) {
          continue;
        }
      }
    }
    return ret;
  }

  int getFileVersionNumber() {
    return fileVersionNumber;
  }

  int getChordSectionBeatsFromLocation(ChordSectionLocation? chordSectionLocation) {
    if (chordSectionLocation == null) {
      return 0;
    }
    return getChordSectionBeats(chordSectionLocation.sectionVersion);
  }

  int getChordSectionBeats(SectionVersion? sectionVersion) {
    if (sectionVersion == null) {
      return 0;
    }
    _computeSongMoments();
    int? ret = _chordSectionBeats[sectionVersion];
    if (ret == null) {
      return 0;
    }
    return ret;
  }

  ///Compute a relative complexity index for the song
  int getComplexity() {
    if (_complexity == 0) {
      //  compute the complexity
      SplayTreeSet<Measure> differentChords = SplayTreeSet();
      for (ChordSection chordSection in _getChordSectionMap().values) {
        for (Phrase phrase in chordSection.phrases) {
          //  the more different measures, the greater the complexity
          differentChords.addAll(phrase.measures);

          //  weight measures by guitar complexity
          for (Measure measure in phrase.measures) {
            if (!measure.isEasyGuitarMeasure()) {
              _complexity++;
            }
          }
        }
      }
      _complexity += _getChordSectionMap().values.length;
      _complexity += differentChords.length;
    }
    return _complexity;
  }

  /// Copyright year
  int getCopyrightYear() {
    if (_copyrightYear == null) {
      //  find the year
      RegExpMatch? m = _yearRegexp.firstMatch(_copyright);
      _copyrightYear = int.parse(m?.group(1) ?? _defaultYear.toString());
    }
    return _copyrightYear!;
  }

  String getCopyrightYearAsString() {
    return getCopyrightYear() == _defaultYear ? '' : _copyrightYear.toString();
  }

  static int get defaultYear => _defaultYear;
  static const int _defaultYear = 3000;
  static final RegExp _yearRegexp = RegExp(r'(?:\D|^)(\d{4})(?:\D|$)');

  void setChords(String chords) {
    _clearCachedValues();
    _chords = chords;
    _chordSectionMap = HashMap(); //  clear chord sections, will be parsed when required
  }

  void setTotalBeats(int totalBeats) {
    this.totalBeats = totalBeats;
  }

  void setCurrentMeasureEditType(MeasureEditType measureEditType) {
    currentMeasureEditType = measureEditType;
    logger.d('set edit type: ' +
        currentMeasureEditType.toString() +
        ' at ' +
        (currentChordSectionLocation != null ? currentChordSectionLocation.toString() : 'none'));
  }

  ChordSectionLocation? getCurrentChordSectionLocation() {
    //  insist on something non-null
    if (currentChordSectionLocation == null) {
      if (_getChordSectionMap().keys.isEmpty) {
        currentChordSectionLocation = ChordSectionLocation(SectionVersion.defaultInstance);
      } else {
        //  last location
        SplayTreeSet<SectionVersion> sectionVersions = SplayTreeSet.of(_getChordSectionMap().keys);
        ChordSection? lastChordSection = _getChordSectionMap()[sectionVersions.last];
        if (lastChordSection != null) {
          if (lastChordSection.isEmpty) {
            currentChordSectionLocation = ChordSectionLocation(lastChordSection.sectionVersion);
          } else {
            Phrase? phrase = lastChordSection.lastPhrase();
            if (phrase != null) {
              if (phrase.isEmpty) {
                currentChordSectionLocation =
                    ChordSectionLocation(lastChordSection.sectionVersion, phraseIndex: phrase.phraseIndex);
              } else {
                currentChordSectionLocation = ChordSectionLocation(lastChordSection.sectionVersion,
                    phraseIndex: phrase.phraseIndex, measureIndex: phrase.measures.length - 1);
              }
            }
          }
        }
      }
    }
    return currentChordSectionLocation;
  }

  MeasureNode? getCurrentChordSectionLocationMeasureNode() {
    return currentChordSectionLocation == null ? null : findMeasureNodeByLocation(currentChordSectionLocation);
  }

  void setCurrentChordSectionLocation(ChordSectionLocation? chordSectionLocation) {
    //  try to find something close if the exact location doesn't exist
    if (chordSectionLocation == null) {
      chordSectionLocation = currentChordSectionLocation;
      chordSectionLocation ??= getLastChordSectionLocation();
    }
    if (chordSectionLocation != null) {
      try {
        ChordSection? chordSection = getChordSectionByLocation(chordSectionLocation);
        ChordSection? cs = chordSection;
        if (cs == null) {
          SplayTreeSet<SectionVersion> sortedSectionVersions =
              SplayTreeSet<SectionVersion>.of(_getChordSectionMap().keys);
          cs = _getChordSectionMap()[sortedSectionVersions.last];
        }
        if (cs != null && chordSectionLocation.hasPhraseIndex) {
          Phrase? phrase = cs.getPhrase(chordSectionLocation.phraseIndex);
          phrase ??= cs.getPhrase(cs.getPhraseCount() - 1); //  at least the last
          if (phrase != null) {
            int phraseIndex = phrase.phraseIndex; //  fixme: too much presumption here?
            if (chordSectionLocation.hasMeasureIndex) {
              int pi = (phraseIndex >= cs.getPhraseCount() ? cs.getPhraseCount() - 1 : phraseIndex);
              int measureIndex = chordSectionLocation.measureIndex;
              int mi = (measureIndex >= phrase.length || pi < chordSectionLocation.phraseIndex
                  ? phrase.length - 1
                  : measureIndex);
              if (cs != chordSection ||
                  pi != chordSectionLocation.phraseIndex ||
                  mi != chordSectionLocation.measureIndex) {
                chordSectionLocation = ChordSectionLocation(cs.sectionVersion, phraseIndex: pi, measureIndex: mi);
              }
            }
          }
        }
      } catch (e) {
        chordSectionLocation = null;
      }
    }

    currentChordSectionLocation = chordSectionLocation;
    logger.d('set loc: ' +
        (currentChordSectionLocation != null ? currentChordSectionLocation.toString() : 'none') +
        ', type: ' +
        currentMeasureEditType.toString() +
        ', song value: ' +
        (currentChordSectionLocation != null
            ? findMeasureNodeByLocation(currentChordSectionLocation).toString()
            : 'none'));
  }

  Grid<MeasureNode> toGrid({bool? expanded}) {
    var grid = Grid<MeasureNode>();

    //  find the required chord columns across all sections in the song
    var columns = 0;
    for (var lyricSection in lyricSections) {
      var chordSection = findChordSectionByLyricSection(lyricSection);
      assert(chordSection != null);
      if (chordSection == null) {
        continue;
      }
      columns = max(columns, chordSection.chordRowMaxLength());
    }

    //  add the lyric sections
    for (var lyricSection in lyricSections) {
      //  section by section

      //  get the chord section
      var chordSection = findChordSectionByLyricSection(lyricSection);
      assert(chordSection != null);
      if (chordSection == null) {
        continue;
      }

      //  convert to chord section grid
      var sectionGrid = chordSection.toGrid(chordColumns: columns, expanded: expanded);

      //  find the rows used by the chords
      var rows = sectionGrid.getRowCount() //
          -
          1; //  chord section version on title row without lyrics!

      //  get the lyrics spread properly across the chord row count
      var lyrics = lyricSection.asLyrics(rows);

      //  add the lyrics to the chord section grid as a final column
      assert(rows == lyrics.length);
      sectionGrid.set(0, columns, null); //  section version title row
      for (var i = 1; //  offset for section version title row without lyrics
          i <= rows;
          i++) {
        var lyric = lyrics[i - 1];
        sectionGrid.set(i, columns, lyric);
      }

      //  add the lyrics section grid to the song grid
      grid.add(sectionGrid);
    }

    return grid;
  }

  ///  map the grid to the song moments
  List<GridCoordinate> songMomentToGrid({bool expanded = false}) {
    List<GridCoordinate> list = [];
    logger.v('songMoments: $songMoments');

    var phraseBasisRow = 0;
    for (var lyricSection in lyricSections) {
      ChordSection? chordSection = findChordSectionByLyricSection(lyricSection);
      assert(chordSection != null);
      if (chordSection == null) {
        continue; //  safety
      }

      phraseBasisRow++; //  skip the section title row

      for (var phrase in chordSection.phrases) {
        int endOfRowCount = phrase.rowCount(); //  rows in one repetition
        for (var repetition = 0; repetition < phrase.repeats; repetition++) //  for possible measure repeats
        {
          var r = 0;
          var c = 0;
          for (var measureIndex = 0; measureIndex < phrase.length; measureIndex++) {
            var measure = phrase.measures[measureIndex];
            list.add(GridCoordinate(phraseBasisRow + r, c++));
            if (measure.endOfRow) {
              r++;
              c = 0;
            }
          }
          r++; //  supply the end of row for the last measure in the phrase
          if (expanded) {
            //  grid is showing every repetition so each one has a new basis
            phraseBasisRow += endOfRowCount;
          }
        }
        if (!expanded) {
          //  each phrase needs a new basis
          phraseBasisRow += endOfRowCount;
        }
      }
    }

    assert(songMoments.length == list.length);

    // //  debug
    // for (int i = 0; i < list.length; i++) {
    //   logger.i('${list[i]}: ${songMoments[i]}');
    // }

    return list;
  }

  //  preferred sections by order of priority
  final List<SectionVersion> _suggestedSectionVersions = [
    SectionVersion.bySection(Section.get(SectionEnum.verse)),
    SectionVersion.bySection(Section.get(SectionEnum.chorus)),
    SectionVersion.bySection(Section.get(SectionEnum.intro)),
    SectionVersion.bySection(Section.get(SectionEnum.bridge)),
    SectionVersion.bySection(Section.get(SectionEnum.outro)),
    SectionVersion.bySection(Section.get(SectionEnum.tag)),
    SectionVersion.bySection(Section.get(SectionEnum.a)),
    SectionVersion.bySection(Section.get(SectionEnum.b)),
  ];

  /// suggest a new chord section (that doesn't currently exist
  ChordSection suggestNewSection() {
    //  generate the set of the song's section versions
    SplayTreeSet<SectionVersion> songSectionVersions = SplayTreeSet();
    for (final ChordSection cs in getChordSections()) {
      songSectionVersions.add(cs.sectionVersion);
    }

    //  see if one of the suggested default section versions is missing
    for (final SectionVersion sv in _suggestedSectionVersions) {
      if (songSectionVersions.contains(sv)) {
        continue;
      }
      return ChordSection(sv, null);
    }

    //  see if one of the suggested numbered section versions is missing
    for (final SectionVersion sv in _suggestedSectionVersions) {
      for (int i = 1; i <= 9; i++) {
        SectionVersion svn = SectionVersion(sv.section, i);
        if (songSectionVersions.contains(svn)) {
          continue;
        }
        return ChordSection(svn, null);
      }
    }

    //  punt
    return ChordSection(SectionVersion(Section.get(SectionEnum.chorus), 0), null);
  }

  @override
  String toString() {
    return title +
        (fileVersionNumber > 0 ? ':(' + fileVersionNumber.toString() + ')' : '') +
        ' by ' +
        artist +
        (coverArtist.isNotEmpty ? ', cover by $coverArtist' : '');
  }

  static bool containsSongTitleAndArtist(Iterable<SongBase> iterable, SongBase song) {
    for (SongBase collectionSong in iterable) {
      if (song.compareBySongId(collectionSong) == 0) {
        return true;
      }
    }
    return false;
  }

  /// Compare only the title and artist.
  ///To be used for listing purposes only.
  int compareBySongId(SongBase o) {
    int ret = getSongId().compareTo(o.getSongId());
    if (ret != 0) {
      return ret;
    }
    return 0;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    return runtimeType == other.runtimeType && other is SongBase && songBaseSameAs(other);
  }

  bool songBaseSameContent(SongBase? o) {
    if (o == null) {
      return false;
    }
    if (title != o.title) {
      return false;
    }
    if (artist != o.artist) {
      return false;
    }
    if (coverArtist != o.coverArtist) {
      return false;
    }
    if (copyright != o.copyright) {
      return false;
    }
    if (key != o.key) {
      return false;
    }
    if (beatsPerMinute != o.beatsPerMinute) {
      return false;
    }
    if (timeSignature != o.timeSignature) {
      return false;
    }
    // if (user != o.user) {return false;}  //  different user not sufficient for a change of content
    if (_getChords() != o._getChords()) {
      return false;
    }
    if (_rawLyrics != (o._rawLyrics)) {
      return false;
    }

    //  notice that a modification date is not sufficient to declare a change in content.

    return true;
  }

  bool songBaseSameAs(SongBase o) {
    //  song id built from title with reduced whitespace
    if (!songBaseSameContent(o)) {
      return false;
    }

    //    if (metadata != (o.metadata)){
    //      return false;}

    //  song base is the same, no matter when last modified
    // if (lastModifiedTime != o.lastModifiedTime) {
    //   return false;
    // }

    //  hmm, think about these
    if (fileName != o.fileName) {
      return false;
    }
    if (fileVersionNumber != o.fileVersionNumber) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode {
    //  2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97
    int ret = hash4(title, artist, coverArtist, copyright);
    ret = ret * 17 + hash3(key.keyEnum, beatsPerMinute, timeSignature);
    ret = ret * 19 + hash4(_getChords(), _rawLyrics, fileName, fileVersionNumber);
    //  note:   _lastModifiedTime intentionally not included
    return ret;
  }

  //  primary values

  void setSongId(String title, String artist, String coverArtist) {
    _title = _theToTheEnd(title.trim());
    _artist = _theToTheEnd(artist.trim());
    _coverArtist = _theToTheEnd(coverArtist.trim());
    computeSongIdFromSongData();
  }

  String get title => _title;

  String get titleWithCover => _title + (coverArtist.isNotEmpty ? ', cover by $coverArtist' : '');

  set title(String s) {
    s = _theToTheEnd(s.trim());
    if (_title != s) {
      _title = s;
      computeSongIdFromSongData();
    }
  }

  String _title = '';

  String get artist => _artist;

  set artist(String s) {
    s = _theToTheEnd(s.trim());
    if (_artist != s) {
      _artist = s;
      computeSongIdFromSongData();
    }
  }

  String _artist = '';

  String get user => _user;

  set user(String s) {
    if (_user != s) {
      _user = s; //  fixme: this is currently meaningless
    }
  }

  String _user = defaultUser;

  String get coverArtist => _coverArtist;

  set coverArtist(String s) {
    s = _theToTheEnd(s); //  fixme: null or empty?
    if (_coverArtist != s) {
      _coverArtist = s;
      computeSongIdFromSongData();
    }
  }

  String _coverArtist = '';

  String get copyright => _copyright;

  set copyright(String s) {
    if (_copyright != s) {
      _copyright = s;
    }
  }

  String _copyright = 'Unknown';

  Key get key => _key;

  set key(Key k) {
    if (_key != k) {
      _key = k;
    }
  }

  Key _key = Key.C; //  default

  int get beatsPerMinute => _beatsPerMinute;

  set beatsPerMinute(int k) {
    k = max(MusicConstants.minBpm, min(MusicConstants.maxBpm, k));
    if (_beatsPerMinute != k) {
      _beatsPerMinute = k;
      //fixme: do something on beatsPerMinute change
    }
  }

  int _beatsPerMinute = MusicConstants.defaultBpm; //  beats per minute

  set timeSignature(TimeSignature timeSignature) {
    _timeSignature = timeSignature;
    _clearCachedValues();
  }

  TimeSignature get timeSignature => _timeSignature;

  TimeSignature _timeSignature = TimeSignature.defaultTimeSignature;

  /// should only be used for testing
  set lastModifiedTime(int t) {
    _lastModifiedTime = t;
  }

  void resetLastModifiedDateToNow() {
    _lastModifiedTime = DateTime.now().millisecondsSinceEpoch;
  }

  int get lastModifiedTime => _lastModifiedTime;
  int _lastModifiedTime = 0;

  //  chords as a string is only valid on input or output
  String _chords = '';

  //  normally the chords data is held in the chord section map
  HashMap<SectionVersion, ChordSection> _chordSectionMap = HashMap();

  set rawLyrics(String rawLyrics) {
    _rawLyrics = rawLyrics;
    _clearCachedValues();
  }

  String get rawLyrics => _rawLyrics;
  String _rawLyrics = '';

  //  deprecated values
  int fileVersionNumber = 0;

  //  meta data
  String? fileName;

  //  computed values
  SongId get songId => _songId;
  SongId _songId = SongId.noArgs();

  double get duration {
    computeDuration();
    return _duration!;
  }

  bool get isLyricsParseRequired => _isLyricsParseRequired;
  bool _isLyricsParseRequired = true;

  double? _duration; //  units of seconds
  int totalBeats = 0;

  List<LyricSection> get lyricSections {
    _parseLyrics();
    return _lyricSections;
  }

  String get lyricSectionsAsEntryString {
    _parseLyrics();
    var sb = StringBuffer();
    for (var lyricSection in _lyricSections) {
      sb.writeln(lyricSection.sectionVersion.toString());
      for (var line in lyricSection.lyricsLines) {
        sb.writeln(line);
      }
    }
    return sb.toString();
  }

  List<LyricSection> _lyricSections = [];
  HashMap<SectionVersion, GridCoordinate> _chordSectionGridCoordinateMap = HashMap();

  //  match to representative section version
  HashMap<SectionVersion, SectionVersion> _chordSectionGridMatches = HashMap();

  HashMap<GridCoordinate, ChordSectionLocation> _gridCoordinateChordSectionLocationMap = HashMap();
  HashMap<ChordSectionLocation, GridCoordinate> _gridChordSectionLocationCoordinateMap = HashMap();
  HashMap<SongMoment, GridCoordinate> _songMomentGridCoordinateHashMap = HashMap();
  Grid<SongMoment>? _songMomentGrid;

  HashMap<SectionVersion, int> _chordSectionBeats = HashMap();

  ChordSectionLocation? currentChordSectionLocation;
  MeasureEditType currentMeasureEditType = MeasureEditType.append;

  Grid<ChordSectionGridData> get chordSectionGrid => getChordSectionGrid();
  Grid<ChordSectionGridData>? _chordSectionGrid;

  int _complexity = 0;
  String? _chordsAsMarkup;
  int? _copyrightYear;

  String? get message => _message;

  set message(String? m) {
    _message = m;
  }

  String? _message;

  List<SongMoment> get songMoments => getSongMoments();
  List<SongMoment> _songMoments = [];
  HashMap<int, SongMoment> _beatsToMoment = HashMap();

  static final RegExp _spaceRegexp = RegExp(r'[ \t]');
  static final RegExp theRegExp = RegExp('^ *(the +)(.*)', caseSensitive: false);

  //SplayTreeSet<Metadata> metadata = new SplayTreeSet();
  static final String defaultUser = 'Unknown';
  static final bool _debugging = false; //  true false
}

@immutable
class LyricParseException {
  LyricParseException(this.message, this.markedString);

  final String message;
  final MarkedString markedString;
}
