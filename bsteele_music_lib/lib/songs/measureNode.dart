import 'key.dart';

enum MeasureNodeType {
  section,
  repeat,
  phrase,
  measure,
  comment,
  decoration,
}

enum MeasureEditType {
  insert,
  replace,
  append,
  delete,
}

/// Base class for all measure node trees, i.e. the song chords.
/// Designed to simplify the walk of the song's sequence of measures and sequences of measures.

abstract class MeasureNode {
  /// Returns true if the node is a single item and not a collection or measures.
  bool isSingleItem() {
    return true;
  }

  /// Return true if the node represents a collection of measures that are to be repeated a prescribed number of repeats.
  bool isRepeat() {
    return false;
  }

  /// Return true if the node is a comment.  This is typically false.
  bool isComment() {
    return false;
  }

  /// Return true if the measure node is a collection and it's empty
  bool isEmpty() {
    return false;
  }

  /// Transpose the measure node the given number of half steps from the given key.
  String transpose(Key key, int halfSteps);

  /// If required, transpose the measure node to the given key.
  /// This is used to represent the scale note(s) in the proper expression
  /// of flats or sharps based on the key.
  ///
  /// Note that the key of C is considered sharp.
  MeasureNode transposeToKey(Key key);

  /// Represent the measure node to the user in a string form and from storage encoding.
  String toMarkup();

  /// Represent the measure node to the user in a display string for presentation
  String toMarkupWithoutEnd();

  /// Represent the measure node to the user in a string form and entry ready.
  String toEntry();

  /// Set the measures per row to the given value;
  bool setMeasuresPerRow(int measuresPerRow);

  static String concatMarkup(List<MeasureNode>? measureNodes) {
    StringBuffer sb = StringBuffer();
    if (measureNodes != null) {
      for (MeasureNode measureNode in measureNodes) {
        sb.write(measureNode.toMarkup());
      }
    }
    return sb.toString();
  }

  /// Gets the block identifier for this measure node type when expressed in HTML.
  String getHtmlBlockId() {
    return 'C';
  }

  ///  Export to JSON
  String toJson();

  /// The id to uniquely identify this measureNode in the song.
  String? getId();

  MeasureNodeType getMeasureNodeType();
}
