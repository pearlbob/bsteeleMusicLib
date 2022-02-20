import 'dart:convert';

class SongId implements Comparable<SongId> {
  SongId.noArgs() : _songId = 'UnknownSong';

  SongId(this._songId);

  SongId.computeSongId(String? title, String? artist, String? coverArtist)
      : _songId = _prefix +
            _toSongId(title) +
            '_by_' +
            _toSongId(artist) +
            (coverArtist == null || coverArtist.isEmpty ? '' : '_coverBy_' + _toSongId(coverArtist));

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
    return songId.compareTo(o.songId);
  }

  static const _prefix = 'Song_';

  String get songId => _songId;
  final String _songId;
  String? _underScorelessId;

  static final RegExp notWordOrSpaceRegExp = RegExp(r'[^\w\s]');
  static final RegExp dupUnderscoreOrSpaceRegExp = RegExp('[ _]+');
}
