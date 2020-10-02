import 'dart:convert';

class SongId implements Comparable<SongId> {
  SongId.noArgs() : _songId = 'UnknownSong';

  SongId(this._songId);

  SongId.computeSongId(String title, String artist, String coverArtist)
      : _songId = 'Song_' +
            _toSongId(title) +
            '_by_' +
            _toSongId(artist) +
            (coverArtist == null || coverArtist.isEmpty ? '' : '_coverBy_' + _toSongId(coverArtist));

  static String _toSongId(String s) {
    return s
        .trim()
        .replaceAllMapped(notWordOrSpaceRegExp, (Match m) => '')
        .replaceAllMapped(dupUnderscoreOrSpaceRegExp, (Match m) => '_');
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
    return songId.compareTo(o.songId);
  }

  String get songId => _songId;
  final String _songId;

  static final RegExp notWordOrSpaceRegExp = RegExp(r'[^\w\s]');
  static final RegExp dupUnderscoreOrSpaceRegExp = RegExp('[ _]+');
}
