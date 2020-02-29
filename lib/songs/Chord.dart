import 'package:bsteeleMusicLib/songs/scaleChord.dart';
import 'package:bsteeleMusicLib/songs/scaleNote.dart';
import 'package:bsteeleMusicLib/util/util.dart';
import 'package:quiver/core.dart';

import 'ChordAnticipationOrDelay.dart';
import 'Key.dart';

class Chord implements Comparable<Chord> {
  Chord(
      ScaleChord scaleChord,
      int beats,
      int beatsPerBar,
      ScaleNote slashScaleNote,
      ChordAnticipationOrDelay anticipationOrDelay,
      bool implicitBeats) {
    _scaleChord = scaleChord;
    this.beats = beats;
    _beatsPerBar = beatsPerBar;
    this.slashScaleNote = slashScaleNote;
    _anticipationOrDelay = anticipationOrDelay;
    this.implicitBeats = implicitBeats;
  }

  Chord.copy(Chord chord) {
    _scaleChord = chord._scaleChord;
    beats = chord.beats;
    _beatsPerBar = chord._beatsPerBar;
    slashScaleNote = chord.slashScaleNote;
    _anticipationOrDelay = chord._anticipationOrDelay;
    implicitBeats = chord.implicitBeats;
  }

  Chord.byScaleChord(this._scaleChord) {
    beats = 4;
    _beatsPerBar = 4;
    slashScaleNote = null;
    _anticipationOrDelay =
        ChordAnticipationOrDelay.get(ChordAnticipationOrDelayEnum.none);
    implicitBeats = true;
  }

  Chord.byScaleChordAndBeats(this._scaleChord, this.beats, this._beatsPerBar) {
    slashScaleNote = null;
    _anticipationOrDelay =
        ChordAnticipationOrDelay.get(ChordAnticipationOrDelayEnum.none);
    implicitBeats = true;
  }

  static Chord parseString(String s, int beatsPerBar) {
    return parse(MarkedString(s), beatsPerBar);
  }

  static Chord parse(final MarkedString markedString, int beatsPerBar) {
    if (markedString == null || markedString.isEmpty) throw 'no data to parse';

    int beats = beatsPerBar; //  default only
    ScaleChord scaleChord = ScaleChord.parse(markedString);
    if (scaleChord == null) return null;

    ChordAnticipationOrDelay anticipationOrDelay =
        ChordAnticipationOrDelay.parse(markedString);

    ScaleNote slashScaleNote;
//  note: X chords can have a slash chord
    if (markedString.isNotEmpty && markedString.charAt(0) == '/') {
      markedString.consume(1);
      slashScaleNote = ScaleNote.parse(markedString);
    }
    if (markedString.isNotEmpty && markedString.charAt(0) == '.') {
      String s = markedString.toString();
      if (_beatSizeRegexp.hasMatch(s)) {
        beats = int.parse(s.substring(1, 2));
        markedString.consume(2);
      } else {
        beats = 1;
        while (markedString.isNotEmpty && markedString.charAt(0) == '.') {
          markedString.consume(1);
          beats++;
          if (beats >= 12) break;
        }
      }
    }

    if (beats > beatsPerBar) throw 'too many beats in the chord'; //  whoops

    Chord ret = Chord(scaleChord, beats, beatsPerBar, slashScaleNote,
        anticipationOrDelay, (beats == beatsPerBar)); //  fixme
    return ret;
  }

// Chord(ScaleChord scaleChord) {
//  this(scaleChord, 4, 4, null, ChordAnticipationOrDelay.none, true);
//}
//
// Chord(ScaleChord scaleChord, int beats, int beatsPerBar) {
//  this(scaleChord, beats, beatsPerBar, null, ChordAnticipationOrDelay.none, true);
//}

  Chord transpose(Key key, int halfSteps) {
    return Chord(
        _scaleChord.transpose(key, halfSteps),
        beats,
        _beatsPerBar,
        slashScaleNote == null
            ? null
            : slashScaleNote.transpose(key, halfSteps),
        _anticipationOrDelay,
        implicitBeats);
  }

  /// Compares this object with the specified object for order.  Returns a
  /// negative integer, zero, or a positive integer as this object is less
  /// than, equal to, or greater than the specified object.
  @override
  int compareTo(Chord o) {
    int ret = _scaleChord.compareTo(o._scaleChord);
    if (ret != 0) return ret;
    if (slashScaleNote == null && o.slashScaleNote != null) return -1;
    if (slashScaleNote != null && o.slashScaleNote == null) return 1;
    if (slashScaleNote != null && o.slashScaleNote != null) {
      ret = slashScaleNote.compareTo(o.slashScaleNote);
      if (ret != 0) return ret;
    }
    if (beats != o.beats) return beats < o.beats ? -1 : 1;
    ret = _anticipationOrDelay.compareTo(o._anticipationOrDelay);
    if (ret != 0) return ret;
    if (_beatsPerBar != o._beatsPerBar) {
      return _beatsPerBar < o._beatsPerBar ? -1 : 1;
    }
    return 0;
  }

  /// Returns a string representation of the object.
  @override
  String toString() {
    String ret = _scaleChord.toString() +
        (slashScaleNote == null ? '' : '/' + slashScaleNote.toString()) +
        _anticipationOrDelay.toString();
    if (!implicitBeats && beats < _beatsPerBar) {
      if (beats == 1) {
        ret += '.1';
      } else {
        int b = 1;
        while (b++ < beats && b < 12) {
          ret += '.';
        }
      }
    }
    return ret;
  }

  /// Returns a markup representation of the object.
  String toMarkup() {
    String ret = _scaleChord.toMarkup() +
        (slashScaleNote == null ? '' : '/' + slashScaleNote.toMarkup()) +
        _anticipationOrDelay.toString();
    if (!implicitBeats && beats < _beatsPerBar) {
      if (beats == 1) {
        ret += '.1';
      } else {
        int b = 1;
        while (b++ < beats && b < 12) {
          ret += '.';
        }
      }
    }
    return ret;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Chord &&
        _scaleChord == other._scaleChord &&
        beats == other.beats &&
        _beatsPerBar == other._beatsPerBar &&
        slashScaleNote == other.slashScaleNote &&
        _anticipationOrDelay == other._anticipationOrDelay;
  }


  @override
  int get hashCode {
    return hash4(beats, _beatsPerBar, slashScaleNote, _anticipationOrDelay);
  }

  ScaleChord get scaleChord => _scaleChord;
  ScaleChord _scaleChord;

  int beats;

  int get beatsPerBar => _beatsPerBar;
  int _beatsPerBar;

  bool implicitBeats = true;
  ScaleNote slashScaleNote;

  ChordAnticipationOrDelay get anticipationOrDelay => _anticipationOrDelay;
  ChordAnticipationOrDelay _anticipationOrDelay;

  static final RegExp _beatSizeRegexp = RegExp(r'^\.\d');
}
