import 'dart:core';

import 'measure.dart';
import 'measureNode.dart';
import 'key.dart';

class MeasureRepeatMarker extends Measure {
  MeasureRepeatMarker(this.repeats) : super.zeroArgs();

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
    return 'x' + repeats.toString();
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

  int repeats;
}
