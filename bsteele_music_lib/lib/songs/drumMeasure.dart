import 'dart:collection';

import 'package:bsteeleMusicLib/util/util.dart';

enum DrumDivision {
  beat,
  beatE,
  beatAnd,
  beatAndA,
}

final drumDivisionsPerBeat = DrumDivision.values.length;

enum DrumType { closedHighHat, openHighHat, snare, kick, bass }

class DrumBeat implements Comparable<DrumBeat> {
  DrumBeat(int beat, //  counts from 1!
      {DrumDivision? division = DrumDivision.beat})
      : _beat = beat - 1,
        _offset = (beat - 1) * drumDivisionsPerBeat + division!.index {
    assert(beat >= 1);
    assert(beat <= 6); //  fixme eventually
    this.division = _divisionAt(_offset);
    divisionName = _drumDivisionNames[division.index];
    shortDivisionName = _drumShortDivisionNames[division.index];
  }

  DrumBeat.offset(this._offset) : _beat = _offset ~/ drumDivisionsPerBeat {
    assert(_offset >= 0);
    assert(_offset <= 6 * drumDivisionsPerBeat); //  fixme
    division = _divisionAt(_offset);
    divisionName = _drumDivisionNames[division.index];
    shortDivisionName = _drumShortDivisionNames[division.index];
  }

  int get offset => _offset;

  DrumDivision _divisionAt(int offSet) {
    return DrumDivision.values[offSet % drumDivisionsPerBeat];
  }

  @override
  String toString() {
    return '${_beat + 1}${_drumDivisionNames[division.index]}';
  }

  @override
  int compareTo(DrumBeat other) {
    return _offset.compareTo(other._offset);
  }

  static const List<String> _drumDivisionNames = <String>['', 'e', 'and', 'andA'];
  static const List<String> _drumShortDivisionNames = <String>['', 'e', 'and', 'a'];

  int get beat => _beat + 1;

  final int _beat;
  final int _offset;
  late final DrumDivision division;
  late final String divisionName;
  late final String shortDivisionName;
}

/// Descriptor of a single drum in the measure.

class DrumMeasurePart implements Comparable<DrumMeasurePart> {
  DrumMeasurePart(this._drumType, {Iterable<DrumBeat>? beats}) {
    if (beats != null) addAll(beats);
  }

  List<double> timings(double t0, int bpm) {
    List<double> ret = [];
    if (bpm > 0) {
      for (var beat in beats) {
        ret.add(t0 + beat.offset * 60.0 / (bpm * drumDivisionsPerBeat));
      }
    }
    return ret;
  }

  bool get isEmpty => beats.isEmpty;

  bool get isNotEmpty => !isEmpty;

  void addBeat(DrumBeat drumBeat) {
    beats.add(drumBeat);
  }

  void add(int beat, //  counts from 1!
      {DrumDivision? division}) {
    beats.add(DrumBeat(beat, division: division));
  }

  void addAll(Iterable<DrumBeat> newBeats) {
    for (var beat in newBeats) {
      beats.add(beat);
    }
  }

  void addAt(int offset) {
    beats.add(DrumBeat.offset(offset));
  }

  void removeBeat(DrumBeat drumBeat) {
    beats.remove(drumBeat);
  }

  void remove(int beat, //  counts from 1!
      {DrumDivision? division = DrumDivision.beat}) {
    assert(beat >= 1);
    assert(beat <= 6); //  fixme eventually
    beats.remove(DrumBeat(beat, division: division));
  }

  void removeAt(int offset) {
    assert(offset >= 0);
    assert(offset <= 6 * drumDivisionsPerBeat); //  fixme eventually
    beats.remove(DrumBeat.offset(offset));
  }

  @override
  String toString() {
    var sb = StringBuffer();
    var first = true;
    for (var beat in beats) {
      if (first) {
        first = false;
      } else {
        sb.write(', ');
      }
      sb.write(beat.toString());
    }

    return 'DrumMeasurePart{drumType: ${Util.enumName(_drumType)}, beats: ${sb.toString()} }  ';
  }

  @override
  int compareTo(DrumMeasurePart other) {
    if (identical(this, other)) return 0;

    int ret = other.drumType.index - drumType.index;
    if (ret != 0) return ret < 0 ? -1 : 1;

    for (var i = 0; i < beats.length; i++) {
      if (other.beats.length <= i) return 1;
      int ret = beats.elementAt(i).compareTo(other.beats.elementAt(i));
      if (ret != 0) return ret;
    }
    if (beats.length < other.beats.length) return -1;
    return 0;
  }

  SplayTreeSet<DrumBeat> beats = SplayTreeSet();

  DrumType get drumType => _drumType;
  final DrumType _drumType;
}

/// Descriptor of the drums to be played for the given measure and
/// likely subsequent measures.
class DrumMeasure implements Comparable<DrumMeasure> {
  /// Set an individual drum's part.
  void addPart(DrumMeasurePart part) {
    parts[part.drumType] = part;
  }

  void removePart(DrumMeasurePart part) {
    parts.remove(part.drumType);
  }

  bool? isSilent() {
    if (parts.isEmpty) {
      return true;
    }
    for (var part in parts.keys) {
      if (parts[part]?.isNotEmpty ?? false) {
        return false;
      }
    }
    return true;
  }

  @override
  String toString() {
    var sb = StringBuffer();
    var first = true;
    for (var type in parts.keys) {
      var part = parts[type]!;
      if (first) {
        first = false;
      } else {
        sb.write(', ');
      }
      sb.write(part.toString());
    }

    return 'DrumMeasure{parts: ${sb.toString()} }  ';
  }

  @override
  int compareTo(DrumMeasure other) {
    if (identical(this, other)) return 0;
    for (var type in parts.keys) {
      var thisPart = parts[type];
      assert(thisPart != null);
      var otherPart = other.parts[type];
      if (otherPart == null) return -1;
      int ret = thisPart!.compareTo(otherPart);
      if (ret != 0) return ret;
    }
    return 0;
  }

  HashMap<DrumType, DrumMeasurePart> parts = HashMap<DrumType, DrumMeasurePart>();
}
