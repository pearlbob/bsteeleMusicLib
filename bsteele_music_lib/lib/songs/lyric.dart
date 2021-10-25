import 'dart:convert';

import 'package:bsteeleMusicLib/songs/key.dart';

import 'measureNode.dart';

class Lyric extends MeasureNode {
  Lyric(this.line);

  @override
  String? getId() {
    return 'line_$line';
  }

  @override
  MeasureNodeType getMeasureNodeType() {
    return MeasureNodeType.lyric;
  }

  @override
  bool setMeasuresPerRow(int measuresPerRow) {
    return false;
  }

  @override
  String toEntry() {
    return line;
  }

  @override
  String toJson() {
    return '"line": "${jsonEncode(line)}"';
  }

  @override
  String toMarkup() {
    return line;
  }

  @override
  String toMarkupWithoutEnd() {
    return line;
  }

  @override
  String transpose(Key key, int halfSteps) {
    return line;
  }

  @override
  MeasureNode transposeToKey(Key key) {
    return this;
  }

  @override
  String toString() {
    return '"$line"';
  }

  final String line;
}
