import 'ChordSectionLocation.dart';
import 'MeasureComment.dart';
import 'MeasureNode.dart';
import 'Key.dart';

class MeasureRepeatExtension extends MeasureComment {
  static MeasureRepeatExtension get(ChordSectionLocationMarker marker) {
    if (marker == null) return nullMeasureRepeatExtension;

    switch (marker) {
      case ChordSectionLocationMarker.repeatUpperRight:
        return upperRightMeasureRepeatExtension;
      case ChordSectionLocationMarker.repeatMiddleRight:
        return middleRightMeasureRepeatExtension;
      case ChordSectionLocationMarker.repeatLowerRight:
        return lowerRightMeasureRepeatExtension;
      case ChordSectionLocationMarker.none:
      default:
        return nullMeasureRepeatExtension;
    }
  }


  MeasureRepeatExtension(this.markerString) : super.zeroArgs();

  @override
  MeasureNodeType getMeasureNodeType() {
    return MeasureNodeType.decoration;
  }

  @deprecated
  String getHtmlBlockId() {
    return "RE";
  }

  @override
  String transpose(Key key, int halfSteps) {
    return toString();
  }

  @override
  String toMarkup() {
    return "";
  }

  @override
  bool isRepeat() {
    return true;
  }

  @override
  String toString() {
    return markerString;
  }

  static final String uppperRight = "\u23A4";
  static final String lowerRight = "\u23A6";
  static final String uppperLeft = "\u23A1";
  static final String lowerLeft = "\u23A3";
  static final String extension = "\u23A5";
  static final MeasureRepeatExtension upperRightMeasureRepeatExtension =
      new MeasureRepeatExtension(uppperRight);
  static final MeasureRepeatExtension middleRightMeasureRepeatExtension =
      new MeasureRepeatExtension(extension);
  static final MeasureRepeatExtension lowerRightMeasureRepeatExtension =
      new MeasureRepeatExtension(lowerRight);
  static final MeasureRepeatExtension nullMeasureRepeatExtension =
      new MeasureRepeatExtension("");

  final String markerString;
}
