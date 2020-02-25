import 'package:quiver/core.dart';

import '../util/util.dart';
import 'Section.dart';

/// A version identifier for multiple numerical variations of a given section.
class SectionVersion implements Comparable<SectionVersion> {
  /// A convenience constructor for a section without numerical variation.
  SectionVersion.bySection(this._section)
      : _version = 0,
        _name = _section.abbreviation;

  /// A constructor for the section version variation's representation.
  SectionVersion(this._section, this._version)
      : _name =
            _section.abbreviation + (_version > 0 ? _version.toString() : "");

  static SectionVersion getDefault() {
    return new SectionVersion.bySection(Section.get(SectionEnum.verse));
  }

  static SectionVersion parseString(String s) {
    return parse(new MarkedString(s));
  }

  /// Return the section from the found id. Match will ignore case. String has to
  /// include the : delimiter and it will be considered part of the section id.
  /// Use the returned version.getParseLength() to find how many characters were
  /// used in the id.

  static SectionVersion parse(MarkedString markedString) {
    if (markedString == null) throw "no data to parse";

    RegExpMatch m = sectionRegexp.firstMatch(markedString.toString());
    if (m == null) throw "no section version found";

    String sectionId = m.group(1);
    String versionId = (m.groupCount >= 2 ? m.group(2) : null);
    int version = 0;
    if (versionId != null && versionId.length > 0) {
      version = int.parse(versionId);
    }
    Section section = Section.getSection(sectionId);
    if (section == null) throw "no section found";

    //   consume the section label
    markedString.consume(m.group(0).length); //  includes the separator
    return SectionVersion(section, version);
  }

  /// Gets the internal name that will identify this specific section and version
  String get id => _name;

  /// The external facing string that represents the section version to the user.
  @override
  String toString() {
    //  note: designed to go to the user display
    return _name + ":";
  }

  ///Gets a more formal name for the section version that can be presented to the user.
  String getFormalName() {
    //  note: designed to go to the user display
    return _section.formalName +
        (_version > 0 ? _version.toString() : "") +
        ":";
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    return other is SectionVersion &&
        _section == other._section &&
        _version == other._version;
  }

  @override
  int compareTo(SectionVersion o) {
    int ret = _section.compareTo(o._section);
    if (ret != 0) return ret;

    if (_version != o._version) {
      return _version < o._version ? -1 : 1;
    }
    return 0;
  }

  @override
  int get hashCode {
    return hash2(_section, _version);
  }

  /// Return the generic section for this section version.
  Section get section => _section;
  final Section _section;

  /// Return the numeric count for this section version.
  int get version => _version;
  final int _version;

  //  computed values
  String get name => _name;
  final String _name;

  static final RegExp sectionRegexp = RegExp(r"^([a-zA-Z]+)([\d]*):\s*\,*");
}
