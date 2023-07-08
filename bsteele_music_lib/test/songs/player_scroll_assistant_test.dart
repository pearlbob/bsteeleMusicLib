import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/grid_coordinate.dart';
import 'package:bsteele_music_lib/player_scroll_assistant.dart';
import 'package:bsteele_music_lib/songs/key.dart';
import 'package:bsteele_music_lib/songs/music_constants.dart';
import 'package:bsteele_music_lib/songs/song.dart';
import 'package:bsteele_music_lib/songs/song_base.dart';
import 'package:bsteele_music_lib/songs/song_performance.dart';
import 'package:bsteele_music_lib/songs/song_update.dart';
import 'package:bsteele_music_lib/util/util.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

// ignore_for_file: avoid_print

const String _allSongDirectory = 'github/allSongs.songlyrics';
// final _allSongLyricsGithubFile = File('${Util.homePath()}/$_allSongDirectory/allSongs.songlyrics');
const String _allSongPerformancesGithubFileLocation = '$_allSongDirectory/allSongPerformances.songperformances';
// final _allSongsMetadataFile = File('${Util.homePath()}/$_allSongDirectory/allSongs.songmetadata');
late final String downloadsDirString;

final _firstValidDate = DateTime(2022, 7, 26);
final _now = DateTime.now();
final _oldestValidDate = DateTime(_now.year - 2, _now.month, _now.day);

const _cjLogFiles = Level.debug;
const _cjLogLines = Level.debug;
const _cjLogPerformances = Level.debug;
const _cjLogManualBumps = Level.info;
const _cjLogErrors = Level.info;
const _cjLogDetails = Level.info;
const _cjLogRawInput = Level.debug;

const songPerformanceExtension = '.songperformances';

void main() {
  Logger.level = Level.info;

  test('PlayerScrollAssistant testing', () {
    List<String> args = [];
    CjLog().runMain(args);
  });

  test('PlayerScrollAssistant isLyricSectionFirstRow()', () {
    var song = Song(
      title: 'the song',
      artist: 'bob',
      copyright: '2023 bob',
      key: Key.C,
      beatsPerMinute: 105,
      beatsPerBar: 4,
      unitsPerMeasure: 4,
      chords: 'i: G G G G, A B C D v: [ A B C D ] x2 c: A B C D, [F F F G] x3 E o: [ E F G ] x2 E',
      rawLyrics: 'i: v: c: o:',
    );

    bool expanded = false;
    // var displayGrid =
    song.toDisplayGrid(UserDisplayStyle.both, expanded: expanded);
    List<GridCoordinate> songMomentToGridCoordinate = song.songMomentToGridCoordinate;
    PlayerScrollAssistant assistant = PlayerScrollAssistant(song,
        userDisplayStyle: UserDisplayStyle.both, expanded: expanded, bpm: song.beatsPerMinute);
    final start = DateTime.now();
    assistant.sectionRequest(start, 0);
    final List<int> firstRowMoments = [
      //  i:
      0, 1, 2, 3,
      //  v:
      8, 9, 10, 11,
      //  c:
      16, 17, 18, 19,
      //  o:
      33, 34, 35
    ];
    for (var m in song.songMoments) {
      var t = song.getSongTimeAtMoment(m.momentNumber);
      var songTime = start.add(Duration(microseconds: (Duration.microsecondsPerSecond * t).round()));
      var gc = songMomentToGridCoordinate[m.momentNumber];
      var isFirstRow = assistant.isLyricSectionFirstRow(songTime);
      logger.i('${m.momentNumber}: ${m.lyricSection.sectionVersion} ${m.measure}'
          ' $songTime, offset: ${songTime.difference(start)}'
          ', row: ${gc.row}, firstRow? $isFirstRow');
      expect(isFirstRow, firstRowMoments.contains(m.momentNumber));
    }
  });
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

      var hasStarted = false;
      int beatCount = 0;
      int songMomentsLength = 0;
      DateTime? baseTime;
      int? baseBeat;
      int? baseBeatsTotal;
      int? baseSectionCount;
      int? lastSectionIndex;
      int lastMoment = 0;
      bool expanded = false; //fixme:  needs to match the song display!!!!!

      for (var line in log.split('\n')) {
        //  look for the bsteeleMusicApp log messages
        RegExpMatch? m = messageRegExp.firstMatch(line);
        if (m == null) {
          continue;
        }
        logger.log(_cjLogRawInput, line);

        //  parse the date time
        var lastDateTime = dateTime;
        dateTime = dateFormat.parse(m.group(1)!);
        var duration = dateTime.difference(lastDateTime);
        if (duration > const Duration(hours: 1)) {
          duration = Duration.zero;
        }

        //  exclude the time distribution requests
        var msg = m.group(2);
        if (msg == null || msg.isEmpty || msg == 't:' //  a time request can show up when a new client starts!
            ) {
          continue;
        }
        logger.log(_cjLogLines, '$dateTime: string: $msg');

        //  parse the song update
        SongUpdate songUpdate;
        try {
          songUpdate = lastSongUpdate.updateFromJson(msg);
        } catch (e) {
          print('error thrown for file $file: $e');
          print('   line: <$line>');
          continue;
        }

        //  see if this is a new song
        if (lastSong == null || lastSong?.songId != songUpdate.song.songId) {
          if (lastSong != null) {
            _simulateManualPlay(lastSong!, bumps, expanded: expanded);
          }

          //  prep the next song
          hasStarted = false;
          lastSong = songUpdate.song;
          songMomentsLength = songUpdate.song.songMoments.length;
          baseTime = null;
          baseBeat = null;
          baseBeatsTotal = null;
          bumps.clear();
        }

        //  get the song moment
        final songMoment = songUpdate.song.getSongMoment(songUpdate.momentNumber);
        if (songMoment == null) {
          continue;
        }
        var sectionIndex = songMoment.lyricSection.index;
        var bpm =
            duration.inMilliseconds > 0 ? 60 * Duration.millisecondsPerSecond * beatCount / duration.inMilliseconds : 0;
        logger.log(
            _cjLogManualBumps,
            'manual bump at moment: section: ${songMoment.lyricSection.index}'
            ', moment: ${songMoment.momentNumber}'
            ', $dateTime: ${sectionIndex > (lastSectionIndex ?? 0) ? 1 : -1}');
        bumps.add((dateTime: dateTime, sectionIndex: sectionIndex));

        if (lastMoment < songMoment.momentNumber) {
          lastMoment = songMoment.momentNumber;
        } else {
          while (lastMoment < songMoment.momentNumber) {
            logger.log(_cjLogDetails, '  moment $lastMoment at: ');
            lastMoment++;
          }
        }

        //  ignore the first section... we don't know how long we've been sitting here prior to playing
        if (sectionIndex >= 0) {
          if (lastSectionIndex == null || sectionIndex > lastSectionIndex) {
            //  we're moving forward
            baseSectionCount ??= 0;
            baseSectionCount++;
            if (bpm < MusicConstants.minBpm || bpm > MusicConstants.maxBpm) {
              //  toss the effort based on a bad bpm
              baseSectionCount = null;
              baseTime = null;
              baseBeat = null;
              baseBeatsTotal = null;
            }
          } else if (sectionIndex < lastSectionIndex
              //  gone backwards? lets forget what we thought we knew.
              ) {
            baseSectionCount = null;
            baseTime = null;
            baseBeat = null;
            baseBeatsTotal = null;
          }
          lastSectionIndex = sectionIndex;
        }

        //  only push the display forward in manual play mode
        if (songUpdate.state == SongUpdateState.manualPlay) {
          //  mark the beginning to use it as a reference
          //  used to average the manual input (section bumps)
          if ((baseSectionCount ?? -1) >= 0) {
            hasStarted = true;
            baseTime ??= dateTime;
            baseBeat ??= 0;
            baseBeatsTotal ??= 0;
          }

          //  diagnostics
          if ((baseSectionCount ?? -1) >= 2) {
            logger.log(
                _cjLogDetails,
                '$dateTime: ${_shortString(songUpdate.song.toString())}: $hasStarted'
                ', ${songUpdate.state.name}'
                ', momentNumber: ${songUpdate.momentNumber}/$songMomentsLength'
                ': $beatCount in $duration => '
                '${(Duration.millisecondsPerSecond * beatCount / duration.inMilliseconds).toStringAsFixed(2)} b/s = '
                '${(60 * Duration.millisecondsPerSecond * beatCount / duration.inMilliseconds).toStringAsFixed(2)} BPM'
                // ', lyricSection: ${songMoment?.lyricSection.index}'
                ', section: $sectionIndex');
            var b = (baseBeatsTotal ?? 0) - (baseBeat ?? 0);
            var d = dateTime.difference(baseTime ?? dateTime);
            logger.log(
                _cjLogDetails,
                '   $b beats in $d since $baseTime =>'
                ' ${(Duration.millisecondsPerSecond * b / d.inMilliseconds).toStringAsFixed(2)} b/s ='
                ' ${(60 * Duration.millisecondsPerSecond * b / d.inMilliseconds).toStringAsFixed(2)}'
                ' bpm, section: $sectionIndex'
                '${sectionIndex == baseSectionCount ? '' : ', baseSectionCount: $baseSectionCount'}');
          }

          //  the song has ended
          if (songUpdate.momentNumber + (songMoment.chordSection.getTotalMoments()) >= songMomentsLength) {
            if (!hasStarted) {
              lastSongUpdate = songUpdate;
              continue;
            }
            logger.log(_cjLogDetails, '   performance finished: average BPM: ');
          }
        }

        //  prep data for the next input
        lastSongUpdate = songUpdate;
        beatCount = songMoment.chordSection.beatCount;
        if (baseBeatsTotal != null) {
          baseBeatsTotal += beatCount;
        }
      }
      if (lastSong != null) {
        _simulateManualPlay(lastSong!, bumps, expanded: expanded); //  do the last song of that day
      }

      break; //fixme: only one file for the moment
    }
  }

  String _shortString(final String s) {
    var len = s.length;
    return s.substring(0, min(35, len));
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

  Song? lastSong;
  final List<({DateTime dateTime, int sectionIndex})> bumps = [];

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

_simulateManualPlay(final Song song, final List<({DateTime dateTime, int sectionIndex})> bumps,
    {final bool expanded = false}) {
  if (bumps.isEmpty || song.songMoments.isEmpty) {
    logger.i('invalid play: $song, $bumps');
    return;
  }
  logger.log(_cjLogDetails, '');
  logger.log(_cjLogDetails, '${song.songId}, BPM: ${song.beatsPerMinute}');

  PlayerScrollAssistant assistant =
      PlayerScrollAssistant(song, userDisplayStyle: UserDisplayStyle.both, expanded: expanded);

  DateTime? baseTime;
  DateTime? rowTime;
  int? lastRow = -1;
  double maxErrorAmplitude = 0;
  int maxErrorSection = 0;
  for (final bump in bumps) {
    baseTime ??= bump.dateTime;
    rowTime ??= baseTime;

    //  see if we can get a row suggestion from the scroll assistant
    while (rowTime!.isBefore(bump.dateTime)) {
      var row = assistant.rowSuggestion(rowTime);
      if (row != lastRow) {
        lastRow = row;
        logger.log(
            _cjLogDetails,
            '   ${rowTime.difference(baseTime)}'
            ', section: ${bump.sectionIndex} ${song.lyricSections[bump.sectionIndex].sectionVersion}'
            ', assistant row: $row'
            ' $assistant');
      }
      rowTime = rowTime.add(const Duration(milliseconds: 400));
    }

    //  register the row request the user asked for
    assistant.sectionRequest(bump.dateTime, bump.sectionIndex);
    if (assistant.error != null) {
      double error = assistant.error!.abs();
      if (error > maxErrorAmplitude) {
        maxErrorAmplitude = error;
        maxErrorSection = bump.sectionIndex;
        logger.log(
            _cjLogErrors,
            'sectionRequest(${bump.dateTime}, section: ${bump.sectionIndex})'
            ', assistant.error: ${assistant.error}');
      }
    }
  }
  logger.i('errorAmplitude: ${maxErrorAmplitude.toStringAsFixed(1).padLeft(7)}'
      ' at section ${maxErrorSection.toString().padLeft(2)}/${song.lyricSections.length.toString().padRight(2)}'
      ': ${song.songId}, BPM: ${assistant.bpm} (${song.beatsPerMinute})');
}
