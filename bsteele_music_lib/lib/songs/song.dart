import 'dart:convert';
import 'dart:core';

import 'package:bsteeleMusicLib/songs/timeSignature.dart';

import '../appLogger.dart';
import '../util/util.dart';
import 'chordSectionLocation.dart';
import 'key.dart';
import 'songBase.dart';

enum SongComparatorType {
  title,
  artist,
  lastModifiedDate,
  lastModifiedDateLast,
  versionNumber,
  complexity,
  copyrightYear,
}

/// A song is a wrapper class for {@link SongBase} that provides
/// file I/O routines and comparators for various sortings.
/// This is the class most all song interactions should reference.
///
/// The class is designed to provide some functionality outside
/// of the main purpose of the the SongBase class.
/// All the musical functions happen in SongBase.

class Song extends SongBase implements Comparable<Song> {
  /// Create a minimal song to be used internally as a place holder.
  static Song createEmptySong({int? currentBeatsPerMinute, Key? currentKey}) {
    return createSong('', '', '', currentKey ?? Key.C, currentBeatsPerMinute ?? 100, 4, 4, '', '', '');
  }

  /// A convenience constructor used to enforce the minimum requirements for a song.
  static Song createSong(String title, String artist, String copyright, Key key, int bpm, int beatsPerBar,
      int unitsPerMeasure, String user, String chords, String lyrics,
      {String coverArtist = ''}) {
    Song song = Song();
    song.setSongId(title, artist, coverArtist);
    song.copyright = copyright;
    song.key = key;
    song.setBeatsPerMinute(bpm);
    song.timeSignature = TimeSignature(beatsPerBar, unitsPerMeasure);
    song.setUser(user);
    song.setChords(chords);
    song.rawLyrics = lyrics;
    song.resetLastModifiedDateToNow();

    return song;
  }

  /// Copy the song to a new instance.
  Song copySong() {
    //  note: assure all arguments are immutable, or at least unique to the copy
    Song ret = Song.createSong(getTitle(), getArtist(), getCopyright(), getKey(), beatsPerMinute, getBeatsPerBar(),
        getUnitsPerMeasure(), getUser(), toMarkup(), rawLyrics,
        coverArtist: coverArtist);
    ret.setFileName(getFileName());
    ret.lastModifiedTime = lastModifiedTime;
    ret.setTotalBeats(getTotalBeats());
    ret.setCurrentChordSectionLocation(ChordSectionLocation.copy(getCurrentChordSectionLocation()));
    ret.setCurrentMeasureEditType(currentMeasureEditType);
    return ret;
  }

  /// Parse a song from a JSON string.
//  static List<Song> fromJson(String jsonString) {
//    List<Song> ret = List();
//    if (jsonString == null || jsonString.length <= 0) {
//      return ret;
//    }
//
//    if (jsonString.startsWith("<")) {
//      logger.w("this can't be good: " +
//          jsonString.substring(0, min(25, jsonString.length)));
//    }
//
//    try {
//      JSONValue jv = JSONParser.parseStrict(jsonString);
//
//      JSONArray ja = jv.isArray();
//      if (ja != null) {
//        int jaLimit = ja.size();
//        for (int i = 0; i < jaLimit; i++) {
//          ret.add(Song.fromJsonObject(ja.get(i).isObject()));
//        }
//      } else {
//        JSONObject jo = jv.isObject();
//        ret.add(fromJsonObject(jo));
//      }
//    }
////    catch
////    (
////    JSONException
////    e) {
////    logger.warning(jsonString);
////    logger.warning("JSONException: " + e.getMessage());
////    return null;
////    }
//    catch (e) {
//      logger.w("exception: " + e.toString());
//      logger.w(jsonString);
//      logger.w(e.getMessage());
//      return null;
//    }
//
//    logger.d("fromJson(): " + ret[ret.length - 1].toString());
//
//    return ret;
//  }

  /// Parse a song from a JSON object.
//  static Song fromJsonObject(JSONObject jsonObject) {
//    if (jsonObject == null) {
//      return null;
//    }
//    //  file information available
//    if (jsonObject.keySet().contains("file"))
//      {return songFromJsonFileObject(jsonObject);}
//
//    //  straight song
//    return songFromJsonObject(jsonObject);
//  }
//
//  static Song songFromJsonFileObject(JSONObject jsonObject) {
//    Song song;
//    double lastModifiedTime = 0;
//    String fileName = null;
//
//    JSONNumber jn;
//    for (String name in jsonObject.keySet()) {
//      JSONValue jv = jsonObject.get(name);
//      switch (name) {
//        case "song":
//          song = songFromJsonObject(jv.isObject());
//          break;
//        case "lastModifiedDate":
//          jn = jv.isNumber();
//          if (jn != null) {
//            lastModifiedTime = jn.doubleValue();
//          }
//          break;
//        case "file":
//          fileName = jv.isString().stringValue();
//          break;
//      }
//    }
//    if (song == null) {return null;}
//
//    if (lastModifiedTime > song.lastModifiedTime)
//     { song.setLastModifiedTime(lastModifiedTime);}
//    song.setFileName(fileName);
//
//    return song;
//  }

  /// Read a single song or a list from a JSON string
  static List<Song> songListFromJson(String jsonString) {
    //  fix for damaged files
    jsonString = jsonString.replaceAll('\": null', '\": \"\"');

    List<Song> songList = [];
    dynamic json = _jsonDecoder.convert(jsonString);
    if (json is List) {
      //  a list of songs
      for (Map jsonMap in json) {
        Song song = songFromJson(jsonMap);
        songList.add(song);
      }
    } else if (json is Map) {
      //  a single song
      Song song = songFromJson(json);
      songList.add(song);
    }
    return songList;
  }

  /// Read a single song from a JSON map
  static Song songFromJson(Map jsonSongFile) {
    Song song = Song.createEmptySong(); //  fixme: better error modes on parse failures

    Map? jsonSong = jsonSongFile['song'];
    jsonSong ??= jsonSongFile;

    var fileDateTime = DateTime.fromMillisecondsSinceEpoch(jsonSong['lastModifiedDate'] ?? 0);
    song.lastModifiedTime = fileDateTime.millisecondsSinceEpoch;
    song.setFileName(jsonSongFile['file']);

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
          song.setChords(sb.toString());
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
        case 'lastModifiedDate':
          DateTime songDateTime = DateTime.fromMillisecondsSinceEpoch(jsonSong[name]);
          if (songDateTime.isAfter(fileDateTime)) {
            song.lastModifiedTime = songDateTime.millisecondsSinceEpoch;
          }
          break;
        case 'user':
          song.setUser(jsonSong[name]);
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
    return '{ \"file\": ' +
        jsonEncode(getFileName()) +
        ', \"lastModifiedDate\": ' +
        lastModifiedTime.toString() +
        ', \"song\":' +
        ' \n' +
        toJson() +
        '}';
  }

  ///Generate the JSON expression of this song.
  String toJson() {
    StringBuffer sb = StringBuffer();

    sb.write('{\n');
    sb.write('\"title\": ');
    sb.write(jsonEncode(getTitle()));
    sb.write(',\n');
    sb.write('\"artist\": ');
    sb.write(jsonEncode(getArtist()));
    sb.write(',\n');
    if (coverArtist.isNotEmpty) {
      sb.write('\"coverArtist\": ');
      sb.write(jsonEncode(coverArtist));
      sb.write(',\n');
    }
    sb.write('\"user\": ');
    sb.write(jsonEncode(getUser()));
    sb.write(',\n');
    sb.write('\"lastModifiedDate\": ');
    sb.write(lastModifiedTime);
    sb.write(',\n');
    sb.write('\"copyright\": ');
    sb.write(jsonEncode(getCopyright()));
    sb.write(',\n');
    sb.write('\"key\": \"');
    sb.write(getKey().toMarkup());
    sb.write('\",\n');
    sb.write('\"defaultBpm\": ');
    sb.write(getDefaultBpm());
    sb.write(',\n');
    sb.write('\"timeSignature\": \"');
    sb.write(getBeatsPerBar());
    sb.write('/');
    sb.write(getUnitsPerMeasure());
    sb.write('\",\n');
    sb.write('\"chords\": \n');
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
    sb.write('\"lyrics\": \n');
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
        StringTriple('file date', DateTime.fromMillisecondsSinceEpoch(a.lastModifiedTime).toString(),
            DateTime.fromMillisecondsSinceEpoch(b.lastModifiedTime).toString()));
    return ret;
  }

  static Comparator<Song> getComparatorByType(SongComparatorType type) {
    switch (type) {
      case SongComparatorType.artist:
        return _comparatorByArtist;
      case SongComparatorType.lastModifiedDate:
        return _comparatorByLastModifiedDate;
      case SongComparatorType.lastModifiedDateLast:
        return _comparatorByLastModifiedDateLast;
      case SongComparatorType.versionNumber:
        return _comparatorByVersionNumber;
      case SongComparatorType.complexity:
        return _comparatorByComplexity;
      case SongComparatorType.copyrightYear:
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
    ret = getArtist().compareTo(o.getArtist());
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

  static final RegExp _timeSignatureExp = RegExp(r'^\w*(\d{1,2})\w*\/\w*(\d)\w*$');

  static final JsonDecoder _jsonDecoder = JsonDecoder();

  static const String unknownUser = 'unknown';

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
  int ret = o1.getArtist().compareTo(o2.getArtist());
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

/// Compares its two arguments for order my most recent modification date.
Comparator<Song> _comparatorByLastModifiedDate = (Song o1, Song o2) {
  return _compareByLastModifiedDate(o1, o2);
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

/// Compares its two arguments for order my most recent modification date.
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
