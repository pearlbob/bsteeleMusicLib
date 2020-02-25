import 'package:bsteeleMusicLib/util/util.dart';
import "package:test/test.dart";

void main() {
  test("test quote", () {
    String s;
    String qs;

    s = null;
    expect(Util.quote(s), s);
    s = "";
    qs = Util.quote(s);
    expect(qs, s);
    s = " ";
    expect(Util.quote(s), '\'$s\'');
    s = " nothing special, per se &nbsp;";
    expect(Util.quote(s), '\'' + s + '\'');
    s = " something special,\nhere;";
    qs = Util.quote(s);
    expect(qs, '\' something special,\\n\'\n\'here;\'');
  });
}
