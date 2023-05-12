import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/songs/measure.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('test id', () {
    Measure m;
    Measure ref;
    int beats = 4;

    {
      m = Measure.parseString('B', beats);
      int id = m.id;
      logger.i('id: $id');
      ref = Measure.parseString('B', beats);
      int refId = ref.id;

      logger.i('refId: $refId, id: $id');
      logger.i('m.hashCode: ${m.hashCode}, ref.hashCode: ${ref.hashCode}');

      expect(refId == id, isFalse);
      expect(m.hashCode, ref.hashCode);
    }
  });
}
