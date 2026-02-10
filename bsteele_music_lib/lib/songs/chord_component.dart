import 'package:meta/meta.dart';

import 'music_constants.dart';

///
// Components of a chord expressed in a structured single note form.
//
@immutable
class ChordComponent implements Comparable<ChordComponent> {
  static const root = ChordComponent._('R', 1, 0);
  static const minorSecond = ChordComponent._('m2', 2, 1);
  static const flatSecond = ChordComponent._('b2', 2, 1);
  static const second = ChordComponent._('2', 2, 2);
  static const minorThird = ChordComponent._('m3', 3, 3);
  static const flatThird = ChordComponent._('b3', 3, 3);
  static const third = ChordComponent._('3', 3, 4);
  static const fourth = ChordComponent._('4', 4, 5);
  static const sharpFourth = ChordComponent._('#4', 4, 6);
  static const flatFifth = ChordComponent._('b5', 5, 6);
  static const fifth = ChordComponent._('5', 5, 7);
  static const sharpFifth = ChordComponent._('#5', 5, 8);
  static const minorSixth = ChordComponent._('m6', 6, 8);
  static const flatSixth = ChordComponent._('b6', 6, 8);
  static const sixth = ChordComponent._('6', 6, 9);
  static const flatSeventh = ChordComponent._('b7', 7, 10);
  static const minorSeventh = ChordComponent._('m7', 7, 10);
  static const seventh = ChordComponent._('7', 7, 11);
  static const octave = ChordComponent._('8', 8, 12);
  static const minorNinth = ChordComponent._('m9', 9, 12 + 1);
  static const ninth = ChordComponent._('9', 9, 12 + 2);
  static const eleventh = ChordComponent._('11', 11, 12 + 5);
  static const thirteenth = ChordComponent._('13', 13, 12 + 9);

  static List<ChordComponent> get values => _majorChordComponentByHalfSteps;

  const ChordComponent._(this._shortName, this._scaleNumber, this._halfSteps);

  static Set<ChordComponent> parse(String chordComponentString) {
    Set<ChordComponent> ret = {};
    for (String s in chordComponentString.split(RegExp(r'[,. ]'))) {
      if (s.isEmpty) {
        continue;
      }

      ChordComponent? cc;
      for (ChordComponent t in _majorChordComponentByHalfSteps) {
        if (t.shortName == s) {
          cc = t;
          break;
        }
      }

      //  specials
      if (cc == null) {
        switch (s) {
          case 'r':
          case '1':
            cc = root;
            break;
          case 'm2':
            cc = minorSecond;
            break;
          case 'b2':
            cc = flatSecond;
            break;
          case 'b3':
            cc = flatThird;
            break;
          case '#4':
            cc = sharpFourth;
            break;
          case 'm5':
            cc = flatFifth;
            break;
          case '#5':
            cc = sharpFifth;
            break;
          case 'b6':
            cc = flatSixth;
            break;
          case 'b7':
            cc = flatSeventh;
            break;
          case 'm9':
          case 'b9':
            cc = minorNinth;
            break;
          case '9':
            cc = ninth;
            break;
          case '11':
            cc = eleventh;
            break;
          case '13':
            cc = thirteenth;
            break;
          default:
            throw ArgumentError('unknown component: <$s>');
        }
      }
      ret.add(cc);
    }
    return ret;
  }

  static ChordComponent getByHalfStep(int halfStep) {
    return _majorChordComponentByHalfSteps[halfStep % MusicConstants.halfStepsPerOctave];
  }

  @override
  int compareTo(ChordComponent other) {
    return _halfSteps - other._halfSteps;
  }

  @override
  bool operator ==(other) {
    return runtimeType == other.runtimeType && identical(this, other);
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

  static final _majorChordComponentByHalfSteps = <ChordComponent>[
    root,
    minorSecond,
    second,
    minorThird,
    third,
    fourth,
    flatFifth,
    fifth,
    minorSixth,
    sixth,
    minorSeventh,
    seventh,
    octave,
    minorNinth,
    ninth,
    eleventh,
    thirteenth,
  ];
}
