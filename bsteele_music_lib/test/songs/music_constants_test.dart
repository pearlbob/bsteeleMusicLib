import 'package:bsteele_music_lib/songs/music_constants.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('diatonics test', () {
    parseTest('I iv V I');

    for (Diatonic d in majorDiatonics) {
      List<Diatonic> list = parseTest(d.label);
      assert(list.first == d);
    }
    for (Diatonic d in minorDiatonics) {
      List<Diatonic> list = parseTest(d.label);
      assert(list.first == d);
    }

    for (Diatonic d0 in Diatonic.values) {
      for (Diatonic d1 in Diatonic.values) {
        for (Diatonic d2 in Diatonic.values) {

          List<Diatonic> list = parseTest('${d0.label} ${d1.label} ${d2.label}');
          assert(list.length == 3);
          assert(list[0] == d0);
          assert(list[1] == d1);
          assert(list[2] == d2);
        }
      }
    }
  });
}

List<Diatonic> parseTest(String s) {
  print(s);
  List<Diatonic> list = Diatonic.parse(s);
  assert(s == list.map<String>((e) => e.label).toString().replaceAll(extrasRegExp, ''));
  return list;
}

RegExp extrasRegExp = RegExp(r'[,()]');
