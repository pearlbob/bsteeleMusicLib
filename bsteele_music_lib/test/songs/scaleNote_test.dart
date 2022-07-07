import 'dart:math';

import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/musicConstants.dart';
import 'package:bsteeleMusicLib/songs/scaleNote.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('Scale note sharps, flats and naturals', () {
    var sn = ScaleNote.A;
    expect(0, sn.halfStep);
    sn = ScaleNote.X;
    expect(0, sn.halfStep);

    final RegExp endsInB = RegExp(r'b$');
    final RegExp endsInS = RegExp(r's$');
    for (final e in ScaleNote.values) {
      sn = e;
      logger.d(e.name + ': ' + endsInB.hasMatch(e.toString()).toString());
      expect(sn.isFlat, endsInB.hasMatch(e.name));
      expect(sn.isSharp, endsInS.hasMatch(e.name));
      if (e != ScaleNote.X) {
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
      var sn = ScaleNote.getSharpByHalfStep(i);
      expect(sn.isSharp || sn.isNatural, true);
      expect(sn.isFlat, false);
      expect(sn.isSilent, false);
    }
    for (int i = -3; i < MusicConstants.halfStepsPerOctave * 2; i++) {
      var sn = ScaleNote.getFlatByHalfStep(i);
      expect(sn.isSharp, false);
      expect(sn.isFlat || sn.isNatural, true);
      expect(sn.isSilent, false);
    }
  });

  test('get asSharp', () {
    Logger.level = Level.info;
    for (int i = 0; i < MusicConstants.halfStepsPerOctave; i++) {
      var sn = ScaleNote.getSharpByHalfStep(i);
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
      var sn = ScaleNote.getFlatByHalfStep(i);
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

  test('test intervals', () {
    Logger.level = Level.info;
    logger.i('\nD Pythagorean Scale Note Intervals:');
    for (var interval in DPythagoreanScaleNoteInterval.intervals) {
      logger.i('${interval.name}:'
          ' ${interval.numerator.toString().padLeft(4)}'
          '/${interval.denominator.toString().padRight(4)}'
          ' = ${interval.ratio.toStringAsFixed(12).padLeft(12 + 1 + 1)}');
    }
    logger.i('\nFive Limit Scale Note Intervals:');
    for (var interval in FiveLimitScaleNoteInterval.intervals) {
      logger.i('${interval.name}:'
          ' ${interval.numerator.toString().padLeft(4)}'
          '/${interval.denominator.toString().padRight(4)}'
          ' = ${interval.ratio.toStringAsFixed(12).padLeft(12 + 1 + 1)}');
    }
    logger.i('\nEqual Temperament Scale Note Interval:');
    for (var interval in EqualTemperamentScaleNoteInterval.intervals) {
      logger.i('${interval.name}:'
          ' ${interval.numerator.toString().padLeft(4)}'
          '/${interval.denominator.toString().padRight(4)}'
          ' = ${interval.ratio.toStringAsFixed(12).padLeft(12 + 1 + 1)}');
    }

    //  testing:
    double maxError = 0;
    double tolerance = 0.01821;
    for (var i = 0; i < EqualTemperamentScaleNoteInterval.intervals.length; i++) {
      var e = EqualTemperamentScaleNoteInterval.intervals[i];
      var d = DPythagoreanScaleNoteInterval.intervals[i];
      var f = FiveLimitScaleNoteInterval.intervals[i];
      logger.d('$i: e: ${e.ratio},  d: ${d.ratio} (${(d.ratio - e.ratio).abs()})'
          ',  f: ${f.ratio}  (${(f.ratio - e.ratio).abs()})');
      var error = (d.ratio - e.ratio).abs();
      maxError = max(maxError, error);
      expect(error < tolerance, true);
      error = (f.ratio - e.ratio).abs();
      maxError = max(maxError, error);
      expect(error < tolerance, true);
    }
    logger.i('maxError: $maxError');
  });

  /// temporary proof of software transition
  test('test enum extensions', () {
    Logger.level = Level.info;

    for (final sn in ScaleNote.values) {
      logger.i('${sn.name}');
    }
    logger.i('${ScaleNote.valueOf(ScaleNote.As.name)}');

    //  test old ScaleNote against ScaleNoteEnum3
    for (final sn in ScaleNote.values) {
      logger.i('${sn.name}(${sn.halfStep}, \'${sn.toMarkup()}\', \'$sn\','
          ' ${sn.isSharp}, ${sn.isFlat},'
          ' alias: ${sn.alias.name}, '
          ' scaleNumber: ${sn.scaleNumber},'
          ' isSilent: ${sn.isSilent} ),'
          //
          );
      var sn3 = ScaleNote.parseString(sn.toMarkup());
      expect(sn3, isNotNull);
      sn3 = sn3!;
      expect(sn3.toMarkup(), sn.toMarkup());
      expect(sn3.isFlat, sn.isFlat);
      expect(sn3.isSharp, sn.isSharp);
      expect(sn3.isNatural, sn.isNatural);
      expect(sn3.isSilent, sn.isSilent);
      expect(sn3.accidental, sn.accidental);
      expect(sn3.halfStep, sn.halfStep);
      expect(sn3.asFlat().toMarkup(), sn.asFlat().toMarkup());
      expect(sn3.asSharp().toMarkup(), sn.asSharp().toMarkup());
      if (sn3 != ScaleNote.Bs && sn3 != ScaleNote.Cb && sn3 != ScaleNote.Es && sn3 != ScaleNote.Fb) {
        expect(sn3.alias.toMarkup(), sn.alias.toMarkup());
      }

      for (final snOther in ScaleNote.values) {
        var sn3Other = ScaleNote.parseString(snOther.toMarkup());
        expect(sn3.compareTo(sn3Other!), sn.compareTo(snOther));
      }

      logger.i('sn: $sn, name: "${sn.name}"');
      ScaleNote.valueOf(sn.toMarkup());
      logger.i('    "${ScaleNote.parseString(sn.toMarkup())?.toMarkup() ?? 'null'}"'
          ' vs "${ScaleNote.valueOf(sn.name)?.toMarkup()}"');
      expect(ScaleNote.parseString(sn.toMarkup())?.toMarkup(), ScaleNote.valueOf(sn.name)?.toMarkup());
    }
  });
}
