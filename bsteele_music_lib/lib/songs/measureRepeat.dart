import 'package:bsteeleMusicLib/songs/measureRepeatExtension.dart';

import '../appLogger.dart';
import '../util/util.dart';
import 'chordSectionLocation.dart';
import 'measure.dart';
import 'measureComment.dart';
import 'measureNode.dart';
import 'measureRepeatMarker.dart';
import 'phrase.dart';
import 'section.dart';
import 'key.dart';

class MeasureRepeat extends Phrase {
  MeasureRepeat(List<Measure> measures, int phraseIndex, int repeats)
      : _repeatMarker = MeasureRepeatMarker(repeats),
        super(measures, phraseIndex);

  static MeasureRepeat parseString(String s, int phraseIndex, int beatsPerBar, Measure? priorMeasure) {
    return parse(MarkedString(s), phraseIndex, beatsPerBar, priorMeasure);
  }

  static MeasureRepeat parse(MarkedString markedString, int phraseIndex, int beatsPerBar, Measure? priorMeasure) {
    if (markedString.isEmpty) throw 'no data to parse';

    int initialMark = markedString.mark();

    List<Measure> measures = [];

    markedString.stripLeadingSpaces();

    bool hasBracket = markedString.charAt(0) == '[';
    if (hasBracket) markedString.consume(1);

//  look for a set of measures and comments
    bool barFound = false;
    for (int i = 0; i < 1e3; i++) {
      //  safety
      markedString.stripLeadingSpaces();
      logger.v('repeat parsing: ' + markedString.remainingStringLimited(10));
      if (markedString.isEmpty) {
        markedString.resetTo(initialMark);
        throw 'no data to parse';
      }

//  extend the search for a repeat only if the line ends with a |
      if (markedString.charAt(0) == '|') {
        barFound = true;
        markedString.consume(1);
        if (measures.isNotEmpty) measures[measures.length - 1].endOfRow = true;
        continue;
      }
      if (barFound && markedString.charAt(0) == ',') {
        markedString.consume(1);
        continue;
      }
      if (markedString.charAt(0) == '\n') {
        markedString.consume(1);
        if (barFound) {
          barFound = false;
          continue;
        }
        markedString.resetTo(initialMark);
        throw 'repeat not found';
      }

//  assure this is not a section
      if (Section.lookahead(markedString)) break;

      int mark = markedString.mark();
      try {
        Measure measure = Measure.parse(markedString, beatsPerBar, priorMeasure);
        if (!hasBracket && measure.endOfRow) {
          throw 'repeat not found'; //  this is not a repeat!
        }
        priorMeasure = measure;
        measures.add(measure);
        barFound = false;
        continue;
      } catch (e) {
        markedString.resetTo(mark);
      }

      if (markedString.charAt(0) != ']' && markedString.charAt(0) != 'x') {
        try {
          MeasureComment measureComment = MeasureComment.parse(markedString);
          measures.add(measureComment);
          priorMeasure = null;
          continue;
        } catch (e) {
          markedString.resetTo(mark);
        }
      }
      break;
    }

    final RegExp repeatExp = RegExp('^' + (hasBracket ? '\\s*]' : '') + '\\s*x(\\d+)\\s*');
    RegExpMatch? mr = repeatExp.firstMatch(markedString.toString());
    if (mr != null) {
      int repeats = int.parse(mr.group(1)!);
      if (measures.isNotEmpty) measures[measures.length - 1].endOfRow = false;
      MeasureRepeat ret = MeasureRepeat(measures, phraseIndex, repeats);
      logger.d(' measure repeat: ' + ret.toMarkup());
      markedString.consume(mr.group(0)!.length);
      return ret;
    }

    markedString.resetTo(initialMark);
    throw 'repeat not found';
  }

  @override
  int getTotalMoments() {
    return getRepeatMarker().repeats * super.getTotalMoments();
  }

  int get repeats => getRepeatMarker().repeats;

  set repeats(int repeats) => getRepeatMarker().repeats = repeats;

  @override
  MeasureNodeType getMeasureNodeType() {
    return MeasureNodeType.repeat;
  }

  @override
  MeasureNode? findMeasureNode(MeasureNode measureNode) {
    MeasureNode? ret = super.findMeasureNode(measureNode);
    if (ret != null) return ret;
    if (measureNode == _repeatMarker) return _repeatMarker;
    return null;
  }

  int repeatAt(int index) {
    if (index < 0 || index >= measures.length * repeats) {
      return 0;
    }
    return index ~/ measures.length;
  }

  @override
  int chordRowMaxLength() {
    //  include the row markers
    return super.chordRowMaxLength() + 2;
  }

  @override

  /// get a display row at the index, including the repeat markers
  List<Measure> rowAt(int index, {expanded = false}) {
    var ret = <Measure>[];

    if (measures.isEmpty) {
      return ret;
    }

    //  walk through all prior measures //  fixme: efficiency?
    var repeatRowCount = 0;
    for (var measure in measures) {
      if (measure.endOfRow) {
        repeatRowCount++;
      } else if (identical(measure, measures.last)) {
        repeatRowCount++;
        break; //  redundant
      }
    }
    int chordRowMaxLength = super.chordRowMaxLength();

    var r = 0;
    for (var m = 0; m < measureCount * repeats /*  safety only */; m++) {
      var measure = measureAt(m, expanded: expanded);
      if (measure == null) {
        break;
      }
      if (r == index) {
        ret.add(measure);
      }
      if (measure.endOfRow || identical(measure, measures.last)) {
        if (r == index) {
          //  fill a short row
          while (ret.length < chordRowMaxLength) {
            ret.add(MeasureRepeatExtension.get(ChordSectionLocationMarker.none));
          }

          //  place repeat markers
          var repeatRowNumber = r % repeatRowCount;
          if (measure == measures.last) {
            if (repeatRowNumber == 0) {
              ret.add(MeasureRepeatExtension.get(ChordSectionLocationMarker.repeatOnOneLineRight));
            } else {
              ret.add(MeasureRepeatExtension.get(ChordSectionLocationMarker.repeatLowerRight));
            }
            if (expanded) {
              ret.add(MeasureRepeatExtension('${r ~/ repeatRowCount + 1}/$repeats'));
            } else {
              ret.add(_repeatMarker);
            }
          } else if (repeatRowNumber == 0) {
            ret.add(MeasureRepeatExtension.get(ChordSectionLocationMarker.repeatUpperRight));
          } else {
            ret.add(MeasureRepeatExtension.get(ChordSectionLocationMarker.repeatMiddleRight));
          }
          return ret;
        }
        r++;
      }
    }

    return ret;
  }

  @override
  Measure? measureAt(int index, {expanded = false}) {
    if (expanded) {
      if (index >= measures.length * repeats) {
        return null;
      }
      index %= measures.length;
    }
    return super.measureAt(index);
  }

  @override
  bool delete(Measure? measure) {
    if (measure == null) return false;
    if (measure == getRepeatMarker()) {
      //  fixme: improve delete repeat marker
      //  fake it
      getRepeatMarker().repeats = 1;
      return true;
    }
    return super.delete(measure);
  }

  MeasureRepeatMarker getRepeatMarker() {
    return _repeatMarker;
  }

  @override
  bool isSingleItem() {
    return false;
  }

  @override
  bool isRepeat() {
    return true;
  }

  @override
  String transpose(Key key, int halfSteps) {
    return 'x' + repeats.toString();
  }

  @override
  MeasureNode transposeToKey(Key key) {
    List<Measure> newMeasures = <Measure>[];
    for (Measure measure in measures) {
      newMeasures.add(measure.transposeToKey(key) as Measure);
    }
    return MeasureRepeat(newMeasures, phraseIndex, repeats);
  }

  @override
  int get chordRowCount {
    return super.chordRowCount * _repeatMarker.repeats;
  }

  @override
  String toMarkup() {
    return '[' + (measures.isEmpty ? '' : super.toMarkup()) + '] x' + repeats.toString() + ' ';
  }

  @override
  String toMarkupWithoutEnd() {
    return '[' + (measures.isEmpty ? '' : super.toMarkupWithoutEnd()) + '] x' + repeats.toString() + ' ';
  }

  @override
  String toEntry() {
    return '[' + (measures.isEmpty ? '' : super.toEntry()) + '] x' + repeats.toString() + '\n ';
  }

  @override
  String toJson() {
    if (measures.isEmpty) return ' ';

    StringBuffer sb = StringBuffer();
    if (measures.isNotEmpty) {
      int rowCount = 0;
      int i = 0;
      int last = measures.length - 1;
      for (Measure measure in measures) {
        sb.write(measure.toJson());
        if (i == last) {
          if (rowCount > 0) sb.write(' |');
          sb.write(' x' + repeats.toString() + '\n');
          break;
        } else if (measure.endOfRow) {
          sb.write(' |\n');
          rowCount++;
        } else {
          sb.write(' ');
        }
        i++;
      }
    }
    return sb.toString();
  }

  @override
  String toString() {
    return super.toMarkup() + ' x' + repeats.toString() + '\n';
  }

  @override
  int compareTo(Object o) {
    if (!(o is MeasureRepeat)) return -1;

    int ret = super.compareTo(o);
    if (ret != 0) return ret;
    MeasureRepeat other = o;
    ret = _repeatMarker.compareTo(other._repeatMarker);
    if (ret != 0) return ret;
    return 0;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    return runtimeType == other.runtimeType &&
        other is MeasureRepeat &&
        super == (other) &&
        _repeatMarker == other._repeatMarker;
  }

  @override
  int get hashCode {
    int ret = super.hashCode;
    ret = ret * 17 + _repeatMarker.hashCode;
    return ret;
  }

  final MeasureRepeatMarker _repeatMarker;
}
