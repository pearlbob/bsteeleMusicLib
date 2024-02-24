import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'songs/song.dart';
import 'songs/song_metadata.dart';
import 'songs/song_performance.dart';
import 'songs/song_update.dart';
import 'util/us_timer.dart';
import 'util/util.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import 'app_logger.dart';

// ignore_for_file: avoid_print

const String _allSongDirectory = 'github/allSongs.songlyrics';
final _allSonglyricsGithubFile = File('${Util.homePath()}/$_allSongDirectory/allSongs.songlyrics');
const String _allSongPerformancesGithubFileLocation = '$_allSongDirectory/allSongPerformances.songperformances';
final _allSongsMetadataFile = File('${Util.homePath()}/$_allSongDirectory/allSongs.songmetadata');
late final String downloadsDirString;

// final _firstValidFormatDate = DateTime(2022, 7, 26); //  first valid file format
final _now = DateTime.now();
final _oldestValidDate = DateTime(_now.year - 2, _now.month, _now.day);
final _firstValidDate = _oldestValidDate;

const _cjLogFiles = Level.debug;
const _cjLogLines = Level.debug;
const _cjLogWasSung = Level.info;
const _cjLogPerformances = Level.debug;
const _cjLogDelete = Level.debug;

const songPerformanceExtension = '.songperformances';

void main(List<String> args) {
  Logger.level = Level.info;

  CjLog().runMain(args);

  exit(0);
}

class CjLog {
  void _help() {
    print('cjlogs {-v} {-V} --host=hostname --tomcat=tomcatCatalinaBase');
  }

  /// Process the augmented tomcat logs to a performance history JSON file
  void runMain(List<String> args) async {
    //  setup
    var gZipDecoder = GZipCodec().decoder;
    Utf8Decoder utf8Decoder = const Utf8Decoder();
    var dateFormat = DateFormat('dd-MMM-yyyy HH:mm:ss.SSS'); //  20-Aug-2022 06:08:20.127

    _catalinaBase = null;
    _host = 'cj';

    //  process the args
    // if (args.isEmpty) {
    //   _help(); //  help if nothing to do
    //   exit(-1);
    // }
    for (var arg in args) {
      if (arg.startsWith('--host=')) {
        _host = arg.substring(arg.indexOf('=') + 1);
      } else if (arg.startsWith('--tomcat=')) {
        _catalinaBase = arg.substring(arg.indexOf('=') + 1);
      } else {
        switch (arg) {
          case '-v':
            _verbose = 1;
            break;
          case '-V':
            _verbose = 2;
            break;
          default:
            print('bad arg: $arg');
            _help();
            exit(-1);
        }
      }
    }

    if (_verbose > 0) {
      print('CjLogs:');
    }

    //  prepare the file stuff
    if (_host.isEmpty) {
      logger.log(_cjLogFiles, 'Empty host: "$_host"');
      exit(-1);
    }
    logger.log(_cjLogFiles, 'host: $_host');
    downloadsDirString = '${Util.homePath()}/communityJams/$_host/Downloads';

    var usTimer = UsTimer();
    Directory logs;
    var processedLogs = Directory(downloadsDirString);
    if (_catalinaBase != null) {
      if (_catalinaBase!.isEmpty) {
        print('Empty CATALINA_BASE environment variable: "$_catalinaBase"');
        exit(-1);
      }
      logger.log(_cjLogFiles, 'CATALINA_BASE: $_catalinaBase');
      //  look at the tomcat logs directly
      logs = Directory('$_catalinaBase/logs');
    } else {
      logs = processedLogs;
    }

    logger.log(_cjLogFiles, 'logs: $logs');
    logger.log(_cjLogFiles, 'processedLogs: $processedLogs');

    processedLogs.createSync();

    //  add the github version
    {
      File file = File('${Util.homePath()}/$_allSongPerformancesGithubFileLocation');
      String data = file.readAsStringSync();
      allSongPerformances.updateFromJsonString(data);
    }

    logger.i('request count: ${allSongPerformances.allSongPerformanceRequests.length}');

    //  process the logs
    var list = logs.listSync();
    list.sort((a, b) {
      return a.path.compareTo(b.path);
    });

    SplayTreeSet<int> momentNumbers = SplayTreeSet();
    for (var fileSystemEntity in list) {
      if (fileSystemEntity is! File) {
        continue;
      }
      var file = fileSystemEntity;
      DateTime date;
      {
        RegExpMatch? m = catalinaLogRegExp.firstMatch(file.path);
        if (m == null) {
          continue;
        }
        date = DateTime(int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
      }

      if (_verbose > 1) {
        print('$file:  $date');
      }

      //  don't go too far back in time... the file format is wrong!
      if (date.isBefore(_firstValidDate)) {
        if (_verbose > 1) {
          print('\ttoo early: ${file.path.substring(file.path.lastIndexOf('/') + 1)}');
        }
        continue;
      }
      {
        //  don't go too far back in time...
        if (date.isBefore(_oldestValidDate)) {
          if (_verbose > 0) {
            print('\ttoo old: ${file.path.substring(file.path.lastIndexOf('/') + 1)}');
          }
          continue;
        }
      }

      logger.log(_cjLogFiles, '');
      logger.log(_cjLogFiles, '${file.path}:  $date');
      var log = utf8Decoder
          .convert(file.path.endsWith('.gz') ? gZipDecoder.convert(file.readAsBytesSync()) : file.readAsBytesSync());
      SongUpdate? firstSongUpdate;
      SongUpdate lastSongUpdate = SongUpdate();
      var dateTime = DateTime(1970);
      // var startTime = DateTime(1970);
      for (var line in log.split('\n')) {
        RegExpMatch? m = messageRegExp.firstMatch(line);
        if (m == null) {
          continue;
        }
        dateTime = dateFormat.parse(m.group(1)!);
        var msg = m.group(2);
        if (msg == null || msg.isEmpty || msg == 't:' //  a time request can show up when a client starts!
            ) {
          continue;
        }
        logger.log(_cjLogLines, '$dateTime: string: $msg');
        SongUpdate songUpdate;
        try {
          songUpdate = lastSongUpdate.updateFromJson(msg);
        } catch (e) {
          print('error thrown for file $file: $e');
          print('   line: <$line>');
          continue;
        }
        // if ( firstSongUpdate == null ) startTime = dateTime;
        firstSongUpdate ??= songUpdate;

        //  output the update if the song has changed
        if (!songUpdate.song.songBaseSameContent(lastSongUpdate.song) && lastSongUpdate.song.title.isNotEmpty) {
          logger.log(_cjLogLines,
              '$dateTime: $songUpdate, key: ${songUpdate.currentKey}, lastkey: ${lastSongUpdate.currentKey}');

          //  see if it makes sense that this song was actually played... or only looked at
          var song = lastSongUpdate.song;

          //  note: duration of time on the song does not seem to indicate whether it was played
          // logger.log(_cjLogWasSung, '   from $startTime to $dateTime: ${dateTime.difference(startTime)}'
          //     ' vs ${lastSongUpdate.song.duration} s');
          var moments = song.getSongMoments();
          var minimumMomentCount = moments.length - moments.last.chordSection.getTotalMoments();
          //  try to allow one section songs, e.g. the blues
          //  will be fooled by damaged songs
          if (song.lyricSections.length > 1) {
            //  otherwise, try assure that most nearly all the song was seen
            minimumMomentCount = max(minimumMomentCount, (0.6 * moments.last.momentNumber).round());
          }
          logger.log(
              _cjLogWasSung,
              '$song:  ${momentNumbers.toString()}/$minimumMomentCount '
              '(${song.getSongMomentsSize()})');
          if (momentNumbers.first <= 0 && momentNumbers.last >= minimumMomentCount) {
            logger.log(_cjLogWasSung, '  sung');
          } else {
            logger.i('  not sung: ${song.toString()}');
          }

          //  convert last song update to a performance
          allSongPerformances.addSongPerformance(toSongPerformance(lastSongUpdate, dateTime));
          momentNumbers.clear(); //  remove the last moment numbers from the prior song
        }
        momentNumbers.add(songUpdate.momentNumber);
        lastSongUpdate = songUpdate;
      }

      //  output the last update
      if (lastSongUpdate.song.title.isNotEmpty) {
        //  convert last song update to a performance
        allSongPerformances.addSongPerformance(toSongPerformance(lastSongUpdate, dateTime));
      }
      // if (allSongPerformances.isNotEmpty) {
      //   _writeSongPerformances(jsonOutputFile);
      //   fileList.add(jsonOutputFile);
      // }
    }

    //  clean duplicates generated by having allSongPerformances and catalina logs cover the same date
    {
      SongPerformance? lastPerformance;
      List<SongPerformance> deleteList = [];
      for (SongPerformance performance in allSongPerformances.allSongPerformanceHistory) {
        //  throw out the old performances
        if (performance.lastSungDateTime.compareTo(_firstValidDate) < 0) {
          logger.log(_cjLogDelete, 'delete: $performance');
          deleteList.add(performance);
        } else if (lastPerformance != null) {
          if (performance.compareTo(lastPerformance) == 0 &&
              (performance.lastSung - lastPerformance.lastSung).abs() < Duration.millisecondsPerDay) {
            //  same performance
            logger.log(_cjLogDelete, 'delete: $performance');
            deleteList.add(performance);
          }
        }
        lastPerformance = performance;
      }
      for (SongPerformance performance in deleteList) {
        allSongPerformances.removeSingerSongHistory(performance);
      }
    }

    //  Note:  intentionally leave in unknown singers.
    //  These are songs sung from outside the singers screen.

    //  read the new songs as source for song corrections
    var songs = Song.songListFromJson(_allSonglyricsGithubFile.readAsStringSync());
    var corrections = allSongPerformances.loadSongs(songs);
    print('postLoad: usTimer: ${usTimer.seconds} s, delta: ${usTimer.deltaToString()}, songs: ${songs.length}');
    print('corrections: $corrections');

    // clean up the near misses in the history and performances due to song title, artist and cover artist changes
    //  count the sloppy matched songs in history
    {
      var matches = 0;
      for (var performance in allSongPerformances.allSongPerformanceHistory) {
        if (performance.song == null) {
          print('missing song: ${performance.lowerCaseSongIdAsString}');
          assert(false);
        } else if (performance.lowerCaseSongIdAsString != performance.song!.songId.toString().toLowerCase()) {
          logger.i('${performance.lowerCaseSongIdAsString}'
              ' vs ${performance.song!.songId.toString().toLowerCase()}');
          assert(false);
        } else {
          matches++;
        }
      }
      print('matches:  $matches/${allSongPerformances.allSongPerformanceHistory.length}'
          ', corrections: ${allSongPerformances.allSongPerformanceHistory.length - matches}');
    }

    //  repair metadata song changes
    SongMetadata.fromJson(_allSongsMetadataFile.readAsStringSync());
    File localSongMetadata = File('$downloadsDirString/allSongs.songmetadata');
    logger.i('localSongMetadata: ${localSongMetadata.path}');
    {
      SongMetadata.repairSongs(allSongPerformances.songRepair);
      try {
        localSongMetadata.deleteSync();
      } catch (e) {
        logger.e(e.toString());
        //assert(false);
      }
      localSongMetadata.writeAsStringSync(SongMetadata.toJson(), flush: true);

      if (_verbose > 0) {
        logger.i('allSongPerformances location: ${localSongMetadata.path}');
      }
    }

    //  write the corrected performances
    File localSongperformances = File('$downloadsDirString/allSongPerformances.songperformances');
    {
      try {
        localSongperformances.deleteSync();
      } catch (e) {
        logger.e(e.toString());
        //assert(false);
      }
      localSongperformances.writeAsStringSync(allSongPerformances.toJsonString(), flush: true);
    }

    //  time the reload
    {
      // allSongPerformances.clear();
      // SongMetadata.clear();

      print('\nreload:');
      var usTimer = UsTimer();

      allSongPerformances.updateFromJsonString(localSongperformances.readAsStringSync());
      print('performances: ${usTimer.deltaToString()}');

      var json = _allSonglyricsGithubFile.readAsStringSync();
      print('song data read: ${usTimer.deltaToString()}');
      var songs = Song.songListFromJson(json);
      print('song data parsed: ${usTimer.deltaToString()}');
      var corrections = allSongPerformances.loadSongs(songs);
      print('loadSongs: ${usTimer.deltaToString()}');

      SongMetadata.fromJson(localSongMetadata.readAsStringSync());
      print('localSongMetadata: ${usTimer.deltaToString()}');

      double seconds = usTimer.seconds;
      print('reload: usTimer: $seconds s'
          ', allSongPerformances.length: ${allSongPerformances.length}'
          ', songs.length: ${songs.length}'
          ', idMetadata.length: ${SongMetadata.idMetadata.length}'
          ', corrections: $corrections');
      assert(seconds < 0.25);
    }

    //  write the output file
    _writeSongPerformances(File('${processedLogs.path}/allSongPerformances.songperformances'), prettyPrint: false);
    logger.log(_cjLogPerformances, allSongPerformances.toJsonString(prettyPrint: false));
  }

  void _writeSongPerformances(File file, {bool prettyPrint = true}) {
    if (allSongPerformances.isNotEmpty) {
      logger.i('first valid date: $_firstValidDate');
      {
        int count = 0;
        var oldest = _now;
        for (var p in allSongPerformances.allSongPerformanceHistory) {
          if (p.lastSungDateTime.compareTo(oldest) < 0) {
            oldest = p.lastSungDateTime;
          }
          if (p.lastSungDateTime.compareTo(_firstValidDate) < 0) {
            // logger.i('      too early:  ${p.lastSungDateTime}');
            count++;
          }
        }
        logger.i('oldest:  $oldest');
        logger.i('history too early count:  $count');
      }

      if (file.path.endsWith('.gz')) {
        file.writeAsBytesSync(gzip.encode(utf8.encode(allSongPerformances.toJsonString(prettyPrint: prettyPrint))),
            flush: true);
      } else {
        file.writeAsStringSync(allSongPerformances.toJsonString(prettyPrint: prettyPrint), flush: true);
      }
      if (_verbose > 0) {
        logger.i('\twrote: ${file.path}');
      }
    }
  }

  SongPerformance toSongPerformance(SongUpdate songUpdate, DateTime dateTime) {
    logger.log(_cjLogPerformances, 'output: $songUpdate');
    var ret = SongPerformance(
      songUpdate.song.songId.toString(),
      songUpdate.singer,
      song: songUpdate.song,
      key: songUpdate.currentKey,
      bpm: songUpdate.currentBeatsPerMinute,
      lastSung: dateTime.millisecondsSinceEpoch,
    );
    logger.log(_cjLogPerformances, 'performance: ${ret.toJsonString()}');
    return ret;
  }

  AllSongPerformances allSongPerformances = AllSongPerformances();
  String? _catalinaBase;
  String _host = 'cj';
  var _verbose = 0;

  final RegExp catalinaLogRegExp =
      RegExp(r'.*/catalina\.(\d{4})-(\d{2})-(\d{2})\.log'); //  note: no end to allow for both .log and .log.gz
  final RegExp messageRegExp = RegExp(r'(\d{2}-\w{3}-\d{4} \d{2}:\d{2}:\d{2}\.\d{3}) INFO .*'
      r' com.bsteele.bsteeleMusicApp.WebSocketServer.onMessage'
      r' onMessage\("(.*)"\)\s*$');
}
