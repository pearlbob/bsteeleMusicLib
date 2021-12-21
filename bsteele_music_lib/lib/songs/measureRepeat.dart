import 'dart:math';

import 'package:bsteeleMusicLib/songs/measureRepeatExtension.dart';

import '../appLogger.dart';
import '../grid.dart';
import '../util/util.dart';
import 'chordSectionLocation.dart';
import 'key.dart';
import 'measure.dart';
import 'measureComment.dart';
import 'measureNode.dart';
import 'measureRepeatMarker.dart';
import 'phrase.dart';
import 'section.dart';

class MeasureRepeat extends Phrase {
  MeasureRepeat(List<Measure> measures, int phraseIndex, int repeats)
      : _repeatMarker = MeasureRepeatMarker(repeats),
        super(measures, phraseIndex);

  static MeasureRepeat parseString(String s, int phraseIndex, int beatsPerBar, Measure? priorMeasure) {
    return parse(MarkedString(s), phraseIndex, beatsPerBar, priorMeasure);
  }

  static MeasureRepeat parse(MarkedString markedString, int phraseIndex, int beatsPerBar, Measure? priorMeasure) {
    if (markedString.isEmpty) {
      throw 'no data to parse';
    }

    int initialMark = markedString.mark();

    List<Measure> measures = [];

    markedString.stripLeadingSpaces();

    bool hasBracket = markedString.charAt(0) == '[';
    if (hasBracket) {
      markedString.consume(1);
    }

//  look for a set of measures and comments
    bool barFound = false;
    for (int i = 0; i < 1e3; i++) //  safety
        {
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
        if (measures.isNotEmpty) {
          measures[measures.length - 1].endOfRow = true;
        }
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
      if (Section.lookahead(markedString)) {
        break;
      }

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
      if (measures.isNotEmpty) {
        measures.last.endOfRow = false;
      }
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

  @override
  Phrase deepCopy() {
    List<Measure> newMeasures = [];
    for (var measure in measures) {
      newMeasures.add(measure.deepCopy());
    }
    return MeasureRepeat(newMeasures, phraseIndex, repeats);
  }

  @override
  int get repeats => getRepeatMarker().repeats;

  set repeats(int repeats) => getRepeatMarker().repeats = repeats;

  @override
  MeasureNodeType get measureNodeType => MeasureNodeType.repeat;

  @override
  MeasureNode? findMeasureNode(MeasureNode measureNode) {
    MeasureNode? ret = super.findMeasureNode(measureNode);
    if (ret != null) {
      return ret;
    }
    if (measureNode == _repeatMarker) {
      return _repeatMarker;
    }
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
    return super.maxMeasuresPerChordRow() + (rowCount() > 1 ? 1 : 0) + 1;
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
              //  marker not necessary!
              //ret.add(MeasureRepeatExtension.get(ChordSectionLocationMarker.repeatOnOneLineRight));
            } else {
              ret.add(MeasureRepeatExtension.get(ChordSectionLocationMarker.repeatLowerRight));
            }
            if (expanded) {
              ret.add(MeasureRepeatExtension(
                  ChordSectionLocationMarker.repeatLowerRight, '${r ~/ repeatRowCount + 1}/$repeats'));
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
    if (measure == null) {
      return false;
    }
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

  // @override
  // int beatsInRow( int row,{bool? expanded} ){
  //   if (measures.isEmpty) {
  //     return 0;
  //   }
  //   var chordRowCount = 0;
  //   var beats = 0;  fixme here now
  //   for (Measure measure in measures) {
  //     chordRowCount += (measure.endOfRow ? 1 : 0);
  //     if ( row == chordRowCount ){
  //       beats += measure.beatCount;
  //     }
  //   }
  //   return beats;
  // }

  @override
  String toMarkup({bool expanded = false}) {
    if ( expanded ){
      var sb = StringBuffer();
      for ( var r = 1; r <= repeats; r++ ){
        sb.write( '[${(measures.isEmpty ? '' : super.toMarkup())}] x$repeats#$r ');
      }
      return sb.toString();
    }
    return '[' + (measures.isEmpty ? '' : super.toMarkup()) + '] x' + repeats.toString() + ' ';
  }

  @override
  String toMarkupWithoutEnd() {
    return '[' + (measures.isEmpty ? '' : super.toMarkupWithoutEnd()) + '] x' + repeats.toString() + ' ';
  }

  @override
  String toEntry() {
    if (measures.isEmpty) {
      return '  [] x$repeats\n';
    }

    StringBuffer sb = StringBuffer();
    sb.write(' [');
    for (Measure measure in measures) {
      sb.write(measure.toEntry());
      if (!identical(measure, measures.last)) {
        sb.write(measure.endOfRow ? '  ' : ' ');
      }
    }
    sb.writeln('] x$repeats');
    return sb.toString();
  }

  @override
  String toJson() {
    if (measures.isEmpty) {
      return ' ';
    }

    StringBuffer sb = StringBuffer();
    if (measures.isNotEmpty) {
      int rowCount = 0;
      int i = 0;
      int last = measures.length - 1;
      for (Measure measure in measures) {
        sb.write(measure.toJson());
        if (i == last) {
          if (rowCount > 0) {
            sb.write(' |');
          }
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
  Grid<MeasureNode> toGrid({int? chordColumns, bool? expanded}) {
    var grid = Grid<MeasureNode>();
    int row = 0;
    int rowMod = 0;
    int col = 0;
    var rowCount = this.rowCount();
    bool hasExtensions = rowCount > 1;
    int maxCol = max(
        chordColumns ?? 0,
        maxMeasuresPerChordRow() +
            (hasExtensions ? 1 : 0) //  for repeat extension
            +
            1 //  for repeat marker
        );

    var limit = (expanded ?? false) ? repeats : 1;
    var repetition = 1;
    for (var repeatExpansion = 0; repeatExpansion < limit; repeatExpansion++) {
      for (Measure measure in measures) {
        grid.set(row, col++, measure);
        if (measure.endOfRow) {
          if (hasExtensions) {
            //  even out all the rows
            while (col < maxCol - 2) {
              grid.set(row, col++, null);
            }

            //  add the extension
            var extension;
            if (rowMod == 0) {
              extension = MeasureRepeatExtension.upperRightMeasureRepeatExtension;
            } else if (rowMod == rowCount - 1) {
              extension = MeasureRepeatExtension.lowerRightMeasureRepeatExtension;
            } else {
              extension = MeasureRepeatExtension.middleRightMeasureRepeatExtension;
            }
            grid.set(row, col++, extension);
          }
          if (rowMod < rowCount - 1) {
            grid.set(row, col++, null); //  place holder for the marker at the end
            row++;
            rowMod = row % rowCount;
            col = 0;
          }
        }
      }

      if (hasExtensions) {
        //  even out all the rows
        while (col < maxCol - 2) {
          grid.set(row, col++, null);
        }
        grid.set(row, col++, MeasureRepeatExtension.lowerRightMeasureRepeatExtension);
      }
      grid.set(row, col, (limit > 1 ? MeasureRepeatMarker(limit, repetition: repetition++) : _repeatMarker));
      row++;
      rowMod = row % rowCount;
      col = 0;
    }
    return grid;
  }

  @override
  String toString() {
    return super.toMarkup() + ' x' + repeats.toString() + '\n';
  }

  @override
  int compareTo(Object o) {
    if (!(o is MeasureRepeat)) {
      return -1;
    }

    int ret = super.compareTo(o);
    if (ret != 0) {
      return ret;
    }
    MeasureRepeat other = o;
    ret = _repeatMarker.compareTo(other._repeatMarker);
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
