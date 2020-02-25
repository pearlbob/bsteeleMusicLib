import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/Phrase.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.warning;

  test("testParsing", () {
    int phraseIndex = 0;
    int beatsPerBar = 4;
    String s;
    Phrase phrase;

    try {
      s = "G F E D x2";
      phrase = Phrase.parseString(s, phraseIndex, beatsPerBar, null);
      fail("a repeat is not a phrase");
    } catch (e) {}

    s = "A B C D, G F E D x2";
    phrase = Phrase.parseString(s, phraseIndex, beatsPerBar, null);
    expect(phrase.length, 4); //  phrase should not include the repeat

    s = "   A ";
    phrase = Phrase.parseString(s, phraseIndex, beatsPerBar, null);
    expect(phrase.length, 1);

    s = "A B C D";
    phrase = Phrase.parseString(s, phraseIndex, beatsPerBar, null);
    expect(phrase.length, 4);

    s = "A B C D A B C D A B C D";
    phrase = Phrase.parseString(s, phraseIndex, beatsPerBar, null);
    expect(phrase.length, 12);

    s = "A B C, D A ,B C D ,A, B C D";
    phrase = Phrase.parseString(s, phraseIndex, beatsPerBar, null);
    expect(phrase.length, 12);

    s = "A B C, D A ,B C D ,A, B C D, G G x2";
    phrase = Phrase.parseString(s, phraseIndex, beatsPerBar, null);
    logger.d(s);
    expect(phrase.length, 12);
  });
}
