import 'package:bsteeleMusicLib/songs/measureComment.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

String? rawComment;
MeasureComment? measureComment;

void parse(String s) {
  rawComment = s;
  try {
    measureComment = MeasureComment.parseString(s);
  } catch (e) {
    measureComment = null;
  }
}

void main() {
  Logger.level = Level.debug;

  test('testparseString', () {
    parse('  (  123  )   A\n');
    if (measureComment == null) throw 'measureComment == null';
    expect(measureComment, isNotNull);
    expect(measureComment!.isComment(), true);
    expect(measureComment!.isSingleItem(), true);
    expect(measureComment!.isRepeat(), false);
    expect(measureComment!.comment, '123');

    parse('(123)');
    expect(measureComment!.isComment(), true);
    expect(measureComment!.isSingleItem(), true);
    expect(measureComment!.isRepeat(), false);
    expect('123', measureComment!.comment);

    parse('   (   abc 123   )   ');
    expect('abc 123', measureComment!.comment);

    parse(' '); //  not a comment
    expect(measureComment, isNull);
    parse('\n'); //  not a comment
    expect(measureComment, isNull);
    parse(' \t'); //  not a comment
    expect(measureComment, isNull);
    parse('\t'); //  not a comment
    expect(measureComment, isNull);
    parse('\t\t  \t\t   '); //  not a comment
    expect(measureComment, isNull);
    parse(' '); //  not a comment
    expect(measureComment, isNull);

    //  initial and final spaces not included
    parse('( this is a comment )');
    expect(rawComment!.length - 2, measureComment.toString().length);
    expect('this is a comment', measureComment!.comment);

    parse('this is not a comment )');
    expect(measureComment, isNull);

    parse('( this is also a bad comment');
    expect(measureComment, isNull);

    parse('this is also has to not be a comment');
    expect(measureComment, isNull);

    parse('ABC\nDEF'); //  not all a comment
    expect(measureComment, isNull);

    parse(''); //  not a comment
    expect(measureComment, isNull);

    try {
      MeasureComment.parseString('');
      fail("parsing nothing didn't throw an exception");
    } catch (e) {
      //  should throw this exception
    }
  });
}
