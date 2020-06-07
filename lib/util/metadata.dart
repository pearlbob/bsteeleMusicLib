import 'dart:collection';
import 'dart:convert';

import 'package:bsteeleMusicLib/appLogger.dart';

enum CjRankingEnum {
  bad,
  poor,
  ok,
  good,
  best,
}

extension CjRankingEnumParser on String {
  CjRankingEnum toCjRankingEnum() {
    return CjRankingEnum.values
        .firstWhere((e) => e.toString() == 'CjRankingEnum.$this', orElse: () => null); //return null if not found
  }
}

/// name and value pair
class NameValue implements Comparable<NameValue> {
  NameValue(this._name, this._value);

  @override
  String toString() {
    return '{"$name":"$value"}';
  }

  @override
  bool operator ==(other) {
    return _name == other._name && _value == other._value;
  }

  @override
  int compareTo(NameValue other) {
    if (other == null) {
      return -1;
    }

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
class IdMetadata implements Comparable<IdMetadata> {
  IdMetadata(this._id, {List<NameValue> metadata}) {
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

  @override
  int compareTo(IdMetadata other) {
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
      sb.write(nv.toString());
    }
    return '{"id":"$id","metadata":[$sb]}';
  }

  String get id => _id;
  final String _id;

  List<NameValue> get nameValues => _nameValues.toList();
  final SplayTreeSet<NameValue> _nameValues = SplayTreeSet();
}

/// system metadata registry that is a set of id metadata
class Metadata {
  static final Metadata _singleton = Metadata._internal();

  factory Metadata() {
    return _singleton;
  }

  Metadata._internal();

  static void set(IdMetadata idMetadata) {
    if (!_singleton._idMetadata.add(idMetadata)) {
      _singleton._idMetadata.remove(idMetadata);
      _singleton._idMetadata.add(idMetadata);
    }
  }

  static void add(IdMetadata idMetadata) {
    IdMetadata value;
    if ((value = _singleton._idMetadata.lookup(idMetadata)) != null) {
      value._nameValues.addAll(idMetadata._nameValues);
    } else {
      set(idMetadata);
    }
  }

  static SplayTreeSet<IdMetadata> match(bool Function(IdMetadata idMetadata) doesMatch, {SplayTreeSet<IdMetadata> from}) {
    SplayTreeSet<IdMetadata> ret = SplayTreeSet();
    if (doesMatch != null) {
      for (IdMetadata idMetadata in from ?? _singleton._idMetadata) {
        if (doesMatch(idMetadata)) {
          ret.add(idMetadata);
        }
      }
    }
    return ret;
  }

  static SplayTreeSet<IdMetadata> where({String idIsLike, String nameIsLike, String valueIsLike}) {
    if (idIsLike == null && nameIsLike == null && valueIsLike == null) {
      return _singleton._shallowCopyIdMetadata();
    }

    SplayTreeSet<IdMetadata> ret = SplayTreeSet();
    RegExp idIsLikeReg;
    RegExp nameIsLikeReg;
    RegExp valueIsLikeReg;

    if (idIsLike != null) {
      idIsLikeReg = RegExp(idIsLike, caseSensitive: false, dotAll: true);
    }
    if (nameIsLike != null) {
      nameIsLikeReg = RegExp(nameIsLike, caseSensitive: false, dotAll: true);
    }
    if (valueIsLike != null) {
      valueIsLikeReg = RegExp(valueIsLike, caseSensitive: false, dotAll: true);
    }

    loop:
    for (IdMetadata idm in _singleton._idMetadata) {
      if (idIsLikeReg != null && idIsLikeReg.hasMatch(idm._id)) {
        ret.add(idm);
        continue;
      }

      if (nameIsLikeReg != null) {
        if (valueIsLikeReg != null) {
          for (NameValue nv in idm._nameValues) {
            if (valueIsLikeReg.hasMatch(nv._name) && valueIsLikeReg.hasMatch(nv._value)) {
              ret.add(idm);
              continue loop;
            }
          }
        } else {
          for (NameValue nv in idm._nameValues) {
            if (nameIsLikeReg.hasMatch(nv._name)) {
              ret.add(idm);
              continue loop;
            }
          }
        }
      }
      if (valueIsLikeReg != null) {
        for (NameValue nv in idm._nameValues) {
          if (valueIsLikeReg.hasMatch(nv._value)) {
            ret.add(idm);
            continue loop;
          }
        }
      }
    }
    return ret;
  }

  SplayTreeSet<IdMetadata> _shallowCopyIdMetadata() {
    SplayTreeSet<IdMetadata> ret = SplayTreeSet();
    for (IdMetadata idMetadata in _idMetadata) {
      ret.add(idMetadata);
    }
    return ret;
  }

  static SplayTreeSet<String> namesOf(SplayTreeSet<IdMetadata> idMetadata) {
    SplayTreeSet<String> ret = SplayTreeSet();
    for (IdMetadata idMetadata in _singleton._idMetadata) {
      for (NameValue nameValue in idMetadata.nameValues) {
        ret.add(nameValue.name);
      }
    }
    return ret;
  }

  static SplayTreeSet<String> valuesOf(SplayTreeSet<IdMetadata> idMetadata, String name) {
    SplayTreeSet<String> ret = SplayTreeSet();
    for (IdMetadata idMetadata in _singleton._idMetadata) {
      for (NameValue nameValue in idMetadata.nameValues) {
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
    for (IdMetadata idMetadata in _singleton._idMetadata) {
      if (first) {
        first = false;
      } else {
        sb.write(',\n');
      }
      sb.write(idMetadata.toJson());
    }
    return '[\n$sb\n]';
  }

  static void fromJson(String jsonString) {
    var decoded = json.decode(jsonString);
    Metadata.clear();
    if (decoded != null) {
      for (var item in decoded) {
        String id;
        for (String key in item.keys) {
          logger.d('\t${key.toString()}:');
          switch (key) {
            case 'id':
              id = item[key].toString();
              logger.d('\t\t$id');
              break;
            case 'metadata':
              for (var value in item[key]) {
                if (value is Map) {
                  for (var k in value.keys) {
                    //  fixme: id has to be first!
                    Metadata.add(IdMetadata(id, metadata: [NameValue(k.toString(), value[k].toString())]));
                  }
                }
              }
              break;
          }
        }

        logger.d('');
      }
    }
  }

  static SplayTreeSet<IdMetadata> get idMetadata => _singleton._idMetadata;
  final SplayTreeSet<IdMetadata> _idMetadata = SplayTreeSet();
}
