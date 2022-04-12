import 'dart:collection';
import 'dart:convert';

import 'package:bsteeleMusicLib/songs/song.dart';
import 'package:bsteeleMusicLib/util/util.dart';
import 'package:intl/intl.dart';
import 'package:quiver/core.dart';

import 'key.dart';
import 'musicConstants.dart';

class SongPerformance implements Comparable<SongPerformance> {
  SongPerformance(this._songIdAsString, final String singer, this._key, {int? bpm, int? lastSung})
      : _singer = _cleanSinger(singer),
        _bpm = bpm ?? MusicConstants.defaultBpm,
        _lastSung = lastSung ?? DateTime.now().millisecondsSinceEpoch;

  SongPerformance.fromSong(Song song, final String singer, this._key, {int? bpm, int? lastSung})
      : _singer = _cleanSinger(singer),
        song = song,
        _songIdAsString = song.songId.toString(),
        _bpm = bpm ?? song.beatsPerMinute,
        _lastSung = lastSung ?? DateTime.now().millisecondsSinceEpoch;

  SongPerformance update({Key? key, int? bpm}) {
    //  produce a copy with a new last sung date
    return SongPerformance(_songIdAsString, _singer, key ?? _key, bpm: bpm ?? _bpm, lastSung: null);
  }

  static int compareBySongIdAndSinger(SongPerformance first, SongPerformance other) {
    if (identical(first, other)) {
      return 0;
    }
    int ret = first._songIdAsString.compareTo(other._songIdAsString);
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
        _singer = _cleanSinger(json['singer']),
        _key = Key.getKeyByHalfStep(json['key']),
        _bpm = json['bpm'],
        _lastSung = json['lastSung'] ?? 0;

  String toJsonString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => {
        'songId': _songIdAsString,
        'singer': _singer,
        'key': _key.halfStep,
        'bpm': _bpm,
        'lastSung': _lastSung,
      };

  @override
  int compareTo(SongPerformance other) {
    if (identical(this, other)) {
      return 0;
    }

    int ret = _songIdAsString.compareTo(other._songIdAsString);
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

  static final RegExp _multipleWhiteCharactersRegexp = RegExp('\\s+');

  static String _cleanSinger(final String value) {
    return value.trim().replaceAll(_multipleWhiteCharactersRegexp, ' ');
  }

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

class AllSongPerformances {
  static final AllSongPerformances _singleton = AllSongPerformances._internal();

  factory AllSongPerformances() {
    return _singleton;
  }

  AllSongPerformances._internal();

  /// Populate song performance references with current songs
  void loadSongs(Iterable<Song> songs) {
    for (var song in songs) {
      songMap[song.songId.toString()] = song;
    }

    for (var songPerformance in _allSongPerformances) {
      songPerformance.song = songMap[songPerformance._songIdAsString];
    }

    for (var songPerformance in _allSongPerformanceHistory) {
      songPerformance.song = songMap[songPerformance._songIdAsString];
    }
  }

  /// add a song performance to the song history and add it if it was sung more recently than the current entry
  void addSongPerformance(SongPerformance songPerformance) {
    //  clear the previous song performance.  needed to change auxiliary data such as key and bpm
    _allSongPerformances.remove(songPerformance);

    _allSongPerformances.add(songPerformance);
    _allSongPerformanceHistory.add(songPerformance);
    songPerformance.song = songMap[songPerformance._songIdAsString];
  }

  bool updateSongPerformance(SongPerformance songPerformance) {
    songPerformance.song = songMap[songPerformance._songIdAsString];
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

  List<SongPerformance> bySinger(String singer) {
    List<SongPerformance> ret = [];
    ret.addAll(_allSongPerformances.where((songPerformance) {
      return songPerformance._singer == singer;
    }));
    return ret;
  }

  List<SongPerformance> bySong(Song song) {
    List<SongPerformance> ret = [];
    var songIdString = song.songId.toString();
    ret.addAll(_allSongPerformances.where((songPerformance) {
      return songPerformance.songIdAsString == songIdString;
    }));
    return ret;
  }

  SplayTreeSet<String> setOfSingers() {
    SplayTreeSet<String> set = SplayTreeSet();
    set.addAll(_allSongPerformances.map((e) => e._singer));
    return set;
  }

  bool isSongInSingersList(String singer, Song? song) {
    if (song == null) {
      return false;
    }
    return isSongIdInSingersList(singer, song.songId.toString());
  }

  bool isSongIdInSingersList(String singer, String songIdString) {
    return _allSongPerformances.where((e) => e._singer == singer && e._songIdAsString == songIdString).isNotEmpty;
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
  }

  String toJsonString() {
    return Util.jsonEncodeNewLines(jsonEncode(this));
  }

  String toJsonStringFor(String singer) {
    return Util.jsonEncodeNewLines(jsonEncode(bySinger(singer)));
  }

  Map<String, dynamic> toJson() => {
        allSongPerformancesName: _allSongPerformances.toList(growable: false),
        allSongPerformanceHistoryName: _allSongPerformanceHistory.toList(growable: false),
      };

  void clear() {
    _allSongPerformances.clear();
    _allSongPerformanceHistory.clear();
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

  static const String fileExtension = '.songperformances'; //  intentionally all lower case
}
