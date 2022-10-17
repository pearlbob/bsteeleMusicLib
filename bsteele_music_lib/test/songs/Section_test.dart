import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/section.dart';
import 'package:bsteeleMusicLib/util/util.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('section abbreviations', () {
    StringBuffer sb = StringBuffer();
    bool first = true;
    for (Section section in Section.values) {
      expect(section.description, isNotNull);
      if (first) {
        first = false;
      } else {
        sb.write(', ');
      }
      sb.write('${section.formalName}:');
      String s = section.abbreviation;
      sb.write(' $s');
    }
    logger.d(sb.toString());
    expect(sb.toString(),
        'Intro: I, Verse: V, Prechorus: PC, Chorus: C, A: A, B: B, Bridge: Br, Coda: Co, Tag: T, Outro: O');
  });

  test('lookahead', () {
    expect(Section.lookahead(MarkedString('I:')), isTrue);
    expect(Section.lookahead(MarkedString('i:')), isTrue);
    expect(Section.lookahead(MarkedString('V:')), isTrue);
    expect(Section.lookahead(MarkedString('v:')), isTrue);
    expect(Section.lookahead(MarkedString('PC:')), isTrue);
    expect(Section.lookahead(MarkedString('pc:')), isTrue);
    expect(Section.lookahead(MarkedString('pC:')), isTrue);
    expect(Section.lookahead(MarkedString('c:')), isTrue);
    expect(Section.lookahead(MarkedString('ch:')), isTrue);
    expect(Section.lookahead(MarkedString('C:')), isTrue);
    expect(Section.lookahead(MarkedString('b:')), isTrue);
    expect(Section.lookahead(MarkedString('br:')), isTrue);
    expect(Section.lookahead(MarkedString('co:')), isTrue);
    expect(Section.lookahead(MarkedString('t:')), isTrue);
    expect(Section.lookahead(MarkedString('o:')), isTrue);
    expect(Section.lookahead(MarkedString('T:')), isTrue);

    expect(Section.lookahead(MarkedString('I: ')), isTrue);
    expect(Section.lookahead(MarkedString('i: asdf')), isTrue);
    expect(Section.lookahead(MarkedString('V::')), isTrue);
    expect(Section.lookahead(MarkedString('v:\n')), isTrue);
    expect(Section.lookahead(MarkedString('PC:\tasdf')), isTrue);
    expect(Section.lookahead(MarkedString('pc: C:')), isTrue);
    expect(Section.lookahead(MarkedString('pC:v:o:')), isTrue);
    expect(Section.lookahead(MarkedString('c::')), isTrue);

    expect(Section.lookahead(MarkedString(' ch:')), isFalse);
    expect(Section.lookahead(MarkedString('x:')), isFalse);
    expect(Section.lookahead(MarkedString('Chourus:')), isFalse);
    expect(Section.lookahead(MarkedString('chorus:')), isTrue);
    expect(Section.lookahead(MarkedString('bridge:')), isTrue);
    expect(Section.lookahead(MarkedString('coDA:')), isTrue);
    expect(Section.lookahead(MarkedString('tag:')), isTrue);
    expect(Section.lookahead(MarkedString('outro:')), isTrue);
    expect(Section.lookahead(MarkedString('instrumental:')), isFalse);
  });
}
