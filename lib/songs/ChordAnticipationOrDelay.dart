import 'dart:collection';
import 'dart:core';

import '../util/util.dart';

enum ChordAnticipationOrDelayEnum {
  /// Play the chord on time.
  none,

  /// Anticipate (push) the chord by an 8th note duration.
  ///
  anticipate8th,

  /// Anticipate (push) the chord by a 16th note duration.
  // This is likely the most common form.
  anticipate16th,

  /// Anticipate (push) the chord by one triplet's duration.
  anticipateTriplet,

  /// Delay (pull) the chord by an 8th note duration.
  delay8th,

  /// Delay (pull) the chord by a 16th note duration.
  delay16th,

  /// Delay (pull) the chord by one triplet's duration.
  delayTriplet,
}

/// A small timing adjustment for a chord to change the feel of the chord.
/// Units are fractions of a beat expressed assuming quarter note beat duration.
class ChordAnticipationOrDelay implements Comparable<ChordAnticipationOrDelay> {
  static Map<ChordAnticipationOrDelayEnum, ChordAnticipationOrDelay> _delays;
  static List<dynamic> _initialization = [
    [ChordAnticipationOrDelayEnum.none, ""],
    [ChordAnticipationOrDelayEnum.anticipate8th, "<8"],
    [ChordAnticipationOrDelayEnum.anticipate16th, "<"],
    [ChordAnticipationOrDelayEnum.anticipateTriplet, "<3"],
    [ChordAnticipationOrDelayEnum.delay8th, ">8"],
    [ChordAnticipationOrDelayEnum.delay16th, ">"],
    [ChordAnticipationOrDelayEnum.delayTriplet, ">3"],
  ];

  ChordAnticipationOrDelay._(
      this._chordAnticipationOrDelayEnum, this._shortName);

  static ChordAnticipationOrDelay parse(MarkedString markedString) {
    if (markedString == null) throw "no data to parse";
    if (markedString.isNotEmpty)
      for (ChordAnticipationOrDelay a in _getSortedByShortName()) {
        if (markedString.available() >= a.shortName.length &&
            a.shortName ==
                markedString.remainingStringLimited(a.shortName.length)) {
          markedString.consume(a.shortName.length);
          return a;
        }
      }
    return ChordAnticipationOrDelay._getDelays()[
        ChordAnticipationOrDelayEnum.none];
  }

  static ChordAnticipationOrDelay get( ChordAnticipationOrDelayEnum e ){
    return _getDelays()[e];
  }

  static Iterable<ChordAnticipationOrDelay> get values {
    return _getDelays().values;
  }

  static SplayTreeSet<ChordAnticipationOrDelay> _sortedByShortName;

  static Set _getSortedByShortName() {
    if (_sortedByShortName == null) {
      //  initialize
      _sortedByShortName = SplayTreeSet<ChordAnticipationOrDelay>((a1, a2) {
        return a2.shortName.compareTo(a1.shortName);
      });
      for (ChordAnticipationOrDelayEnum delays
          in ChordAnticipationOrDelayEnum.values) {
        ChordAnticipationOrDelay delay = _getDelays()[delays];
        _sortedByShortName.add(delay);
      }
    }
    return _sortedByShortName;
  }

  static Map<ChordAnticipationOrDelayEnum, ChordAnticipationOrDelay>
      _getDelays() {
    if (_delays == null) {
      _delays = Map<ChordAnticipationOrDelayEnum,
          ChordAnticipationOrDelay>.identity();
      for (var init in _initialization) {
        ChordAnticipationOrDelayEnum keInit = init[0];
        _delays[keInit] = ChordAnticipationOrDelay._(keInit, init[1]);
      }
    }

    return _delays;
  }

  @override
  int compareTo(ChordAnticipationOrDelay other) {
    return _chordAnticipationOrDelayEnum.index -
        other._chordAnticipationOrDelayEnum.index;
  }

  /// Returns the human name of this enum.
  @override
  String toString() {
    return _shortName;
  }

  ChordAnticipationOrDelayEnum get chordAnticipationOrDelayEnum =>
      _chordAnticipationOrDelayEnum;
  final ChordAnticipationOrDelayEnum _chordAnticipationOrDelayEnum;

  String get shortName => _shortName;
  final String _shortName;
}
