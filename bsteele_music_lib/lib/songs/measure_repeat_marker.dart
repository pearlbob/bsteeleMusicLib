import 'dart:core';

import 'package:json_annotation/json_annotation.dart';

import 'key.dart';
import 'measure.dart';
import 'measure_node.dart';
import 'chord.dart';

part 'measure_repeat_marker.g.dart';

@JsonSerializable()
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

  factory MeasureRepeatMarker.fromJson(Map<String, dynamic> json) => _$MeasureRepeatMarkerFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MeasureRepeatMarkerToJson(this);

  int? repetition; //  the cycle count of the repeats, starting at 1
  int repeats;
}
