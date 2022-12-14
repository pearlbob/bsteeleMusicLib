import 'package:bsteeleMusicLib/app_logger.dart';
import 'package:bsteeleMusicLib/songs/drum_measure.dart';
import 'package:bsteeleMusicLib/songs/key.dart';
import 'package:bsteeleMusicLib/songs/song.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

const debugLog = Level.info;

void main() {
  Logger.level = Level.info;

  test('test DrumPart', () {
    for (var drumType in DrumTypeEnum.values) {
      for (var beats = 2; beats <= 6; beats += 2) {
        {
          assert(beats <= DrumBeat.values.length);
          DrumPart dp = DrumPart(drumType, beats: beats);

          int beatCount = 0;
          expect(dp.beatCount, beatCount);

          for (var i = 0; i < beats; i++) {
            var beat = DrumBeat.values[i];
            for (var subBeat in DrumSubBeatEnum.values) {
              dp.addBeat(beat, subBeat: subBeat);
              beatCount++;
              logger.log(debugLog, 'dp: $dp');
              expect(dp.beatCount, beatCount);
            }
          }
          beatCount = beats * drumSubBeatsPerBeat;
          expect(dp.beatCount, beatCount);

          for (var beat in DrumBeat.values) {
            for (var subBeat in DrumSubBeatEnum.values) {
              dp.removeBeat(beat, subBeat: subBeat);
              logger.log(debugLog, 'dp: $dp');
              if (beatCount > 0) {
                beatCount--;
              }
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
          expect(dp.timings(t0, bpm, beats), expectedTimings);

          for (var i = 0; i < beats; i++) {
            var beat = DrumBeat.values[i];
            for (var subBeat in DrumSubBeatEnum.values) {
              dp.addBeat(beat, subBeat: subBeat);
              beatCount++;
              logger.log(debugLog, 'dp.timings: ${dp.timings(t0, bpm, beats)}');
              expect(dp.beatCount, beatCount);

              expectedTimings
                  .add(t0 + (beat.index * drumSubBeatsPerBeat + subBeat.index) * 60.0 / (bpm * drumSubBeatsPerBeat));
              expect(dp.timings(t0, bpm, beats), expectedTimings);
            }
          }

          beatCount = beats * drumSubBeatsPerBeat;
          expect(dp.beatCount, beatCount);
          expect(dp.timings(t0, bpm, beats), expectedTimings);

          for (var i = 0; i < beats; i++) {
            var beat = DrumBeat.values[i];
            for (var subBeat in DrumSubBeatEnum.values) {
              dp.removeBeat(beat, subBeat: subBeat);
              logger.log(debugLog, 'dp.timings: ${dp.timings(t0, bpm, beats)}');
              if (beatCount > 0) {
                beatCount--;
              }
              expect(dp.beatCount, beatCount);
              expectedTimings.removeAt(0);
              expect(dp.timings(t0, bpm, beats), expectedTimings);
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
        dp3.addBeat(DrumBeat.beat2, subBeat: DrumSubBeatEnum.subBeatE);
        expect(dp1.compareTo(dp3), 1);
        expect(dp3.compareTo(dp1), -1);
        dp1.addBeat(DrumBeat.beat2, subBeat: DrumSubBeatEnum.subBeatE);
        expect(dp1.compareTo(dp3), 0);
        dp1.removeBeat(DrumBeat.beat2, subBeat: DrumSubBeatEnum.subBeatE);
        dp1.addBeat(DrumBeat.beat2, subBeat: DrumSubBeatEnum.subBeat);
        expect(dp1.compareTo(dp3), -1);
        dp1.addBeat(DrumBeat.beat2, subBeat: DrumSubBeatEnum.subBeatE);
        expect(dp1.compareTo(dp3), -1);
        expect(dp3.compareTo(dp1), 1);

        //  see 1 stay first when 1 is emptied
        dp3.addBeat(DrumBeat.beat3, subBeat: DrumSubBeatEnum.subBeat);
        expect(dp1.compareTo(dp3), -1);
        dp1.removeBeat(DrumBeat.beat2, subBeat: DrumSubBeatEnum.subBeatE);
        expect(dp1.compareTo(dp3), -1);
        dp1.removeBeat(DrumBeat.beat2, subBeat: DrumSubBeatEnum.subBeat);
        expect(dp1.compareTo(dp3), 1);

        //  see 3 go first if 1 is filled with a late beat
        dp1.addBeat(DrumBeat.beat4, subBeat: DrumSubBeatEnum.subBeat);
        logger.log(debugLog, 'dp1: $dp1, dp3: $dp3');
        expect(dp1.compareTo(dp3), 1);
      }

      for (var beats = 4; beats <= 6; beats += 2) {
        DrumPart dp1;
        dp1 = DrumPart(DrumTypeEnum.kick, beats: beats);
        expect(dp1.isEmpty, true);
        dp1 = DrumPart(DrumTypeEnum.kick, beats: beats);
        expect(dp1.isEmpty, true);
        dp1.addBeat(DrumBeat.beat2);
        dp1.addBeat(DrumBeat.beat4);
        expect(dp1.isEmpty, false);
        var dp2 = DrumPart(DrumTypeEnum.kick, beats: beats)
          ..addBeat(DrumBeat.beat2)
          ..addBeat(DrumBeat.beat4);
        expect(dp1.compareTo(dp2), 0);
        dp2.removeBeat(DrumBeat.beat4);
        dp2.addBeat(DrumBeat.beat4, subBeat: DrumSubBeatEnum.subBeatAnd);
        expect(dp1.compareTo(dp2), -1);
        dp2.removeBeat(DrumBeat.beat4, subBeat: DrumSubBeatEnum.subBeatAnd);
        dp2.addBeat(DrumBeat.beat3, subBeat: DrumSubBeatEnum.subBeatAndA);
        expect(dp1.compareTo(dp2), 1);
        logger.log(debugLog, 'dp1: $dp1, dp2: $dp2');
      }

      //  drum part offsets
      for (var drumType in DrumTypeEnum.values) {
        for (var beats = 2; beats <= 6; beats += 2) {
          {
            DrumPart dp = DrumPart(drumType, beats: beats);

            for (var i = 0; i < beats; i++) {
              dp.addBeat(DrumBeat.values[i]);
            }
            logger.log(debugLog, 'drumPart: $dp');
            expect(dp.beatCount, beats);

            int pass = 1;
            for (var subBeat in DrumSubBeatEnum.values) {
              for (var i = 0; i < beats; i++) {
                dp.addBeat(DrumBeat.values[i], subBeat: subBeat);
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
      drumPart.setBeatSelection(DrumBeat.beat1, DrumSubBeatEnum.subBeat, true);
      expect(drumPart.isEmpty, false);
      drumPart.setBeatSelection(DrumBeat.beat1, DrumSubBeatEnum.subBeatAndA, true);
      expect(drumPart.isEmpty, false);
      drumPart.setBeatSelection(DrumBeat.beat1, DrumSubBeatEnum.subBeat, false);
      expect(drumPart.isEmpty, false);
      drumPart.setBeatSelection(DrumBeat.beat1, DrumSubBeatEnum.subBeatAndA, false);
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
      const int bpm = 120;
      const int beats = 4;
      double t0 = 0;

      expect(dm.isSilent(), true);
      var closedHighHat = DrumPart(DrumTypeEnum.closedHighHat, beats: 4)
        ..addBeat(DrumBeat.beat2)
        ..addBeat(DrumBeat.beat4);

      dm.addPart(closedHighHat);
      expect(dm.isSilent(), false);
      logger.log(debugLog, 'dm: $dm');
      expect(dm.length, 1);
      for (var part in dm.parts) {
        if (part.drumType == DrumTypeEnum.closedHighHat) {
          logger.log(debugLog, 'timings: ${part.timings(t0, bpm, beats)}');
          expect(part.timings(t0, bpm, beats), [0.5, 1.5]);
        }
      }

      closedHighHat.addBeat(DrumBeat.beat1, subBeat: DrumSubBeatEnum.subBeatAnd);
      expect(closedHighHat.timings(t0, bpm, beats), [0.25, 0.5, 1.5]);
      closedHighHat.addBeat(DrumBeat.beat4, subBeat: DrumSubBeatEnum.subBeatAndA);
      expect(closedHighHat.timings(t0, bpm, beats), [0.25, 0.5, 1.5, 1.875]);
      closedHighHat.addBeat(DrumBeat.beat1, subBeat: DrumSubBeatEnum.subBeatE);
      expect(closedHighHat.timings(t0, bpm, beats), [0.125, 0.25, 0.5, 1.5, 1.875]);
      closedHighHat.addBeat(DrumBeat.beat1, subBeat: DrumSubBeatEnum.subBeat);
      expect(closedHighHat.timings(t0, bpm, beats), [0.0, 0.125, 0.25, 0.5, 1.5, 1.875]);
      closedHighHat.addBeat(DrumBeat.beat4, subBeat: DrumSubBeatEnum.subBeatAndA);
      expect(closedHighHat.timings(t0, bpm, beats), [0.0, 0.125, 0.25, 0.5, 1.5, 1.875]);
      closedHighHat.removeBeat(DrumBeat.beat4, subBeat: DrumSubBeatEnum.subBeatAndA);
      expect(closedHighHat.timings(t0, bpm, beats), [0.0, 0.125, 0.25, 0.5, 1.5]);
      closedHighHat.removeBeat(DrumBeat.beat3, subBeat: DrumSubBeatEnum.subBeatAnd);
      expect(closedHighHat.timings(t0, bpm, beats), [0.0, 0.125, 0.25, 0.5, 1.5]);
      closedHighHat.removeBeat(DrumBeat.beat1, subBeat: DrumSubBeatEnum.subBeatE);
      expect(closedHighHat.timings(t0, bpm, beats), [0.0, 0.25, 0.5, 1.5]);
    }
  });

  test('drumParts to/from JSON', () {
    {
      DrumParts drumParts = DrumParts();

      logger.i(drumParts.toJson());

      DrumTypeEnum drumType = DrumTypeEnum.closedHighHat;
      drumParts.name = 'bob stuff';

      DrumPart dp = drumParts.at(drumType);
      for (var beat in DrumBeat.values) {
        if (beat.index & 1 == 0) {
          continue;
        }
        dp.addBeat(beat);
      }
      drumParts.at(DrumTypeEnum.kick).setBeatSelection(DrumBeat.beat2, DrumSubBeatEnum.subBeat, true);
      //  logger.i(drumParts.toString());
      expect(drumParts == drumParts, true);

      var drumPart = drumParts.parts.first;
      // logger.i(drumPart.toString());
      logger.i(drumPart.toJson());
      var drumPartFromJson = DrumPart.fromJson(drumPart.toJson());
      logger.i(drumPartFromJson?.toJson());
      expect(drumPart == drumPartFromJson, isTrue);

      drumParts.at(DrumTypeEnum.closedHighHat).setBeatSelection(DrumBeat.beat2, DrumSubBeatEnum.subBeat, true);
      drumParts.at(DrumTypeEnum.closedHighHat).setBeatSelection(DrumBeat.beat2, DrumSubBeatEnum.subBeatE, true);
      drumParts.at(DrumTypeEnum.closedHighHat).setBeatSelection(DrumBeat.beat2, DrumSubBeatEnum.subBeatAnd, true);
      drumParts.at(DrumTypeEnum.closedHighHat).setBeatSelection(DrumBeat.beat2, DrumSubBeatEnum.subBeatAndA, true);

      var drumPartsFromJson = DrumParts.fromJson(drumParts.toJson());
      logger.i(drumParts.toJson());
      logger.i(drumPartsFromJson?.toJson());
      expect(drumParts == drumPartsFromJson, isTrue);
      drumParts.at(DrumTypeEnum.closedHighHat).setBeatSelection(DrumBeat.beat2, DrumSubBeatEnum.subBeatAndA, false);
      expect(drumParts == drumPartsFromJson, isFalse);
    }
    {
      //  cumulative entries
      for (var beats = 2; beats <= 6; beats += 2) {
        DrumParts drumParts = DrumParts();
        drumParts.name = 'bob stuff for $beats beats';
        logger.i('beats: $beats');
        for (var beat in DrumBeat.values) {
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
    for (var beat in DrumBeat.values) {
      if (beat.index & 1 == 0) {
        continue;
      }
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
        for (var beat in DrumBeat.values) {
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
    drumPartsList.clear();
    drumPartsList.add(DrumParts(name: DrumPartsList.defaultName, beats: 6, parts: [
      DrumPart(DrumTypeEnum.closedHighHat, beats: 6)
        ..addBeat(DrumBeat.beat1)
        ..addBeat(DrumBeat.beat3)
        ..addBeat(DrumBeat.beat5),
      DrumPart(DrumTypeEnum.snare, beats: 6)
        ..addBeat(DrumBeat.beat2)
        ..addBeat(DrumBeat.beat4)
        ..addBeat(DrumBeat.beat6),
    ]));
    logger.i(drumPartsList.toJson());
    expect(drumPartsList.length, 1); //  built in default!
    expect(drumPartsList.toJson(), '''{ "drumPartsList" : [{
 "name": "Default", "beats": 6, "subBeats": 4, "volume": 1.0,
 "parts": [{ "drumType": "closedHighHat", "beats": 6, "selection": [ 0, 8, 16 ]},
   { "drumType": "snare", "beats": 6, "selection": [ 4, 12, 20 ]}]
}],"matchesList" : {} }''');
    DrumParts drumParts = DrumParts(name: 'bob stuff', beats: 4);

    int beats = 4;
    var test1 = DrumParts(
        name: 'test1',
        beats: beats,
        parts: [DrumPart(DrumTypeEnum.closedHighHat, beats: beats)..addBeat(DrumBeat.beat1)]);
    expect(drumParts.compareTo(test1), -1);

    drumPartsList.add(drumParts);

    logger.i(drumPartsList.toJson());
    expect(drumPartsList.toJson(), '''{ "drumPartsList" : [{
 "name": "Default", "beats": 6, "subBeats": 4, "volume": 1.0,
 "parts": [{ "drumType": "closedHighHat", "beats": 6, "selection": [ 0, 8, 16 ]},
   { "drumType": "snare", "beats": 6, "selection": [ 4, 12, 20 ]}]
},
{
 "name": "bob stuff", "beats": 4, "subBeats": 4, "volume": 1.0,
 "parts": []
}],"matchesList" : {} }''');

    drumPartsList.add(drumParts);
    //  no change
    expect(drumPartsList.toJson(), '''{ "drumPartsList" : [{
 "name": "Default", "beats": 6, "subBeats": 4, "volume": 1.0,
 "parts": [{ "drumType": "closedHighHat", "beats": 6, "selection": [ 0, 8, 16 ]},
   { "drumType": "snare", "beats": 6, "selection": [ 4, 12, 20 ]}]
},
{
 "name": "bob stuff", "beats": 4, "subBeats": 4, "volume": 1.0,
 "parts": []
}],"matchesList" : {} }''');
    expect(drumPartsList.length, 2); //  includes the default
    logger.i(drumPartsList.toJson());

    logger.i('bob stuff: $drumPartsList');

    drumPartsList.add(test1);
    expect(drumPartsList.length, 3);
    drumPartsList.add(test1);
    expect(drumPartsList.length, 3);

    var test2 = DrumParts(
        name: 'test2', beats: beats, parts: [DrumPart(DrumTypeEnum.bass, beats: beats)..addBeat(DrumBeat.beat2)]);
    drumPartsList.add(test2);

    var test3 = test1.copyWith();
    test3.at(DrumTypeEnum.closedHighHat).addBeat(DrumBeat.beat3);
    logger.i('$test3');
    drumPartsList.add(test3);
    logger.i('bob+test1+test3: $drumPartsList');
    expect(drumPartsList.length, 4);
    drumPartsList.add(test3);
    expect(drumPartsList.length, 4);
    drumPartsList.add(test2);
    expect(drumPartsList.length, 4);

    var original = drumPartsList.toJson();
    drumPartsList.fromJson(drumPartsList.toJson());
    logger.i(drumParts.toString());
    expect(drumPartsList.toJson(), original);

    DrumTypeEnum drumType = DrumTypeEnum.closedHighHat;

    DrumPart dp = drumParts.at(drumType);
    for (var beat in DrumBeat.values) {
      if (beat.index & 1 == 0) {
        continue;
      }
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
        for (var beat in DrumBeat.values) {
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

  test('drumParts DrumPartsList default song matches', () {
    DrumPartsList drumPartsList = DrumPartsList();
    drumPartsList.addDefaults();

    Song a4 = Song.createSong('a song', 'bob', 'bob', Key.C, 104, 4, 4, 'pearl bob', 'v: A A A A',
        'v: Ain\'t you going to play something else?');
    Song b2 = Song.createSong('b song', 'bob', 'bob', Key.C, 104, 2, 4, 'pearl bob', 'v: B B B Bb', 'v: Be flat.');
    Song c6 =
        Song.createSong('c never sung song', 'bob', 'bob', Key.G, 104, 6, 8, 'pearl bob', 'v: G D C G', 'v: Gee baby');
    Song d3 = Song.createSong('D3', 'bob', 'bob', Key.G, 104, 3, 4, 'pearl bob', 'v: G D C G', 'v: Gee baby');
    expect(drumPartsList[a4]?.name, 'Default4');
    expect(drumPartsList[b2]?.name, 'Default2');
    expect(drumPartsList[c6]?.name, 'Default6');
    expect(drumPartsList[d3]?.name, 'Default3');
  });

  test('drumParts DrumPartsList song matches', () {
    DrumPartsList drumPartsList = DrumPartsList();
    drumPartsList.clear();

    Song a = Song.createSong('a song', 'bob', 'bob', Key.C, 104, 4, 4, 'pearl bob', 'v: A A A A',
        'v: Ain\'t you going to play something else?');
    Song b = Song.createSong('b song', 'bob', 'bob', Key.C, 104, 4, 4, 'pearl bob', 'v: B B B Bb', 'v: Be flat.');
    Song c =
        Song.createSong('c never sung song', 'bob', 'bob', Key.G, 104, 4, 4, 'pearl bob', 'v: G D C G', 'v: Gee baby');
    expect(drumPartsList[a], null);
    expect(drumPartsList[b], null);
    expect(drumPartsList[c], null);

    int beats = 4;
    var simplisticDrumParts = DrumParts(name: 'simplistic', beats: beats, parts: [
      DrumPart(DrumTypeEnum.closedHighHat, beats: beats)
        ..addBeat(DrumBeat.beat1)
        ..addBeat(DrumBeat.beat3),
      DrumPart(DrumTypeEnum.snare, beats: beats)
        ..addBeat(DrumBeat.beat2)
        ..addBeat(DrumBeat.beat4)
    ]);
    var rockDrumParts = DrumParts(name: 'rock', beats: beats, parts: [
      DrumPart(DrumTypeEnum.closedHighHat, beats: beats)
        ..addBeat(DrumBeat.beat1)
        ..addBeat(DrumBeat.beat2)
        ..addBeat(DrumBeat.beat3)
        ..addBeat(DrumBeat.beat4),
      DrumPart(DrumTypeEnum.snare, beats: beats)
        ..addBeat(DrumBeat.beat1)
        ..addBeat(DrumBeat.beat2)
        ..addBeat(DrumBeat.beat3)
        ..addBeat(DrumBeat.beat4),
    ]);
    drumPartsList.add(simplisticDrumParts);
    drumPartsList.add(rockDrumParts);
    drumPartsList.match(a, simplisticDrumParts);

    logger.i('drumPartsList["${a.title}"]: ${drumPartsList[a]}');
    expect(drumPartsList[a], simplisticDrumParts);
    expect(drumPartsList[b], null);
    expect(drumPartsList[c], null);

    drumPartsList.match(b, simplisticDrumParts);
    expect(drumPartsList[a], simplisticDrumParts);
    expect(drumPartsList[b], simplisticDrumParts);
    expect(drumPartsList[c], null);

    drumPartsList.match(b, rockDrumParts);
    expect(drumPartsList[a], simplisticDrumParts);
    expect(drumPartsList[b], rockDrumParts);
    expect(drumPartsList[c], null);

    drumPartsList.removeMatch(b);
    expect(drumPartsList[a], simplisticDrumParts);
    expect(drumPartsList[b], null);
    expect(drumPartsList[c], null);

    drumPartsList.match(b, rockDrumParts);
    expect(drumPartsList[a], simplisticDrumParts);
    expect(drumPartsList[b], rockDrumParts);
    expect(drumPartsList[c], null);

    logger.i(drumPartsList.toJson());
    var drumPartsListToJson = drumPartsList.toJson();
    expect(drumPartsListToJson, '''{ "drumPartsList" : [{
 "name": "rock", "beats": 4, "subBeats": 4, "volume": 1.0,
 "parts": [{ "drumType": "closedHighHat", "beats": 4, "selection": [ 0, 4, 8, 12 ]},
   { "drumType": "snare", "beats": 4, "selection": [ 0, 4, 8, 12 ]}]
},
{
 "name": "simplistic", "beats": 4, "subBeats": 4, "volume": 1.0,
 "parts": [{ "drumType": "closedHighHat", "beats": 4, "selection": [ 0, 8 ]},
   { "drumType": "snare", "beats": 4, "selection": [ 4, 12 ]}]
}],"matchesList" : { "Song_a_song_by_bob": "simplistic",
 "Song_b_song_by_bob": "rock"} }''');

    drumPartsList.clear();
    expect(drumPartsList[a], null);
    expect(drumPartsList[b], null);
    expect(drumPartsList[c], null);

    drumPartsList.fromJson(drumPartsListToJson);
    expect(drumPartsList[a], simplisticDrumParts);
    expect(drumPartsList[b], rockDrumParts);
    expect(drumPartsList[c], null);
  });

  test('drumParts is dirty', () {
    int beats = 4;
    var closed = DrumPart(DrumTypeEnum.closedHighHat, beats: beats)
      ..addBeat(DrumBeat.beat1)
      ..addBeat(DrumBeat.beat3);
    var parts = DrumParts(name: 'simplistic', beats: beats, parts: [
      closed,
      DrumPart(DrumTypeEnum.snare, beats: beats)
        ..addBeat(DrumBeat.beat2)
        ..addBeat(DrumBeat.beat4)
    ]);

    //  add an existing part means no change
    expect(parts.hasChanged, false);
    parts.addPart(closed);
    expect(parts.hasChanged, false);

    //  change a part
    var part = closed.copyWith();
    part.addBeat(DrumBeat.beat2);
    parts.addPart(part);
    expect(parts.hasChanged, true);
    parts.hasChanged = false;
    expect(parts.hasChanged, false);

    //  put the original part back:
    parts.addPart(closed);
    expect(parts.hasChanged, true);
    parts.hasChanged = false;
    expect(parts.hasChanged, false);

    //  changing beats makes the parts dirty
    parts.beats = 6;
    expect(parts.hasChanged, true);
    parts.hasChanged = false;

    //  remove
    parts.removePart(closed);
    expect(parts.hasChanged, true);
    parts.hasChanged = false;

    //  add empty part
    var open = DrumPart(DrumTypeEnum.openHighHat, beats: beats);
    parts.addPart(open);
    expect(parts.hasChanged, true);
    parts.hasChanged = false;

    //  remove empty part
    parts.removePart(open);
    expect(parts.hasChanged, true);
    parts.hasChanged = false;
  });

  test('drumParts an empty part should match a null part', () {
    int beats = 4;
    var emptyParts = DrumParts(name: 'simplistic', beats: beats, parts: [
      DrumPart(DrumTypeEnum.closedHighHat, beats: beats),
      DrumPart(DrumTypeEnum.snare, beats: beats),
    ]);
    var nullParts = DrumParts(
      name: 'simplistic',
      beats: beats,
    );

    expect(emptyParts, nullParts);
    expect(emptyParts.compareTo(nullParts), 0);
  });
}
