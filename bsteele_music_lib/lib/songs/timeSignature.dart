
List<TimeSignature> knownTimeSignatures = [
  TimeSignature.defaultTimeSignature,
  TimeSignature(2, 2),
  TimeSignature(2, 4),
  TimeSignature(3, 4),
  TimeSignature(6, 8),
];

/// beats per bar over units per measure ( 2, 4, 8 )
class TimeSignature {
  TimeSignature(
    this.beatsPerBar,
    this.unitsPerMeasure,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSignature &&
          runtimeType == other.runtimeType &&
          beatsPerBar == other.beatsPerBar &&
          unitsPerMeasure == other.unitsPerMeasure;

  @override
  int get hashCode => beatsPerBar.hashCode ^ unitsPerMeasure.hashCode;

  @override
  String toString() {
    return '$beatsPerBar/$unitsPerMeasure';
  }

  static TimeSignature defaultTimeSignature = TimeSignature(4, 4);

  final int beatsPerBar; //  beats per bar, i.e. timeSignature numerator
  final int unitsPerMeasure; //  units per measure, i.e. timeSignature denominator
}
