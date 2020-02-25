import 'dart:math';

import 'package:quiver/collection.dart';
import 'package:quiver/core.dart';

import '../util/util.dart';
import 'Chord.dart';
import 'MeasureNode.dart';
import 'Section.dart';
import 'Key.dart';

/// A measure in a section of a song.
/// Holds the lyrics, the chord changes and their beats.
/// <p>
/// When added, chord beat durations exceeding the measure beat count will be ignored on playback.
/// </p>
class Measure extends MeasureNode implements Comparable<Measure> {
  /// A convenience constructor to build a typical measure.
  Measure(this.beatCount, this.chords) {
    allocateTheBeats();
  }

  Measure.deepCopy(Measure measure) {
    if (measure == null) return;

    this.beatCount = measure.beatCount;

    //  deep copy
    List<Chord> chords = new List();
    for (Chord chord in measure.chords) {
      chords.add(new Chord.copy(chord));
    }
    this.chords = chords;

    this.endOfRow = measure.endOfRow;
  }

  /// for subclasses
  Measure.zeroArgs()
      : beatCount = 4,
        chords = null;

  /// Convenience method for testing only
  static Measure parseString(String s, int beatsPerBar, {bool endOfRow}) {
    return parse(new MarkedString(s), beatsPerBar, null, endOfRow: endOfRow);
  }

  /// Parse a measure from the input string
  static Measure parse(final MarkedString markedString, final int beatsPerBar,
      final Measure priorMeasure,
      {bool endOfRow}) {
    //  should not be white space, even leading, in a measure
    if (markedString == null || markedString.isEmpty) throw "no data to parse";

    List<Chord> chords = new List();
    Measure ret;

    for (int i = 0; i < 32; i++) //  safety
    {
      if (markedString.isEmpty) break;

      //  assure this is not a section
      if (Section.lookahead(markedString)) break;

      int mark = markedString.mark();
      try {
        Chord chord = Chord.parse(markedString, beatsPerBar);
        chords.add(chord);
      } catch (e) {
        markedString.resetTo(mark);

        //  see if this is a chordless measure
        if (markedString.charAt(0) == 'X') {
          ret = new Measure(beatsPerBar, emptyChordList);
          markedString.getNextChar();
          break;
        }

        //  see if this is a repeat measure
        if (chords.isEmpty &&
            markedString.charAt(0) == '-' &&
            priorMeasure != null) {
          ret = new Measure(beatsPerBar, priorMeasure.chords);
          markedString.getNextChar();
          break;
        }
        break;
      }
    }
    if (ret == null && chords.isEmpty) throw "no chords found";

    if (ret == null) ret = Measure(beatsPerBar, chords);

    //  process end of row markers
    RegExpMatch mr = sectionRegexp.firstMatch(markedString.toString());
    if (mr != null) {
      markedString.consume(mr.group(0).length);
      endOfRow = true;
    }

    if (endOfRow != null) ret.endOfRow = endOfRow;

    return ret;
  }

  void allocateTheBeats() {
    // allocate the beats
    //  try to deal with over-specified beats: eg. in 4/4:  E....A...
    if (chords != null && chords.length > 0) {
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
      if (explicitBeats + (chords.length - explicitChords) >
          beatCount) // fixme: better failure
        return; //  too many beats!  even if the unspecified chords only got 1

      //  verify not under specified
      if (chords.length == explicitChords && explicitBeats < beatCount) {
        //  a short measure
        for (Chord c in chords) {
          c.implicitBeats = false;
        }
        beatCount = explicitBeats;
        return;
      }

      if (explicitBeats == 0 &&
          explicitChords == 0 &&
          beatCount % chords.length == 0) {
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
          Chord firstUnspecifiedChord;
          int beatsPerUnspecifiedChord = max(1,
              (beatCount - explicitBeats) ~/ (chords.length - explicitChords));
          for (Chord c in chords) {
            c.implicitBeats = false;
            if (c.beats == beatCount) {
              if (firstUnspecifiedChord == null) firstUnspecifiedChord = c;
              c.beats = beatsPerUnspecifiedChord;
              totalBeats += beatsPerUnspecifiedChord;
            }
          }
          //  dump all the remaining beats on the first unspecified
          if (firstUnspecifiedChord != null && totalBeats < beatCount) {
            firstUnspecifiedChord.implicitBeats = false;
            firstUnspecifiedChord.beats =
                beatsPerUnspecifiedChord + (beatCount - totalBeats);
            totalBeats = beatCount;
          }
        }
        if (totalBeats == beatCount) {
          int b = chords[0].beats;
          bool allMatch = true;
          for (Chord c in chords) allMatch &= (c.beats == b);
          if (allMatch) {
            //  reduce the over specification
            for (Chord c in chords) c.implicitBeats = true;
          } else if (totalBeats > 1) {
            //  reduce the over specification
            for (Chord c in chords) if (c.beats == 1) c.implicitBeats = true;
          }
        }
      }
    }
  }

  Chord getChordAtBeat(double beat) {
    if (chords == null || chords.isEmpty) return null;

    double beatSum = 0;
    for (Chord chord in chords) {
      beatSum += chord.beats;
      if (beat <= beatSum) return chord;
    }
    return chords[chords.length - 1];
  }

  @override
  String transpose(Key key, int halfSteps) {
    if (chords != null && chords.isNotEmpty) {
      StringBuffer sb = new StringBuffer();
      for (Chord chord in chords) {
        sb.write(chord.transpose(key, halfSteps).toString());
      }
      return sb.toString();
    }
    return "X"; // no chords
  }

  @override
  MeasureNode transposeToKey(Key key) {
    if (chords != null && chords.isNotEmpty) {
      List<Chord> newChords = new List();
      for (Chord chord in chords) {
        newChords.add(chord.transpose(key, 0));
      }
      if (newChords == chords) return this;
      Measure ret = new Measure(beatCount, newChords);
      ret.endOfRow = endOfRow;
      return ret;
    }
    return this;
  }

  bool isEasyGuitarMeasure() {
    return chords != null &&
        chords.length == 1 &&
        chords[0].scaleChord.isEasyGuitarChord();
  }

  @override
  String toMarkup() {
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
  String toJson() {
    return toMarkupWithEnd(null);
  }

  String toMarkupWithEnd(String endOfRowChar) {
    if (chords != null && chords.isNotEmpty) {
      StringBuffer sb = StringBuffer();
      for (Chord chord in chords) {
        sb.write(chord.toMarkup());
      }
      if (endOfRowChar!=null && endOfRow) sb.write(endOfRowChar);
      return sb.toString();
    }
    if (endOfRowChar!=null && endOfRow) return "X" + endOfRowChar;
    return "X"; // no chords
  }

  @override
  String getId() {
    return null;
  }

  @override
  MeasureNodeType getMeasureNodeType() {
    return MeasureNodeType.measure;
  }

  @override
  String toString() {
    return toMarkup();
  }

  @override
  int compareTo(Measure o) {
    if (beatCount != o.beatCount) return beatCount < o.beatCount ? -1 : 1;
    if (!listsEqual(chords, o.chords)) {
      //  compare the lists
      if (chords == null) return o.chords == null ? 0 : 1;
      if (o.chords == null) return -1;
      if (chords.length != o.chords.length)
        return chords.length < o.chords.length ? -1 : 1;
      for (int i = 0; i < chords.length; i++) {
        int ret = chords[i].compareTo(o.chords[i]);
        if (ret != 0) return ret;
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
        beatCount == other.beatCount &&
        endOfRow == other.endOfRow &&
        listsEqual(chords, other.chords);
  }

  @override
  int get hashCode {
    //  2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97
    int ret = hash2(beatCount, endOfRow);
    if (chords != null) ret = ret * 17 + hashObjects(chords);
    return ret;
  }

  /// The beat count for the measure should be set prior to chord additions
  /// to avoid awkward behavior when chords are added without a count.
  /// Defaults to 4.
  int beatCount = 4; //  default only

  /// indicate that the measure is at the end of it's row of measures in the phrase
  bool endOfRow = false;

  /// The chords to be played over this measure.
  List<Chord> chords = List();

  static final List<Chord> emptyChordList = new List();
  static final Measure defaultMeasure = new Measure(4, emptyChordList);

  static final RegExp sectionRegexp = RegExp("^\\s*(,|\\n)");
}
