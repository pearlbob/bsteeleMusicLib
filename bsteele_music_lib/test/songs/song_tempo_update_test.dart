import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/songs/song_id.dart';
import 'package:bsteele_music_lib/songs/song_tempo_update.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('song tempo updates', () {
    var songId = SongId('Song_1234_by_Feist');
    var songId2 = SongId('Song_bob_by_bob');

    {
      logger.i('song tempo');
      SongTempoUpdate instance = SongTempoUpdate(songId, 120, 0.678);
      logger.i(instance.toString());
      expect(SongTempoUpdate.fromJson(instance.toJson()), instance);

      SongTempoUpdate instance2 = SongTempoUpdate(songId, 110, 0.678);
      assert(instance != instance2);
      assert(instance.hashCode != instance2.hashCode);
      expect(SongTempoUpdate.fromJson(instance2.toJson()), instance2);

      instance2.currentBeatsPerMinute = 120;
      instance2.level = 0.6;
      assert(instance != instance2);
      assert(instance.hashCode != instance2.hashCode);
      expect(SongTempoUpdate.fromJson(instance2.toJson()), instance2);

      instance2.level = 0.678;
      assert(instance == instance2);
      assert(instance.hashCode == instance2.hashCode);
      expect(SongTempoUpdate.fromJson(instance2.toJson()), instance);

      instance2 = SongTempoUpdate(songId2, 120, 0.678);
      assert(instance != instance2);
      assert(instance.hashCode != instance2.hashCode);
      expect(SongTempoUpdate.fromJson(instance2.toJson()), instance2);
    }
  });
}
