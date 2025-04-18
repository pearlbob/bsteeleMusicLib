import 'dart:math';

import '../grid.dart';
import 'package:quiver/collection.dart';
import 'package:quiver/core.dart';

import '../app_logger.dart';
import '../util/util.dart';
import 'key.dart';
import 'measure.dart';
import 'measure_comment.dart';
import 'measure_node.dart';
import 'measure_repeat.dart';
import 'phrase.dart';
import 'section.dart';
import 'section_version.dart';

/// A chord section of a song is typically a collection of measures
/// that constitute a portion of the song that is considered musically a unit.
/// Immutable.
class ChordSection extends MeasureNode implements Comparable<ChordSection> {
  ChordSection(this.sectionVersion, List<Phrase>? phrases) : _phrases = (phrases ?? []);

  static ChordSection getDefault() {
    return ChordSection(SectionVersion.defaultInstance, null);
  }

  @override
  bool isSingleItem() {
    return false;
  }

  static ChordSection parseString(String s, int beatsPerBar) {
    return parse(MarkedString(s), beatsPerBar, false);
  }

  static ChordSection parse(MarkedString markedString, int beatsPerBar, bool strict) {
    if (markedString.isEmpty) {
      throw 'no data to parse';
    }

    markedString.stripLeadingWhitespace(); //  includes newline
    if (markedString.isEmpty) {
      throw 'no data to parse';
    }

    SectionVersion sectionVersion;
    try {
      sectionVersion = SectionVersion.parse(markedString);
    } catch (e) {
      if (strict) {
        rethrow;
      }

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
      if (markedString.isEmpty) {
        break;
      }

      //  quit if next section found
      if (Section.lookahead(markedString)) {
        break;
      }

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

      //  if it's not one of the above, it's a comment

      //  if strict, no comments allowed
      if (strict) {
        throw 'proper measure nodes not found';
      }

      //  consume unused commas
      {
        String s = markedString.remainingStringLimited(10);
        logger.t('s: $s');
        RegExpMatch? mr = _commaRegexp.firstMatch(s);
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

        RegExpMatch? mr = _commentRegExp.firstMatch(s);

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
          logger.i('ChordSection parse: junk found: $s');
        }
      }
      logger.i("can't figure out: $markedString");
      throw "can't figure out: $markedString"; //  all whitespace
    }

    //  don't assume every line has an eol
    for (Measure m in lineMeasures) {
      measures.add(m);
    }
    if (measures.isNotEmpty) {
      phrases.add(Phrase(measures, phrases.length));
    }

    if (strict) {
      //  don't allow empty phrases
      for (var phrase in phrases) {
        if (phrase.isEmpty) {
          throw 'Empty phrases not allowed';
        }
      }
    }

    ChordSection ret = ChordSection(sectionVersion, phrases);
    return ret;
  }

  bool add(int index, MeasureNode? newMeasureNode) {
    if (newMeasureNode == null) {
      return false;
    }

    switch (newMeasureNode.measureNodeType) {
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
    _renumberPhraseIndexes();
    return true;
  }

  bool insert(int index, MeasureNode? newMeasureNode) {
    if (newMeasureNode == null) {
      return false;
    }

    switch (newMeasureNode.measureNodeType) {
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
      if (_phrases.length < index) {
        _phrases.add(newPhrase);
      } else {
        _phrases.insert(index, newPhrase);
      }
    } catch (e) {
      _phrases.add(newPhrase); //  default to the end!
    }
    return true;
  }

  void _addPhraseAt(int index, Phrase m) {
    if (_phrases.length < index) {
      _phrases.add(m);
    } else {
      _phrases.insert(index, m);
    }
  }

  /// Collapse adjacent phrases into a single phrase
  /// that have come together due to an edit.
  bool collapsePhrases() {
    int limit = getPhraseCount();
    if (limit <= 1) {
      return false;
    } //  no work to do

    bool ret = false;
    Phrase? lastPhrase;
    for (int i = 0; i < getPhraseCount(); i++) {
      Phrase? phrase = getPhrase(i);
      assert(phrase != null);
      if (phrase!.isEmpty) {
        deletePhrase(i);
        ret = true;
        i--; //  back up and collapse with the new version as the lastPhrase!   fixme: too tricky
        continue;
      }
      if (lastPhrase == null) {
        if (phrase.measureNodeType == MeasureNodeType.phrase) {
          lastPhrase = phrase;
        }
        continue;
      }
      if (phrase.measureNodeType == MeasureNodeType.phrase) {
        //  join two contiguous phrases
        lastPhrase.lastMeasure?.endOfRow = true; //  assure odd rows are preserved
        lastPhrase.add(phrase.measures);
        deletePhrase(i);
        ret = true;
        i--; //  back up and collapse with the new version as the lastPhrase!   fixme: too tricky
      } else {
        lastPhrase = null;
      }
    }
    if (ret) {
      //  re-number the phrases on a collapse
      var i = 0;
      for (var phase in _phrases) {
        phase.setPhraseIndex(i++);
      }
    }
    return ret;
  }

  MeasureNode? findMeasureNode(MeasureNode measureNode) {
    for (Phrase measureSequenceItem in phrases) {
      if (measureSequenceItem == measureNode) {
        return measureSequenceItem;
      }
      MeasureNode? mn = measureSequenceItem.findMeasureNode(measureNode);
      if (mn != null) {
        return mn;
      }
    }
    return null;
  }

  int findMeasureNodeIndex(MeasureNode measureNode) {
    int index = 0;
    for (Phrase phrase in phrases) {
      int i = phrase.findMeasureNodeIndex(measureNode);
      if (i >= 0) {
        return index + i;
      }
      index += phrase.length;
    }
    return -1;
  }

  Phrase? findPhrase(MeasureNode measureNode) {
    for (Phrase phrase in phrases) {
      if (phrase == measureNode || phrase.contains(measureNode)) {
        return phrase;
      }
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
      if (phrase == p) {
        return i;
      }
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
      _renumberPhraseIndexes();
      return true;
    } catch (e) {
      return false;
    }
  }

  void _renumberPhraseIndexes() {
    //  fixme: remove phraseIndex?
    //  re-number the phrases
    var i = 0;
    for (var phase in _phrases) {
      phase.setPhraseIndex(i++);
    }
  }

  bool deleteMeasure(int phraseIndex, int measureIndex) {
    try {
      Phrase? phrase = getPhrase(phraseIndex);
      bool ret = phrase?.deleteAt(measureIndex) ?? false;
      if (ret && (phrase?.isEmpty ?? true)) {
        return deletePhrase(phraseIndex);
      }
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

  @override
  MeasureNodeType get measureNodeType => MeasureNodeType.section;

  MeasureNode? lastMeasureNode() {
    if (isEmpty) {
      return this;
    }
    Phrase? measureSequenceItem = _phrases[_phrases.length - 1];
    List<Measure> measures = measureSequenceItem.measures;
    if (measures.isEmpty) {
      return measureSequenceItem;
    }
    return measures[measures.length - 1];
  }

  @override
  String transpose(Key key, int halfSteps) {
    StringBuffer sb = StringBuffer();
    // sb.write(sectionVersion.toString());
    for (var phrase in _phrases) {
      sb.write(phrase.transpose(key, halfSteps));
    }

    return sb.toString();
  }

  int get beatCount {
    var beats = 0;
    for (var phrase in _phrases) {
      beats += phrase.beatCount * phrase.repeats;
    }
    return beats;
  }

  @override
  String toNashville(Key key) {
    var sb = StringBuffer();
    for (var phrase in _phrases) {
      sb.write(phrase.toNashville(key));
    }
    return sb.toString().trim();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}

  @override
  MeasureNode transposeToKey(Key? key) {
    if (key == null) {
      return this;
    }
    List<Phrase>? newPhrases;
    newPhrases = [];
    for (Phrase phrase in _phrases) {
      newPhrases.add(phrase.transposeToKey(key) as Phrase);
    }
    return ChordSection(sectionVersion, newPhrases);
  }

  String toMarkupInRows(int lines) // fixme: worry about this is being complex and fragile
  {
    _LineCounts lineCounts = _LineCounts(lines, repeatRowCount);
    logger.d('toMarkupInRows($lines):');

    var sb = StringBuffer(sectionVersion.toString());
    sb.write(lineCounts.newLine(''));

    for (var phrase in phrases) {
      var repeatReps = phrase is MeasureRepeat ? phrase.repeats : 1;
      var reps = (repeatReps > 0 ? repeatReps : 1);
      for (var rep = 0; rep < reps; rep++) {
        var whiteSpace = phrase.markupStart();
        for (var m in phrase.measures) {
          sb.write(whiteSpace);
          whiteSpace = ' ';
          sb.write(m.toMarkupWithoutEnd());
          if (identical(m, phrase.measures.last)) {
            var me = phrase.markupEnd(rep: reps == 1 ? null : rep + 1);
            sb.write(me);
            var nl = lineCounts.newLine(me.isEmpty && reps == 1 && !identical(phrase, phrases.last) ? ' ' : '');
            sb.write(nl);
            if (reps > 1 && lineCounts.isDone && rep < reps - 1 && nl.isEmpty) {
              sb.write(' ');
            }
          } else if (m.endOfRow) {
            sb.write(lineCounts.newLine(','));
          }
        }
      }
      for (var rep = reps; rep < repeatReps; rep++) {
        sb.write(lineCounts.newLine(''));
      }
    }
    sb.writeln('');

    return sb.toString();
  }

  @override
  String toMarkup({bool withInversion = true}) {
    StringBuffer sb = StringBuffer();
    sb.write(sectionVersion.toString());
    sb.write(' ');
    sb.write(phrasesToMarkup());
    return sb.toString();
  }

  String phrasesToMarkup() {
    if (isEmpty) {
      return '[] ';
    }
    StringBuffer sb = StringBuffer();
    for (Phrase phrase in _phrases) {
      sb.write(phrase.toMarkup());
    }
    return sb.toString();
  }

  @override
  String toMarkupWithoutEnd() {
    StringBuffer sb = StringBuffer();
    sb.write(sectionVersion.toString());
    sb.write(' ');
    sb.write(phrasesToMarkup());
    return sb.toString();
  }

  String phrasesToMarkupWithoutEnd() {
    if (isEmpty) {
      return '[] ';
    }
    StringBuffer sb = StringBuffer();
    for (Phrase phrase in _phrases) {
      sb.write(phrase.toMarkupWithoutEnd());
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
    if (measuresPerRow <= 0) {
      return false;
    }

    bool ret = false;
    for (Phrase phrase in _phrases) {
      ret = ret || phrase.setMeasuresPerRow(measuresPerRow);
    }
    return ret;
  }

  String phrasesToEntry() {
    if (isEmpty) {
      return '  []';
    }
    StringBuffer sb = StringBuffer();
    for (Phrase phrase in _phrases) {
      sb.write(phrase.toEntry());
    }
    return sb.toString();
  }

  @override
  String toJsonString() {
    StringBuffer sb = StringBuffer();
    sb.write(sectionVersion.toString());
    sb.write('\n');
    if (isEmpty) {
      sb.write('[]');
    } else {
      for (Phrase phrase in _phrases) {
        String s = phrase.toJsonString();
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
    return '${sectionVersion.toString()}\n${phrasesToString()}';
  }

  String phrasesToString() {
    StringBuffer sb = StringBuffer();
    for (Phrase phrase in _phrases) {
      sb.write(phrase.toString());
    }
    return sb.toString();
  }

  Section getSection() {
    return sectionVersion.section;
  }

  Phrase? getPhrase(int index) {
    if (index < 0 || index >= _phrases.length) {
      return null;
    }
    return _phrases[index];
  }

  void setPhrases(List<Phrase> phrases) {
    _phrases = phrases;
  }

  ///  note: these measures do not include the repeat markers
  int maxMeasuresPerChordRow() {
    var columns = 0;
    for (var phrase in phrases) {
      columns = max(columns, phrase.chordRowMaxLength());
    }
    return columns;
  }

  Grid<MeasureNode> toGrid({int? chordColumns, bool? expanded}) {
    var grid = Grid<MeasureNode>();

    chordColumns = max(chordColumns ?? 0, maxMeasuresPerChordRow());
    {
      var col = 0;
      grid.set(0, col++, this);
      while (col < chordColumns) {
        grid.set(0, col++, null);
      }
    }

    for (var phrase in phrases) {
      grid.add(phrase.toGrid(chordColumns: chordColumns));
    }
    return grid;
  }

  int getPhraseCount() {
    return _phrases.length;
  }

  /// sum all the measures in all the phrases
  int get repeatMeasureCount {
    int measureCount = 0;
    for (Phrase phrase in _phrases) {
      measureCount += phrase.repeatMeasureCount;
    }
    return measureCount;
  }

  ///  maximum number of measures in a chord row
  int chordRowMaxLength() {
    var ret = 0;
    for (var phrase in _phrases) {
      ret = max(ret, phrase.chordRowMaxLength());
    }
    return ret;
  }

  int get repeatRowCount {
    var ret = 0;
    for (var phrase in _phrases) {
      ret += phrase.repeatRowCount;
    }
    return ret;
  }

  int get phraseRowCount {
    var ret = 0;
    for (var phrase in _phrases) {
      ret += phrase.phraseRowCount;
    }
    return ret;
  }

  //  used for edit row chording
  List<Measure> rowAt(final int desiredIndex) {
    //  walk through all prior measures //  fixme: efficiency?
    var index = desiredIndex;
    for (var phrase in _phrases) {
      var row = phrase.rowAt(index);
      if (row.isNotEmpty) {
        return row;
      }
      index -= phrase.repeatRowCount;
    }

    return <Measure>[];
  }

  Measure? measureAt(int index) {
    for (var phrase in _phrases) {
      var measureCount = phrase.repeatMeasureCount;
      if (index >= measureCount) {
        index -= measureCount;
      } else {
        return phrase.repeatMeasureAt(index);
      }
    }
    return null;
  }

  Phrase? lastPhrase() {
    if (_phrases.isEmpty) {
      return null;
    }
    return _phrases[_phrases.length - 1];
  }

  /// Get the number of rows in this phrase after griding, with repeat expansion.
  @override
  int get chordExpandedRowCount {
    if (isEmpty) {
      return 0;
    }
    int chordRowCount = 0;
    for (Phrase phrase in _phrases) {
      chordRowCount += phrase.chordExpandedRowCount;
    }
    return chordRowCount;
  }

  @override
  bool get isEmpty {
    if (_phrases.isEmpty) {
      return true;
    }
    for (Phrase phrase in _phrases) {
      if (!phrase.isEmpty) {
        return false;
      }
    }
    return true;
  }

  @override
  bool get isNotEmpty {
    return !isEmpty;
  }

  /// Compares this object with the specified object for order.  Returns a
  /// negative integer, zero, or a positive integer as this object is less
  /// than, equal to, or greater than the specified object.
  @override
  int compareTo(ChordSection o) {
    int ret = sectionVersion.compareTo(o.sectionVersion);
    if (ret != 0) {
      return ret;
    }

    if (_phrases.length != o._phrases.length) {
      return _phrases.length < o._phrases.length ? -1 : 1;
    }

    for (int i = 0; i < _phrases.length; i++) {
      ret = _phrases[i].toMarkup().compareTo(o._phrases[i].toMarkup());
      if (ret != 0) {
        return ret;
      }
    }
    return 0;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    if (!(runtimeType == other.runtimeType &&
        other is ChordSection &&
        sectionVersion == other.sectionVersion &&
        repeatMeasureCount == other.repeatMeasureCount)) {
      return false;
    }
//  deal with empty-ish phrases
    if (phraseRowCount == 0) {
//  only works since the measure counts are identical
      return true;
    }
    return listsEqual(_phrases, other._phrases);
  }

  @override
  int get hashCode {
    int ret = sectionVersion.hashCode;
    ret = ret * 17 + hashObjects(_phrases);
    return ret;
  }

  final SectionVersion sectionVersion;

  List<Phrase> get phrases => _phrases;
  List<Phrase> _phrases;

  static final RegExp _commaRegexp = RegExp('^\\s*,');
  static final RegExp _commentRegExp = RegExp('^(\\S+)\\s+');
}

class _LineCounts {
  _LineCounts(this.lines, int rows) {
    lines = max(lines - 1, 0); //  remove one for the section version
    rowLines = lines;
    if (rowLines <= 1) {
      linesPerRow = 0;
      extraLines = 0;
    } else {
      linesPerRow = rowLines ~/ rows;
      extraLines = rowLines % rows;
    }
  }

  bool get isDone => first == false && line >= lines - 1;

  int lines;
  int rowLines = 0;
  int line = 0;
  int linesPerRow = 0;
  int extraLines = 0;
  bool first = true; //  deal with the section version as a special

  String newLine(String whiteSpace) {
    if (first) {
      first = false;
      return lines > 0 ? '\n' : '';
    }
    if (line < lines - 1) {
      String ret = '';
      for (int i = 0; i < linesPerRow; i++) {
        if (line < lines - 1) {
          ret += '\n';
          line++;
        } else {
          break;
        }
      }
      if (extraLines > 0) {
        extraLines--;

        if (line < lines - 1) {
          ret += '\n';
          line++;
        }
      }

      if (ret.isNotEmpty) {
        return ret;
      }
    }
    return whiteSpace;
  }
}
