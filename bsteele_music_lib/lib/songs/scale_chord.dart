import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import '../util/util.dart';
import 'chord_component.dart';
import 'chord_descriptor.dart';
import 'key.dart';
import 'scale_note.dart';

part 'scale_chord.g.dart';

///  A chord with a scale note and an optional chord descriptor and tension.
@immutable
@JsonSerializable()
class ScaleChord implements Comparable<ScaleChord> {
  ScaleChord(this.scaleNote, ChordDescriptor chordDescriptor) : _chordDescriptor = chordDescriptor.deAlias();

  ScaleChord.fromScaleNoteEnum(ScaleNote scaleNoteEnum)
      : scaleNote = scaleNoteEnum,
        _chordDescriptor = ChordDescriptor.defaultChordDescriptor().deAlias();

  ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote scaleNoteEnum, ChordDescriptor chordDescriptor)
      : scaleNote = scaleNoteEnum,
        _chordDescriptor = chordDescriptor.deAlias();

  ScaleChord.fromScaleNote(this.scaleNote) : _chordDescriptor = ChordDescriptor.defaultChordDescriptor().deAlias();

  static ScaleChord? parseString(String s) {
    return parse(MarkedString(s));
  }

  static ScaleChord? parse(MarkedString markedString) {
    if (markedString.isEmpty) {
      throw ArgumentError('no data to parse');
    }

    ScaleNote? retScaleNote = ScaleNote.parse(markedString);
    if (retScaleNote == null) {
      return null;
    }

    if (retScaleNote == ScaleNote.X) {
      return ScaleChord(retScaleNote, ChordDescriptor.major); //  by convention only
    }

    ChordDescriptor retChordDescriptor = ChordDescriptor.parse(markedString);
    return ScaleChord(retScaleNote, retChordDescriptor);
  }

  ScaleChord transpose(Key key, int halfSteps) {
    return ScaleChord(scaleNote.transpose(key, halfSteps), chordDescriptor);
  }

//public final ScaleNote getScaleN//public final ScaleChord transpose(Key key, int halfSteps) {
//return new ScaleChord(scaleNote.transpose(key, halfSteps), chordDescriptor);
//}

  List<ScaleNote> chordNotes(Key key) {
    var ret = <ScaleNote>[];
    for (var component in _chordDescriptor.chordComponents) {
      ret.add(scaleNote.transpose(key, component.halfSteps));
    }
    return ret;
  }

  ScaleChord getAlias() {
    ScaleNote alias = scaleNote.alias;
    return ScaleChord(alias, _chordDescriptor);
  }

  Set<ChordComponent> getChordComponents() {
    return chordDescriptor.chordComponents;
  }

  bool contains(ChordComponent chordComponent) {
    return chordDescriptor.chordComponents.contains(chordComponent);
  }

  bool isEasyGuitarChord() {
    return _getEasyGuitarChords().contains(this);
  }

  @override
  String toString() {
    return scaleNote.toString() + chordDescriptor.shortName;
  }

  String toMarkup() {
    return scaleNote.toMarkup() + chordDescriptor.shortName;
  }

  @override
  int compareTo(ScaleChord o) {
    int ret = scaleNote.compareTo(o.scaleNote);
    if (ret != 0) {
      return ret;
    }
    ret = chordDescriptor.compareTo(o.chordDescriptor);
    if (ret != 0) {
      return ret;
    }
    return 0;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    return runtimeType == other.runtimeType &&
        other is ScaleChord &&
        scaleNote == other.scaleNote &&
        _chordDescriptor == other._chordDescriptor;
  }

  @override
  int get hashCode {
    int ret = Object.hash(scaleNote, _chordDescriptor);
    return ret;
  }

  static final Set<ScaleChord> _easyGuitarChords = <ScaleChord>{};

  static Set<ScaleChord> _getEasyGuitarChords() {
    if (_easyGuitarChords.isEmpty) {
      _easyGuitarChords.add(ScaleChord.parseString('C')!);
      _easyGuitarChords.add(ScaleChord.parseString('A')!);
      _easyGuitarChords.add(ScaleChord.parseString('G')!);
      _easyGuitarChords.add(ScaleChord.parseString('E')!);
      _easyGuitarChords.add(ScaleChord.parseString('D')!);
      _easyGuitarChords.add(ScaleChord.parseString('Am')!);
      _easyGuitarChords.add(ScaleChord.parseString('Em')!);
      _easyGuitarChords.add(ScaleChord.parseString('Dm')!);
    }
    return _easyGuitarChords;
  }

  factory ScaleChord.fromJson(Map<String, dynamic> json) => _$ScaleChordFromJson(json);

  Map<String, dynamic> toJson() => _$ScaleChordToJson(this);

//
//
  final ScaleNote scaleNote;

  ChordDescriptor get chordDescriptor => _chordDescriptor;
  final ChordDescriptor _chordDescriptor;
}
