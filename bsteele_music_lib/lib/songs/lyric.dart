import 'dart:convert';

import 'package:meta/meta.dart';

import 'key.dart';

import 'measure_node.dart';

@immutable
class Lyric extends MeasureNode {
  Lyric(this.line, {this.phraseIndex = 0, this.repeat = 0});

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
  String toJsonString() {
    return '"line": "${jsonEncode(line)}"';
  }

  @override
  String toMarkup({bool expanded = false, bool withInversion = true}) {
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
    return '"$line"'; // at $phraseIndex';
  }

  @override
  String toNashville(Key key) {
    return ''; //  no lyrics in Nashville!
  }

  final String line;
  final int phraseIndex;
  final int repeat;
}
