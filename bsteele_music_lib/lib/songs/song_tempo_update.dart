/*
 * Copyright 2024 Robert Steele at bsteele.com
 */

import 'dart:convert';

import 'package:bsteele_music_lib/songs/song_id.dart';

import '../app_logger.dart';

const JsonDecoder _jsonDecoder = JsonDecoder();

const String _tempoUser = 'tempo';

class SongTempoUpdate {
  SongTempoUpdate(this.songId, this.currentBeatsPerMinute, this.level, {this.user = _tempoUser});

  @override
  String toString() {
    var sb = StringBuffer('SongTempoUpdate: "$songId"');
    sb.write(', currentBPM: $currentBeatsPerMinute');
    sb.write(', user: $user');
    sb.write(', level: ${level.toStringAsFixed(3)}');
    return sb.toString();
  }

  static SongTempoUpdate? fromJson(final String jsonString) {
    logger.d(jsonString);

    if (jsonString.isEmpty) {
      return null;
    }

    return fromJsonObject(_jsonDecoder.convert(jsonString));
  }

  static SongTempoUpdate? fromJsonObject(dynamic json) {
    SongTempoUpdate songTempoUpdate = SongTempoUpdate(SongId.noArgs(), 0, 0);
    songTempoUpdate._updateFromJsonObject(json);
    return songTempoUpdate;
  }

  void _updateFromJsonObject(dynamic json) {
    if (json is Map) {
      for (String name in json.keys) {
        var jv = json[name];
        switch (name) {
          case 'songId':
            songId = SongId.fromString(jv);
            break;
          case 'user':
            user = jv.toString();
            break;
          case 'currentBeatsPerMinute':
            currentBeatsPerMinute = jv;
            break;
          case 'level':
            level = jv;
            break;
          default:
            logger.w('unknown field in JSON: "$name"');
            break;
        }
      }
    }
  }

  String toJson() {
    var sb = StringBuffer();
    sb.write('{\n');

    sb.write('"songId": ');
    sb.write(jsonEncode(songId.songIdAsString));
    sb.write(',\n"user": ');
    sb.write(jsonEncode(user));
    sb.write(',\n"currentBeatsPerMinute": ');
    sb.write(jsonEncode(currentBeatsPerMinute));
    sb.write(',\n"level": ');
    sb.write(level);
    sb.write('\n}\n');

    return sb.toString();
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    return runtimeType == other.runtimeType &&
        other is SongTempoUpdate &&
        songId == other.songId &&
        currentBeatsPerMinute == other.currentBeatsPerMinute &&
        user == other.user &&
        level == other.level;
  }

  @override
  int get hashCode {
    return Object.hash(songId, currentBeatsPerMinute, user, level);
  }

  SongId songId;
  String user;
  int currentBeatsPerMinute;
  double level; // 0 to 1.0, best if 0.5 < level < 1.0
}
