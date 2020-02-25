import '../appLogger.dart';
import '../util/util.dart';
import 'Measure.dart';
import 'MeasureComment.dart';
import 'MeasureNode.dart';
import 'MeasureRepeatMarker.dart';
import 'Phrase.dart';
import 'Section.dart';
import 'Key.dart';

class MeasureRepeat extends Phrase {
  MeasureRepeat(List<Measure> measures, int phraseIndex, int repeats)
      : super(measures, phraseIndex) {
    this._repeatMarker = MeasureRepeatMarker(repeats);
  }

  static MeasureRepeat parseString(
      String s, int phraseIndex, int beatsPerBar, Measure priorMeasure) {
    return parse(MarkedString(s), phraseIndex, beatsPerBar, priorMeasure);
  }

  static MeasureRepeat parse(MarkedString markedString, int phraseIndex,
      int beatsPerBar, Measure priorMeasure) {
    if (markedString == null || markedString.isEmpty) throw "no data to parse";

    int initialMark = markedString.mark();

    List<Measure> measures = List();

    markedString.stripLeadingSpaces();

    bool hasBracket = markedString.charAt(0) == '[';
    if (hasBracket) markedString.consume(1);

//  look for a set of measures and comments
    bool barFound = false;
    for (int i = 0; i < 1e3; i++) {
      //  safety
      markedString.stripLeadingSpaces();
      logger.v("repeat parsing: " + markedString.remainingStringLimited(10));
      if (markedString.isEmpty) {
        markedString.resetTo(initialMark);
        throw "no data to parse";
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
        throw "repeat not found";
      }

//  assure this is not a section
      if (Section.lookahead(markedString)) break;

      int mark = markedString.mark();
      try {
        Measure measure =
            Measure.parse(markedString, beatsPerBar, priorMeasure);
        if (!hasBracket && measure.endOfRow) {
          throw "repeat not found"; //  this is not a repeat!
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

    final RegExp repeatExp =
        RegExp("^" + (hasBracket ? "\\s*]" : "") + "\\s*x(\\d+)\\s*");
    RegExpMatch mr = repeatExp.firstMatch(markedString.toString());
    if (mr != null) {
      int repeats = int.parse(mr.group(1));
      if (measures.isNotEmpty) measures[measures.length - 1].endOfRow = false;
      MeasureRepeat ret = MeasureRepeat(measures, phraseIndex, repeats);
      logger.d(" measure repeat: " + ret.toMarkup());
      markedString.consume(mr.group(0).length);
      return ret;
    }

    markedString.resetTo(initialMark);
    throw "repeat not found";
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
  MeasureNode findMeasureNode(MeasureNode measureNode) {
    MeasureNode ret = super.findMeasureNode(measureNode);
    if (ret != null) return ret;
    if (measureNode == _repeatMarker) return _repeatMarker;
    return null;
  }

  @override
  bool delete(Measure measure) {
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
    return "x" + repeats.toString();
  }

  @override
  MeasureNode transposeToKey(Key key) {
    List<Measure> newMeasures = List<Measure>();
    for (Measure measure in measures)
      newMeasures.add(measure.transposeToKey(key) as Measure);
    return MeasureRepeat(newMeasures, phraseIndex, repeats);
  }

  @override
  int get chordRowCount {
    return (super.chordRowCount + 1) //  last end of row not marked on repeats
        *
        _repeatMarker.repeats;
  }

  @override
  String toMarkup() {
    return "[" +
        (measures.isEmpty ? "" : super.toMarkup()) +
        "] x" +
        repeats.toString() +
        " ";
  }

  @override
  String toEntry() {
    return "[" +
        (measures.isEmpty ? "" : super.toEntry()) +
        "] x" +
        repeats.toString() +
        "\n ";
  }

  @override
  String toJson() {
    if (measures == null || measures.isEmpty) return " ";

    StringBuffer sb = StringBuffer();
    if (measures.isNotEmpty) {
      int rowCount = 0;
      int i = 0;
      int last = measures.length - 1;
      for (Measure measure in measures) {
        sb.write(measure.toJson());
        if (i == last) {
          if (rowCount > 0) sb.write(" |");
          sb.write(" x" + repeats.toString() + "\n");
          break;
        } else if (measure.endOfRow) {
          sb.write(" |\n");
          rowCount++;
        } else
          sb.write(" ");
        i++;
      }
    }
    return sb.toString();
  }

  @override
  String toString() {
    return super.toMarkup() + " x" + repeats.toString() + "\n";
  }

  int compareTo(Object o) {
    if (!(o is MeasureRepeat)) return -1;

    int ret = super.compareTo(o);
    if (ret != 0) return ret;
    MeasureRepeat other = o as MeasureRepeat;
    ret = _repeatMarker.compareTo(other._repeatMarker);
    if (ret != 0) return ret;
    return 0;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    return other is MeasureRepeat &&
        super == (other) &&
        _repeatMarker == other._repeatMarker;
  }

  @override
  int get hashCode {
    int ret = super.hashCode;
    ret = ret * 17 + _repeatMarker.hashCode;
    return ret;
  }

  MeasureRepeatMarker _repeatMarker;
}
