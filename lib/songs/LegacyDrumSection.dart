import 'package:quiver/collection.dart';
import 'package:quiver/core.dart';

import 'LegacyDrumMeasure.dart';

/// Definition of drum section for one or more measures
/// to be used either as the song's default drums or
/// the special drums for a given section.

@deprecated
class LegacyDrumSection implements Comparable<LegacyDrumSection>{
  /// Get the section's drum measures
  List<LegacyDrumMeasure> getDrumMeasures() {
    return drumMeasures;
  }

  ///Set the section's drum measures in bulk
  void setDrumMeasures(List<LegacyDrumMeasure> drumMeasures) {
    this.drumMeasures = drumMeasures;
  }


  @override
  int compareTo(LegacyDrumSection o) {
    if (!listsEqual(drumMeasures, o.drumMeasures)) {
      //  compare the lists
      if (drumMeasures == null) return o.drumMeasures == null ? 0 : 1;
      if (o.drumMeasures == null) return -1;
      if (drumMeasures.length != o.drumMeasures.length)
        return drumMeasures.length < o.drumMeasures.length ? -1 : 1;
      for ( int i =0; i < drumMeasures.length; i++){
        int ret = drumMeasures[i].compareTo(o.drumMeasures[i]);
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
    return other is LegacyDrumSection &&
        listsEqual(drumMeasures, other.drumMeasures);
  }

  @override
  int get hashCode {
    if ( drumMeasures== null )
      return 0;
    return hashObjects(drumMeasures);
  }

  List<LegacyDrumMeasure> drumMeasures;

}
