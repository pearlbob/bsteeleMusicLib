import 'music_constants.dart';

enum NashvilleNote {
  nashville1('1', '1'),
  nashvilleFlat2('b2', '${MusicConstants.flatChar}2'),
  nashville2('2', '2'),
  nashvilleFlat3('b3', '${MusicConstants.flatChar}3'),
  nashville3('3', '3'),
  nashville4('4', '4'),
  nashvilleFlat5('b5', '${MusicConstants.flatChar}5'),
  nashville5('5', '5'),
  nashvilleFlat6('b6', '${MusicConstants.flatChar}6'),
  nashville6('6', '6'),
  nashvilleFlat7('b7', '${MusicConstants.flatChar}7'),
  nashville7('7', '7');

  const NashvilleNote(this._markup, this._string);

  //  counts from zero!
  static NashvilleNote byHalfStep(int offset) {
    return NashvilleNote.values[offset % MusicConstants.halfStepsPerOctave];
  }

  String toMarkup() {
    return _markup;
  }

  @override
  String toString() {
    return _string;
  }

  final String _string;
  final String _markup;
}

enum NashvilleRomanNote {
  roman1('I', 'I'),
  romanFlat2('bII', '${MusicConstants.flatChar}II'),
  roman2('II', 'II'),
  romanFlat3('bIII', '${MusicConstants.flatChar}III'),
  roman3('III', 'III'),
  roman4('IV', 'IV'),
  romanFlat5('bV', '${MusicConstants.flatChar}V'),
  roman5('V', 'V'),
  romanFlat6('bVI', '${MusicConstants.flatChar}VI'),
  roman6('VI', 'VI'),
  romanFlat7('bVII', '${MusicConstants.flatChar}VII'),
  roman7('VII', 'VII');

  const NashvilleRomanNote(this._markup, this._string);

  //  counts from zero!
  static NashvilleRomanNote byHalfStep(int offset) {
    return NashvilleRomanNote.values[offset % MusicConstants.halfStepsPerOctave];
  }

  String toMarkup() {
    return _markup;
  }

  @override
  String toString() {
    return _string;
  }

  final String _string;
  final String _markup;
}
