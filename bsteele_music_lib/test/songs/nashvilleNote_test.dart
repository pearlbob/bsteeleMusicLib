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
}
