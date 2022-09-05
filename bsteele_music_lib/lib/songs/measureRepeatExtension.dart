import 'chordSectionLocation.dart';
import 'key.dart';
import 'measureComment.dart';
import 'measureNode.dart';

class MeasureRepeatExtension extends MeasureComment {
  static MeasureRepeatExtension get(ChordSectionLocationMarker? marker) {
    if (marker == null) {
      return nullMeasureRepeatExtension;
    }

    switch (marker) {
      case ChordSectionLocationMarker.repeatUpperRight:
        return upperRightMeasureRepeatExtension;
      case ChordSectionLocationMarker.repeatMiddleRight:
        return middleRightMeasureRepeatExtension;
      case ChordSectionLocationMarker.repeatLowerRight:
        return lowerRightMeasureRepeatExtension;
      case ChordSectionLocationMarker.repeatOnOneLineRight:
        return onOneLineRightMeasureRepeatExtension;
      case ChordSectionLocationMarker.none:
      default:
        return nullMeasureRepeatExtension;
    }
  }

  MeasureRepeatExtension(this.marker, this.markerString) : super.zeroArgs();

  @override
  MeasureNodeType get measureNodeType => MeasureNodeType.decoration;

  @override
  @deprecated
  String getHtmlBlockId() {
    return 'RE';
  }

  @override
  String transpose(Key key, int halfSteps) {
    return toString();
  }

  @override
  String toMarkup({bool expanded = false}) {
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

  static final String _upperRight = '\u23A4';
  static final String _lowerRight = '\u23A6';

  // static final String _upperLeft = '\u23A1';
  // static final String _lowerLeft = '\u23A3';
  static final String _extension = '\u23A5';
  static final MeasureRepeatExtension upperRightMeasureRepeatExtension =
      MeasureRepeatExtension(ChordSectionLocationMarker.repeatUpperRight, _upperRight);
  static final MeasureRepeatExtension middleRightMeasureRepeatExtension =
      MeasureRepeatExtension(ChordSectionLocationMarker.repeatMiddleRight, _extension);
  static final MeasureRepeatExtension lowerRightMeasureRepeatExtension =
      MeasureRepeatExtension(ChordSectionLocationMarker.repeatLowerRight, _lowerRight);
  static final MeasureRepeatExtension onOneLineRightMeasureRepeatExtension =
      MeasureRepeatExtension(ChordSectionLocationMarker.repeatOnOneLineRight, ']');
  static final MeasureRepeatExtension nullMeasureRepeatExtension =
      MeasureRepeatExtension(ChordSectionLocationMarker.none, '');

  final ChordSectionLocationMarker marker;
  final String markerString;
}
