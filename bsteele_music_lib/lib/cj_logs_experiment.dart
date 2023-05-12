import 'dart:convert';
import 'dart:io';

import 'songs/song.dart';
import 'songs/song_performance.dart';
import 'songs/song_update.dart';

// import 'util/us_timer.dart';
import 'util/util.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import 'app_logger.dart';

// ignore_for_file: avoid_print

const String _allSongDirectory = 'github/allSongs.songlyrics';
// final _allSonglyricsGithubFile = File('${Util.homePath()}/$_allSongDirectory/allSongs.songlyrics');
const String _allSongPerformancesGithubFileLocation = '$_allSongDirectory/allSongPerformances.songperformances';
// final _allSongsMetadataFile = File('${Util.homePath()}/$_allSongDirectory/allSongs.songmetadata');
late final String downloadsDirString;

final _firstValidDate = DateTime(2022, 7, 26);
final _now = DateTime.now();
final _oldestValidDate = DateTime(_now.year - 2, _now.month, _now.day);

const _cjLogFiles = Level.info;
const _cjLogLines = Level.debug;
const _cjLogPerformances = Level.debug;

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

    // var usTimer = UsTimer();
    Directory logs;
    var processedLogs = Directory('${Util.homePath()}/communityJams/$_host/Downloads');
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
    allSongPerformances
        .updateFromJsonString(File('${Util.homePath()}/$_allSongPerformancesGithubFileLocation').readAsStringSync());

    //  process the logs
    var list = logs.listSync();
    list.sort((a, b) {
      return a.path.compareTo(b.path);
    });
    //  List<File> fileList = [];
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
      SongUpdate lastSongUpdate = SongUpdate();
      //allSongPerformances.clear();
      var dateTime = DateTime(1970);
      Song? lastSong;
      var hasStarted = false;
      int beatCount = 0;
      int songMomentsLength = 0;
      int lastSectionCount = -1;
      for (var line in log.split('\n')) {
        //  look for the bsteeleMusicApp log messages
        RegExpMatch? m = messageRegExp.firstMatch(line);
        if (m == null) {
          continue;
        }
        var lastDateTime = dateTime;
        dateTime = dateFormat.parse(m.group(1)!);
        var duration = dateTime.difference(lastDateTime);
        if (duration > const Duration(hours: 1)) {
          duration = Duration.zero;
        }
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
        if (lastSong == null || lastSong.songId != songUpdate.song.songId) {
          hasStarted = false;
          lastSong = songUpdate.song;
          songMomentsLength = songUpdate.song.songMoments.length;
        }
        var songMoment = songUpdate.song.getSongMoment(songUpdate.momentNumber);
        var sectionCount = songMoment?.lyricSection.index ?? -1;

        if (sectionCount < 2 // too early to look at BPM
                ||
                sectionCount < lastSectionCount //  going backwards?
            ) {
          lastSectionCount = sectionCount;
          hasStarted = false;
          //logger.i('      ignore backwards: $sectionCount');
          lastSongUpdate = songUpdate; //  don't lose the update!
          continue;
        }
        lastSectionCount = sectionCount;

        if (sectionCount == 0) {
          hasStarted = true;
        }

        logger.i('$dateTime: ${songUpdate.song}: $hasStarted'
            ' momentNumber: ${songUpdate.momentNumber}/$songMomentsLength'
            ': $beatCount in $duration => '
            '${(Duration.millisecondsPerSecond * beatCount / duration.inMilliseconds).toStringAsFixed(2)} b/s = '
            '${(60 * Duration.millisecondsPerSecond * beatCount / duration.inMilliseconds).toStringAsFixed(2)} BPM'
            // ', lyricSection: ${songMoment?.lyricSection.index}'
            ', currentSectionCount: $sectionCount');

        if (songUpdate.momentNumber + (songMoment?.chordSection.getTotalMoments() ?? 0) == songMomentsLength) {
          if (!hasStarted) {
            lastSongUpdate = songUpdate;
            continue;
          }
          logger.i('   performance finished: average BPM: ');
        }

        lastSongUpdate = songUpdate;
        beatCount = songMoment?.chordSection.beatCount ?? 0;
      }

      break; //fixme: only one file at the moment
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
