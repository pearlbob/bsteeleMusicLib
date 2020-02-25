import '../util/util.dart';
import 'ChordComponent.dart';
import 'MusicConstants.dart';

///
// The modifier to a chord specification that describes the basic type of chord.
// Typical values are major, minor, dominant7, etc.
// <p>
// Try:  https://www.scales-chords.com/chord/
//
class ChordDescriptor implements Comparable<ChordDescriptor> {
  //  longest short names must come first!
  //  avoid starting descriptors with b, #, s to avoid confusion with scale notes
  /// Dominant 7th chord with the 3rd replaced by the 4th. Suspended chords are neither major or minor.

  static ChordDescriptor get sevenSus4 => _sevenSus4;
  static final ChordDescriptor _sevenSus4 =
      ChordDescriptor._("sevenSus4", "7sus4", "R 4 5 m7");

  static ChordDescriptor get sevenSus2 => _sevenSus2;
  static final ChordDescriptor _sevenSus2 =
      ChordDescriptor._("sevenSus2", "7sus2", "R 2 5 m7");

  static ChordDescriptor get sevenSus => _sevenSus;
  static final ChordDescriptor _sevenSus =
      ChordDescriptor._("sevenSus", "7sus", "R 5 m7");

  static ChordDescriptor get maug => _maug;
  static final ChordDescriptor _maug =
      ChordDescriptor._("maug", "maug", "R m3 3 #5");

  static ChordDescriptor get dominant13 => _dominant13;
  static final ChordDescriptor _dominant13 =
      ChordDescriptor._("dominant13", "13", "R 3 5 m7 9 11 13");

  static ChordDescriptor get dominant11 => _dominant11;
  static final ChordDescriptor _dominant11 =
      ChordDescriptor._("dominant11", "11", "R 3 5 m7 9 11");

  static ChordDescriptor get mmaj7 => _mmaj7;
  static final ChordDescriptor _mmaj7 =
      ChordDescriptor._("mmaj7", "mmaj7", "R m3 5 7");

  static ChordDescriptor get minor7b5 => _minor7b5;
  static final ChordDescriptor _minor7b5 =
      ChordDescriptor._("minor7b5", "m7b5", "R m3 b5 m7");

  static ChordDescriptor get msus2 => _msus2;
  static final ChordDescriptor _msus2 =
      ChordDescriptor._("msus2", "msus2", "R 2 m3 5");

  static ChordDescriptor get msus4 => _msus4;
  static final ChordDescriptor _msus4 =
      ChordDescriptor._("msus4", "msus4", "R m3 4 5");

  static ChordDescriptor get add9 => _add9;
  static final ChordDescriptor _add9 =
      ChordDescriptor._("add9", "add9", "R 2 3 5 7");

  static ChordDescriptor get jazz7b9 => _jazz7b9;
  static final ChordDescriptor _jazz7b9 =
      ChordDescriptor._("jazz7b9", "jazz7b9", "R m2 3 5");

  static ChordDescriptor get sevenSharp5 => _sevenSharp5;
  static final ChordDescriptor _sevenSharp5 =
      ChordDescriptor._("sevenSharp5", "7#5", "R 3 #5 m7");

  static ChordDescriptor get flat5 => _flat5;
  static final ChordDescriptor _flat5 =
      ChordDescriptor._("flat5", "flat5", "R 3 b5");

  static ChordDescriptor get sevenFlat5 => _sevenFlat5;
  static final ChordDescriptor _sevenFlat5 =
      ChordDescriptor._("sevenFlat5", "7b5", "R 3 b5 m7");

  static ChordDescriptor get sevenSharp9 => _sevenSharp9;
  static final ChordDescriptor _sevenSharp9 =
      ChordDescriptor._("sevenSharp9", "7#9", "R m3 5 m7");

  static ChordDescriptor get sevenFlat9 => _sevenFlat9;
  static final ChordDescriptor _sevenFlat9 =
      ChordDescriptor._("sevenFlat9", "7b9", "R m2 3 5 7");

  static ChordDescriptor get dominant9 => _dominant9;
  static final ChordDescriptor _dominant9 =
      ChordDescriptor._("dominant9", "9", "R 3 5 m7 9");

  static ChordDescriptor get six9 => _six9;
  static final ChordDescriptor _six9 =
      ChordDescriptor._("six9", "69", "R 2 3 5 6");

  static ChordDescriptor get major6 => _major6;
  static final ChordDescriptor _major6 =
      ChordDescriptor._("major6", "6", "R 3 5 6");

  static ChordDescriptor get diminished7 => _diminished7;
  static final ChordDescriptor _diminished7 =
      ChordDescriptor._("diminished7", "dim7", "R m3 b5 6");

  static ChordDescriptor get dimMasculineOrdinalIndicator7 =>
      _dimMasculineOrdinalIndicator7;
  static final ChordDescriptor _dimMasculineOrdinalIndicator7 =
      ChordDescriptor._("dimMasculineOrdinalIndicator7", "º7", "R m3 b5 6",
          alias: diminished7);

  static ChordDescriptor get diminished => _diminished;
  static final ChordDescriptor _diminished =
      ChordDescriptor._("diminished", "dim", "R m3 b5");

  static ChordDescriptor get diminishedAsCircle => _diminishedAsCircle;
  static final ChordDescriptor _diminishedAsCircle = ChordDescriptor._(
      "diminishedAsCircle", "" + MusicConstants.diminishedCircle, "R m3 b5",
      alias: diminished);

  static ChordDescriptor get augmented5 => _augmented5;
  static final ChordDescriptor _augmented5 =
      ChordDescriptor._("augmented5", "aug5", "R 3 #5");

  static ChordDescriptor get augmented7 => _augmented7;
  static final ChordDescriptor _augmented7 =
      ChordDescriptor._("augmented7", "aug7", "R 3 #5 m7");

  static ChordDescriptor get augmented => _augmented;
  static final ChordDescriptor _augmented =
      ChordDescriptor._("augmented", "aug", "R 3 #5");

  static ChordDescriptor get suspended7 => _suspended7;
  static final ChordDescriptor _suspended7 =
      ChordDescriptor._("suspended7", "sus7", "R 5 m7");

  static ChordDescriptor get suspended4 => _suspended4;
  static final ChordDescriptor _suspended4 =
      ChordDescriptor._("suspended4", "sus4", "R 4 5");

  static ChordDescriptor get suspended2 => _suspended2;
  static final ChordDescriptor _suspended2 =
      ChordDescriptor._("suspended2", "sus2", "R 2 5");

  static ChordDescriptor get suspended => _suspended;
  static final ChordDescriptor _suspended =
      ChordDescriptor._("suspended", "sus", "R 5");

  static ChordDescriptor get minor9 => _minor9;
  static final ChordDescriptor _minor9 =
      ChordDescriptor._("minor9", "m9", "R m3 5 m7 9");

  static ChordDescriptor get minor11 => _minor11;
  static final ChordDescriptor _minor11 =
      ChordDescriptor._("minor11", "m11", "R m3 5 m7 11");

  static ChordDescriptor get minor13 => _minor13;
  static final ChordDescriptor _minor13 =
      ChordDescriptor._("minor13", "m13", "R m3 5 m7 13");

  static ChordDescriptor get minor6 => _minor6;
  static final ChordDescriptor _minor6 =
      ChordDescriptor._("minor6", "m6", "R m3 5 6");

  static ChordDescriptor get major7 => _major7;
  static final ChordDescriptor _major7 =
      ChordDescriptor._("major7", "maj7", "R 3 5 7");

  static ChordDescriptor get deltaMajor7 => _deltaMajor7;
  static final ChordDescriptor _deltaMajor7 = ChordDescriptor._(
      "deltaMajor7", "" + MusicConstants.greekCapitalDelta, "R 3 5 7",
      alias: major7);

  static ChordDescriptor get capMajor7 => _capMajor7;
  static final ChordDescriptor _capMajor7 =
      ChordDescriptor._("capMajor7", "Maj7", "R 3 5 7", alias: major7);

  static ChordDescriptor get major9 => _major9;
  static final ChordDescriptor _major9 =
      ChordDescriptor._("major9", "maj9", "R 3 5 7 9");

  static ChordDescriptor get maj => _maj;
  static final ChordDescriptor _maj = ChordDescriptor._("maj", "maj", "R 3 5");

  static ChordDescriptor get majorNine => _majorNine;
  static final ChordDescriptor _majorNine =
      ChordDescriptor._("majorNine", "M9", "R 3 5 7 9");

  static ChordDescriptor get majorSeven => _majorSeven;
  static final ChordDescriptor _majorSeven =
      ChordDescriptor._("majorSeven", "M7", "R 3 5 7");

  static ChordDescriptor get suspendedSecond => _suspendedSecond;
  static final ChordDescriptor _suspendedSecond = ChordDescriptor._(
      "suspendedSecond", "2", "R 2 5"); //  alias for  suspended2

  static ChordDescriptor get suspendedFourth => _suspendedFourth;
  static final ChordDescriptor _suspendedFourth = ChordDescriptor._(
      "suspendedFourth", "4", "R 4 5"); //  alias for suspended 4

  static ChordDescriptor get power5 => _power5;
  static final ChordDescriptor _power5 = ChordDescriptor._(
      "power5", "5", "R 5"); //  3rd omitted typically to avoid distortions

  static ChordDescriptor get minor7 => _minor7;
  static final ChordDescriptor _minor7 =
      ChordDescriptor._("minor7", "m7", "R m3 5 m7");

  static ChordDescriptor get dominant7 => _dominant7;
  static final ChordDescriptor _dominant7 =
      ChordDescriptor._("dominant7", "7", "R 3 5 m7");

  static ChordDescriptor get minor => _minor;
  static final ChordDescriptor _minor =
      ChordDescriptor._("minor", "m", "R m3 5");

  static ChordDescriptor get capMajor => _capMajor;
  static final ChordDescriptor _capMajor =
      ChordDescriptor._("capMajor", "M", "R 3 5");

  static ChordDescriptor get dimMasculineOrdinalIndicator =>
      _dimMasculineOrdinalIndicator;
  static final ChordDescriptor _dimMasculineOrdinalIndicator =
      ChordDescriptor._("dimMasculineOrdinalIndicator", "º", "R m3 b5",
          alias: diminished);

  ///  Default chord descriptor.
  static ChordDescriptor get major => _major;
  static final ChordDescriptor _major = ChordDescriptor._("major", "", "R 3 5");

  static ChordDescriptor defaultChordDescriptor() {
    return _major;
  }

  ChordDescriptor._(this._name, this._shortName, String structure,
      {ChordDescriptor alias}) {
    this._alias = alias;
    _chordComponents = ChordComponent.parse(structure);
  }

  static ChordDescriptor parseString(String s) {
    return parse(new MarkedString(s));
  }

  ///
//    Parse the start of the given string for a chord description.
  static ChordDescriptor parse(MarkedString markedString) {
    if (markedString != null && markedString.isNotEmpty) {
      //  arbitrary cutoff, larger than the max shortname
      const int maxLength = 10;
      String match = markedString.remainingStringLimited(maxLength);
      for (ChordDescriptor cd in _parseOrderedChordDescriptorsOrdered) {
        if (cd._shortName.length > 0 && match.startsWith(cd._shortName)) {
          markedString.consume(cd._shortName.length);
          return cd.deAlias();
        }
      }
    }
    return ChordDescriptor._major; //  chord without modifier short name
  }

  ///
  // Returns the human name of this enum.
  @override
  String toString() {
    if (shortName.length == 0) return name;
    return shortName;
  }

  String chordComponentsToString() {
    StringBuffer sb = new StringBuffer();

    bool first = true;
    for (ChordComponent cc in _chordComponents) {
      if (first)
        first = false;
      else
        sb.write(" ");
      sb.write(cc.shortName);
    }
    return sb.toString();
  }

//public final TreeSet<ChordComponent> getChordComponents() {
//return chordComponents;
//}

  ChordDescriptor deAlias() {
    if (_alias != null) return _alias;
    return this;
  }

  @override
  int get hashCode {
    return _name.hashCode;
  }

  @override
  bool operator ==(other) {
    return _name == other._name;
  }

  int compareTo(ChordDescriptor other) {
    if (other == null) return -1;
    return _name.compareTo(other._name);
  }

  //public static final ChordDescriptor[] getOtherChordDescriptorsOrdered() {
//  return otherChordDescriptorsOrdered;
//}
//
//public static final ChordDescriptor[] getPrimaryChordDescriptorsOrdered() {
//  return primaryChordDescriptorsOrdered;
//}
//
//
//public static final ChordDescriptor[] getAllChordDescriptorsOrdered() {
//  return allChordDescriptorsOrdered;
//}

  /// The name for the chord descriptor used internally in the software.
  /// This name will likely be understood by musicians but will not necessarily
  /// be used by them in written form.
  String get name => _name;
  String _name;

  /// The short name for the chord that typically gets used in human documentation such
  /// as in the song lyrics or sheet music.  The name will never be null but can be empty.
  String get shortName => _shortName;
  String _shortName;

  /// the list of components from the scale that make up the given chord.
  Set<ChordComponent> get chordComponents => _chordComponents;
  Set<ChordComponent> _chordComponents;

  /// an optional alias often used by musicians.
  /// can be null.
  ChordDescriptor get alias => _alias;
  ChordDescriptor _alias;

  static List<ChordDescriptor> get primaryChordDescriptorsOrdered =>
      _primaryChordDescriptorsOrdered;
  static final List<ChordDescriptor> _primaryChordDescriptorsOrdered = [
    //  most common
    _major,
    _minor,
    _dominant7,
  ];

  static List<ChordDescriptor> get otherChordDescriptorsOrdered =>
      _otherChordDescriptorsOrdered;
  static final List<ChordDescriptor> _otherChordDescriptorsOrdered = [
    //  less pop by shortname
    _add9,
    _augmented,
    _augmented5,
    _augmented7,
    _diminished,
    _diminished7,
    _jazz7b9,
    _major7,
    _majorSeven,
    _major9,
    _majorNine,
    _minor9,
    _minor11,
    _minor13,
    _minor6,
    _minor7,
    _mmaj7,
    _minor7b5,
    _msus2,
    _msus4,
    _flat5,
    _sevenFlat5,
    _sevenFlat9,
    _sevenSharp5,
    _sevenSharp9,
    _suspended,
    _suspended2,
    _suspended4,
    _suspendedFourth,
    _suspended7,
    _sevenSus,
    _sevenSus2,
    _sevenSus4,

//  numerically named chords
    _power5,
    _major6,
    _six9,
    _dominant9,
    _dominant11,
    _dominant13,
  ];
  static List<ChordDescriptor> _allChordDescriptorsOrdered;

  static final List<ChordDescriptor> _parseOrderedChordDescriptorsOrdered = [
    _sevenSus4,
    _sevenSus2,
    _sevenSus,
    _maug,
    _dominant13,
    _dominant11,
    _mmaj7,
    _minor7b5,
    _msus2,
    _msus4,
    _add9,
    _jazz7b9,
    _sevenSharp5,
    _flat5,
    _sevenFlat5,
    _sevenSharp9,
    _sevenFlat9,
    _dominant9,
    _six9,
    _major6,
    _diminished7,
    _dimMasculineOrdinalIndicator7,
    _diminished,
    _diminishedAsCircle,
    _augmented5,
    _augmented7,
    _augmented,
    _suspended7,
    _suspended4,
    _suspended2,
    _suspended,
    _minor9,
    _minor11,
    _minor13,
    _minor6,
    _major7,
    _deltaMajor7,
    _capMajor7,
    _major9,
    _maj,
    _majorNine,
    _majorSeven,
    _suspendedSecond,
    _suspendedFourth,
    _power5,
    _minor7,
    _dominant7,
    _minor,
    _capMajor,
    _dimMasculineOrdinalIndicator,
    _major,
  ];

  static List<ChordDescriptor> get values {
    if (_allChordDescriptorsOrdered == null) {
      // lazy eval
      //  compute the ordered list of all chord descriptors
      List<ChordDescriptor> list = List();
      for (ChordDescriptor cd in _primaryChordDescriptorsOrdered) {
        list.add(cd);
      }
      for (ChordDescriptor cd in _otherChordDescriptorsOrdered) {
        list.add(cd);
      }
      _allChordDescriptorsOrdered = list;
    }
    return _allChordDescriptorsOrdered;
  }

//  static String generateGrammar() {
//    StringBuffer sb = StringBuffer();
//    sb.write("\t//\tChordDescriptor\n");
//    sb.write("\t(");
//    bool first = true;
//    for (ChordDescriptor chordDescriptor in ChordDescriptor.values) {
//      sb.write("\n\t\t");
//      String s = chordDescriptor.shortName;
//      if (s.length > 0) {
//        if (first)
//          first = false;
//        else
//          sb.write("| ");
//        sb.write("\"");
//        sb.write(s);
//        sb.write("\"");
//      }
//      sb.write("\t//\t");
//      sb.write(chordDescriptor.name);
//    }
//    sb.write("\n\t)");
//    return sb.toString();
//  }
}
