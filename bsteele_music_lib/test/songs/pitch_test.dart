import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/pitch.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('test counts', () {
    expect(
        Pitch.getPitches().length,
        7 /* octaves */ * (12 /* notes */ + 9 /* aliases/octave */) +
            4 /* high notes (A7 or higher) */ +
            3 /* high note aliases */);
  });

  test('testParsing', () {
    if (true) {
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
        print(sb.toString());
      }
    }
    expect(Pitch.get(PitchEnum.A1).frequency, closeTo(55.0, 1e-20));
    expect(Pitch.get(PitchEnum.E1).frequency, closeTo(41.2034, 1e-4));
    expect(Pitch.get(PitchEnum.A2).frequency, closeTo(110.0, 1e-20));
    expect(Pitch.get(PitchEnum.E2).frequency, closeTo(Pitch.get(PitchEnum.E1).frequency * 2, 1e-20));
    expect(Pitch.get(PitchEnum.A3).frequency, closeTo(220.0, 1e-20));
    expect(Pitch.get(PitchEnum.E3).frequency, closeTo(Pitch.get(PitchEnum.E1).frequency * 4, 1e-12));
    expect(Pitch.get(PitchEnum.A4).frequency, closeTo(440.0, 1e-20));
    expect(Pitch.get(PitchEnum.E4).frequency, closeTo(Pitch.get(PitchEnum.E1).frequency * 8, 1e-12));
    expect(Pitch.get(PitchEnum.A5).frequency, closeTo(880.0, 1e-20));
    expect(Pitch.get(PitchEnum.C6).frequency, closeTo(1046.5022612023945, 1e-20)); // human voice, saprano
    expect(Pitch.get(PitchEnum.C8).frequency, closeTo(4186.009044809578, 1e-20)); //  piano
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

    Pitch? p = Pitch.get(PitchEnum.A0);
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

    p = Pitch.get(PitchEnum.As0);
    expect(true, p.isSharp);
    expect(false, p.isFlat);
    expect(false, p.isNatural);

    sharps = 0;
    naturals = 0;
    flats = 0;

    for (Pitch p in Pitch.getPitches()) {
      logger.v(p.toString());
      if (p.isSharp) sharps++;
      if (p.isNatural) naturals++;
      if (p.isFlat) flats++;
    }
    expect(sharps, 51);
    expect(naturals, 52);
    expect(flats, 51);
  });

  test('testfromFrequency', () {
    expect(Pitch.findFlatFromFrequency(1), Pitch.get(PitchEnum.A0));
    expect(Pitch.findSharpFromFrequency(1), Pitch.get(PitchEnum.A0));
    expect(Pitch.findFlatFromFrequency(41), Pitch.get(PitchEnum.E1));
    expect(Pitch.findFlatFromFrequency(42), Pitch.get(PitchEnum.E1));
    expect(Pitch.findFlatFromFrequency(43), Pitch.get(PitchEnum.F1));
    expect(Pitch.findFlatFromFrequency(880), Pitch.get(PitchEnum.A5));
    expect(Pitch.findFlatFromFrequency(906), Pitch.get(PitchEnum.A5));
    expect(Pitch.findFlatFromFrequency(907), Pitch.get(PitchEnum.Bb5));
    expect(Pitch.findFlatFromFrequency(933), Pitch.get(PitchEnum.Bb5));
    expect(Pitch.findSharpFromFrequency(933), Pitch.get(PitchEnum.As5));
    expect(Pitch.findFlatFromFrequency(7030), Pitch.get(PitchEnum.C8));
  });

  test('testNextPitch', () {
    Pitch p = Pitch.get(PitchEnum.E2);

    expect(p.nextHigherPitch(), Pitch.get(PitchEnum.F2));
    p = Pitch.findFlatFromFrequency(82);
    expect(p, Pitch.get(PitchEnum.E2));
    expect(p.nextHigherPitch(), Pitch.get(PitchEnum.F2));
    p = Pitch.findFlatFromFrequency(92);
    expect(p, Pitch.get(PitchEnum.Gb2));
    expect(p.nextHigherPitch(), Pitch.get(PitchEnum.G2));
    p = Pitch.findSharpFromFrequency(92);
    expect(p, Pitch.get(PitchEnum.Fs2));
    expect(p.nextHigherPitch(), Pitch.get(PitchEnum.G2));
  });

  test('test asSharp and asFlat', () {
    Pitch p;

    p = Pitch.get(PitchEnum.E2);
    expect(p.asSharp(), p);
    expect(p.asFlat(), p);

    p = Pitch.get(PitchEnum.Eb2);
    expect(p.asSharp(), Pitch.get(PitchEnum.Ds2));
    expect(p.asFlat(), p);

    p = Pitch.get(PitchEnum.Cs2);
    expect(p.asSharp(), p);
    expect(p.asFlat(), Pitch.get(PitchEnum.Db2));

    p = Pitch.get(PitchEnum.Es2);
    expect(p.asSharp(), p);
    expect(p.asFlat(), Pitch.get(PitchEnum.F2));

    p = Pitch.get(PitchEnum.Gs2);
    expect(p.asSharp(), p);
    expect(p.asFlat(), Pitch.get(PitchEnum.Ab2));

    p = Pitch.get(PitchEnum.Bs2);
    expect(p.asSharp(), p);
    expect(p.asFlat(), Pitch.get(PitchEnum.C3));
  });

  test('test getFromMidiNoteNumber()', () {
    var a0 = Pitch.get(PitchEnum.A0);
    var c8 = Pitch.get(PitchEnum.C8);
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
}
/*
A0   0 27.5
As0  1 29.13523509488062
Bb0  1 29.13523509488062
B0   2 30.86770632850775
Bs0  3 32.70319566257483
Cb1  2 30.86770632850775
C1   3 32.70319566257483
Cs1  4 34.64782887210901
Db1  4 34.64782887210901
D1   5 36.70809598967594
Ds1  6 38.890872965260115
Eb1  6 38.890872965260115
E1   7 41.20344461410875          //    bass low E
Es1  8 43.653528929125486
Fb1  7 41.20344461410875
F1   8 43.653528929125486
Fs1  9 46.2493028389543
Gb1  9 46.2493028389543
G1  10 48.999429497718666
Gs1 11 51.91308719749314
Ab1 11 51.91308719749314
A1  12 55.0                       //    bass open A
As1 13 58.27047018976124
Bb1 13 58.27047018976124
B1  14 61.7354126570155
Bs1 15 65.40639132514966
Cb2 14 61.7354126570155
C2  15 65.40639132514966
Cs2 16 69.29565774421802
Db2 16 69.29565774421802
D2  17 73.41619197935188          //    bass open D
Ds2 18 77.78174593052023
Eb2 18 77.78174593052023
E2  19 82.4068892282175
Es2 20 87.30705785825097
Fb2 19 82.4068892282175
F2  20 87.30705785825097
Fs2 21 92.4986056779086
Gb2 21 92.4986056779086
G2  22 97.99885899543733           //   bass open G
Gs2 23 103.82617439498628
Ab2 23 103.82617439498628
A2  24 110.0
As2 25 116.54094037952248
Bb2 25 116.54094037952248
B2  26 123.47082531403103
Bs2 27 130.8127826502993
Cb3 26 123.47082531403103
C3  27 130.8127826502993
Cs3 28 138.59131548843604
Db3 28 138.59131548843604
D3  29 146.8323839587038
Ds3 30 155.56349186104046
Eb3 30 155.56349186104046
E3  31 164.81377845643496
Es3 32 174.61411571650194
Fb3 31 164.81377845643496
F3  32 174.61411571650194
Fs3 33 184.9972113558172
Gb3 33 184.9972113558172
G3  34 195.99771799087463
Gs3 35 207.65234878997256
Ab3 35 207.65234878997256
A3  36 220.0
As3 37 233.08188075904496
Bb3 37 233.08188075904496
B3  38 246.94165062806206
Bs3 39 261.6255653005986
Cb4 38 246.94165062806206
C4  39 261.6255653005986
Cs4 40 277.1826309768721
Db4 40 277.1826309768721
D4  41 293.6647679174076
Ds4 42 311.1269837220809
Eb4 42 311.1269837220809
E4  43 329.6275569128699
Es4 44 349.2282314330039
Fb4 43 329.6275569128699
F4  44 349.2282314330039
Fs4 45 369.9944227116344
Gb4 45 369.9944227116344
G4  46 391.99543598174927
Gs4 47 415.3046975799451
Ab4 47 415.3046975799451
A4  48 440.0
As4 49 466.1637615180899
Bb4 49 466.1637615180899
B4  50 493.8833012561241
Bs4 51 523.2511306011972
Cb5 50 493.8833012561241
C5  51 523.2511306011972
Cs5 52 554.3652619537442
Db5 52 554.3652619537442
D5  53 587.3295358348151
Ds5 54 622.2539674441618
Eb5 54 622.2539674441618
E5  55 659.2551138257398
Es5 56 698.4564628660078
Fb5 55 659.2551138257398
F5  56 698.4564628660078
Fs5 57 739.9888454232688
Gb5 57 739.9888454232688
G5  58 783.9908719634985
Gs5 59 830.6093951598903
Ab5 59 830.6093951598903
A5  60 880.0
As5 61 932.3275230361799
Bb5 61 932.3275230361799
B5  62 987.7666025122483
Bs5 63 1046.5022612023945
Cb6 62 987.7666025122483
C6  63 1046.5022612023945
Cs6 64 1108.7305239074883
Db6 64 1108.7305239074883
D6  65 1174.6590716696303
Ds6 66 1244.5079348883237
Eb6 66 1244.5079348883237
E6  67 1318.5102276514797
Es6 68 1396.9129257320155
Fb6 67 1318.5102276514797
F6  68 1396.9129257320155
Fs6 69 1479.9776908465376
Gb6 69 1479.9776908465376
G6  70 1567.981743926997
Gs6 71 1661.2187903197805
Ab6 71 1661.2187903197805
A6  72 1760.0
As6 73 1864.6550460723597
Bb6 73 1864.6550460723597
B6  74 1975.533205024496
Bs6 75 2093.004522404789
Cb7 74 1975.533205024496
C7  75 2093.004522404789
Cs7 76 2217.4610478149766
Db7 76 2217.4610478149766
D7  77 2349.31814333926
Ds7 78 2489.0158697766474
Eb7 78 2489.0158697766474
E7  79 2637.02045530296
Es7 80 2793.825851464031
Fb7 79 2637.02045530296
F7  80 2793.825851464031
Fs7 81 2959.955381693075
Gb7 81 2959.955381693075
G7  82 3135.9634878539946
Gs7 83 3322.437580639561
Ab7 83 3322.437580639561
A7  84 3520.0
As7 85 3729.3100921447194
Bb7 85 3729.3100921447194
B7  86 3951.066410048992
Bs7 87 4186.009044809578
Cb8 86 3951.066410048992
C8  87 4186.009044809578


 */
