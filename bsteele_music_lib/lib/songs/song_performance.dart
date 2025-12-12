import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:string_similarity/string_similarity.dart';

import '../app_logger.dart';
import '../util/us_timer.dart';
import '../util/util.dart';
import 'key.dart';
import 'music_constants.dart';
import 'song.dart';
import 'song_id.dart';

const Level _logPerformance = Level.debug;
const Level _logMatchDetails = Level.debug;
const Level _logLostSongs = Level.debug;
const Level _logListAllSongs = Level.debug;
const Level _logHistory = Level.debug;

final RegExp _multipleWhiteCharactersRegexp = RegExp('\\s+');

String _cleanPerformer(final String? value) {
  if (value == null) {
    return '';
  }
  return value.trim().replaceAll(_multipleWhiteCharactersRegexp, ' ');
}

class SongPerformance implements Comparable<SongPerformance> {
  SongPerformance(
    this._songIdAsString,
    final String singer, {
    Key? key,
    int? bpm,
    int? firstSung,
    int? lastSung,
    this.song,
  }) : _lowerCaseSongIdAsString = _songIdAsString.toLowerCase(),
       _singer = _cleanPerformer(singer),
       key = key ?? Key.getDefault(),
       _bpm = bpm ?? MusicConstants.defaultBpm,
       _firstSung = firstSung ?? lastSung ?? DateTime.now().millisecondsSinceEpoch,
       _lastSung = lastSung ?? DateTime.now().millisecondsSinceEpoch;

  SongPerformance.fromSong(Song this.song, final String singer, {Key? key, int? bpm, int? firstSung, int? lastSung})
    : _lowerCaseSongIdAsString = song.songId.toString().toLowerCase(),
      _singer = _cleanPerformer(singer),
      _songIdAsString = song.songId.toString(),
      key = key ?? song.key,
      _bpm = bpm ?? song.beatsPerMinute,
      _firstSung = firstSung ?? lastSung ?? DateTime.now().millisecondsSinceEpoch,
      _lastSung = lastSung ?? DateTime.now().millisecondsSinceEpoch;

  SongPerformance copyWith({
    final Song? song,
    final SongId? songId,
    final String? singer,
    int? firstSung,
    int? lastSung,
    Key? key,
    int? bpm,
  }) {
    var id = songId?.songIdAsString ?? song?.songId.toString() ?? _songIdAsString;
    var ret = SongPerformance(
      id,
      singer ?? this._singer,
      key: key ?? this.key,
      bpm: bpm ?? _bpm,
      firstSung: firstSung ?? _firstSung,
      lastSung: lastSung ?? _lastSung,
      song: song ?? this.song,
    );
    if (song != null) {
      assert(song.songId.toString() == ret._songIdAsString);
    }
    return ret;
  }

  static int compareByPerformance(SongPerformance first, SongPerformance other) {
    int ret = first.compareTo(other); //  does not include last sung
    return ret == 0 ? first._lastSung.compareTo(other._lastSung) : ret;
  }

  static int compareBySongId(SongPerformance first, SongPerformance other) {
    if (identical(first, other)) {
      return 0;
    }
    return first._songIdAsString.compareTo(other._songIdAsString);
  }

  static int compareBySongIdAndSinger(SongPerformance first, SongPerformance other) {
    int ret = compareBySongId(first, other);
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

    ret = compareBySongId(first, other);
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
    return 'SongPerformance{song: $song, _songId: $_songIdAsString, _singer: \'$_singer\', key: $key'
        ', _bpm: $_bpm'
        '${_firstSung < _lastSung ? ', first sung: $firstSungDateString' : ''}'
        ', last sung: $lastSungDateTimeString'
        //' = $_lastSung'
        '}';
  }

  String toShortString() {
    return '"${song ?? _songIdAsString}" sung by \'$_singer\' in $key, $_bpm bpm, $lastSungDateTimeString';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongPerformance &&
          runtimeType == other.runtimeType &&
          _songIdAsString == other._songIdAsString &&
          _singer == other._singer &&
          key == other.key &&
          _bpm == other._bpm;

  factory SongPerformance.fromJsonString(String jsonString) {
    return SongPerformance.fromJson(jsonDecode(jsonString));
  }

  SongPerformance.fromJson(Map<String, dynamic> json)
    : _songIdAsString = SongId.correctSongId(json['songId']),
      _lowerCaseSongIdAsString = SongId.correctSongId(json['songId']).toLowerCase(),
      _singer = _cleanPerformer(json['singer']),
      key = json['key'] == null || (json['key'] is String && (json['key'] as String).isEmpty)
          ? Key.getDefault()
          : json['key'] is int
          ? Key.getKeyByHalfStep(json['key'])
          : Key.fromMarkup(json['key']),
      _bpm = json['bpm'] ?? MusicConstants.defaultBpm,
      song = null,
      _lastSung = json['lastSung'] ?? 0 {
    _firstSung = _lastSung; //  first sung are all relative the list contents so they are not stored.
  }

  String toJsonString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => {
    'songId': _songIdAsString,
    'singer': _singer,
    'bpm': _bpm,
    'firstSung': _firstSung,
    'lastSung': _lastSung,
    'key': key.toMarkup(),
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
    ret = key.compareTo(other.key);
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
    return Util.underScoresToSpaceUpperCase(
      _songIdAsString.replaceAll(_songIdRegExp, ''),
    ).replaceAll(' Cover By ', ' cover by ').replaceAll(' By ', ' by ');
  }

  static final _songIdRegExp = RegExp('^${SongId.prefix}');

  @override
  int get hashCode => Object.hash(_songIdAsString, _singer, key, _bpm);

  final Song? song;

  Song get performedSong => song ?? (Song.theEmptySong.copySong()..title = _prepIdAsTitle());

  String get songIdAsString => _songIdAsString;
  final String _songIdAsString;

  String get lowerCaseSongIdAsString => _lowerCaseSongIdAsString;
  String _lowerCaseSongIdAsString;

  String get singer => _singer;
  final String _singer;

  final Key key;

  int get bpm => _bpm;
  final int _bpm;

  String get firstSungDateString =>
      _firstSung == 0 ? '' : DateFormat.yMd().format(DateTime.fromMillisecondsSinceEpoch(_firstSung));

  DateTime get firstSungDateTime => DateTime.fromMillisecondsSinceEpoch(_firstSung);

  String get lastSungDateString =>
      _lastSung == 0 ? '' : DateFormat.yMd().format(DateTime.fromMillisecondsSinceEpoch(_lastSung));

  static DateFormat yMdHmDateFormat = DateFormat.yMd().add_jm();
  static DateFormat yMdHmsDateFormat = DateFormat.yMd().add_Hms();

  String get lastSungDateTimeString =>
      _lastSung == 0 ? '' : yMdHmsDateFormat.format(DateTime.fromMillisecondsSinceEpoch(_lastSung));

  DateTime get lastSungDateTime => DateTime.fromMillisecondsSinceEpoch(_lastSung);

  int get firstSung => _firstSung; //  units: ms
  int _firstSung = 0;

  int get lastSung => _lastSung; //  units: ms
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
    return 'SongRequest{song: $song, _songId: $songIdAsString, _requester: \'$_requester\''
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
    return SongRequest.fromJson(jsonDecode(jsonString));
  }

  SongRequest.fromJson(Map<String, dynamic> json)
    : _songIdAsString = json['songId'],
      _lowerCaseSongIdAsString = json['songId'].toString().toLowerCase(),
      _requester = json['requester'];

  String toJsonString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => {'songId': _songIdAsString, 'requester': _requester};

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
      var key2 = repairMap[key]?.toLowerCase();
      if (key2 != null) {
        _songMap[key2] = song;
        _bestMatchesMap[key2] = song;
      }
    }

    //  list the song map
    if (_logListAllSongs.index >= Level.info.index) {
      for (var key in _songMap.keys) {
        logger.log(_logListAllSongs, '$key: ${_songMap[key]?.songId.toString()}');
      }
    }
    _allLowerCaseIds = _songMap.keys.toList();
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
      ', rating: ${bestMatch.ratings[bestMatch.bestMatchIndex]}',
    );
    song = _songMap[_allLowerCaseIds[bestMatch.bestMatchIndex]];
    if ((bestMatch.ratings[bestMatch.bestMatchIndex].rating ?? 0.0) > _matchRatingMinimum) {
      assert(song != null);
      song = song!;
      if (song.songId.songIdAsString.toLowerCase() != id) {
        _bestMatchesMap[id] = song;
      }
      return song;
    }
    logger.i(
      'lost song: $id, ${bestMatch.ratings[bestMatch.bestMatchIndex].rating ?? 0.0}'
      ', best: ${song?.songId.toString().toLowerCase()}\n'
      "   '${song?.songId.toString().toLowerCase()}':'${lowerCaseId}',"
      '\n     $song',
    );
    return null;
  }

  void addSong(final Song? song) {
    if (song != null) {
      var key = song.songId.toString().toLowerCase();
      _songMap[key] = song;
    }
  }

  bool removeSong(final Song? song) {
    var key = song?.songId.toString().toLowerCase() ?? '';
    return _songMap.remove(key) != null;
  }

  static const Map<String, String> repairMap = {
    //  new song id: old song id
    'song_all_of_me_by_ruth_etting_coverby_frank_sinatra': 'song_all_of_me_by_sinatra',
    'song_for_no_one_by_beatles_the': 'song_for_no_one_by_emmy_lou_harris_orig_beatles',
    'song_lookin_out_my_back_door_by_creedence_clearwater_revival': 'song_lookin_out_my_back_door_by_john_fogerty',
    'song_spooky_by_classic_iv': 'song_spooky_by_atlanta_rhythm_section',
    'song_working_on_a_building_by_traditional_folk_song': 'song_working_on_a_building_by_african_american_spiritual',
    'song_blue_christmas_cover_by_elvis_presley_by_billy_hayes_and_jay_johnson': 'song_blue_christmas_by_elvis_presley',
    'song_parting_glass_the_by_traditional_folk_song_coverby_ed_sheeran':
        'song_parting_glass_the_by_wailin_jeenys_lyrics',
    'song_winter_wonderland_by_guy_lombardo_johnny_mathis_et_al_at_christmas': 'song_winter_wonderland_by_christmas',
    'song_let_it_snow_by_vaughn_monroe_and_everybody_at_christmas': 'song_let_it_snow_by_christmas',
    'song_feliz_navidad_by_jos_feliciano': 'song_feliz_navidad_by_christmas',
    'song_blue_bayou_by_roy_orbison_coverby_linda_rondstadt': 'song_blue_bayou_by_roy_orbison',
    'song_sin_city_by_flying_burrito_brothers_the': 'song_sin_city_by_gram_parsons',
    'song_down_home_girl_by_alvin_robinson_coverby_old_crow_medicine_show': 'song_down_home_girl_by_alvin_robinson',
    'song_hard_sun_by_indio_coverby_eddie_vedder': 'song_hard_sun_by_indio',
    'song_hey_joe_by_various_coverby_jimi_hendrix': 'song_hey_joe_by_various',
    'song_killing_the_blues_by_rowland_salley_coverby_robert_plant_and_alison_krauss':
        'song_killing_the_blues_by_rowland_salley',
    'song_i_love_rock_n_roll_by_arrows_coverby_joan_jett_the_blackhearts': 'song_i_love_rock__n__roll_by_arrows',
    'song_gone_gone_gone_by_everly_brothers_the_coverby_robert_plant_alison_krauss':
        'song_gone_gone_gone_by_everly_brothers__the',
    'song_heart_on_a_string_by_candi_staton_coverby_jason_isbell_and_the_400_unit':
        'song_heart_on_a_string_by_candi_staton',
    'song_alone_by_iten_coverby_heart': 'song_alone_by_i_ten',
    'song_valerie_by_zutons_the_coverby_mark_ronson_and_amy_winehouse': 'song_valerie_by_zutons__the',
    'song_my_back_pages_by_bob_dylan_coverby_roger_mcguinn_tom_petty_neil_young_eric_clapton_bob_dylan_george_harrison':
        'song_my_back_pages_by_bob_dylan',
    'song_i_go_blind_by_5440_coverby_hootie_the_blowfish': 'song_i_go_blind_by_54_40',
    'song_mary_had_a_little_lamb_by_buddy_guy_coverby_stevie_ray_vaughan_and_double_trouble':
        'song_mary_had_a_little_lamb_by_buddy_guy',
    'song_who_do_you_love_by_bo_diddley_coverby_george_thorogood_the_destroyers': 'song_who_do_you_love__by_bo_diddley',
    'song_its_so_easy_by_crickets_the_coverby_linda_ronstadt': 'song_it_s_so_easy_by_crickets__the',
    'song_respect_by_otis_redding_coverby_aretha_franklin': 'song_respect_by_otis_redding',
    'song_words_of_love_by_buddy_holly_coverby_mamas_the_papas_the': 'song_words_of_love_by_mamas_and_papas',
  };

  int misses = 0;
  static const _matchRatingMinimum = 0.70;
  late List<String> _allLowerCaseIds = [];
  final HashMap<String, Song> _songMap = HashMap();

  HashMap<String, Song> get bestMatchesMap => _bestMatchesMap;
  final HashMap<String, Song> _bestMatchesMap = HashMap();
}

class AllSongPerformances {
  AllSongPerformances();

  //  only used for testing to avoid collisions of async use of the singleton
  AllSongPerformances.test();

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
        var newSong = _songRepair.findBestSong(songPerformance.songIdAsString);
        if (newSong != null) {
          corrections += songPerformance.song != null && newSong.songId != songPerformance.song?.songId ? 1 : 0;
          if (songPerformance.song == null || newSong.songId != songPerformance.song?.songId) {
            removals.add(songPerformance);
            var copy = songPerformance.copyWith(song: newSong);
            additions.add(copy);
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
      _missingSongsFromPerformanceHistory.clear();
      for (var songPerformance in _allSongPerformanceHistory) {
        var newSong = _songRepair.findBestSong(songPerformance._lowerCaseSongIdAsString);
        if (newSong != null) {
          corrections += (songPerformance.song != null && newSong.songId != songPerformance.song?.songId) ? 1 : 0;
          if (songPerformance.song == null || newSong.songId != songPerformance.song?.songId) {
            removals.add(songPerformance);
            additions.add(songPerformance.copyWith(song: newSong));
          }
        } else {
          logger.e('lost _allSongPerformanceHistory: ${songPerformance.lowerCaseSongIdAsString}');
          _missingSongsFromPerformanceHistory.add(songPerformance);
          // assert(false);
        }
      }
      logger.log(
        _logHistory,
        'history: ${usTimer.deltaToString()} ${_allSongPerformanceHistory.length}'
        ', removals: ${removals.length}, additions: ${additions.length}',
      );
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
          // assert(false);
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
  SongPerformance addSongPerformance(final SongPerformance songPerformance) {
    var newSong = _songRepair.findBestSong(songPerformance._lowerCaseSongIdAsString);
    if (newSong != null) {
      //  clear the previous song performance.  needed to change auxiliary data such as key and bpm
      _allSongPerformances.remove(songPerformance);
      var newPerformance = songPerformance.copyWith(song: newSong);
      _allSongPerformances.add(newPerformance);
      _allSongPerformanceHistory.add(newPerformance);
      return newPerformance;
    }
    if (_allSongPerformances.contains(songPerformance)) {
      _allSongPerformances.remove(songPerformance);
    }
    _allSongPerformances.add(songPerformance);
    _allSongPerformanceHistory.add(songPerformance);
    return songPerformance;
  }

  /// remove a song performance to the song history and add it if it was sung more recently than the current entry
  bool removeSongPerformance(final SongPerformance songPerformance) {
    //  clear the previous song performance.  needed to change auxiliary data such as key and bpm
    var ret = _allSongPerformances.remove(songPerformance);
    if (ret) {
      _allSongPerformanceHistory.remove(songPerformance);
      songRepair.removeSong(songPerformance.song);
    }
    return ret;
  }

  void addSongRequest(SongRequest songRequest) {
    songRequest.song = _songRepair.findBestSong(songRequest._lowerCaseSongIdAsString);
    _allSongPerformanceRequests.add(songRequest);
  }

  void removeSongRequest(SongRequest songRequest) {
    _allSongPerformanceRequests.remove(songRequest);
  }

  bool updateSongPerformance(final SongPerformance songPerformance) {
    var newPerformance = songPerformance.copyWith(
      song: _songRepair.findBestSong(songPerformance._lowerCaseSongIdAsString),
    );
    _allSongPerformanceHistory.add(newPerformance);

    SongPerformance? original = _allSongPerformances.lookup(newPerformance);
    if (original == null) {
      _allSongPerformances.add(newPerformance);
      return true;
    }

    //  don't bother to compare performances, always use the most recent
    if (newPerformance.lastSung <= original.lastSung) {
      //  use the original since it's the same or newer
      //  update first sung
      addSongPerformance(original.copyWith(firstSung: min(original._firstSung, songPerformance.lastSung)));
      return false;
    }
    newPerformance = newPerformance.copyWith(firstSung: min(original._firstSung, songPerformance.lastSung));
    addSongPerformance(newPerformance);
    return true;
  }

  SongPerformance? find({required final String singer, required final Song song}) {
    return findBySingerSongId(songIdAsString: song.songId.toString(), singer: singer);
  }

  SongPerformance? findBySingerSongId({required final String songIdAsString, required final String singer}) {
    try {
      var lowerSongIdAsString = songIdAsString.toLowerCase();
      return _allSongPerformances.firstWhere(
        (e) => e.singer == singer && e._lowerCaseSongIdAsString == lowerSongIdAsString,
      );
    } catch (e) {
      return null;
    }
  }

  List<SongPerformance> bySinger(final String singer) {
    List<SongPerformance> ret = [];
    ret.addAll(
      _allSongPerformances.where((songPerformance) {
        return songPerformance._singer == singer;
      }),
    );
    return ret;
  }

  List<SongPerformance> bySong(Song song) {
    List<SongPerformance> ret = [];
    var lowerSongIdAsString = song.songId.toString().toLowerCase();
    ret.addAll(
      _allSongPerformances.where((songPerformance) {
        return songPerformance.songIdAsString.toLowerCase() == lowerSongIdAsString;
      }),
    );
    return ret;
  }

  SplayTreeSet<String> setOfSingers() {
    SplayTreeSet<String> set = SplayTreeSet();
    set.addAll(_allSongPerformances.map((e) => e._singer));
    return set;
  }

  SplayTreeSet<SongRequest> setOfRequestsBySong(Song song) {
    SplayTreeSet<SongRequest> set = SplayTreeSet();
    set.addAll(_allSongPerformanceRequests.where((e) => e.song == song));
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
    return _allSongPerformanceRequests.any(
      (e) => e._requester == requester && e._lowerCaseSongIdAsString == requestedSongIdString,
    );
  }

  bool isSongIdInSingersList(String singer, String songIdString) {
    return _allSongPerformances.any((e) => e._singer == singer && e.songIdAsString == songIdString);
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

  bool removeSingerSongHistory(SongPerformance songPerformance) {
    return _allSongPerformanceHistory.remove(songPerformance);
  }

  void rebuildAllPerformancesFromHistory({final int lastSungLimitMs = 0 /* since epoch */}) {
    //  limit history as well
    if (lastSungLimitMs > 0) {
      final SplayTreeSet<SongPerformance> newHistory = SplayTreeSet(SongPerformance.compareByLastSungSongIdAndSinger);
      for (var songPerformance in _allSongPerformanceHistory) {
        if (songPerformance.lastSung >= lastSungLimitMs) {
          newHistory.add(songPerformance);
        }
      }
      _allSongPerformanceHistory.clear();
      _allSongPerformanceHistory.addAll(newHistory);
    }

    //  sort the history with most recent first, then add to song performances
    SplayTreeSet<SongPerformance> uniqueSongIdAndSinger = SplayTreeSet(
      (song1, song2) => SongPerformance.compareBySongIdAndSinger(song1, song2),
    );
    for (var songPerformance in _allSongPerformanceHistory.sorted(
      (perf1, perf2) => -perf1.lastSung.compareTo(perf2.lastSung),
    )) {
      uniqueSongIdAndSinger.add(songPerformance);
    }
    _allSongPerformances.clear();
    _allSongPerformances.addAll(uniqueSongIdAndSinger);

    logger.i('_allSongPerformanceHistory.length: ${_allSongPerformanceHistory.length}');
    logger.i('uniqueSongIdAndSinger.length: ${uniqueSongIdAndSinger.length}');
  }

  void fromJsonString(String jsonString) {
    _allSongPerformances.clear();
    fromJson(jsonDecode(jsonString));
  }

  void addFromJsonString(String jsonString) {
    var decoded = jsonDecode(jsonString);
    if (decoded is Map<String, dynamic>) {
      //  assume the items are song performances
      for (var item in decoded[allSongPerformanceHistoryName]) {
        var performance = SongPerformance.fromJson(item);
        _allSongPerformances.add(performance);
        _allSongPerformanceHistory.add(performance);
      }
    } else if (decoded is List<dynamic>) {
      //  assume the items are song performances
      for (var item in decoded) {
        var performance = SongPerformance.fromJson(item);
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
        if (updateSongPerformance(SongPerformance.fromJson(item))) {
          count++;
        }
      }
      for (var item in decoded[allSongPerformanceHistoryName] ?? []) {
        _allSongPerformanceHistory.add(SongPerformance.fromJson(item));
      }
      for (var item in decoded[allSongPerformanceRequestsName] ?? []) {
        _allSongPerformanceRequests.add(SongRequest.fromJson(item));
      }
    } else if (decoded is List<dynamic>) {
      //  assume the items are song performances
      for (var item in decoded) {
        if (updateSongPerformance(SongPerformance.fromJson(item))) {
          count++;
        }
      }
    } else {
      throw 'updateFromJsonString wrong json decode: ${decoded.runtimeType}';
    }
    logger.log(
      _logPerformance,
      'updateFromJsonString: $usTimer, count: $count, requests: ${_allSongPerformanceRequests.length}',
    );
    return count;
  }

  void fromJson(Map<String, dynamic> json) {
    for (var songPerformanceJson in json[allSongPerformancesName]) {
      var performance = SongPerformance.fromJson(songPerformanceJson);
      _allSongPerformances.add(performance);
      _allSongPerformanceHistory.add(performance);
    }
    for (var songPerformanceJson in json[allSongPerformanceHistoryName]) {
      _allSongPerformanceHistory.add(SongPerformance.fromJson(songPerformanceJson));
    }
    for (var songRequestJson in json[allSongPerformanceRequestsName]) {
      _allSongPerformanceRequests.add(SongRequest.fromJson(songRequestJson));
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
    _missingSongsFromPerformanceHistory.clear();
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

  HashMap<String, Song> get bestMatchesMap => _songRepair.bestMatchesMap;

  HashMap<String, Song> get songRepairMap => _songRepairMap;
  HashMap<String, Song> _songRepairMap = HashMap();

  Iterable<SongPerformance> get allSongPerformances => _allSongPerformances;
  final SplayTreeSet<SongPerformance> _allSongPerformances = SplayTreeSet<SongPerformance>(
    SongPerformance.compareBySongIdAndSinger,
  );

  Set<SongPerformance> historyDifference(final AllSongPerformances other) {
    return _allSongPerformanceHistory.difference(other._allSongPerformanceHistory);
  }

  Iterable<SongPerformance> get allSongPerformanceHistory => _allSongPerformanceHistory;
  final SplayTreeSet<SongPerformance> _allSongPerformanceHistory = SplayTreeSet(
    SongPerformance.compareByLastSungSongIdAndSinger,
  );

  Iterable<SongPerformance> get missingSongsFromPerformanceHistory => _missingSongsFromPerformanceHistory;
  final SplayTreeSet<SongPerformance> _missingSongsFromPerformanceHistory = SplayTreeSet<SongPerformance>(
    SongPerformance.compareByLastSungSongIdAndSinger,
  );

  Iterable<SongRequest> get allSongPerformanceRequests => _allSongPerformanceRequests;
  final SplayTreeSet<SongRequest> _allSongPerformanceRequests = SplayTreeSet<SongRequest>();

  static const String fileExtension = '.songperformances'; //  intentionally all lower case
}
