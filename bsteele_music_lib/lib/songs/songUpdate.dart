/*
 * Copyright 2018 Robert Steele at bsteele.com
 */

import 'dart:convert';

import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/key.dart';
import 'package:bsteeleMusicLib/songs/song.dart';
import 'package:bsteeleMusicLib/songs/songMoment.dart';
import 'package:quiver/core.dart';

enum SongUpdateState {
  none,
  playing,
  idle,
}

String _StateEnumToString(SongUpdateState s) {
  return s.toString().split('.').last;
}

SongUpdateState? stateFromString(String s) {
  for (var e in SongUpdateState.values) {
    if (e.toString().endsWith(s)) {
      return e;
    }
  }
  return null;
}

final JsonDecoder _jsonDecoder = JsonDecoder();

/// Immutable song update data
/// <p>
/// fixme: song update should always have a song
///
/// @author bob
class SongUpdate {
  SongUpdate() {
    assignSong(Song.createEmptySong());
  }

  static SongUpdate createSongUpdate(Song song) {
    SongUpdate ret = SongUpdate();
    ret.assignSong(song);
    return ret;
  }

  void assignSong(Song song) {
    this.song = song;
    currentBeatsPerMinute = song.getBeatsPerMinute();
    currentKey = song.getKey();
  }

  SongUpdateState getState() {
    return state;
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
    if (song.getSongMomentsSize() == 0) {
      momentNumber = 0;
      songMoment = null;
      return;
    }

//  past the end and we're done
    if (m >= song.getSongMomentsSize()) {
      momentNumber = song.getSongMomentsSize();
      songMoment = null;
      return;
    }

    momentNumber = m;
    songMoment = song.getSongMoment(momentNumber);
  }

  Song getSong() {
    return song;
  }

  /// Moment index from start of song starts at zero.
  /// The moment number will be negative in play prior to the song start.
  ///
  /// @return the index of the current moment number in time
  int getMomentNumber() {
    return momentNumber;
  }

  /// Return the typical, default duration for the default beats per bar and the beats per minute.
  /// Due to variation in measureNumber beats, this should not be used anywhere but pre-roll!
  ///
  /// @return the typical, default duration
  double getDefaultMeasureDuration() {
    return song.getBeatsPerBar() * 60.0 / (currentBeatsPerMinute == 0 ? 30 : currentBeatsPerMinute);
  }

  /// Beat number from start of the current measureNumber. Starts at zero and goes to
  /// beatsPerBar - 1
  ///
  /// @return the current beat
  int getBeat() {
    return beat;
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
    return currentBeatsPerMinute > 0 ? currentBeatsPerMinute : song.getBeatsPerMinute();
  }

  void setState(SongUpdateState state) {
    this.state = state;
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
      return 'new song: ' + other.song.getTitle() + ', ' + other.song.getArtist();
    }
    if (currentKey != other.currentKey) {
      return 'new key: ' + other.currentKey.toString();
    }
    if (currentKey != other.currentKey) {
      return 'new key: ' + other.currentKey.toString();
    }
    if (currentBeatsPerMinute != other.currentBeatsPerMinute) {
      return 'new tempo: ' + other.currentBeatsPerMinute.toString();
    }
    return 'no change';
  }

  /// Returns a string representation of the object. In general, the
  /// {@code toString} method returns a string that
  /// "textually represents" this object. The result should
  /// be a concise but informative representation that is easy for a
  /// person to read.
  /// It is recommended that all subclasses override this method.
  /// <p>
  /// The {@code toString} method for class {@code Object}
  /// returns a string consisting of the name of the class of which the
  /// object is an instance, the at-sign character `{@code @}', and
  /// the unsigned hexadecimal representation of the hash code of the
  /// object. In other words, this method returns a string equal to the
  /// value of:
  /// <blockquote>
  /// <pre>
  /// getClass().getName() + '@' + Integer.toHexString(hashCode())
  /// </pre></blockquote>
  ///
  /// @return a string representation of the object.
  @override
  String toString() {
    var sb = StringBuffer('SongUpdate: ');
    sb.write(getMomentNumber());
    if (songMoment != null) {
      sb.write(' ');
      sb.write(songMoment!.getMomentNumber().toString());
      sb.write(' ');
      sb.write(songMoment!.getBeatNumber());
      sb.write(' ');
      sb.write(songMoment!.getMeasure().toString());
      if (songMoment!.getRepeatMax() > 0) {
        sb.write(' ');
        sb.write((songMoment!.getRepeat() + 1));
        sb.write('/');
        sb.write(songMoment!.getRepeatMax());
      }
    }
    return sb.toString();
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

    if (json is Map) {
      for (String name in json.keys) {
        var jv = json[name];
        switch (name) {
          case 'state':
            songUpdate.setState(stateFromString(jv) ?? SongUpdateState.none);
            break;
          case 'currentKey':
            songUpdate.setCurrentKey(Key.parseString(jv.toString()) ?? Key.getDefault());
            break;
          case 'song':
            songUpdate.setSong(Song.songFromJson(jv));
            break;
          //  momentNumber sequencing details should be found by local processing
          case 'momentNumber':
            songUpdate.momentNumber = jv;
            break;
          case 'beat':
            songUpdate.beat = jv;
            break;
          case 'beatsPerMeasure':
            songUpdate.beatsPerMeasure = jv;
            break;
          case 'currentBeatsPerMinute':
            songUpdate.currentBeatsPerMinute = jv;
            break;
          case 'user':
            songUpdate.setUser(jv.toString());
            break;
          default:
            logger.w('unknown field in JSON: "$name"');
            return null;
        }
      }
      songUpdate.setMomentNumber(songUpdate.momentNumber);
      songUpdate.songMoment = songUpdate.song.songMoments[songUpdate.momentNumber];

      return songUpdate;
    }
    return null;
  }

  String toJson() {
    var sb = StringBuffer();
    sb.write('{\n');
    sb.write('\"state\": \"');
    sb.write(_StateEnumToString(getState()));
    sb.write('\",\n');
    sb.write('\"currentKey\": \"');
    sb.write(getCurrentKey().name);
    sb.write('\",\n');

    sb.write('\"song\": ');
    sb.write(song.toJson());
    sb.write(',\n');

    //  momentNumber sequencing details should be found by local processing
    sb.write('\"momentNumber\": ');
    sb.write(getMomentNumber());
    sb.write(',\n');
    sb.write('\"beat\": ');
    sb.write(getBeat());
    sb.write(',\n');
    sb.write('\"user\": \"');
    sb.write(getUser());
    sb.write('\",\n');
    sb.write('\"beatsPerMeasure\": ');
    sb.write(getBeatsPerMeasure());
    sb.write(',\n');
    sb.write('\"currentBeatsPerMinute\": ');
    sb.write(getCurrentBeatsPerMinute());
    sb.write('\n}\n');

    return sb.toString();
  }

  @override
  bool operator ==(o) {
    if (identical(this, o)) {
      return true;
    }
    return runtimeType == o.runtimeType && o is SongUpdate && hashCode == o.hashCode;
  }

  @override
  int get hashCode {
    int hash = hash4(state, currentKey, song, momentNumber);
    hash = 83 * hash + hash4(beat, beatsPerMeasure, currentBeatsPerMinute, user);
    return hash;
  }

  SongUpdateState state = SongUpdateState.idle;
  late Song song;
  String user = 'no one';
  int momentNumber = 0;
  SongMoment? songMoment;

//  play values
  int beat = 0;
  int beatsPerMeasure = 4;
  int currentBeatsPerMinute = 100;
  Key currentKey = Key.getDefault();
}