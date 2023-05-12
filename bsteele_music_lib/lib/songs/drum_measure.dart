import 'dart:collection';
import 'dart:convert';

import '../app_logger.dart';
import '../util/util.dart';
import 'song.dart';

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

/// Map from beats counting from 1 to counting from 0
//  Must be in order!
enum DrumBeat {
  beat1,
  beat2,
  beat3,
  beat4,
  beat5,
  beat6;
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

  List<double> timings(final double t0, final int bpm, final int beats) {
    List<double> ret = [];
    double offsetPeriod = 60.0 / (bpm * drumSubBeatsPerBeat);
    if (bpm > 0) {
      for (var i = 0; i < beats; i++) {
        var beat = DrumBeat.values[i];
        for (var subBeat in DrumSubBeatEnum.values) {
          if (beatSelection(beat, subBeat)) {
            ret.add(t0 + _offset(beat.index, subBeat) * offsetPeriod);
          }
        }
      }
    }
    return ret;
  }

  /// Count from zero
  bool beatSelection(final DrumBeat beat, DrumSubBeatEnum subBeat) {
    return _beatSelection[_offset(beat.index, subBeat)];
  }

  void setBeatSelection(final DrumBeat beat, DrumSubBeatEnum subBeat, bool b) {
    _beatSelection[_offset(beat.index, subBeat)] = b;
  }

  bool get isEmpty {
    for (var beat in DrumBeat.values) {
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
    for (var beat in DrumBeat.values) {
      for (var subBeat in DrumSubBeatEnum.values) {
        if (beatSelection(beat, subBeat)) {
          ret++;
        }
      }
    }
    return ret;
  }

  void addBeat(final DrumBeat beat, {DrumSubBeatEnum subBeat = DrumSubBeatEnum.subBeat}) {
    setBeatSelection(beat, subBeat, true);
  }

  void removeBeat(final DrumBeat beat, {DrumSubBeatEnum subBeat = DrumSubBeatEnum.subBeat}) {
    setBeatSelection(beat, subBeat, false);
  }

  @override
  String toString() {
    var sb = StringBuffer();
    for (var beat in DrumBeat.values) {
      for (var subBeat in DrumSubBeatEnum.values) {
        if (beatSelection(beat, subBeat)) {
          //  beats count from 0!
          sb.write(' ${beat.index + 1}${_drumShortSubBeatNames[subBeat.index]}');
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
        var ret = DrumPart(drumType, beats: beats);
        for (var beat in selections) {
          ret.setBeatSelection(DrumBeat.values[beat ~/ DrumSubBeatEnum.values.length],
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
    hasChanged = false; //  initialization does not count as a change
  }

  DrumParts copyWith() {
    List<DrumPart> copyParts = [];
    for (var part in parts) {
      copyParts.add(part.copyWith());
    }
    return DrumParts(name: name, beats: beats, parts: copyParts);
  }

  clear() {
    if (parts.isNotEmpty) {
      hasChanged = true;
      for (var part in parts) {
        part.clear();
      }
    }
  }

  /// Set an individual drum's part.
  DrumPart addPart(DrumPart part) {
    if (_parts[part.drumType] != part) {
      hasChanged = true;
      _parts[part.drumType] = part;
    }
    return part;
  }

  void removePart(DrumPart part) {
    if (_parts.keys.contains(part.drumType)) {
      hasChanged = true;
      _parts.remove(part.drumType);
    }
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
    sb.write('}');
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
      var otherPart = other._parts[type];

      //  empty and null parts match
      if (otherPart == null || otherPart.isEmpty) {
        return (thisPart?.isEmpty ?? true) ? 0 : -1;
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
            _volume == other._volume
        //  doesn't cope with matching empty part with a null part
        //&& deepUnorderedCollectionEquality.equals(_parts.keys, other._parts.keys)
        )) {
      return false;
    }

    //  see that the parts match.  Note: a null part should match an empty part
    for (var key in _parts.keys) {
      var part = _parts[key];
      var otherPart = other._parts[key];
      if ((part == null || part.isEmpty) && (otherPart == null || otherPart.isEmpty)) {
        continue;
      }
      if (part != otherPart) {
        return false;
      }
    }

    return true;
  }

  @override
  int get hashCode => name.hashCode ^ _beats.hashCode ^ _volume.hashCode ^ _parts.hashCode;

  set beats(int value) {
    var beats = Util.intLimit(value, 2, maxDrumBeatsPerBar);
    if (_beats != beats) {
      _beats = beats;
      hasChanged = true;
      for (var key in _parts.keys) {
        _parts[key]!.beats = beats;
      }
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

  bool hasChanged = false;

  final HashMap<DrumTypeEnum, DrumPart> _parts = HashMap();
}

/// system metadata registry that is a set of id metadata
class DrumPartsList {
  static final DrumPartsList _singleton = DrumPartsList._internal();

  factory DrumPartsList() {
    return _singleton;
  }

  DrumPartsList._internal();

  static const defaultName = 'Default';
  static const fileExtension = '.songdrums';

  void add(DrumParts drumParts) {
    _drumPartsMap[drumParts.name] = drumParts;
  }

  addDefaults() {
    for (var drumPart in [
      //  minimum default entries
      DrumParts(name: DrumPartsList.defaultName, beats: 6, parts: [
        DrumPart(DrumTypeEnum.closedHighHat, beats: 6)
          ..addBeat(DrumBeat.beat1)
          ..addBeat(DrumBeat.beat3)
          ..addBeat(DrumBeat.beat5),
        DrumPart(DrumTypeEnum.snare, beats: 6)
          ..addBeat(DrumBeat.beat2)
          ..addBeat(DrumBeat.beat4)
          ..addBeat(DrumBeat.beat6),
      ]),
      DrumParts(name: '${DrumPartsList.defaultName}2', beats: 2, parts: [
        DrumPart(DrumTypeEnum.closedHighHat, beats: 2)..addBeat(DrumBeat.beat1),
        DrumPart(DrumTypeEnum.snare, beats: 2)..addBeat(DrumBeat.beat2),
      ]),
      DrumParts(name: '${DrumPartsList.defaultName}3', beats: 3, parts: [
        DrumPart(DrumTypeEnum.closedHighHat, beats: 3)
          ..addBeat(DrumBeat.beat2)
          ..addBeat(DrumBeat.beat3),
        DrumPart(DrumTypeEnum.snare, beats: 3)..addBeat(DrumBeat.beat1),
      ]),
      DrumParts(name: '${DrumPartsList.defaultName}4', beats: 4, parts: [
        DrumPart(DrumTypeEnum.closedHighHat, beats: 4)
          ..addBeat(DrumBeat.beat1)
          ..addBeat(DrumBeat.beat3),
        DrumPart(DrumTypeEnum.snare, beats: 4)
          ..addBeat(DrumBeat.beat2)
          ..addBeat(DrumBeat.beat4),
      ]),
      DrumParts(name: '${DrumPartsList.defaultName}6', beats: 6, parts: [
        DrumPart(DrumTypeEnum.closedHighHat, beats: 6)
          ..addBeat(DrumBeat.beat1)
          ..addBeat(DrumBeat.beat3)
          ..addBeat(DrumBeat.beat5),
        DrumPart(DrumTypeEnum.snare, beats: 6)
          ..addBeat(DrumBeat.beat2)
          ..addBeat(DrumBeat.beat4)
          ..addBeat(DrumBeat.beat6),
      ]),
    ]) {
      if (!_drumPartsMap.keys.contains(drumPart.name)) {
        _drumPartsMap[drumPart.name] = drumPart;
      }
    }
  }

  DrumParts? findByName(final String name) {
    return _drumPartsMap[name];
  }

  void remove(DrumParts drumParts) {
    _drumPartsMap.remove(drumParts.name);
  }

  DrumParts? songMatch(final Song song) {
    logger.v('songMatch($song): ${_songIdToDrumPartsNameMap[song.songId.toString()]}  '
        '${_drumPartsMap[_songIdToDrumPartsNameMap[song.songId.toString()]]}');
    return _drumPartsMap[_songIdToDrumPartsNameMap[song.songId.toString()]];
  }

  match(final Song song, DrumParts? drumParts) {
    if (drumParts != null) {
      assert(_drumPartsMap.values.contains(drumParts));
      _songIdToDrumPartsNameMap[song.songId.toString()] = drumParts.name;
    }
  }

  removeMatch(Song song) {
    _songIdToDrumPartsNameMap.remove(song.songId.toString());
  }

  DrumParts? operator [](Song song) {
    var name = _songIdToDrumPartsNameMap[song.songId.toString()];
    if (name != null) {
      return _drumPartsMap[name];
    }
    //  map to default based on beats
    return _drumPartsMap['$defaultName${song.timeSignature.beatsPerBar}'];
  }

  /// clear all drum parts
  void clear() {
    _drumPartsMap.clear();
    _songIdToDrumPartsNameMap.clear();
  }

  bool get isEmpty => _drumPartsMap.isEmpty;

  bool get isNotEmpty => _drumPartsMap.isNotEmpty;

  int get length => _drumPartsMap.keys.length;

  @override
  String toString() {
    return '{${_drumPartsMap.keys.length}: ${_drumPartsMap.keys} }';
  }

  String toJson({final bool asObject = true}) {
    StringBuffer partsBuffer = StringBuffer();
    bool first = true;
    for (var dp in drumParts) {
      if (first) {
        first = false;
      } else {
        partsBuffer.write(',\n');
      }
      partsBuffer.write(dp.toJson());
    }

    StringBuffer matchesBuffer = StringBuffer();
    first = true;
    for (var songKey in SplayTreeSet<String>()..addAll(_songIdToDrumPartsNameMap.keys)) {
      var drumPartsName = _songIdToDrumPartsNameMap[songKey];
      assert(drumPartsName != null);
      if (first) {
        first = false;
      } else {
        matchesBuffer.write(',\n');
      }
      matchesBuffer.write(' ${jsonEncode(songKey)}: ${jsonEncode(drumPartsName)}');
    }
    return '${asObject ? '{ ' : ''}'
        '"drumPartsList" : [${partsBuffer.toString()}],'
        '"matchesList" : {${matchesBuffer.toString()}}'
        '${asObject ? ' }' : ''}';
  }

  void fromJson(String jsonString) {
    try {
      var decoded = json.decode(jsonString);
      if (decoded != null && decoded is Map) {
        fromJsonMap(decoded);
      }
    } catch (e) {
      //
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
        case 'matchesList':
          var jsonMatches = decoded[decodedKey];
          for (var key in jsonMatches.keys) {
            logger.v('$key: ${jsonMatches[key]}');
            _songIdToDrumPartsNameMap[key] = jsonMatches[key];
          }
          break;
        default:
          logger.w('unknown $runtimeType.fromJsonMap: "$decodedKey"');
          break;
      }
    }
  }

  final HashMap<String, String> _songIdToDrumPartsNameMap = HashMap();

  SplayTreeSet<DrumParts> get drumParts => SplayTreeSet<DrumParts>()..addAll(_drumPartsMap.values);

  final HashMap<String, DrumParts> _drumPartsMap = HashMap();
}
