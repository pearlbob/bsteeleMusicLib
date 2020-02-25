class SongId implements Comparable<SongId> {
  SongId.noArgs() : _songId = "UnknownSong";

  SongId(this._songId);

  @override
  String toString() {
    return _songId;
  }

  /// Compares this object with the specified object for order.
  @override
  int compareTo(SongId o) {
    return songId.compareTo(o.songId);
  }

  String get songId => _songId;
  final String _songId;
}
