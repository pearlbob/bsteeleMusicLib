import 'dart:core';
import 'dart:math';

import 'package:quiver/collection.dart';
import 'package:quiver/core.dart';

import '../grid.dart';
import '../util/util.dart';
import 'key.dart';
import 'measure.dart';
import 'measureComment.dart';
import 'measureNode.dart';
import 'musicConstants.dart';
import 'section.dart';

class Phrase extends MeasureNode {
  Phrase(List<Measure> measures, int phraseIndex, {bool allowEndOfRow = false}) : _phraseIndex = phraseIndex {
    _measures = [];
    _measures.addAll(measures);

    //  fix measure row length if required
    if (_measures.isNotEmpty) {
      //  enforce formatting of unformatted or sloppy formatted songs
      if (maxMeasuresPerChordRow() > MusicConstants.maxMeasuresPerChordRow) {
        setMeasuresPerRow(MusicConstants.nominalMeasuresPerChordRow);
      }
      if (!allowEndOfRow) {
        _measures.last.endOfRow = false; //  no end of row on the end of the list
      }
    }
  }

  int getTotalMoments() {
    return _measures.length; //  fixme
  }

  static Phrase parseString(String string, int phraseIndex, int beatsPerBar, Measure? priorMeasure) {
    return parse(MarkedString(string), phraseIndex, beatsPerBar, priorMeasure);
  }

  static Phrase parse(MarkedString markedString, int phraseIndex, int beatsPerBar, Measure? priorMeasure,
      {bool allowEndOfRow = false}) {
    if (markedString.isEmpty) {
      throw 'no data to parse';
    }

    List<Measure> measures = [];
    List<Measure> lineMeasures = [];

    markedString.stripLeadingSpaces();

    //  look for a set of measures and comments
    int initialMark = markedString.mark();
    int rowMark = markedString.mark();

    bool hasBracket = markedString.charAt(0) == '[';
    if (hasBracket) {
      markedString.consume(1);
    }

    for (int i = 0; i < 1e3; i++) {
      //  safety
      markedString.stripLeadingSpaces();
      if (markedString.isEmpty) {
        break;
      }

      //  assure this is not a section
      if (Section.lookahead(markedString)) {
        break;
      }

      try {
        Measure measure = Measure.parse(markedString, beatsPerBar, priorMeasure);
        priorMeasure = measure;
        lineMeasures.add(measure);

        //  we found an end of row so this row is a part of a phrase
        if (measure.endOfRow) {
          measures.addAll(lineMeasures);
          lineMeasures.clear();
          rowMark = markedString.mark();
        }
        continue;
      } catch (e) {
        //  fall through
      }

      if (!hasBracket) {
        //  look for repeat marker
        markedString.stripLeadingSpaces();

        //  note: commas or newlines will have been consumed by the measure parse
        String c = markedString.charAt(0);
        if (c == '|' || c == 'x') {
          lineMeasures.clear();
          markedString.resetTo(rowMark);
          break; //  we've found a repeat so the phrase was done the row above
        }
      }

      //  force junk into a comment
      try {
        Measure measure = MeasureComment.parse(markedString);
        measures.addAll(lineMeasures);
        measures.add(measure);
        lineMeasures.clear();
        priorMeasure = null;
        continue;
      } catch (e) {
        //  fall through
      }

      //  end of bracketed phrase
      if (hasBracket && markedString.charAt(0) == ']') {
        markedString.consume(1);
        break;
      }

      break;
    }

    //  look for repeat marker
    markedString.stripLeadingSpaces();

    //  note: commas or newlines will have been consumed by the measure parse
    if (markedString.available() > 0) {
      String c = markedString.charAt(0);
      if (c == '|' || c == 'x') {
        if (measures.isEmpty) {
          //  no phrase found
          markedString.resetTo(initialMark);
          throw 'no measures found in parse'; //  we've found a repeat so the phrase is appropriate
        } else {
          //  repeat found after prior rows
          lineMeasures.clear();
          markedString.resetTo(rowMark);
        }
      }
    }

    //  collect the last row
    measures.addAll(lineMeasures);

    //  note: bracketed phrases can be empty
    if (!hasBracket && measures.isEmpty) {
      markedString.resetTo(initialMark);
      throw 'no measures found in parse';
    }

    return Phrase(measures, phraseIndex, allowEndOfRow: allowEndOfRow);
  }

  Phrase deepCopy() {
    List<Measure> measures = [];
    for (var measure in _measures) {
      measures.add(measure.deepCopy());
    }
    return Phrase(measures, _phraseIndex);
  }

  @override
  String transpose(Key key, int halfSteps) {
    StringBuffer sb = StringBuffer();
    for (Measure measure in _measures) {
      sb.write(measure.transpose(key, halfSteps));
      sb.write(measure.endOfRow ? ', ' : ' ');
    }
    return sb.toString();
  }

  @override
  String toNashville(Key key) {
    StringBuffer sb = StringBuffer();
    for (Measure measure in _measures) {
      sb.write(measure.toNashville(key));
      sb.write(measure.endOfRow ? '     ' : ' '); //  fixme: all on one line?
    }
    return sb.toString().trimRight();
  }

  @override
  MeasureNode transposeToKey(Key key) {
    List<Measure> newMeasures = <Measure>[];
    for (Measure measure in _measures) {
      newMeasures.add(measure.transposeToKey(key) as Measure);
    }
    return Phrase(newMeasures, _phraseIndex, allowEndOfRow: true);
  }

  MeasureNode? findMeasureNode(MeasureNode measureNode) {
    for (Measure m in _measures) {
      if (m == measureNode) {
        return m;
      }
    }
    return null;
  }

  int findMeasureNodeIndex(MeasureNode? measureNode) {
    if (measureNode == null) {
      throw 'measureNode null';
    }

    int ret = _measures.indexOf(measureNode as Measure);

    if (ret < 0) {
      throw 'measureNode not found: ${measureNode.toMarkup()}';
    }

    return ret;
  }

  bool insert(int index, MeasureNode? newMeasureNode) {
    if (newMeasureNode == null) {
      return false;
    }

    switch (newMeasureNode.measureNodeType) {
      case MeasureNodeType.measure:
        break;
      default:
        return false;
    }

    Measure newMeasure = newMeasureNode as Measure;

    if (_measures.isEmpty) {
      _measures.add(newMeasure);
      return true;
    }

    try {
      _addAt(index, newMeasure);
    } catch (ex) {
      _measures.add(newMeasure); //  default to the end!
    }
    return true;
  }

  bool replace(int index, MeasureNode? newMeasureNode) {
    if (_measures.isEmpty) {
      return false;
    }

    if (newMeasureNode == null) {
      return false;
    }

    switch (newMeasureNode.measureNodeType) {
      case MeasureNodeType.measure:
        break;
      default:
        return false;
    }

    Measure newMeasure = newMeasureNode as Measure;

    try {
      List<Measure> replacementList = [];
      if (index > 0) {
        replacementList.addAll(_measures.sublist(0, index));
      }
      replacementList.add(newMeasure);
      if (index < _measures.length - 1) {
        replacementList.addAll(_measures.sublist(index + 1, _measures.length));
      }
      _measures = replacementList;
    } catch (ex) {
      _measures.add(newMeasure); //  default to the end!
    }
    return true;
  }

  bool append(int index, MeasureNode? newMeasureNode) {
    if (newMeasureNode == null) {
      return false;
    }

    switch (newMeasureNode.measureNodeType) {
      case MeasureNodeType.measure:
        break;
      default:
        return false;
    }

    Measure newMeasure = newMeasureNode as Measure;

    if (_measures.isEmpty) {
      _measures.add(newMeasure);
      return true;
    }

    try {
      _addAt(index + 1, newMeasure);
    } catch (ex) {
      _measures.add(newMeasure); //  default to the end!
    }

    return true;
  }

  bool add(List<Measure>? newMeasures) {
    if (newMeasures == null || newMeasures.isEmpty) {
      return false;
    }
    _measures.addAll(newMeasures);
    return true;
  }

  bool addAt(int index, List<Measure>? newMeasures) {
    if (newMeasures == null || newMeasures.isEmpty) {
      return false;
    }
    index = min(index, _measures.length - 1);
    addAllAt(index, newMeasures);
    return true;
  }

  void _addAt(int index, Measure m) {
    if (_measures.length < index) {
      _measures.add(m);
    } else {
      _measures.insert(index, m);
    }
  }

  bool addAllAt(int index, List<Measure>? list) {
    if (list == null || list.isEmpty) {
      return false;
    }
    if (_measures.length < index) {
      _measures.addAll(list);
    } else {
      for (Measure m in list) {
        _measures.insert(index++, m);
      }
    }
    return true;
  }

  bool edit(MeasureEditType type, int index, MeasureNode? newMeasureNode) {
    if (newMeasureNode == null) {
      switch (type) {
        case MeasureEditType.delete:
          break;
        default:
          return false;
      }
    } else {
      //  reject wrong node type
      switch (newMeasureNode.measureNodeType) {
        case MeasureNodeType.phrase: //  multiple measures
        case MeasureNodeType.comment:
        case MeasureNodeType.measure:
          break;
        //  repeats not allowed!
        default:
          return false;
      }
    }

    //  assure measures are ready
    switch (type) {
      case MeasureEditType.replace:
      case MeasureEditType.delete:
        if (_measures.isEmpty) {
          return false;
        }
        break;
      case MeasureEditType.insert:
      case MeasureEditType.append:
        if (newMeasureNode == null) {
          return false;
        }

        //  index doesn't matter
        if (_measures.isEmpty) {
          if (newMeasureNode.isSingleItem()) {
            _measures.add(newMeasureNode as Measure);
          } else {
            _measures.addAll((newMeasureNode as Phrase)._measures);
          }
          return true;
        }
        break;
      default:
        return false;
    }

    //  edit by type
    switch (type) {
      case MeasureEditType.delete:
        try {
          _measures.removeAt(index);
          //  note: newMeasureNode is ignored
        } catch (ex) {
          return false;
        }
        break;
      case MeasureEditType.insert:
        if (newMeasureNode == null) {
          return false;
        }
        try {
          if (newMeasureNode.isSingleItem()) {
            _addAt(index, newMeasureNode as Measure);
          } else {
            addAllAt(index, (newMeasureNode as Phrase)._measures);
          }
        } catch (ex) {
          //  default to the end!
          if (newMeasureNode.isSingleItem()) {
            _measures.add(newMeasureNode as Measure);
          } else {
            _measures.addAll((newMeasureNode as Phrase)._measures);
          }
        }
        break;
      case MeasureEditType.append:
        if (newMeasureNode == null) {
          return false;
        }
        try {
          if (newMeasureNode.isSingleItem()) {
            _addAt(index + 1, newMeasureNode as Measure);
          } else {
            addAllAt(index + 1, (newMeasureNode as Phrase)._measures);
          }
        } catch (ex) {
          //  default to the end!
          if (newMeasureNode.isSingleItem()) {
            _measures.add(newMeasureNode as Measure);
          } else {
            _measures.addAll((newMeasureNode as Phrase)._measures);
          }
        }
        break;
      case MeasureEditType.replace:
        if (newMeasureNode == null) {
          return false;
        }
        try {
          _measures.removeAt(index);
          if (newMeasureNode.isSingleItem()) {
            _addAt(index, newMeasureNode as Measure);
          } else {
            addAllAt(index, (newMeasureNode as Phrase)._measures);
          }
        } catch (ex) {
          //  default to the end!
          if (newMeasureNode.isSingleItem()) {
            _measures.add(newMeasureNode as Measure);
          } else {
            _measures.addAll((newMeasureNode as Phrase)._measures);
          }
        }
        break;
      default:
        return false;
    }

    return true;
  }

  bool contains(MeasureNode measureNode) {
    return _measures.contains(measureNode);
  }

  Measure getMeasure(int measureIndex) {
    return _measures[measureIndex];
  }

  //  return the first measure of the given row
  Measure firstMeasureInRow(int row) {
    int r = 0;
    Measure? firstInPriorRow;
    bool wasEndOfRow = false;
    for (var m in measures) {
      if (r == row) {
        return m;
      }
      if (wasEndOfRow) {
        firstInPriorRow = m;
        wasEndOfRow = false;
      } else {
        firstInPriorRow ??= m;
      }
      if (m.endOfRow) {
        r++;
        wasEndOfRow = true;
      }
    }
    return firstInPriorRow
        //  shouldn't be necessary:
        ??
        measures.last;
  }

  ///  maximum number of measures in a chord row
  ///  note: these measures will include the repeat markers for repeats
  int chordRowMaxLength() {
    return maxMeasuresPerChordRow();
  }

  ///  note: these measures do not include the repeat markers
  int maxMeasuresPerChordRow() {
    //  walk through all prior measures //  fixme: efficiency?
    var maxLength = 0;
    var length = 0;
    for (var m = 0; m < measureCount + 1000 /*  safety only */; m++) {
      var measure = measureAt(m);
      if (measure == null) {
        break;
      }
      //  note: these measures do not include the repeat markers
      length++;
      if (measure.endOfRow || identical(measure, measures.last)) {
        maxLength = max(maxLength, length);
        length = 0;
      }
    }
    return maxLength;
  }

  int rowCount({expanded = false}) {
    //  walk through all prior measures //  fixme: efficiency?
    var r = 0;
    for (var m = 0; m < measureCount + 1000 /*  safety only */; m++) {
      var measure = measureAt(m, expanded: expanded);
      if (measure == null) {
        break;
      }
      if (measure.endOfRow || identical(measure, measures.last)) {
        r++;
      }
    }
    return r;
  }

  List<Measure> rowAt(int index, {expanded = false}) {
    var ret = <Measure>[];

    //  walk through all prior measures //  fixme: efficiency?
    var r = 0;
    for (var m = 0; m < measureCount + 1000 /*  safety only */; m++) {
      var measure = measureAt(m, expanded: expanded);
      if (measure == null) {
        break;
      }
      if (r == index) {
        ret.add(measure);
      }
      if (measure.endOfRow) {
        r++;
        if (r > index) {
          return ret;
        }
      }
    }

    return ret;
  }

  Measure? measureAt(int measureIndex, {expanded = false}) {
    if (measureIndex < 0 || measureIndex >= _measures.length) {
      return null;
    }
    return _measures[measureIndex];
  }

  /// Delete the first instance of the given measure if it belongs in the sequence item.
  bool delete(Measure measure) {
    if (_measures.isEmpty) {
      return false;
    }
    return _measures.remove(measure);
  }

  bool deleteAt(int measureIndex) {
    try {
      _measures.removeAt(measureIndex);
    } catch (e) {
      return false;
    }
    return true;
  }

  @override
  bool isSingleItem() {
    return false;
  }

  int get repeats => 1;

  @override
  MeasureNodeType get measureNodeType => MeasureNodeType.phrase;

  @override
  bool get isEmpty {
    return _measures.isEmpty;
  }

  @override
  String toMarkup({bool expanded = false}) {
    if (_measures.isEmpty) {
      return '[]';
    }

    StringBuffer sb = StringBuffer();
    for (Measure measure in _measures) {
      sb.write(measure.toMarkup());
      sb.write(' ');
    }
    return sb.toString();
  }

  String markupStart() {
    return ' ';
  }

  String markupEnd({int? rep}) {
    return '';
  }

  @override
  String toMarkupWithoutEnd() {
    if (_measures.isEmpty) {
      return '[]';
    }

    StringBuffer sb = StringBuffer();
    for (Measure measure in _measures) {
      sb.write(measure.toMarkupWithoutEnd());
      sb.write(' ');
    }
    return sb.toString();
  }

  @override
  String toEntry() {
    if (_measures.isEmpty) {
      return '  []';
    }

    StringBuffer sb = StringBuffer();
    sb.write('  ');
    for (Measure measure in _measures) {
      sb.write(measure.toEntry());
      if (!identical(measure, measures.last)) {
        sb.write(measure.endOfRow ? '  ' : ' ');
      }
    }
    sb.writeln('');
    return sb.toString();
  }

  @override
  bool setMeasuresPerRow(int measuresPerRow) {
    if (measuresPerRow <= 0) {
      return false;
    }

    bool ret = false;
    int i = 0;
    if (_measures.isNotEmpty) {
      Measure lastMeasure = _measures[_measures.length - 1];
      for (Measure measure in _measures) {
        if (measure.isComment()) {
          continue; //  comments get their own row
        }
        if (i == measuresPerRow - 1 && !identical(measure, lastMeasure)) {
          //  new row required
          if (!measure.endOfRow) {
            measure.endOfRow = true;
            ret = true;
          }
        } else {
          if (measure.endOfRow) {
            measure.endOfRow = false;
            ret = true;
          }
        }
        i++;
        i %= measuresPerRow;
      }
    }
    return ret;
  }

  /// Get the number of rows in this phrase after griding.
  int get chordRowCount {
    if (_measures.isEmpty) {
      return 0;
    }
    int chordRowCount = 0;
    for (Measure measure in _measures) {
      chordRowCount += (measure.endOfRow ? 1 : 0);
    }
    if (!_measures[_measures.length - 1].endOfRow) {
      chordRowCount++; //  fixme: shouldn't be needed?  last measure doesn't have endOfRow!
    }
    return chordRowCount;
  }

  int beatsInRow(int row, {bool? expanded}) {
    if (_measures.isEmpty) {
      return 0;
    }
    var chordRowCount = 0;
    var beats = 0;
    for (Measure measure in _measures) {
      chordRowCount += (measure.endOfRow ? 1 : 0);
      if (row == chordRowCount) {
        beats += measure.beatCount;
      }
    }
    return beats;
  }

  Grid<MeasureNode> toGrid({int? chordColumns, bool? expanded}) {
    var grid = Grid<MeasureNode>();
    chordColumns = max(chordColumns ?? 0, maxMeasuresPerChordRow());
    int row = 0;
    int col = 0;
    var rowCount = this.rowCount();
    for (Measure measure in _measures) {
      grid.set(row, col++, measure);
      if (measure.endOfRow) {
        while (col < chordColumns) {
          grid.set(row, col++, null);
        }
        if (row < rowCount - 1) {
          row++;
          col = 0;
        }
      }
    }
    //  notice that the last measure is always missing the endOfRow
    while (col < chordColumns) {
      grid.set(row, col++, null);
    }
    return grid;
  }

  @override
  String toJson() {
    if (_measures.isEmpty) {
      return ' ';
    }

    StringBuffer sb = StringBuffer();
    if (_measures.isNotEmpty) {
      int i = 0;
      int last = _measures.length - 1;
      for (Measure measure in _measures) {
        sb.write(measure.toJson());
        if (i == last) {
          sb.write('\n');
          break;
        } else if (measure.endOfRow) {
          sb.write('\n');
        } else {
          sb.write(' ');
        }
        i++;
      }
    }
    return sb.toString();
  }

  Measure? get firstMeasure {
    try {
      return _measures.first;
    } catch (e) {
      return null;
    }
  }

  Measure? get lastMeasure {
    try {
      return _measures.last;
    } catch (e) {
      return null;
    }
  }

  int get measureCount => measures.length;

  @override
  String toString() {
    return '${toMarkup()}\n';
  }

  int get length => _measures.length;

  List<Measure> get measures => _measures;

  int get phraseIndex => _phraseIndex;

  void setPhraseIndex(int phraseIndex) {
    _phraseIndex = phraseIndex;
  }

  int compareTo(Object o) {
    if (o is! Phrase) {
      return -1;
    }
    Phrase other = o;
    int limit = min(_measures.length, other._measures.length);
    for (int i = 0; i < limit; i++) {
      int ret = _measures[i].compareTo(other._measures[i]);
      if (ret != 0) {
        return ret;
      }
    }
    if (_measures.length != other._measures.length) {
      return _measures.length < other._measures.length ? -1 : 1;
    }
    return 0;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    return runtimeType == other.runtimeType //  distinguish yourself from subclasses
        &&
        other is Phrase //  required for the following:
        &&
        _phraseIndex == other._phraseIndex &&
        listsEqual(_measures, other._measures);
  }

  @override
  int get hashCode {
    int ret = _phraseIndex.hashCode;
    ret = ret * 17 + hashObjects(_measures);
    return ret;
  }

  List<Measure> _measures = [];
  int _phraseIndex;
}
