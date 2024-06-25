

const List<TimeSignature> knownTimeSignatures = [
  TimeSignature.defaultTimeSignature,
  TimeSignature(2, 2),
  TimeSignature(2, 4),
  TimeSignature(3, 4),
  TimeSignature(6, 8),
];

/// beats per bar over units per measure ( 2, 4, 8 )
class TimeSignature {
  const TimeSignature(
    this.beatsPerBar,
    this.unitsPerMeasure,
  );

  static TimeSignature parse(String timeSignatureAsString) {
    RegExpMatch? m = _timeSignatureRegexp.firstMatch(timeSignatureAsString);
    if (m == null) {
      return TimeSignature.defaultTimeSignature;
    }
    return TimeSignature(int.parse(m.group(1) ?? '4'), int.parse(m.group(2) ?? '4'));
  }

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

  static const TimeSignature commonTimeSignature = TimeSignature(4, 4);
  static const TimeSignature defaultTimeSignature = commonTimeSignature;


  final int beatsPerBar; //  beats per bar, i.e. timeSignature numerator
  final int unitsPerMeasure; //  units per measure, i.e. timeSignature denominator
}

final RegExp _timeSignatureRegexp = RegExp(r'\s*(\d)\s*/\s*(\d)\s*$');
