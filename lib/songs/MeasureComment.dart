import '../util/util.dart';
import 'Measure.dart';
import 'MeasureNode.dart';
import 'Key.dart';

class MeasureComment extends Measure {
  MeasureComment(this._comment) : super.zeroArgs() {
    endOfRow = true;
  }

  MeasureComment.zeroArgs()
      : _comment = "",
        super.zeroArgs();

  @override
  bool isComment() {
    return true;
  }

  @override
  MeasureNodeType getMeasureNodeType() {
    return MeasureNodeType.comment;
  }

  static MeasureComment parseString(String s) {
    return parse(MarkedString(s));
  }

  /// Trash can of measure parsing.  Will consume all that it sees to the end of line.
  static MeasureComment parse(MarkedString markedString) {
    if (markedString == null || markedString.isEmpty) throw "no data to parse";

//  prep a sub string to look for the comment
    int n =
        markedString.indexOf("\n"); //  all comments end at the end of the line
    String s = "";
    if (n > 0)
      s = markedString.remainingStringLimited(n);
    else
      s = markedString.toString();

    //  properly formatted comment

    RegExpMatch mr = commentRegExp.firstMatch(s);

    //  consume the comment
    if (mr != null) {
      s = mr.group(1);
      markedString.consume(mr.group(0).length);
    } else {
      throw "no well formed comment found"; //  all whitespace
    }

//  cope with unbalanced leading ('s and trailing )'s
    s = s.replaceAll(r"^\(", "").replaceAll(r"\)$", "");
    s = s.trim(); //  in case there is white space inside unbalanced parens

    MeasureComment ret = new MeasureComment(s);
    return ret;
  }

  @override
  String transpose(Key key, int halfSteps) {
    return toString();
  }

  @override
  String toMarkup() {
    return toString();
  }

  @override
  String toEntry() {
    return "\n" + toString() + "\n";
  }

  @override
  String toString() {
    return _comment == null || _comment.length <= 0 ? "" : "(" + _comment + ")";
  }

  @override
  String toJson() {
    return toString();
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    return runtimeType == other.runtimeType && _comment == other._comment;
  }

  @override
  int get hashCode {
    return _comment.hashCode;
  }

  String get comment => _comment;
  final String _comment;

  static final RegExp commentRegExp = RegExp(r"^\s*\(\s*(.*?)\s*\)\s*");
}
