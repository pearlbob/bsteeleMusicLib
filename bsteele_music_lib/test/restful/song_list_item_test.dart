import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/restful/song_list_item.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('test song list items', () {
    for (var title in ['A song', 'Another Song', 'A difficult`n song to title!']) {
      for (var artist in ['bob', 'bodhi', 'Shari']) {
        for (var coverArtist in [null, 'Lizard Man']) {
          SongListItem item = SongListItem(title, artist, coverArtist);
          logger.i('item: $item');
          expect(SongListItem.fromJson(item.toJson()), item);
        }
      }
    }
  });
}
