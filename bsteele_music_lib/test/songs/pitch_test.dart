import 'dart:math';

import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/songs/music_constants.dart';
import 'package:bsteele_music_lib/songs/pitch.dart';
import 'package:bsteele_music_lib/util/app_util.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('test counts', () {
    expect(
      Pitch.getPitches().length,
      7 /* octaves */ * (12 /* notes */ + 9 /* aliases/octave */ ) +
          4 /* high notes (A7 or higher) */ +
          3 /* high note aliases */,
    );
  });

  test('pitch numbers', () {
    var lastPitch = Pitch.get(.A0);

    //  expected pitch ratio between half steps
    var refRatio = pow(2, (1 / 12));
    logger.i('$refRatio');

    for (var e in PitchEnum.values) {
      var pitch = Pitch.get(e);

      logger.i(
        '${e.name.padLeft(4)}: ${pitch.toString().padLeft(4)}: ${pitch.number.toString().padLeft(2)}'
        ': ${to16(pitch.frequency, pad: 21)}',
      );

      if (pitch.frequency != lastPitch.frequency) {
        var fRatio = pitch.frequency / lastPitch.frequency;
        // logger.i('$fRatio: ${fRatio - refRatio}');
        expect((fRatio - refRatio) < 2.23e-16, isTrue);
      }
      lastPitch = pitch;
    }
  });

  test('pitch by numbers', () {
    for (Pitch p in Pitch.getPitches()) {
      if (p.isFlat) {
        if (p.scaleNote == .Cb || p.scaleNote == .Fb) {
          expect(Pitch.findFlatByNumber(p.number), p.asSharp()); //  cheap trick
        } else
          expect(Pitch.findFlatByNumber(p.number), p);
      } else if (p.isSharp) {
        if (p.scaleNote == .Bs || p.scaleNote == .Es) {
          expect(Pitch.findSharpByNumber(p.number), p.asFlat()); //  cheap trick
        } else
          expect(Pitch.findSharpByNumber(p.number), p);
      } else {
        expect(Pitch.findFlatByNumber(p.number), p);
        expect(Pitch.findSharpByNumber(p.number), p);
      }
    }
  });

  test('testParsing', () {
    //  print table
    for (Pitch p in Pitch.getPitches()) {
      StringBuffer sb = StringBuffer();
      sb.write(p.name);
      while (sb.length < 4) {
        sb.write(' ');
      }
      if (p.number <= 9) {
        sb.write(' ');
      }
      sb.write(p.number);
      sb.write(' ');
      sb.write(p.frequency.toStringAsFixed(6));
      logger.i(sb.toString());
    }

    expect(Pitch.get(.A1).frequency, closeTo(55.0, 1e-20));
    expect(Pitch.get(.E1).frequency, closeTo(41.2034, 1e-4));
    expect(Pitch.get(.A2).frequency, closeTo(110.0, 1e-20));
    expect(Pitch.get(.E2).frequency, closeTo(Pitch.get(.E1).frequency * 2, 1e-20));
    expect(Pitch.get(.A3).frequency, closeTo(220.0, 1e-20));
    expect(Pitch.get(.E3).frequency, closeTo(Pitch.get(.E1).frequency * 4, 1e-12));
    expect(Pitch.get(.A4).frequency, closeTo(440.0, 1e-20));
    expect(Pitch.get(.E4).frequency, closeTo(Pitch.get(.E1).frequency * 8, 1e-12));
    expect(Pitch.get(.A5).frequency, closeTo(880.0, 1e-20));
    expect(Pitch.get(.C6).frequency, closeTo(1046.5022612023945, 1e-20)); // human voice, saprano
    expect(Pitch.get(.C8).frequency, closeTo(4186.009044809578, 1e-20)); //  piano
  });

  test('testIsSharp', () {
    int sharpCount = 0;
    int naturalCount = 0;
    int flatCount = 0;
    for (Pitch p in Pitch.getPitches()) {
      if (p.isSharp) {
        sharpCount++;
      }
      if (p.isFlat) {
        flatCount++;
      }
      if (p.isSharp && !p.isFlat) {
        naturalCount++;
      }
    }
    expect(7 * 7 + 2, sharpCount);
    expect(7 * 7 + 2, flatCount);
    expect(7 * 7 + 2, naturalCount);

    Pitch? p = Pitch.get(.A0);
    expect(false, p.isSharp);
    expect(false, p.isFlat);
    expect(true, p.isNatural);
    int sharps = 0;
    int naturals = 1;
    int flats = 0;
    for (int i = 0; i < Pitch.getPitches().length; i++) //  safety only
    {
      //System.out.println(p.toString());
      p = p!.offsetByHalfSteps(1);
      if (p == null) break;
      if (p.isSharp) sharps++;
      if (p.isNatural) naturals++;
      if (p.isFlat) flats++;
    }
    expect(0, sharps);
    expect(52, naturals);
    expect(36, flats);

    p = Pitch.get(.As0);
    expect(true, p.isSharp);
    expect(false, p.isFlat);
    expect(false, p.isNatural);

    sharps = 0;
    naturals = 0;
    flats = 0;

    for (Pitch p in Pitch.getPitches()) {
      logger.t(p.toString());
      if (p.isSharp) sharps++;
      if (p.isNatural) naturals++;
      if (p.isFlat) flats++;
    }
    expect(sharps, 51);
    expect(naturals, 52);
    expect(flats, 51);
  });

  test('test from Frequency', () {
    expect(Pitch.findFlatFromFrequency(1), Pitch.get(.A0));
    expect(Pitch.findSharpFromFrequency(1), Pitch.get(.A0));
    expect(Pitch.findFlatFromFrequency(41), Pitch.get(.E1));
    expect(Pitch.findFlatFromFrequency(42), Pitch.get(.E1));
    expect(Pitch.findFlatFromFrequency(43), Pitch.get(.F1));
    expect(Pitch.findFlatFromFrequency(880), Pitch.get(.A5));
    expect(Pitch.findFlatFromFrequency(906), Pitch.get(.A5));
    expect(Pitch.findFlatFromFrequency(907), Pitch.get(.Bb5));
    expect(Pitch.findFlatFromFrequency(933), Pitch.get(.Bb5));
    expect(Pitch.findSharpFromFrequency(933), Pitch.get(.As5));
    expect(Pitch.findFlatFromFrequency(7030), Pitch.get(.C8));
  });

  test('test NextPitch', () {
    Pitch p = Pitch.get(.E2);

    expect(p.nextHigherPitch(), Pitch.get(.F2));
    p = Pitch.findFlatFromFrequency(82);
    expect(p, Pitch.get(.E2));
    expect(p.nextHigherPitch(), Pitch.get(.F2));
    p = Pitch.findFlatFromFrequency(92);
    expect(p, Pitch.get(.Gb2));
    expect(p.nextHigherPitch(), Pitch.get(.G2));
    p = Pitch.findSharpFromFrequency(92);
    expect(p, Pitch.get(.Fs2));
    expect(p.nextHigherPitch(), Pitch.get(.G2));
  });

  test('test asSharp and asFlat', () {
    Pitch p;

    p = Pitch.get(.E2);
    expect(p.asSharp(), p);
    expect(p.asFlat(), p);

    p = Pitch.get(.Eb2);
    expect(p.asSharp(), Pitch.get(.Ds2));
    expect(p.asFlat(), p);

    p = Pitch.get(.Cs2);
    expect(p.asSharp(), p);
    expect(p.asFlat(), Pitch.get(.Db2));

    p = Pitch.get(.Es2);
    expect(p.asSharp(), p);
    expect(p.asFlat(), Pitch.get(.F2));

    p = Pitch.get(.Gs2);
    expect(p.asSharp(), p);
    expect(p.asFlat(), Pitch.get(.Ab2));

    p = Pitch.get(.Bs2);
    expect(p.asSharp(), p);
    expect(p.asFlat(), Pitch.get(.C3));

    for (PitchEnum pe in PitchEnum.values) {
      Pitch p = Pitch.get(pe);
      var note = p.getScaleNote();
      print('$p: asSharp: ${p.asSharp()}, asFlat: ${p.asFlat()}, note: $note');
      if (p.isSharp || p.isFlat) {
        if (note != .Cb && note != .Fb) expect(p.asSharp().name.contains('s'), true);
        if (note != .Bs && note != .Es) expect(p.asFlat().name.contains('b'), true);
      } else {
        expect(p.asSharp().name.contains('s'), false);
        expect(p.asFlat().name.contains('b'), false);
      }
    }
  });

  test('test getFromMidiNoteNumber()', () {
    var a0 = Pitch.get(.A0);
    logger.i('$a0: ${a0.frequency}');
    var e1 = Pitch.get(.E1);
    logger.i('$e1: ${e1.frequency}');
    var c8 = Pitch.get(.C8);
    logger.i('$c8: ${c8.frequency}');

    for (var i = -3; i < 21; i++) {
      expect(Pitch.getFromMidiNoteNumber(i), a0);
    }
    for (var i = 0; i < 88; i++) {
      expect(Pitch.getFromMidiNoteNumber(21 + i), Pitch.sharps[i]);
    }
    for (var i = 88 + 21; i < 127; i++) {
      expect(Pitch.getFromMidiNoteNumber(i), c8);
    }

    for (var b in [true, false]) {
      for (var i = -3; i < 21; i++) {
        expect(Pitch.getFromMidiNoteNumber(i, asSharp: b), a0);
      }
      for (var i = 0; i < 88; i++) {
        expect(Pitch.getFromMidiNoteNumber(21 + i, asSharp: b), (b ? Pitch.sharps : Pitch.flats)[i]);
      }
      for (var i = 88 + 21; i < 127; i++) {
        expect(Pitch.getFromMidiNoteNumber(i, asSharp: b), c8);
      }
    }
  });

  test('test scale ratios', () {
    var basePitch = Pitch.get(.C4);
    for (int i = 0; i <= MusicConstants.halfStepsPerOctave; i++) {
      var pitch = Pitch.sharps[basePitch.number + i];
      logger.i(
        '$i ${pitch.toString().padRight(3)} ${pitch.number.toString().padLeft(2)}'
        ' ${pitch.frequency.toStringAsFixed(12).padLeft(12 + 1 + 4)}'
        ' ${pitch.frequency / basePitch.frequency}'
        '',
      );
    }
    // for (var pitch in Pitch.sharps) {
    //   logger.i('${pitch.toString().padRight(3)} ${pitch.number.toString().padLeft(2)}'
    //       ' ${pitch.frequency.toStringAsFixed(12).padLeft(12+1+4)}');
    // }
  });

  test('test pitch frequencies', () {
    Map<int, Pitch> fMap = {};
    for (var pitchEnum in PitchEnum.values) {
      Pitch pitch = Pitch.get(pitchEnum);

      logger.i(
        '${pitch.toString().padRight(3)} ${pitch.number.toString().padLeft(2)}'
        ' ${pitch.frequency.toStringAsFixed(12).padLeft(12 + 1 + 4)}',
      );

      Pitch? foundPitch = fMap[pitch.number];
      if (foundPitch == null) {
        fMap[pitch.number] = pitch;
      } else {
        logger.i('    same f as: $foundPitch');
        expect(pitch.frequency, foundPitch.frequency);
      }
    }
  });

  test('test pitch ratios', () {
    for (var pitch in Pitch.flats) {
      logger.i(
        '${pitch.toString().padRight(3)} ${pitch.number.toString().padLeft(2)}'
        ' ${pitch.frequency.toStringAsFixed(12).padLeft(12 + 1 + 4)}',
      );
      var nextPitch = pitch.nextHigherPitch()?.asFlat();
      if (nextPitch != null) {
        var ratio = nextPitch.frequency / pitch.frequency;
        logger.i('   next as fraction: $ratio');
        expect(ratio, closeTo(MusicConstants.halfStepFrequencyRatio, 2.3e-16));
      }
    }
  });

  test('test frequency with cents', () {
    Pitch? lastPitch;
    double lastF = 0;
    for (var pitch in Pitch.sharps) {
      logger.i(
        '${pitch.toString().padRight(3)} ${pitch.number.toString().padLeft(2)}'
        ' ${to12(pitch.frequency)}',
      );
      for (int cents = -50; cents <= 50; cents += 5) {
        double f = pitch.frequencyWithCents(cents);
        logger.i('    cents: ${cents.toString().padLeft(3)}:  f: ${to12(f)}');
        if (cents == 0) {
          expect(f, closeTo(pitch.frequency, 1e-300));
        } else if (lastPitch != null) {
          if (cents == -50) {
            expect(f, lastF);
          } else {
            assert(f > lastF);
          }
        }
        lastF = f;
      }
      lastPitch = pitch;
    }
  });

  test('test cents from frequency', () {
    for (var pitch in Pitch.sharps) {
      logger.i(
        '${pitch.toString().padRight(3)} ${pitch.number.toString().padLeft(2)}'
        ' ${to12(pitch.frequency)}',
      );
      for (int cents = -50; cents <= 50; cents += 5) {
        double f = pitch.frequencyWithCents(cents);
        int centsFromFrequency = pitch.centsFromFrequency(f);
        logger.i(
          '    cents: ${cents.toString().padLeft(3)}:  f: ${to12(f)}'
          ', cents: ${centsFromFrequency.toString().padLeft(3)}',
        );
        expect(centsFromFrequency, cents);
      }
    }
  });

  test('test all pitches', () {
    int number = 0;
    for (var pitch in Pitch.sharps) {
      logger.i(
        '${pitch.toString().padRight(3)} ${pitch.number.toString().padLeft(2)}'
        ' ${pitch.frequency.toStringAsFixed(12).padLeft(12 + 1 + 4)}',
      );
      logger.i('  accidental: ${pitch.accidental.name}, number: ${pitch.number}');

      expect(pitch.number, number);
      expect(pitch.isFlat, false);
      expect(pitch.accidental.name, pitch.isSharp ? 'sharp' : 'natural');
      number++;
    }

    number = 0;
    for (var pitch in Pitch.flats) {
      logger.i(
        '${pitch.toString().padRight(3)} ${pitch.number.toString().padLeft(2)}'
        ' ${to12(pitch.frequency)}',
      );
      logger.i('  accidental: ${pitch.accidental.name}, number: ${pitch.number}');

      expect(pitch.number, number);
      expect(pitch.isSharp, false);
      expect(pitch.accidental.name, pitch.isFlat ? 'flat' : 'natural');
      number++;
    }
  });
}

/*

  A0:   A0:  0:   27.5000000000000000
 As0:  A♯0:  1:   29.1352350948806205
 Bb0:  B♭0:  1:   29.1352350948806205
  B0:   B0:  2:   30.8677063285077509
 Bs0:  B♯0:  3:   32.7031956625748279
 Cb1:  C♭1:  2:   30.8677063285077509
  C1:   C1:  3:   32.7031956625748279
 Cs1:  C♯1:  4:   34.6478288721090095
 Db1:  D♭1:  4:   34.6478288721090095
  D1:   D1:  5:   36.7080959896759396
 Ds1:  D♯1:  6:   38.8908729652601153
 Eb1:  E♭1:  6:   38.8908729652601153
  E1:   E1:  7:   41.2034446141087471          //    bass low E
 Es1:  E♯1:  8:   43.6535289291254855
 Fb1:  F♭1:  7:   41.2034446141087471
  F1:   F1:  8:   43.6535289291254855
 Fs1:  F♯1:  9:   46.2493028389542999
 Gb1:  G♭1:  9:   46.2493028389542999
  G1:   G1: 10:   48.9994294977186655
 Gs1:  G♯1: 11:   51.9130871974931409
 Ab1:  A♭1: 11:   51.9130871974931409
  A1:   A1: 12:   55.0000000000000000          //    bass open A
 As1:  A♯1: 13:   58.2704701897612409
 Bb1:  B♭1: 13:   58.2704701897612409
  B1:   B1: 14:   61.7354126570155017
 Bs1:  B♯1: 15:   65.4063913251496558
 Cb2:  C♭2: 14:   61.7354126570155017
  C2:   C2: 15:   65.4063913251496558
 Cs2:  C♯2: 16:   69.2956577442180190
 Db2:  D♭2: 16:   69.2956577442180190
  D2:   D2: 17:   73.4161919793518791          //    bass open D
 Ds2:  D♯2: 18:   77.7817459305202306
 Eb2:  E♭2: 18:   77.7817459305202306
  E2:   E2: 19:   82.4068892282174943
 Es2:  E♯2: 20:   87.3070578582509711
 Fb2:  F♭2: 19:   82.4068892282174943
  F2:   F2: 20:   87.3070578582509711
 Fs2:  F♯2: 21:   92.4986056779085999
 Gb2:  G♭2: 21:   92.4986056779085999
  G2:   G2: 22:   97.9988589954373310           //   bass open G
 Gs2:  G♯2: 23:  103.8261743949862819
 Ab2:  A♭2: 23:  103.8261743949862819
  A2:   A2: 24:  110.0000000000000000
 As2:  A♯2: 25:  116.5409403795224819
 Bb2:  B♭2: 25:  116.5409403795224819
  B2:   B2: 26:  123.4708253140310319
 Bs2:  B♯2: 27:  130.8127826502993116
 Cb3:  C♭3: 26:  123.4708253140310319
  C3:   C3: 27:  130.8127826502993116
 Cs3:  C♯3: 28:  138.5913154884360381
 Db3:  D♭3: 28:  138.5913154884360381
  D3:   D3: 29:  146.8323839587037867
 Ds3:  D♯3: 30:  155.5634918610404611
 Eb3:  E♭3: 30:  155.5634918610404611
  E3:   E3: 31:  164.8137784564349602
 Es3:  E♯3: 32:  174.6141157165019422
 Fb3:  F♭3: 31:  164.8137784564349602
  F3:   F3: 32:  174.6141157165019422
 Fs3:  F♯3: 33:  184.9972113558171998
 Gb3:  G♭3: 33:  184.9972113558171998
  G3:   G3: 34:  195.9977179908746336
 Gs3:  G♯3: 35:  207.6523487899725637
 Ab3:  A♭3: 35:  207.6523487899725637
  A3:   A3: 36:  220.0000000000000000
 As3:  A♯3: 37:  233.0818807590449637
 Bb3:  B♭3: 37:  233.0818807590449637
  B3:   B3: 38:  246.9416506280620638
 Bs3:  B♯3: 39:  261.6255653005986233
 Cb4:  C♭4: 38:  246.9416506280620638
  C4:   C4: 39:  261.6255653005986233
 Cs4:  C♯4: 40:  277.1826309768720762
 Db4:  D♭4: 40:  277.1826309768720762
  D4:   D4: 41:  293.6647679174075733
 Ds4:  D♯4: 42:  311.1269837220809222
 Eb4:  E♭4: 42:  311.1269837220809222
  E4:   E4: 43:  329.6275569128699203
 Es4:  E♯4: 44:  349.2282314330038844
 Fb4:  F♭4: 43:  329.6275569128699203
  F4:   F4: 44:  349.2282314330038844
 Fs4:  F♯4: 45:  369.9944227116343995
 Gb4:  G♭4: 45:  369.9944227116343995
  G4:   G4: 46:  391.9954359817492673
 Gs4:  G♯4: 47:  415.3046975799451275
 Ab4:  A♭4: 47:  415.3046975799451275
  A4:   A4: 48:  440.0000000000000000
 As4:  A♯4: 49:  466.1637615180899274
 Bb4:  B♭4: 49:  466.1637615180899274
  B4:   B4: 50:  493.8833012561241276
 Bs4:  B♯4: 51:  523.2511306011972465
 Cb5:  C♭5: 50:  493.8833012561241276
  C5:   C5: 51:  523.2511306011972465
 Cs5:  C♯5: 52:  554.3652619537441524
 Db5:  D♭5: 52:  554.3652619537441524
  D5:   D5: 53:  587.3295358348151467
 Ds5:  D♯5: 54:  622.2539674441618445
 Eb5:  E♭5: 54:  622.2539674441618445
  E5:   E5: 55:  659.2551138257398406
 Es5:  E♯5: 56:  698.4564628660077688
 Fb5:  F♭5: 55:  659.2551138257398406
  F5:   F5: 56:  698.4564628660077688
 Fs5:  F♯5: 57:  739.9888454232687991
 Gb5:  G♭5: 57:  739.9888454232687991
  G5:   G5: 58:  783.9908719634985346
 Gs5:  G♯5: 59:  830.6093951598902549
 Ab5:  A♭5: 59:  830.6093951598902549
  A5:   A5: 60:  880.0000000000000000
 As5:  A♯5: 61:  932.3275230361798549
 Bb5:  B♭5: 61:  932.3275230361798549
  B5:   B5: 62:  987.7666025122482552
 Bs5:  B♯5: 63: 1046.5022612023944930
 Cb6:  C♭6: 62:  987.7666025122482552
  C6:   C6: 63: 1046.5022612023944930
 Cs6:  C♯6: 64: 1108.7305239074883048
 Db6:  D♭6: 64: 1108.7305239074883048
  D6:   D6: 65: 1174.6590716696302934
 Ds6:  D♯6: 66: 1244.5079348883236889
 Eb6:  E♭6: 66: 1244.5079348883236889
  E6:   E6: 67: 1318.5102276514796813
 Es6:  E♯6: 68: 1396.9129257320155375
 Fb6:  F♭6: 67: 1318.5102276514796813
  F6:   F6: 68: 1396.9129257320155375
 Fs6:  F♯6: 69: 1479.9776908465375982
 Gb6:  G♭6: 69: 1479.9776908465375982
  G6:   G6: 70: 1567.9817439269970691
 Gs6:  G♯6: 71: 1661.2187903197805099
 Ab6:  A♭6: 71: 1661.2187903197805099
  A6:   A6: 72: 1760.0000000000000000
 As6:  A♯6: 73: 1864.6550460723597098
 Bb6:  B♭6: 73: 1864.6550460723597098
  B6:   B6: 74: 1975.5332050244960556
 Bs6:  B♯6: 75: 2093.0045224047889860
 Cb7:  C♭7: 74: 1975.5332050244960556
  C7:   C7: 75: 2093.0045224047889860
 Cs7:  C♯7: 76: 2217.4610478149766095
 Db7:  D♭7: 76: 2217.4610478149766095
  D7:   D7: 77: 2349.3181433392601321
 Ds7:  D♯7: 78: 2489.0158697766473779
 Eb7:  E♭7: 78: 2489.0158697766473779
  E7:   E7: 79: 2637.0204553029598173
 Es7:  E♯7: 80: 2793.8258514640310750
 Fb7:  F♭7: 79: 2637.0204553029598173
  F7:   F7: 80: 2793.8258514640310750
 Fs7:  F♯7: 81: 2959.9553816930751964
 Gb7:  G♭7: 81: 2959.9553816930751964
  G7:   G7: 82: 3135.9634878539945930
 Gs7:  G♯7: 83: 3322.4375806395610198
 Ab7:  A♭7: 83: 3322.4375806395610198
  A7:   A7: 84: 3520.0000000000000000
 As7:  A♯7: 85: 3729.3100921447194196
 Bb7:  B♭7: 85: 3729.3100921447194196
  B7:   B7: 86: 3951.0664100489921111
 Bs7:  B♯7: 87: 4186.0090448095779720
 Cb8:  C♭8: 86: 3951.0664100489921111
  C8:   C8: 87: 4186.0090448095779720

 */
