import 'dart:collection';

import 'package:json_annotation/json_annotation.dart';

part 'song_id.g.dart';

///  Generate a unique song identification string from a song's title, artist, and cover artist.
///
///  Special characters are eliminated.
///  Spaces are replaced with underscores.
///  Names starting with "The" have the "The" moved to the end.
@JsonSerializable()
class SongId implements Comparable<SongId> {
  /// For uninitialized values
  SongId.noArgs() : songId = 'UnknownSong';

  /// Copy constructor
  SongId(this.songId);

  /// Generated song id from input [title], [artist], [coverArtist].
  /// Previously generated id's will be reused.
  SongId.computeSongId(String? title, String? artist, String? coverArtist)
      : songId = _findSongId('$prefix${_toSongId(title)}_by_${_toSongId(artist)}'
            '${coverArtist == null || coverArtist.isEmpty ? '' : '_coverBy_${_toSongId(coverArtist)}'}');

  /// Eliminate special characters. Replace spaces with an underscore.
  static String _toSongId(String? s) {
    if (s == null) {
      return 'unknown';
    }
    return s
        .trim()
        .replaceAllMapped(notWordOrSpaceRegExp, (Match m) => '')
        .replaceAllMapped(dupUnderscoreOrSpaceRegExp, (Match m) => '_');
  }

  String toUnderScorelessString() =>
      _underScorelessId ??= songId.replaceFirst(prefix, '').replaceAll('_', ' '); //  note the lazy eval at ??=

  static String asReadableString(String songIdAsString) {
    return songIdAsString.replaceFirst(prefix, '').replaceAll('_', ' ').replaceAll(' The', ', The');
  }

  @override
  String toString() {
    return songId;
  }

  /// Compares this object with the specified object for order.
  @override
  int compareTo(SongId o) {
    if (identical(songId, o.songId)) {
      return 0;
    }
    return songId.compareTo(o.songId);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SongId && runtimeType == other.runtimeType && songId == other.songId;

  @override
  int get hashCode => songId.hashCode;

  /// A prefix for all song id's to identify them as such.
  static const prefix = 'Song_';

  /// The song id as a generated string.
  final String songId;
  String? _underScorelessId;

  /// Method used to minimize the number of song id's generated
  static String _findSongId(String value) {
    if (!songIds.contains(value)) {
      songIds.add(value);
    }
    return value;
  }

  /// custom serialization: only the song id as string is needed to represent the id
  factory SongId.fromJson(String json) {
    return SongId(json);
  }

  /// custom serialization: only the song id as string is needed to represent the id
  String toJson() => songId;

  static final SplayTreeSet<String> songIds = SplayTreeSet();

  static final RegExp notWordOrSpaceRegExp = RegExp(r'[^\w\s]');
  static final RegExp dupUnderscoreOrSpaceRegExp = RegExp('[ _]+');
}
