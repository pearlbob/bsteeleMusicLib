import 'package:bsteele_music_lib/songs/song.dart';
import 'package:bsteele_music_lib/songs/song_id.dart';

class SongListItem {
  SongListItem(this.title, this.artist, this.coverArtist) {
    songId = SongId.computeSongId(title, artist, coverArtist);
  }

  SongListItem.fromSong(final Song song) : this(song.title, song.artist, song.coverArtist);

  Map<String, dynamic> toJson() => {'songId': songId, 'title': title, 'artist': artist, 'coverArtist': coverArtist};

  factory SongListItem.fromJson(Map<String, dynamic> json) {
    return SongListItem(json['title'], json['artist'], json['coverArtist']);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongListItem &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          artist == other.artist &&
          coverArtist == other.coverArtist &&
          songId == other.songId;

  @override
  int get hashCode => Object.hash(title, artist, coverArtist, songId);

  @override
  String toString() {
    return 'SongListItem{title: $title, artist: $artist, coverArtist: $coverArtist, songId: $songId}';
  }

  final String title;
  final String artist;
  final String? coverArtist;
  late final SongId songId;
}
