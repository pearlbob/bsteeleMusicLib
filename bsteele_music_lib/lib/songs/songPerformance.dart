import 'dart:collection';
import 'dart:convert';

import 'package:bsteeleMusicLib/songs/song.dart';
import 'package:bsteeleMusicLib/util/util.dart';
import 'package:intl/intl.dart';
import 'package:quiver/core.dart';

import 'key.dart';
import 'musicConstants.dart';

final RegExp _multipleWhiteCharactersRegexp = RegExp('\\s+');

String _cleanPerformer(final String? value) {
  if (value == null) {
    return '';
  }
  return value.trim().replaceAll(_multipleWhiteCharactersRegexp, ' ');
}

class SongPerformance implements Comparable<SongPerformance> {
  SongPerformance(this._songIdAsString, final String singer, {Key? key, int? bpm, int? lastSung})
      : _lowerCaseSongIdAsString = _songIdAsString.toLowerCase(),
        _singer = _cleanPerformer(singer),
        _key = key ?? Key.getDefault(),
        _bpm = bpm ?? MusicConstants.defaultBpm,
        _lastSung = lastSung ?? DateTime.now().millisecondsSinceEpoch;

  SongPerformance.fromSong(final Song song, final String singer, {Key? key, int? bpm, int? lastSung})
      : _lowerCaseSongIdAsString = song.songId.toString().toLowerCase(),
        _singer = _cleanPerformer(singer),
        song = song,
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
    return first._lowerCaseSongIdAsString.compareTo(other._lowerCaseSongIdAsString);
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
        ', _bpm: $_bpm, sung: ${lastSungDateString}'
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
        _key = json['key'] is int ? Key.getKeyByHalfStep(json['key']) : Key.fromMarkup(json['key']),
        _bpm = json['bpm'],
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

    int ret = _lowerCaseSongIdAsString.compareTo(other._lowerCaseSongIdAsString);
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

  @override
  int get hashCode => _songIdAsString.hashCode ^ _singer.hashCode ^ _key.hashCode ^ _bpm.hashCode;

  Song? song;

  String get songIdAsString => _songIdAsString;
  final String _songIdAsString;

  String get lowerCaseSongIdAsString => _lowerCaseSongIdAsString;
  final String _lowerCaseSongIdAsString;

  String get singer => _singer;
  final String _singer;

  Key get key => _key;
  final Key _key;

  int get bpm => _bpm;
  final int _bpm;

  String get lastSungDateString =>
      _lastSung == 0 ? '' : DateFormat.yMd().format(DateTime.fromMillisecondsSinceEpoch(_lastSung));

  DateTime get lastSungDateTime => DateTime.fromMillisecondsSinceEpoch(_lastSung);

  int get lastSung => _lastSung;
  int _lastSung = 0;
}

class SongRequest implements Comparable<SongRequest> {
  SongRequest(this._songIdAsString, String requester)
      : _lowerCaseSongIdAsString = _songIdAsString.toLowerCase(),
        _requester = _cleanPerformer(requester);

  @override
  String toString() {
    return 'SongPerformance{song: $song, _songId: $_songIdAsString, _requester: \'$_requester\''
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

class AllSongPerformances {
  static final AllSongPerformances _singleton = AllSongPerformances._internal();

  factory AllSongPerformances() {
    return _singleton;
  }

  AllSongPerformances._internal();

  /// Populate song performance references with current songs
  void loadSongs(Iterable<Song> songs) {
    for (var song in songs) {
      songMap[song.songId.toString().toLowerCase()] = song;
    }

    for (var songPerformance in _allSongPerformances) {
      songPerformance.song = songMap[songPerformance._lowerCaseSongIdAsString];
    }

    for (var songPerformance in _allSongPerformanceHistory) {
      songPerformance.song = songMap[songPerformance._lowerCaseSongIdAsString];
    }

    for (var songRequest in _allSongPerformanceRequests) {
      songRequest.song = songMap[songRequest._lowerCaseSongIdAsString];
    }
  }

  /// add a song performance to the song history and add it if it was sung more recently than the current entry
  void addSongPerformance(SongPerformance songPerformance) {
    //  clear the previous song performance.  needed to change auxiliary data such as key and bpm
    _allSongPerformances.remove(songPerformance);

    _allSongPerformances.add(songPerformance);
    _allSongPerformanceHistory.add(songPerformance);
    songPerformance.song = songMap[songPerformance._lowerCaseSongIdAsString];
  }

  void addSongRequest(SongRequest songRequest) {
    songRequest.song = songMap[songRequest._lowerCaseSongIdAsString];
    _allSongPerformanceRequests.add(songRequest);
  }

  void removeSongRequest(SongRequest songRequest) {
    _allSongPerformanceRequests.remove(songRequest);
  }

  bool updateSongPerformance(SongPerformance songPerformance) {
    songPerformance.song = songMap[songPerformance._lowerCaseSongIdAsString];
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
    _singleton._fromJson(jsonDecode(jsonString));
  }

  void addFromJsonString(String jsonString) {
    var decoded = jsonDecode(jsonString);
    if (decoded is List<dynamic>) {
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
  int get hashCode => hash2(_allSongPerformances, _allSongPerformanceHistory);

  Map<String, Song> songMap = {};

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
