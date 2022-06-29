import 'dart:collection';
import 'dart:convert';

class SongId implements Comparable<SongId> {
  SongId.noArgs() : _songId = 'UnknownSong';

  SongId(this._songId);

  SongId.computeSongId(String? title, String? artist, String? coverArtist)
      : _songId = _findSongId(_prefix +
            _toSongId(title) +
            '_by_' +
            _toSongId(artist) +
            (coverArtist == null || coverArtist.isEmpty ? '' : '_coverBy_' + _toSongId(coverArtist)));

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
      _underScorelessId ??= _songId.replaceFirst(_prefix, '').replaceAll('_', ' '); //  note the lazy eval at ??=

  static String asReadableString(String songIdAsString) {
    return songIdAsString.replaceFirst(_prefix, '').replaceAll('_', ' ').replaceAll(' The', ', The');
  }

  @override
  String toString() {
    return _songId;
  }

  String toJson() {
    return jsonEncode(this);
  }

  /// Compares this object with the specified object for order.
  @override
  int compareTo(SongId o) {
    if (identical(_songId, o._songId)) {
      return 0;
    }
    return songId.compareTo(o.songId);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SongId && runtimeType == other.runtimeType && _songId == other._songId;

  @override
  int get hashCode => _songId.hashCode;

  static const _prefix = 'Song_';

  String get songId => _songId;
  final String _songId;
  String? _underScorelessId;

  static String _findSongId(String value) {
    if (!_songIds.contains(value)) {
      _songIds.add(value);
    }
    return value;
  }

  static final SplayTreeSet<String> _songIds = SplayTreeSet();

  static final RegExp notWordOrSpaceRegExp = RegExp(r'[^\w\s]');
  static final RegExp dupUnderscoreOrSpaceRegExp = RegExp('[ _]+');
}
