import 'phrase.dart';
import 'section.dart';
import 'section_version.dart';
import 'song.dart';

import 'chord.dart';
import 'chord_anticipation_or_delay.dart';
import 'chord_section.dart';
import 'chord_section_location.dart';
import 'measure.dart';
import 'measure_node.dart';

final ChordSectionLocation defaultLocation = // last resort, better than null
ChordSectionLocation(SectionVersion.bySection(Section.get(.chorus)));

enum SongEditScale {
  section,
  //  phrase,
  measure,
}

/// Manage edits for the user interface to simplify its structure
class SongEditManager {
  SongEditManager(this._song) : _preEditSong = _song;

  /// pre edit the song to convert inserts and appends into their resulting edits to aid in the entry of content
  Song preEdit(EditPoint editPoint) {
    var location = editPoint.location;
    var measureNode = _song.findMeasureNodeByLocation(location);

    var songEditScale = editPoint.songEditScale;

    switch (songEditScale) {
      case SongEditScale.section:
        if (location.isSection) {
          if (measureNode == null) {
            //  new section
            measureNode = ChordSection(location.sectionVersion!, []);
          } else {
            //  restrict edits to a section add if given a section
            if (measureNode is ChordSection) {
              measureNode = _song.suggestNewSection();
            }
          }
        } else {
          assert(false); //  shouldn't happen
        }
        break;
      case SongEditScale.measure:
        {
          //  restrict edits to a single measure
          if (measureNode is Phrase && measureNode.isNotEmpty) {
            measureNode = measureNode.firstMeasure!.deepCopy();
          }
          //  create new measure if one doesn't exist
          if (measureNode == null || measureNode.isEmpty) {
            measureNode = Measure(_song.beatsPerBar, [
              Chord(_song.key.getMajorScaleChord(), _song.beatsPerBar, _song.beatsPerBar, null,
                  ChordAnticipationOrDelay.get(.none), true)
            ]);
          }
        }
        break;
    }

    switch (editPoint.measureEditType) {
      case MeasureEditType.replace:
      case MeasureEditType.delete:
        //  no work to be done
        _preEditSong = song;
        _editPoint = editPoint;
        return _preEditSong;
      case MeasureEditType.insert:
      case MeasureEditType.append:
        break;
    }

    //  pre edit required, use a copy
    _preEditSong = song.copySong();
    _preEditSong.setCurrentChordSectionLocation(location);
    _preEditSong.currentMeasureEditType = editPoint.measureEditType;
    if (_preEditSong.editMeasureNode(measureNode)) {
      _editPoint = EditPoint(_preEditSong.currentChordSectionLocation, onEndOfRow: editPoint.onEndOfRow);
      if (measureNode is Measure) {
        switch (editPoint.measureEditType) {
          case MeasureEditType.insert:
            break;
          case MeasureEditType.append:
            //  append on new row with a single new measure on the new row
            if (editPoint.onEndOfRow) {
              _preEditSong.setChordSectionLocationMeasureEndOfRow(location, true);
              _preEditSong.setChordSectionLocationMeasureEndOfRow(_preEditSong.currentChordSectionLocation, true);
            } else {
              _preEditSong.setChordSectionLocationMeasureEndOfRow(location, false);
            }
            break;
          default:
            break;
        }
      }
    }

    return _preEditSong;
  }

  Song reset() {
    _preEditSong = song.copySong();
    return _preEditSong;
  }

  EditPoint get editPoint => _editPoint;
  EditPoint _editPoint = EditPoint.defaultInstance;

  Song get song => _song;
  final Song _song;

  Song get preEditSong => _preEditSong;
  late Song _preEditSong;
}

//  internal class to hold handy data for each point in the chord section edit display
class EditPoint {
  EditPoint(ChordSectionLocation? loc, {this.measureEditType = MeasureEditType.replace, this.onEndOfRow = false})
      : location = loc ?? defaultLocation,
        songEditScale = SongEditScale.measure;

  EditPoint.byChordSection(ChordSection chordSection,
      {this.onEndOfRow = false, this.measureEditType = MeasureEditType.replace})
      : location = ChordSectionLocation(chordSection.sectionVersion),
        measureNode = chordSection,
        songEditScale = SongEditScale.section;

  bool matches(EditPoint? o) {
    return o != null && location == o.location && measureEditType == o.measureEditType;
  }

  @override
  String toString() {
    return 'EditPoint{'
        ' loc: ${location.toString()}'
        ', editType: ${measureEditType.name}'
        ', onEndOfRow: $onEndOfRow'
        ', scale: ${songEditScale.name}'
        '${(measureNode == null ? '' : ', measureNode: $measureNode')}'
        '}';
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! EditPoint) {
      return false;
    }
    EditPoint o = other;
    return location == o.location &&
        measureEditType == o.measureEditType &&
        onEndOfRow == o.onEndOfRow &&
        measureNode == o.measureNode;
  }

  bool get isSection => measureNode != null && measureNode?.measureNodeType == .section;

  @override
  int get hashCode => Object.hashAll([location, measureEditType, measureNode]);

  static final EditPoint defaultInstance = EditPoint.byChordSection(ChordSection(SectionVersion.defaultInstance, []));

  ChordSectionLocation location;
  bool onEndOfRow = false;
  MeasureEditType measureEditType = MeasureEditType.replace; //  default
  MeasureNode? measureNode;
  final SongEditScale songEditScale;
}
