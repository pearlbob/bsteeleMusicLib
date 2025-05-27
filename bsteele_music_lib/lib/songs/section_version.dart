import 'package:meta/meta.dart';

import '../util/util.dart';
import 'section.dart';

/// A version identifier for multiple numerical variations of a given section.
@immutable
class SectionVersion implements Comparable<SectionVersion> {
  /// A convenience constructor for a section without numerical variation.
  SectionVersion.bySection(this.section)
      : version = 0,
        _name = section.abbreviation;

  /// A constructor for the section version variation's representation.
  SectionVersion(this.section, this.version) : _name = section.abbreviation + (version > 0 ? version.toString() : '');

  static final SectionVersion defaultInstance = SectionVersion.bySection(Section.defaultInstance);

  static SectionVersion parseString(String s) {
    return parse(MarkedString(s));
  }

  /// Return the section from the found id. Match will ignore case. String has to
  /// include the : delimiter and it will be considered part of the section id.
  /// Use the returned version.getParseLength() to find how many characters were
  /// used in the id.

  static SectionVersion parse(MarkedString markedString) {
    if (markedString.isEmpty) {
      throw 'no data to parse';
    }

    RegExpMatch? m = sectionRegexp.firstMatch(markedString.toString());
    if (m == null) {
      throw 'no section version found';
    }

    String? sectionId = m.group(1)!;
    String? versionId = (m.groupCount >= 2 ? m.group(2)! : null);
    int version = 0;
    if (versionId != null && versionId.isNotEmpty) {
      version = int.parse(versionId);
    }
    Section? section = Section.getSection(sectionId);
    if (section == null) {
      throw 'no section found';
    }

    //   consume the section label
    markedString.consume(m.group(0)!.length); //  includes the separator
    return SectionVersion(section, version);
  }

  /// Gets the internal name that will identify this specific section and version
  String get id => _name;

  /// The external facing string that represents the section version to the user.
  @override
  String toString() {
    //  note: designed to go to the user display
    return '$_name:';
  }

  ///Gets a more formal name for the section version that can be presented to the user.
  String getFormalName() {
    //  note: designed to go to the user display
    return '${section.formalName}${version > 0 ? version.toString() : ''}:';
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    return runtimeType == other.runtimeType &&
        other is SectionVersion &&
        section == other.section &&
        version == other.version;
  }

  @override
  int compareTo(SectionVersion o) {
    int ret = section.compareTo(o.section);
    if (ret != 0) {
      return ret;
    }

    if (version != o.version) {
      return version < o.version ? -1 : 1;
    }
    return 0;
  }

  @override
  int get hashCode {
    return Object.hash(section, version);
  }

  final Section section;

  final int version;

  //  computed values
  String get name => _name;
  final String _name;

  int get weight => section.weight + (10 - version);

  static final RegExp sectionRegexp = RegExp(r'^([a-zA-Z]+)([\d]*):');
}
