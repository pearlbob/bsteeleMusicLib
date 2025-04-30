import 'dart:math';

import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/songs/key.dart';
import 'package:bsteele_music_lib/songs/song.dart';
import 'package:bsteele_music_lib/songs/song_update.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('song updates', () {
    {
      logger.d('getMomentNumber');
      SongUpdate instance = SongUpdate();
      int expResult = 0;
      int result = instance.momentNumber;
      expect(result, expResult);
    }
    {
      logger.d('getBeat');
      SongUpdate instance = SongUpdate();
      int expResult = 0;
      int result = instance.beat;
      expect(result, expResult);
      expResult = 14;
      instance.setBeat(expResult);
      expect(instance.beat, expResult);
    }
    {
      logger.d('getBeatsPerMeasure');
      SongUpdate instance = SongUpdate();
      int expResult = 4;
      int result = instance.getBeatsPerMeasure();
      expect(result, expResult);
      expResult = 3;
      instance.setBeatsPerBar(expResult);
      expect(instance.getBeatsPerMeasure(), expResult);
    }
    {
      logger.d('getCurrentBeatsPerMinute');
      SongUpdate instance = SongUpdate();
      int expResult = SongUpdate.defaultBeatsPerMinute;
      int result = instance.getCurrentBeatsPerMinute();
      expect(result, expResult);
      expResult = 112;
      instance.setCurrentBeatsPerMinute(expResult);
      expect(instance.getCurrentBeatsPerMinute(), expResult);
    }
    {
      logger.d('setMeasure');
      int momentNumber = 0;
      SongUpdate instance = SongUpdate();
      instance.setMomentNumber(momentNumber);
      expect(instance.momentNumber, momentNumber);
    }
    {
      logger.d('setBeat');
      int beat = 0;
      SongUpdate instance = SongUpdate();
      instance.setBeat(beat);
    }
    {
      logger.d('setBeatsPerBar');
      int beatsPerMeasure = 0;
      SongUpdate instance = SongUpdate();
      instance.setBeatsPerBar(beatsPerMeasure);
    }
    {
      logger.d('setCurrentBeatsPerMinute');
      int beatsPerMinute = 0;
      SongUpdate instance = SongUpdate();
      instance.setCurrentBeatsPerMinute(beatsPerMinute);
    }
    {
      logger.d('fromJson');
      String jsonString = '';
      SongUpdate? expResult;
      try {
        SongUpdate? result = SongUpdate.fromJson(jsonString);
        expect(result, expResult);
      } catch (pex) {
        fail(pex.toString());
      }
    }
    {
      logger.d('fromJsonObject');
      dynamic jo;
      SongUpdate? expResult = SongUpdate();
      SongUpdate? result;
      try {
        result = SongUpdate.fromJsonObject(jo);
      } catch (e) {
        logger.i(e.toString());
      }
      expect(result, expResult);
    }
    {
      logger.d('toJson');
//    SongUpdate instance =SongUpdate();
//    String expResult = "";
//    String result = instance.toJson();
//    expect(result, expResult);

      logger.d('hashCode');
      SongUpdate instance = SongUpdate();
      expect(instance.hashCode, instance.hashCode);
      SongUpdate instance2 = SongUpdate();
      expect(instance.hashCode, instance2.hashCode);
      instance.setBeat(14);
      expect(instance.hashCode == instance2.hashCode, false);
      instance2.setBeat(14);
      expect(instance.hashCode, instance2.hashCode);
    }
    {
      logger.d('equals');
      SongUpdate instance = SongUpdate();
      expect(instance == instance, true);
      SongUpdate instance2 = SongUpdate();
      expect(instance == instance2, true);
      instance.setBeat(14);
      expect(instance == instance2, false);
      instance2.setBeat(14);
      expect(instance == instance2, true);
    }

    {
      logger.d('setMomentNumber');
      SongUpdate instance = SongUpdate();

      Song a = Song(
          title: 'A',
          artist: 'bobby',
          copyright: 'bsteele.com',
          key: Key.getDefault(),
          beatsPerMinute: 106,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          user: 'bob',
          chords: 'i1: D D D D v: A B C D x4',
          rawLyrics: 'i1:\nv:\nbob, bob, bob berand\n');

      instance.song = a;
      int expResult = 10;
      instance.setMomentNumber(expResult);
      expect(instance.momentNumber, expResult);
      expResult = 19;
      instance.setMomentNumber(expResult);
      expect(instance.momentNumber, expResult);
      expResult = 20;
      instance.setMomentNumber(expResult);
      expect(instance.momentNumber, min(expResult, instance.song.songMoments.length - 1));
      expResult = 25;
      instance.setMomentNumber(expResult);
      expect(instance.momentNumber, min(expResult, instance.song.songMoments.length - 1));
      expResult = -3;
      instance.setMomentNumber(expResult);
      expect(instance.momentNumber, expResult);
      expResult = 0;
      instance.setMomentNumber(expResult);
      expect(instance.momentNumber, expResult);


      instance.song.lastModifiedTime = 0; //  for testing only

      //  moment number should never be greater then length - 1
      int length = instance.song.songMoments.length;
      int limit = instance.song.songMoments.length + 3;
      for (int momentNumber = 0; momentNumber < limit; momentNumber++) {
        instance.setMomentNumber(momentNumber);

        expect(instance.toJson(), '''{
"state": "idle",
"currentKey": "C",
"song": {
"title": "A",
"artist": "bobby",
"user": "bob",
"lastModifiedDate": 0,
"copyright": "bsteele.com",
"key": "C",
"defaultBpm": 106,
"timeSignature": "4/4",
"chords": 
    [
	"I1:",
	"D D D D",
	"V:",
	"A B C D x4"
    ],
"lyrics": 
    [
	"i1:",
	"v:",
	"bob, bob, bob berand"
    ]
}
,
"momentNumber": ${min(momentNumber, length - 1)},
"rowNumber": 0,
"beat": 0,
"user": "unknown",
"singer": "unknown",
"beatsPerMeasure": 4,
"currentBeatsPerMinute": ${SongUpdate.defaultBeatsPerMinute}
}
''');
      }

      SongUpdate? instance2 = SongUpdate.fromJson(instance.toJson());
      expect(instance2 != null, true);
      expect(instance2 == instance, isTrue);
      expect(instance2, instance);
      expect(instance, instance2);
    }
  });
}
