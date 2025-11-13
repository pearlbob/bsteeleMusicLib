import 'dart:core';

import 'key.dart';
import 'measure.dart';
import 'measure_node.dart';

class MeasureRepeatMarker extends Measure {
  MeasureRepeatMarker(this.repeats, this.measuresPerRepeat, {this.repetition, this.lastRepetition}) : super.zeroArgs() {
    lastRepetition ??= repeats;
  }

  @override
  MeasureNodeType get measureNodeType => .measureRepeatMarker;

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
  String toMarkup({bool expanded = false, bool withInversion = true}) {
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

  /// Copy the song to a new instance with possible changes.
  MeasureRepeatMarker copyWith({int? lastRepetition}) {
    return MeasureRepeatMarker(
      repeats,
      measuresPerRepeat,
      repetition: repetition,
      lastRepetition: lastRepetition ?? this.lastRepetition,
    );
  }

  @override
  String toDebugString() {
    return '${toString()}, lastRepetition: $lastRepetition, measuresPerRepeat: $measuresPerRepeat';
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    return runtimeType == other.runtimeType &&
        other is MeasureRepeatMarker &&
        repeats == other.repeats &&
        repetition == other.repetition &&
        measuresPerRepeat == other.measuresPerRepeat;
  }

  @override
  int get hashCode {
    return Object.hash(repeats, repetition, measuresPerRepeat);
  }

  int? repetition; //  the cycle count of the repeats, starting at 1
  int? lastRepetition; //  the last cycle of this repeat, starting at 1
  int repeats;
  int measuresPerRepeat;
}
