import 'package:quiver/collection.dart';
import 'package:quiver/core.dart';

import '../appLogger.dart';
import '../util/util.dart';
import 'key.dart';
import 'measure.dart';
import 'measureComment.dart';
import 'measureNode.dart';
import 'measureRepeat.dart';
import 'phrase.dart';
import 'section.dart';
import 'sectionVersion.dart';

/// A chord section of a song is typically a collection of measures
/// that constitute a portion of the song that is considered musically a unit.
/// Immutable.

class ChordSection extends MeasureNode implements Comparable<ChordSection> {
  ChordSection(this._sectionVersion, List<Phrase>? phrases) : _phrases = (phrases ?? []);

  static ChordSection getDefault() {
    return ChordSection(SectionVersion.getDefault(), null);
  }

  @override
  bool isSingleItem() {
    return false;
  }

  static ChordSection parseString(String s, int beatsPerBar) {
    return parse(MarkedString(s), beatsPerBar, false);
  }

  static ChordSection parse(MarkedString markedString, int beatsPerBar, bool strict) {
    if (markedString.isEmpty) throw 'no data to parse';

    markedString.stripLeadingWhitespace(); //  includes newline
    if (markedString.isEmpty) throw 'no data to parse';

    SectionVersion sectionVersion;
    try {
      sectionVersion = SectionVersion.parse(markedString);
    } catch (e) {
      if (strict) rethrow;

      //  cope with badly formatted songs
      sectionVersion = SectionVersion.bySection(Section.get(SectionEnum.verse));
    }

    List<Phrase> phrases = [];
    List<Measure> measures = [];
    List<Measure> lineMeasures = [];
    //  bool repeatMarker = false;
    Measure? lastMeasure;
    for (int i = 0; i < 2000; i++) //  arbitrary safety hard limit
    {
      markedString.stripLeadingWhitespace();
      if (markedString.isEmpty) break;

      //  quit if next section found
      if (Section.lookahead(markedString)) break;

      try {
        //  look for a block repeat
        MeasureRepeat measureRepeat = MeasureRepeat.parse(markedString, phrases.length, beatsPerBar, null);
        //  don't assume every line has an eol
        for (Measure m in lineMeasures) {
          measures.add(m);
        }
        lineMeasures = [];
        if (measures.isNotEmpty) {
          phrases.add(Phrase(measures, phrases.length));
        }
        measureRepeat.setPhraseIndex(phrases.length);
        phrases.add(measureRepeat);
        measures = [];
        lastMeasure = null;
        continue;
      } catch (e) {
        //  ignore
      }

      try {
        //  look for a phrase
        Phrase phrase = Phrase.parse(markedString, phrases.length, beatsPerBar, null);
        //  don't assume every line has an eol
        for (Measure m in lineMeasures) {
          measures.add(m);
        }
        lineMeasures = [];
        if (measures.isNotEmpty) {
          phrases.add(Phrase(measures, phrases.length));
        }
        phrase.setPhraseIndex(phrases.length);
        phrases.add(phrase);
        measures = [];
        lastMeasure = null;
        continue;
      } catch (e) {
        //  ignore
      }

      try {
        //  add a measure to the current line measures
        Measure measure = Measure.parse(markedString, beatsPerBar, lastMeasure);
        lineMeasures.add(measure);
        lastMeasure = measure;
        continue;
      } catch (e) {
        //  ignore
      }

      //  consume unused commas
      {
        String s = markedString.remainingStringLimited(10);
        logger.d('s: ' + s);
        RegExpMatch? mr = commaRegexp.firstMatch(s);
        if (mr != null) {
          markedString.consume(mr.group(0)!.length);
          continue;
        }
      }

      try {
        //  look for a comment
        MeasureComment measureComment = MeasureComment.parse(markedString);
        for (Measure m in lineMeasures) {
          measures.add(m);
        }
        lineMeasures.clear();
        lineMeasures.add(measureComment);
        continue;
      } catch (e) {
        //  ignore
      }

      //  chordSection has no choice, force junk into a comment
      {
        int n = markedString.indexOf('\n'); //  all comments end at the end of the line
        String s = '';
        if (n > 0) {
          s = markedString.remainingStringLimited(n + 1);
        } else {
          s = markedString.toString();
        }

        RegExpMatch? mr = commentRegExp.firstMatch(s);

        //  consume the comment
        if (mr != null) {
          s = mr.group(1) ?? '';
          markedString.consume(mr.group(0)!.length);
          //  cope with unbalanced leading ('s and trailing )'s
          s = s.replaceAll('^\\(', '').replaceAll(r'\)$', '');
          s = s.trim(); //  in case there is white space inside unbalanced parens

          MeasureComment measureComment = MeasureComment(s);
          for (Measure m in lineMeasures) {
            measures.add(m);
          }
          lineMeasures.clear();
          lineMeasures.add(measureComment);
          continue;
        } else {
          logger.i('here: ' + s);
        }
      }
      logger.i("can't figure out: " + markedString.toString());
      throw "can't figure out: " + markedString.toString(); //  all whitespace
    }

//  don't assume every line has an eol
    for (Measure m in lineMeasures) {
      measures.add(m);
    }
    if (measures.isNotEmpty) {
      phrases.add(Phrase(measures, phrases.length));
    }

    ChordSection ret = ChordSection(sectionVersion, phrases);
    return ret;
  }

  bool add(int index, MeasureNode? newMeasureNode) {
    if (newMeasureNode == null) return false;

    switch (newMeasureNode.getMeasureNodeType()) {
      case MeasureNodeType.repeat:
      case MeasureNodeType.phrase:
        break;
      default:
        return false;
    }

    Phrase newPhrase = newMeasureNode as Phrase;

    if (_phrases.isEmpty) {
      _phrases.add(newPhrase);
      return true;
    }

    try {
      _addPhraseAt(index, newPhrase);
    } catch (e) {
      _phrases.add(newPhrase); //  default to the end!
    }
    return true;
  }

  bool insert(int index, MeasureNode? newMeasureNode) {
    if (newMeasureNode == null) return false;

    switch (newMeasureNode.getMeasureNodeType()) {
      case MeasureNodeType.repeat:
      case MeasureNodeType.phrase:
        break;
      default:
        return false;
    }

    Phrase newPhrase = newMeasureNode as Phrase;

    if (_phrases.isEmpty) {
      _phrases.add(newPhrase);
      return true;
    }

    try {
      _addPhraseAt(index, newPhrase);
    } catch (e) {
      _phrases.add(newPhrase); //  default to the end!
    }
    return true;
  }

  void _addPhraseAt(int index, Phrase m) {
    if (_phrases.length < index) {
      _phrases.add(m);
    } else {
      _phrases.insert(index + 1, m);
    }
  }

//  void _addAllPhrasesAt(int index, List<Phrase> list) {
//    if (_phrases == null) _phrases = List();
//    if (_phrases.length < index)
//      _phrases.addAll(list);
//    else {
//      for (Phrase phrase in list) _phrases.insert(index++ + 1, phrase);
//    }
//  }

  MeasureNode? findMeasureNode(MeasureNode measureNode) {
    for (Phrase measureSequenceItem in phrases) {
      if (measureSequenceItem == measureNode) return measureSequenceItem;
      MeasureNode? mn = measureSequenceItem.findMeasureNode(measureNode);
      if (mn != null) return mn;
    }
    return null;
  }

  int findMeasureNodeIndex(MeasureNode measureNode) {
    int index = 0;
    for (Phrase phrase in phrases) {
      int i = phrase.findMeasureNodeIndex(measureNode);
      if (i >= 0) return index + i;
      index += phrase.length;
    }
    return -1;
  }

  Phrase? findPhrase(MeasureNode measureNode) {
    for (Phrase phrase in phrases) {
      if (phrase == measureNode || phrase.contains(measureNode)) return phrase;
    }
    return null;
  }

  int findPhraseIndex(MeasureNode measureNode) {
    for (int i = 0; i < phrases.length; i++) {
      Phrase p = phrases[i];
      if (measureNode == p || p.contains(measureNode)) {
        return i;
      }
    }
    return -1;
  }

  int indexOf(Phrase phrase) {
    for (int i = 0; i < phrases.length; i++) {
      Phrase? p = phrases[i];
      if (phrase == p) return i;
    }
    return -1;
  }

  Measure? getMeasure(int phraseIndex, int measureIndex) {
    try {
      Phrase? phrase = getPhrase(phraseIndex);
      return phrase?.getMeasure(measureIndex);
    } catch (e) {
      return null;
    }
  }

  Measure? get firstMeasure {
    try {
      return phrases.first.firstMeasure;
    } catch (e) {
      return null;
    }
  }

  Measure? get lastMeasure {
    try {
      return phrases.last.lastMeasure;
    } catch (e) {
      return null;
    }
  }

  bool deletePhrase(int phraseIndex) {
    try {
      _phrases.removeAt(phraseIndex);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool deleteMeasure(int phraseIndex, int measureIndex) {
    try {
      Phrase? phrase = getPhrase(phraseIndex);
      bool ret = phrase?.deleteAt(measureIndex) ?? false;
      if (ret && (phrase?.isEmpty() ?? true)) return deletePhrase(phraseIndex);
      return ret;
    } catch (e) {
      return false;
    }
  }

  int getTotalMoments() {
    int total = 0;
    for (Phrase measureSequenceItem in _phrases) {
      total += measureSequenceItem.getTotalMoments();
    }
    return total;
  }

  /**
   * Return the sectionVersion beats per minute
   * or null to default to the song BPM.
   *
   * @return the sectionVersion BPM or null
   */
//   Integer getBeatsPerMinute() {
//    return bpm;
//}

  /// Return the sections's number of beats per bar or null to default to the song's number of beats per bar
//       Integer getBeatsPerBar() {
//        return beatsPerBar;
//    }

  @override
  String getId() {
    return _sectionVersion.id;
  }

  @override
  MeasureNodeType getMeasureNodeType() {
    return MeasureNodeType.section;
  }

  MeasureNode? lastMeasureNode() {
    if (isEmpty()) {
      return this;
    }
    Phrase? measureSequenceItem = _phrases[_phrases.length - 1];
    List<Measure> measures = measureSequenceItem.measures;
    if ( measures.isEmpty) return measureSequenceItem;
    return measures[measures.length - 1];
  }

  @override
  String transpose(Key key, int halfSteps) {
    StringBuffer sb = StringBuffer();
    sb.write(sectionVersion.toString());
    for (Phrase phrase in _phrases) {
      sb.write(phrase.transpose(key, halfSteps));
    }

    return sb.toString();
  }

  @override
  MeasureNode transposeToKey(Key? key) {
    if (key == null) return this;
    List<Phrase>? newPhrases;
    newPhrases = [];
    for (Phrase phrase in _phrases) {
      newPhrases.add(phrase.transposeToKey(key) as Phrase);
    }
    return ChordSection(_sectionVersion, newPhrases);
  }

  @override
  String toMarkup() {
    StringBuffer sb = StringBuffer();
    sb.write(sectionVersion.toString());
    sb.write(' ');
    sb.write(phrasesToMarkup());
    return sb.toString();
  }

  String phrasesToMarkup() {
    if (isEmpty()) {
      return '[] ';
    }
    StringBuffer sb = StringBuffer();
    for (Phrase phrase in _phrases) {
      sb.write(phrase.toMarkup());
    }
    return sb.toString();
  }

  @override
  String toEntry() {
    StringBuffer sb = StringBuffer();
    sb.write(sectionVersion.toString());
    sb.write('\n ');
    sb.write(phrasesToEntry());
    return sb.toString();
  }

  @override
  bool setMeasuresPerRow(int measuresPerRow) {
    if (measuresPerRow <= 0) return false;

    bool ret = false;
    for (Phrase phrase in _phrases) {
      ret = ret || phrase.setMeasuresPerRow(measuresPerRow);
    }
    return ret;
  }

  String phrasesToEntry() {
    if (isEmpty()) {
      return '[]';
    }
    StringBuffer sb = StringBuffer();
    for (Phrase phrase in _phrases) {
      sb.write(phrase.toEntry());
    }
    return sb.toString();
  }

  @override
  String toJson() {
    StringBuffer sb = StringBuffer();
    sb.write(sectionVersion.toString());
    sb.write('\n');
    if (isEmpty()) {
      sb.write('[]');
    } else {
      for (Phrase phrase in _phrases) {
        String s = phrase.toJson();
        sb.write(s);
        if (!s.endsWith('\n')) {
          sb.write('\n');
        }
      }
    }
    return sb.toString();
  }

  ///Old style markup
  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write(sectionVersion.toString());
    sb.write('\n');
    if (_phrases.isNotEmpty) {
      for (Phrase phrase in _phrases) {
        sb.write(phrase.toString());
      }
    }
    return sb.toString();
  }

  Section getSection() {
    return _sectionVersion.section;
  }

  Phrase? getPhrase(int index) {
    return _phrases[index];
  }

  void setPhrases(List<Phrase> phrases) {
    _phrases = phrases;
  }

  int getPhraseCount() {
    return _phrases.length;
  }

  /// sum all the measures in all the phrases
  int get measureCount {
    int measureCount = 0;
    for (Phrase phrase in _phrases) {
      measureCount += phrase.measureCount;
    }
    return measureCount;
  }

  Phrase? lastPhrase() {
    if (_phrases.isEmpty) {
      return null;
    }
    return _phrases[_phrases.length - 1];
  }

  int get chordRowCount {
    if (isEmpty()) {
      return 0;
    }
    int chordRowCount = 0;
    for (Phrase phrase in _phrases) {
      chordRowCount += phrase.chordRowCount;
    }
    return chordRowCount;
  }

  @override
  bool isEmpty() {
    if (_phrases.isEmpty) {
      return true;
    }
    for (Phrase phrase in _phrases) {
      if (!phrase.isEmpty()) {
        return false;
      }
    }
    return true;
  }

  /// Compares this object with the specified object for order.  Returns a
  /// negative integer, zero, or a positive integer as this object is less
  /// than, equal to, or greater than the specified object.
  @override
  int compareTo(ChordSection o) {
    int ret = _sectionVersion.compareTo(o._sectionVersion);
    if (ret != 0) return ret;

    if (_phrases.length != o._phrases.length) return _phrases.length < o._phrases.length ? -1 : 1;

    for (int i = 0; i < _phrases.length; i++) {
      ret = _phrases[i].toMarkup().compareTo(o._phrases[i].toMarkup());
      if (ret != 0) return ret;
    }
    return 0;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    if (!(runtimeType == other.runtimeType && other is ChordSection && _sectionVersion == other._sectionVersion && measureCount == other.measureCount)) {
      return false;
    }
    //  deal with empty-ish phrases
    if (measureCount == 0) {
      //  only works since the measure counts are identical
      return true;
    }
    return listsEqual(_phrases, other._phrases);
  }

  @override
  int get hashCode {
    int ret = _sectionVersion.hashCode;
    ret = ret * 17 + hashObjects(_phrases);
    return ret;
  }

  SectionVersion get sectionVersion => _sectionVersion;
  final SectionVersion _sectionVersion;

  List<Phrase> get phrases => _phrases;
  List<Phrase> _phrases;

  static RegExp commaRegexp = RegExp('^\\s*,');
  static RegExp commentRegExp = RegExp('^(\\S+)\\s+');
}
