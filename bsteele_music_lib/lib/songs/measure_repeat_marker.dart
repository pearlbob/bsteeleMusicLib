import 'dart:core';

import 'key.dart';
import 'measure.dart';
import 'measure_node.dart';

class MeasureRepeatMarker extends Measure {
  MeasureRepeatMarker(this.repeats, {this.repetition}) : super.zeroArgs();

  @override
  MeasureNodeType get measureNodeType => MeasureNodeType.decoration;

  @override
  String transpose(Key key, int halfSteps) {
    return toString();
  }

  @override
  String getHtmlBlockId() {
    return 'RX';
  }

  bool isEndOfRow() {
    return true;
  }

  @override
  String toMarkup({bool expanded = false}) {
    return toString();
  }

  @override
  String toString() {
    return 'x${repetition == null ? '' : '$repetition/'}$repeats';
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
    return runtimeType == other.runtimeType &&
        other is MeasureRepeatMarker &&
        repeats == other.repeats &&
        repetition == other.repetition;
  }

  @override
  int get hashCode {
    return Object.hash(repeats, repetition);
  }

  int? repetition; //  the cycle count of the repeats, starting at 1
  int repeats;
}
