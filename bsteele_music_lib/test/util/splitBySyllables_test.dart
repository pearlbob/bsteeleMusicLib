
import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/util/splitBySyllables.dart';
import 'package:test/test.dart';

void main() {
  test('test splitBySyllables', () {
    var words = 'String words to test by syllables!';
    logger.i('splitBySyllables(\'$words\') = ${splitBySyllables(words)}');
  });

}
