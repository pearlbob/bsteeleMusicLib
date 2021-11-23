import 'dart:collection';

import '../util/util.dart';
import 'sectionVersion.dart';

enum SectionEnum {
  /// A section that introduces the song.
  intro,

  /// A repeating section of the song that typically has new lyrics
  /// for each instance.
  verse,

  /// A section that precedes the chorus but may not be used
  /// to lead all chorus sections.
  preChorus,

  /// A repeating section of the song that typically has lyrics that repeat
  /// to enforce the song's theme.
  chorus,

  /// A section labeled "A" to be used in contrast the "B" section.
  /// A concept borrowed from jazz.
  a,

  /// A section labeled "B" to be used in contrast the "A" section.
  /// A concept borrowed from jazz.
  b,

  /// A non-repeating section often used once to break the repeated
  /// section patterns prior to the last sections of a song.
  bridge,

  /// A section used to jump to for an ending or repeat.
  coda,

  /// A short section that repeats or closely resembles a number of measures from the end
  /// of a previous section.  Typically used to end a song.
  tag,

  ///The ending section of many songs.
  outro,
}

//  indicate how "interesting", i.e. how common the section is
Map<SectionEnum, int> _sectionWeights = {
  SectionEnum.intro: 8,
  SectionEnum.verse: 10,
  SectionEnum.preChorus: 8,
  SectionEnum.chorus: 9,
  SectionEnum.a: 2,
  SectionEnum.b: 2,
  SectionEnum.bridge: 5,
  SectionEnum.coda: 1,
  SectionEnum.tag: 4,
  SectionEnum.outro: 6,
};

/// Song structure is represented by a sequence of these sections.
/// The section names have been borrowed from musical practice in the USA
/// so they will likely be familiar.
///
/// Sections do not imply semantics but their proper suggested use
/// will aid in song structure readability.

class Section implements Comparable<Section> {
  Section._(this._sectionEnum, this._abbreviation, this._alternateAbbreviation, this._description)
      : //_lowerCaseName = _sectionEnumToString(_sectionEnum).toLowerCase(),
        _formalName = Util.firstToUpper(_sectionEnumToString(_sectionEnum).toLowerCase()),
        _originalAbbreviation = _abbreviation;

  static String _sectionEnumToString(SectionEnum se) {
    return se.toString().split('.').last;
  }

  static final List<dynamic> _initialization = [
    [SectionEnum.intro, 'I', 'in', 'A section that introduces the song.'],
    [SectionEnum.verse, 'V', 'vs', 'A repeating section of the song that typically has new lyrics for each instance.'],
    [
      SectionEnum.preChorus,
      'PC',
      null,
      'A section that precedes the chorus but may not be used to lead all chorus sections.'
    ],
    [
      SectionEnum.chorus,
      'C',
      'ch',
      "A repeating section of the song that typically has lyrics that repeat  to enforce the song's  theme  .  "
    ],
    [
      SectionEnum.a,
      'A',
      null,
      'A section labeled \"A\" to be used in contrast the \"B\" section.  A concept borrowed from jazz.'
    ],
    [
      SectionEnum.b,
      'B',
      null,
      'A section labeled \"B\" to be used in contrast the \"A\" section.  A concept borrowed from jazz.'
    ],
    [
      SectionEnum.bridge,
      'Br',
      null,
      'A non-repeating section often used once to break the repeated section patterns prior to the last sections of a song.'
    ],
    [SectionEnum.coda, 'Co', 'coda', 'A section used to jump to for an ending or repeat.'],
    [
      SectionEnum.tag,
      'T',
      null,
      'A short section that repeats or closely resembles a number of measures from the end '
          ' of a previous section.  Typically used to end a song.'
    ],
    [SectionEnum.outro, 'O', 'out', 'The ending section of many songs.'],
  ];

  static HashMap<SectionEnum, Section> _getSections() {
    if (_sections.isEmpty) {
      for (var init in _initialization) {
        SectionEnum seInit = init[0];
        Section section = Section._(seInit, init[1], init[2], init[3]);
        _sectionsList.add(section);
        _sections[seInit] = section;
      }
    }
    return _sections;
  }

  static HashMap<String, Section> _getMapStringToSection() {
    if (mapStringToSection.isEmpty) {
      for (Section section in _getSections().values) {
        mapStringToSection[section._formalName.toLowerCase()] = section;
        mapStringToSection[section._abbreviation.toLowerCase()] = section;
        if (section._alternateAbbreviation != null) {
          mapStringToSection[section._alternateAbbreviation!.toLowerCase()] = section;
        }
      }
      //  additions:
      mapStringToSection['instrumental'] = Section.get(SectionEnum.intro);
    }
    return mapStringToSection;
  }

  static Section get(SectionEnum se) {
    return _getSections()[se]!;
  }

  static Iterable<Section> get values {
    _getSections(); // assure lazy eval
    return _sectionsList;
  }

  // static late final HashMap<String, SectionEnum> _sectionEnums = HashMap.identity();

  // static SectionEnum? _getSectionEnum(String s) {
  //   //  lazy eval
  //   if (_sectionEnums.isEmpty) {
  //     for (SectionEnum se in SectionEnum.values) {
  //       _sectionEnums[_sectionEnumToString(se).toLowerCase()] = se;
  //
  //       //  add abbreviations
  //       Section section = get(se);
  //       _sectionEnums[section._abbreviation.toLowerCase()] = se;
  //       if (section._alternateAbbreviation != null) {
  //         _sectionEnums[section._alternateAbbreviation!.toLowerCase()] = se;
  //       }
  //     }
  //   }
  //   return _sectionEnums[s];
  // }

  static Section? parseString(String s) {
    return _getMapStringToSection()[s.toLowerCase()];
  }

  static bool lookahead(MarkedString markedString) {
    RegExpMatch? m = sectionRegexp.firstMatch(markedString.remainingStringLimited(maxLength));
    if (m == null) {
      return false;
    }
    if (m.groupCount < 2) {
      return false;
    }
    String sectionName = m.group(1)!;
    Section? section = parseString(sectionName.toLowerCase());
    //String sectionNumber = m.group(2)!;
    return section != null;
  }

  static Section? getSection(String sectionId) {
    sectionId = sectionId.toLowerCase();
    return _getMapStringToSection()[sectionId];
  }

  @override
  int compareTo(Section other) {
    return _sectionEnum.index - other._sectionEnum.index;
  }

  /// Utility to return the default section.
  static SectionVersion getDefaultVersion() {
    //  fixme: is this in the right place?
    return SectionVersion.bySection(Section.get(SectionEnum.verse));
  }

  @override
  String toString() {
    return _abbreviation;
  }

  @override
  bool operator ==(other) {
    return runtimeType == other.runtimeType && other is Section && _sectionEnum == other._sectionEnum;
  }

  @override
  int get hashCode {
    return _sectionEnum.hashCode;
  }

  static final HashMap<SectionEnum, Section> _sections = HashMap.identity();
  static final List<Section> _sectionsList = [];

  SectionEnum get sectionEnum => _sectionEnum;
  final SectionEnum _sectionEnum;

  String get abbreviation => _abbreviation;
  final String _abbreviation;

  String? get alternateAbbreviation => _alternateAbbreviation;
  final String? _alternateAbbreviation;

  String get description => _description;
  final String _description;

  //final String _lowerCaseName;

  String get formalName => _formalName;
  final String _formalName;

  String get originalAbbreviation => _originalAbbreviation;
  final String _originalAbbreviation;

  int get weight => _sectionWeights[_sectionEnum] ?? 0;

  static late HashMap<String, Section> mapStringToSection = HashMap();

  static final int maxLength = 10; //  fixme: compute

  static final defaultInstance = Section.get(SectionEnum.verse);

  static final RegExp sectionRegexp = RegExp('^([a-zA-Z]+)([\\d]*):\\s*,*');
}
