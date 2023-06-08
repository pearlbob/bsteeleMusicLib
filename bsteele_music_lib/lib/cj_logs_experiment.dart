import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bsteele_music_lib/songs/music_constants.dart';
import 'package:bsteele_music_lib/songs/song_moment.dart';

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

      var hasStarted = false;
      int beatCount = 0;
      int songMomentsLength = 0;
      DateTime? baseTime;
      int? baseBeat;
      int? baseBeatsTotal;
      int? baseSectionCount;
      int? lastSectionIndex;
      int lastMoment = 0;

      for (var line in log.split('\n')) {
        //  look for the bsteeleMusicApp log messages
        RegExpMatch? m = messageRegExp.firstMatch(line);
        if (m == null) {
          continue;
        }

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
          simulateManualPlay();

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
        logger.i('manual bump at moment: section: ${songMoment.lyricSection.index}'
            ', moment: ${songMoment.momentNumber}'
            ', $dateTime: ${sectionIndex > (lastSectionIndex ?? 0) ? 1 : -1}');
        bumps.add((dateTime: dateTime, sectionIndex: sectionIndex));

        if (lastMoment < songMoment.momentNumber) {
          lastMoment = songMoment.momentNumber;
        } else {
          while (lastMoment < songMoment.momentNumber) {
            logger.i('  moment $lastMoment at: ');
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
            logger.i('$dateTime: ${_shortString(songUpdate.song.toString())}: $hasStarted'
                ', ${songUpdate.state.name}'
                ', momentNumber: ${songUpdate.momentNumber}/$songMomentsLength'
                ': $beatCount in $duration => '
                '${(Duration.millisecondsPerSecond * beatCount / duration.inMilliseconds).toStringAsFixed(2)} b/s = '
                '${(60 * Duration.millisecondsPerSecond * beatCount / duration.inMilliseconds).toStringAsFixed(2)} BPM'
                // ', lyricSection: ${songMoment?.lyricSection.index}'
                ', section: $sectionIndex');
            var b = (baseBeatsTotal ?? 0) - (baseBeat ?? 0);
            var d = dateTime.difference(baseTime ?? dateTime);
            logger.i('   $b beats in $d since $baseTime =>'
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
            logger.i('   performance finished: average BPM: ');
          }
        }

        //  prep data for the next input
        lastSongUpdate = songUpdate;
        beatCount = songMoment.chordSection.beatCount;
        if (baseBeatsTotal != null) {
          baseBeatsTotal += beatCount;
        }
      }
      simulateManualPlay(); //  do the last song of that day

      break; //fixme: only one file for the moment
    }
  }

  simulateManualPlay0() {
    if (lastSong == null || bumps.isEmpty || (lastSong?.songMoments.isEmpty ?? true)) {
      return;
    }
    final song = lastSong!;
    logger.i('');
    logger.i('${song.songId}, BPM: ${song.beatsPerMinute}');
    DateTime? baseTime;
    int bpm = song.beatsPerMinute;
    int songMomentIndex = 0;
    int lastSectionIndex = 0;
    for (final bump in bumps) {
      baseTime ??= bump.dateTime;
      final t = bump.dateTime.difference(baseTime);
      logger.i('   $t: ${bump.sectionIndex}, last: $lastSectionIndex');

      if (lastSectionIndex > bump.sectionIndex) {
        lastSectionIndex = bump.sectionIndex;
        baseTime = null;
        while (song.songMoments[songMomentIndex].lyricSection.index > bump.sectionIndex) {
          if (songMomentIndex > 0) {
            songMomentIndex--;
          } else {
            break;
          }
        }
        logger.i('backup to: songMomentIndex: $songMomentIndex');
        continue;
      }

      while (songMomentIndex < song.songMoments.length - 1 &&
          song.songMoments[songMomentIndex].lyricSection.index < bump.sectionIndex) {
        songMomentIndex =
            songMomentIndex >= song.songMoments.length - 1 ? song.songMoments.length - 1 : songMomentIndex + 1;
      }
      lastSectionIndex = bump.sectionIndex;

      for (;;) {
        if (songMomentIndex >= song.songMoments.length - 1) {
          break;
        }
        SongMoment moment = song.songMoments[songMomentIndex];
        final songTime = Duration(
            milliseconds: (song.getSongTimeAtMoment(moment.momentNumber) * Duration.millisecondsPerSecond).toInt());

        if (moment.lyricSection.index <= bump.sectionIndex
            // && momentTime < t
            ) {
          logger.i('      $t: ${moment.lyricSection.index} $songMomentIndex/${song.songMoments.length}'
              ', songTime: $songTime'
              ', bpm: $bpm');
          songMomentIndex =
              songMomentIndex >= song.songMoments.length - 1 ? song.songMoments.length - 1 : songMomentIndex + 1;
        } else {
          break;
        }
      }
    }
  }

  simulateManualPlay() {
    if (lastSong == null || bumps.isEmpty || (lastSong?.songMoments.isEmpty ?? true)) {
      logger.i('invalid play: $lastSong, $bumps');
      return;
    }
    final song = lastSong!;
    logger.i('');
    logger.i('${song.songId}, BPM: ${song.beatsPerMinute}');

    DateTime? baseTime;
    DateTime? rowTime;
    ManualPlayerScrollAssistant assistant = ManualPlayerScrollAssistant(song);
    for (var songMoment in song.songMoments) {
      logger.i('  beat: ${songMoment.beatNumber}: row: ${songMoment.row}: ${songMoment.measure}');
    }

    for (final bump in bumps) {
      baseTime ??= bump.dateTime;
      rowTime ??= baseTime;

      while (rowTime!.isBefore(bump.dateTime)) {
        logger.i('   ${rowTime.difference(baseTime)}: ${bump.sectionIndex}'
            ', assistant: ${assistant.rowSuggestion(rowTime)}'
            ' $assistant');
        rowTime = rowTime.add(const Duration(milliseconds: 400));
      }
      assistant.sectionRequest(bump.dateTime, bump.sectionIndex);
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

enum _ManualPlayerScrollAssistantState {
  noClue,
  tooEarly,
  forward,
}

class ManualPlayerScrollAssistant {
  ManualPlayerScrollAssistant(this.song) : _bpm = song.beatsPerMinute /*  just a rough guess */;

  /// Suggest a row for the player list using the current time
  int? rowSuggestion(final DateTime dateTime) {
    int? ret;
    switch (_state) {
      case _ManualPlayerScrollAssistantState.forward:
        var beatNumber = beatNumberAt(dateTime);
        ret = rowAtBeatNumber(beatNumber.round());
        logger.i('beatNumber: $beatNumber, row: $ret');
        break;
      default:
        break;
    }
    return ret;
  }

  ///  Update the assistant with the given section request
  sectionRequest(final DateTime dateTime, int sectionIndex) {
    sectionIndex = Util.indexLimit(sectionIndex, song.lyricSections);
    logger.i('   sectionRequest($dateTime, $sectionIndex)');

    var beatNumber = 0;
    if (sectionIndex > _lastSectionIndex) {
      logger.i('section: from $_lastSectionIndex to $sectionIndex');
      var newSongMomentIndex = song.firstMomentInLyricSection(song.lyricSections[sectionIndex]).momentNumber;
      beatNumber = song.songMoments[newSongMomentIndex].beatNumber;
    } else {
      //  going backwards?
      _state = _ManualPlayerScrollAssistantState.noClue;
    }
    _lastSectionIndex = sectionIndex;

    //  compute the bpm going forward
    switch (_state) {
      case _ManualPlayerScrollAssistantState.noClue:
        //  skip the first beat number
        if (beatNumber > 0) {
          _refBeatNumber = beatNumber;
          _refDateTime = dateTime;
          _state = _ManualPlayerScrollAssistantState.tooEarly;
        }
        break;
      case _ManualPlayerScrollAssistantState.tooEarly:
        //  delay to get two points of reference
        _state = _ManualPlayerScrollAssistantState.forward;
        break;
      case _ManualPlayerScrollAssistantState.forward:
        var estimatedBeatNumber = beatNumberAt(dateTime);
        _bpm = (60 *
                (beatNumber - _refBeatNumber) *
                Duration.microsecondsPerSecond /
                dateTime.difference(_refDateTime!).inMicroseconds)
            .round();
        logger.i('forward: $beatNumber/${dateTime.difference(_refDateTime!)}'
            ' = $_bpm bpm'
            ', est: $estimatedBeatNumber'
            ', row: ${rowAtBeatNumber(beatNumber)}'
            ', error: ${beatNumber - estimatedBeatNumber}');
        break;
    }
  }

  double beatNumberAt(final DateTime dateTime) {
    return _refBeatNumber +
        _bpm * dateTime.difference(_refDateTime!).inMicroseconds / (60 * Duration.microsecondsPerSecond);
  }

  int? rowAtBeatNumber(final int beatNumber) {
    var moment = song.songMomentAtBeatNumber(beatNumber);
    if (moment == null) {
      return null;
    }
    logger.i('fixme now rowAtBeatNumber()');
    return null;
    // var gc = song.getMomentGridCoordinateFromMomentNumber(moment.momentNumber);
    // if (gc == null) {
    //   return null;
    // }
    // return gc.row;
  }

  @override
  String toString() {
    return '{bpm: $_bpm, section: $_lastSectionIndex, state: ${_state.name}}';
  }

  int _bpm;

  int _lastSectionIndex = 0;
  int _refBeatNumber = 0;
  DateTime? _refDateTime;

  final Song song;

  _ManualPlayerScrollAssistantState _state = _ManualPlayerScrollAssistantState.noClue;
}
