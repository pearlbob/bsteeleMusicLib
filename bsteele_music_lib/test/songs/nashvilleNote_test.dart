import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/musicConstants.dart';
import 'package:bsteeleMusicLib/songs/nashvilleNote.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('test Nashville notes', () {
    expect(NashvilleNote.values.length, MusicConstants.halfStepsPerOctave);

    expect(NashvilleNote.nashville1.toString(), '1');
    expect(NashvilleNote.nashvilleFlat2.toString(), '♭2');
    expect(NashvilleNote.nashville2.toString(), '2');
    expect(NashvilleNote.nashvilleFlat7.toString(), '♭7');
    expect(NashvilleNote.nashville7.toString(), '7');

    for (var n = 0; n < NashvilleNote.values.length; n++) {
      var note = NashvilleNote.values[n];
      logger.i('$n:\t${note.toMarkup()}\t${NashvilleNote.values[n]}');
      expect(NashvilleNote.byHalfStep(n), note);
      expect(note.toString(), note.toMarkup().replaceAll('b', MusicConstants.flatChar));
    }
  });

  test('test Nashville Roman notes', () {
    expect(NashvilleRomanNote.values.length, MusicConstants.halfStepsPerOctave);

    //  code generator
    // for ( var r in NashvilleRomanNote.values ){
    //   logger.i('expect(NashvilleRomanNote.${r.name}.toString(), \'${r.toString()}\'); ');
    // }

    expect(NashvilleRomanNote.roman1.toString(), 'I');
    expect(NashvilleRomanNote.romanFlat2.toString(), '♭II');
    expect(NashvilleRomanNote.roman2.toString(), 'II');
    expect(NashvilleRomanNote.romanFlat3.toString(), '♭III');
    expect(NashvilleRomanNote.roman3.toString(), 'III');
    expect(NashvilleRomanNote.roman4.toString(), 'IV');
    expect(NashvilleRomanNote.romanFlat5.toString(), '♭V');
    expect(NashvilleRomanNote.roman5.toString(), 'V');
    expect(NashvilleRomanNote.romanFlat6.toString(), '♭VI');
    expect(NashvilleRomanNote.roman6.toString(), 'VI');
    expect(NashvilleRomanNote.romanFlat7.toString(), '♭VII');
    expect(NashvilleRomanNote.roman7.toString(), 'VII');

    for (var n = 0; n < NashvilleRomanNote.values.length; n++) {
      var note = NashvilleRomanNote.values[n];
      logger.i('$n:\t${note.toMarkup()}\t${NashvilleRomanNote.values[n]}'
          ', ${NashvilleRomanNote.values[n].toMarkup().toLowerCase()}');
      expect(NashvilleRomanNote.byHalfStep(n), note);
      expect(note.toString(), note.toMarkup().replaceAll('b', MusicConstants.flatChar));
    }
  });
}
