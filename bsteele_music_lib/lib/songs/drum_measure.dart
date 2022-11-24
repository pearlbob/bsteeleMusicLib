import 'dart:collection';
import 'dart:convert';

import 'package:bsteeleMusicLib/util/util.dart';

import '../app_logger.dart';

enum DrumSubBeatEnum {
  subBeat,
  subBeatE,
  subBeatAnd,
  subBeatAndA,
}

final drumSubBeatsPerBeat = DrumSubBeatEnum.values.length;
const maxDrumBeatsPerBar = 6; //  fixme eventually
int beatsLimit(int value) => Util.intLimit(value, 2, maxDrumBeatsPerBar);
const List<String> _drumShortSubBeatNames = <String>['', 'e', '&', 'a'];
const JsonDecoder _jsonDecoder = JsonDecoder();

String drumShortSubBeatName(DrumSubBeatEnum drumSubBeatEnum) {
  return _drumShortSubBeatNames[drumSubBeatEnum.index];
}

enum DrumTypeEnum implements Comparable<DrumTypeEnum> {
  closedHighHat,
  openHighHat,
  snare,
  kick,
  bass;

  @override
  int compareTo(DrumTypeEnum other) {
    return index.compareTo(other.index);
  }
}

/// Descriptor of a single drum in the measure.

class DrumPart implements Comparable<DrumPart> {
  DrumPart(this._drumType, {required beats})
      : _beats = beatsLimit(beats),
        _beatSelection = List.filled(maxDrumBeatsPerBar * drumSubBeatsPerBeat, false, growable: false) {
    assert(beats >= 2);
    assert(beats <= maxDrumBeatsPerBar);
  }

  DrumPart copyWith() {
    var ret = DrumPart(_drumType, beats: _beats);
    for (var s = 0; s < _beatSelection.length; s++) {
      if (_beatSelection[s]) {
        ret._beatSelection[s] = true;
      }
    }
    return ret;
  }

  clear() {
    for (var s = 0; s < _beatSelection.length; s++) {
      _beatSelection[s] = false;
    }
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
    for (var beat = 0; beat < beats; beat++) {
      for (var subBeat in DrumSubBeatEnum.values) {
        if (beatSelection(beat, subBeat)) {
          //  beats count from 0!
          sb.write(' ${beat + 1}${_drumShortSubBeatNames[subBeat.index]}');
        }
      }
    }
    return '${_drumType.name}:${sb.toString()}';
  }

  String toJson() {
    StringBuffer sb = StringBuffer();
    sb.write('{');
    sb.write(' "drumType": "${drumType.name}"');
    sb.write(', "beats": $_beats');
    sb.write(', "selection": [ ');
    bool first = true;
    for (int i = 0; i < _beatSelection.length; i++) {
      if (_beatSelection[i]) {
        if (first) {
          first = false;
        } else {
          sb.write(', ');
        }
        sb.write(i);
      }
    }
    sb.write(' ]');
    sb.write('}');

    return sb.toString();
  }

  static DrumPart? fromJson(String jsonString) {
    return fromJsonDecoderConvert(_jsonDecoder.convert(jsonString));
  }

  static DrumPart? fromJsonDecoderConvert(dynamic json) {
    if (json is Map) {
      DrumTypeEnum? drumType;
      var beats = 0;
      List<int> selections = [];
      for (String name in json.keys) {
        switch (name) {
          case 'drumType':
            logger.v('type: ${json[name]}');
            drumType = Util.enumFromString<DrumTypeEnum>(json[name], DrumTypeEnum.values);
            break;
          case 'beats':
            beats = json[name];
            break;
          case 'selection':
            logger.v('selections: ${json[name]}');
            for (var v in json[name]) {
              selections.add(v as int);
            }
            break;
        }
      }
      if (drumType != null && beats > 0) {
        // logger.i(
        //     'selections: $selections'
        // );
        var ret = DrumPart(drumType, beats: beats);
        for (var beat in selections) {
          ret.setBeatSelection(beat ~/ DrumSubBeatEnum.values.length,
              DrumSubBeatEnum.values[beat % DrumSubBeatEnum.values.length], true);
        }
        return ret;
      }
    }
    return null;
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrumPart &&
          runtimeType == other.runtimeType &&
          deepCollectionEquality.equals(_beatSelection, other._beatSelection) &&
          _beats == other._beats &&
          _drumType == other._drumType;

  @override
  int get hashCode => Object.hash(_beats, _drumType, _beatSelection);

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
class DrumParts implements Comparable<DrumParts> {
  DrumParts({this.name = 'unknown', beats = 4, List<DrumPart>? parts}) : _beats = beats {
    for (var part in parts ?? []) {
      addPart(part);
    }
  }

  DrumParts copyWith() {
    List<DrumPart> copyParts = [];
    for (var part in parts) {
      copyParts.add(part.copyWith());
    }
    return DrumParts(name: name, beats: beats, parts: copyParts);
  }

  clear() {
    for (var part in parts) {
      part.clear();
    }
  }

  /// Set an individual drum's part.
  DrumPart addPart(DrumPart part) {
    _parts[part.drumType] = part;
    return part;
  }

  void removePart(DrumPart part) {
    _parts.remove(part.drumType);
  }

  DrumPart at(DrumTypeEnum drumType) {
    return _parts[drumType] ?? addPart(DrumPart(drumType, beats: beats));
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
    return '$name:$beats: ${partsToString()}';
  }

  String partsToString() {
    var sb = StringBuffer();
    var first = true;
    for (var type in _parts.keys) {
      var part = _parts[type]!;
      if (part.isEmpty) {
        continue;
      }
      if (first) {
        first = false;
      } else {
        sb.write(', ');
      }
      sb.write(part.toString());
    }

    return sb.toString();
  }

  String toJson() {
    StringBuffer sb = StringBuffer();

    sb.write('{\n');
    sb.write(' "name": ${jsonEncode(name)},');
    sb.write(' "beats": $_beats,');
    sb.write(' "subBeats": $subBeats,');
    sb.write(' "volume": $_volume,');
    sb.write('\n "parts": [');
    bool first = true;
    for (var key in SplayTreeSet<DrumTypeEnum>()..addAll(_parts.keys)) {
      var part = _parts[key]!;
      if (part.isEmpty) {
        continue;
      }
      if (first) {
        first = false;
      } else {
        sb.write(',\n   ');
      }
      sb.write(part.toJson());
    }
    sb.write(']\n');
    sb.write('}\n');
    return sb.toString();
  }

  static DrumParts? fromJson(String jsonString) {
    dynamic json = _jsonDecoder.convert(jsonString);
    if (json is Map) {
      return fromJsonMap(json);
    }
    return null;
  }

  static DrumParts? fromJsonMap(Map json) {
    var drumPartsName = 'unknown';
    var beats = 0;
    var subBeats = 0;
    var volume = 0.0;
    HashMap<DrumTypeEnum, DrumPart> parts = HashMap();
    for (String name in json.keys) {
      switch (name) {
        case 'name':
          drumPartsName = json[name];
          break;
        case 'beats':
          beats = json[name];
          break;
        case 'subBeats':
          subBeats = json[name];
          break;
        case 'volume':
          volume = json[name];
          break;
        case 'parts':
          logger.v('parts: ${json[name].runtimeType} ${json[name]}');
          for (var jsonPart in json[name]) {
            logger.v('json part: ${jsonPart.runtimeType} $jsonPart');
            var part = DrumPart.fromJsonDecoderConvert(jsonPart);
            if (part != null) {
              parts[part.drumType] = part;
            }
          }
          break;
        default:
          logger.w('bad json name: $name');
          break;
      }
    }
    if (beats > 0 && subBeats > 0) {
      var ret = DrumParts();
      ret.name = drumPartsName;
      ret.beats = beats;
      ret.subBeats = subBeats;
      ret.volume = volume;
      for (var key in parts.keys) {
        ret._parts[key] = parts[key]!;
      }
      return ret;
    }
    return null;
  }

  @override
  int compareTo(DrumParts other) {
    if (identical(this, other)) {
      return 0;
    }
    int ret = name.compareTo(other.name);
    if (ret != 0) {
      return ret;
    }
    for (var type in _parts.keys) {
      var thisPart = _parts[type];
      assert(thisPart != null);
      var otherPart = other._parts[type];
      if (otherPart == null) {
        return -1;
      }
      int ret = thisPart!.compareTo(otherPart);
      if (ret != 0) {
        return ret;
      }
    }
    return 0;
  }

  Iterable<DrumPart> get parts {
    return _parts.values;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (!(other is DrumParts &&
        runtimeType == other.runtimeType &&
        name == other.name &&
        _beats == other._beats &&
        _volume == other._volume &&
        deepUnorderedCollectionEquality.equals(_parts.keys, other._parts.keys))) {
      return false;
    }

    //  fixme: why do empty parts kill deepUnorderedCollectionEquality.equals() test for empty maps?
    for (var key in _parts.keys) {
      if (_parts[key] != other._parts[key]) {
        return false;
      }
    }

    return true;
  }

  @override
  int get hashCode => name.hashCode ^ _beats.hashCode ^ _volume.hashCode ^ _parts.hashCode;

  set beats(int value) {
    _beats = Util.intLimit(value, 2, maxDrumBeatsPerBar);
    for (var key in _parts.keys) {
      _parts[key]!.beats = beats;
    }
  }

  String name;

  int get beats => _beats;
  int _beats = 4; //  default

  int subBeats = drumSubBeatsPerBeat;

  set volume(double value) {
    assert(value >= 0);
    assert(value <= 1.0);
    _volume = value > 1.0 ? 1.0 : (value < 0 ? 0 : value);
  }

  double get volume => _volume;
  double _volume = 1.0;

  final HashMap<DrumTypeEnum, DrumPart> _parts = HashMap();
}

/// system metadata registry that is a set of id metadata
class DrumPartsList {
  static final DrumPartsList _singleton = DrumPartsList._internal();

  factory DrumPartsList() {
    return _singleton;
  }

  DrumPartsList._internal();

  void add(DrumParts drumParts) {
    try {
      var original = _singleton._drumPartsList.firstWhere((dp) => dp.name == drumParts.name);
      _singleton._drumPartsList.remove(original);
    } catch (e) {
      //
      logger.v('e: $e');
    }
    _singleton._drumPartsList.add(drumParts);
    logger.v(' _singleton._drumPartsList.add(): ${_singleton._drumPartsList}');
  }

  void remove(DrumParts drumParts) {
    try {
      var original = _singleton._drumPartsList.firstWhere((dp) => dp.name == drumParts.name);
      _singleton._drumPartsList.remove(original);
    } catch (e) {
      //
    }
  }

  /// clear all metadata.
  void clear() {
    _singleton._drumPartsList.clear();
  }

  bool get isEmpty => _drumPartsList.isEmpty;

  bool get isNotEmpty => _drumPartsList.isNotEmpty;

  int get length => _drumPartsList.length;

  @override
  String toString() {
    return '{${_drumPartsList.length}: ${_drumPartsList.map((e) => e.toString())} }';
  }

  String toJson({final bool asObject = true}) {
    StringBuffer sb = StringBuffer();
    bool first = true;
    for (var drumParts in _singleton._drumPartsList) {
      if (first) {
        first = false;
      } else {
        sb.write(',\n');
      }
      sb.write(drumParts.toJson());
    }
    return '${asObject ? '{ ' : ''}"drumPartsList" : [${sb.toString()}]${asObject ? ' }' : ''}';
  }

  void fromJson(String jsonString) {
    var decoded = json.decode(jsonString);
    if (decoded != null && decoded is Map) {
      fromJsonMap(decoded);
    }
  }

  void fromJsonMap(Map decoded) {
    clear(); //  expect things to go well
    for (var decodedKey in decoded.keys) {
      switch (decodedKey) {
        case 'drumPartsList':
          for (var partMap in decoded[decodedKey]) {
            var parts = DrumParts.fromJsonMap(partMap);
            logger.d('\t$parts');
            if (parts != null) {
              add(parts);
            }
          }
          break;
        default:
          logger.w('unknown $runtimeType.fromJsonMap: "$decodedKey"');
          break;
      }
    }
  }

  SplayTreeSet<DrumParts> get drumParts => _drumPartsList;

  final SplayTreeSet<DrumParts> _drumPartsList = SplayTreeSet((e1, e2) =>
      //  unique by name only
      e1.name.compareTo(e2.name));
}
