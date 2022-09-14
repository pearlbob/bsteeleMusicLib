import 'dart:collection';

import 'package:bsteeleMusicLib/util/util.dart';

enum DrumSubBeatEnum {
  subBeat,
  subBeatE,
  subBeatAnd,
  subBeatAndA,
}

final drumSubBeatsPerBeat = DrumSubBeatEnum.values.length;
const maxDrumBeatsPerBar = 6; //  fixme eventually
int beatsLimit(int value) => Util.intLimit(value, 2, maxDrumBeatsPerBar);
const List<String> _drumShortSubBeatNames = <String>['', 'e', 'and', 'a'];

String drumShortSubBeatName(DrumSubBeatEnum drumSubBeatEnum) {
  return _drumShortSubBeatNames[drumSubBeatEnum.index];
}

enum DrumTypeEnum { closedHighHat, openHighHat, snare, kick, bass }

/// Descriptor of a single drum in the measure.

class DrumPart implements Comparable<DrumPart> {
  DrumPart(this._drumType, {required beats})
      : _beats = beatsLimit(beats),
        _beatSelection = List.filled(beats * drumSubBeatsPerBeat, false, growable: false) {
    assert(beats >= 2);
    assert(beats <= maxDrumBeatsPerBar);
  }

  List<double> timings(double t0, int bpm) {
    List<double> ret = [];
    double offsetPeriod = 60.0 / (bpm * drumSubBeatsPerBeat);
    if (bpm > 0) {
      for (var beat = 0; beat < beats; beat++) {
        for (var subBeat in DrumSubBeatEnum.values) {
          if (beatSelection(beat, subBeat)) {
            ret.add(t0 + _offset(beat, subBeat) * offsetPeriod);
          }
        }
      }
    }
    return ret;
  }

  /// Count from zero
  bool beatSelection(
      int beat, //  counts from 0!
      DrumSubBeatEnum subBeat) {
    assert(beat >= 0);
    assert(beat < beats);
    return _beatSelection[_offset(beat, subBeat)];
  }

  void setBeatSelection(
      int beat, //  counts from 0!
      DrumSubBeatEnum subBeat,
      bool b) {
    assert(beat >= 0);
    assert(beat < beats);
    _beatSelection[_offset(beat, subBeat)] = b;
  }

  bool get isEmpty {
    for (var beat = 0; beat < beats; beat++) {
      for (var subBeat in DrumSubBeatEnum.values) {
        if (beatSelection(beat, subBeat)) {
          return false;
        }
      }
    }
    return true;
  }

  int get beatCount {
    int ret = 0;
    for (var beat = 0; beat < beats; beat++) {
      for (var subBeat in DrumSubBeatEnum.values) {
        if (beatSelection(beat, subBeat)) {
          ret++;
        }
      }
    }
    return ret;
  }

  void addBeat(int beat, //  counts from 0!
      {DrumSubBeatEnum subBeat = DrumSubBeatEnum.subBeat}) {
    setBeatSelection(beat, subBeat, true);
  }

  void removeBeat(int beat, //  counts from 0!
      {DrumSubBeatEnum subBeat = DrumSubBeatEnum.subBeat}) {
    setBeatSelection(beat, subBeat, false);
  }

  @override
  String toString() {
    var sb = StringBuffer();
    var first = true;
    for (var beat = 0; beat < beats; beat++) {
      for (var subBeat in DrumSubBeatEnum.values) {
        if (beatSelection(beat, subBeat)) {
          if (first) {
            first = false;
          } else {
            sb.write(', ');
          }
          //  beats count from 0!
          sb.write('${beat + 1}${_drumShortSubBeatNames[subBeat.index]}');
        }
      }
    }
    return 'DrumPart{${_drumType.name}, beats: $beats, selection: ${sb.toString()} }  ';
  }

  @override
  int compareTo(DrumPart other) {
    if (identical(this, other)) return 0;

    int ret = other.drumType.index - drumType.index;
    if (ret != 0) return ret < 0 ? -1 : 1;
    if (beats != other.beats) {
      //  how does this happen?
      return beats < other.beats ? -1 : 1;
    }

    for (var beat = 0; beat < beats; beat++) {
      for (var subBeat in DrumSubBeatEnum.values) {
        int offset = _offset(beat, subBeat);
        if (_beatSelection[offset]) {
          if (!other._beatSelection[offset]) {
            return -1;
          }
        } else {
          if (other._beatSelection[offset]) {
            return 1;
          }
        }
      }
    }
    return 0;
  }

  late final List<bool> _beatSelection;

  int _offset(int beat, DrumSubBeatEnum drumSubBeatEnum) => beat * drumSubBeatsPerBeat + drumSubBeatEnum.index;

  set beats(int value) => _beats = Util.intLimit(value, 2, maxDrumBeatsPerBar);

  int get beats => _beats;
  int _beats = 4; //  default

  DrumTypeEnum get drumType => _drumType;
  final DrumTypeEnum _drumType;
}

/// Descriptor of the drums to be played for the given measure and
/// likely subsequent measures.
class DrumParts //  fixme: name confusion with song chord Measure class
    implements
        Comparable<DrumParts> {
  DrumParts() {
    for (var drumType in DrumTypeEnum.values) {
      addPart(DrumPart(drumType, beats: maxDrumBeatsPerBar));
    }
  }

  /// Set an individual drum's part.
  void addPart(DrumPart part) {
    _parts[part.drumType] = part;
  }

  void removePart(DrumPart part) {
    _parts.remove(part.drumType);
  }

  DrumPart? at(DrumTypeEnum drumType) {
    return _parts[drumType];
  }

  int get length => _parts.keys.length;

  bool? isSilent() {
    if (_parts.isEmpty) {
      return true;
    }
    for (var part in _parts.keys) {
      if (!(_parts[part]?.isEmpty ?? true)) {
        return false;
      }
    }
    return true;
  }

  @override
  String toString() {
    var sb = StringBuffer();
    var first = true;
    for (var type in _parts.keys) {
      var part = _parts[type]!;
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
  int compareTo(DrumParts other) {
    if (identical(this, other)) return 0;
    for (var type in _parts.keys) {
      var thisPart = _parts[type];
      assert(thisPart != null);
      var otherPart = other._parts[type];
      if (otherPart == null) return -1;
      int ret = thisPart!.compareTo(otherPart);
      if (ret != 0) return ret;
    }
    return 0;
  }

  Iterable<DrumPart> get parts {
    return _parts.values;
  }

  set volume(double value) {
    assert(value >= 0);
    assert(value <= 1.0);
    _volume = value > 1.0 ? 1.0 : (value < 0 ? 0 : value);
  }

  set beats(int value) {
    _beats = Util.intLimit(value, 2, maxDrumBeatsPerBar);
    for (var key in _parts.keys) {
      _parts[key]!.beats = beats;
    }
  }

  int get beats => _beats;
  int _beats = 4; //  default

  double get volume => _volume;
  double _volume = 1.0;
  final HashMap<DrumTypeEnum, DrumPart> _parts = HashMap<DrumTypeEnum, DrumPart>();
}
