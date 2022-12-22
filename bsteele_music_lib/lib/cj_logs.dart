import 'dart:convert';
import 'dart:io';

import 'package:bsteeleMusicLib/songs/song_performance.dart';
import 'package:bsteeleMusicLib/songs/song_update.dart';
import 'package:bsteeleMusicLib/util/util.dart';
import 'package:dotenv/dotenv.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import 'app_logger.dart';

const String _allSongDirectory = 'github/allSongs.songlyrics';
const String _allSongPerformancesGithubFileLocation = '$_allSongDirectory/allSongPerformances.songperformances';

final _firstValidDate = DateTime(2022, 7, 26);
final _now = DateTime.now();
final _oldestValidDate = DateTime(_now.year - 1, _now.month, _now.day);

const _cjLogFiles = Level.info;
const _cjLogLines = Level.debug;
const _cjLogPerformances = Level.info;

const songPerformanceExtension = '.songperformances';

void main(List<String> args) {
  Logger.level = Level.info;

  CjLog().runMain(args);

  exit(0);
}

class CjLog {
  void _help() {
    logger.i('cjlogs {-f} {-v} {-V} --host=hostname --tomcat=tomcatCatalinaBase');
  }

  /// Process the augmented tomcat logs to a performance history JSON file
  void runMain(List<String> args) async {
    //  setup
    var gZipDecoder = GZipCodec().decoder;
    Utf8Decoder utf8Decoder = const Utf8Decoder();
    var dateFormat = DateFormat('dd-MMM-yyyy HH:mm:ss.SSS'); //  20-Aug-2022 06:08:20.127
    var dotEnv = DotEnv(includePlatformEnvironment: true)..load();

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
          case '-f':
            _force = true;
            break;
          case '-v':
            _verbose = 1;
            break;
          case '-V':
            _verbose = 2;
            break;
          default:
            logger.i('bad arg: $arg');
            _help();
            exit(-1);
        }
      }
    }

    if (_verbose > 0) {
      logger.i('CjLogs:');
    }

    //  prepare the file stuff
    if (_host.isEmpty) {
      logger.log(_cjLogFiles, 'Empty host: "$_host"');
      exit(-1);
    }
    logger.log(_cjLogFiles, 'host: $_host');

    Directory logs;
    var processedLogs = Directory('${dotEnv['HOME']}/communityJams/$_host/Downloads');
    if (_catalinaBase != null) {
      if (_catalinaBase!.isEmpty) {
        logger.i('Empty CATALINA_BASE environment variable: "$_catalinaBase"');
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
        logger.i('$file:  $date');
      }

      //  don't go too far back in time... the file format is wrong!
      if (date.isBefore(_firstValidDate)) {
        if (_verbose > 1) {
          logger.i('\ttoo early: ${file.path.substring(file.path.lastIndexOf('/') + 1)}');
        }
        continue;
      }
      {
        //  don't go too far back in time...
        if (date.isBefore(_oldestValidDate)) {
          if (_verbose > 0) {
            logger.i('\ttoo old: ${file.path.substring(file.path.lastIndexOf('/') + 1)}');
          }
          continue;
        }
      }

      // var jsonOutputFile = File('${processedLogs.path}'
      //     '/${file.path.substring(file.path.lastIndexOf('/') + 1).replaceFirst('.log', songPerformanceExtension)}');
      // logger.log(_cjLogFiles, 'jsonOutputFile: ${jsonOutputFile.path}');
      //
      // if (!_force &&
      //     jsonOutputFile.existsSync() &&
      //     jsonOutputFile.lastModifiedSync().microsecondsSinceEpoch > file.lastModifiedSync().microsecondsSinceEpoch) {
      //   fileList.add(jsonOutputFile);
      //   if (_verbose > 0) {
      //     logger.i('\texisting: ${jsonOutputFile.path}');
      //   }
      //   continue;
      // }
      logger.log(_cjLogFiles, '');
      logger.log(_cjLogFiles, '${file.path}:  $date');
      var log = utf8Decoder
          .convert(file.path.endsWith('.gz') ? gZipDecoder.convert(file.readAsBytesSync()) : file.readAsBytesSync());
      SongUpdate lastSongUpdate = SongUpdate();
      //allSongPerformances.clear();
      var dateTime = DateTime(1970);
      for (var line in log.split('\n')) {
        RegExpMatch? m = messageRegExp.firstMatch(line);
        if (m == null) {
          continue;
        }
        dateTime = dateFormat.parse(m.group(1)!);
        logger.log(_cjLogLines, '$dateTime: string: ${m.group(2)}');
        SongUpdate songUpdate = lastSongUpdate.updateFromJson(m.group(2)!);
        logger.log(_cjLogLines,
            '$dateTime: $songUpdate, key: ${songUpdate.currentKey}, lastkey: ${lastSongUpdate.currentKey}');

        //  output the update if the song has changed
        if (!songUpdate.song.songBaseSameContent(lastSongUpdate.song) && lastSongUpdate.song.title.isNotEmpty) {
          //  convert last song update to a performance
          allSongPerformances.addSongPerformance(toSongPerformance(lastSongUpdate, dateTime));
        }
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

    //  build the net output file
    //  allSongPerformances.clear();
    //   for (var file in fileList) {
    //     allSongPerformances.readFileSync(file);
    //   }
    _writeSongPerformances(File('${processedLogs.path}/allSongPerformances.songperformances'), prettyPrint: false);
    logger.log(_cjLogPerformances, allSongPerformances.toJsonString(prettyPrint: false));
  }

  void _writeSongPerformances(File file, {bool prettyPrint = true}) {
    if (allSongPerformances.isNotEmpty) {
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
  var _force = false;

  final RegExp catalinaLogRegExp =
      RegExp(r'.*/catalina\.(\d{4})-(\d{2})-(\d{2})\.log'); //  note: no end to allow for both .log and .log.gz
  final RegExp messageRegExp = RegExp(r'(\d{2}-\w{3}-\d{4} \d{2}:\d{2}:\d{2}\.\d{3}) INFO .*'
      r' com.bsteele.bsteeleMusicApp.WebSocketServer.onMessage'
      r' onMessage\("(.*)"\)\s*$');
}
