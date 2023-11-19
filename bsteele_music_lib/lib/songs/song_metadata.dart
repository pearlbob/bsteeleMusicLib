import 'dart:collection';
import 'dart:convert';

import 'package:logger/logger.dart';

import '../app_logger.dart';
import '../util/util.dart';
import 'song.dart';
import 'song_base.dart';
import 'song_performance.dart';

const _logRepair = Level.debug;

enum SongMetadataGeneratedValue {
  decade,
  year,
  beats,
  user,
  key,
  ;

  static bool isGenerated(NameValue nameValue) {
    var name = Util.firstToLower(nameValue.name);
    for (var genValue in SongMetadataGeneratedValue.values) {
      if (name == genValue.name) {
        return true;
      }
    }
    return false;
  }
}

/// name and value pair
class NameValue implements Comparable<NameValue> {
  NameValue(String name, String value)
      : _name = Util.firstToUpper(name),
        _value = Util.firstToUpper(value);

  @override
  String toString() {
    return '$name:$value';
  }

  /// will return empty name value on parse failure
  static NameValue parse(String s) {
    RegExpMatch? m = _nameValueRegexp.firstMatch(s);
    if (m == null) {
      return NameValue('', '');
    }
    return NameValue(m.group(1) ?? ' ', m.group(2) ?? '');
  }

  String toJson() {
    return '{"name":${jsonEncode(name)},"value":${jsonEncode(value)}}';
  }

  @override
  int compareTo(NameValue other) {
    int ret = _name.compareTo(other._name);
    if (ret != 0) {
      return ret;
    }
    ret = _value.compareTo(other._value);
    if (ret != 0) {
      return ret;
    }
    return 0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NameValue && runtimeType == other.runtimeType && _name == other._name && _value == other._value;

  @override
  int get hashCode => _name.hashCode ^ _value.hashCode;

  String get name => _name;
  final String _name;

  String get value => _value;
  final String _value;
}

enum NameValueType {
  value,
  noValue,
  anyValue;
}

class NameValueMatcher extends NameValue {
  NameValueMatcher(super.name, super.value, {NameValueType type = NameValueType.value}) : _type = type;

  NameValueMatcher.value(NameValue nameValue) : this(nameValue.name, nameValue.value, type: NameValueType.value);

  NameValueMatcher.noValue(String name) : this(name, '', type: NameValueType.noValue);

  NameValueMatcher.anyValue(String name) : this(name, '', type: NameValueType.anyValue);

  bool testAll(final Iterable<NameValue> nameValues) {
    switch (type) {
      case NameValueType.value:
      //  name and value match required
        for (var nv in nameValues) {
          if (nv.compareTo(this) == 0) {
            return true;
          }
        }
        break;
      case NameValueType.noValue:
      //  name cannot match
        for (var nv in nameValues) {
          if (nv.name == name) {
            return false;
          }
        }
        return true;
      case NameValueType.anyValue:
      //  any name match
        for (var nv in nameValues) {
          if (nv.name == name) {
            return true;
          }
        }
        break;
    }
    return false;
  }

  bool test(final NameValue nameValue) {
    switch (type) {
      case NameValueType.value:
      //  name and value match required
        return nameValue.compareTo(this) == 0;
      case NameValueType.noValue:
        //  name cannot match
        return nameValue.name != name;
      case NameValueType.anyValue:
        //  any name match
        return nameValue.name == name;
    }
  }

  @override
  String toString() {
    switch (_type) {
      case NameValueType.noValue:
        return 'no $name';
      case NameValueType.anyValue:
        return 'any $name';
      default:
        return super.toString();
    }
  }

  NameValueType get type => _type;
  final NameValueType _type;
}

//  a filter for name values that match the initial given values
class NameValueFilter {
  NameValueFilter(final Iterable<NameValueMatcher> nameValueMatchers) {
    Map<String, SplayTreeSet<NameValueMatcher>> map = {};
    for (var nv in nameValueMatchers) {
      var mappedList = map[nv.name];
      mappedList ??= SplayTreeSet();
      mappedList.add(nv); //  fixme: deal with nameValue changes?
      map[nv.name] = mappedList;
    }
    filterMap = map;
  }

  bool isOr(final NameValue nameValue) {
    var values = filterMap[nameValue.name];
    return values != null && values.length > 1 && test(nameValue);
  }

  //  sort all the given name value pairs
  SplayTreeSet<NameValueMatcher> matchers() {
    SplayTreeSet<NameValueMatcher> ret = SplayTreeSet();
    for (var matchers in filterMap.values) {
      ret.addAll(matchers);
    }
    return ret;
  }

  bool testAll(final Iterable<NameValue>? nameValues) {
    if (nameValues == null || nameValues.isEmpty) {
      return false;
    }

    for (var key in filterMap.keys) {
      SplayTreeSet<NameValueMatcher>? matchers = filterMap[key];
      if (matchers != null) {
        var ret = false;
        for (var matcher in matchers) {
          ret |= matcher.testAll(nameValues);
        }
        //  or matchers with same name
        if (ret == false) {
          return false;
        }
      }
    }

    return true;
  }

  bool test(final NameValue nameValue) {
    SplayTreeSet<NameValueMatcher>? matchers = filterMap[nameValue.name];
    if (matchers == null) {
      return false;
    }

    if (matchers.length == 1) {
      //  an AND term
      return matchers.first.test(nameValue);
    }

    //  an OR term
    for (var matcher in matchers) {
      if (matcher.test(nameValue)) {
        return true;
      }
    }

    return false;
  }

  late final Map<String, SplayTreeSet<NameValueMatcher>> filterMap;
}

/// name value pairs attached to a song id
class SongIdMetadata implements Comparable<SongIdMetadata> {
  SongIdMetadata(this._id, {Iterable<NameValue>? metadata}) {
    if (metadata != null) {
      for (NameValue nameValue in metadata) {
        add(nameValue);
      }
    }
  }

  bool add(NameValue nameValue) {
    if (!_nameValues.contains(nameValue)) {
      _nameValues.add(nameValue);
      return true;
    }
    return false;
  }

  bool remove(NameValue nameValue) {
    return _nameValues.remove(nameValue);
  }

  Iterable<NameValue> where(bool Function(NameValue nameValue) matcher) {
    return nameValues.where(matcher);
  }

  @override
  int compareTo(SongIdMetadata other) {
    int ret = _id.compareTo(other._id);
    if (ret != 0) {
      return ret;
    }
    return 0; //  since id's are meant to be unique
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    bool first = true;
    for (NameValue nv in _nameValues) {
      if (first) {
        first = false;
        sb.write('\n\t');
      } else {
        sb.write(',\n\t');
      }
      sb.write(nv.toString());
    }
    sb.write('\n\t');
    return '{ "id": "$id", "metadata": [$sb] }';
  }

  String toJson() {
    StringBuffer sb = StringBuffer();
    bool first = true;
    for (NameValue nv in _nameValues) {
      if (!SongMetadataGeneratedValue.isGenerated(nv)) {
        if (first) {
          first = false;
        } else {
          sb.write(',');
        }
        sb.write(nv.toJson());
      }
    }
    return '{"id":${jsonEncode(id)},"metadata":[${sb.toString()}]}';
  }

  String toJsonAt(NameValue nameValue) {
    StringBuffer sb = StringBuffer();
    bool first = true;
    for (NameValue nv in _nameValues) {
      if (nv == nameValue) {
        if (first) {
          first = false;
        } else {
          sb.write(',');
        }
        sb.write(nv.toJson());
      }
    }
    return '{"id":${jsonEncode(id)},"metadata":[${sb.toString()}]}';
  }

  bool get hasNonGeneratedNameValues {
    for (NameValue nv in _nameValues) {
      if (!SongMetadataGeneratedValue.isGenerated(nv)) {
        return true;
      }
    }
    return false;
  }

  bool get isEmpty => _nameValues.isEmpty;

  bool get isNotEmpty => _nameValues.isNotEmpty;

  bool contains(NameValue nameValue) => _nameValues.contains(nameValue);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongIdMetadata &&
          runtimeType == other.runtimeType &&
          _id == other._id &&
          _nameValues == other._nameValues;

  @override
  int get hashCode => _id.hashCode ^ _nameValues.hashCode;

  String get id => _id;
  final String _id;

  SplayTreeSet<NameValue> get nameValues => _nameValues;
  final SplayTreeSet<NameValue> _nameValues = SplayTreeSet();
}

String mapYearToDecade(int year) {
  if (year < 0) {
    year = 0;
  }
  if (year < 1940) {
    return 'prior to 1940';
  }
  if (year >= 2030) {
    return '${year ~/ 10}0\'s';
  }
  return '${(year ~/ 10) % 10}0\'s';
}

/// system metadata registry that is a set of id metadata
class SongMetadata {
  static final SongMetadata _singleton = SongMetadata._internal();

  factory SongMetadata() {
    return _singleton;
  }

  SongMetadata._internal();

  static repairSongs(SongRepair songRepair) {
    HashMap<String, Song> repairs = HashMap();
    for (var songIdMetadata in _singleton._idMetadata) {
      var newSong = songRepair.findBestSong(songIdMetadata.id);
      if (newSong == null) {
        logger.i('SongMetadata.repairSongs: missing: ${songIdMetadata.id}');
        continue;
      }

      if (songIdMetadata.id != newSong.songId.toString()) {
        repairs[songIdMetadata.id] = newSong;
        // logger.i('repair: ${songIdMetadata.id}  vs  ${newSong.songId}');
      }
    }

    //  perform the repairs
    for (var id in repairs.keys) {
      logger.log(_logRepair, 'SongMetadata.repair: "$id" to "${repairs[id]?.songId.toString()}');
      var songIdMetadata = SongMetadata.byId(id);
      assert(songIdMetadata != null);
      songIdMetadata = songIdMetadata!;
      var newSongIdMetadata = SongIdMetadata(repairs[id]!.songId.toString(), metadata: songIdMetadata.nameValues);
      logger.d(songIdMetadata.toString());
      logger.d(newSongIdMetadata.toString());
      SongMetadata.removeSongIdMetadata(songIdMetadata);
      SongMetadata.addSongIdMetadata(newSongIdMetadata);
    }
  }

  static void set(SongIdMetadata songIdMetadata) {
    if (!_singleton._idMetadata.add(songIdMetadata)) {
      //  the metadata already matches a key, so remove the old and try again
      _singleton._idMetadata.remove(songIdMetadata);
      _singleton._idMetadata.add(songIdMetadata);
      isDirty = true;
    }
  }

  static void add(SongIdMetadata songIdMetadata) {
    SongIdMetadata? value;
    if ((value = _singleton._idMetadata.lookup(songIdMetadata)) != null) {
      value!._nameValues.addAll(songIdMetadata._nameValues);
    } else {
      set(songIdMetadata);
    }
    isDirty = true;
  }

  static SongIdMetadata? songIdMetadata(final Song song) {
    return _singleton._idMetadata.lookup(SongIdMetadata(song.songId.toString()));
  }

  static SongIdMetadata? byId(final String id) {
    return _singleton._idMetadata.lookup(SongIdMetadata(id));
  }

  //  convenience method
  static void addSong(Song song, NameValue nameValue) {
    SongIdMetadata songIdMetadata = SongIdMetadata(song.songId.toString(), metadata: [nameValue]);
    add(songIdMetadata);
    isDirty = true;
  }

  //  convenience method
  static void removeFromSong(Song song, NameValue nameValue) {
    //  find the entry, if it exists
    SongIdMetadata? songIdMetadata = _singleton._idMetadata.lookup(SongIdMetadata(song.songId.toString()));
    if (songIdMetadata != null) {
      remove(songIdMetadata, nameValue);
      isDirty = true;
    }
  }

  static void remove(SongIdMetadata songIdMetadata, NameValue nameValue) {
    songIdMetadata.remove(nameValue);
    isDirty = true;
    if (songIdMetadata.isEmpty) {
      //  remove this id metadata if it was the last one
      _singleton._idMetadata.remove(songIdMetadata);
      //  fixme: generate generated values?
    }
  }

  static void removeSongIdMetadata(final SongIdMetadata songIdMetadata) {
    if (_singleton._idMetadata.contains(songIdMetadata)) {
      isDirty = true;
      _singleton._idMetadata.remove(songIdMetadata);
    }
  }

  static void addSongIdMetadata(final SongIdMetadata songIdMetadata) {
    if (!_singleton._idMetadata.contains(songIdMetadata)) {
      isDirty = true;
      _singleton._idMetadata.add(songIdMetadata);
    }
  }

  static void removeAll(NameValue nameValue) {
    _singleton._removeAll(nameValue);
  }

  void _removeAll(NameValue nameValue) {
    final SplayTreeSet<SongIdMetadata> removeSet = SplayTreeSet();
    for (var songIdMetadata in _idMetadata) {
      songIdMetadata.remove(nameValue);
      if (songIdMetadata.isEmpty) {
        removeSet.add(songIdMetadata); //  avoid concurrency problems
      }
    }
    _idMetadata.removeAll(removeSet);
    isDirty = true;
  }

  static SplayTreeSet<SongIdMetadata> match(bool Function(SongIdMetadata songIdMetadata) doesMatch,
      {SplayTreeSet<SongIdMetadata>? from}) {
    SplayTreeSet<SongIdMetadata> ret = SplayTreeSet();
    for (SongIdMetadata songIdMetadata in from ?? _singleton._idMetadata) {
      if (doesMatch(songIdMetadata)) {
        ret.add(songIdMetadata);
      }
    }
    return ret;
  }

  /// basically the and function
  static SplayTreeSet<SongIdMetadata> filterMatch(Iterable<NameValue> filters, {SplayTreeSet<SongIdMetadata>? from}) {
    SplayTreeSet<SongIdMetadata> ret = SplayTreeSet();
    if (filters.isNotEmpty) {
      for (SongIdMetadata songIdMetadata in from ?? _singleton._idMetadata) {
        bool matchedAll = true;
        for (var filter in filters) {
          if (!songIdMetadata.contains(filter)) {
            matchedAll = false;
            break;
          }
        }
        if (matchedAll) {
          ret.add(songIdMetadata);
        }
      }
    }
    return ret;
  }

  static SplayTreeSet<NameValue> songMetadata(final Song song, final String name) {
    return songMetadataAt(song.songId.toString(), name);
  }

  static SplayTreeSet<NameValue> songMetadataAt(final String id, final String name) {
    var set = where(idIs: id, nameIs: name);
    // assert(set.length == 1); fixme: why was this here?
    var ret = SplayTreeSet<NameValue>();
    for (var songIdMetadata in set) {
      for (var nameValue in songIdMetadata._nameValues) {
        if (nameValue.name == name) {
          ret.add(nameValue);
        }
      }
    }
    return ret;
  }

  static bool contains(NameValue nameValue) {
    for (SongIdMetadata idm in _singleton._idMetadata) {
      if (idm.nameValues.contains(nameValue)) {
        return true;
      }
    }
    return false;
  }

  static void generateMetadata(Iterable<Song> songs) {
    for (var song in songs) {
      generateSongMetadata(song);
    }
  }

  /// Generate a decades metadata entry from the copyright year
  static void generateSongMetadata(Song song) {
    for (var genValue in SongMetadataGeneratedValue.values) {
      final name = Util.firstToUpper(genValue.name);

      SongIdMetadata? idm = songIdMetadata(song);
      //  remove any existing decade metadata
      if (idm != null) {
        SplayTreeSet<NameValue> removals = SplayTreeSet(); //  avoid concurrent removals
        for (var nv in idm.where((nameValue) => nameValue.name.compareTo(name) == 0)) {
          removals.add(nv);
        }
        for (var nv in removals) {
          idm.remove(nv);
        }
      }

      switch (genValue) {
        case SongMetadataGeneratedValue.decade:
          //  add the decade metadata
          int year = song.getCopyrightYear();
          if (year != SongBase.defaultYear) {
            addSong(song, NameValue(name, mapYearToDecade(year)));
          }
          break;
        case SongMetadataGeneratedValue.year:
          int year = song.getCopyrightYear();
          if (year != SongBase.defaultYear) {
            addSong(song, NameValue(name, year.toString()));
          }
          break;
        case SongMetadataGeneratedValue.beats:
          addSong(song, NameValue(name, song.timeSignature.beatsPerBar.toString()));
          break;
        case SongMetadataGeneratedValue.user:
          addSong(song, NameValue(name, song.user.toString()));
          break;
        case SongMetadataGeneratedValue.key:
          addSong(song, NameValue(name, song.key.toString()));
          break;
      }
    }
  }

  static SplayTreeSet<SongIdMetadata> where(
      {String? idIsLike,
      String? nameIsLike,
      String? valueIsLike,
      String? idIs,
      String? nameIs,
      String? valueIs,
      NameValue? nameValue}) {
    //  no filters allow any id
    if (idIsLike == null &&
        nameIsLike == null &&
        valueIsLike == null &&
        idIs == null &&
        nameIs == null &&
        valueIs == null &&
        nameValue == null) {
      return _singleton._shallowCopyIdMetadata();
    }

    SplayTreeSet<SongIdMetadata> ret = SplayTreeSet();
    RegExp? idIsLikeReg;
    RegExp? nameIsLikeReg;
    RegExp? valueIsLikeReg;

    if (idIsLike != null) {
      idIsLikeReg = RegExp(idIsLike, caseSensitive: false, dotAll: true);
    }
    if (nameIsLike != null) {
      if (nameIsLike.isEmpty) {
        return ret; //  name can't be empty when used for selection
      }
      nameIsLikeReg = RegExp(nameIsLike, caseSensitive: false, dotAll: true);
    }
    if (valueIsLike != null) {
      valueIsLikeReg = RegExp(valueIsLike.isEmpty ? r'^$' : valueIsLike, caseSensitive: false, dotAll: true);
    }

    loop:
    for (SongIdMetadata idm in _singleton._idMetadata) {
      if (idIsLikeReg != null && !idIsLikeReg.hasMatch(idm._id)) {
        continue loop;
      }

      if (nameValue != null && !idm._nameValues.contains(nameValue)) {
        continue loop;
      }
      if (idIs != null && idIs != idm.id.toString()) {
        continue loop;
      }
      if (nameIs != null) {
        bool hasMatch = false;
        for (NameValue nv in idm._nameValues) {
          if (nameIs == nv._name) {
            hasMatch = true;
            break;
          }
        }
        if (!hasMatch) {
          continue loop;
        }
      }
      if (valueIs != null) {
        bool hasMatch = false;
        for (NameValue nv in idm._nameValues) {
          if (valueIs == nv.value) {
            hasMatch = true;
            break;
          }
        }
        if (!hasMatch) {
          continue loop;
        }
      }

      if (nameIsLikeReg != null) {
        if (valueIsLikeReg != null) {
          bool hasMatch = false;
          for (NameValue nv in idm._nameValues) {
            if (nameIsLikeReg.hasMatch(nv._name) && valueIsLikeReg.hasMatch(nv._value)) {
              hasMatch = true;
              break;
            }
          }
          if (!hasMatch) {
            continue loop;
          }
        } else {
          bool hasMatch = false;
          for (NameValue nv in idm._nameValues) {
            if (nameIsLikeReg.hasMatch(nv._name)) {
              hasMatch = true;
              break;
            }
          }
          if (!hasMatch) {
            continue loop;
          }
        }
      } else if (valueIsLikeReg != null) {
        bool hasMatch = false;
        for (NameValue nv in idm._nameValues) {
          if (valueIsLikeReg.hasMatch(nv._value)) {
            hasMatch = true;
            break;
          }
        }
        if (!hasMatch) {
          continue loop;
        }
      }
      ret.add(idm);
    }
    return ret;
  }

  SplayTreeSet<SongIdMetadata> _shallowCopyIdMetadata() {
    SplayTreeSet<SongIdMetadata> ret = SplayTreeSet();
    for (SongIdMetadata songIdMetadata in _idMetadata) {
      ret.add(songIdMetadata);
    }
    return ret;
  }

  static SplayTreeSet<String> namesOf(SplayTreeSet<SongIdMetadata> idMetadata) {
    SplayTreeSet<String> ret = SplayTreeSet();
    for (SongIdMetadata songIdMetadata in _singleton._idMetadata) {
      for (NameValue nameValue in songIdMetadata.nameValues) {
        ret.add(nameValue.name);
      }
    }
    return ret;
  }

  static SplayTreeSet<String> valuesOf(SplayTreeSet<SongIdMetadata> idMetadata, String name) {
    SplayTreeSet<String> ret = SplayTreeSet();
    for (SongIdMetadata songIdMetadata in _singleton._idMetadata) {
      for (NameValue nameValue in songIdMetadata.nameValues) {
        if (nameValue.name == name) {
          ret.add(nameValue.value);
        }
      }
    }
    return ret;
  }

  /// clear all metadata.
  static void clear() {
    _singleton._idMetadata.clear();
    isDirty = false;
  }

  static String toJson({Iterable<SongIdMetadata>? values}) {
    StringBuffer sb = StringBuffer();
    bool first = true;
    for (SongIdMetadata songIdMetadata in values ?? _singleton._idMetadata) {
      if (songIdMetadata.hasNonGeneratedNameValues) {
        if (first) {
          first = false;
        } else {
          sb.write(',\n');
        }
        sb.write(songIdMetadata.toJson());
      }
    }
    return '[${sb.toString()}]';
  }

  static void fromJson(String jsonString) {
    var decoded = json.decode(jsonString);
    if (decoded != null) {
      for (var item in decoded) {
        String id = '';
        for (String key in item.keys) {
          logger.d('\t${key.toString()}:');
          switch (key) {
            case 'id':
              id = item[key].toString();
              logger.d('\t\t$id');
              break;
            case 'metadata':
              for (var nv in item[key]) {
                if (nv is Map) {
                  SongMetadata.add(SongIdMetadata(id, metadata: [NameValue(nv['name'], nv['value'])]));
                }
              }
              break;
          }
        }
      }
    }
    isDirty = true;
  }

  static bool isDirty = false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongMetadata && runtimeType == other.runtimeType && _idMetadata == other._idMetadata;

  @override
  int get hashCode => _idMetadata.hashCode;

  static int get staticHashCode => _singleton.hashCode;

  static SplayTreeSet<SongIdMetadata> get idMetadata => _singleton._idMetadata;
  final SplayTreeSet<SongIdMetadata> _idMetadata = SplayTreeSet();
}

final RegExp _nameValueRegexp = RegExp(r'\s*(\d)\s*:\s*(\d)\s*$');
