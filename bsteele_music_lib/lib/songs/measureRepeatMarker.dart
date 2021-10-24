import 'dart:core';

import 'key.dart';
import 'measure.dart';
import 'measureNode.dart';

class MeasureRepeatMarker extends Measure {
  MeasureRepeatMarker(this.repeats, {this.repetition}) : super.zeroArgs();

  @override
  MeasureNodeType getMeasureNodeType() {
    return MeasureNodeType.decoration;
  }

  @override
  String transpose(Key key, int halfSteps) {
    return toString();
  }

  @override
  String getHtmlBlockId() {
    return 'RX';
  }

//  int compareTo(MeasureRepeatMarker o) {
//    return repeats < o.repeats ? -1 : (repeats > o.repeats ? 1 : 0);
//  }

  bool isEndOfRow() {
    return true;
  }

  @override
  String toString() {
    return 'x$repeats${repetition == null ? '' : '#$repetition'}';
  }

  @override
  String toMarkupWithoutEnd() {
    return toString();
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    return runtimeType == other.runtimeType && other is MeasureRepeatMarker && repeats == other.repeats;
  }

  @override
  int get hashCode {
    return repeats.hashCode;
  }

  int? repetition;
  int repeats;
}
