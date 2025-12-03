import 'dart:collection';

///  Generate a unique song identification string from a song's title, artist, and cover artist.
///
///  Special characters are eliminated.
///  Spaces are replaced with underscores.
///  Names starting with "The" have the "The" moved to the end.
class SongId implements Comparable<SongId> {
  /// For uninitialized values
  SongId.noArgs() : songIdAsString = '${prefix}Unknown_Song_by_Unknown';

  SongId.fromString(final String s) : songIdAsString = s {
    assert(songIdRegExp.hasMatch(songIdAsString));
  }

  /// Copy constructor
  SongId(this.songIdAsString);

  /// Generated song id from input [title], [artist], [coverArtist].
  /// Previously generated id's will be reused.
  SongId.computeSongId(String? title, String? artist, String? coverArtist)
      : songIdAsString = _findSongId('$prefix${_toSongId(title)}_by_${_toSongId(artist)}'
            '${coverArtist == null || coverArtist.isEmpty ? '' : '_coverBy_${_toSongId(coverArtist)}'}');

  /// Eliminate special characters. Replace spaces with an underscore.
  static String _toSongId(String? s) {
    if (s == null) {
      return 'unknown';
    }
    return correctSongId(s);
  }

  static String correctSongId(final String s) {
    return s
        .trim()
        .replaceAllMapped(notWordOrSpaceRegExp, (Match m) => '')
        .replaceAllMapped(dupUnderscoreOrSpaceRegExp, (Match m) => '_');
  }

  String toUnderScorelessString() =>
      _underScorelessId ??= songIdAsString.replaceFirst(prefix, '').replaceAll('_', ' '); //  note the lazy eval at ??=

  static String asReadableString(String songIdAsString) {
    return songIdAsString.replaceFirst(prefix, '').replaceAll('_', ' ').replaceAll(' The', ', The');
  }

  @override
  String toString() {
    return songIdAsString;
  }

  /// Compares this object with the specified object for order.
  @override
  int compareTo(SongId o) {
    if (identical(songIdAsString, o.songIdAsString)) {
      return 0;
    }
    return songIdAsString.compareTo(o.songIdAsString);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongId && runtimeType == other.runtimeType && songIdAsString == other.songIdAsString;

  @override
  int get hashCode => songIdAsString.hashCode;

  /// A prefix for all song id's to identify them as such.
  static const prefix = 'Song_';

  /// The song id as a generated string.
  final String songIdAsString;
  String? _underScorelessId;

  /// Method used to minimize the number of song id's generated
  static String _findSongId(String value) {
    if (!songIds.contains(value)) {
      songIds.add(value);
    }
    return value;
  }

  /// custom serialization: only the song id as string is needed to represent the id
  factory SongId.fromJsonString(String json) {
    return SongId(json);
  }

  /// custom serialization: only the song id as string is needed to represent the id
  String toJson() => songIdAsString;

  static final SplayTreeSet<String> songIds = SplayTreeSet();

  static final RegExp notWordOrSpaceRegExp = RegExp(r'[^\w\s]');
  static final RegExp dupUnderscoreOrSpaceRegExp = RegExp('[ _]+');
  static final RegExp songIdRegExp = RegExp('$prefix' r'[\w_]+_by_[\w_]+(_coverBy_[\w_]+)?$');
}
