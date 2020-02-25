import 'package:bsteeleMusicLib/util/util.dart';
import "package:test/test.dart";

void main() {
  test("test MarkedStrings", ()
  {
    {
      MarkedString ms = new MarkedString("1234");
      expect(4, ms.available());
      ms.getNextChar();
      ms.mark();
      expect(3, ms.available());
      expect('2', ms.charAt(0));
      expect('3', ms.charAt(1));
      expect('4', ms.charAt(2));

      try {
        ms.charAt(3);
        fail("expected to fail, but didn't");
      }
      on RangeError {
        //  expected
      }

      expect('2', ms.getNextChar());
      expect('3', ms.getNextChar());
      expect('4', ms.getNextChar());
      expect(0, ms.available());

      try {
        ms.getNextChar();
        fail("expected to fail, but didn't");
      }
      on RangeError {
        //  expected
      }

      ms.resetToMark();
      expect(3, ms.available());
      expect('2', ms.getNextChar());
      expect('3', ms.getNextChar());
      expect('4', ms.getNextChar());
      expect(0, ms.available());

      try {
        ms.getNextChar();
        fail("expected to fail, but didn't");
      } on RangeError {
        //  expected
      }

      ms.resetTo(2);
      expect(2, ms.available());
      expect('3', ms.getNextChar());
      expect('4', ms.getNextChar());
      expect(0, ms.available());

      try {
        ms.getNextChar();
        fail("expected to fail, but didn't");
      } on RangeError {
        //  expected
      }
    }
    {
      MarkedString eb = new MarkedString("s");
      expect(false, eb.isEmpty);
      eb.getNextChar();
      expect(true, eb.isEmpty);
    }

    {
      MarkedString markedString = new MarkedString("1234");
      expect(4, markedString.available());
      expect('1', markedString.charAt(0));
      expect('2', markedString.charAt(1));
      expect('4', markedString.charAt(3));
      try {
        markedString.charAt(4);
        fail("expected to fail, but didn't");
      } on RangeError {
        //  expected
      }
      markedString.getNextChar();
      expect(3, markedString.available());
      expect('2', markedString.charAt(0));
    }

    {
      String s = "1234";
      MarkedString markedString = new MarkedString(s);

      String actual = markedString.remainingStringLimited(25);
      expect(s, actual);
      expect(s.substring(0, 2), markedString.remainingStringLimited(2));
      expect(s.substring(0, 4), markedString.remainingStringLimited(4));
      expect("", markedString.remainingStringLimited(0));
    }
  });
}