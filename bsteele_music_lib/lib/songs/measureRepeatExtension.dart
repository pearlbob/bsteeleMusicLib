import 'chordSectionLocation.dart';
import 'measureComment.dart';
import 'measureNode.dart';
import 'key.dart';

class MeasureRepeatExtension extends MeasureComment {
  static MeasureRepeatExtension get(ChordSectionLocationMarker? marker) {
    if (marker == null) return nullMeasureRepeatExtension;

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

  MeasureRepeatExtension(this.markerString) : super.zeroArgs();

  @override
  MeasureNodeType getMeasureNodeType() {
    return MeasureNodeType.decoration;
  }

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
  String toMarkup() {
    return '';
  }

  @override
  bool isRepeat() {
    return true;
  }

  @override
  String toString() {
    return markerString;
  }

  static final String upperRight = '\u23A4';
  static final String lowerRight = '\u23A6';
  static final String upperLeft = '\u23A1';
  static final String lowerLeft = '\u23A3';
  static final String extension = '\u23A5';
  static final MeasureRepeatExtension upperRightMeasureRepeatExtension = MeasureRepeatExtension(upperRight);
  static final MeasureRepeatExtension middleRightMeasureRepeatExtension = MeasureRepeatExtension(extension);
  static final MeasureRepeatExtension lowerRightMeasureRepeatExtension = MeasureRepeatExtension(lowerRight);
  static final MeasureRepeatExtension onOneLineRightMeasureRepeatExtension = MeasureRepeatExtension(']');
  static final MeasureRepeatExtension nullMeasureRepeatExtension = MeasureRepeatExtension('');

  final String markerString;
}
