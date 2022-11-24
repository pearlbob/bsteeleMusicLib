import 'package:bsteeleMusicLib/app_logger.dart';
import 'package:bsteeleMusicLib/songs/drum_measure.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

const debugLog = Level.info;

void main() {
  Logger.level = Level.info;

  test('test DrumPart', () {
    for (var drumType in DrumTypeEnum.values) {
      for (var beats = 2; beats <= 6; beats += 2) {
        {
          DrumPart dp = DrumPart(drumType, beats: beats);

          int beatCount = 0;
          expect(dp.beatCount, beatCount);

          for (var beat = 0; beat < beats; beat++) {
            for (var subBeat in DrumSubBeatEnum.values) {
              dp.addBeat(beat, subBeat: subBeat);
              beatCount++;
              logger.log(debugLog, 'dp: $dp');
              expect(dp.beatCount, beatCount);
            }
          }
          beatCount = beats * drumSubBeatsPerBeat;
          expect(dp.beatCount, beatCount);

          for (var beat = 0; beat < beats; beat++) {
            for (var subBeat in DrumSubBeatEnum.values) {
              dp.removeBeat(beat, subBeat: subBeat);
              logger.log(debugLog, 'dp: $dp');
              beatCount--;
              expect(dp.beatCount, beatCount);
            }
          }
        }

        {
          DrumPart dp = DrumPart(drumType, beats: beats);
          double t0 = 10.0;
          int bpm = 120;
          int beatCount = 0;
          List<double> expectedTimings = [];
          expect(dp.beatCount, beatCount);
          expect(dp.timings(t0, bpm), expectedTimings);

          for (var beat = 0; beat < beats; beat++) {
            for (var subBeat in DrumSubBeatEnum.values) {
              dp.addBeat(beat, subBeat: subBeat);
              beatCount++;
              logger.log(debugLog, 'dp.timings: ${dp.timings(t0, bpm)}');
              expect(dp.beatCount, beatCount);

              expectedTimings
                  .add(t0 + (beat * drumSubBeatsPerBeat + subBeat.index) * 60.0 / (bpm * drumSubBeatsPerBeat));
              expect(dp.timings(t0, bpm), expectedTimings);
            }
          }

          beatCount = beats * drumSubBeatsPerBeat;
          expect(dp.beatCount, beatCount);
          expect(dp.timings(t0, bpm), expectedTimings);

          for (var beat = 0; beat < beats; beat++) {
            for (var subBeat in DrumSubBeatEnum.values) {
              dp.removeBeat(beat, subBeat: subBeat);
              logger.log(debugLog, 'dp.timings: ${dp.timings(t0, bpm)}');
              beatCount--;
              expect(dp.beatCount, beatCount);
              expectedTimings.removeAt(0);
              expect(dp.timings(t0, bpm), expectedTimings);
            }
          }
        }
      }

      {
        DrumPart dp1 = DrumPart(DrumTypeEnum.kick, beats: 4);
        DrumPart dp2 = DrumPart(DrumTypeEnum.closedHighHat, beats: 4);
        DrumPart dp3 = DrumPart(DrumTypeEnum.kick, beats: 4);
        expect(dp1.compareTo(dp2), -1);
        expect(dp1.compareTo(dp3), 0);
        expect(dp3.compareTo(dp1), 0);
        expect(dp2.compareTo(dp1), 1);
        dp3.addBeat(1, subBeat: DrumSubBeatEnum.subBeatE);
        expect(dp1.compareTo(dp3), 1);
        expect(dp3.compareTo(dp1), -1);
        dp1.addBeat(1, subBeat: DrumSubBeatEnum.subBeatE);
        expect(dp1.compareTo(dp3), 0);
        dp1.removeBeat(1, subBeat: DrumSubBeatEnum.subBeatE);
        dp1.addBeat(1, subBeat: DrumSubBeatEnum.subBeat);
        expect(dp1.compareTo(dp3), -1);
        dp1.addBeat(1, subBeat: DrumSubBeatEnum.subBeatE);
        expect(dp1.compareTo(dp3), -1);
        expect(dp3.compareTo(dp1), 1);

        //  see 1 stay first when 1 is emptied
        dp3.addBeat(2, subBeat: DrumSubBeatEnum.subBeat);
        expect(dp1.compareTo(dp3), -1);
        dp1.removeBeat(1, subBeat: DrumSubBeatEnum.subBeatE);
        expect(dp1.compareTo(dp3), -1);
        dp1.removeBeat(1, subBeat: DrumSubBeatEnum.subBeat);
        expect(dp1.compareTo(dp3), 1);

        //  see 3 go first if 1 is filled with a late beat
        dp1.addBeat(3, subBeat: DrumSubBeatEnum.subBeat);
        logger.log(debugLog, 'dp1: $dp1, dp3: $dp3');
        expect(dp1.compareTo(dp3), 1);
      }

      for (var beats = 4; beats <= 6; beats += 2) {
        DrumPart dp1;
        dp1 = DrumPart(DrumTypeEnum.kick, beats: beats);
        expect(dp1.isEmpty, true);
        dp1 = DrumPart(DrumTypeEnum.kick, beats: beats);
        expect(dp1.isEmpty, true);
        dp1.addBeat(1);
        dp1.addBeat(3);
        expect(dp1.isEmpty, false);
        var dp2 = DrumPart(DrumTypeEnum.kick, beats: beats)
          ..addBeat(1)
          ..addBeat(3);
        expect(dp1.compareTo(dp2), 0);
        dp2.removeBeat(3);
        dp2.addBeat(3, subBeat: DrumSubBeatEnum.subBeatAnd);
        expect(dp1.compareTo(dp2), -1);
        dp2.removeBeat(3, subBeat: DrumSubBeatEnum.subBeatAnd);
        dp2.addBeat(2, subBeat: DrumSubBeatEnum.subBeatAndA);
        expect(dp1.compareTo(dp2), 1);
        logger.log(debugLog, 'dp1: $dp1, dp2: $dp2');
      }

      //  drum part offsets
      for (var drumType in DrumTypeEnum.values) {
        for (var beats = 2; beats <= 6; beats += 2) {
          {
            DrumPart dp = DrumPart(drumType, beats: beats);

            for (var beat = 0; beat < beats; beat++) {
              dp.addBeat(beat);
            }
            logger.log(debugLog, 'drumPart: $dp');
            expect(dp.beatCount, beats);

            int pass = 1;
            for (var subBeat in DrumSubBeatEnum.values) {
              for (var beat = 0; beat < beats; beat++) {
                dp.addBeat(beat, subBeat: subBeat);
              }
              logger.log(debugLog, 'drumPart: $dp');
              expect(dp.beatCount, pass * beats);
              pass++;
            }
          }
        }
      }
    }
  });

  test('drumParts', () {
    {
      DrumParts drumParts = DrumParts();
      drumParts.name = 'bob stuff';

      expect(drumParts.isSilent(), true);
      expect(drumParts.length, 0);
      drumParts.addPart(DrumPart(DrumTypeEnum.closedHighHat, beats: 4));
      expect(drumParts.length, 1);
      expect(drumParts.isSilent(), true);
      logger.log(debugLog, 'dm: $drumParts');
      var drumPart = drumParts.at(DrumTypeEnum.closedHighHat);
      expect(drumPart, isNotNull);
      expect(drumPart.beats, 4);
      expect(drumPart.isEmpty, true);
      drumPart.setBeatSelection(0, DrumSubBeatEnum.subBeat, true);
      expect(drumPart.isEmpty, false);
      drumPart.setBeatSelection(0, DrumSubBeatEnum.subBeatAndA, true);
      expect(drumPart.isEmpty, false);
      drumPart.setBeatSelection(0, DrumSubBeatEnum.subBeat, false);
      expect(drumPart.isEmpty, false);
      drumPart.setBeatSelection(0, DrumSubBeatEnum.subBeatAndA, false);
      expect(drumPart.isEmpty, true);
    }
    {
      DrumParts dm = DrumParts();

      dm.volume = 0.0;
      expect(dm.volume, 0.0);
      dm.volume = 0.4;
      expect(dm.volume, 0.4);
      dm.volume = 1.0;
      expect(dm.volume, 1.0);
      try {
        dm.volume = -0.4;
        expect(true, false); //  expect assertion from above
      } catch (e) {
        if (e is TestFailure) rethrow;
      }
      try {
        dm.volume = 1.4;
        expect(true, false); //  expect assertion from above
      } catch (e) {
        if (e is TestFailure) rethrow;
      }
    }
    {
      DrumParts dm = DrumParts();
      int bpm = 120;
      double t0 = 0;

      expect(dm.isSilent(), true);
      var closedHighHat = DrumPart(DrumTypeEnum.closedHighHat, beats: 4)
        ..addBeat(1)
        ..addBeat(3);

      dm.addPart(closedHighHat);
      expect(dm.isSilent(), false);
      logger.log(debugLog, 'dm: $dm');
      expect(dm.length, 1);
      for (var part in dm.parts) {
        if (part.drumType == DrumTypeEnum.closedHighHat) {
          logger.log(debugLog, 'timings: ${part.timings(t0, bpm)}');
          expect(part.timings(t0, bpm), [0.5, 1.5]);
        }
      }

      closedHighHat.addBeat(0, subBeat: DrumSubBeatEnum.subBeatAnd);
      expect(closedHighHat.timings(t0, bpm), [0.25, 0.5, 1.5]);
      closedHighHat.addBeat(3, subBeat: DrumSubBeatEnum.subBeatAndA);
      expect(closedHighHat.timings(t0, bpm), [0.25, 0.5, 1.5, 1.875]);
      closedHighHat.addBeat(0, subBeat: DrumSubBeatEnum.subBeatE);
      expect(closedHighHat.timings(t0, bpm), [0.125, 0.25, 0.5, 1.5, 1.875]);
      closedHighHat.addBeat(0, subBeat: DrumSubBeatEnum.subBeat);
      expect(closedHighHat.timings(t0, bpm), [0.0, 0.125, 0.25, 0.5, 1.5, 1.875]);
      closedHighHat.addBeat(3, subBeat: DrumSubBeatEnum.subBeatAndA);
      expect(closedHighHat.timings(t0, bpm), [0.0, 0.125, 0.25, 0.5, 1.5, 1.875]);
      closedHighHat.removeBeat(3, subBeat: DrumSubBeatEnum.subBeatAndA);
      expect(closedHighHat.timings(t0, bpm), [0.0, 0.125, 0.25, 0.5, 1.5]);
      closedHighHat.removeBeat(2, subBeat: DrumSubBeatEnum.subBeatAnd);
      expect(closedHighHat.timings(t0, bpm), [0.0, 0.125, 0.25, 0.5, 1.5]);
      closedHighHat.removeBeat(0, subBeat: DrumSubBeatEnum.subBeatE);
      expect(closedHighHat.timings(t0, bpm), [0.0, 0.25, 0.5, 1.5]);
    }
  });

  test('drumParts to/from JSON', () {
    {
      DrumParts drumParts = DrumParts();

      logger.i(drumParts.toJson());

      DrumTypeEnum drumType = DrumTypeEnum.closedHighHat;
      int beats = 4;

      drumParts.name = 'bob stuff';

      DrumPart dp = drumParts.at(drumType);
      for (var beat = 1; beat < beats; beat += 2) {
        dp.addBeat(beat);
      }
      drumParts.at(DrumTypeEnum.kick).setBeatSelection(1, DrumSubBeatEnum.subBeat, true);
      //  logger.i(drumParts.toString());
      expect(drumParts == drumParts, true);

      var drumPart = drumParts.parts.first;
      // logger.i(drumPart.toString());
      logger.i(drumPart.toJson());
      var drumPartFromJson = DrumPart.fromJson(drumPart.toJson());
      logger.i(drumPartFromJson?.toJson());
      expect(drumPart == drumPartFromJson, isTrue);

      drumParts.at(DrumTypeEnum.closedHighHat).setBeatSelection(1, DrumSubBeatEnum.subBeat, true);
      drumParts.at(DrumTypeEnum.closedHighHat).setBeatSelection(1, DrumSubBeatEnum.subBeatE, true);
      drumParts.at(DrumTypeEnum.closedHighHat).setBeatSelection(1, DrumSubBeatEnum.subBeatAnd, true);
      drumParts.at(DrumTypeEnum.closedHighHat).setBeatSelection(1, DrumSubBeatEnum.subBeatAndA, true);

      var drumPartsFromJson = DrumParts.fromJson(drumParts.toJson());
      logger.i(drumParts.toJson());
      logger.i(drumPartsFromJson?.toJson());
      expect(drumParts == drumPartsFromJson, isTrue);
      drumParts.at(DrumTypeEnum.closedHighHat).setBeatSelection(1, DrumSubBeatEnum.subBeatAndA, false);
      expect(drumParts == drumPartsFromJson, isFalse);
    }
    {
      //  cumulative entries
      for (var beats = 2; beats <= 6; beats += 2) {
        DrumParts drumParts = DrumParts();
        drumParts.name = 'bob stuff for $beats beats';
        logger.i('beats: $beats');
        for (var beat = 0; beat < beats; beat++) {
          logger.i('  beat: $beat');
          for (var drumSubBeat in DrumSubBeatEnum.values) {
            logger.i('    drumSubBeat: $drumSubBeat');
            for (var drumType in DrumTypeEnum.values) {
              drumParts.beats = beats;
              var drumPart = drumParts.at(drumType);
              drumPart.addBeat(beat, subBeat: drumSubBeat);

              drumParts.addPart(drumPart);

              var drumPartsFromJson = DrumParts.fromJson(drumParts.toJson());
              logger.v(drumParts.toJson());
              logger.v(drumPartsFromJson?.toJson());
              expect(drumParts == drumPartsFromJson, isTrue);
            }
          }
        }
        logger.i(drumParts.toJson());
      }
    }
  });

  test('drumParts copyWith', () {
    DrumParts drumParts = DrumParts(name: 'bob stuff', beats: 4);

    logger.i(drumParts.toString());
    expect(drumParts.copyWith(), drumParts);

    DrumTypeEnum drumType = DrumTypeEnum.closedHighHat;

    DrumPart dp = drumParts.at(drumType);
    for (var beat = 1; beat < drumParts.beats; beat += 2) {
      dp.addBeat(beat, subBeat: DrumSubBeatEnum.subBeatAnd);
      logger.i(drumParts.toString());
      expect(drumParts.copyWith(), drumParts);
    }
    {
      //  cumulative entries
      for (var beats = 2; beats <= 6; beats += 2) {
        DrumParts drumParts = DrumParts();
        drumParts.name = 'bob stuff for $beats beats';
        logger.v('beats: $beats');
        for (var beat = 0; beat < beats; beat++) {
          logger.v('  beat: $beat');
          for (var drumSubBeat in DrumSubBeatEnum.values) {
            logger.v('    drumSubBeat: $drumSubBeat');
            for (var drumType in DrumTypeEnum.values) {
              drumParts.beats = beats;
              var drumPart = drumParts.at(drumType);
              drumPart.addBeat(beat, subBeat: drumSubBeat);

              drumParts.addPart(drumPart);

              logger.v(drumParts.toString());
              expect(drumParts.copyWith(), drumParts);
            }
          }
        }
      }
    }
  });

  test('drumParts DrumPartsList', () {
    DrumPartsList drumPartsList = DrumPartsList();
    logger.i(drumPartsList.toJson());
    expect(drumPartsList.length, 0);
    expect(drumPartsList.toJson(), '''{ "drumPartsList" : [] }''');
    DrumParts drumParts = DrumParts(name: 'bob stuff', beats: 4);

    int beats = 4;
    var test1 =
        DrumParts(name: 'test1', beats: beats, parts: [DrumPart(DrumTypeEnum.closedHighHat, beats: beats)..addBeat(0)]);
    expect(drumParts.compareTo(test1), -1);

    drumPartsList.add(drumParts);

    logger.i(drumPartsList.toJson());
    expect(drumPartsList.toJson(), '''{ "drumPartsList" : [{
 "name": "bob stuff", "beats": 4, "subBeats": 4, "volume": 1.0,
 "parts": []
}
] }''');

    drumPartsList.add(drumParts);
    //  no change
    expect(drumPartsList.toJson(), '''{ "drumPartsList" : [{
 "name": "bob stuff", "beats": 4, "subBeats": 4, "volume": 1.0,
 "parts": []
}
] }''');
    expect(drumPartsList.length, 1);
    logger.i(drumPartsList.toJson());

    logger.i('bob stuff: $drumPartsList');

    drumPartsList.add(test1);
    expect(drumPartsList.length, 2);
    drumPartsList.add(test1);
    expect(drumPartsList.length, 2);

    var test2 = DrumParts(name: 'test2', beats: beats, parts: [DrumPart(DrumTypeEnum.bass, beats: beats)..addBeat(1)]);
    drumPartsList.add(test2);

    var test3 = test1.copyWith();
    test3.at(DrumTypeEnum.closedHighHat).addBeat(2);
    logger.i('$test3');
    drumPartsList.add(test3);
    logger.i('bob+test1+test3: $drumPartsList');
    expect(drumPartsList.length, 3);
    drumPartsList.add(test3);
    expect(drumPartsList.length, 3);
    drumPartsList.add(test2);
    expect(drumPartsList.length, 3);

    var original = drumPartsList.toJson();
    drumPartsList.fromJson(drumPartsList.toJson());
    logger.i(drumParts.toString());
    expect(drumPartsList.toJson(), original);

    DrumTypeEnum drumType = DrumTypeEnum.closedHighHat;

    DrumPart dp = drumParts.at(drumType);
    for (var beat = 1; beat < drumParts.beats; beat += 2) {
      dp.addBeat(beat, subBeat: DrumSubBeatEnum.subBeatAnd);
      var original = drumPartsList.toJson();
      drumPartsList.fromJson(drumPartsList.toJson());
      logger.i(drumParts.toString());
      expect(drumPartsList.toJson(), original);
    }
    {
      //  cumulative entries
      for (var beats = 2; beats <= 6; beats += 2) {
        DrumParts drumParts = DrumParts();
        drumParts.name = 'bob stuff for $beats beats';
        logger.v('beats: $beats');
        for (var beat = 0; beat < beats; beat++) {
          logger.v('  beat: $beat');
          for (var drumSubBeat in DrumSubBeatEnum.values) {
            logger.v('    drumSubBeat: $drumSubBeat');
            for (var drumType in DrumTypeEnum.values) {
              drumParts.beats = beats;
              var drumPart = drumParts.at(drumType);
              drumPart.addBeat(beat, subBeat: drumSubBeat);

              drumParts.addPart(drumPart);

              var original = drumPartsList.toJson();
              drumPartsList.fromJson(drumPartsList.toJson());
              logger.i(drumParts.toString());
              expect(drumPartsList.toJson(), original);
            }
          }
        }
      }
    }
  });
}
