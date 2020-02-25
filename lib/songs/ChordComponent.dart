import 'MusicConstants.dart';

///
// Components of a chord expressed in a structured single note form.
//
class ChordComponent implements Comparable<ChordComponent> {
  static final ChordComponent root = ChordComponent._("R", 1, 0);
  static final ChordComponent minorSecond = ChordComponent._("m2", 2, 1);
  static final second = ChordComponent._("2", 2, 2);
  static final minorThird = ChordComponent._("m3", 3, 3);
  static final third = ChordComponent._("3", 3, 4);
  static final fourth = ChordComponent._("4", 4, 5);
  static final flatFifth = ChordComponent._("b5", 5, 6);
  static final fifth = ChordComponent._("5", 5, 7);
  static final sharpFifth = ChordComponent._("#5", 5, 8);
  static final sixth = ChordComponent._("6", 6, 9);
  static final minorSeventh = ChordComponent._("m7", 7, 10);
  static final seventh = ChordComponent._("7", 7, 11);
  static final ninth = ChordComponent._("9", 9, 12 + 4);
  static final eleventh = ChordComponent._("11", 11, 12 + 7);
  static final thirteenth = ChordComponent._("13", 13, 12 + 11);

  ChordComponent._(this._shortName, this._scaleNumber, this._halfSteps);

  static Set<ChordComponent> parse(String chordComponentString) {
    Set<ChordComponent> ret = Set();
    for (String s in chordComponentString.split(new RegExp(r"[,. ]"))) {
      if (s.length <= 0) continue;

      ChordComponent cc;
      for (ChordComponent t in _chordComponentByHalfSteps)
        if (t.shortName == s) {
          cc = t;
          break;
        }

      //  specials
      if (cc == null)
        switch (s) {
          case "r":
          case "1":
            cc = root;
            break;
          case "m5":
            cc = flatFifth;
            break;
          case "9":
            cc = ninth;
            break;
          case "11":
            cc = eleventh;
            break;
          case "13":
            cc = thirteenth;
            break;
          default:
            throw new ArgumentError("unknown component: <" + s + ">");
        }
      ret.add(cc);
    }
    return ret;
  }

  static ChordComponent getByHalfStep(int halfStep) {
    return _chordComponentByHalfSteps[ halfStep% MusicConstants.halfStepsPerOctave];
  }

  @override
  int compareTo(ChordComponent other) {
    return _halfSteps - other._halfSteps;
  }

  @override
  bool operator ==(other) {
    return identical(this, other);
  }

  @override
  int get hashCode {
    return _halfSteps.hashCode;
  }

  @override
  String toString() {
    return _shortName;
  }

  String get shortName => _shortName;
  final String _shortName;

  int get scaleNumber => _scaleNumber;
  final int _scaleNumber;

  int get halfSteps => _halfSteps;
  final int _halfSteps;

  static final _chordComponentByHalfSteps = <ChordComponent>[
    root,
    minorSecond,
    second,
    minorThird,
    third,
    fourth,
    flatFifth,
    fifth,
    sharpFifth,
    sixth,
    minorSeventh,
    seventh
  ];
}
