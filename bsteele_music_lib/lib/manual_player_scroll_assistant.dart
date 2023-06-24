import 'package:bsteele_music_lib/songs/lyric_section.dart';
import 'package:bsteele_music_lib/songs/music_constants.dart';
import 'package:bsteele_music_lib/songs/song_base.dart';
import 'package:logger/logger.dart';

import 'app_logger.dart';
import 'grid_coordinate.dart';
import 'songs/song.dart';
import 'util/util.dart';

const _cjLogManualBumps = Level.debug;
const _logComputeBpm = Level.debug;

enum ManualPlayerScrollAssistantState {
  noClue,
  tooEarly,
  forward,
}

class ManualPlayerScrollAssistant {
  ManualPlayerScrollAssistant(this.song, {required final bool expanded, int? bpm}) : _bpm = bpm ?? song.beatsPerMinute {
    logger.i('ManualPlayerScrollAssistant(bpm: $_bpm)');

    //  generate table of minimum phrase row indices
    {
      //  generate the display grid
      // Grid<MeasureNode> displayGrid =
      //  note: actual grid is not used!... just the song moment to grid coordinate mapping.
      song.toDisplayGrid(UserDisplayStyle.both,
          expanded: expanded); //  fixme: style and expanded from current values!!!!
      final List<GridCoordinate> songMomentToGridCoordinateLookup = song.songMomentToGridCoordinate;

      int lastPhraseIndex = 0;
      LyricSection? lastLyricSection;
      int minRow = 0;
      for (var songMoment in song.songMoments) {
        //  find the minimum row required for a new lyric section, new phrase index, or any measure if expanded
        LyricSection lyricSection = songMoment.lyricSection;
        var row = songMomentToGridCoordinateLookup[songMoment.momentNumber].row;
        if (!identical(lyricSection, lastLyricSection)) {
          //  mark the new section row
          _lyricSectionFirstRows.add(row);
        }
        if (!identical(lyricSection, lastLyricSection) ||
                songMoment.phraseIndex != lastPhraseIndex ||
                !songMoment.phrase.isRepeat() //  non-repeats use their own row
                ||
                expanded //  every repeat row gets a row for itself if expanded
            ) {
          lastLyricSection = lyricSection;
          lastPhraseIndex = songMoment.phraseIndex;
          minRow = row;
        }
        songMomentsToMinRowIndex.add(minRow);
      }
      // for (var songMoment in song.songMoments) {
      //   logger.i('moment: ${songMoment.momentNumber}:'
      //       ' row: ${songMomentsToMinRowIndex[songMoment.momentNumber]}'
      //       ', ${songMoment.chordSection.sectionVersion}'
      //       ' ${songMoment.measure}'
      //       ', repeat: ${songMoment.repeat}/${songMoment.repeatMax}');
      // }
    }

    // logger.i('displayGrid:');
    // for (var r = 0; r < displayGrid.getRowCount(); r++) {
    //   var row = displayGrid.getRow(r);
    //   for (var measureNode in (row ?? []).indexed) {
    //     logger.i( ' ${measureNode.$1}: ${measureNode.$2.runtimeType}: ${measureNode.$2}');
    //   }
    // }
  }

  /// Suggest a row for the player list using the current time
  int? rowSuggestion(final DateTime dateTime) {
    int? ret;
    switch (_state) {
      case ManualPlayerScrollAssistantState.forward:
        var beatNumber = beatNumberAt(dateTime);
        ret = rowAtBeatNumber(beatNumber.round());
        // logger.i('beatNumber: $beatNumber, row: $ret');
        _lastRowSuggestion = ret ?? _lastRowSuggestion;
        break;
      default:
        break;
    }
    return ret;
  }

  ///  Update the assistant with the given section request
  sectionRequest(final DateTime dateTime, int sectionIndex) {
    sectionIndex = Util.indexLimit(sectionIndex, song.lyricSections);
    var beatNumber = 0;
    if (sectionIndex >= _lastSectionIndex) {
      var newSongMomentIndex = song.firstMomentInLyricSection(song.lyricSections[sectionIndex]).momentNumber;
      beatNumber = song.songMoments[newSongMomentIndex].beatNumber;
      logger.log(
          _cjLogManualBumps,
          'section: from $_lastSectionIndex to $sectionIndex, moment: $newSongMomentIndex'
          ', row: ${songMomentsToMinRowIndex[newSongMomentIndex]}, beat: $beatNumber');
    } else {
      //  going backwards
      _state = ManualPlayerScrollAssistantState.noClue;
    }
    _lastSectionIndex = sectionIndex;
    rowSuggestion(dateTime);

    //  compute the bpm going forward
    error = null;
    switch (_state) {
      case ManualPlayerScrollAssistantState.noClue:
        //  skip the first beat number
        if (beatNumber >= 0) {
          _refBeatNumber = beatNumber;
          _refDateTime = dateTime;
          _state = ManualPlayerScrollAssistantState.tooEarly;
        }
        break;
      case ManualPlayerScrollAssistantState.tooEarly:
        //  delay to get two points of reference
        _state = ManualPlayerScrollAssistantState.forward;
        break;
      case ManualPlayerScrollAssistantState.forward:
        var estimatedBeatNumber = beatNumberAt(dateTime);
        _bpm = _computeBpmAt(dateTime, beatNumber);
        error = estimatedBeatNumber - beatNumber;
        logger.log(
            _cjLogManualBumps,
            'forward: $beatNumber/${dateTime.difference(_refDateTime!)}'
            ' = $_bpm bpm'
            ', est: ${estimatedBeatNumber.toStringAsFixed(3)}'
            ', row: ${rowAtBeatNumber(beatNumber)}'
            ', error: ${error?.toStringAsFixed(3)}');
        break;
    }
  }

  int _computeBpmAt(final DateTime dateTime, final int beatNumber) {
    var diff = dateTime.difference(_refDateTime!).inMicroseconds;
    var songMoment = song.songMomentAtBeatNumber(beatNumber);

    int ret;
    if (beatNumber <= 0 ||
        songMoment == null ||
        //  don't compute bpm at the start of the song
        songMoment.sectionCount < 1 ||
        //  don't compute bpm at the end of the song
        songMoment.sectionCount >= song.lyricSections.length - 1) {
      ret = _bpm ?? MusicConstants.defaultBpm;
    } else {
      ret = (diff > 0)
          ? (60 * (beatNumber - _refBeatNumber) * Duration.microsecondsPerSecond / diff).round()
          : _bpm ?? MusicConstants.defaultBpm;
      //logger.i('raw ret: $ret, diff: $diff, state: ${state.name}, _bpm: $_bpm');
      if (ret < MusicConstants.minBpm || ret > MusicConstants.maxBpm) {
        //  out of range
        ret = _bpm ?? MusicConstants.defaultBpm;
      }
    }
    logger.log(
        _logComputeBpm,
        '_computeBpmAt($dateTime, $beatNumber) = $ret'
        ', _bpm: $_bpm, $songMoment');
    return ret;
  }

  /// Compute the beat number for the given time
  /// Requires a valid BPM.
  double beatNumberAt(final DateTime dateTime) {
    return _refDateTime == null || _bpm == null
        ? 0.0
        : _refBeatNumber +
            bpm * dateTime.difference(_refDateTime!).inMicroseconds / (60 * Duration.microsecondsPerSecond);
  }

  int? rowAtBeatNumber(final int beatNumber) {
    var moment = song.songMomentAtBeatNumber(beatNumber);
    if (moment == null) {
      return null;
    }
    return songMomentsToMinRowIndex[moment.momentNumber];
  }

  bool isLyricSectionFirstRow(final DateTime dateTime) {
    var moment = song.songMomentAtBeatNumber(beatNumberAt(dateTime).ceil());
    if (moment == null) {
      return false;
    }
    return moment.phraseIndex == 0 //  in the first phrase
        &&
        moment.repeat == 0 //  in the first repeat
        &&
        //  in the first row
        moment.chordSection.phrases[moment.phraseIndex].expandedRowIndexAt(moment.measureIndex) == 0;
  }

  @override
  String toString() {
    return '{bpm: $_bpm, section: $_lastSectionIndex, row: $_lastRowSuggestion, state: ${_state.name}'
        '${error != null ? ', error: ${error?.toStringAsFixed(1)}' : ''}}';
  }

  int get bpm => _bpm ?? 0;
  int? _bpm;
  double? error;

  int _lastSectionIndex = 0;

  int get lastRowSuggestion => _lastRowSuggestion;
  int _lastRowSuggestion = 0;
  int _refBeatNumber = 0;

  DateTime? get refDateTime => _refDateTime;
  DateTime? _refDateTime;

  final Song song;

  ManualPlayerScrollAssistantState get state => _state;
  ManualPlayerScrollAssistantState _state = ManualPlayerScrollAssistantState.noClue;
  List<int> songMomentsToMinRowIndex = [];
  final List<int> _lyricSectionFirstRows = [];
}
