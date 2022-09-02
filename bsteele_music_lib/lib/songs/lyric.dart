import 'dart:convert';

import 'package:bsteeleMusicLib/songs/key.dart';

import 'measureNode.dart';

class Lyric extends MeasureNode {
  Lyric(this.line, {this.phraseIndex = 0});

  @override
  MeasureNodeType get measureNodeType => MeasureNodeType.lyric;

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
  String toMarkup({bool expanded = false}) {
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
    return '"$line" at $phraseIndex';
  }

  final String line;
  final int phraseIndex;
}
