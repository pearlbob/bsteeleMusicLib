import 'dart:collection';

import 'package:quiver/core.dart';

enum DrumType { closedHighHat, openHighHat, snare, kick }

/// Descriptor of a single drum in the measure.

class Part {
  /// The drum type for the part described
  DrumType getDrumType() {
    return drumType;
  }

  /// The drum type for the part described
  void setDrumType(DrumType drumType) {
    this.drumType = drumType;
  }

  /// Get the divisions per beat, i.e. the drum part resolution
  int getDivisionsPerBeat() {
    return divisionsPerBeat;
  }

  /// Set the divisions per beat, i.e. the drum part resolution
  void setDivisionsPerBeat(int divisionsPerBeat) {
    this.divisionsPerBeat = divisionsPerBeat;
  }

  /// Get the description in the form of a string where drum hits
  /// are non-white space and silence are spaces.  Resolution of the drum
  /// description is determined by the divisions per beat.  When the length
  /// of the description is less than the divisions per beat times the beats per measure,
  /// the balance of the measure will be silent.
  String getDescription() {
    return description;
  }

  ///Set the drum part description
  void setDescription(String description) {
    this.description = description;
  }

  DrumType drumType;
  int divisionsPerBeat;
  String description;
}

/// Descriptor of the drums to be played for the given measure and
/// likely subsequent measures.

@deprecated
class LegacyDrumMeasure implements Comparable<LegacyDrumMeasure> {
  /// Get all parts as a map.
  Map<DrumType, Part> getParts() {
    return parts;
  }

  ///Get an individual drum's part.
  Part getPart(DrumType drumType) {
    return parts[drumType];
  }

  /// Set an individual drum's part.
  void setPart(DrumType drumType, Part part) {
    parts[drumType] = part;
  }

  HashMap<DrumType, Part> parts;

  //  legacy stuff
  //
  String getHighHat() {
    return highHat;
  }

  void setHighHat(String highHat) {
    this.highHat = (highHat == null ? "" : highHat);
    _isSilent = null;
  }

  String getSnare() {
    return snare;
  }

  void setSnare(String snare) {
    this.snare = (snare == null ? "" : snare);
    _isSilent = null;
  }

  String getKick() {
    return kick;
  }

  void setKick(String kick) {
    this.kick = (kick == null ? "" : kick);
    _isSilent = null;
  }

  bool isSilent() {
    if (_isSilent == null)
      _isSilent = !(regExpHasX.hasMatch(highHat) ||
          regExpHasX.hasMatch(snare) ||
          regExpHasX.hasMatch(kick));
    return _isSilent;
  }

  @override
  String toString() {
    return "{" + highHat + ", " + snare + ", " + kick + '}';
  }

  @override
  int compareTo(LegacyDrumMeasure o) {
    int ret = (_isSilent == o._isSilent ? 0 : (_isSilent ? -1 : 1));
    if (ret != 0) return ret;
    ret = highHat.compareTo(o.highHat);
    if (ret != 0) return ret;
    ret = snare.compareTo(o.snare);
    if (ret != 0) return ret;
    ret = kick.compareTo(o.kick);
    if (ret != 0) return ret;
    return 0;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    return other is LegacyDrumMeasure &&
        highHat == other.highHat &&
        snare == other.snare &&
        kick == other.kick &&
        _isSilent == other._isSilent;
  }

  @override
  int get hashCode {
    int ret = hash4(highHat, snare, kick, _isSilent);
    return ret;
  }

  String highHat = "";
  String snare = "";
  String kick = "";
  bool _isSilent;
  static final RegExp regExpHasX = RegExp(".*[xX].*");
}
