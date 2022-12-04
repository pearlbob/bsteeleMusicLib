import 'dart:collection';
import 'dart:convert';

import 'package:bsteeleMusicLib/app_logger.dart';
import 'package:bsteeleMusicLib/songs/song.dart';
import 'package:bsteeleMusicLib/songs/song_base.dart';

import '../util/util.dart';

enum SongMetadataGeneratedValue {
  decade,
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
    return '{"$name":"$value"}';
  }

  String toShortString() {
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

class NameValueFilter {
  NameValueFilter(final Iterable<NameValue> nameValues) {
    Map<String, SplayTreeSet<NameValue>> map = {};
    for (var nv in nameValues) {
      var mappedList = map[nv.name];
      mappedList ??= SplayTreeSet();
      mappedList.add(nv); //  fixme: deal with nameValue changes?
      map[nv.name] = mappedList;
    }
    filterMap = map;
  }

  bool isOr(final NameValue nameValue) {
    var values = filterMap[nameValue.name];
    return values != null && values.contains(nameValue) && values.length > 1;
  }

  SplayTreeSet<NameValue> nameValues() {
    SplayTreeSet<NameValue> ret = SplayTreeSet();
    for (var key in SplayTreeSet<String>()..addAll(filterMap.keys)) {
      ret.addAll(filterMap[key] ?? []);
    }
    return ret;
  }

  bool testAll(final SplayTreeSet<NameValue>? nameValues) {
    if (nameValues == null) {
      return false;
    }

    Map<String, SplayTreeSet<NameValue>> map = {};
    for (var nv in nameValues) {
      var mappedSet = map[nv.name];
      mappedSet ??= SplayTreeSet<NameValue>();
      mappedSet.add(nv); //  fixme: deal with nameValue changes?
      map[nv.name] = mappedSet;
    }

    for (var key in filterMap.keys) {
      SplayTreeSet<NameValue>? mappedSet = map[key];
      //  set intersection is the equivalent of the or function for name values with the same name
      if (mappedSet == null || mappedSet.intersection(filterMap[key]!.toSet()).isEmpty) {
        return false;
      }
    }

    return true;
  }

  bool test(final NameValue nameValue) {
    var values = filterMap[nameValue.name];
    if (values == null || values.isEmpty) {
      return false;
    }
    //  an AND term
    if (values.length == 1) {
      return nameValue.value == values.first.value;
    }
    //  an OR term
    for (var key in filterMap.keys) {
      if (filterMap[key]?.contains(nameValue) ?? false) {
        return true;
      }
    }
    return false;
  }

  late final Map<String, SplayTreeSet<NameValue>> filterMap;
}

/// name value pairs attached to a song id
class SongIdMetadata implements Comparable<SongIdMetadata> {
  SongIdMetadata(this._id, {List<NameValue>? metadata}) {
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
