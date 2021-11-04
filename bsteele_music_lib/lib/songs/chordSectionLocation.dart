import 'dart:collection';

import 'package:quiver/core.dart';

import '../util/util.dart';
import 'measureRepeatExtension.dart';
import 'sectionVersion.dart';

enum ChordSectionLocationMarker { none, repeatUpperRight, repeatMiddleRight, repeatLowerRight, repeatOnOneLineRight }

/// identify a section, phrase, or measure in the chord definitions
/// by it's unique section id, phrase index, and measure index.
/// Phrase index is the running count from zero of the phrases or repeats in the section.
/// Measure index is the running count from zero of the measure within the phrase.
/// Note that measures within repeats are counted in the repeat's compact form.
class ChordSectionLocation implements Comparable<ChordSectionLocation> {
  ChordSectionLocation(this._sectionVersion, {int? phraseIndex, int? measureIndex}) : _labelSectionVersions = null {
    if (phraseIndex == null || phraseIndex < 0) {
      _phraseIndex = -1;
      _hasPhraseIndex = false;
      _measureIndex = -1;
      _hasMeasureIndex = false;
    } else {
      _phraseIndex = phraseIndex;
      _hasPhraseIndex = true;
      if (measureIndex == null || measureIndex < 0) {
        _measureIndex = -1;
        _hasMeasureIndex = false;
      } else {
        _measureIndex = measureIndex;
        _hasMeasureIndex = true;
      }
    }

    _marker = ChordSectionLocationMarker.none;
  }

  ChordSectionLocation.copy(ChordSectionLocation? other)
      : this(other?.sectionVersion, phraseIndex: other?.phraseIndex, measureIndex: other?._measureIndex);

  ChordSectionLocation.byMultipleSectionVersion(Set<SectionVersion>? labelSectionVersions)
      : _sectionVersion = null,
        _phraseIndex = -1,
        _hasPhraseIndex = false,
        _measureIndex = -1,
        _hasMeasureIndex = false {
    if (labelSectionVersions != null) {
      _labelSectionVersions = SplayTreeSet();
      if (labelSectionVersions.isEmpty) {
        _labelSectionVersions?.add(SectionVersion.getDefault());
      } else {
        _labelSectionVersions?.addAll(labelSectionVersions);
      }

      _sectionVersion = labelSectionVersions.first;
    }

    _marker = ChordSectionLocationMarker.none;
  }

  ChordSectionLocation.withMarker(this._sectionVersion, int phraseIndex, this._marker) : _labelSectionVersions = null {
    _initPhraseIndex(phraseIndex);
  }

  ChordSectionLocation.withRepeatMarker(this._sectionVersion, int phraseIndex, this._repeats)
      : _labelSectionVersions = null {
    _initPhraseIndex(phraseIndex);
  }

  ChordSectionLocation asSectionLocation() {
    return ChordSectionLocation(_sectionVersion);
  }

  ChordSectionLocation? asPhraseLocation() {
    if (!_hasPhraseIndex) {
      return null;
    }
    return ChordSectionLocation(_sectionVersion, phraseIndex: phraseIndex);
  }

  void _initPhraseIndex(int phraseIndex) {
    if (phraseIndex < 0) {
      _phraseIndex = -1;
      _hasPhraseIndex = false;
    } else {
      _phraseIndex = phraseIndex;
      _hasPhraseIndex = true;
    }
    _measureIndex = -1;
    _hasMeasureIndex = false;
  }

  ChordSectionLocation changeSectionVersion(SectionVersion? sectionVersion) {
    if (sectionVersion == null || sectionVersion == _sectionVersion) {
      return this; //  no change
    }

    if (_hasPhraseIndex) {
      if (_hasMeasureIndex) {
        return ChordSectionLocation(sectionVersion, phraseIndex: _phraseIndex, measureIndex: _measureIndex);
      } else {
        return ChordSectionLocation(sectionVersion, phraseIndex: _phraseIndex);
      }
    } else {
      return ChordSectionLocation(sectionVersion);
    }
  }

  static ChordSectionLocation parseString(String s) {
    return parse(MarkedString(s));
  }

  /// Parse a chord section location from the given string input
  static ChordSectionLocation parse(MarkedString markedString) {
    SectionVersion sectionVersion = SectionVersion.parse(markedString); // fails with an exception

    if (markedString.available() >= 3) {
      //  look for full sectionVersion, phrase, measure specification
      RegExpMatch? mr = numberRangeRegexp.firstMatch(markedString.remainingStringLimited(6));
      if (mr != null) {
        try {
          int phraseIndex = int.parse(mr.group(1)!);
          int measureIndex = int.parse(mr.group(2)!);
          markedString.consume(mr.group(0)!.length);
          return ChordSectionLocation(sectionVersion, phraseIndex: phraseIndex, measureIndex: measureIndex);
        } catch (e) {
          throw e.toString();
        }
      }
    }
    //  look for full sectionVersion, phrase specification
    if (markedString.isNotEmpty) {
      RegExpMatch? mr = numberRegexp.firstMatch(markedString.remainingStringLimited(2));
      if (mr != null) {
        try {
          int phraseIndex = int.parse(mr.group(1) ?? '');
          markedString.consume(mr.group(0)!.length);
          return ChordSectionLocation(sectionVersion, phraseIndex: phraseIndex);
        } catch (nfe) {
          throw nfe.toString();
        }
      }
    }

    //  return only the sectionVersion
    return ChordSectionLocation(sectionVersion);
  }

  ChordSectionLocation? priorMeasureIndexLocation() {
    if (!_hasPhraseIndex || !_hasMeasureIndex || _measureIndex == 0) {
      return null;
    }
    return ChordSectionLocation(_sectionVersion, phraseIndex: _phraseIndex, measureIndex: _measureIndex - 1);
  }

  ChordSectionLocation nextMeasureIndexLocation() {
    if (!_hasPhraseIndex || !_hasMeasureIndex) {
      return this;
    }
    return ChordSectionLocation(_sectionVersion, phraseIndex: _phraseIndex, measureIndex: _measureIndex + 1);
  }

  ChordSectionLocation nextPhraseIndexLocation() {
    if (!_hasPhraseIndex) {
      return this;
    }
    return ChordSectionLocation(_sectionVersion, phraseIndex: _phraseIndex);
  }

  @override
  String toString() {
    return getId() +
        (_marker != ChordSectionLocationMarker.none ? ':${MeasureRepeatExtension.get(_marker)}' : '') +
        (_repeats != null ? ':x$_repeats' : '');
  }

  static ChordSectionLocation? fromString(String s) {
    //logger.i('fromString($s)');

    RegExpMatch? m = _chordSectionLocationRegexp.firstMatch(s);
    // logger.i('m: $m, ${m?.groupCount}');
    // var count = m?.groupCount ?? 0;
    // for (var i = 0; i <= count; i++) {
    //   logger.i('  $i: ${m?.group(i)}');
    // }
    if (m == null) {
      return null;
    }
    try {
      SectionVersion? sectionVersion = SectionVersion.parseString(m.group(1)!);
      // logger.i('sectionVersion: $sectionVersion, count: $count');
      var phraseString = m.group(2);
      var measureString = m.group(3);
      if (phraseString != null && measureString != null) {
        return ChordSectionLocation(sectionVersion,
            phraseIndex: int.parse(phraseString), measureIndex: int.parse(measureString));
      }
      if (phraseString != null) {
        return ChordSectionLocation(sectionVersion, phraseIndex: int.parse(phraseString));
      }
      return ChordSectionLocation(sectionVersion);
    } catch (e) {
      return null;
    }
  }

  static final RegExp _chordSectionLocationRegexp = RegExp(r'^([^:]+:)(\d)?(?::(\d))?$');

  String getId() {
    if (id == null) {
      if (_labelSectionVersions == null) {
        id = _sectionVersion.toString() +
            (_hasPhraseIndex ? _phraseIndex.toString() + (_hasMeasureIndex ? ':' + _measureIndex.toString() : '') : '');
      } else {
        StringBuffer sb = StringBuffer();
        for (SectionVersion sv in _labelSectionVersions!) {
          sb.write(sv.toString());
          sb.write(' ');
        }
        id = sb.toString();
      }
    }
    return id ?? 'unknownId';
  }

  @override
  int compareTo(ChordSectionLocation other) {
    int ret = 0;

    if (_sectionVersion == null && other._sectionVersion == null) {
      ;
    } else if (other._sectionVersion == null) {
      ret = -1;
    } else {
      ret = (_sectionVersion?.compareTo(other._sectionVersion!) ?? 1);
    }
    if (ret != 0) {
      return ret;
    }

    if (_repeats == null && other._repeats == null) {
      ;
    } else if (other._repeats == null) {
      ret = -1;
    } else {
      ret = (_repeats?.compareTo(other._repeats!) ?? 1);
    }
    if (ret != 0) {
      return ret;
    }

    ret = _phraseIndex - other._phraseIndex;
    if (ret != 0) {
      return ret;
    }
    ret = _measureIndex - other._measureIndex;
    if (ret != 0) {
      return ret;
    }

    if (_labelSectionVersions == null) {
      return other._labelSectionVersions == null ? 0 : -1;
    }
    if (other._labelSectionVersions == null) {
      return 1;
    }

    ret = (_labelSectionVersions?.length ?? 0) - (other._labelSectionVersions?.length ?? 0);
    if (ret != 0) {
      return ret;
    }

    if (_labelSectionVersions == null && other._labelSectionVersions == null) {
      ret = 0;
    } else if (_labelSectionVersions == null) {
      ret = -1;
    } else if (other._labelSectionVersions == null) {
      ret = 1;
    } else {
      ret = _labelSectionVersions!.length.compareTo(other._labelSectionVersions!.length);
      if (ret == 0) {
        for (int i = 0; i < _labelSectionVersions!.length; i++) {
          ret = _labelSectionVersions!.elementAt(i).compareTo(other._labelSectionVersions!.elementAt(i));
          if (ret != 0) {
            return ret;
          }
        }
      }
    }
    if (ret != 0) {
      return ret;
    }
    return 0;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    if (!(other is ChordSectionLocation &&
        _sectionVersion == other._sectionVersion &&
        _phraseIndex == other._phraseIndex &&
        _measureIndex == other._measureIndex &&
        _repeats == other._repeats)) return false;

    if (_labelSectionVersions == null) {
      return (other._labelSectionVersions == null);
    }

    if (_labelSectionVersions!.length != (other._labelSectionVersions?.length ?? 0)) {
      return false;
    }
    for (int i = 0; i < _labelSectionVersions!.length; i++) {
      if (_labelSectionVersions!.elementAt(i) != other._labelSectionVersions!.elementAt(i)) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    //  2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97
    int ret = hash4(_sectionVersion, _phraseIndex, _measureIndex, _repeats);
    if (_labelSectionVersions != null && _labelSectionVersions!.isNotEmpty) {
      ret = ret * 83 + _labelSectionVersions.hashCode;
    }
    return ret;
  }

  bool get isSection => _hasPhraseIndex == false && _hasMeasureIndex == false;

  bool get isPhrase => _hasPhraseIndex == true && _hasMeasureIndex == false;

  bool get isMeasure => _hasPhraseIndex == true && _hasMeasureIndex == true;

  bool get isMarker => _marker != ChordSectionLocationMarker.none;

  bool get isRepeat => _repeats != null;

  SectionVersion? get sectionVersion => _sectionVersion;
  SectionVersion? _sectionVersion;
  SplayTreeSet<SectionVersion>? _labelSectionVersions;

  int get phraseIndex => _phraseIndex;
  late int _phraseIndex;

  bool get hasPhraseIndex => _hasPhraseIndex;
  late bool _hasPhraseIndex;

  int get measureIndex => _measureIndex;
  late int _measureIndex;

  bool get hasMeasureIndex => _hasMeasureIndex;
  late bool _hasMeasureIndex;

  ChordSectionLocationMarker get marker => _marker;
  ChordSectionLocationMarker _marker = ChordSectionLocationMarker.none;
  String? id;

  int? _repeats;

  static final RegExp numberRangeRegexp = RegExp('^(\\d+):(\\d+)');
  static final RegExp numberRegexp = RegExp('^(\\d+)');
}
