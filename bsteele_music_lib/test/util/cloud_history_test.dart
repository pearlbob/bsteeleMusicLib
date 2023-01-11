import 'dart:collection';
import 'dart:io';

import 'package:bsteeleMusicLib/app_logger.dart';
import 'package:bsteeleMusicLib/songs/song.dart';
import 'package:bsteeleMusicLib/songs/song_performance.dart';
import 'package:bsteeleMusicLib/util/util.dart';
import 'package:logger/logger.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:test/test.dart';

// const String _allSongPerformancesDirectoryLocation = 'communityJams/cj/Downloads';
// const String _junkRelativeDirectory = 'junk'; //  relative to user home
const String _allSongDirectory = 'github/allSongs.songlyrics';
const String _allSongPerformancesGithubFileLocation = '$_allSongDirectory/allSongPerformances.songperformances';
const String _allSongsFileLocation = '$_allSongDirectory/allSongs.songlyrics';
final _allSongsFile = File('${Util.homePath()}/$_allSongsFileLocation');
// final _allSongsMetadataFile = File('${Util.homePath()}/$_allSongDirectory/allSongs.songmetadata');
AllSongPerformances allSongPerformances = AllSongPerformances();
bool _verbose = false;
// int _updateCount = 0;

SplayTreeSet<Song> allSongs = SplayTreeSet();

void main() {
  test('test cloud history', () async {
    Logger.level = Level.info;

    //  see how well the singer performance history from the website matches the current song list
    logger.i('test cloud history:');
    _addAllSongsFromFile(_allSongsFile);
    //  add the github version
     allSongPerformances
        .updateFromJsonString(File('${Util.homePath()}/$_allSongPerformancesGithubFileLocation').readAsStringSync());
    await allSongPerformances.loadSongs(allSongs);
    logger.i('allSongs.length: ${allSongs.length}');
    logger.i('allSongPerformances.allSongPerformanceHistory.length:'
        ' ${allSongPerformances.allSongPerformanceHistory.length}');
    final List<Song> allSongList = allSongs.toList(growable: false);
    final List<String?> allSongIdList = allSongs.map((e) => e.songId.toString()).toList(growable: false);
    for (var perf in allSongPerformances.allSongPerformanceHistory) {
      logger.d('perf: ${perf.lowerCaseSongIdAsString}');
      if (perf.song == null) {
        logger.i('${perf.songIdAsString}: singer: ${perf.singer}, ${perf.lastSungDateTime}');
        BestMatch bestMatch = StringSimilarity.findBestMatch(perf.songIdAsString, allSongIdList);
        logger.i('       ${allSongList[bestMatch.bestMatchIndex]}, ${bestMatch.ratings.first.rating}');
        assert(false); //  all songs should get at least some match
      } else if (perf.lowerCaseSongIdAsString != perf.song?.songId.toString().toLowerCase()) {
        logger.i('Matched: $perf =>\n              ${perf.song}');
      }
    }
  });
}

void _addAllSongsFromFile(File inputFile) {
  logger.d('_addAllSongsFromFile: $inputFile');

  if (!inputFile.path.endsWith('.songlyrics')) return;
  if (_verbose) logger.i('$inputFile');

  //  fix for bad song lyric files
  String s = inputFile.readAsStringSync();
  s = s.replaceAll('": null,', '": "",');

  //  only add the most recent modification
  List<Song> addSongs = Song.songListFromJson(s);
  for (Song song in addSongs) {
    if (allSongs.contains(song)) {
      Song listSong = allSongs.firstWhere((value) => value.songId.compareTo(song.songId) == 0);
      if (song.lastModifiedTime > listSong.lastModifiedTime) {
        allSongs.remove(listSong);
        allSongs.add(song);
        // _updateCount++;
      }
    } else {
      allSongs.add(song);
    }
  }
}
