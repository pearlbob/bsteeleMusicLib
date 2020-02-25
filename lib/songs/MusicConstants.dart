import 'ChordDescriptor.dart';

enum MajorDiatonic { i, ii, iii, IV, V, VI, vii }

enum MinorDiatonic { i, ii, III, iv, v, VI, VII }

class MusicConstants {
  static const String flatChar = '\u266D';
  static const String naturalChar = '\u266E';
  static const String sharpChar = '\u266F';
  static const String greekCapitalDelta = '\u0394';
  static const String diminishedCircle = '\u00BA';

  static const String flatHtml = "&#9837;";
  static const String naturalHtml = "&#9838;";
  static const String sharpHtml = "&#9839;";
  static const String greekCapitalDeltaHtml = "&#916;";
  static const String whiteBulletHtml = "&#25e6;";
  static const String diminishedCircleHtml = whiteBulletHtml;

  static const String bassClef = "\uD834\uDD22";
  static const String gClef = "\uD834\uDD1E";

  static const int halfStepsPerOctave = 12;
  static const int notesPerScale = 7;

  static const int measuresPerDisplayRow = 4;

  static const int minBpm = 50;
  static const int maxBpm = 400;

  //  has to be ahead of it's use since it's static
  static final List<ChordDescriptor> _majorDiatonicChordModifiers = [
    ChordDescriptor.major, //  0 + 1 = 1
    ChordDescriptor.minor, //  1 + 1 = 2
    ChordDescriptor.minor, //  2 + 1 = 3
    ChordDescriptor.major, //  3 + 1 = 4
    ChordDescriptor.dominant7, //  4 + 1 = 5
    ChordDescriptor.minor, //  5 + 1 = 6
    ChordDescriptor.minor7b5, //  6 + 1 = 7
  ];

  ///    Return the major diatonic chord descriptor for the given degree.
  static ChordDescriptor getMajorDiatonicChordModifier(int degree) {
    return _majorDiatonicChordModifiers[
        degree % _majorDiatonicChordModifiers.length];
  }

  //  has to be ahead of it's use since it's static
  static final List<ChordDescriptor> _minorDiatonicChordModifiers = [
    ChordDescriptor.minor, //  0 + 1 = 1
    ChordDescriptor.diminished, //  1 + 1 = 2
    ChordDescriptor.major, //  2 + 1 = 3
    ChordDescriptor.minor, //  3 + 1 = 4
    ChordDescriptor.minor, //  4 + 1 = 5
    ChordDescriptor.major, //  5 + 1 = 6
    ChordDescriptor.major, //  6 + 1 = 7
  ];

  ///  Return the major diatonic chord descriptor for the given degree.
  static ChordDescriptor getMinorDiatonicChordModifier(int degree) {
    return _minorDiatonicChordModifiers[
        degree % _minorDiatonicChordModifiers.length];
  }
}
