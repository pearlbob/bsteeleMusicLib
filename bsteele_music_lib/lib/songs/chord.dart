import 'dart:collection';

import 'pitch.dart';
import 'scale_chord.dart';
import 'scale_note.dart';
import '../util/util.dart';

import 'chord_anticipation_or_delay.dart';
import 'key.dart';

///
class Chord implements Comparable<Chord> {
  Chord(ScaleChord scaleChord, this.beats, int beatsPerBar, this.slashScaleNote,
      ChordAnticipationOrDelay anticipationOrDelay, this.implicitBeats)
      : _anticipationOrDelay = anticipationOrDelay {
    _scaleChord = scaleChord;
    _beatsPerBar = beatsPerBar;
  }

  Chord.copy(Chord chord) : _anticipationOrDelay = chord._anticipationOrDelay {
    _scaleChord = chord._scaleChord;
    beats = chord.beats;
    _beatsPerBar = chord._beatsPerBar;
    slashScaleNote = chord.slashScaleNote;
    implicitBeats = chord.implicitBeats;
  }

  static Chord? parseString(String s, int beatsPerBar) {
    return parse(MarkedString(s), beatsPerBar);
  }

  static Chord? parse(final MarkedString markedString, int beatsPerBar) {
    if (markedString.isEmpty) {
      throw 'no data to parse';
    }

    ScaleChord? scaleChord = ScaleChord.parse(markedString);
    if (scaleChord == null) {
      return null;
    }

    ChordAnticipationOrDelay? anticipationOrDelay = ChordAnticipationOrDelay.parse(markedString);
    if (anticipationOrDelay == null) {
      throw 'anticipationOrDelay not understood: ${markedString.remainingStringLimited(5)}';
    }

    ScaleNote? slashScaleNote;
    //  note: X chords can have a slash chord
    if (markedString.isNotEmpty && markedString.charAt(0) == '/') {
      markedString.consume(1);
      slashScaleNote = ScaleNote.parse(markedString);
    }
    int beats = 1;
    bool implicitBeats = true;
    if (markedString.isNotEmpty && markedString.charAt(0) == '.') {
      implicitBeats = false;
      while (markedString.isNotEmpty && markedString.charAt(0) == '.') {
        markedString.consume(1);
        beats++;
        if (beats >= 12) {
          break;
        }
      }
    }

    if (beats > beatsPerBar) {
      assert(false);
      throw 'too many beats in the chord';
    } //  whoops

    Chord ret = Chord(scaleChord, beats, beatsPerBar, slashScaleNote, anticipationOrDelay, implicitBeats); //  fixme
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
    return Chord(_scaleChord.transpose(key, halfSteps), beats, _beatsPerBar, slashScaleNote?.transpose(key, halfSteps),
        _anticipationOrDelay, implicitBeats);
  }

  /// Compares this object with the specified object for order.  Returns a
  /// negative integer, zero, or a positive integer as this object is less
  /// than, equal to, or greater than the specified object.
  @override
  int compareTo(Chord o) {
    int ret = _scaleChord.compareTo(o._scaleChord);
    if (ret != 0) {
      return ret;
    }
    if (slashScaleNote == null && o.slashScaleNote != null) {
      return -1;
    }
    if (slashScaleNote != null && o.slashScaleNote == null) {
      return 1;
    }
    if (slashScaleNote != null && o.slashScaleNote != null) {
      ret = slashScaleNote!.compareTo(o.slashScaleNote!);
      if (ret != 0) {
        return ret;
      }
    }
    if (beats != o.beats) {
      return beats < o.beats ? -1 : 1;
    }

    ret = _anticipationOrDelay.compareTo(o._anticipationOrDelay);
    if (ret != 0) {
      return ret;
    }

    if (_beatsPerBar != o._beatsPerBar) {
      return _beatsPerBar < o._beatsPerBar ? -1 : 1;
    }
    return 0;
  }

  /// Returns a string representation of the object.
  @override
  String toString() {
    String ret = _scaleChord.toString() +
        (slashScaleNote == null ? '' : '/$slashScaleNote') +
        _anticipationOrDelay.toString() +
        beatsToString();
    return ret;
  }

  String beatsToString() {
    String ret = '';
    //  note: at the chord level, a single beat chord should not have additional beats
    //  the single beat designation will be done at the measure level
    if (!implicitBeats && beats < _beatsPerBar) {
      if (beats > 1) {
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
        (slashScaleNote == null ? '' : '/${slashScaleNote!.toMarkup()}') +
        _anticipationOrDelay.toString();
    if (!implicitBeats && beats < _beatsPerBar) {
      int b = 1;
      while (b++ < beats && b < 12) {
        ret += '.';
      }
    }
    return ret;
  }

  List<Pitch> getPitches(Pitch atOrAbove) {
    List<Pitch> ret = [];
    Pitch root = Pitch.findPitch(_scaleChord.scaleNote, atOrAbove);
    for (var chordComponent in _scaleChord.getChordComponents()) {
      var p = root.offsetByHalfSteps(chordComponent.halfSteps);
      if (p != null) {
        ret.add(p);
      }
    }
    return ret;
  }

  List<Pitch> pianoChordPitches() {
    Pitch root = Pitch.findPitch(scaleChord.scaleNote, minimumPianoRootPitch);
    SplayTreeSet<Pitch> pitches = SplayTreeSet();
    pitches.addAll(getPitches(root));
    return pitches.toList(growable: false);
  }

  Pitch? pianoSlashPitch() {
    if (slashScaleNote == null) {
      return null;
    }
    return Pitch.findPitch(slashScaleNote!, minimumPianoSlashPitch);
  }

  Pitch? bassSlashPitch() {
    if (slashScaleNote == null) {
      return null;
    }
    return Pitch.findPitch(slashScaleNote!, minimumBassSlashPitch);
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    return runtimeType == other.runtimeType &&
        other is Chord &&
        _scaleChord == other._scaleChord &&
        beats == other.beats &&
        _beatsPerBar == other._beatsPerBar &&
        slashScaleNote == other.slashScaleNote &&
        _anticipationOrDelay == other._anticipationOrDelay;
  }

  @override
  int get hashCode {
    return Object.hash(beats, _beatsPerBar, slashScaleNote, _anticipationOrDelay);
  }

  ScaleChord get scaleChord => _scaleChord;
  late ScaleChord _scaleChord;

  late int beats;

  int get beatsPerBar => _beatsPerBar;
  late int _beatsPerBar;

  bool implicitBeats = true; //  chord has fewer beats than the beats per bar
  ScaleNote? slashScaleNote;

  ChordAnticipationOrDelay get anticipationOrDelay => _anticipationOrDelay;
  late final ChordAnticipationOrDelay _anticipationOrDelay;

  static final minimumPianoRootPitch = Pitch.get(PitchEnum.A3); //  the A below middle C, i.e. C4.
  static final minimumPianoSlashPitch = Pitch.get(PitchEnum.E2); // bottom of piano bass clef
  static final minimumBassSlashPitch = Pitch.get(PitchEnum.E1); //  the low E of a bass guitar
}
