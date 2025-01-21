import 'package:collection/collection.dart';

import '../app_logger.dart';

final guitarStringCount = 6;
final guitarMaxFret = 24;
final guitarMaxFingering = 4;
final guitarNotThisString = -1;

/// guitar chord chart data
/// note: worry about inversions.  at the moment, they are excluded
/// note: they source json file format is terrible.  Odd stuff is done to get around this.
class GuitarChord {
  GuitarChord.unknown()
      : name = 'unknown',
        positions = List<int>.generate(guitarStringCount, (i) {
          return guitarNotThisString;
        }),
        fingerings = List<int>.generate(guitarStringCount, (i) {
          return 0;
        });

  GuitarChord(this.name, this.positions, this.fingerings);

  factory GuitarChord.fromJson(final Map<String, dynamic> json) {
    if (json.isNotEmpty) {
      var key = json.keys.first;
      if (key == 'name') {
        //  proper json
        return _fromJsonPartial(json[key], json); //  fixme: first fingering/position only!!!!
      }
      return _fromJsonPartial(key, json[key].first); //  fixme: first fingering/position only!!!!
    }
    return GuitarChord.unknown();
  }

  static List<GuitarChord> fromJsonList(final Map<String, dynamic> json) {
    List<GuitarChord> ret = [];
    for (var key in json.keys) {
      if (key.contains('/')) {
        continue; //  no inversions!   12708 total chords if included
      }
      var jsonOptions = json[key];
      if (jsonOptions.isNotEmpty && jsonOptions.first is Map<String, dynamic>) {
        ret.add(_fromJsonPartial(key, jsonOptions.first)); //  fixme: first fingering/position only!!!!
      } else {
        // print( 'bad options at $key: $jsonOptions');
      }
    }
    return ret;
  }

  static GuitarChord _fromJsonPartial(final String name, final Map<String, dynamic> json) {
    var positions = List<int>.generate(guitarStringCount, (i) {
      return guitarNotThisString;
    });
    var fingering = List<int>.generate(guitarStringCount, (i) {
      return 0;
    });
    if (json.isNotEmpty) {
      for (var param in json.keys) {
        switch (param) {
          case 'positions':
            var optionPositions = json[param];
            assert(optionPositions.length == guitarStringCount);
            for (int i = 0; i < guitarStringCount; i++) {
              var optionPosition = optionPositions[i];
              int position = optionPosition is int ? optionPosition : int.tryParse(optionPosition) ?? -1;
              assert(position <= guitarMaxFret);
              positions[i] = position;
            }
            break;
          case 'fingerings':
            var optionFingerings = json[param];
            if (optionFingerings.isNotEmpty) {
              var optionFingering = optionFingerings.first is List //
                  ? optionFingerings.first //  original input
                  : optionFingerings;
              assert(optionFingering.length == guitarStringCount);
              for (int i = 0; i < guitarStringCount; i++) {
                int f = optionFingering[i] is int ? optionFingering[i] : int.tryParse(optionFingering[i]) ?? -1;
                assert(f <= guitarMaxFingering);
                fingering[i] = f;
              }
            }
            break;
          case 'name':
            break;
          default:
            logger.i('unknown guitar chord param: $param');
            assert(false);
            break;
        }
      }
    }
    return GuitarChord(name, positions, fingering);
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'positions': positions.map((c) => c).toList(),
        'fingerings': fingerings.map((c) => c).toList(),
      };

  @override
  String toString() {
    return 'GuitarChord{name: "$name", positions: $positions, fingerings: $fingerings}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuitarChord &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          listEquality.equals(positions, other.positions) &&
          listEquality.equals(fingerings, other.fingerings);

  @override
  int get hashCode => Object.hash(name, positions, fingerings);

  final String name;
  final List<int> positions; //  less than zero => X, i.e. string is not to be strummed
  final List<int> fingerings;
  static const listEquality = ListEquality();
}
