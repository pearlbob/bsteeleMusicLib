import 'dart:math';

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
  Measure(this._beatCount, this.chords) {
    _allocateTheBeats();
  }

  Measure deepCopy() {
    return Measure.parseString(toMarkup(), _beatCount, endOfRow: endOfRow); //  fixme: efficiency?  stability?
  }

  /// for subclasses
  Measure.zeroArgs()
      : _beatCount = 4,
        chords = [];

  /// Convenience method for testing only
  static Measure parseString(String s, int beatsPerBar, {bool endOfRow = false}) {
    return parse(MarkedString(s), beatsPerBar, null, endOfRow: endOfRow);
  }

  /// Parse a measure from the input string
  static Measure parse(final MarkedString markedString, final int beatsPerBar, final Measure? priorMeasure,
      {bool endOfRow = false}) {
    //  should not be white space, even leading, in a measure
    if (markedString.isEmpty) {
      throw 'no data to parse';
    }

    List<Chord> chords = [];
    Measure? ret;

    for (int i = 0; i < 32; i++) //  safety
    {
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

        //  see if this is a chordless measure
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

    ret ??= Measure(beatsPerBar, chords);

    //  process end of row markers
    RegExpMatch? mr = sectionRegexp.firstMatch(markedString.toString());
    if (mr != null) {
      markedString.consume(mr.group(0)!.length);
      endOfRow = true;
    }

    ret.endOfRow = endOfRow;

    return ret;
  }

  void _allocateTheBeats() {
    //  fixme: deal with under specified beats: eg. A.B in 4/4, implement as A.B1.
    // allocate the beats
    //  try to deal with over-specified beats: eg. in 4/4:  E....A...
    if (chords.isNotEmpty) {
      //  find the total count of beats explicitly specified
      int explicitChords = 0;
      int explicitBeats = 0;
      for (Chord c in chords) {
        if (c.beats < beatCount) {
          explicitChords++;
          explicitBeats += c.beats;
        }
      }
      //  verify not over specified
      if (explicitBeats + (chords.length - explicitChords) > beatCount) {
        return; //  too many beats!  even if the unspecified chords only got 1
      }

      //  verify not under specified
      if (chords.length == explicitChords && explicitBeats < beatCount) {
        //  a short measure
        for (Chord c in chords) {
          c.implicitBeats = false;
        }
        _beatCount = explicitBeats;
        return;
      }

      if (explicitBeats == 0 && explicitChords == 0 && beatCount % chords.length == 0) {
        //  spread the implicit beats evenly
        int implicitBeats = beatCount ~/ chords.length;
        //  fixme: why is the cast required?
        for (Chord c in chords) {
          c.beats = implicitBeats;
          c.implicitBeats = true;
        }
      } else {
        //  allocate the remaining beats to the unspecified chords
        //  give left over beats to the first unspecified
        int totalBeats = explicitBeats;
        if (chords.length > explicitChords) {
          Chord? firstUnspecifiedChord;
          int beatsPerUnspecifiedChord = max(1, (beatCount - explicitBeats) ~/ (chords.length - explicitChords));
          for (Chord c in chords) {
            c.implicitBeats = false;
            if (c.beats == beatCount) {
              firstUnspecifiedChord ??= c;
              c.beats = beatsPerUnspecifiedChord;
              totalBeats += beatsPerUnspecifiedChord;
            }
          }
          //  dump all the remaining beats on the first unspecified
          if (firstUnspecifiedChord != null && totalBeats < beatCount) {
            firstUnspecifiedChord.implicitBeats = false;
            firstUnspecifiedChord.beats = beatsPerUnspecifiedChord + (beatCount - totalBeats);
            totalBeats = beatCount;
          }
        }
        if (totalBeats == beatCount) {
          int b = chords[0].beats;
          bool allMatch = true;
          for (Chord c in chords) {
            allMatch &= (c.beats == b);
          }
          if (allMatch) {
            //  reduce the over specification
            for (Chord c in chords) {
              c.implicitBeats = true;
            }
          } else if (totalBeats > 1) {
            //  reduce the over specification
            for (Chord c in chords) {
              if (c.beats == 1) {
                c.implicitBeats = true;
              }
            }
          }
        }
      }
    }
  }

  Chord? getChordAtBeat(double beat) {
    if (chords.isEmpty) {
      return null;
    }

    double beatSum = 0;
    for (Chord chord in chords) {
      beatSum += chord.beats;
      if (beat <= beatSum) {
        return chord;
      }
    }
    return chords[chords.length - 1];
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
    return toMarkupWithEnd(',');
  }

  @override
  String toEntry() {
    return toMarkupWithEnd('\n');
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
    return toMarkupWithEnd(null);
  }

  @override
  String toMarkupWithoutEnd() {
    return toMarkupWithEnd(null);
  }

  String toMarkupWithEnd(String? endOfRowChar) {
    if (chords.isNotEmpty) {
      StringBuffer sb = StringBuffer();
      for (Chord chord in chords) {
        sb.write(chord.toMarkup());
      }
      if (endOfRowChar != null && endOfRow) {
        sb.write(endOfRowChar);
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
    int ret = Object.hash(beatCount, endOfRow, hashObjects(chords));
    return ret;
  }

  /// The beat count for the measure should be set prior to chord additions
  /// to avoid awkward behavior when chords are added without a count.
  /// Defaults to 4.
  int get beatCount => _beatCount;
  int _beatCount = 4; //  default only

  /// indicate that the measure is at the end of it's row of measures in the phrase
  bool endOfRow = false;

  /// The chords to be played over this measure.
  List<Chord> chords = [];

  static final List<Chord> emptyChordList = [];
  static final Measure defaultMeasure = Measure(4, emptyChordList);

  static final RegExp sectionRegexp = RegExp('^\\s*(,|\\n)');
}
