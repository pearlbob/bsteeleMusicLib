import 'dart:collection';
import 'dart:core';
import 'dart:math';

import 'package:quiver/collection.dart';
import 'package:quiver/core.dart';

import '../grid.dart';
import '../gridCoordinate.dart';
import '../appLogger.dart';
import '../util/util.dart';
import 'chord.dart';
import 'chordDescriptor.dart';
import 'chordSection.dart';
import 'chordSectionLocation.dart';
import 'lyricSection.dart';
import 'measure.dart';
import 'measureComment.dart';
import 'measureNode.dart';
import 'measureRepeat.dart';
import 'measureRepeatExtension.dart';
import 'measureRepeatMarker.dart';
import 'musicConstants.dart';
import 'phrase.dart';
import 'section.dart';
import 'sectionVersion.dart';
import 'song.dart';
import 'songId.dart';
import 'songMoment.dart';
import 'key.dart';
import 'scaleChord.dart';

enum UpperCaseState {
  initial,
  flatIsPossible,
  comment,
  normal,
}

/// A piece of music to be played according to the structure it contains.
///  The song base class has been separated from the song class to allow most of the song
///  mechanics to be tested in the shared code environment where debugging is easier.

class SongBase {
  ///  Not to be used externally
  SongBase() {
    setTitle('');
    setArtist('');
    setCoverArtist(null);
    copyright = '';
    setKey(Key.get(KeyEnum.C));
    unitsPerMeasure = 4;
    setRawLyrics('');
    setChords('');
    setBeatsPerMinute(100);
    setBeatsPerBar(4);
  }

  /// A convenience constructor used to enforce the minimum requirements for a song.
  /// <p>Note that this is the base class for a song object.
  /// The split from Song was done for testability reasons.
  /// It's much easier to test free of GWT.
  static SongBase createSongBase(String title, String artist, String copyright, Key key, int bpm, int beatsPerBar,
      int unitsPerMeasure, String chords, String lyricsToParse) {
    SongBase song = SongBase();
    song.setTitle(title);
    song.setArtist(artist);
    song.setCopyright(copyright);
    song.setKey(key);
    song.setUnitsPerMeasure(unitsPerMeasure);
    song.setChords(chords);
    song.setRawLyrics(lyricsToParse);

    song.setBeatsPerMinute(bpm);
    song.setBeatsPerBar(beatsPerBar);

    return song;
  }

  /// Compute the song moments list given the song's current state.
  /// Moments are the temporal sequence of measures as the song is to be played.
  /// All repeats are expanded.  Measure node such as comments,
  /// repeat ends, repeat counts, section headers, etc. are ignored.
  void _computeSongMoments() {
    if (_songMoments != null && _songMoments.isNotEmpty) return;

    //  force the chord parse
    _getChordSectionMap();

    _songMoments = <SongMoment>[];
    beatsToMoment = HashMap<int, SongMoment>();

    if (_lyricSections == null) return;

    logger.d('_lyricSections size: ' + _lyricSections.length.toString());
    int sectionCount;
    HashMap<SectionVersion, int> sectionVersionCountMap = HashMap<SectionVersion, int>();
    chordSectionBeats = HashMap<SectionVersion, int>();
    int beatNumber = 0;
    for (LyricSection lyricSection in _lyricSections) {
      ChordSection chordSection = findChordSectionByLyricSection(lyricSection);
      if (chordSection == null) continue;

      //  compute section count
      SectionVersion sectionVersion = chordSection.sectionVersion;
      sectionCount = sectionVersionCountMap[sectionVersion];
      sectionCount ??= 0;
      sectionCount++;
      sectionVersionCountMap[sectionVersion] = sectionCount;

      List<Phrase> phrases = chordSection.phrases;
      if (phrases != null) {
        int phraseIndex = 0;
        int sectionVersionBeats = 0;
        for (Phrase phrase in phrases) {
          if (phrase.isRepeat()) {
            MeasureRepeat measureRepeat = phrase as MeasureRepeat;
            int limit = measureRepeat.repeats;
            for (int repeat = 0; repeat < limit; repeat++) {
              List<Measure> measures = measureRepeat.measures;
              if (measures != null) {
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
                      sectionCount));
                  measureIndex++;
                  beatNumber += measure.beatCount;
                  sectionVersionBeats += measure.beatCount;
                }
              }
            }
          } else {
            List<Measure> measures = phrase.measures;
            if (measures != null) {
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
                    sectionCount));
                measureIndex++;
                beatNumber += measure.beatCount;
                sectionVersionBeats += measure.beatCount;
              }
            }
          }
          phraseIndex++;
        }

        for (SectionVersion sv in matchingSectionVersions(sectionVersion)) {
          chordSectionBeats[sv] = sectionVersionBeats;
        }
      }
    }

    {
      //  Generate song moment grid coordinate map for play to display purposes.
      _songMomentGridCoordinateHashMap = HashMap<SongMoment, GridCoordinate>();

      int row = 0;
      GridCoordinate lastGridCoordinate;
      for (SongMoment songMoment in _songMoments) {
        //  increment the row based on the chord section change
        GridCoordinate gridCoordinate = getGridCoordinate(songMoment.getChordSectionLocation());
        if (lastGridCoordinate != null &&
            (gridCoordinate.row != lastGridCoordinate.row || gridCoordinate.col != lastGridCoordinate.col + 1)) {
          row++;
        }
        lastGridCoordinate = gridCoordinate;

        GridCoordinate momentGridCoordinate = GridCoordinate(row, gridCoordinate.col);
        logger.d(songMoment.toString() + ': ' + momentGridCoordinate.toString());
        songMoment.row = momentGridCoordinate.row; //  convenience later
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
          beatsToMoment[beat++] = songMoment;
        }
      }
    }
  }

  ///   Return a grid for the song moments in play order.
  ///   Note that the grid will only be filled with song moments.
  ///   Nulls will fill other grid positions intended for section versions
  ///   and filler to an even, minimum right grid boundary.
  Grid<SongMoment> get songMomentGrid {
    if (_songMomentGrid != null) return _songMomentGrid;

    _computeSongMoments();

    //  lazy eval
    _songMomentGrid = Grid();

    //  find the maximum number of cols in the rows
    int maxCol = 0;
    for (SongMoment songMoment in songMoments) {
      GridCoordinate momentGridCoordinate = getMomentGridCoordinate(songMoment);
      logger.v('add ${songMoment.toString()}  at (${momentGridCoordinate.row},${momentGridCoordinate.col})');
      _songMomentGrid.set(momentGridCoordinate.row, momentGridCoordinate.col, songMoment);
      maxCol = max(maxCol, momentGridCoordinate.col);
    }

    //  Fill the rows to a common maximum length,
    //  even if you have to fill with null.
    //  This is done in preparation of the flutter table.
    for (int row = 0; row < _songMomentGrid.getRowCount(); row++) {
      if (_songMomentGrid.getRow(row).length <= maxCol) _songMomentGrid.set(row, maxCol, null);
    }

    if (_lyricSections != null) {
      {
        if (_debugging) {
          int i = 0;
          for (LyricSection ls in _lyricSections) {
            logger.i('lyricSection $i: ${ls.toString()}');
            for (String lyricsLine in ls.lyricsLines) {
              logger.i('     $i: ${lyricsLine.toString()}');
              i++;
            }
          }
        }
        LyricSection lyricSection;
        int minimumLinesPerRow;
        int rows;
        int rowsOfExtraLines;
        int priorRow;
        int lineIndex = 0;
        int extraLine;
        String rowLyrics = '';
        for (int songMomentNumber = 0; songMomentNumber < songMoments.length; songMomentNumber++) {
          SongMoment songMoment = songMoments[songMomentNumber];

          //  Compute values for the next lyric section.
          if (songMoment.lyricSection != lyricSection) {
            lyricSection = songMoment.lyricSection;

            //  Find the number of lines in this section
            ChordSection chordSection = getChordSection(lyricSection.sectionVersion);
            int lines = lyricSection.lyricsLines.length;

            //  Find the number of rows in this chord section griding
            rows = chordSection.chordRowCount;
            if (rows == 0) continue;

            if (_debugging) {
              for (String lyricsLine in lyricSection.lyricsLines) {
                logger.i('\t$lyricSection:$lines lines/$rows: "$lyricsLine"');
              }
            }

            //  Distribute the lines over the rows.
            //  Extra lines go in earlier rows.
            minimumLinesPerRow = lines ~/ rows;
            rowsOfExtraLines = lines.remainder(rows);

            if (_debugging) {
              logger.i('${chordSection.sectionVersion.toString()} has $rows chord rows and $lines lines of lyrics'
                  ' = $minimumLinesPerRow per + $rowsOfExtraLines rows with extra line');
            }

            //  Generate the lyrics for the rows.
            extraLine = rowsOfExtraLines;
            lineIndex = 0;
          }

          //  Compute a new set of lyrics lines when required.
          GridCoordinate gridCoordinate = _songMomentGridCoordinateHashMap[songMoment];
          if (gridCoordinate == null) {
            throw 'null gridCoordinate at: ${songMoment.toString()}'; //  should not happen
          }
          if (gridCoordinate.row != priorRow) {
            priorRow = gridCoordinate.row;
            rowLyrics = '';
            if (lineIndex < lyricSection.lyricsLines.length) {
              for (int i = 0; i < minimumLinesPerRow; i++) {
                logger.v('min lyricsLines[$lineIndex]=${lyricSection.lyricsLines[lineIndex].toString()}');
                rowLyrics =
                    rowLyrics + (rowLyrics.isNotEmpty ? '\n' : '') + lyricSection.lyricsLines[lineIndex++].toString();
              }
              if (extraLine > 0) {
                logger.v('ext lyricsLines[$lineIndex]=${lyricSection.lyricsLines[lineIndex].toString()}');
                rowLyrics =
                    rowLyrics + (rowLyrics.isNotEmpty ? '\n' : '') + lyricSection.lyricsLines[lineIndex++].toString();
                extraLine--;
              }
            }
            if (_debugging) {
              logger.d('row ${gridCoordinate.row}:');
              logger.d('\t$rowLyrics');
            }
          }

          //  Note that every moment in the row gets the same lyrics.
          songMoment.lyrics = rowLyrics; //  fixme: should not change a value of an object already in a hashmap!

          if (_debugging && gridCoordinate.col == 1) {
            logger.d('(${gridCoordinate.row},1) = ${songMoment.lyrics}');
          }
        }
      }
    }

    return _songMomentGrid;
  }

  GridCoordinate getMomentGridCoordinate(SongMoment songMoment) {
    _computeSongMoments();
    return _songMomentGridCoordinateHashMap[songMoment];
  }

  GridCoordinate getMomentGridCoordinateFromMomentNumber(int momentNumber) {
    SongMoment songMoment = getSongMoment(momentNumber);
    if (songMoment == null) return null;
    return _songMomentGridCoordinateHashMap[songMoment];
  }

  void debugSongMoments() {
    _computeSongMoments();

    for (SongMoment songMoment in _songMoments) {
      GridCoordinate momentGridCoordinate = getMomentGridCoordinateFromMomentNumber(songMoment.getMomentNumber());
      logger.d(songMoment.getMomentNumber().toString() +
          ': ' +
          songMoment.getChordSectionLocation().toString() +
          '#' +
          songMoment.getSectionCount().toString() +
          ' m:' +
          momentGridCoordinate.toString() +
          ' ' +
          songMoment.getMeasure().toMarkup() +
          (songMoment.getRepeatMax() > 1
              ? ' ' + (songMoment.getRepeat() + 1).toString() + '/' + songMoment.repeatMax.toString()
              : ''));
    }
  }

  String songMomentMeasure(int momentNumber, Key key, int halfStepOffset) {
    _computeSongMoments();
    if (momentNumber < 0 || _songMoments.isEmpty || momentNumber > _songMoments.length - 1) return '';
    return _songMoments[momentNumber].getMeasure().transpose(key, halfStepOffset);
  }

  String songNextMomentMeasure(int momentNumber, Key key, int halfStepOffset) {
    _computeSongMoments();
    if (momentNumber < -1 || _songMoments.isEmpty || momentNumber > _songMoments.length - 2) return '';
    return _songMoments[momentNumber + 1].getMeasure().transpose(key, halfStepOffset);
  }

  String songMomentStatus(int beatNumber, int momentNumber) {
    _computeSongMoments();
    if (_songMoments.isEmpty) return 'unknown';

    if (momentNumber < 0) {
//            beatNumber %= getBeatsPerBar();
//            if (beatNumber < 0)
//                beatNumber += getBeatsPerBar();
//            beatNumber++;
      return 'count in ' + (-momentNumber).toString();
    }

    SongMoment songMoment = getSongMoment(momentNumber);
    if (songMoment == null) return '';

    Measure measure = songMoment.getMeasure();

    beatNumber %= measure.beatCount;
    if (beatNumber < 0) beatNumber += measure.beatCount;
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

  /// Find the corrsesponding chord section for the given lyrics section
  ChordSection findChordSectionByLyricSection(LyricSection lyricSection) {
    if (lyricSection == null) return null;
    logger.d('chordSectionMap size: ' + _getChordSectionMap().keys.length.toString());
    return _getChordSectionMap()[lyricSection.sectionVersion];
  }

  /// Compute the duration and total beat count for the song.
  void computeDuration() {
    //  be lazy
    if (_duration != null && _duration > 0) return;

    _duration = 0;
    totalBeats = 0;

    List<SongMoment> moments = getSongMoments();
    if (beatsPerBar == 0 || defaultBpm == 0 || moments == null || moments.isEmpty) return;

    for (SongMoment moment in moments) {
      totalBeats += moment.getMeasure().beatCount;
    }
    _duration = totalBeats * 60.0 / defaultBpm;
  }

  /// Find the chord section for the given section version.
  ChordSection getChordSection(SectionVersion sectionVersion) {
    return _getChordSectionMap()[sectionVersion];
  }

  ChordSection getChordSectionByLocation(ChordSectionLocation chordSectionLocation) {
    if (chordSectionLocation == null) return null;
    ChordSection ret = _getChordSectionMap()[chordSectionLocation.sectionVersion];
    return ret;
  }

  String getUser() {
    return user;
  }

  void setUser(String user) {
    this.user = (user == null || user.isEmpty) ? defaultUser : user;
  }

  HashMap<SectionVersion, ChordSection> _getChordSectionMap() {
    //  lazy eval
    if (_chordSectionMap == null) {
      try {
        _parseChords(_chords);
        _invalidateChords();
      } catch (e) {
        logger.i('unexpected: ' + e);
        return null;
      }
    }
    return _chordSectionMap;
  }

  String _getChords() {
    _chords ??= chordsToJsonTransportString();
    return _chords;
  }

  /// Try to promote lower case characters to uppercase when they appear to be musical chords
  static String entryToUppercase(String entry) {
    StringBuffer sb = StringBuffer();

    UpperCaseState state = UpperCaseState.initial;
    for (int i = 0; i < entry.length; i++) {
      String c = entry[i];

      //  map newlines!
      if (c == '\n') c = ',';

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
              String sf = entry[i + 1];
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
                for (ChordDescriptor chordDescriptor in ChordDescriptor.values) {
                  cdString = chordDescriptor.toString();
                  if (cdString.isNotEmpty && test.startsWith(cdString)) {
                    isChordDescriptor = true;
                    break;
                  }
                }
                //  a chord descriptor makes a good partition to restart capitalization
                if (isChordDescriptor) {
                  sb.write(c.toUpperCase());
                  if (sf != null) sb.write(sf);
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
          if (c == ')') state = UpperCaseState.initial;
          break;
      }
    }
    return sb.toString();
  }

  /// Parse the current string representation of the song's chords into the song internal structures.
  void _parseChords(final String chords) {
    _chords = chords; //  safety only
    _chordSectionMap = HashMap();
    clearCachedValues(); //  force lazy eval

    if (chords != null) {
      logger.d('parseChords for: ' + getTitle());
      SplayTreeSet<ChordSection> emptyChordSections = SplayTreeSet<ChordSection>();
      MarkedString markedString = MarkedString(chords);
      ChordSection chordSection;
      while (markedString.isNotEmpty) {
        markedString.stripLeadingWhitespace();
        if (markedString.isEmpty) {
          break;
        }
        logger.d(markedString.toString());

        try {
          chordSection = ChordSection.parse(markedString, beatsPerBar, false);
          if (chordSection.phrases.isEmpty) {
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
          clearCachedValues();
        } catch (e) {
          //  try some repair
          clearCachedValues();

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
  List<MeasureNode> parseChordEntry(final String entry) {
    List<MeasureNode> ret = [];

    if (entry != null) {
      logger.d('parseChordEntry: ' + entry);
      SplayTreeSet<ChordSection> emptyChordSections = SplayTreeSet();
      MarkedString markedString = MarkedString(entry);
      ChordSection chordSection;
      int phaseIndex = 0;
      while (markedString.isNotEmpty) {
        markedString.stripLeadingWhitespace();
        if (markedString.isEmpty) break;
        logger.d('parseChordEntry: ' + markedString.toString());

        int mark = markedString.mark();

        try {
          //  if it's a full section (or multiple sections) it will all be handled here
          chordSection = ChordSection.parse(markedString, beatsPerBar, true);

          //  look for multiple sections defined at once
          if (chordSection.phrases.isEmpty) {
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
          ret.add(MeasureRepeat.parse(markedString, phaseIndex, beatsPerBar, null));
          phaseIndex++;
          continue;
        } catch (e) {
          markedString.resetTo(mark);
        }
        //  see if it's a phrase
        try {
          ret.add(Phrase.parse(markedString, phaseIndex, beatsPerBar, getCurrentChordSectionLocationMeasure()));
          phaseIndex++;
          continue;
        } catch (e) {
          markedString.resetTo(mark);
        }
        //  see if it's a single measure
        try {
          ret.add(Measure.parse(markedString, beatsPerBar, getCurrentChordSectionLocationMeasure()));
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
          if (measure.isComment()) continue;
          if (measure.endOfRow) {
            hasEndOfRow = true;
            break;
          }
        }
        if (!hasEndOfRow && phrase.length >= 8) {
          int i = 0;
          for (Measure measure in phrase.measures) {
            if (measure.isComment()) continue;
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
    sortedChordSections.addAll(_getChordSectionMap().values);
    if (sortedChordSections.isEmpty) return;

    ChordSection chordSection = sortedChordSections.last;
    if (chordSection != null) {
      List<Phrase> measureSequenceItems = chordSection.phrases;
      if (measureSequenceItems != null && measureSequenceItems.isNotEmpty) {
        Phrase lastPhrase = measureSequenceItems[measureSequenceItems.length - 1];
        currentChordSectionLocation = ChordSectionLocation(chordSection.sectionVersion,
            phraseIndex: measureSequenceItems.length - 1, measureIndex: lastPhrase.length - 1);
      }
    }
  }

  void calcChordMaps() {
    getChordSectionLocationGrid(); //  use location grid to force them all in lazy eval
  }

  HashMap<GridCoordinate, ChordSectionLocation> _getGridCoordinateChordSectionLocationMap() {
    getChordSectionLocationGrid();
    return gridCoordinateChordSectionLocationMap;
  }

  HashMap<ChordSectionLocation, GridCoordinate> _getGridChordSectionLocationCoordinateMap() {
    getChordSectionLocationGrid();
    return gridChordSectionLocationCoordinateMap;
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
    getChordSectionLocationGrid();
    return _chordSectionGridMatches;
  }

  Grid<ChordSectionLocation> getChordSectionLocationGrid() {
    //  support lazy eval
    if (_chordSectionLocationGrid != null) return _chordSectionLocationGrid;

    Grid<ChordSectionLocation> grid = Grid<ChordSectionLocation>();
    chordSectionGridCoorinateMap = HashMap<SectionVersion, GridCoordinate>();
    _chordSectionGridMatches = HashMap<SectionVersion, SectionVersion>();
    gridCoordinateChordSectionLocationMap = HashMap<GridCoordinate, ChordSectionLocation>();
    gridChordSectionLocationCoordinateMap = HashMap<ChordSectionLocation, GridCoordinate>();

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
      if (!sectionVersionsToDo.contains(sectionVersion)) continue;
      sectionVersionsToDo.remove(sectionVersion);

      //  start each section on it's own line
      if (col != offset) {
        row++;
      }
      col = 0;

      logger.v('gridding: ' + sectionVersion.toString() + ' (' + row.toString() + ', ' + col.toString() + ')');

      {
        //  grid the section header
        SplayTreeSet<SectionVersion> matchingSectionVersionsSet = matchingSectionVersions(sectionVersion);
        GridCoordinate coordinate = GridCoordinate(row, col);
        for (SectionVersion matchingSectionVersion in matchingSectionVersionsSet) {
          chordSectionGridCoorinateMap[matchingSectionVersion] = coordinate;
          ChordSectionLocation loc = ChordSectionLocation(matchingSectionVersion);
          gridChordSectionLocationCoordinateMap[loc] = coordinate;
        }
        for (SectionVersion matchingSectionVersion in matchingSectionVersionsSet) {
          //  don't add identity mapping
          if (matchingSectionVersion == sectionVersion) continue;
          //  note: don't use the get function!  we're building it in this method.
          _chordSectionGridMatches[matchingSectionVersion] = sectionVersion;
        }

        ChordSectionLocation loc;
        if (matchingSectionVersionsSet.length > 1) {
          loc = ChordSectionLocation.byMultipleSectionVersion(matchingSectionVersionsSet);
        } else {
          loc = ChordSectionLocation(sectionVersion);
        }
        gridCoordinateChordSectionLocationMap[coordinate] = loc;
        gridChordSectionLocationCoordinateMap[loc] = coordinate;
        grid.set(row, col, loc);
        col = offset;
        sectionVersionsToDo.removeAll(matchingSectionVersionsSet);
      }

      //  allow for empty sections... on entry
      if (chordSection.phrases.isEmpty) {
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

          Phrase phrase = chordSection.getPhrase(phraseIndex);

          //  default to max measures per row
          int measuresPerRow = 8;

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
              measuresPerRow = 4;
            }
          }

          //  grid each measure of the phrase
          bool repeatExtensionUsed = false;
          if (phraseSize == 0 && phrase.isRepeat()) {
            //  special case: deal with empty repeat
            //  fill row to measures per line
            col = offset + measuresPerRow - 1;
            {
              //  add repeat indicator
              ChordSectionLocation loc = ChordSectionLocation(sectionVersion, phraseIndex: phraseIndex);
              GridCoordinate coordinate = GridCoordinate(row, col);
              gridCoordinateChordSectionLocationMap[coordinate] = loc;
              gridChordSectionLocationCoordinateMap[loc] = coordinate;
              grid.set(row, col++, loc);
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
                  if (currentCol > maxCol) maxCol = currentCol;
                  currentCol = offset;
                }
              }
              if (currentCol > maxCol) maxCol = currentCol;
              maxCol = min(maxCol, measuresPerRow + 1);
            }

            //  place each measure in the grid
            Measure lastMeasure;
            for (int measureIndex = 0; measureIndex < phraseSize; measureIndex++) {
              //  place comments on their own line
              //  don't upset the col location
              //  expect the output to span the row
              measure = phrase.getMeasure(measureIndex);
              if (measure.isComment()) {
                if (col > offset && lastMeasure != null && !lastMeasure.isComment()) row++;
                ChordSectionLocation loc =
                    ChordSectionLocation(sectionVersion, phraseIndex: phraseIndex, measureIndex: measureIndex);
                grid.set(row, offset, loc);
                GridCoordinate coordinate = GridCoordinate(row, offset);
                gridCoordinateChordSectionLocationMap[coordinate] = loc;
                gridChordSectionLocationCoordinateMap[loc] = coordinate;
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
                      ChordSectionLocation.withMarker(
                          sectionVersion,
                          phraseIndex,
                          (repeatExtensionUsed
                              ? ChordSectionLocationMarker.repeatMiddleRight
                              : ChordSectionLocationMarker.repeatUpperRight)));
                  repeatExtensionUsed = true;
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
                gridCoordinateChordSectionLocationMap[coordinate] = loc;
                gridChordSectionLocationCoordinateMap[loc] = coordinate;
                grid.set(row, col++, loc);
              }

              //  put the repeat on the end of the last line of the repeat
              if (phrase.isRepeat() && measureIndex == phraseSize - 1) {
                col = maxCol;

                //  close the multiline repeat marker
                if (repeatExtensionUsed) {
                  ChordSectionLocation loc = ChordSectionLocation.withMarker(
                      sectionVersion, phraseIndex, ChordSectionLocationMarker.repeatLowerRight);
                  GridCoordinate coordinate = GridCoordinate(row, col);
                  gridCoordinateChordSectionLocationMap[coordinate] = loc;
                  gridChordSectionLocationCoordinateMap[loc] = coordinate;
                  grid.set(row, col++, loc);

                  repeatExtensionUsed = false;
                }

                {
                  //  add repeat indicator
                  ChordSectionLocation loc = ChordSectionLocation.withMarker(
                      sectionVersion, phraseIndex, ChordSectionLocationMarker.repeatLowerRight);
                  GridCoordinate coordinate = GridCoordinate(row, col);
                  gridCoordinateChordSectionLocationMap[coordinate] = loc;
                  gridChordSectionLocationCoordinateMap[loc] = coordinate;
                  grid.set(row, col++, loc);
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

    _chordSectionLocationGrid = grid;
    //logger.d(grid.toString());

    {
      logger.d('gridCoordinateChordSectionLocationMap: ');
      SplayTreeSet set = SplayTreeSet<GridCoordinate>();
      set.addAll(gridCoordinateChordSectionLocationMap.keys);
      for (GridCoordinate coordinate in set) {
        logger.d(' ' +
            coordinate.toString() +
            ' ' +
            gridCoordinateChordSectionLocationMap[coordinate].toString() +
            ' -> ' +
            findMeasureNodeByLocation(gridCoordinateChordSectionLocationMap[coordinate])?.toMarkup().toString());
      }
    }
    {
      logger.d('gridChordSectionLocationCoordinateMap: ');
      SplayTreeSet set = SplayTreeSet<ChordSectionLocation>();
      set.addAll(gridChordSectionLocationCoordinateMap.keys);
      for (ChordSectionLocation loc in set) {
        logger.d(' ' +
            loc.toString() +
            ' ' +
            gridChordSectionLocationCoordinateMap[loc].toString() +
            ' -> ' +
            findMeasureNodeByGrid(gridChordSectionLocationCoordinateMap[loc])?.toMarkup().toString());
      }
    }

    return _chordSectionLocationGrid;
  }

  /// Find all matches to the given section version, including the given section version itself
  SplayTreeSet<SectionVersion> matchingSectionVersions(SectionVersion multSectionVersion) {
    SplayTreeSet<SectionVersion> ret = SplayTreeSet();
    if (multSectionVersion == null) return ret;
    ChordSection multChordSection = findChordSectionBySectionVersion(multSectionVersion);
    if (multChordSection == null) return ret;

    {
      SplayTreeSet<ChordSection> set = SplayTreeSet();
      set.addAll(_getChordSectionMap().values);
      for (ChordSection chordSection in set) {
        if (multSectionVersion == chordSection.sectionVersion) {
          ret.add(multSectionVersion);
        } else if (chordSection.phrases == multChordSection.phrases) {
          ret.add(chordSection.sectionVersion);
        }
      }
    }
    return ret;
  }

  ChordSectionLocation getLastChordSectionLocation() {
    Grid<ChordSectionLocation> grid = getChordSectionLocationGrid();
    if (grid == null || grid.isEmpty) return null;
    List<ChordSectionLocation> row = grid.getRow(grid.getRowCount() - 1);
    return grid.get(grid.getRowCount() - 1, row.length - 1);
  }

  HashMap<SectionVersion, GridCoordinate> getChordSectionGridCoorinateMap() {
    // force grid population from lazy eval
    if (_chordSectionLocationGrid == null) getChordSectionLocationGrid();
    return chordSectionGridCoorinateMap;
  }

  void clearCachedValues() {
    _chordSectionLocationGrid = null;
    complexity = 0;
    chordsAsMarkup = null;
    _songMomentGrid = null;
    _songMoments = null;
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

  String toMarkup() {
    if (chordsAsMarkup != null) return chordsAsMarkup;

    StringBuffer sb = StringBuffer();

    SplayTreeSet<SectionVersion> sortedSectionVersions = SplayTreeSet.of(_getChordSectionMap().keys);
    SplayTreeSet<SectionVersion> completedSectionVersions = SplayTreeSet();

    //  markup by section version order
    for (SectionVersion sectionVersion in sortedSectionVersions) {
      //  don't repeat anything
      if (completedSectionVersions.contains(sectionVersion)) continue;
      completedSectionVersions.add(sectionVersion);

      //  find all section versions with the same chords
      ChordSection chordSection = _getChordSectionMap()[sectionVersion];
      if (chordSection.isEmpty()) {
        //  empty sections stand alone
        sb.write(sectionVersion.toString());
        sb.write(' ');
      } else {
        SplayTreeSet<SectionVersion> currentSectionVersions = SplayTreeSet();
        for (SectionVersion otherSectionVersion in sortedSectionVersions) {
          if (listsEqual(chordSection.phrases, _getChordSectionMap()[otherSectionVersion].phrases)) {
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

      //  chord section phrases (only) to output
      sb.write(chordSection.phrasesToMarkup());
      sb.write(' '); //  for human readability only
    }
    chordsAsMarkup = sb.toString();
    return chordsAsMarkup;
  }

  String toMarkupByLocation(ChordSectionLocation location) {
    StringBuffer sb = StringBuffer();
    if (location != null) {
      if (location.isSection) {
        sb.write(location.toString());
        sb.write(' ');
        sb.write(getChordSectionByLocation(location).phrasesToMarkup());
        return sb.toString();
      } else {
        MeasureNode measureNode = findMeasureNodeByLocation(location);
        if (measureNode != null) return measureNode.toMarkup();
      }
    }
    return null;
  }

  String toEntry(ChordSectionLocation location) {
    StringBuffer sb = StringBuffer();
    if (location != null) {
      if (location.isSection) {
        sb.write(getChordSectionByLocation(location).transposeToKey(key).toEntry());
        return sb.toString();
      } else {
        MeasureNode measureNode = findMeasureNodeByLocation(location);
        if (measureNode != null) return measureNode.transposeToKey(key).toEntry();
      }
    }
    return null;
  }

  /// Add the given section version to the song chords
  bool addSectionVersion(SectionVersion sectionVersion) {
    if (sectionVersion == null || _getChordSectionMap().containsKey(sectionVersion)) return false;
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
    ChordSectionLocation location = getCurrentChordSectionLocation();

    //  find the named chord section
    ChordSection chordSection = getChordSectionByLocation(location);
    if (chordSection == null) {
      postMod();
      return false;
    }

    if (chordSection.phrases.isEmpty) {
      chordSection.phrases.add(Phrase([], 0));
    }

    Phrase phrase;
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
      if (ret && phrase.isEmpty()) return deleteCurrentChordSectionPhrase();
    } else if (location.isPhrase) {
      return deleteCurrentChordSectionPhrase();
    } else if (location.isSection) {
      //  find the section prior to the one being deleted
      SectionVersion nextSectionVersion = _priorSectionVersion(chordSection.sectionVersion);
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
          location = findChordSectionLocation(_getChordSectionMap()[nextSectionVersion]);
        }
      }
    }
    return standardEditCleanup(ret, location);
  }

  bool deleteCurrentChordSectionPhrase() {
    ChordSectionLocation location = getCurrentChordSectionLocation();
    ChordSection chordSection = getChordSectionByLocation(location);
    bool ret = chordSection.deletePhrase(location.phraseIndex);
    if (ret) {
      //  move the current location if required
      if (location.phraseIndex >= chordSection.phrases.length) {
        if (chordSection.phrases.isEmpty) {
          location = ChordSectionLocation(chordSection.sectionVersion);
        } else {
          int i = chordSection.phrases.length - 1;
          Phrase phrase = chordSection.getPhrase(i);
          int m = phrase.measures.length - 1;
          location = ChordSectionLocation(chordSection.sectionVersion, phraseIndex: i, measureIndex: m);
        }
      }
    }
    return standardEditCleanup(ret, location);
  }

  void preMod(MeasureNode measureNode) {
    logger.d('startingChords(\"' + toMarkup() + '\");');
    logger.d(' pre(MeasureEditType.' +
        getCurrentMeasureEditType().toString() +
        ', \"' +
        getCurrentChordSectionLocation().toString() +
        '\"' +
        ', \"' +
        (getCurrentChordSectionLocationMeasureNode() == null
            ? 'null'
            : getCurrentChordSectionLocationMeasureNode().toMarkup()) +
        '\"' +
        ', \"' +
        (measureNode == null ? 'null' : measureNode.toMarkup()) +
        '\");');
  }

  void postMod() {
    logger.d('resultChords(\"' + toMarkup() + '\");');
    logger.d('post(MeasureEditType.' +
        getCurrentMeasureEditType().toString() +
        ', \"' +
        getCurrentChordSectionLocation().toString() +
        '\"' +
        ', \"' +
        (getCurrentChordSectionLocationMeasureNode() == null
            ? 'null'
            : getCurrentChordSectionLocationMeasureNode().toMarkup()) +
        '\");');
  }

  bool editList(List<MeasureNode> measureNodes) {
    if (measureNodes == null || measureNodes.isEmpty) return false;

    for (MeasureNode measureNode in measureNodes) {
      if (!editMeasureNode(measureNode)) return false;
    }
    return true;
  }

  bool deleteCurrentSelection() {
    setCurrentMeasureEditType(MeasureEditType.delete);
    return editMeasureNode(null);
  }

  /// Edit the given measure in or out of the song based on the data from the edit location.
  bool editMeasureNode(MeasureNode measureNode) {
    MeasureEditType editType = getCurrentMeasureEditType();

    if (editType == MeasureEditType.delete) return deleteCurrentChordSectionLocation();

    preMod(measureNode);

    if (measureNode == null) {
      postMod();
      return false;
    }

    ChordSectionLocation location = getCurrentChordSectionLocation();

    //  find the named chord section
    ChordSection chordSection = getChordSectionByLocation(location);
    if (chordSection == null) {
      switch (measureNode.getMeasureNodeType()) {
        case MeasureNodeType.section:
          chordSection = measureNode as ChordSection;
          break;
        default:
          chordSection = _getChordSectionMap()[SectionVersion.getDefault()];
          if (chordSection == null) {
            chordSection = ChordSection.getDefault();
            _getChordSectionMap()[chordSection.sectionVersion] = chordSection;
            _invalidateChords();
          }
          break;
      }
    }

    //  default to insert if empty
    if (chordSection.phrases.isEmpty) {
      chordSection.phrases.add(Phrase([], 0));
      //fixme?  editType = MeasureEditType.insert;
    }

    Phrase phrase;
    if (location.hasPhraseIndex) {
      try {
        phrase = chordSection.getPhrase(location.phraseIndex);
      } catch (e) {
        ;
      }
    }
    if (phrase == null && !chordSection.isEmpty()) phrase = chordSection.phrases[0]; //  use the default empty list

    bool ret = false;

    //  handle situations by the type of measure node being added
    ChordSectionLocation newLocation;
    ChordSection newChordSection;
    MeasureRepeat newRepeat;
    Phrase newPhrase;
    switch (measureNode.getMeasureNodeType()) {
      case MeasureNodeType.section:
        switch (editType) {
          case MeasureEditType.delete:
            //  find the section prior to the one being deleted
            SectionVersion nextSectionVersion = _priorSectionVersion(chordSection.sectionVersion);
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
        if (newRepeat.isEmpty()) {
          //  empty repeat
          if (phrase.isRepeat()) {
            //  change repeats
            MeasureRepeat repeat = phrase as MeasureRepeat;
            if (newRepeat.repeats < 2) {
              setCurrentMeasureEditType(MeasureEditType.append);

              //  convert repeat to phrase
              newPhrase = Phrase(repeat.measures, location.phraseIndex);
              int phaseIndex = location.phraseIndex;
              if (phaseIndex > 0 &&
                  chordSection.getPhrase(phaseIndex - 1).getMeasureNodeType() == MeasureNodeType.phrase) {
                //  expect combination of the two phrases
                int newPhraseIndex = phaseIndex - 1;
                Phrase priorPhrase = chordSection.getPhrase(newPhraseIndex);
                location = ChordSectionLocation(chordSection.sectionVersion,
                    phraseIndex: newPhraseIndex,
                    measureIndex: priorPhrase.measures.length + newPhrase.measures.length - 1);
                return standardEditCleanup(
                    chordSection.deletePhrase(phaseIndex) && chordSection.add(newPhraseIndex, newPhrase), location);
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
          if (newRepeat.repeats <= 1) return true; //  no change but no change was asked for

          if (!phrase.isEmpty()) {
            //  convert phrase line to a repeat
            GridCoordinate minGridCoordinate = getGridCoordinate(location);
            minGridCoordinate = GridCoordinate(minGridCoordinate.row, 1);
            MeasureNode minMeasureNode = findMeasureNodeByGrid(minGridCoordinate);
            ChordSectionLocation minLocation = getChordSectionLocation(minGridCoordinate);
            GridCoordinate maxGridCoordinate = getGridCoordinate(location);
            maxGridCoordinate = GridCoordinate(
                maxGridCoordinate.row, _chordSectionLocationGrid.getRow(maxGridCoordinate.row).length - 1);
            MeasureNode maxMeasureNode = findMeasureNodeByGrid(maxGridCoordinate);
            ChordSectionLocation maxLocation = getChordSectionLocation(maxGridCoordinate);
            logger.d('min: ' +
                minGridCoordinate.toString() +
                ' ' +
                minMeasureNode.toMarkup() +
                ' ' +
                minLocation.measureIndex.toString());
            logger.d('max: ' +
                maxGridCoordinate.toString() +
                ' ' +
                maxMeasureNode.toMarkup() +
                ' ' +
                maxLocation.measureIndex.toString());

            //  delete the old
            int phraseIndex = phrase.phraseIndex;
            chordSection.deletePhrase(phraseIndex);
            //  replace the old early part
            if (minLocation.measureIndex > 0) {
              List<Measure> range = [];
              range.addAll(phrase.measures.getRange(0, minLocation.measureIndex));
              chordSection.add(phraseIndex, Phrase(range, phraseIndex));
              phraseIndex++;
            }
            //  replace the sub-phrase with a repeat
            {
              List<Measure> range = [];
              range.addAll(phrase.measures.getRange(minLocation.measureIndex, maxLocation.measureIndex + 1));
              MeasureRepeat repeat = MeasureRepeat(range, phraseIndex, newRepeat.repeats);
              chordSection.add(phraseIndex, repeat);
              location = ChordSectionLocation(chordSection.sectionVersion, phraseIndex: phraseIndex);
              phraseIndex++;
            }
            //  replace the old late part
            if (maxLocation.measureIndex < phrase.measures.length - 1) {
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
          if (newRepeat.repeats < 2) newPhrase = Phrase(newRepeat.measures, newRepeat.phraseIndex);

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
              return standardEditCleanup(chordSection.add(phrase.phraseIndex, newPhrase), location);
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
              Phrase lastPhrase = chordSection.lastPhrase();
              switch (lastPhrase.getMeasureNodeType()) {
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
            if (chordSection.isEmpty()) {
              location = ChordSectionLocation(chordSection.sectionVersion,
                  phraseIndex: phraseIndex, measureIndex: newPhrase.length - 1);
              newPhrase.setPhraseIndex(phraseIndex);
              return standardEditCleanup(chordSection.add(phraseIndex, newPhrase), location);
            }

            if (location.hasMeasureIndex) {
              newLocation = ChordSectionLocation(chordSection.sectionVersion,
                  phraseIndex: phrase.phraseIndex, measureIndex: location.measureIndex + newPhrase.length);
              return standardEditCleanup(phrase.edit(editType, location.measureIndex, newPhrase), newLocation);
            }
            if (location.hasPhraseIndex) {
              phraseIndex = location.phraseIndex + 1;
              newLocation = ChordSectionLocation(chordSection.sectionVersion,
                  phraseIndex: phraseIndex, measureIndex: newPhrase.length - 1);
              return standardEditCleanup(chordSection.add(phraseIndex, newPhrase), newLocation);
            }
            newLocation = ChordSectionLocation(chordSection.sectionVersion,
                phraseIndex: phrase.phraseIndex, measureIndex: phrase.measures.length + newPhrase.length - 1);
            return standardEditCleanup(phrase.add(newPhrase.measures), newLocation);

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
              Phrase firstPhrase = chordSection.getPhrase(0);
              switch (firstPhrase.getMeasureNodeType()) {
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
            if (chordSection.isEmpty()) {
              location = ChordSectionLocation(chordSection.sectionVersion,
                  phraseIndex: phraseIndex, measureIndex: newPhrase.length - 1);
              newPhrase.setPhraseIndex(phraseIndex);
              return standardEditCleanup(chordSection.add(phraseIndex, newPhrase), location);
            }

            if (location.hasMeasureIndex) {
              newLocation = ChordSectionLocation(chordSection.sectionVersion,
                  phraseIndex: phrase.phraseIndex, measureIndex: location.measureIndex + newPhrase.length - 1);
              return standardEditCleanup(phrase.edit(editType, location.measureIndex, newPhrase), newLocation);
            }

            //  insert new phrase in front of existing phrase
            newLocation = ChordSectionLocation(chordSection.sectionVersion,
                phraseIndex: phrase.phraseIndex, measureIndex: newPhrase.length - 1);
            return standardEditCleanup(phrase.addAllAt(0, newPhrase.measures), newLocation);
          case MeasureEditType.replace:
            if (location != null) {
              if (location.hasPhraseIndex) {
                if (location.hasMeasureIndex) {
                  newLocation = ChordSectionLocation(chordSection.sectionVersion,
                      phraseIndex: phraseIndex, measureIndex: location.measureIndex + newPhrase.length - 1);
                  return standardEditCleanup(phrase.edit(editType, location.measureIndex, newPhrase), newLocation);
                }
                //  delete the phrase before replacing it
                phraseIndex = location.phraseIndex;
                if (phraseIndex > 0 &&
                    chordSection.getPhrase(phraseIndex - 1).getMeasureNodeType() == MeasureNodeType.phrase) {
                  //  expect combination of the two phrases
                  Phrase priorPhrase = chordSection.getPhrase(phraseIndex - 1);
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
        if (location.hasMeasureIndex) {
          newLocation = location;
          switch (editType) {
            case MeasureEditType.append:
              newLocation = location.nextMeasureIndexLocation();
              break;
            default:
              break;
          }
          return standardEditCleanup(phrase.edit(editType, newLocation.measureIndex, measureNode), newLocation);
        }

        //  add measure to chordSection by creating a new phase
        if (location.hasPhraseIndex) {
          List<Measure> measures = [];
          measures.add(measureNode as Measure);
          newPhrase = Phrase(measures, location.phraseIndex);
          switch (editType) {
            case MeasureEditType.delete:
              break;
            case MeasureEditType.append:
              newPhrase.setPhraseIndex(phrase.phraseIndex);
              return standardEditCleanup(
                  chordSection.add(phrase.phraseIndex, newPhrase), location.nextMeasureIndexLocation());
            case MeasureEditType.insert:
              newPhrase.setPhraseIndex(phrase.phraseIndex);
              return standardEditCleanup(chordSection.add(phrase.phraseIndex, newPhrase), location);
            case MeasureEditType.replace:
              newPhrase.setPhraseIndex(phrase.phraseIndex);
              return standardEditCleanup(
                  chordSection.deletePhrase(phrase.phraseIndex) && chordSection.add(newPhrase.phraseIndex, newPhrase),
                  location);
          }
        }
        break;
      case MeasureNodeType.decoration:
        return false;
    }

    //  edit measure node into location
    switch (editType) {
      case MeasureEditType.insert:
        switch (measureNode.getMeasureNodeType()) {
          case MeasureNodeType.repeat:
          case MeasureNodeType.phrase:
            ret = chordSection.insert(location.phraseIndex, measureNode);
            break;
          default:
            break;
        }
        //  no location change
        standardEditCleanup(ret, location);
        break;

      case MeasureEditType.append:
        //  promote marker to repeat
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
          switch (measureNode.getMeasureNodeType()) {
            case MeasureNodeType.section:
              SectionVersion sectionVersion = location.sectionVersion;
              return standardEditCleanup(
                  ((_getChordSectionMap()[sectionVersion] = measureNode as ChordSection) != null),
                  location.nextMeasureIndexLocation());
            case MeasureNodeType.phrase:
            case MeasureNodeType.repeat:
              return standardEditCleanup(chordSection.add(location.phraseIndex, measureNode as Phrase), location);
            default:
              break;
          }
        }
        if (location.isPhrase) {
          switch (measureNode.getMeasureNodeType()) {
            case MeasureNodeType.repeat:
            case MeasureNodeType.phrase:
              chordSection.phrases.insert(location.phraseIndex + 1, measureNode as Phrase);
              return standardEditCleanup(true, location);
            default:
              break;
          }
          break;
        }

        break;

      case MeasureEditType.delete:
        //  note: measureNode is ignored, and should be ignored
        if (location.isMeasure) {
          ret = (phrase.deleteAt(location.measureIndex) != null);
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
                      phraseIndex: 0, measureIndex: chordSection.getPhrase(0).length - 1);
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
                  phraseIndex: index, measureIndex: chordSection.getPhrase(index).length - 1);
              measureNode = findMeasureNodeByLocation(location);
            } else if (chordSection.getPhraseCount() > 0) {
              location = ChordSectionLocation(chordSection.sectionVersion,
                  phraseIndex: 0, measureIndex: chordSection.getPhrase(0).length - 1);
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
        break;
      default:
        break;
    }
    postMod();
    return ret;
  }

  /// Important function to clean up data conditions after an edit
  bool standardEditCleanup(bool ret, ChordSectionLocation location) {
    if (ret) {
      _invalidateChords(); //  force lazy re-compute of markup when required, after and edit

      collapsePhrases(location);
      setCurrentChordSectionLocation(location);
      resetLastModifiedDateToNow();

      switch (getCurrentMeasureEditType()) {
        // case MeasureEditType.replace:
        case MeasureEditType.delete:
          if (getCurrentChordSectionLocationMeasureNode() == null) setCurrentMeasureEditType(MeasureEditType.append);
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
  /// that have come togeter due to an edit.
  void collapsePhrases(ChordSectionLocation location) {
    if (location == null) return;
    ChordSection chordSection = _getChordSectionMap()[location.sectionVersion];
    if (chordSection == null) return;
    int limit = chordSection.getPhraseCount();
    if (limit <= 1) return; //  no work to do

    Phrase lastPhrase;
    for (int i = 0; i < limit; i++) {
      Phrase phrase = chordSection.getPhrase(i);
      if (lastPhrase == null) {
        if (phrase.getMeasureNodeType() == MeasureNodeType.phrase) lastPhrase = phrase;
        continue;
      }
      if (phrase.getMeasureNodeType() == MeasureNodeType.phrase) {
        if (lastPhrase != null) {
          //  two contiguous phrases: join
          lastPhrase.add(phrase.measures);
          chordSection.deletePhrase(i);
          limit--; //  one less index

          _invalidateChords();
        }
        lastPhrase = phrase;
      } else {
        lastPhrase = null;
      }
    }
  }

  SectionVersion _priorSectionVersion(SectionVersion sectionVersion) {
    SplayTreeSet<SectionVersion> sortedSectionVersions = SplayTreeSet<SectionVersion>.of(_getChordSectionMap().keys);
    if (sortedSectionVersions.length < 2) return null;

    SectionVersion ret = sortedSectionVersions.firstWhere((v) {
      return sectionVersion.compareTo(v) > 0;
    }, orElse: () {
      return null;
    });

    logger.d('_priorSectionVersion($sectionVersion): $ret');
    logger.d(sortedSectionVersions.toList().toString());
    return ret;
  }

  SectionVersion _nextSectionVersion(SectionVersion sectionVersion) {
    SplayTreeSet<SectionVersion> sortedSectionVersions = SplayTreeSet<SectionVersion>.of(_getChordSectionMap().keys);

    SectionVersion ret = sortedSectionVersions.firstWhere((v) {
      return sectionVersion.compareTo(v) < 0;
    }, orElse: () {
      return null;
    });
    logger.d('_nextSectionVersion($sectionVersion): $ret');
    logger.d(sortedSectionVersions.toList().toString());
    return ret;
  }

  SectionVersion _firstSectionVersion() {
    SplayTreeSet<SectionVersion> set = SplayTreeSet.of(_getChordSectionMap().keys);
    return (set.isEmpty ? null : set.first);
  }

  /// Find the measure sequence item for the given measure (i.e. the measure's parent container).
  Phrase findPhrase(Measure measure) {
    if (measure == null) return null;

    ChordSection chordSection = findChordSectionByMeasureNode(measure);
    if (chordSection == null) return null;
    for (Phrase msi in chordSection.phrases) {
      for (Measure m in msi.measures) {
        if (m == measure) return msi;
      }
    }
    return null;
  }

  ///Find the chord section for the given measure node.
  ChordSection findChordSectionByMeasureNode(MeasureNode measureNode) {
    if (measureNode == null) return null;

    String id = measureNode.getId();
    for (ChordSection chordSection in _getChordSectionMap().values) {
      if (id != null && id == chordSection.getId()) return chordSection;
      MeasureNode mn = chordSection.findMeasureNode(measureNode);
      if (mn != null) return chordSection;
    }
    return null;
  }

  ChordSectionLocation findChordSectionLocation(MeasureNode measureNode) {
    if (measureNode == null) return null;

    Phrase phrase;
    try {
      ChordSection chordSection = findChordSectionByMeasureNode(measureNode);
      switch (measureNode.getMeasureNodeType()) {
        case MeasureNodeType.section:
          return ChordSectionLocation(chordSection.sectionVersion);
        case MeasureNodeType.repeat:
        case MeasureNodeType.phrase:
          phrase = chordSection.findPhrase(measureNode);
          return ChordSectionLocation(chordSection.sectionVersion, phraseIndex: phrase.phraseIndex);
        case MeasureNodeType.decoration:
        case MeasureNodeType.comment:
        case MeasureNodeType.measure:
          phrase = chordSection.findPhrase(measureNode);
          return ChordSectionLocation(chordSection.sectionVersion,
              phraseIndex: phrase.phraseIndex, measureIndex: phrase.findMeasureNodeIndex(measureNode));
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  ChordSectionLocation getChordSectionLocation(GridCoordinate gridCoordinate) {
    return _getGridCoordinateChordSectionLocationMap()[gridCoordinate];
  }

  GridCoordinate getGridCoordinate(ChordSectionLocation chordSectionLocation) {
    chordSectionLocation =
        chordSectionLocation.changeSectionVersion(_getChordSectionGridMatches()[chordSectionLocation.sectionVersion]);
    return _getGridChordSectionLocationCoordinateMap()[chordSectionLocation];
  }

  /// Find the chord section for the given type of chord section
  ChordSection findChordSectionBySectionVersion(SectionVersion sectionVersion) {
    if (sectionVersion == null) return null;
    return _getChordSectionMap()[sectionVersion]; //  get not type safe!!!!
  }

  Measure findMeasureByChordSectionLocation(ChordSectionLocation chordSectionLocation) {
    try {
      if (chordSectionLocation.isMeasure) {
        return _getChordSectionMap()[chordSectionLocation.sectionVersion]
            .getPhrase(chordSectionLocation.phraseIndex)
            .getMeasure(chordSectionLocation.measureIndex);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Measure getCurrentChordSectionLocationMeasure() {
    ChordSectionLocation location = getCurrentChordSectionLocation();
    if (location.hasMeasureIndex) {
      int index = location.measureIndex;
      if (index > 0) {
        location =
            ChordSectionLocation(location.sectionVersion, phraseIndex: location.phraseIndex, measureIndex: index);
        MeasureNode measureNode = findMeasureNodeByLocation(location);
        if (measureNode != null) {
          switch (measureNode.getMeasureNodeType()) {
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

  MeasureNode findMeasureNodeByGrid(GridCoordinate coordinate) {
    MeasureNode ret = findMeasureNodeByLocation(_getGridCoordinateChordSectionLocationMap()[coordinate]);
    return ret;
  }

  MeasureNode findMeasureNodeByLocation(ChordSectionLocation chordSectionLocation) {
    if (chordSectionLocation == null) return null;
    ChordSection chordSection = _getChordSectionMap()[chordSectionLocation.sectionVersion];
    if (chordSection == null) return null;
    if (chordSectionLocation.isSection) return chordSection;

    try {
      Phrase phrase = chordSection.getPhrase(chordSectionLocation.phraseIndex);
      if (chordSectionLocation.isPhrase) {
        switch (chordSectionLocation.marker) {
          case ChordSectionLocationMarker.none:
            return phrase;
          default:
            return MeasureRepeatExtension.get(chordSectionLocation.marker);
        }
      }

      return phrase.getMeasure(chordSectionLocation.measureIndex);
    } catch (RangeError) {
      return null;
    }
  }

  MeasureNode getCurrentMeasureNode() {
    return findMeasureNodeByLocation(currentChordSectionLocation);
  }

  ChordSection findChordSectionByString(String s) {
    SectionVersion sectionVersion = SectionVersion.parseString(s);
    return _getChordSectionMap()[sectionVersion];
  }

  ChordSection findChordSectionbyMarkedString(MarkedString markedString) {
    SectionVersion sectionVersion = SectionVersion.parse(markedString);
    return _getChordSectionMap()[sectionVersion];
  }

  bool chordSectionLocationDelete(ChordSectionLocation chordSectionLocation) {
    try {
      ChordSection chordSection = getChordSection(chordSectionLocation.sectionVersion);
      if (chordSection.deleteMeasure(chordSectionLocation.phraseIndex, chordSectionLocation.measureIndex)) {
        clearCachedValues();
        setCurrentChordSectionLocation(chordSectionLocation);
        return true;
      }
    } catch (e) {
      ;
    }
    return false;
  }

  bool chordSectionDelete(ChordSection chordSection) {
    if (chordSection == null) return false;
    bool ret = _getChordSectionMap().remove(chordSection) != null;
    _invalidateChords();
    return ret;
  }

  void guessTheKey() {
    //  fixme: key guess based on chords section or lyrics?
    setKey(Key.guessKey(findScaleChordsUsed().keys));
  }

  HashMap<ScaleChord, int> findScaleChordsUsed() {
    HashMap<ScaleChord, int> ret = HashMap();
    for (ChordSection chordSection in _getChordSectionMap().values) {
      for (Phrase msi in chordSection.phrases) {
        for (Measure m in msi.measures) {
          for (Chord chord in m.chords) {
            ScaleChord scaleChord = chord.scaleChord;
            int chordCount = ret[scaleChord];
            ret[scaleChord] = (chordCount == null ? 1 : chordCount + 1);
          }
        }
      }
    }
    return ret;
  }

  void _parseLyrics() {
    int state = 0;
    String whiteSpace = '';
    StringBuffer lyricsBuffer = StringBuffer();
    LyricSection lyricSection;

    _lyricSections = [];

    MarkedString markedString = MarkedString(rawLyrics);
    while (markedString.isNotEmpty) {
      String c = markedString.charAt(0);

      //  absorb leading white space
      if (state == 0) {
        if (!(c == ' ' || c == '\t' || c == '\n' || c == '\r')) {
          state = 1;
        }
      }

      //  note that fall through is possible
      if (state == 1) {
        try {
          //  try to find the section version marker
          SectionVersion version = SectionVersion.parse(markedString);
          if (lyricSection != null) _lyricSections.add(lyricSection);

          lyricSection = LyricSection();
          lyricSection.setSectionVersion(version);

          whiteSpace = ''; //  ignore white space
          state = 1;
          continue;
        } catch (e) {
          logger.v('not section: ${markedString.remainingStringLimited(25)}');
          //  ignore
        }
        state = 2;
      }

      //  note that fall through is possible
      if (state == 2) {
        //  absorb all characters to a newline
        switch (c) {
          case ' ':
          case '\t':
            whiteSpace = whiteSpace + c;
            break;
          case '\n':
          case '\r':
            if (lyricSection == null) {
              //  oops, an old unformatted song, force a lyrics section
              lyricSection = LyricSection();
              lyricSection.setSectionVersion(Section.getDefaultVersion());
            }
            lyricSection.add(lyricsBuffer.toString());
            lyricsBuffer = StringBuffer();
            whiteSpace = ''; //  ignore trailing white space
            state = 0;
            break;
          default:
            lyricsBuffer.write(whiteSpace);
            lyricsBuffer.write(c);
            whiteSpace = '';
            break;
        }
      }

      if (state < 0 || state > 2) throw 'fsm broken at state: ' + state.toString();

      markedString.consume(1);
    }

    //  last one is not terminated by another section
    if (lyricSection != null) {
      lyricSection.add(lyricsBuffer.toString());
      _lyricSections.add(lyricSection);
    }

    //  safety with lazy eval
    clearCachedValues();
  }

  /// Debug only!  a string form of the song chord section grid
  String logGrid() {
    StringBuffer sb = StringBuffer('\n');

    calcChordMaps(); //  avoid ConcurrentModificationException
    for (int r = 0; r < getChordSectionLocationGrid().getRowCount(); r++) {
      List<ChordSectionLocation> row = chordSectionLocationGrid.getRow(r);
      for (int c = 0; c < row.length; c++) {
        ChordSectionLocation loc = row[c];
        if (loc == null) continue;
        sb.write('(');
        sb.write(r);
        sb.write(',');
        sb.write(c);
        sb.write(') ');
        sb.write(loc.isMeasure ? '        ' : (loc.isPhrase ? '    ' : ''));
        sb.write(loc.toString());
        sb.write('  ');
        sb.write(findMeasureNodeByLocation(loc)?.toMarkup());
        sb.write('\n');
      }
    }
    return sb.toString();
  }

  void addRepeat(ChordSectionLocation chordSectionLocation, MeasureRepeat repeat) {
    Measure measure = findMeasureByChordSectionLocation(chordSectionLocation);
    if (measure == null) return;

    Phrase measureSequenceItem = findPhrase(measure);
    if (measureSequenceItem == null) return;

    ChordSection chordSection = findChordSectionByMeasureNode(measure);
    List<Phrase> measureSequenceItems = chordSection.phrases;
    int i = measureSequenceItems.indexOf(measureSequenceItem);
    if (i >= 0) {
      List<Phrase> copy = [];
      copy.addAll(measureSequenceItems);
      measureSequenceItems = copy;
      measureSequenceItems.removeAt(i);
      repeat.setPhraseIndex(i);
      measureSequenceItems.insert(i, repeat);
    } else {
      repeat.setPhraseIndex(measureSequenceItems.length - 1);
      measureSequenceItems.add(repeat);
    }

    chordSectionDelete(chordSection);
    chordSection = ChordSection(chordSection.sectionVersion, measureSequenceItems);
    _getChordSectionMap()[chordSection.sectionVersion] = chordSection;
    _invalidateChords();
  }

  void setRepeat(ChordSectionLocation chordSectionLocation, int repeats) {
    Measure measure = findMeasureByChordSectionLocation(chordSectionLocation);
    if (measure == null) return;

    Phrase phrase = findPhrase(measure);
    if (phrase == null) return;

    if (phrase is MeasureRepeat) {
      MeasureRepeat measureRepeat = phrase;

      if (repeats <= 1) {
        //  remove the repeat
        ChordSection chordSection = findChordSectionByMeasureNode(measureRepeat);
        List<Phrase> measureSequenceItems = chordSection.phrases;
        int phraseIndex = measureSequenceItems.indexOf(measureRepeat);
        measureSequenceItems.removeAt(phraseIndex);
        measureSequenceItems.insert(phraseIndex, Phrase(measureRepeat.measures, phraseIndex));

        chordSectionDelete(chordSection);
        chordSection = ChordSection(chordSection.sectionVersion, measureSequenceItems);
        _getChordSectionMap()[chordSection.sectionVersion] = chordSection;
      } else {
        //  change the count
        measureRepeat.repeats = repeats;
      }
    } else {
      //  change sequence items to repeat
      MeasureRepeat measureRepeat = MeasureRepeat(phrase.measures, phrase.phraseIndex, repeats);
      ChordSection chordSection = findChordSectionByMeasureNode(phrase);
      List<Phrase> measureSequenceItems = chordSection.phrases;
      int i = measureSequenceItems.indexOf(phrase);
      List<Phrase> copy = [];
      copy.addAll(measureSequenceItems);
      measureSequenceItems = copy;
      measureSequenceItems.removeAt(i);
      measureSequenceItems.insert(i, measureRepeat);

      chordSectionDelete(chordSection);
      chordSection = ChordSection(chordSection.sectionVersion, measureSequenceItems);
      _getChordSectionMap()[chordSection.sectionVersion] = chordSection;
    }

    _invalidateChords();
  }

  /// Set the number of measures displayed per row
  bool setMeasuresPerRow(int measuresPerRow) {
    if (measuresPerRow <= 0) return false;

    bool ret = false;
    SplayTreeSet<ChordSection> set = SplayTreeSet.of(_getChordSectionMap().values);
    for (ChordSection chordSection in set) {
      ret = chordSection.setMeasuresPerRow(measuresPerRow) || ret;
    }
    if (ret) _invalidateChords();
    return ret;
  }

  /// Checks a song for completeness.
  Song checkSong() {
    return checkSongBase(getTitle(), getArtist(), getCopyright(), getKey(), getDefaultBpm().toString(),
        getBeatsPerBar().toString(), getUnitsPerMeasure().toString(), getUser(), toMarkup(), getRawLyrics());
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
   * @param unitsPerMeasureEntry the inverse of the note duration fraction per entry, for exmple if each beat is
   *                             represented by a quarter note, the units per measure would be 4.
   * @param chordsTextEntry      the string transport form of the song's chord sequence description
   * @param lyricsTextEntry      the string transport form of the song's section sequence and lyrics
   * @return a new song if the fields are valid
   * @throws ParseException exception thrown if the song's fields don't match properly.
   */
  static Song checkSongBase(
      String title,
      String artist,
      String copyright,
      Key key,
      String bpmEntry,
      String beatsPerBarEntry,
      String unitsPerMeasureEntry,
      String user,
      String chordsTextEntry,
      String lyricsTextEntry) {
    if (title == null || title.isEmpty) {
      throw 'no song title given!';
    }

    if (artist == null || artist.isEmpty) {
      throw 'no artist given!';
    }

    if (copyright == null || copyright.isEmpty) {
      throw 'no copyright given!';
    }

    key ??= Key.get(KeyEnum.C); //  punt on an error

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

    Song newSong = Song.createSong(
        title, artist, copyright, key, bpm, beatsPerBar, unitsPerMeasure, user, chordsTextEntry, lyricsTextEntry);
    newSong.resetLastModifiedDateToNow();

    if (newSong.getChordSections().isEmpty) throw 'The song has no chord sections! ';

    for (ChordSection chordSection in newSong.getChordSections()) {
      if (chordSection.isEmpty()) throw 'Chord section ' + chordSection.sectionVersion.toString() + ' is empty.';
    }

//  see that all chord sections have a lyric section
    for (ChordSection chordSection in newSong.getChordSections()) {
      SectionVersion chordSectionVersion = chordSection.sectionVersion;
      bool found = false;
      for (LyricSection lyricSection in newSong._lyricSections) {
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
    for (LyricSection lyricSection in newSong._lyricSections) {
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

    if (newSong.getMessage() == null) {
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

    newSong.setMessage(null);

    if (newSong.getMessage() == null) {
//  an early song with default (no) structure?
      if (newSong._lyricSections.length == 1 &&
          newSong._lyricSections[0].sectionVersion == Section.getDefaultVersion()) {
        newSong.setMessage('song looks too simple, is there really no structure?');
      }
    }

    return newSong;
  }

  static List<StringTriple> diff(SongBase a, SongBase b) {
    List<StringTriple> ret = [];

    if (a.getTitle().compareTo(b.getTitle()) != 0) ret.add(StringTriple('title:', a.getTitle(), b.getTitle()));
    if (a.getArtist().compareTo(b.getArtist()) != 0) ret.add(StringTriple('artist:', a.getArtist(), b.getArtist()));
    if (a.getCoverArtist() != null &&
        b.getCoverArtist() != null &&
        a.getCoverArtist().compareTo(b.getCoverArtist()) != 0) {
      ret.add(StringTriple('cover:', a.getCoverArtist(), b.getCoverArtist()));
    }
    if (a.getCopyright().compareTo(b.getCopyright()) != 0) {
      ret.add(StringTriple('copyright:', a.getCopyright(), b.getCopyright()));
    }
    if (a.getKey().compareTo(b.getKey()) != 0) {
      ret.add(StringTriple('key:', a.getKey().toString(), b.getKey().toString()));
    }
    if (a.getBeatsPerMinute() != b.getBeatsPerMinute()) {
      ret.add(StringTriple('BPM:', a.getBeatsPerMinute().toString(), b.getBeatsPerMinute().toString()));
    }
    if (a.getBeatsPerBar() != b.getBeatsPerBar()) {
      ret.add(StringTriple('per bar:', a.getBeatsPerBar().toString(), b.getBeatsPerBar().toString()));
    }
    if (a.getUnitsPerMeasure() != b.getUnitsPerMeasure()) {
      ret.add(StringTriple('units/measure:', a.getUnitsPerMeasure().toString(), b.getUnitsPerMeasure().toString()));
    }

//  chords
    for (ChordSection aChordSection in a.getChordSections()) {
      ChordSection bChordSection = b.getChordSection(aChordSection.sectionVersion);
      if (bChordSection == null) {
        ret.add(StringTriple('chords missing:', aChordSection.toMarkup(), ''));
      } else if (aChordSection.compareTo(bChordSection) != 0) {
        ret.add(StringTriple('chords:', aChordSection.toMarkup(), bChordSection.toMarkup()));
      }
    }
    for (ChordSection bChordSection in b.getChordSections()) {
      ChordSection aChordSection = a.getChordSection(bChordSection.sectionVersion);
      if (aChordSection == null) {
        ret.add(StringTriple('chords missing:', '', bChordSection.toMarkup()));
      }
    }

//  lyrics
    {
      int limit = min(a._lyricSections.length, b._lyricSections.length);
      for (int i = 0; i < limit; i++) {
        LyricSection aLyricSection = a._lyricSections[i];
        SectionVersion sectionVersion = aLyricSection.sectionVersion;
        LyricSection bLyricSection = b._lyricSections[i];
        int lineLimit = min(aLyricSection.getLyricsLines().length, bLyricSection.getLyricsLines().length);
        for (int j = 0; j < lineLimit; j++) {
          String aLine = aLyricSection.getLyricsLines()[j];
          String bLine = bLyricSection.getLyricsLines()[j];
          if (aLine.compareTo(bLine) != 0) {
            ret.add(StringTriple('lyrics ' + sectionVersion.toString(), aLine, bLine));
          }
        }
        lineLimit = aLyricSection.getLyricsLines().length;
        for (int j = bLyricSection.getLyricsLines().length; j < lineLimit; j++) {
          String aLine = aLyricSection.getLyricsLines()[j];
          ret.add(StringTriple('lyrics missing ' + sectionVersion.toString(), aLine, ''));
        }
        lineLimit = bLyricSection.getLyricsLines().length;
        for (int j = aLyricSection.getLyricsLines().length; j < lineLimit; j++) {
          String bLine = bLyricSection.getLyricsLines()[j];
          ret.add(StringTriple('lyrics missing ' + sectionVersion.toString(), '', bLine));
        }
      }
    }

    return ret;
  }

  bool hasSectionVersion(Section section, int version) {
    if (section == null) return false;

    for (SectionVersion sectionVersion in _getChordSectionMap().keys) {
      if (sectionVersion.section == section && sectionVersion.version == version) return true;
    }
    return false;
  }

  /// Sets the song's title and song id from the given title. Leading "The " articles are rotated to the title end.
  void setTitle(String title) {
    this.title = _theToTheEnd(title);
    computeSongIdFromSongData();
  }

  /// Sets the song's artist
  void setArtist(String artist) {
    this.artist = _theToTheEnd(artist);
    computeSongIdFromSongData();
  }

  void setCoverArtist(String coverArtist) {
    this.coverArtist = _theToTheEnd(coverArtist);
    computeSongIdFromSongData();
  }

  String _theToTheEnd(String s) {
    if (s == null || s.length <= 4) return s;

    //  move the leading "The " to the end
    RegExp theRegExp = RegExp('^ *(the +)(.*)', caseSensitive: false);
    RegExpMatch m = theRegExp.firstMatch(s);
    if (m != null) {
      s = m.group(2) + ', ' + m.group(1);
    }
    return s;
  }

  void resetLastModifiedDateToNow() {
    lastModifiedTime = DateTime.now().millisecondsSinceEpoch;
  }

  void computeSongIdFromSongData() {
    songId = computeSongId(title, artist, coverArtist);
  }

  static SongId computeSongId(String title, String artist, String coverArtist) {
    return SongId('Song_' +
        toSongId(title) +
        '_by_' +
        toSongId(artist) +
        (coverArtist == null || coverArtist.isEmpty ? '' : '_coverBy_' + toSongId(coverArtist)));
  }

  static String toSongId(String s) {
    return s
        .trim()
        .replaceAllMapped(notWordOrSpaceRegExp, (Match m) => '')
        .replaceAllMapped(dupUnderscoreOrSpaceRegExp, (Match m) => '_');
  }

  /// Sets the copyright for the song.  All songs should have a copyright.
  void setCopyright(String copyright) {
    this.copyright = copyright;
  }

  /// Set the key for this song.
  void setKey(Key key) {
    this.key = key;
  }

  /// Return the song default beats per minute.
  int getBeatsPerMinute() {
    return defaultBpm;
  }

  double getDefaultTimePerBar() {
    if (defaultBpm == 0) return 1;
    return beatsPerBar * 60.0 / defaultBpm;
  }

  double getSecondsPerBeat() {
    if (defaultBpm == 0) return 1;
    return 60.0 / defaultBpm;
  }

  /// Set the song default beats per minute.
  void setBeatsPerMinute(int bpm) {
    if (bpm < 20) {
      bpm = 20;
    } else if (bpm > 1000) bpm = 1000;
    defaultBpm = bpm;
    _duration = null;
  }

  /// Return the song's number of beats per bar
  int getBeatsPerBar() {
    return beatsPerBar;
  }

  /// Set the song's number of beats per bar
  void setBeatsPerBar(int beatsPerBar) {
    //  never divide by zero
    if (beatsPerBar <= 1) beatsPerBar = 2;
    this.beatsPerBar = beatsPerBar;
    clearCachedValues();
  }

  /// Return an integer that represents the number of notes per measure
  /// represented in the sheet music.  Typically this is 4; meaning quarter notes.
  int getUnitsPerMeasure() {
    return unitsPerMeasure;
  }

  void setUnitsPerMeasure(int unitsPerMeasure) {
    this.unitsPerMeasure = unitsPerMeasure;
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
    return songId.songId;
  }

  /// Return the song's title
  String getTitle() {
    return title;
  }

  /// Return the song's artist.
  String getArtist() {
    return artist;
  }

  /// Return the lyrics.
  @deprecated
  String getLyricsAsString() {
    return rawLyrics;
  }

  /// Return the default beats per minute.
  int getDefaultBpm() {
    return defaultBpm;
  }

  Iterable<ChordSection> getChordSections() {
    return _getChordSectionMap().values;
  }

  String getFileName() {
    return fileName;
  }

  void setFileName(String fileName) {
    this.fileName = fileName;
    if (fileName == null) return;

    RegExp fileVersionRegExp = RegExp(r' \(([0-9]+)\).songlyrics$');
    RegExpMatch mr = fileVersionRegExp.firstMatch(fileName);
    if (mr != null) {
      fileVersionNumber = int.parse(mr.group(1));
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
    _computeSongMoments();
    return _songMoments;
  }

  SongMoment getSongMoment(int momentNumber) {
    _computeSongMoments();
    if (_songMoments == null || _songMoments.isEmpty || momentNumber < 0 || momentNumber >= _songMoments.length) {
      return null;
    }
    return _songMoments[momentNumber];
  }

  SongMoment getFirstSongMomentInSection(int momentNumber) {
    SongMoment songMoment = getSongMoment(momentNumber);
    if (songMoment == null) return null;

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

  SongMoment getLastSongMomentInSection(int momentNumber) {
    SongMoment songMoment = getSongMoment(momentNumber);
    if (songMoment == null) return null;

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
    SongMoment songMoment = getSongMoment(momentNumber);
    if (songMoment == null) return 0;
    return songMoment.getBeatNumber() * getBeatsPerMinute() / 60.0;
  }

  static int getBeatNumberAtTime(int bpm, double songTime) {
    if (bpm <= 0) return null; //  we're done with this song play

    int songBeat = (songTime * bpm / 60.0).floor();
    return songBeat;
  }

  int getSongMomentNumberAtSongTime(double songTime) {
    if (getBeatsPerMinute() <= 0) return null; //  we're done with this song play

    int songBeat = getBeatNumberAtTime(getBeatsPerMinute(), songTime);
    if (songBeat < 0) {
      return (songBeat - beatsPerBar + 1) ~/ beatsPerBar; //  constant measure based lead in
    }

    _computeSongMoments();
    if (songBeat >= beatsToMoment.length) return null; //  we're done with the last measure of this song play

    return beatsToMoment[songBeat].getMomentNumber();
  }

  /// Return the first moment on the given row
  SongMoment getFirstSongMomentAtRow(int rowIndex) {
    if (rowIndex < 0) return null;
    _computeSongMoments();
    for (SongMoment songMoment in _songMoments) {
      //  return the first moment on this row
      if (rowIndex == getMomentGridCoordinate(songMoment).row) return songMoment;
    }
    return null;
  }

  int rowBeats(int rowIndex) {
    int ret = 0;
    SongMoment songMoment = getFirstSongMomentAtRow(rowIndex);
    if (songMoment != null) {
      for (int i = songMoment.getMomentNumber(); i < _songMoments.length; i++) {
        songMoment = _songMoments[i];
        if (songMoment.row != rowIndex) break;
        ret += songMoment.measure.beatCount;
      }
    }
    return ret;
  }

  int getFileVersionNumber() {
    return fileVersionNumber;
  }

  int getChordSectionBeatsFromLocation(ChordSectionLocation chordSectionLocation) {
    if (chordSectionLocation == null) return 0;
    return getChordSectionBeats(chordSectionLocation.sectionVersion);
  }

  int getChordSectionBeats(SectionVersion sectionVersion) {
    if (sectionVersion == null) return 0;
    _computeSongMoments();
    int ret = chordSectionBeats[sectionVersion];
    if (ret == null) return 0;
    return ret;
  }

  ///Compute a relative complexity index for the song
  int getComplexity() {
    if (complexity == 0) {
      //  compute the complexity
      SplayTreeSet<Measure> differentChords = SplayTreeSet();
      for (ChordSection chordSection in _getChordSectionMap().values) {
        for (Phrase phrase in chordSection.phrases) {
          //  the more different measures, the greater the complexity
          differentChords.addAll(phrase.measures);

          //  weight measures by guitar complexity
          for (Measure measure in phrase.measures) {
            if (!measure.isEasyGuitarMeasure()) complexity++;
          }
        }
      }
      complexity += _getChordSectionMap().values.length;
      complexity += differentChords.length;
    }
    return complexity;
  }

  String getRawLyrics() {
    return rawLyrics;
  }

  void setChords(String chords) {
    _chords = chords;
    _chordSectionMap = null; //  force a parse of the new chords
    clearCachedValues();
  }

  void _invalidateChords() {
    _chords = null;
    clearCachedValues();
  }

  void setRawLyrics(String rawLyrics) {
    this.rawLyrics = rawLyrics;
    _parseLyrics();
  }

  void setTotalBeats(int totalBeats) {
    this.totalBeats = totalBeats;
  }

  void setDefaultBpm(int defaultBpm) {
    this.defaultBpm = defaultBpm;
  }

  String getCoverArtist() {
    return coverArtist;
  }

  String getMessage() {
    return message;
  }

  void setMessage(String message) {
    this.message = message;
  }

  MeasureEditType getCurrentMeasureEditType() {
    return currentMeasureEditType;
  }

  void setCurrentMeasureEditType(MeasureEditType measureEditType) {
    currentMeasureEditType = measureEditType;
    logger.d('set edit type: ' +
        (currentMeasureEditType != null ? currentMeasureEditType.toString() : 'no type') +
        ' at ' +
        (currentChordSectionLocation != null ? currentChordSectionLocation.toString() : 'none'));
  }

  ChordSectionLocation getCurrentChordSectionLocation() {
    //  insist on something non-null
    if (currentChordSectionLocation == null) {
      if (_getChordSectionMap().keys.isEmpty) {
        currentChordSectionLocation = ChordSectionLocation(SectionVersion.getDefault());
      } else {
        //  last location
        SplayTreeSet<SectionVersion> sectionVersions = SplayTreeSet.of(_getChordSectionMap().keys);
        ChordSection lastChordSection = _getChordSectionMap()[sectionVersions.last];
        if (lastChordSection.isEmpty()) {
          currentChordSectionLocation = ChordSectionLocation(lastChordSection.sectionVersion);
        } else {
          Phrase phrase = lastChordSection.lastPhrase();
          if (phrase.isEmpty()) {
            currentChordSectionLocation =
                ChordSectionLocation(lastChordSection.sectionVersion, phraseIndex: phrase.phraseIndex);
          } else {
            currentChordSectionLocation = ChordSectionLocation(lastChordSection.sectionVersion,
                phraseIndex: phrase.phraseIndex, measureIndex: phrase.measures.length - 1);
          }
        }
      }
    }
    return currentChordSectionLocation;
  }

  MeasureNode getCurrentChordSectionLocationMeasureNode() {
    return currentChordSectionLocation == null ? null : findMeasureNodeByLocation(currentChordSectionLocation);
  }

  void setCurrentChordSectionLocation(ChordSectionLocation chordSectionLocation) {
//  try to find something close if the exact location doesn't exist
    if (chordSectionLocation == null) {
      chordSectionLocation = currentChordSectionLocation;
      chordSectionLocation ??= getLastChordSectionLocation();
    }
    if (chordSectionLocation != null) {
      try {
        ChordSection chordSection = getChordSectionByLocation(chordSectionLocation);
        ChordSection cs = chordSection;
        if (cs == null) {
          SplayTreeSet<SectionVersion> sortedSectionVersions =
              SplayTreeSet<SectionVersion>.of(_getChordSectionMap().keys);
          cs = _getChordSectionMap()[sortedSectionVersions.last];
        }
        if (chordSectionLocation.hasPhraseIndex) {
          Phrase phrase = cs.getPhrase(chordSectionLocation.phraseIndex);
          phrase ??= cs.getPhrase(cs.getPhraseCount() - 1);
          int phraseIndex = phrase.phraseIndex;
          if (chordSectionLocation.hasMeasureIndex) {
            int pi = (phraseIndex >= cs.getPhraseCount() ? cs.getPhraseCount() - 1 : phraseIndex);
            int measureIndex = chordSectionLocation.measureIndex;
            int mi = (measureIndex >= phrase.length ? phrase.length - 1 : measureIndex);
            if (cs != chordSection || pi != phraseIndex || mi != measureIndex) {
              chordSectionLocation = ChordSectionLocation(cs.sectionVersion, phraseIndex: pi, measureIndex: mi);
            }
          }
        }
      } catch (e) {
        chordSectionLocation = null;
      }
    }
//    catch
//    (
//    Exception ex) {
//    //  javascript parse error
//    logger.d(ex.getMessage());
//    chordSectionLocation = null;
//    }

    currentChordSectionLocation = chordSectionLocation;
    logger.d('set loc: ' +
        (currentChordSectionLocation != null ? currentChordSectionLocation.toString() : 'none') +
        ', type: ' +
        (currentMeasureEditType != null ? currentMeasureEditType.toString() : 'no type') +
        ', song value: ' +
        (currentChordSectionLocation != null
            ? findMeasureNodeByLocation(currentChordSectionLocation).toString()
            : 'none'));
  }

  @override
  String toString() {
    return title + (fileVersionNumber > 0 ? ':(' + fileVersionNumber.toString() + ')' : '') + ' by ' + artist;
  }

  static bool containsSongTitleAndArtist(Iterable<SongBase> iterable, SongBase song) {
    for (SongBase collectionSong in iterable) {
      if (song.compareBySongId(collectionSong) == 0) return true;
    }
    return false;
  }

  /// Compare only the title and artist.
  ///To be used for listing purposes only.
  int compareBySongId(SongBase o) {
    if (o == null) return -1;
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
    return other is SongBase && songBaseSameAs(other);
  }

  bool songBaseSameAs(SongBase o) {
    //  song id built from title with reduced whitespace
    if (title != o.title) return false;
    if (artist != o.artist) return false;
    if (coverArtist != null) {
      if (coverArtist != o.coverArtist) return false;
    } else if (o.coverArtist != null) {
      return false;
    }
    if (copyright != o.copyright) return false;
    if (key != o.key) return false;
    if (defaultBpm != o.defaultBpm) return false;
    if (unitsPerMeasure != o.unitsPerMeasure) return false;
    if (beatsPerBar != o.beatsPerBar) return false;
    if (_getChords() != o._getChords()) return false;
    if (rawLyrics != (o.rawLyrics)) return false;
    //    if (metadata != (o.metadata))
    //      return false;
    if (lastModifiedTime != o.lastModifiedTime) return false;

    //  hmm, think about these
    if (fileName != o.fileName) return false;
    if (fileVersionNumber != o.fileVersionNumber) return false;

    return true;
  }

  @override
  int get hashCode {
    //  2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97
    int ret = hash4(title, artist, coverArtist, copyright);
    ret = ret * 17 + hash4(key.keyEnum, defaultBpm, unitsPerMeasure, beatsPerBar);
    ret = ret * 19 + hash3(_getChords(), rawLyrics, lastModifiedTime);
    ret = ret * 23 + hash2(fileName, fileVersionNumber);
    return ret;
  }

//  primary values
  String title = 'Unknown';
  String artist = 'Unknown';
  String user = defaultUser;
  String coverArtist = '';
  String copyright = 'Unknown';
  Key key = Key.get(KeyEnum.C); //  default
  int defaultBpm = 106; //  beats per minute
  int unitsPerMeasure = 4; //  units per measure, i.e. timeSignature numerator
  int beatsPerBar = 4; //  beats per bar, i.e. timeSignature denominator
  int lastModifiedTime;

//  chords as a string is only valid on input or output
  String _chords = '';

//  normally the chords data is held in the chord section map
  HashMap<SectionVersion, ChordSection> _chordSectionMap;

  String rawLyrics = '';

//  deprecated values
  int fileVersionNumber = 0;

//  meta data
  String fileName;

//  computed values
  SongId songId;

  double get duration {
    computeDuration();
    return _duration;
  }

  double _duration; //  units of seconds
  int totalBeats;

  List<LyricSection> get lyricSections => _lyricSections;
  List<LyricSection> _lyricSections = [];
  HashMap<SectionVersion, GridCoordinate> chordSectionGridCoorinateMap;

//  match to representative section version
  HashMap<SectionVersion, SectionVersion> _chordSectionGridMatches;

  HashMap<GridCoordinate, ChordSectionLocation> gridCoordinateChordSectionLocationMap;
  HashMap<ChordSectionLocation, GridCoordinate> gridChordSectionLocationCoordinateMap;
  HashMap<SongMoment, GridCoordinate> _songMomentGridCoordinateHashMap;
  Grid<SongMoment> _songMomentGrid;

  HashMap<SectionVersion, int> chordSectionBeats = HashMap();

  ChordSectionLocation currentChordSectionLocation;
  MeasureEditType currentMeasureEditType = MeasureEditType.append;

  Grid<ChordSectionLocation> get chordSectionLocationGrid => getChordSectionLocationGrid();
  Grid<ChordSectionLocation> _chordSectionLocationGrid;

  int complexity;
  String chordsAsMarkup;
  String message;

  List<SongMoment> get songMoments => getSongMoments();
  List<SongMoment> _songMoments;
  HashMap<int, SongMoment> beatsToMoment;

//SplayTreeSet<Metadata> metadata = new SplayTreeSet();
  static final String defaultUser = 'Unknown';
  static final bool _debugging = false;

  static RegExp notWordOrSpaceRegExp = RegExp(r'[^\w\s]');
  static RegExp dupUnderscoreOrSpaceRegExp = RegExp('[ _]+');
}