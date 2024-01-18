import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import '../util/us_timer.dart';
import '../util/util.dart';
import 'song.dart';
import 'song_id.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:string_similarity/string_similarity.dart';

import '../app_logger.dart';
import 'key.dart';
import 'music_constants.dart';

const Level _logPerformance = Level.debug;
const Level _logMatchDetails = Level.debug;
const Level _logLostSongs = Level.debug;
const Level _logListAllSongs = Level.debug;

final RegExp _multipleWhiteCharactersRegexp = RegExp('\\s+');

String _cleanPerformer(final String? value) {
  if (value == null) {
    return '';
  }
  return value.trim().replaceAll(_multipleWhiteCharactersRegexp, ' ');
}

class SongPerformance implements Comparable<SongPerformance> {
  SongPerformance(this._songIdAsString, final String singer, {Key? key, int? bpm, int? lastSung, Song? song})
      : _song = song,
        _lowerCaseSongIdAsString = _songIdAsString.toLowerCase(),
        _singer = _cleanPerformer(singer),
        _key = key ?? Key.getDefault(),
        _bpm = bpm ?? MusicConstants.defaultBpm,
        _lastSung = lastSung ?? DateTime.now().millisecondsSinceEpoch;

  SongPerformance.fromSong(Song song, final String singer, {Key? key, int? bpm, int? lastSung})
      : _song = song,
        _lowerCaseSongIdAsString = song.songId.toString().toLowerCase(),
        _singer = _cleanPerformer(singer),
        _songIdAsString = song.songId.toString(),
        _key = key ?? song.key,
        _bpm = bpm ?? song.beatsPerMinute,
        _lastSung = lastSung ?? DateTime.now().millisecondsSinceEpoch;

  SongPerformance update({Key? key, int? bpm}) {
    //  produce a copy with a new last sung date
    return SongPerformance(_songIdAsString, _singer, key: key ?? _key, bpm: bpm ?? _bpm, lastSung: null);
  }

  SongPerformance copy() {
    var ret = SongPerformance(_songIdAsString, singer, key: _key, bpm: bpm, lastSung: lastSung);
    ret.song = song;
    return ret;
  }

  static int _compareBySongId(SongPerformance first, SongPerformance other) {
    if (identical(first, other)) {
      return 0;
    }
    return first._songIdAsString.compareTo(other._songIdAsString);
  }

  static int compareBySongIdAndSinger(SongPerformance first, SongPerformance other) {
    int ret = _compareBySongId(first, other);
    if (ret != 0) {
      return ret;
    }
    ret = first._singer.compareTo(other._singer);
    if (ret != 0) {
      return ret;
    }
    return 0;
  }

  static int compareBySinger(SongPerformance first, SongPerformance other) {
    int ret = first._singer.compareTo(other._singer);
    if (ret != 0) {
      return ret;
    }

    ret = _compareBySongId(first, other);
    if (ret != 0) {
      return ret;
    }

    return 0;
  }

  static int compareByLastSungSongIdAndSinger(SongPerformance first, SongPerformance other) {
    if (identical(first, other)) {
      return 0;
    }
    int ret = first.lastSung.compareTo(other.lastSung);
    if (ret != 0) {
      return ret;
    }
    return compareBySongIdAndSinger(first, other);
  }

  @override
  String toString() {
    return 'SongPerformance{song: $song, _songId: $_songIdAsString, _singer: \'$_singer\', _key: $_key'
        ', _bpm: $_bpm, sung: $lastSungDateString'
        //' = $_lastSung'
        '}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongPerformance &&
          runtimeType == other.runtimeType &&
          _songIdAsString == other._songIdAsString &&
          _singer == other._singer &&
          _key == other._key &&
          _bpm == other._bpm;

  factory SongPerformance.fromJsonString(String jsonString) {
    return SongPerformance._fromJson(jsonDecode(jsonString));
  }

  SongPerformance._fromJson(Map<String, dynamic> json)
      : _songIdAsString = json['songId'],
        _lowerCaseSongIdAsString = json['songId'].toString().toLowerCase(),
        _singer = _cleanPerformer(json['singer']),
        _key = json['key'] == null
            ? Key.getDefault()
            : json['key'] is int
                ? Key.getKeyByHalfStep(json['key'])
                : Key.fromMarkup(json['key']),
        _bpm = json['bpm'] ?? MusicConstants.defaultBpm,
        _lastSung = json['lastSung'] ?? 0;

  String toJsonString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => {
        'songId': _songIdAsString,
        'singer': _singer,
        'key': _key.toMarkup(),
        'bpm': _bpm,
        'lastSung': _lastSung,
      };

  @override
  int compareTo(SongPerformance other) {
    if (identical(this, other)) {
      return 0;
    }

    int ret = _songIdAsString.compareTo(other._songIdAsString); //  exact
    if (ret != 0) {
      return ret;
    }
    ret = _singer.compareTo(other._singer);
    if (ret != 0) {
      return ret;
    }
    ret = _key.compareTo(other._key);
    if (ret != 0) {
      return ret;
    }
    ret = _bpm.compareTo(other._bpm);
    if (ret != 0) {
      return ret;
    }
    //  notice that lastSung is not included!  this is intentional
    return 0;
  }

  String _prepIdAsTitle() {
    return Util.underScoresToSpaceUpperCase(_songIdAsString.replaceAll(_songIdRegExp, ''))
        .replaceAll(' Cover By ', ' cover by ')
        .replaceAll(' By ', ' by ');
  }

  static final _songIdRegExp = RegExp('^${SongId.prefix}');

  @override
  int get hashCode => _songIdAsString.hashCode ^ _singer.hashCode ^ _key.hashCode ^ _bpm.hashCode;

  set song(Song? song) {
    if (song != null) {
      if (_song?.songId != song.songId) {
        _song = song;

        _songIdAsString = song.songId.toString();
        _lowerCaseSongIdAsString = _songIdAsString.toLowerCase();
      }
    }
  }

  Song? get song => _song;
  Song? _song;

  Song get performedSong => _song ?? (Song.theEmptySong.copySong()..title = _prepIdAsTitle());

  String get songIdAsString => _songIdAsString;
  String _songIdAsString;

  String get lowerCaseSongIdAsString => _lowerCaseSongIdAsString;
  String _lowerCaseSongIdAsString;

  String get singer => _singer;
  final String _singer;

  Key get key => _key;
  final Key _key;

  int get bpm => _bpm;
  final int _bpm;

  String get lastSungDateString => _lastSung == 0
      ? ''
      : DateFormat.yMd().format(DateTime.fromMillisecondsSinceEpoch(_lastSung)); // fixme: performance

  DateTime get lastSungDateTime => DateTime.fromMillisecondsSinceEpoch(_lastSung);

  int get lastSung => _lastSung;
  int _lastSung = 0;
}

class SongRequest implements Comparable<SongRequest> {
  SongRequest(this._songIdAsString, String requester, {this.song})
      : _lowerCaseSongIdAsString = _songIdAsString.toLowerCase(),
        _requester = _cleanPerformer(requester);

  SongRequest copyWith({String? songIdAsString, String? requester, Song? song}) {
    return SongRequest(songIdAsString ?? _songIdAsString, requester ?? _requester, song: song);
  }

  @override
  String toString() {
    return 'SongRequest{song: $song, _songId: $_songIdAsString, _requester: \'$_requester\''
        '}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongRequest &&
          runtimeType == other.runtimeType &&
          _songIdAsString == other._songIdAsString &&
          _requester == other._requester;

  factory SongRequest.fromJsonString(String jsonString) {
    return SongRequest._fromJson(jsonDecode(jsonString));
  }

  SongRequest._fromJson(Map<String, dynamic> json)
      : _songIdAsString = json['songId'],
        _lowerCaseSongIdAsString = json['songId'].toString().toLowerCase(),
        _requester = json['requester'];

  String toJsonString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => {
        'songId': _songIdAsString,
        'requester': _requester,
      };

  @override
  int compareTo(SongRequest other) {
    if (identical(this, other)) {
      return 0;
    }

    int ret = _requester.compareTo(other._requester);
    if (ret != 0) {
      return ret;
    }

    ret = _songIdAsString.compareTo(other._songIdAsString);
    if (ret != 0) {
      return ret;
    }

    //  notice that lastSung is not included!  this is intentional
    return 0;
  }

  @override
  int get hashCode => _songIdAsString.hashCode ^ _requester.hashCode;

  Song? song;

  String get songIdAsString => _songIdAsString;
  final String _songIdAsString;

  String get lowerCaseSongIdAsString => _lowerCaseSongIdAsString;
  final String _lowerCaseSongIdAsString;

  String get requester => _requester;
  final String _requester;
}

/// Find the best match against the current songs to replace songs where the song id has been changed.
class SongRepair {
  SongRepair(final Iterable<Song> songs) {
    for (var song in songs) {
      var key = song.songId.toString().toLowerCase();
      _songMap[key] = song;

      //  repair some old song names
      var key2 = repairMap[key];
      if (key2 != null) {
        _songMap[key2] = song;
      }
    }

    //  list the song map
    if (_logListAllSongs.index >= Level.info.index) {
      for (var key in _songMap.keys) {
        logger.log(_logListAllSongs, '$key: ${_songMap[key]?.songId.toString()}');
      }
    }
    _allLowerCaseIds = _songMap.keys.toList(growable: false);
  }

  Song? findBestSong(final String id) {
    var lowerCaseId = id.toLowerCase();
    var song = _songMap[lowerCaseId];
    if (song != null) {
      return song; //  no guessing required
    }

    if (_allLowerCaseIds.isEmpty) {
      return null;
    }

    //  find a soft match the expensive way
    misses++;
    BestMatch bestMatch = StringSimilarity.findBestMatch(lowerCaseId, _allLowerCaseIds);
    logger.log(
        _logMatchDetails,
        'match: "$id" to "${_allLowerCaseIds[bestMatch.bestMatchIndex]}"'
        ', rating: ${bestMatch.ratings[bestMatch.bestMatchIndex]}');
    song = _songMap[_allLowerCaseIds[bestMatch.bestMatchIndex]];
    if ((bestMatch.ratings[bestMatch.bestMatchIndex].rating ?? 0.0) > _matchRatingMinimum) {
      assert(song != null);
      return song;
    }
    logger.i('lost song: $id, ${bestMatch.ratings[bestMatch.bestMatchIndex].rating ?? 0.0}'
        ', best: ${song?.songId.toString()}'
        '\n     $song');
    return null;
  }

  static const Map<String, String> repairMap = {
    //  new song id: old song id
      'song_all_of_me_by_ruth_etting_coverby_frank_sinatra': 'song_all_of_me_by_sinatra',
      'song_for_no_one_by_beatles_the': 'song_for_no_one_by_emmy_lou_harris_orig_beatles',
      'song_lookin_out_my_back_door_by_creedence_clearwater_revival': 'song_lookin_out_my_back_door_by_john_fogerty',
      'song_spooky_by_classic_iv': 'song_spooky_by_atlanta_rhythm_section',
      'song_working_on_a_building_by_traditional_folk_song': 'song_working_on_a_building_by_african_american_spiritual',
      'song_blue_christmas_cover_by_elvis_presley_by_billy_hayes_and_jay_johnson':
          'song_blue_christmas_by_elvis_presley',
      'song_parting_glass_the_by_traditional_folk_song_coverby_ed_sheeran':
          'song_parting_glass_the_by_wailin_jeenys_lyrics',
      'song_winter_wonderland_by_guy_lombardo_johnny_mathis_et_al_at_christmas': 'song_winter_wonderland_by_christmas',
      'song_let_it_snow_by_vaughn_monroe_and_everybody_at_christmas': 'song_let_it_snow_by_christmas',
      'song_feliz_navidad_by_jos_feliciano': 'song_feliz_navidad_by_christmas',
    'song_blue_bayou_by_roy_orbison_coverby_linda_rondstadt': 'song_blue_bayou_by_roy_orbison',
    'song_sin_city_by_flying_burrito_brothers_the': 'song_sin_city_by_gram_parsons',
  };

  int misses = 0;
  static const _matchRatingMinimum = 0.70;
  late List<String> _allLowerCaseIds;
  final HashMap<String, Song> _songMap = HashMap();
}

class AllSongPerformances {
  static final AllSongPerformances _singleton = AllSongPerformances._internal();

  factory AllSongPerformances() {
    return _singleton;
  }

  //  only used for testing to avoid collisions of async use of the singleton
  AllSongPerformances.test();

  AllSongPerformances._internal();

  /// Populate song performance references with current songs
  int loadSongs(Iterable<Song> songs) {
    var usTimer = UsTimer();
    var corrections = 0;

    _songRepair = SongRepair(songs);

    //  fixme: a failed match can choose a wrong-ish "best match" if the song id has been changed too much

    //  find performance matches

    {
      List<SongPerformance> removals = [];
      List<SongPerformance> additions = [];
      for (var songPerformance in _allSongPerformances) {
        var newSong = _songRepair.findBestSong(songPerformance._lowerCaseSongIdAsString);
        if (newSong != null) {
          corrections += songPerformance.song != null && newSong.songId != songPerformance.song?.songId ? 1 : 0;
          if (songPerformance.song == null || newSong.songId != songPerformance.song?.songId) {
            removals.add(songPerformance);
            additions.add(songPerformance.copy()..song = newSong);
          }
        } else {
          logger.e('lost _allSongPerformances song: ${songPerformance.lowerCaseSongIdAsString}');
          //assert(false);
        }
      }
      _allSongPerformances.removeAll(removals);
      _allSongPerformances.addAll(additions);
    }
    logger.log(_logPerformance, '  matches: ${usTimer.deltaToString()}');

    //  find history matches
    {
      List<SongPerformance> removals = [];
      List<SongPerformance> additions = [];
      for (var songPerformance in _allSongPerformanceHistory) {
        var newSong = _songRepair.findBestSong(songPerformance._lowerCaseSongIdAsString);
        if (newSong != null) {
          corrections += (songPerformance.song != null && newSong.songId != songPerformance.song?.songId) ? 1 : 0;
          if (songPerformance.song == null || newSong.songId != songPerformance.song?.songId) {
            removals.add(songPerformance);
            additions.add(songPerformance.copy()..song = newSong);
          }
        } else {
          logger.e('lost _allSongPerformanceHistory: ${songPerformance.lowerCaseSongIdAsString}');
          // assert(false);
        }
      }
      logger.d('history: ${usTimer.deltaToString()} ${_allSongPerformanceHistory.length}'
          ', removals: ${removals.length}, additions: ${additions.length}');
      _allSongPerformanceHistory.removeAll(removals);
      _allSongPerformanceHistory.addAll(additions);
    }
    logger.log(_logPerformance, '  history: ${usTimer.deltaToString()} for ${_allSongPerformanceHistory.length}');

    //  find request matches
    {
      List<SongRequest> removals = [];
      List<SongRequest> additions = [];
      for (var songRequest in _allSongPerformanceRequests) {
        var newSong = _songRepair.findBestSong(songRequest._lowerCaseSongIdAsString);
        if (newSong != null) {
          corrections += songRequest.song != null && newSong.songId != songRequest.song?.songId ? 1 : 0;
          removals.add(songRequest);
          additions.add(songRequest.copyWith(song: newSong));
        } else {
          logger.log(_logLostSongs, 'lost _allSongPerformanceRequests: ${songRequest.lowerCaseSongIdAsString}');
          assert(false);
        }
      }
      _allSongPerformanceRequests.removeAll(removals);
      _allSongPerformanceRequests.addAll(additions);
    }
    logger.log(_logPerformance, '  requests: ${usTimer.deltaToString()}');

    logger.log(_logPerformance, 'loadSongs: $usTimer, corrections: $corrections');
    return corrections;
  }

  /// add a song performance to the song history and add it if it was sung more recently than the current entry
  void addSongPerformance(SongPerformance songPerformance) {
    //  clear the previous song performance.  needed to change auxiliary data such as key and bpm
    _allSongPerformances.remove(songPerformance);

    _allSongPerformances.add(songPerformance);
    _allSongPerformanceHistory.add(songPerformance);
    songPerformance.song = _songRepair.findBestSong(songPerformance._lowerCaseSongIdAsString);
  }

  void addSongRequest(SongRequest songRequest) {
    songRequest.song = _songRepair.findBestSong(songRequest._lowerCaseSongIdAsString);
    _allSongPerformanceRequests.add(songRequest);
  }

  void removeSongRequest(SongRequest songRequest) {
    _allSongPerformanceRequests.remove(songRequest);
  }

  bool updateSongPerformance(SongPerformance songPerformance) {
    songPerformance.song = _songRepair.findBestSong(songPerformance._lowerCaseSongIdAsString);
    _allSongPerformanceHistory.add(songPerformance);

    SongPerformance? original = _allSongPerformances.lookup(songPerformance);
    if (original == null) {
      _allSongPerformances.add(songPerformance);
      return true;
    }

    //  don't bother to compare performances, always use the most recent
    if (songPerformance.lastSung <= original.lastSung) {
      //  use the original since it's the same or newer
      return false;
    }

    addSongPerformance(songPerformance);
    return true;
  }

  SongPerformance? find({required final String singer, required final Song song}) {
    return findBySingerSongId(songIdAsString: song.songId.toString(), singer: singer);
  }

  SongPerformance? findBySingerSongId({required final String songIdAsString, required final String singer}) {
    try {
      var lowerSongIdAsString = songIdAsString.toLowerCase();
      return _allSongPerformances
          .firstWhere((e) => e.singer == singer && e._lowerCaseSongIdAsString == lowerSongIdAsString);
    } catch (e) {
      return null;
    }
  }

  List<SongPerformance> bySinger(final String singer) {
    List<SongPerformance> ret = [];
    ret.addAll(_allSongPerformances.where((songPerformance) {
      return songPerformance._singer == singer;
    }));
    return ret;
  }

  List<SongPerformance> bySong(Song song) {
    List<SongPerformance> ret = [];
    var lowerSongIdAsString = song.songId.toString().toLowerCase();
    ret.addAll(_allSongPerformances.where((songPerformance) {
      return songPerformance.songIdAsString.toLowerCase() == lowerSongIdAsString;
    }));
    return ret;
  }

  SplayTreeSet<String> setOfSingers() {
    SplayTreeSet<String> set = SplayTreeSet();
    set.addAll(_allSongPerformances.map((e) => e._singer));
    return set;
  }

  SplayTreeSet<String> setOfRequesters() {
    SplayTreeSet<String> set = SplayTreeSet();
    set.addAll(_allSongPerformanceRequests.map((e) => e._requester));
    return set;
  }

  bool isSongInSingersList(String singer, Song? song) {
    if (song == null) {
      return false;
    }
    return isSongIdInSingersList(singer, song.songId.toString());
  }

  bool isSongInRequestersList(String requester, Song? song) {
    if (song == null) {
      return false;
    }
    var requestedSongIdString = song.songId.toString().toLowerCase();
    return _allSongPerformanceRequests
        .any((e) => e._requester == requester && e._lowerCaseSongIdAsString == requestedSongIdString);
  }

  bool isSongIdInSingersList(String singer, String songIdString) {
    return _allSongPerformances.any((e) => e._singer == singer && e._songIdAsString == songIdString);
  }

  void removeSinger(String singer) {
    var songPerformances = _allSongPerformances.where((e) => e._singer == singer).toList(growable: false);
    _allSongPerformances.removeAll(songPerformances);
  }

  void removeSingerSong(String singer, String songIdAsString) {
    var songPerformances = _allSongPerformances
        .where((e) => e._singer == singer && e.songIdAsString == songIdAsString)
        .toList(growable: false);
    _allSongPerformances.removeAll(songPerformances);
  }

  void removeSingerSongHistory(SongPerformance songPerformance) {
    _allSongPerformanceHistory.remove(songPerformance);
  }

  void fromJsonString(String jsonString) {
    _allSongPerformances.clear();
    _fromJson(jsonDecode(jsonString));
  }

  void addFromJsonString(String jsonString) {
    var decoded = jsonDecode(jsonString);
    if (decoded is Map<String, dynamic>) {
      //  assume the items are song performances
      for (var item in decoded[allSongPerformanceHistoryName]) {
        var performance = SongPerformance._fromJson(item);
        _allSongPerformances.add(performance);
        _allSongPerformanceHistory.add(performance);
      }
    } else if (decoded is List<dynamic>) {
      //  assume the items are song performances
      for (var item in decoded) {
        var performance = SongPerformance._fromJson(item);
        _allSongPerformances.add(performance);
        _allSongPerformanceHistory.add(performance);
      }
    } else {
      throw 'addFromJsonString wrong json decode: ${decoded.runtimeType}';
    }
  }

  static const String allSongPerformancesName = 'allSongPerformances';
  static const String allSongPerformanceHistoryName = 'allSongPerformanceHistory';
  static const String allSongPerformanceRequestsName = 'allSongPerformanceRequests';

  int updateFromJsonString(String jsonString) {
    var usTimer = UsTimer();
    int count = 0;

    var decoded = jsonDecode(jsonString);
    if (decoded is Map<String, dynamic>) {
      //  assume the items are song performances
      for (var item in decoded[allSongPerformancesName] ?? []) {
        if (updateSongPerformance(SongPerformance._fromJson(item))) {
          count++;
        }
      }
      for (var item in decoded[allSongPerformanceHistoryName] ?? []) {
        _allSongPerformanceHistory.add(SongPerformance._fromJson(item));
      }
      for (var item in decoded[allSongPerformanceRequestsName] ?? []) {
        _allSongPerformanceRequests.add(SongRequest._fromJson(item));
      }
    } else if (decoded is List<dynamic>) {
      //  assume the items are song performances
      for (var item in decoded) {
        if (updateSongPerformance(SongPerformance._fromJson(item))) {
          count++;
        }
      }
    } else {
      throw 'updateFromJsonString wrong json decode: ${decoded.runtimeType}';
    }
    logger.log(_logPerformance,
        'updateFromJsonString: $usTimer, count: $count, requests: ${_allSongPerformanceRequests.length}');
    return count;
  }

  void _fromJson(Map<String, dynamic> json) {
    for (var songPerformanceJson in json[allSongPerformancesName]) {
      var performance = SongPerformance._fromJson(songPerformanceJson);
      _allSongPerformances.add(performance);
      _allSongPerformanceHistory.add(performance);
    }
    for (var songPerformanceJson in json[allSongPerformanceHistoryName]) {
      _allSongPerformanceHistory.add(SongPerformance._fromJson(songPerformanceJson));
    }
    for (var songRequestJson in json[allSongPerformanceRequestsName]) {
      _allSongPerformanceRequests.add(SongRequest._fromJson(songRequestJson));
    }
  }

  String toJsonString({bool prettyPrint = false}) {
    if (prettyPrint) {
      const JsonEncoder encoder = JsonEncoder.withIndent(' ');
      return Util.jsonEncodeNewLines(encoder.convert(this));
    }

    return Util.jsonEncodeNewLines(jsonEncode(this));
  }

  String toJsonStringFor(String singer) {
    return Util.jsonEncodeNewLines(jsonEncode(bySinger(singer)));
  }

  Map<String, dynamic> toJson() => {
        allSongPerformancesName: _allSongPerformances.toList(growable: false),
        allSongPerformanceHistoryName: _allSongPerformanceHistory.toList(growable: false),
        allSongPerformanceRequestsName: _allSongPerformanceRequests.toList(growable: false),
      };

  void clear() {
    _allSongPerformances.clear();
    _allSongPerformanceHistory.clear();
    _allSongPerformanceRequests.clear();
  }

  void clearAllSongPerformanceRequests() {
    _allSongPerformanceRequests.clear();
  }

  void readFileSync(File file) {
    String jsonString = file.path.endsWith('.gz')
        ? const Utf8Decoder().convert(GZipCodec().decoder.convert(file.readAsBytesSync()))
        : file.readAsStringSync();
    addFromJsonString(jsonString);
  }

  int get length => _allSongPerformances.length;

  bool get isEmpty => _allSongPerformances.isEmpty;

  bool get isNotEmpty => _allSongPerformances.isNotEmpty;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AllSongPerformances &&
            runtimeType == other.runtimeType &&
            _allSongPerformances.difference(other._allSongPerformances).isEmpty &&
            other._allSongPerformances.difference(_allSongPerformances).isEmpty &&
            _allSongPerformanceHistory.difference(other._allSongPerformanceHistory).isEmpty &&
            other._allSongPerformanceHistory.difference(_allSongPerformanceHistory).isEmpty;
  }

  @override
  int get hashCode => Object.hash(_allSongPerformances, _allSongPerformanceHistory);

  SongRepair get songRepair => _songRepair;
  SongRepair _songRepair = SongRepair([]);

  Iterable<SongPerformance> get allSongPerformances => _allSongPerformances;
  final SplayTreeSet<SongPerformance> _allSongPerformances =
      SplayTreeSet<SongPerformance>(SongPerformance.compareBySongIdAndSinger);

  Iterable<SongPerformance> get allSongPerformanceHistory => _allSongPerformanceHistory;
  final SplayTreeSet<SongPerformance> _allSongPerformanceHistory =
      SplayTreeSet<SongPerformance>(SongPerformance.compareByLastSungSongIdAndSinger);

  Iterable<SongRequest> get allSongPerformanceRequests => _allSongPerformanceRequests;
  final SplayTreeSet<SongRequest> _allSongPerformanceRequests = SplayTreeSet<SongRequest>();

  static const String fileExtension = '.songperformances'; //  intentionally all lower case
}
