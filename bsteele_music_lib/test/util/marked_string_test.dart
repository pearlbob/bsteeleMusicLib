import 'package:bsteele_music_lib/util/util.dart';
import 'package:test/test.dart';

void main() {
  test('test MarkedStrings', () {
    {
      MarkedString ms = MarkedString('1234');
      expect(ms.available(), 4);
      expect(ms.first(), '1');
      expect(ms.pop(), '1');
      ms.mark();
      expect(ms.available(), 3);
      expect(ms.first(), '2');
      expect(ms.available(), 3);
      expect(ms.pop(), '2');
      expect(ms.available(), 2);
      expect(ms.pop(), '3');
      expect(ms.available(), 1);
      expect(ms.first(), '4');

      expect(ms.charAt(3), '');

      ms.resetToMark();
      expect(ms.available(), 3);
      expect(ms.first(), '2');
      expect(ms.pop(), '2');
      expect(ms.pop(), '3');
      expect(ms.available(), 1);
      expect(ms.pop(), '4');
      expect(ms.available(), 0);

      expect(ms.pop(), '');
      expect(ms.available(), 0);

      ms.resetToMark();
      expect(ms.available(), 3);
      expect(ms.first(), '2');
      expect(ms.available(), 3);
      expect(ms.pop(), '2');
      expect(ms.available(), 2);
      expect(ms.pop(), '3');
      expect(ms.available(), 1);
      expect(ms.pop(), '4');
      expect(ms.available(), 0);

      expect(ms.first(), '');
      expect(ms.available(), 0);
      expect(ms.pop(), '');
      expect(ms.available(), 0);

      ms.resetTo(2);
      expect(ms.available(), 2);
      expect(ms.pop(), '3');
      expect(ms.available(), 1);
      expect(ms.first(), '4');
      expect(ms.available(), 1);
      expect(ms.pop(), '4');
      expect(ms.available(), 0);
      expect(ms.pop(), '');
    }
    {
      MarkedString eb = MarkedString('s');
      expect(false, eb.isEmpty);
      eb.pop();
      expect(true, eb.isEmpty);
    }

    {
      MarkedString markedString = MarkedString('1234');
      expect(markedString.available(), 4);
      expect(markedString.charAt(0), '1');
      expect(markedString.charAt(1), '2');
      expect(markedString.charAt(3), '4');
      expect(markedString.charAt(4), '');

      markedString.pop();
      expect(markedString.available(), 3);
      expect(markedString.charAt(0), '2');
    }

    {
      String s = '1234';
      MarkedString markedString = MarkedString(s);

      String actual = markedString.remainingStringLimited(25);
      expect(s, actual);
      expect(s.substring(0, 2), markedString.remainingStringLimited(2));
      expect(s.substring(0, 4), markedString.remainingStringLimited(4));
      expect('', markedString.remainingStringLimited(0));
    }
  });
}
