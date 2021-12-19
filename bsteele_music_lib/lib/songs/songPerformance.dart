import 'dart:collection';
import 'dart:convert';

import 'package:bsteeleMusicLib/songs/song.dart';
import 'package:bsteeleMusicLib/util/util.dart';
import 'package:intl/intl.dart';

import 'key.dart';
import 'musicConstants.dart';

int _compareBySongIdAndSinger(SongPerformance first, SongPerformance other) {
  if (identical(first, other)) return 0;
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

class SongPerformance implements Comparable<SongPerformance> {
  SongPerformance(this._songIdAsString, this._singer, this._key, {int? bpm, int? lastSung})
      : _bpm = bpm ?? MusicConstants.defaultBpm,
        _lastSung = lastSung ?? DateTime.now().millisecondsSinceEpoch;

  SongPerformance.fromSong(Song song, this._singer, this._key, {int? bpm, int? lastSung})
      : song = song,
        _songIdAsString = song.songId.toString(),
        _bpm = bpm ?? song.beatsPerMinute,
        _lastSung = lastSung ?? DateTime.now().millisecondsSinceEpoch;

  SongPerformance update({Key? key}) {
    //  produce a copy with a new last sung date
    return SongPerformance(_songIdAsString, _singer, key ?? _key, bpm: _bpm, lastSung: null);
  }

  @override
  String toString() {
    return 'SongPerformance{song: $song, _songId: $_songIdAsString, _singer: \'$_singer\', _key: $_key'
        ', _bpm: $_bpm, sung: ${lastSungDateString}}';
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
        _singer = json['singer'],
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
    if (identical(this, other)) return 0;
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
    return 0;
  }

  @override
  int get hashCode => _songIdAsString.hashCode ^ _singer.hashCode ^ _key.hashCode ^ _bpm.hashCode;

  Song? song;

  String get songIdAsString => _songIdAsString;
  final String _songIdAsString;

  String get singer => _singer;
  final String _singer;

  Key get key => _key;
  final Key _key;

  int get bpm => _bpm;
  final int _bpm;

  String get lastSungDateString =>
      _lastSung == 0 ? '' : DateFormat.yMd().format(DateTime.fromMillisecondsSinceEpoch(_lastSung));

  int get lastSung => _lastSung;
  int _lastSung = 0;
}

class AllSongPerformances {
  static final AllSongPerformances _singleton = AllSongPerformances._internal();

  factory AllSongPerformances() {
    return _singleton;
  }

  AllSongPerformances._internal();

  void loadSongs(List<Song> songs) {
    for (var song in songs) {
      songMap[song.songId.toString()] = song;
    }

    for (var songPerformance in _allSongPerformances) {
      songPerformance.song = songMap[songPerformance._songIdAsString];
    }
  }

  void addSongPerformance(SongPerformance songPerformance) {
    //  clear the pervious song performance.  needed to change auxiliary data such as key and bpm
    _allSongPerformances.remove(songPerformance);

    _allSongPerformances.add(songPerformance);
    songPerformance.song = songMap[songPerformance._songIdAsString];
  }

  List<SongPerformance> bySinger(String singer) {
    List<SongPerformance> ret = [];
    ret.addAll(_allSongPerformances.where((songPerformance) {
      return songPerformance._singer == singer;
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

  void fromJsonString(String jsonString) {
    _allSongPerformances.clear();
    _singleton._fromJson(jsonDecode(jsonString));
  }

  void addFromJsonString(String jsonString) {
    var decoded = jsonDecode(jsonString);
    if (decoded is List<dynamic>) {
      //  assume the items are song performances
      for (var item in decoded) {
        _allSongPerformances.add(SongPerformance._fromJson(item));
      }
    } else {
      throw 'addFromJsonString wrong json decode: ${decoded.runtimeType}';
    }
  }

  void _fromJson(Map<String, dynamic> json) {
    for (var songPerformanceJson in json['allSongPerformances']) {
      _allSongPerformances.add(SongPerformance._fromJson(songPerformanceJson));
    }
  }

  String toJsonString() {
    return Util.jsonEncodeNewLines(jsonEncode(this));
  }

  String toJsonStringFor(String singer) {
    return Util.jsonEncodeNewLines(jsonEncode(bySinger(singer)));
  }

  Map<String, dynamic> toJson() => {
        'allSongPerformances': _allSongPerformances.toList(growable: false),
      };

  void clear() {
    _allSongPerformances.clear();
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
            other._allSongPerformances.difference(_allSongPerformances).isEmpty;
  }

  @override
  int get hashCode => _allSongPerformances.hashCode;

  Map<String, Song> songMap = {};
  final SplayTreeSet<SongPerformance> _allSongPerformances = SplayTreeSet<SongPerformance>(_compareBySongIdAndSinger);

  static const String fileExtension = '.songperformances';
}
