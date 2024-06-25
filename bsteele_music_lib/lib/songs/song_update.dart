/*
 * Copyright 2018 Robert Steele at bsteele.com
 */

import 'dart:convert';
import 'dart:math';

import '../app_logger.dart';
import 'key.dart';
import 'song.dart';
import 'song_moment.dart';

enum SongUpdateState {
  none, //  basically an initial condition
  playing, // song is in play mode
  idle, //  song is stopped
  pause, //  song play is paused
  drumTempo, //  prior to play, drum the given tempo, temporarily
}

const unknownSinger = 'unknown';

String songUpdateStateToString(SongUpdateState s) {
  return s.toString().split('.').last;
}

SongUpdateState? _stateFromString(String s) {
  for (var e in SongUpdateState.values) {
    if (e.toString().endsWith(s)) {
      return e;
    }
  }
  return null;
}

const JsonDecoder _jsonDecoder = JsonDecoder();

/// Immutable song update data
///
/// fixme: song update should always have a song
class SongUpdate {
  SongUpdate(
      {SongUpdateState? state,
      Song? song,
      String? user,
      String? singer,
      int? momentNumber,
      int? rowNumber,
      this.songMoment,
      int? beat,
      int? beatsPerMeasure,
      int? currentBeatsPerMinute,
      Key? currentKey})
      : state = state ?? SongUpdateState.idle,
        user = user ?? 'unknown',
        singer = singer ?? unknownSinger,
        momentNumber = momentNumber ?? 0,
        rowNumber = rowNumber ?? 0,
        beat = beat ?? 0,
        beatsPerMeasure = beatsPerMeasure ?? 4,
        currentBeatsPerMinute = currentBeatsPerMinute ?? 100,
        currentKey = currentKey ?? Key.getDefault() {
    //  notice assignSong() is not used to keep currentKey and currentBeatsPerMinute correct
    //  that is, the update versions
    this.song = song ?? Song.createEmptySong(currentBeatsPerMinute: song?.beatsPerMinute, currentKey: song?.key);
  }

  SongUpdate copyWith(
      {SongUpdateState? state,
      Song? song,
      String? user,
      String? singer,
      int? momentNumber,
      SongMoment? songMoment,
      int? beat,
      int? beatsPerMeasure,
      int? currentBeatsPerMinute,
      Key? currentKey}) {
    SongUpdate ret = SongUpdate(
      song: song ?? this.song,
      state: state ?? this.state,
      user: user ?? this.user,
      singer: singer ?? this.singer,
      momentNumber: momentNumber ?? this.momentNumber,
      songMoment: songMoment ?? this.songMoment,
      beat: beat ?? this.beat,
      beatsPerMeasure: beatsPerMeasure ?? this.beatsPerMeasure,
      currentBeatsPerMinute: currentBeatsPerMinute ?? this.currentBeatsPerMinute,
      currentKey: currentKey ?? this.currentKey,
    );
    return ret;
  }

  static SongUpdate createSongUpdate(Song song) {
    SongUpdate ret = SongUpdate();
    ret.assignSong(song);
    return ret;
  }

  void assignSong(Song song) {
    this.song = song;
    currentBeatsPerMinute = song.beatsPerMinute;
    currentKey = song.key;
  }

  SongMoment? getSongMoment() {
    return songMoment;
  }

  /// Move the update indicators to the given measureNumber.
  /// Should only be used to reposition the moment number.
  ///
  /// @param m the measureNumber to move to
  void setMomentNumber(int m) {
    if (m == momentNumber) {
      return;
    }

    beat = 0;

    //  leave negative moment numbers as they are
    if (m < 0) {
      momentNumber = m;
      songMoment = null;
      return;
    }

    //  deal with empty songs
    if (song.songMoments.isEmpty) {
      momentNumber = 0;
      songMoment = null;
      return;
    }

    //  past the end and we're done
    if (m >= song.songMoments.length) {
      momentNumber = song.songMoments.length;
      songMoment = null;
      return;
    }

    momentNumber = m;
    songMoment = song.getSongMoment(momentNumber);
  }

  Song getSong() {
    return song;
  }

  /// Return the typical, default duration for the default beats per bar and the beats per minute.
  /// Due to variation in measureNumber beats, this should not be used anywhere but pre-roll!
  ///
  /// @return the typical, default duration
  double getDefaultMeasureDuration() {
    return song.beatsPerBar * 60.0 / (currentBeatsPerMinute == 0 ? 30 : currentBeatsPerMinute);
  }

  double getBeatDuration() {
    return 60.0 / song.getDefaultBpm();
  }

  /// @return the beatsPerMeasure
  int getBeatsPerMeasure() {
    return beatsPerMeasure;
  }

  /// @return the currentBeatsPerMinute
  int getCurrentBeatsPerMinute() {
    return currentBeatsPerMinute > 0 ? currentBeatsPerMinute : song.beatsPerMinute;
  }

  /// @param song the song to set
  void setSong(Song song) {
    this.song = song;
  }

  /// @param beat the beat to set
  void setBeat(int beat) {
    this.beat = beat;
  }

  /// @param beatsPerMeasure the beatsPerMeasure to set
  void setBeatsPerBar(int beatsPerMeasure) {
    this.beatsPerMeasure = beatsPerMeasure;
  }

  /// @param currentBeatsPerMinute the currentBeatsPerMinute to set
  void setCurrentBeatsPerMinute(int currentBeatsPerMinute) {
    this.currentBeatsPerMinute = currentBeatsPerMinute;
  }

  Key getCurrentKey() {
    return currentKey;
  }

  void setCurrentKey(Key currentKey) {
    this.currentKey = currentKey;
  }

  String getUser() {
    return user;
  }

  void setUser(String user) {
    this.user = user;
  }

  String diff(SongUpdate other) {
    if (!song.songBaseSameContent(other.song)) {
      return 'new song: ${other.song.title}, ${other.song.artist}';
    }
    if (currentKey != other.currentKey) {
      return 'new key: ${other.currentKey}';
    }
    if (currentKey != other.currentKey) {
      return 'new key: ${other.currentKey}';
    }
    if (currentBeatsPerMinute != other.currentBeatsPerMinute) {
      return 'new tempo: ${other.currentBeatsPerMinute}';
    }
    return 'no change';
  }

  @override
  String toString() {
    var sb = StringBuffer('SongUpdate: "${song.title}" by "${song.artist}" '
        '${song.coverArtist.isNotEmpty ? ' cover by "${song.coverArtist}"' : ''}: ');
    sb.write(', moment: ');
    sb.write(momentNumber);
    if (songMoment != null) {
      sb.write(', beat: ');
      sb.write(songMoment!.beatNumber);
      sb.write(', measure: ');
      sb.write(songMoment!.measure.toString());
      if (songMoment!.repeatMax > 0) {
        sb.write(', repeat: ');
        sb.write((songMoment!.repeat + 1));
        sb.write('/');
        sb.write(songMoment!.repeatMax);
      }
      sb.write(', key: $currentKey');
    }
    return sb.toString();
  }

  SongUpdate updateFromJson(String jsonString) {
    //logger.i(jsonString);

    SongUpdate ret = copyWith();

    if (jsonString.isEmpty) {
      return ret;
    }
    ret._updateFromJsonObject(_jsonDecoder.convert(jsonString));
    return ret;
  }

  static SongUpdate? fromJson(String jsonString) {
    logger.d(jsonString);

    if (jsonString.isEmpty) {
      return null;
    }

    return fromJsonObject(_jsonDecoder.convert(jsonString));
  }

  static SongUpdate? fromJsonObject(dynamic json) {
    SongUpdate songUpdate = SongUpdate();
    songUpdate._updateFromJsonObject(json);
    return songUpdate;
  }

  void _updateFromJsonObject(dynamic json) {
    if (json is Map) {
      for (String name in json.keys) {
        var jv = json[name];
        switch (name) {
          case 'state':
            state = (_stateFromString(jv) ??
                //  workaround for old historical value: manualPlay
                (jv == 'manualPlay' ? SongUpdateState.playing : SongUpdateState.none));
            break;
          case 'currentKey':
            setCurrentKey(Key.parseString(jv.toString()) ?? Key.getDefault());
            break;
          case 'song':
            setSong(Song.fromJson(jv));
            break;
          //  momentNumber sequencing details should be found by local processing
          case 'momentNumber':
            momentNumber = jv;
            break;
          case 'rowNumber':
            rowNumber = jv;
            break;
          case 'beat':
            beat = jv;
            break;
          case 'beatsPerMeasure':
            beatsPerMeasure = jv;
            break;
          case 'currentBeatsPerMinute':
            currentBeatsPerMinute = jv;
            break;
          case 'user':
            setUser(jv.toString());
            break;
          case 'singer':
            singer = jv.toString();
            break;
          default:
            logger.w('unknown field in JSON: "$name"');
            break;
        }
      }
      setMomentNumber(momentNumber);
      songMoment =
          song.songMoments.isNotEmpty ? song.songMoments[min(max(0, momentNumber), song.songMoments.length)] : null;
    }
  }

  String toJson() {
    var sb = StringBuffer();
    sb.write('{\n');
    sb.write('"state": "');
    sb.write(songUpdateStateToString(state));
    sb.write('",\n');
    sb.write('"currentKey": "');
    sb.write(getCurrentKey().name);
    sb.write('",\n');

    sb.write('"song": ');
    sb.write(song.toJson());
    sb.write(',\n');

    //  momentNumber sequencing details should be found by local processing
    sb.write('"momentNumber": ');
    sb.write(momentNumber);
    sb.write(',\n');
    sb.write('"rowNumber": ');
    sb.write(rowNumber);
    sb.write(',\n');
    sb.write('"beat": ');
    sb.write(beat);
    sb.write(',\n');
    sb.write('"user": ');
    sb.write(jsonEncode(user));
    sb.write(',\n');
    sb.write('"singer": ');
    sb.write(jsonEncode(singer));
    sb.write(',\n');
    sb.write('"beatsPerMeasure": ');
    sb.write(getBeatsPerMeasure());
    sb.write(',\n');
    sb.write('"currentBeatsPerMinute": ');
    sb.write(getCurrentBeatsPerMinute());
    sb.write('\n}\n');

    return sb.toString();
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    return runtimeType == other.runtimeType && other is SongUpdate && hashCode == other.hashCode;
  }

  @override
  int get hashCode {
    int hash = Object.hash(state, currentKey, song, momentNumber);
    hash = 83 * hash + Object.hash(beat, beatsPerMeasure, currentBeatsPerMinute, user);
    hash = 17 * hash + singer.hashCode;
    return hash;
  }

  SongUpdateState state;
  late Song song;
  String user;
  String singer;
  int momentNumber;
  int rowNumber;
  SongMoment? songMoment;

  //  play values

  // Beat number from start of the current measureNumber. Starts at zero and goes to beatsPerBar - 1
  int beat;
  int beatsPerMeasure;
  int currentBeatsPerMinute;
  Key currentKey;
}
