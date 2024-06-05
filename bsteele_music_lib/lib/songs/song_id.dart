import 'dart:collection';

import 'package:json_annotation/json_annotation.dart';

part 'song_id.g.dart';

@JsonSerializable()
class SongId implements Comparable<SongId> {
  SongId.noArgs() : songId = 'UnknownSong';

  SongId(this.songId);

  SongId.computeSongId(String? title, String? artist, String? coverArtist)
      : songId = _findSongId('$prefix${_toSongId(title)}_by_${_toSongId(artist)}'
            '${coverArtist == null || coverArtist.isEmpty ? '' : '_coverBy_${_toSongId(coverArtist)}'}');

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

  static const prefix = 'Song_';

  final String songId;
  String? _underScorelessId;

  static String _findSongId(String value) {
    if (!songIds.contains(value)) {
      songIds.add(value);
    }
    return value;
  }

  // custom serialization: only the key enum need represent the id in a song id context
  factory SongId.fromJson(String json) {
    return SongId(json);
  }

  // custom serialization: only the key enum need represent the id in a song id context
  String toJson() => songId;

  static final SplayTreeSet<String> songIds = SplayTreeSet();

  static final RegExp notWordOrSpaceRegExp = RegExp(r'[^\w\s]');
  static final RegExp dupUnderscoreOrSpaceRegExp = RegExp('[ _]+');
}
