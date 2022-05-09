import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/musicConstants.dart';
import 'package:bsteeleMusicLib/songs/scaleNote.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.warning;

  test('Scale note sharps, flats and naturals', () {
    ScaleNote sn = ScaleNote.get(ScaleNoteEnum.A);
    expect(0, sn.halfStep);
    sn = ScaleNote.get(ScaleNoteEnum.X);
    expect(0, sn.halfStep);

    final RegExp endsInB = RegExp(r'b$');
    final RegExp endsInS = RegExp(r's$');
    for (final e in ScaleNoteEnum.values) {
      sn = ScaleNote.get(e);
      logger.d(e.toString() + ': ' + endsInB.hasMatch(e.toString()).toString());
      expect(sn.isFlat, endsInB.hasMatch(e.toString()));
      expect(sn.isSharp, endsInS.hasMatch(e.toString()));
      if (e != ScaleNoteEnum.X) {
        expect(sn.isFlat, !(sn.isSharp || sn.isNatural));
        expect(sn.isSilent, false);
      } else {
        expect(sn.isSilent, true);
        expect(sn.isFlat, false);
        expect(sn.isSharp, false);
        expect(sn.isNatural, false);
      }
    }
  });

  test('get By HalfStep', () {
    for (int i = 0; i < MusicConstants.halfStepsPerOctave * 3; i++) {
      ScaleNote sn = ScaleNote.getSharpByHalfStep(i);
      expect(sn.isSharp || sn.isNatural, true);
      expect(sn.isFlat, false);
      expect(sn.isSilent, false);
    }
    for (int i = -3; i < MusicConstants.halfStepsPerOctave * 2; i++) {
      ScaleNote sn = ScaleNote.getFlatByHalfStep(i);
      expect(sn.isSharp, false);
      expect(sn.isFlat || sn.isNatural, true);
      expect(sn.isSilent, false);
    }
  });

  test('get asSharp', () {
    Logger.level = Level.info;
    for (int i = 0; i < MusicConstants.halfStepsPerOctave; i++) {
      ScaleNote sn = ScaleNote.getSharpByHalfStep(i);
      var sharp = sn.asSharp();
      var sharpTrue = sn.asSharp(value: true);
      var flat = sn.asFlat();
      var flatTrue = sn.asFlat(value: true);
      logger.i('sn: $sn $sharp $sharpTrue $flat $flatTrue');
      expect(sharp, sn);
      expect(sharpTrue, sn);
      if (!sn.isNatural) {
        expect(flat.isFlat, isTrue);
        expect(flatTrue.isFlat, isTrue);
      }
    }

    for (int i = 0; i < MusicConstants.halfStepsPerOctave; i++) {
      ScaleNote sn = ScaleNote.getFlatByHalfStep(i);
      var sharp = sn.asSharp();
      var sharpTrue = sn.asSharp(value: true);
      var flat = sn.asFlat();
      var flatTrue = sn.asFlat(value: true);
      logger.i('sn: $sn $sharp $sharpTrue $flat $flatTrue');
      expect(flat, sn);
      expect(flatTrue, sn);
      if (!sn.isNatural) {
        expect(sharp.isSharp, isTrue);
        expect(sharpTrue.isSharp, isTrue);
      }
    }
  });
}
