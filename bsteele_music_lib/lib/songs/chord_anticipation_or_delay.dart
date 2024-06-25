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
  delayTriplet;

  Map<String, dynamic> toJson() => {'name': name};

  factory ChordAnticipationOrDelayEnum.fromJson(Map<String, dynamic> json) =>
      ChordAnticipationOrDelayEnum.values.byName(json['name']);
}

/// A small timing adjustment for a chord to change the feel of the chord.
/// Units are fractions of a beat expressed assuming quarter note beat duration.
class ChordAnticipationOrDelay implements Comparable<ChordAnticipationOrDelay> {
  static Map<ChordAnticipationOrDelayEnum, ChordAnticipationOrDelay> _delays = {};
  static final List<dynamic> _initialization = [
    [ChordAnticipationOrDelayEnum.none, ''],
    [ChordAnticipationOrDelayEnum.anticipate8th, '<8'],
    [ChordAnticipationOrDelayEnum.anticipate16th, '<'],
    [ChordAnticipationOrDelayEnum.anticipateTriplet, '<3'],
    [ChordAnticipationOrDelayEnum.delay8th, '>8'],
    [ChordAnticipationOrDelayEnum.delay16th, '>'],
    [ChordAnticipationOrDelayEnum.delayTriplet, '>3'],
  ];

  ChordAnticipationOrDelay._(this.chordAnticipationOrDelayEnum, this.shortName);

  static ChordAnticipationOrDelay? parse(MarkedString? markedString) {
    if (markedString == null) {
      throw 'no data to parse';
    }
    if (markedString.isNotEmpty) {
      for (ChordAnticipationOrDelay a in _getSortedByShortName()) {
        if (markedString.available() >= a.shortName.length &&
            a.shortName == markedString.remainingStringLimited(a.shortName.length)) {
          markedString.consume(a.shortName.length);
          return a;
        }
      }
    }
    return ChordAnticipationOrDelay._getDelays()[ChordAnticipationOrDelayEnum.none];
  }

  static ChordAnticipationOrDelay get(ChordAnticipationOrDelayEnum e) {
    var ret = _getDelays()[e];
    if (ret != null) {
      return ret;
    }
    throw 'ChordAnticipationOrDelay not found!';
  }

  static Iterable<ChordAnticipationOrDelay> get values {
    return _getDelays().values;
  }

  static SplayTreeSet<ChordAnticipationOrDelay> _sortedByShortName = SplayTreeSet();

  static Set _getSortedByShortName() {
    if (_sortedByShortName.isEmpty) {
      //  lazy initialize
      _sortedByShortName = SplayTreeSet<ChordAnticipationOrDelay>((a1, a2) {
        return a2.shortName.compareTo(a1.shortName);
      });
      for (ChordAnticipationOrDelayEnum delays in ChordAnticipationOrDelayEnum.values) {
        ChordAnticipationOrDelay? delay = _getDelays()[delays];
        if (delay != null) {
          _sortedByShortName.add(delay);
        }
      }
    }
    return _sortedByShortName;
  }

  static Map<ChordAnticipationOrDelayEnum, ChordAnticipationOrDelay> _getDelays() {
    if (_delays.isEmpty) {
      _delays = Map<ChordAnticipationOrDelayEnum, ChordAnticipationOrDelay>.identity();
      for (var init in _initialization) {
        ChordAnticipationOrDelayEnum keInit = init[0];
        _delays[keInit] = ChordAnticipationOrDelay._(keInit, init[1]);
      }
    }

    return _delays;
  }

  /// for JSON serialization only
  ChordAnticipationOrDelay()
      : shortName = '',
        chordAnticipationOrDelayEnum = ChordAnticipationOrDelayEnum.none;

  static ChordAnticipationOrDelay get defaultValue => ChordAnticipationOrDelay.get(ChordAnticipationOrDelayEnum.none);

  @override
  int compareTo(ChordAnticipationOrDelay other) {
    return chordAnticipationOrDelayEnum.index - other.chordAnticipationOrDelayEnum.index;
  }

  Map<String, dynamic> toJson() => {'chordAnticipationOrDelayEnum': chordAnticipationOrDelayEnum.name};

  factory ChordAnticipationOrDelay.fromJson(Map<String, dynamic> json) {
    return ChordAnticipationOrDelay.get(
        ChordAnticipationOrDelayEnum.values.firstWhere((e) => e.name == json['chordAnticipationOrDelayEnum']));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChordAnticipationOrDelay &&
          runtimeType == other.runtimeType &&
          chordAnticipationOrDelayEnum.index == other.chordAnticipationOrDelayEnum.index;

  @override
  int get hashCode => shortName.hashCode;

  /// Returns the human name of this enum.
  @override
  String toString() {
    return shortName;
  }

  final ChordAnticipationOrDelayEnum chordAnticipationOrDelayEnum;

  final String shortName;
}
