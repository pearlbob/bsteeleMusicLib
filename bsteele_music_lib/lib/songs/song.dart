import 'dart:convert';
import 'dart:core';

import '../app_logger.dart';
import '../util/util.dart';
import 'chord_section_location.dart';
import 'key.dart';
import 'song_base.dart';
import 'time_signature.dart';

enum SongComparatorType {
  title,
  artist,
  dateCreated,
  lastModifiedDate,
  lastModifiedDateLast,
  versionNumber,
  complexity,
  copyrightYear,
  popularity,
}

/// A song is a wrapper class for {@link SongBase} that provides
/// file I/O routines and comparators for various sortings.
/// This is the class most all song interactions should reference.
///
/// The class is designed to provide some functionality outside
/// of the main purpose of the the SongBase class.
/// All the musical functions happen in SongBase.

class Song extends SongBase implements Comparable<Song> {
  Song({
    required super.title,
    required super.artist,
    String? coverArtist,
    required super.copyright,
    required Key super.key,
    required super.beatsPerMinute,
    required super.beatsPerBar, //  beats per bar, i.e. timeSignature numerator
    required super.unitsPerMeasure,
    String? user,
    required super.chords,
    required super.rawLyrics,
  }) : super(coverArtist: coverArtist ?? '', user: user ?? defaultUser);

  /// Create a minimal song to be used internally as a place holder.
  static Song createEmptySong({int? currentBeatsPerMinute, Key? currentKey}) {
    //  note: this is not a valid song!
    return Song(
      title: '',
      artist: '',
      copyright: '',
      key: currentKey ?? Key.getDefault(),
      beatsPerMinute: currentBeatsPerMinute ?? 100,
      beatsPerBar: 4,
      unitsPerMeasure: 4,
      user: '',
      chords: '',
      rawLyrics: '',
    );
  }

  /// Copy the song to a new instance.
  Song copySong() {
    //  note: assure all arguments are immutable, or at least unique to the copy
    Song ret = Song(
      title: title,
      artist: artist,
      coverArtist: coverArtist,
      copyright: copyright,
      key: key,
      beatsPerMinute: beatsPerMinute,
      beatsPerBar: beatsPerBar,
      unitsPerMeasure: unitsPerMeasure,
      user: user,
      chords: toMarkup(),
      rawLyrics: rawLyrics,
    );
    ret.setFileName(getFileName());
    ret.dateCreated = dateCreated;
    ret.lastModifiedTime = lastModifiedTime;
    ret.totalBeats = totalBeats;
    ret.setCurrentChordSectionLocation(ChordSectionLocation.copy(getCurrentChordSectionLocation()));
    ret.setCurrentMeasureEditType(currentMeasureEditType);
    return ret;
  }

  /// Copy the song to a new instance with possible changes.
  Song copyWith({
    String? title,
    String? artist,
    String? coverArtist,
    String? copyright,
    Key? key,
    int? beatsPerMinute,
    int? beatsPerBar,
    int? unitsPerMeasure,
    String? user,
    String? markup,
    String? rawLyrics,
  }) {
    //  note: assure all arguments are immutable, or at least unique to the copy
    Song ret = Song(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      coverArtist: coverArtist ?? this.coverArtist,
      copyright: copyright ?? this.copyright,
      key: key ?? this.key,
      beatsPerMinute: beatsPerMinute ?? this.beatsPerMinute,
      beatsPerBar: beatsPerBar ?? this.beatsPerBar,
      unitsPerMeasure: unitsPerMeasure ?? this.unitsPerMeasure,
      user: user ?? this.user,
      chords: markup ?? toMarkup(),
      rawLyrics: rawLyrics ?? this.rawLyrics,
    );
    ret.setFileName(getFileName());
    ret.dateCreated = dateCreated;
    ret.lastModifiedTime = lastModifiedTime;
    ret.totalBeats = totalBeats;
    ret.setCurrentChordSectionLocation(ChordSectionLocation.copy(getCurrentChordSectionLocation()));
    ret.setCurrentMeasureEditType(currentMeasureEditType);
    return ret;
  }

  /// Read a single song or a list from a JSON string
  static List<Song> songListFromJson(String jsonString) {
    //  fix for damaged files
    jsonString = jsonString.replaceAll('": null', '": ""');

    List<Song> songList = [];
    if (jsonString.isNotEmpty) {
      dynamic json = _jsonDecoder.convert(jsonString);
      if (json is List) {
        //  a list of songs
        for (Map<String, dynamic> jsonMap in json) {
          Song song = fromJson(jsonMap);
          songList.add(song);
        }
      } else if (json is Map<String, dynamic>) {
        //  a single song
        Song song = fromJson(json);
        songList.add(song);
      }
    }
    return songList;
  }

  /// Read a single song from a JSON map
  static Song fromJson(Map<String, dynamic> json) {
    Song song = Song.createEmptySong(); //  fixme: better error modes on parse failures

    Map? jsonSong = json['song'];
    jsonSong ??= json;

    var fileDateTime = DateTime.fromMillisecondsSinceEpoch(jsonSong['lastModifiedDate'] ?? 0);
    song.lastModifiedTime = fileDateTime.millisecondsSinceEpoch;
    song.setFileName(json['file']);

    for (String name in jsonSong.keys) {
      switch (name) {
        case 'title':
          song.title = jsonSong[name];
          break;
        case 'artist':
          song.artist = jsonSong[name];
          break;
        case 'coverArtist':
          song.coverArtist = jsonSong[name];
          break;
        case 'copyright':
          song.copyright = jsonSong[name];
          break;
        case 'key':
          song.key = Key.parseString(jsonSong[name]) ?? Key.getDefault();
          break;
        case 'defaultBpm':
          song.beatsPerMinute = (jsonSong[name] as int);
          break;
        case 'timeSignature':
          //  most of this is coping with real old events with poor formatting
          String timeSignatureString = jsonSong[name];
          RegExpMatch? mr = _timeSignatureExp.firstMatch(timeSignatureString);
          if (mr != null) {
            // parse
            song.timeSignature = TimeSignature(int.parse(mr.group(1)!), int.parse(mr.group(2)!));
          } else {
            //  safe default
            song.timeSignature = TimeSignature.defaultTimeSignature;
          }
          break;
        case 'chords':
          dynamic chordRows = jsonSong[name];
          StringBuffer sb = StringBuffer();
          for (int chordRow = 0; chordRow < chordRows.length; chordRow++) {
            sb.write(chordRows[chordRow]);
            //  brutal way to transcribe the new line without the chaos of a newline character
            sb.write(', ');
          }
          song.chords = sb.toString();
          break;
        case 'lyrics':
          dynamic lyricRows = jsonSong[name];
          StringBuffer sb = StringBuffer();
          for (int lyricRow = 0; lyricRow < lyricRows.length; lyricRow++) {
            sb.write(lyricRows[lyricRow]);
            sb.write('\n');
          }
          song.rawLyrics = sb.toString(); // no trim!
          break;
        case 'dateCreated':
          {
            DateTime dateCreated = DateTime.fromMillisecondsSinceEpoch(jsonSong[name]);
            song.dateCreated = dateCreated.millisecondsSinceEpoch;
          }
          break;
        case 'lastModifiedDate':
          {
            DateTime songDateTime = DateTime.fromMillisecondsSinceEpoch(jsonSong[name]);
            if (songDateTime.isAfter(fileDateTime)) {
              song.lastModifiedTime = songDateTime.millisecondsSinceEpoch;
            }
          }
          break;
        case 'user':
          song.user = jsonSong[name];
          break;
        default:
          logger.w('unknown field in JSON: "$name"');
          break;
      }
    }
    return song;
  }

  static String listToJson(List<Song> songs) {
    StringBuffer sb = StringBuffer();
    sb.write('[\n');
    bool first = true;
    for (Song song in songs) {
      if (first) {
        first = false;
      } else {
        sb.write(',\n');
      }
      sb.write(song.toJsonAsFile());
    }
    sb.write(']\n');
    return sb.toString();
  }

  String toJsonAsFile() {
    return '{ "file": ${jsonEncode(getFileName())}, "lastModifiedDate": $lastModifiedTime, "song": \n${toJsonString()}}';
  }

  ///Generate the JSON expression of this song.
  String toJsonString() {
    StringBuffer sb = StringBuffer();

    sb.write('{\n');
    sb.write('"title": ');
    sb.write(jsonEncode(title));
    sb.write(',\n');
    sb.write('"artist": ');
    sb.write(jsonEncode(artist));
    sb.write(',\n');
    if (coverArtist.isNotEmpty) {
      sb.write('"coverArtist": ');
      sb.write(jsonEncode(coverArtist));
      sb.write(',\n');
    }
    sb.write('"user": ');
    sb.write(jsonEncode(user));
    sb.write(',\n');
    sb.write('"dateCreated": ');
    sb.write(dateCreated);
    sb.write(',\n');
    sb.write('"lastModifiedDate": ');
    sb.write(lastModifiedTime);
    sb.write(',\n');
    sb.write('"copyright": ');
    sb.write(jsonEncode(copyright));
    sb.write(',\n');
    sb.write('"key": "');
    sb.write(key.toMarkup());
    sb.write('",\n');
    sb.write('"defaultBpm": ');
    sb.write(getDefaultBpm());
    sb.write(',\n');
    sb.write('"timeSignature": "');
    sb.write(beatsPerBar);
    sb.write('/');
    sb.write(unitsPerMeasure);
    sb.write('",\n');
    sb.write('"chords": \n');
    sb.write('    [\n');

    //  chord content
    bool first = true;
    for (String s in chordsToJsonTransportString().split('\n')) {
      if (s.isEmpty) {
        continue;
      }
      if (first) {
        first = false;
      } else {
        sb.write(',\n');
      }
      sb.write('\t');
      sb.write(jsonEncode(s));
    }
    sb.write('\n    ],\n');
    sb.write('"lyrics": \n');
    sb.write('    [\n');

    //  lyrics content
    first = true;
    {
      var list = rawLyrics.split('\n');
      //  since empty strings map to a newline, the are significant and should be removed if added by the split
      if (list.last.isEmpty) {
        list.removeAt(list.length - 1);
      }
      for (String s in list) {
        if (first) {
          first = false;
        } else {
          sb.write(',\n');
        }
        sb.write('\t');

        sb.write(jsonEncode(s));
      }
    }
    sb.write('\n    ]\n');
    sb.write('}\n');

    return sb.toString();
  }

  String lyricsAsString() {
    StringBuffer sb = StringBuffer();

    bool firstSection = true;
    for (var lyricSection in lyricSections) {
      if (firstSection) {
        firstSection = false;
      } else {
        sb.write(', ');
      }
      sb.write('${lyricSection.sectionVersion}');

      for (var line in lyricSection.lyricsLines) {
        sb.write(' "$line"');
      }
    }
    return sb.toString();
  }

  static List<StringTriple> diff(Song a, Song b) {
    List<StringTriple> ret = SongBase.diff(a, b);
    int limit = 15;
    if (ret.length > limit) {
      while (ret.length > limit) {
        ret.removeAt(ret.length - 1);
      }
      ret.add(StringTriple('+more', '', ''));
    }
    ret.insert(
      0,
      StringTriple(
        'file date',
        DateTime.fromMillisecondsSinceEpoch(a.lastModifiedTime).toString(),
        DateTime.fromMillisecondsSinceEpoch(b.lastModifiedTime).toString(),
      ),
    );
    return ret;
  }

  static Comparator<Song> getComparatorByType(SongComparatorType type) {
    switch (type) {
      case .artist:
        return _comparatorByArtist;
      case .lastModifiedDate:
        return _comparatorByLastModifiedDate;
      case .dateCreated:
        return _comparatorByDateCreated;
      case .lastModifiedDateLast:
        return _comparatorByLastModifiedDateLast;
      case .versionNumber:
        return _comparatorByVersionNumber;
      case .complexity:
        return _comparatorByComplexity;
      case .copyrightYear:
        return _comparatorByCopyrightYear;
      default:
        return _comparatorByTitle;
    }
  }

  /// Compare only the title and artist.
  /// To be used for general user listing purposes only.
  ///
  /// Note that leading articles will be rotated to the end.
  @override
  int compareTo(Song o) {
    int ret = getSongId().compareTo(o.getSongId());
    if (ret != 0) {
      return ret;
    }
    ret = artist.compareTo(o.artist);
    if (ret != 0) {
      return ret;
    }
    ret = coverArtist.compareTo(o.coverArtist);
    if (ret != 0) {
      return ret;
    }

    //    //  more?  if so, changes in lyrics will be a new "song"
    //    ret = getLyricsAsString().compareTo(o.getLyricsAsString());
    //    if (ret != 0) {
    //      return ret;
    //    }
    //    ret = getChordsAsString().compareTo(o.getChordsAsString());
    //    if (ret != 0) {
    //      return ret;
    //    }
    return 0;
  }

  static String defaultUser = SongBase.defaultUser;

  static final RegExp _timeSignatureExp = RegExp(r'^\w*(\d{1,2})\w*/\w*(\d)\w*$');

  static const JsonDecoder _jsonDecoder = JsonDecoder();

  bool get isTheEmptySong => identical(this, theEmptySong);
  static final Song theEmptySong = createEmptySong();
}

/// A comparator that sorts by song title and then artist.
/// Note the title order implied by {@link #compareTo(Song)}.
Comparator<Song> _comparatorByTitle = (Song o1, Song o2) {
  return o1.compareBySongId(o2);
};

/// A comparator that sorts on the artist.
Comparator<Song> _comparatorByArtist = (Song o1, Song o2) {
  int ret = o1.artist.compareTo(o2.artist);
  if (ret != 0) {
    return ret;
  }
  return o1.compareBySongId(o2);
};

int _compareByLastModifiedDate(Song o1, Song o2) {
  int mod1 = o1.lastModifiedTime;
  int mod2 = o2.lastModifiedTime;

  if (mod1 == mod2) {
    return o1.compareTo(o2);
  }
  return mod1 < mod2 ? 1 : -1;
}

int _compareByDateCreated(Song o1, Song o2) {
  int mod1 = o1.dateCreated;
  int mod2 = o2.dateCreated;

  if (mod1 == mod2) {
    return o1.compareTo(o2);
  }
  return mod1 < mod2 ? 1 : -1;
}

/// Compares its two arguments for order my most recent modification date.
Comparator<Song> _comparatorByLastModifiedDate = (Song o1, Song o2) {
  return _compareByLastModifiedDate(o1, o2);
};

/// Compares its two arguments for order my most recent modification date.
Comparator<Song> _comparatorByDateCreated = (Song o1, Song o2) {
  return _compareByDateCreated(o1, o2);
};

/// Compares its two arguments for order my most recent modification date, reversed
Comparator<Song> _comparatorByLastModifiedDateLast = (Song o1, Song o2) {
  return -_compareByLastModifiedDate(o1, o2);
};

/// Compares its two arguments for order my most recent modification date.
Comparator<Song> _comparatorByVersionNumber = (Song o1, Song o2) {
  int ret = o1.compareTo(o2);
  if (ret != 0) {
    return ret;
  }
  if (o1.getFileVersionNumber() != o2.getFileVersionNumber()) {
    return o1.getFileVersionNumber() < o2.getFileVersionNumber() ? -1 : 1;
  }
  return _compareByLastModifiedDate(o1, o2);
};

/// Compares its two arguments for order by most recent modification date.
Comparator<Song> _comparatorByComplexity = (Song o1, Song o2) {
  if (o1.getComplexity() != o2.getComplexity()) {
    return o1.getComplexity() < o2.getComplexity() ? -1 : 1;
  }
  return o1.compareTo(o2);
};

/// Compares its two arguments for order my most recent modification date.
Comparator<Song> _comparatorByCopyrightYear = (Song o1, Song o2) {
  if (o1.getCopyrightYear() != o2.getCopyrightYear()) {
    return o1.getCopyrightYear() < o2.getCopyrightYear() ? -1 : 1;
  }
  return o1.compareTo(o2);
};
