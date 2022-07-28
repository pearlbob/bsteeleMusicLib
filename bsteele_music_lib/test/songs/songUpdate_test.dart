import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/key.dart';
import 'package:bsteeleMusicLib/songs/song.dart';
import 'package:bsteeleMusicLib/songs/songUpdate.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('song updates', () {
    {
      logger.d('getMomentNumber');
      SongUpdate instance = SongUpdate();
      int expResult = 0;
      int result = instance.getMomentNumber();
      expect(result, expResult);
    }
    {
      logger.d('getBeat');
      SongUpdate instance = SongUpdate();
      int expResult = 0;
      int result = instance.getBeat();
      expect(result, expResult);
      expResult = 14;
      instance.setBeat(expResult);
      expect(instance.getBeat(), expResult);
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
      int expResult = 100;
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
      expect(instance.getMomentNumber(), momentNumber);
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
      SongUpdate? expResult;
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

      Song a = Song.createSong('A', 'bobby', 'bsteele.com', Key.getDefault(), 106, 4, 4, 'bob',
          'i1: D D D D v: A B C D x4', 'i1:\nv:\nbob, bob, bob berand\n');
      instance.song = a;
      int expResult = 10;
      instance.setMomentNumber(expResult);
      expect(instance.getMomentNumber(), expResult);
      expResult = 19;
      instance.setMomentNumber(expResult);
      expect(instance.getMomentNumber(), expResult);
      expResult = 20;
      instance.setMomentNumber(expResult);
      expect(instance.getMomentNumber(), expResult);
      expResult = 25;
      instance.setMomentNumber(expResult);
      expect(instance.getMomentNumber(), 20);
      expResult = 0;
      instance.setMomentNumber(expResult);
      expect(instance.getMomentNumber(), expResult);

      instance.song.lastModifiedTime = 0; //  for testing only

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
"momentNumber": 0,
"beat": 0,
"user": "no one",
"singer": "unknown",
"beatsPerMeasure": 4,
"currentBeatsPerMinute": 100
}
''');

      SongUpdate? instance2 = SongUpdate.fromJson(instance.toJson());
      expect(instance2 != null, true);
      expect(instance2 == instance, isTrue);
      expect(instance2, instance);
      expect(instance, instance2);
    }
  });
}
