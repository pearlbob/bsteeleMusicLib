import 'dart:collection';

import 'package:quiver/core.dart';

import '../util/util.dart';
import 'SectionVersion.dart';

enum ChordSectionLocationMarker {
  none,
  repeatUpperRight,
  repeatMiddleRight,
  repeatLowerRight
}

class ChordSectionLocation implements Comparable<ChordSectionLocation> {
  ChordSectionLocation(this._sectionVersion,
      {int phraseIndex, int measureIndex})
      : _labelSectionVersions = null {
    if (phraseIndex == null || phraseIndex < 0) {
      _phraseIndex = -1;
      hasPhraseIndex = false;
      _measureIndex = -1;
      _hasMeasureIndex = false;
    } else {
      _phraseIndex = phraseIndex;
      hasPhraseIndex = true;
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

  ChordSectionLocation.byMultipleSectionVersion(
      Set<SectionVersion> labelSectionVersions)
      : _sectionVersion = null,
        this._phraseIndex = -1,
        hasPhraseIndex = false,
        this._measureIndex = -1,
        _hasMeasureIndex = false {
    if (labelSectionVersions != null) {
      _labelSectionVersions = SplayTreeSet();
      if (labelSectionVersions.isEmpty)
        _labelSectionVersions.add(SectionVersion.getDefault());
      else
        _labelSectionVersions.addAll(labelSectionVersions);

      _sectionVersion = labelSectionVersions.first;
    }

    _marker = ChordSectionLocationMarker.none;
  }

  ChordSectionLocation.withMarker(
      this._sectionVersion, int phraseIndex, this._marker)
      : _labelSectionVersions = null {
    if (phraseIndex == null || phraseIndex < 0) {
      _phraseIndex = -1;
      hasPhraseIndex = false;
    } else {
      this._phraseIndex = phraseIndex;
      hasPhraseIndex = true;
    }
    _measureIndex = -1;
    _hasMeasureIndex = false;
  }

  ChordSectionLocation changeSectionVersion(SectionVersion sectionVersion) {
    if (sectionVersion == null || sectionVersion == this._sectionVersion)
      return this; //  no change

    if (hasPhraseIndex) {
      if (_hasMeasureIndex)
        return new ChordSectionLocation(sectionVersion,
            phraseIndex: _phraseIndex, measureIndex: _measureIndex);
      else
        return new ChordSectionLocation(sectionVersion,
            phraseIndex: _phraseIndex);
    } else
      return new ChordSectionLocation(sectionVersion);
  }

  static ChordSectionLocation parseString(String s) {
    return parse(new MarkedString(s));
  }

  /// Parse a chord section location from the given string input
  static ChordSectionLocation parse(MarkedString markedString) {
    SectionVersion sectionVersion = SectionVersion.parse(markedString);

    if (markedString.available() >= 3) {
      RegExpMatch mr =
          numberRangeRegexp.firstMatch(markedString.remainingStringLimited(6));
      if (mr != null) {
        try {
          int phraseIndex = int.parse(mr.group(1));
          if (phraseIndex == null) phraseIndex = -1;
          int measureIndex = int.parse(mr.group(2));
          if (measureIndex == null) measureIndex = -1;
          markedString.consume(mr.group(0).length);
          return ChordSectionLocation(sectionVersion,
              phraseIndex: phraseIndex, measureIndex: measureIndex);
        } catch (e) {
          throw e.getMessage();
        }
      }
    }
    if (markedString.isNotEmpty) {
      RegExpMatch mr =
          numberRegexp.firstMatch(markedString.remainingStringLimited(2));
      if (mr != null) {
        try {
          int phraseIndex = int.parse(mr.group(1));
          markedString.consume(mr.group(0).length);
          return ChordSectionLocation(sectionVersion, phraseIndex: phraseIndex);
        } catch (nfe) {
          throw nfe.getMessage();
        }
      }
    }
    return new ChordSectionLocation(sectionVersion);
  }

  ChordSectionLocation nextMeasureIndexLocation() {
    if (!hasPhraseIndex || !_hasMeasureIndex) return this;
    return new ChordSectionLocation(_sectionVersion,
        phraseIndex: _phraseIndex, measureIndex: _measureIndex + 1);
  }

  ChordSectionLocation nextPhraseIndexLocation() {
    if (!hasPhraseIndex) return this;
    return new ChordSectionLocation(_sectionVersion,
        phraseIndex: _phraseIndex + 1);
  }

  @override
  String toString() {
    return getId();
  }

  String getId() {
    if (id == null) {
      if (_labelSectionVersions == null)
        id = _sectionVersion.toString() +
            (hasPhraseIndex
                ? _phraseIndex.toString() +
                    (_hasMeasureIndex ? ":" + _measureIndex.toString() : "")
                : "");
      else {
        StringBuffer sb = new StringBuffer();
        for (SectionVersion sv in _labelSectionVersions) {
          sb.write(sv.toString());
          sb.write(" ");
        }
        id = sb.toString();
      }
    }
    return id;
  }

  @override
  int compareTo(ChordSectionLocation other) {
    int ret = _sectionVersion.compareTo(other._sectionVersion);
    if (ret != 0) return ret;
    ret = _phraseIndex - other._phraseIndex;
    if (ret != 0) return ret;
    ret = _measureIndex - other._measureIndex;
    if (ret != 0) return ret;

    if (_labelSectionVersions == null)
      return other._labelSectionVersions == null ? 0 : -1;
    if (other._labelSectionVersions == null) return 1;

    ret = _labelSectionVersions.length - other._labelSectionVersions.length;
    if (ret != 0) return ret;
    if (_labelSectionVersions.isNotEmpty) {
      for (int i = 0; i < _labelSectionVersions.length; i++) {
        ret = _labelSectionVersions
            .elementAt(i)
            .compareTo(other._labelSectionVersions.elementAt(i));
        if (ret != 0) return ret;
      }
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
        _measureIndex == other._measureIndex)) return false;

    if (_labelSectionVersions == null)
      return (other._labelSectionVersions == null);

    if (_labelSectionVersions.length != other._labelSectionVersions.length)
      return false;
    for (int i = 0; i < _labelSectionVersions.length; i++) {
      if (_labelSectionVersions.elementAt(i) !=
          other._labelSectionVersions.elementAt(i)) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    //  2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97
    int ret = hash3(_sectionVersion, _phraseIndex, _measureIndex);
    if (_labelSectionVersions != null && _labelSectionVersions.isNotEmpty)
      ret = ret * 83 + _labelSectionVersions.hashCode;
    return ret;
  }

  bool get isSection => hasPhraseIndex == false && _hasMeasureIndex == false;

  bool get isPhrase => hasPhraseIndex == true && _hasMeasureIndex == false;

  bool get isMeasure => hasPhraseIndex == true && _hasMeasureIndex == true;

  SectionVersion get sectionVersion => _sectionVersion;
  SectionVersion _sectionVersion;
  SplayTreeSet<SectionVersion> _labelSectionVersions;

  int get phraseIndex => _phraseIndex;
  int _phraseIndex;
  bool hasPhraseIndex;

  int get measureIndex => _measureIndex;
  int _measureIndex;

  bool get hasMeasureIndex => _hasMeasureIndex;
  bool _hasMeasureIndex;

  ChordSectionLocationMarker get marker => _marker;
  ChordSectionLocationMarker _marker;
  String id;

  static final RegExp numberRangeRegexp = RegExp("^(\\d+):(\\d+)");
  static final RegExp numberRegexp = RegExp("^(\\d+)");
}
