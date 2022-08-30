import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/util/splitBySyllables.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  test('test splitBySyllables', () {
    Logger.level = Level.info;

    var words = 'String separable words to test by syllables!';
    var result = toSyllableTuples(words.toLowerCase());
    logger.i('splitBySyllables(\'$words\') = $result');
    expect(result.toString(),
        '[[string, 1], [separable, 4], [words, 1], [to, 1], [test, 1], [by, 1], [syllables, 3], [!, 0]]');

    words = 'don\'t panic!';
    result = toSyllableTuples(words.toLowerCase());
    logger.i('splitBySyllables(\'$words\') = $result');
    expect(result.toString(), '[[don, 1], [\', 0], [t, 1], [panic, 2], [!, 0]]');
  });
}
