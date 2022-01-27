import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/drumMeasure.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('test DrumMeasurePart', () {
    int beatsPerMeasure = 4;

    {
      DrumMeasurePart dp = DrumMeasurePart(DrumType.closedHighHat);

      int beatDivisions = 0;
      expect(dp.beats.length, beatDivisions);
      beatDivisions++;
      for (var beat = 1; beat <= 4; beat++) {
        for (var division in DrumDivision.values) {
          dp.add(beat, division: division);
          logger.d('dp: $dp');
          expect(dp.beats.length, beatDivisions);
          beatDivisions++;
        }
      }
      beatDivisions = beatsPerMeasure * drumDivisionsPerBeat;
      expect(dp.beats.length, beatDivisions);

      for (var beat = 1; beat <= 4; beat++) {
        for (var division in DrumDivision.values) {
          dp.remove(beat, division: division);
          logger.d('dp: $dp');
          beatDivisions--;
          expect(dp.beats.length, beatDivisions);
        }
      }
    }

    {
      DrumMeasurePart dp = DrumMeasurePart(DrumType.bass);
      var limit = beatsPerMeasure * DrumDivision.values.length;
      int beatDivisions = 0;
      expect(dp.beats.length, beatDivisions);
      beatDivisions++;
      for (var offset = 0; offset < limit; offset++) {
        dp.addAt(offset);
        logger.d('dp: $dp');
        expect(dp.beats.length, beatDivisions);
        beatDivisions++;
      }
      beatDivisions = beatsPerMeasure * drumDivisionsPerBeat;
      expect(dp.beats.length, beatDivisions);

      for (var offset = 0; offset < limit; offset++) {
        dp.removeAt(offset);
        logger.d('dp: $dp');
        beatDivisions--;
        expect(dp.beats.length, beatDivisions);
      }
    }
    {
      DrumMeasurePart dp = DrumMeasurePart(DrumType.kick);
      var limit = beatsPerMeasure * DrumDivision.values.length;
      double t0 = 3.14;
      int bpm = 120;
      int beatDivisions = 0;
      List<double> expectedTimings = [];
      expect(dp.beats.length, beatDivisions);
      expect(dp.timings(t0, bpm), expectedTimings);
      beatDivisions++;
      for (var offset = 0; offset <= limit; offset++) {
        dp.addAt(offset);
        logger.d('dp.timings: ${dp.timings(t0, bpm)}');
        expect(dp.beats.length, beatDivisions);
        beatDivisions++;
        expectedTimings.add(t0 + offset * 60.0 / (bpm * drumDivisionsPerBeat));
        expect(dp.timings(t0, bpm), expectedTimings);
      }
      beatDivisions = beatsPerMeasure * drumDivisionsPerBeat + 1;
      expect(dp.beats.length, beatDivisions);
      expect(dp.timings(t0, bpm), expectedTimings);

      for (var offset = 0; offset <= limit; offset++) {
        dp.removeAt(offset);
        logger.d('dp.timings: ${dp.timings(t0, bpm)}');
        beatDivisions--;
        expect(dp.beats.length, beatDivisions);
        expectedTimings.removeAt(0);
        expect(dp.timings(t0, bpm), expectedTimings);
      }
    }

    {
      DrumMeasurePart dp1 = DrumMeasurePart(DrumType.kick);
      DrumMeasurePart dp2 = DrumMeasurePart(DrumType.closedHighHat);
      DrumMeasurePart dp3 = DrumMeasurePart(DrumType.kick);
      expect(dp1.compareTo(dp2), -1);
      expect(dp1.compareTo(dp3), 0);
      expect(dp3.compareTo(dp1), 0);
      expect(dp2.compareTo(dp1), 1);
      dp3.add(1, division: DrumDivision.beatE);
      expect(dp1.compareTo(dp3), -1);
      expect(dp3.compareTo(dp1), 1);
      dp1.add(1, division: DrumDivision.beatE);
      expect(dp1.compareTo(dp3), 0);
      dp1.remove(1, division: DrumDivision.beatE);
      dp1.add(1, division: DrumDivision.beat);
      expect(dp1.compareTo(dp3), -1);
      dp1.add(1, division: DrumDivision.beatE);
      expect(dp1.compareTo(dp3), -1);
      expect(dp3.compareTo(dp1), 1);

      //  see 1 stay first when 1 is emptied
      dp3.add(2, division: DrumDivision.beat);
      expect(dp1.compareTo(dp3), -1);
      dp1.remove(1, division: DrumDivision.beatE);
      expect(dp1.compareTo(dp3), -1);
      dp1.remove(1, division: DrumDivision.beat);
      expect(dp1.compareTo(dp3), -1);

      //  see 3 go first if 1 is filled with a late beat
      dp1.add(4, division: DrumDivision.beat);
      logger.i('dp1: $dp1, dp3: $dp3');
      expect(dp1.compareTo(dp3), 1);
    }
    {
      DrumMeasurePart dp1;
      dp1 = DrumMeasurePart(DrumType.kick);
      expect(dp1.isEmpty, true);
      dp1 = DrumMeasurePart(DrumType.kick, beats: []);
      expect(dp1.isEmpty, true);
      var beat4 = DrumBeat(4);
      var beats = [DrumBeat(2), beat4];
      dp1.addAll(beats);
      expect(dp1.isEmpty, false);
      var dp2 = DrumMeasurePart(DrumType.kick, beats: beats);
      expect(dp1.compareTo(dp2), 0);
      dp2.removeBeat(beat4);
      var beat4and = DrumBeat(4, division: DrumDivision.beatAnd);
      dp2.addBeat(beat4and);
      expect(dp1.compareTo(dp2), -1);
      dp2.remove(4, division: DrumDivision.beatAnd);
      dp2.add(3, division: DrumDivision.beatAndA);
      expect(dp1.compareTo(dp2), 1);
      logger.i('dp1: $dp1, dp2: $dp2');
    }
  });

  test('drumMeasure', () {
    // int beatsPerMeasure = 4;

    {
      DrumMeasure dm = DrumMeasure();

      expect(dm.isSilent(), true);
      dm.addPart(DrumMeasurePart(DrumType.closedHighHat));
      expect(dm.isSilent(), true);
      logger.i('dm: $dm');
    }
    {
      DrumMeasure dm = DrumMeasure();
      int bpm = 120;
      double t0 = 0;

      expect(dm.isSilent(), true);
      dm.addPart(DrumMeasurePart(DrumType.closedHighHat, beats: [DrumBeat(2), DrumBeat(4)]));
      expect(dm.isSilent(), false);
      logger.i('dm: $dm');
      expect(dm.parts.keys.length, 1);
      for (var type in dm.parts.keys) {
        var part = dm.parts[type]!;
        logger.i('timings: ${part.timings(t0, bpm)}');
        expect(part.timings(t0, bpm), [0.5, 1.5]);
      }
    }
  });
}
