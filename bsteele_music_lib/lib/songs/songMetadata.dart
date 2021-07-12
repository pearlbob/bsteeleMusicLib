import 'dart:collection';
import 'dart:convert';

import 'package:bsteeleMusicLib/appLogger.dart';

enum CjRankingEnum {
  all,
  poor,
  ok,
  good,
  best,
}

extension CjRankingEnumParser on String {
  CjRankingEnum toCjRankingEnum() {
    return CjRankingEnum.values.firstWhere((e) => e.toString() == 'CjRankingEnum.$this',
        orElse: () => CjRankingEnum.all); //return all if not found
  }
}

/// name and value pair
class NameValue implements Comparable<NameValue> {
  const NameValue(this._name, this._value);

  @override
  String toString() {
    return '{"$name":"$value"}';
  }

  String toJson() {
    return '{"name":${jsonEncode(name)},"value":${jsonEncode(value)}}';
  }

  @override
  bool operator ==(other) {
    return runtimeType == other.runtimeType && other is NameValue && _name == other._name && _value == other._value;
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

  String get name => _name;
  final String _name;

  String get value => _value;
  final String _value;
}

/// name value pairs attached to an id
class SongIdMetadata implements Comparable<SongIdMetadata> {
  SongIdMetadata(this._id, {List<NameValue>? metadata}) {
    if (metadata != null) {
      for (NameValue nameValue in metadata) {
        add(nameValue);
      }
    }
  }

  void add(NameValue nameValue) {
    if (!_nameValues.contains(nameValue)) {
      _nameValues.add(nameValue);
    }
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
      if (first) {
        first = false;
      } else {
        sb.write(',');
      }
      sb.write(nv.toJson());
    }
    return '{"id":${jsonEncode(id)},"metadata":[${sb.toString()}]}';
  }

  String get id => _id;
  final String _id;

  List<NameValue> get nameValues => _nameValues.toList();
  final SplayTreeSet<NameValue> _nameValues = SplayTreeSet();
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
      _singleton._idMetadata.remove(songIdMetadata);
      _singleton._idMetadata.add(songIdMetadata);
    }
  }

  static void add(SongIdMetadata songIdMetadata) {
    SongIdMetadata? value;
    if ((value = _singleton._idMetadata.lookup(songIdMetadata)) != null) {
      value!._nameValues.addAll(songIdMetadata._nameValues);
    } else {
      set(songIdMetadata);
    }
  }

  static void remove(SongIdMetadata songIdMetadata) {
    _singleton._idMetadata.remove(songIdMetadata);
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

  static NameValue? songMetadataAt(final String id, final String name, {SplayTreeSet<SongIdMetadata>? from}) {
    for (SongIdMetadata songIdMetadata in from ?? _singleton._idMetadata) {
      if (songIdMetadata.id == id) {
        for (NameValue nameValue in songIdMetadata.nameValues) {
          if (nameValue.name == name) {
            return nameValue;
          }
        }
      }
    }
    return null;
  }

  static SplayTreeSet<SongIdMetadata> where(
      {String? idIsLike, String? nameIsLike, String? valueIsLike, String? idIs, String? nameIs, String? valueIs}) {
    if (idIsLike == null &&
        nameIsLike == null &&
        valueIsLike == null &&
        idIs == null &&
        nameIs == null &&
        valueIs == null) {
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

  static void clear() {
    _singleton._idMetadata.clear();
  }

  static String toJson() {
    StringBuffer sb = StringBuffer();
    bool first = true;
    for (SongIdMetadata songIdMetadata in _singleton._idMetadata) {
      if (first) {
        first = false;
      } else {
        sb.write(',\n');
      }
      sb.write(songIdMetadata.toJson());
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

        logger.d('');
      }
    }
  }

  static SplayTreeSet<SongIdMetadata> get idMetadata => _singleton._idMetadata;
  final SplayTreeSet<SongIdMetadata> _idMetadata = SplayTreeSet();
}
