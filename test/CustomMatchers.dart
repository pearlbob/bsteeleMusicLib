import 'package:test/test.dart';

/*
There are three important parts to this:

the constructor, which needs to take in any expected value information or a matcher that is used to test the expected value
the matches(item, Map matchState) method, which matches an actual value and returns true if the match is good and false otherwise
the describe() method, which generates a textual description of the matcher
 */

class CompareTo extends Matcher {
  final Comparable _comparable;
  CompareTo(comp) : this._comparable = comp;
  bool matches(item, Map matchState) {
    return item is Comparable &&
        _comparable.compareTo(item)==0;
  }
  Description describe(Description description) =>
      description.add('compare the actual with the expected ');
}

