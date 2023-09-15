import 'package:bsteele_music_lib/songs/music_constants.dart';
import 'package:quiver/collection.dart';
import 'package:quiver/core.dart';

import '../util/util.dart';
import 'chord.dart';
import 'key.dart';
import 'measure_node.dart';
import 'nashville_note.dart';
import 'section.dart';

/// A measure in a section of a song.
/// Holds the lyrics, the chord changes and their beats.
///
/// When added, chord beat durations exceeding the measure beat count will be ignored on playback.
class Measure extends MeasureNode implements Comparable<Measure> {
  /// A convenience constructor to build a typical measure.
  Measure(this._beatCount, this.chords, {int? beatsPerBar, int? maxBeatCount})
      : _beatsPerBar = beatsPerBar ?? _beatCount {
    _allocateTheBeats(maxBeatCount ?? _beatCount);
  }

  Measure deepCopy() {
    return Measure.parseString(toMarkup(), _beatCount, endOfRow: endOfRow); //  fixme: efficiency?  stability?
  }

  /// for subclasses
  Measure.zeroArgs()
      : _beatCount = MusicConstants.defaultBeatsPerBar,
        _beatsPerBar = MusicConstants.defaultBeatsPerBar,
        chords = [];

  /// Convenience method for testing only
  static Measure parseString(String s, final int beatsPerBar, {final bool endOfRow = false}) {
    return parse(MarkedString(s), beatsPerBar, null, endOfRow: endOfRow);
  }

  /// Parse a measure from the input string
  static Measure parse(final MarkedString markedString, final int beatsPerBar, final Measure? priorMeasure,
      {bool endOfRow = false}) {
    //  should not be white space, even leading, in a measure
    if (markedString.isEmpty) {
      throw 'no data to parse';
    }

    int maxBeatCount = beatsPerBar;
    {
      //  look for leading beat count
      var c = markedString.charAt(0);
      switch (c) {
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
          maxBeatCount = int.parse(c);
          markedString.consume(1);
          break;
      }
    }

    List<Chord> chords = [];
    Measure? ret;

    for (int i = 0; i < 32; i++) //  safety
    {
      assert(i < 30);

      if (markedString.isEmpty) {
        break;
      }

      //  assure this is not a section
      if (Section.lookahead(markedString)) {
        break;
      }

      int mark = markedString.mark();
      try {
        Chord? chord = Chord.parse(markedString, beatsPerBar);
        if (chord != null) {
          chords.add(chord);
        }
      } catch (e) {
        markedString.resetTo(mark);

        //  see if this is a chord less measure
        if (markedString.charAt(0) == 'X') {
          ret = Measure(beatsPerBar, emptyChordList);
          markedString.pop();
          break;
        }

        //  see if this is a repeat measure
        if (chords.isEmpty && markedString.charAt(0) == '-' && priorMeasure != null) {
          ret = Measure(beatsPerBar, priorMeasure.chords);
          markedString.pop();
          break;
        }
        break;
      }
    }
    if (ret == null && chords.isEmpty) {
      throw 'no chords found';
    }

    assert(maxBeatCount <= beatsPerBar);
    ret ??= Measure(maxBeatCount, chords, beatsPerBar: beatsPerBar, maxBeatCount: maxBeatCount);

    //  process end of row markers
    RegExpMatch? mr = sectionRegexp.firstMatch(markedString.toString());
    if (mr != null) {
      markedString.consume(mr.group(0)!.length);
      endOfRow = true;
    }

    ret.endOfRow = endOfRow;

    return ret;
  }

  void _allocateTheBeats(final int maxBeatCount) {
    //  fixme: deal with under specified beats: eg. A.B in 4/4, implement as A.B1.
    // allocate the beats
    //  try to deal with over-specified beats: eg. in 4/4:  E....A...
    if (chords.isEmpty) {
      return;
    }

    //  find the total count of beats, prior to implicit distribution
    int totalBeats = 0;
    bool allMatch = true;
    int defaultBeat = chords.first.beats;
    for (Chord c in chords) {
      totalBeats += c.beats;
      allMatch = allMatch && c.beats == defaultBeat;
    }

    //  verify not over specified
    if (totalBeats > maxBeatCount) {
      _beatCount = maxBeatCount;
      //  fixme: limit the total beats???
      return; //  too many beats!  even if the implicit chords only got 1 beat
    }

    //  abbreviate when appropriate
    if (chords.length == 1) {
      //  silence the explicit beats
      var first = chords.first;
      if (first.implicitBeats == false) {
        _beatCount = first.beats;
        return;
      }

      first.implicitBeats = maxBeatCount == 1 || chords.first.beats == beatsPerBar;
      first.beats = maxBeatCount;
      _beatCount = maxBeatCount;
      return;
    }

    if (allMatch && totalBeats == beatsPerBar) {
      //  silence the explicit beats
      for (Chord c in chords) {
        c.implicitBeats = true;
      }
      _beatCount = beatsPerBar;
      return;
    }

    //  find the total count of beats explicitly specified
    int explicitChords = 0;
    for (Chord c in chords) {
      if (!c.implicitBeats) {
        explicitChords++;
      }
    }

    //  explicit measures must be explicit, i.e. all beats are specified.
    if (explicitChords > 0) {
      //  a short measure
      for (Chord c in chords) {
        c.implicitBeats = false;
      }
      _beatCount = totalBeats;
      return;
    }

    //  allocate the remaining beats to the implicit chords
    int unallocatedBeats = maxBeatCount - totalBeats;
    if (unallocatedBeats > 0 && unallocatedBeats % chords.length == 0) {
      int additionalBeatsPerChord = unallocatedBeats ~/ chords.length;
      for (Chord c in chords) {
        c.beats += additionalBeatsPerChord;
        unallocatedBeats -= additionalBeatsPerChord;
      }
      _beatCount = maxBeatCount;
      return;
    }

    //  a short measure
    for (Chord c in chords) {
      c.implicitBeats = false;
    }
    _beatCount = totalBeats;
  }

  Chord? getChordAtBeat(int beat) {
    if (chords.isEmpty) {
      return null;
    }

    int beatSum = 0;
    for (Chord chord in chords) {
      beatSum += chord.beats;
      if (beatSum >= beat + 1) {
        return chord;
      }
    }
    return null;
  }

  @override
  String transpose(Key key, int halfSteps) {
    if (chords.isNotEmpty) {
      StringBuffer sb = StringBuffer();
      for (Chord chord in chords) {
        sb.write(chord.transpose(key, halfSteps).toMarkup());
      }
      return sb.toString();
    }
    return 'X'; // no chords
  }

  @override
  MeasureNode transposeToKey(Key key) {
    if (chords.isNotEmpty) {
      List<Chord> newChords = [];
      for (Chord chord in chords) {
        newChords.add(chord.transpose(key, 0));
      }
      if (newChords == chords) {
        return this;
      }
      Measure ret = Measure(beatCount, newChords);
      ret.endOfRow = endOfRow;
      return ret;
    }
    return this;
  }

  bool isEasyGuitarMeasure() {
    return chords.length == 1 && chords[0].scaleChord.isEasyGuitarChord();
  }

  @override
  String toMarkup({bool expanded = false}) {
    return _toMarkupWithEnd(',');
  }

  @override
  String toEntry() {
    return _toMarkupWithEnd('\n');
  }

  @override
  bool setMeasuresPerRow(int measuresPerRow) {
    return false;
  }

  @override
  String toNashville(Key key) {
    var sb = StringBuffer();
    var keyOffset = key.getHalfStep();
    for (var chord in chords) {
      sb.write('${NashvilleNote.byHalfStep(chord.scaleChord.scaleNote.halfStep - keyOffset)}'
          '${chord.scaleChord.chordDescriptor.toNashville()}'
          //  fixme: strict Nashville inversions call for fractions
          '${chord.slashScaleNote != null ? '/${NashvilleNote.byHalfStep(chord.slashScaleNote!.halfStep - keyOffset)}' : ''}'
          ' ');
    }
    return sb.toString().trimRight();
  }

  @override
  String toJson() {
    return _toMarkupWithEnd(null);
  }

  @override
  String toMarkupWithoutEnd() {
    return _toMarkupWithEnd(null);
  }

  String _toMarkupWithEnd(String? endOfRowChar) {
    if (chords.isNotEmpty) {
      StringBuffer sb = StringBuffer();
      bool implicitBeats = false;
      for (Chord chord in chords) {
        sb.write(chord.toMarkup());
        implicitBeats = implicitBeats || chord.implicitBeats;
      }
      if (endOfRowChar != null && endOfRow) {
        sb.write(endOfRowChar);
      }
      if (_beatCount < _beatsPerBar && (chords.length > 1 || chords.first.implicitBeats == true)) {
        return '$_beatCount${sb.toString()}';
      }

      return sb.toString();
    }
    if (endOfRowChar != null && endOfRow) {
      return 'X$endOfRowChar';
    }
    return 'X'; // no chords
  }

  @override
  bool get isEmpty {
    return false;
  }

  @override
  MeasureNodeType get measureNodeType => MeasureNodeType.measure;

  bool get hasReducedBeats => beatCount < beatsPerBar;

  @override
  String toString() {
    return toMarkup();
  }

  @override
  int compareTo(Measure o) {
    if (beatCount != o.beatCount) {
      return beatCount < o.beatCount ? -1 : 1;
    }
    if (!listsEqual(chords, o.chords)) {
      //  compare the lists
      if (chords.length != o.chords.length) {
        return chords.length < o.chords.length ? -1 : 1;
      }
      for (int i = 0; i < chords.length; i++) {
        int ret = chords[i].compareTo(o.chords[i]);
        if (ret != 0) {
          return ret;
        }
      }
    }

    return 0;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    return runtimeType == other.runtimeType &&
        other is Measure &&
        beatCount == other.beatCount &&
        endOfRow == other.endOfRow &&
        listsEqual(chords, other.chords);
  }

  @override
  int get hashCode {
    int ret = Object.hash(_beatCount, endOfRow, _beatsPerBar, hashObjects(chords));
    return ret;
  }

  /// The beat count for the measure should be set prior to chord additions
  /// to avoid awkward behavior when chords are added without a count.
  /// Defaults to 4.
  int get beatCount => _beatCount;
  int _beatCount = 4; //  default only

  int get beatsPerBar => _beatsPerBar;
  final int _beatsPerBar;

  /*
  beats  bpb    forms, in order of preference
  1       2     1A
  2       2     A AB
  1       3     1A
  2       3     A. 2A 2AB
  3       3     A A.. A.B AB. ABC
                  AB => A.B  ???
  1       4     1A
  2       4     A. 2A 2AB
  3       4     A.. 3A A.B AB. 3ABC                   not: ABC
                  3AB => AB.  ???
  4       4     A A..B AB A.BC AB.C ABC.              not: ABC   A...
                  AB => A.B.
                  ABC => A.BC ???       not: ABC.  ???
  1       6     1A
  2       6     A. 2A 2AB
  3       6     A.. 3A A.B AB.                      not: ABC
  4       6     A... 4A A..B 4A.B. 4A.BC 4AB.C 4ABC.
  5       6     A.... 5A A...B A..B. A.BC. A.B.C AB..C ABC..
  6       6     A AB A..B.C AB...C ABC...   A.B.C.  not:  ABC  A.....
                  AB => A..B..
                  ABC => A.B.C. ???  likely
   */

  /// indicate that the measure is at the end of it's row of measures in the phrase
  bool endOfRow = false;

  /// The chords to be played over this measure.
  List<Chord> chords = [];

  static final List<Chord> emptyChordList = [];
  static final Measure defaultMeasure = Measure(4, emptyChordList);

  static final RegExp sectionRegexp = RegExp('^\\s*(,|\\n)');
}
