import 'chord_section_location.dart';
import 'key.dart';
import 'measure_comment.dart';
import 'measure_node.dart';

class MeasureRepeatExtension extends MeasureComment {
  static MeasureRepeatExtension get(ChordSectionLocationMarker? marker) {
    if (marker == null) {
      return nullMeasureRepeatExtension;
    }

    switch (marker) {
      case .repeatUpperRight:
        return upperRightMeasureRepeatExtension;
      case .repeatMiddleRight:
        return middleRightMeasureRepeatExtension;
      case .repeatLowerRight:
        return lowerRightMeasureRepeatExtension;
      case .repeatOnOneLineRight:
        return onOneLineRightMeasureRepeatExtension;
      case .none:
        return nullMeasureRepeatExtension;
    }
  }

  MeasureRepeatExtension(this.marker, this.markerString) : super.zeroArgs();

  @override
  MeasureNodeType get measureNodeType => .decoration;

  @override
  @Deprecated('dont use this')
  String getHtmlBlockId() {
    return 'RE';
  }

  @override
  String transpose(Key key, int halfSteps) {
    return toString();
  }

  @override
  String toMarkup({bool expanded = false, bool withInversion = true}) {
    return markerString;
  }

  @override
  String toMarkupWithoutEnd() {
    return markerString;
  }

  @override
  bool isRepeat() {
    return true;
  }

  @override
  String toString() {
    return markerString;
  }

  static const String _upperRight = '\u23A4'; //  ⎤
  static const String _lowerRight = '\u23A6'; //  ⎦

  // static final String _upperLeft = '\u23A1';
  // static final String _lowerLeft = '\u23A3';
  static const String _extension = '\u23A5'; // ⎥
  static final MeasureRepeatExtension upperRightMeasureRepeatExtension =
  MeasureRepeatExtension(.repeatUpperRight, _upperRight);
  static final MeasureRepeatExtension middleRightMeasureRepeatExtension =
  MeasureRepeatExtension(.repeatMiddleRight, _extension);
  static final MeasureRepeatExtension lowerRightMeasureRepeatExtension =
  MeasureRepeatExtension(.repeatLowerRight, _lowerRight);
  static final MeasureRepeatExtension onOneLineRightMeasureRepeatExtension =
  MeasureRepeatExtension(.repeatOnOneLineRight, ']');
  static final MeasureRepeatExtension nullMeasureRepeatExtension =
  MeasureRepeatExtension(.none, '');

  final ChordSectionLocationMarker marker;
  final String markerString;
}
