//  -v -o songs -x allSongs.songlyrics -a songs -f -w allSongs2.songlyrics
//  -v -o songs -x allSongs.songlyrics -a songs -f -w allSongs2.songlyrics -o songs2 -x allSongs2.songlyrics
//   -v -url http://www.bsteele.com/bsteeleMusicApp/allSongs.songlyrics -ninjam
//  -v -url http://www.bsteele.com/bsteeleMusicApp/allSongs.songlyrics

import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:bsteele_music_lib/songs/pitch.dart';
import 'package:bsteele_music_lib/songs/scale_note.dart';
import 'package:bsteele_music_lib/songs/song_base.dart';
import 'package:bsteele_music_lib/util/app_util.dart';
import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:english_words/english_words.dart';
import 'package:excel/excel.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:quiver/collection.dart';
import 'package:string_similarity/string_similarity.dart';

import 'app_logger.dart';
import 'songs/chord_descriptor.dart';
import 'songs/chord_section.dart';
import 'songs/key.dart';
import 'songs/music_constants.dart';
import 'songs/scale_chord.dart';
import 'songs/song.dart';
import 'songs/song_id.dart';
import 'songs/song_metadata.dart';
import 'songs/song_performance.dart';
import 'songs/song_update.dart';
import 'util/us_timer.dart';
import 'util/util.dart';

// ignore_for_file: avoid_print

const String _allSongPerformancesDirectoryLocation = 'communityJams/cj/Downloads';
const String _allSongPerformancesHistoricalDirectoryLocation = 'communityJams/cj/old_Downloads';
const String _junkRelativeDirectory = 'junk'; //  relative to user home
const String _allSongDirectory = 'github/allSongs.songlyrics';
const String _allSongPerformancesGithubFileLocation =
    '$_allSongDirectory/allSongPerformances${AllSongPerformances.fileExtension}';
const String _allSongsFileLocation = '$_allSongDirectory/allSongs.songlyrics';
const String _missingSongsFilePrefix = 'missing_songs_';
final String _missingSongsFileLocation = '${Util.homePath()}/Downloads/$_missingSongsFilePrefix';

final _allSongsFile = File('${Util.homePath()}/$_allSongsFileLocation');
final _allSongMetadataFileName = 'allSongs.songmetadata';
final _allSongsMetadataFile = File('${Util.homePath()}/$_allSongDirectory/$_allSongMetadataFileName');

AllSongPerformances _allSongPerformances = AllSongPerformances();
final _downloadsDirectory = '${Util.homePath()}/Downloads';
final _messagePattern = RegExp(r'(.*)\s+INFO\s+.*\s+onMessage\("\s*(.*)\s*"\)');

const _logFiles = Level.debug;
const _logMessageLines = Level.debug;
const _logManualPushes = Level.debug;
const _logPerformanceDetails = Level.debug;

final DateTime oldestSungDateTime = DateTime.now().subtract(Duration(days: 2 * 365));
final int lastSungLimitMs = oldestSungDateTime.millisecondsSinceEpoch;

const JsonDecoder _jsonDecoder = JsonDecoder();
const _jsonEncoder = const JsonEncoder.withIndent('  '); // Using two spaces for indentation

void main(List<String> args) async {
  Logger.level = Level.info;

  exit(await BsteeleMusicUtil().runMain(args));
}

/// a command line utility to help manage song list maintenance
/// to and from tools like git and the bsteele Music App.
///
///  example:
///  dart run bsteele_music_lib/lib/bsteele_music_util.dart -tomcat $CATALINA_BASE
class BsteeleMusicUtil {
  /// help message to the user
  void _help() {
    print('''
bsteeleMusicUtil:
//  a utility for the bsteele Music App
arguments:
-a {file_or_dir}    add all the .songlyrics files to the utility's allSongs list 
-autoscroll         test the auto scroll algorithm against the CJ historical data
-allSongPerformances sync with CJ performances
-attendance         CJ attendance in csv
-bpm                list the bpm's used
-chord              list the chord descriptors used
-blues              look for blues songs
-cjcsvread {file}   read a cj csv format the song metadata file
-cjcsvwrite {file}  format the song data as a CSV version of the CJ ranking metadata
-cjdiff             diff songlist
-cjgenre {file}     read the csv version of the CJ web genre file
-cjgenrewrite {file}     write the csv version of the CJ web genre file
-cjread {file)      add song metadata
-cjwrite {file)     format the song metadata
-cjwritesongs {file)     write song list of cj songs
-complexity         write songlist in order of complexity
-cover              look for cover artist hidden in the title
-expand {file}      expand a songlyrics list file to the output directory
-floatnotes         list bass notes by float frequency
-file               read the songs from the given file
-f                  force file writes over existing files
-h                  this help message
-html               HTML song list
-jamble             Jamble sync
-json {file}        pretty print a json file
-list               list all songs
-longlyrics         select for songs  with long lyrics lines
-longsections       select for songs  with long sections
-missing            list all performance songs that are missing in the song list
-ninjam             select for ninjam friendly songs
-o {output dir}     select the output directory, must be specified prior to -x
-oddmeasures        find the odd length measures in songs
-perfupdate {file}  update the song performances with a file
-perfread {file}    read the song performances from a file
-perfwrite {file}   update the song performances to a file
-popSongs           list the most popular songs
-similar            list similar titled/artist/coverArtist songs
-spreadsheet        generate history spreadsheet in excel
-stat               statistics
-tempo              tempo test
-tomcat {catalina_base}  read the tomcat logs
-url {url}          read the given url into the utility's allSongs list
-user               list contributing users
-v                  verbose output utility's allSongs list
-V                  very verbose output
-w {file}           write the utility's allSongs list to the given file
-words              show word statistics
-x                  experimental
-xmas               filter for christmas songs
-meta               print a metadata entries

note: the output directory will NOT be cleaned prior to the expansion.
this means old and stale songs might remain in the directory.
note: the modification date and time of the songlyrics file will be 
coerced to reflect the songlist's last modification for that song.
''');
  }

  /// A workaround to call the unix touch command to modify the
  /// read song's file to reflect it's last modification date in the song list.
  Future setLastModified(File file, int lastModified) async {
    var t = DateTime.fromMillisecondsSinceEpoch(lastModified);
    //print ('t: ${t.toIso8601String()}');
    //  print ('file.path: ${file.path}');
    await Process.run('bash', ['-c', 'touch --date="${t.toIso8601String()}" ${file.path}']).then((result) {
      stdout.write(result.stdout);
      stderr.write(result.stderr);
      if (result.exitCode != 0) {
        throw 'setLastModified() bad exit code: ${result.exitCode}';
      }
    });
  }

  /// A workaround method to get the async on main()
  Future<int> runMain(List<String> args) async {
    //  help if nothing to do
    if (args.isEmpty) {
      _help();
      return -1;
    }

    Logger.level = Level.info;

    //  process the requests
    for (var argCount = 0; argCount < args.length; argCount++) {
      var arg = args[argCount];
      switch (arg) {
        case '-a':
          //  insist there is another arg
          if (argCount >= args.length - 1) {
            logger.e('missing directory path for -a');
            _help();
            exit(-1);
          }
          argCount++;
          {
            Directory inputDirectory = Directory(args[argCount]);

            if (inputDirectory.statSync().type == FileSystemEntityType.directory) {
              if (!(await inputDirectory.exists())) {
                logger.e('missing directory for -a');
                _help();
                exit(-1);
              }
              _addAllSongsFromDir(inputDirectory);
              continue;
            }
          }
          File inputFile = File(args[argCount]);
          print('a: ${(await inputFile.exists())}, ${inputFile is Directory}');

          if (!(await inputFile.exists()) && inputFile is! Directory) {
            logger.e('missing input file/directory for -a: ${inputFile.path}');
            exit(-1);
          }
          _addAllSongsFromDir(inputFile);
          break;

        case '-autoscroll':
          testAutoScrollAlgorithm();
          break;

        case '-copyright':
          _copyright();
          break;

        //        case '-csv':
        //          _csv();
        //          break;

        case '-cjread': // {file}
          //  insist there is another arg
          if (argCount >= args.length - 1) {
            logger.e('missing directory path for -a');
            _help();
            exit(-1);
          }
          argCount++;
          {
            Directory inputDirectory = Directory(args[argCount]);

            if (inputDirectory.statSync().type == FileSystemEntityType.directory) {
              if (!(await inputDirectory.exists())) {
                logger.e('missing directory for -a');
                _help();
                exit(-1);
              }
              _addAllSongsFromDir(inputDirectory);
              continue;
            }
          }
          File inputFile = File(args[argCount]);
          print('a: ${(await inputFile.exists())}, ${(inputFile is Directory)}');

          if (!(await inputFile.exists()) && (inputFile is! Directory)) {
            logger.e('missing input file/directory for -a: ${inputFile.path}');
            exit(-1);
          }
          SongMetadata.fromJson(inputFile.readAsStringSync());
          break;

        case '-bpm':
          {
            Map<int, int> bpms = {};
            for (Song song in allSongs) {
              int bpm = song.beatsPerMinute;
              var n = bpms[bpm];
              bpms[bpm] = (n ?? 0) == 0 ? 1 : n! + 1;
              print('"${song.songId.songIdAsString}", bpm: $bpm');
            }
            for (int n
                in SplayTreeSet<int>()
                  ..addAll(bpms.keys)
                  ..toList()) {
              print('$n: ${bpms[n]}');
            }
            for (Song song
                in SplayTreeSet<Song>((song1, song2) {
                    var ret = song1.beatsPerMinute.compareTo(song2.beatsPerMinute);
                    if (ret != 0) {
                      return ret;
                    }
                    return song1.compareTo(song2);
                  })
                  ..addAll(allSongs)
                  ..toList()) {
              int bpm = song.beatsPerMinute;
              if (bpm > 200) {
                print('${song.title} by ${song.artist}, bpm: $bpm, beats: ${song.beatsPerBar}');
              }
            }
          }
          break;

        case '-chord':
          {
            Map<ChordDescriptor, int> chordDescriptors = {};
            //  include all for completeness
            for (var cd in ChordDescriptor.values) {
              chordDescriptors[cd] = 0;
            }
            for (Song song in allSongs) {
              for (var songMoment in song.songMoments) {
                for (var chord in songMoment.measure.chords) {
                  var cd = chord.scaleChord.chordDescriptor;
                  chordDescriptors[cd] = chordDescriptors[cd]! + 1;
                  //    print('"$chord: ", cd: $cd');
                }
              }
            }

            print('${'Name'.padLeft(15)}: ${'Count'.padLeft(6)}  ShortName');
            for (ChordDescriptor cd
                in SplayTreeSet<ChordDescriptor>((ChordDescriptor key1, ChordDescriptor key2) {
                    int ret = chordDescriptors[key2]!.compareTo(chordDescriptors[key1]!);
                    if (ret == 0) {
                      return key1.name.compareTo(key2.name);
                    }
                    return ret;
                  })
                  ..addAll(chordDescriptors.keys)
                  ..toList()) {
              print(
                '${cd.name.padLeft(15)}: ${chordDescriptors[cd].toString().padLeft(6)}'
                '  ${cd.shortName}',
              );
            }
          }
          break;

        case '-blues':
          {
            for (Song song in allSongs) {
              //  look for 12 bar sections
              int bars12 = 0;
              int barsNot12 = 0;
              for (ChordSection chordSection in song.getChordSections()) {
                if (chordSection.phrases.length == 1 && chordSection.phrases[0].measures.length == 12) {
                  bool blues = true;
                  //  fixme: jazz blues can fail here
                  SplayTreeSet<ScaleNote> set = SplayTreeSet();
                  for (var m in chordSection.phrases[0].measures) {
                    if (m.chords.length > 1) {
                      blues = false;
                      break;
                    }
                    set.add(m.chords[0].scaleChord.scaleNote);
                  }
                  if (!blues || set.length > 3) {
                    barsNot12++;
                  }
                  bars12++;
                } else {
                  barsNot12++;
                }
              }
              if (bars12 > barsNot12) {
                print('$song:');
                print('      12: $bars12, not12: $barsNot12');
              }
            }
          }
          break;

        case '-cjwrite': // {file)     format the song metadata
          //  assert there is another arg
          if (argCount >= args.length - 1) {
            logger.e('missing directory path for -a');
            exit(-1);
          }
          argCount++;
          {
            File outputFile = File(args[argCount]);

            if (await outputFile.exists() && !_force) {
              logger.e('"${outputFile.path}" already exists for -w without -f');
              exit(-1);
            }
            await outputFile.writeAsString(SongMetadata.toJson(), flush: true);
          }
          break;

        case '-cjwritesongs': // {file)
          //  assert there is another arg
          if (argCount >= args.length - 1) {
            logger.e('missing directory path for -a');
            exit(-1);
          }
          argCount++;
          {
            File outputFile = File(args[argCount]);

            if (await outputFile.exists() && !_force) {
              logger.e('"${outputFile.path}" already exists for -w without -f');
              exit(-1);
            }
            SplayTreeSet<Song> cjSongs = SplayTreeSet();
            for (Song song in allSongs) {
              var meta = SongMetadata.where(idIs: song.songId.songIdAsString, nameIs: 'jam');
              if (meta.isNotEmpty) {
                cjSongs.add(song);
                print('"${song.songId.songIdAsString}", cj:${meta.first.nameValues.first.value}');
              }
            }

            print('cjSongs: ${cjSongs.length}');

            await outputFile.writeAsString(Song.listToJson(cjSongs.toList()), flush: true);
          }
          break;

        case '-cjdiff':
          print('cjdiff:');
          //  assert there data in the songlist
          if (allSongs.isEmpty) {
            logger.e('initial song list is empty. try: ');
            exit(-1);
          }
          print('allSongs.length: ${allSongs.length}');

          //  assert there is another arg
          if (argCount >= args.length - 1) {
            logger.e('missing other file path for -cjdiff');
            exit(-1);
          }
          argCount++;
          {
            SplayTreeSet<Song> otherSongs;
            {
              File otherSongsFile = File(args[argCount]);

              if (otherSongsFile.statSync().type == FileSystemEntityType.file) {
                if (!(await otherSongsFile.exists())) {
                  logger.e('missing other file at: $otherSongsFile');
                  exit(-1);
                }
              }
              print('otherSongsFile: $otherSongsFile');

              var tempAllSongs = allSongs;
              allSongs = SplayTreeSet();
              _addAllSongsFromFile(otherSongsFile);
              otherSongs = allSongs;
              allSongs = tempAllSongs;
            }
            print('otherSongs.length: ${otherSongs.length}');

            //  compare the two song lists
            print('');
            print('missing songs:');
            for (var song in allSongs) {
              if (!otherSongs.contains(song)) {
                print('   $song');
              }
            }
            print('');
            print('added songs (should be fine):');
            for (var song in otherSongs) {
              if (!allSongs.contains(song)) {
                print('   $song');
              }
            }
            print('');
            print('changed signatures:');
            for (var song in allSongs) {
              if (otherSongs.contains(song)) {
                try {
                  var otherSong = otherSongs.firstWhere((otherSong) {
                    return otherSong.compareBySongId(song) == 0;
                  });
                  if (song.timeSignature != otherSong.timeSignature) {
                    print('   song: $otherSong');
                    print('       signature change: was: ${song.timeSignature}, new: ${otherSong.timeSignature}');
                  }
                } catch (e) {
                  print('   missing song: $song');
                }
              }
            }
            print('');
            print('changed copyrights:');
            for (var song in allSongs) {
              if (otherSongs.contains(song)) {
                try {
                  var otherSong = otherSongs.firstWhere((otherSong) {
                    return otherSong.compareBySongId(song) == 0;
                  });
                  if (song.copyright != otherSong.copyright) {
                    print('   song: $otherSong');
                    print('       was: "${song.copyright}"');
                    print('       new: "${otherSong.copyright}"');
                  }
                } catch (e) {
                  print('   missing song: $song');
                }
              }
            }
          }
          break;

        case '-cjcsvwrite': // {file}  format the song data as a CSV version of the CJ ranking metadata
          //  assert there is another arg
          if (argCount >= args.length - 1) {
            logger.e('missing directory path for -a');
            exit(-1);
          }
          argCount++;
          {
            File outputFile = File(args[argCount]);

            if (await outputFile.exists() && !_force) {
              logger.e('"${outputFile.path}" already exists for -w without -f');
              exit(-1);
            }
            await outputFile.writeAsString(_cjCsvRanking(), flush: true);
          }
          break;

        case '-cjcsvread': // {file}
          //  insist there is another arg
          if (argCount >= args.length - 1) {
            logger.e('missing directory path for -a');
            _help();
            exit(-1);
          }
          argCount++;
          {
            Directory inputDirectory = Directory(args[argCount]);

            if (inputDirectory.statSync().type == FileSystemEntityType.directory) {
              if (!(await inputDirectory.exists())) {
                logger.e('missing directory for -a');
                _help();
                exit(-1);
              }
              _addAllSongsFromDir(inputDirectory);
              continue;
            }
          }
          File inputFile = File(args[argCount]);
          print('a: ${(await inputFile.exists())}, ${inputFile is Directory}');

          if (!(await inputFile.exists()) && inputFile is! Directory) {
            logger.e('missing input file/directory for -a: ${inputFile.path}');
            exit(-1);
          }
          _cjCsvRead(inputFile.readAsStringSync());
          break;

        case '-cjgenre': // {file}
          //  insist there is another arg
          if (argCount >= args.length - 1) {
            logger.e('missing directory path for -a');
            _help();
            exit(-1);
          }
          argCount++;
          {
            File inputFile = File(args[argCount]);

            if (inputFile.statSync().type != FileSystemEntityType.file || !(await inputFile.exists())) {
              logger.e('missing file for -cjgenre');
              _help();
              exit(-1);
            }

            print('-cjgenre: $inputFile');
            final input = inputFile.openRead();
            final fields = await input.transform(utf8.decoder).transform(const CsvToListConverter(eol: '\n')).toList();

            print('${fields.runtimeType}');
            assert(fields[0][0] == 'Title');
            assert(fields[0][1] == 'Artist');
            assert(fields[0][2] == 'Year');
            assert(fields[0][3] == 'Jam');
            assert(fields[0][4] == 'Genre');
            assert(fields[0][5] == 'Subgenre');
            assert(fields[0][6] == 'Status');

            // for (var r = 1; r < fields.length; r++) {
            //   var title = fields[r][0];
            //   var artist = fields[r][1];
            //   var year = fields[r][2];
            //   var jam = fields[r][3].toString();
            //   var genre = fields[r][4];
            //   var subgenre = fields[r][5];
            //   // var status = fields[r][6];
            //   if (jam.isNotEmpty || genre.isNotEmpty || subgenre.isNotEmpty) {
            //     print('$r: "$title", $artist, $year, $jam, $genre, $subgenre');
            //   }
            // }

            //  read all songs from the standard location
            _addAllSongsFromFile(_allSongsFile);
            assert(allSongs.isNotEmpty);
            SongMetadata.fromJson(_allSongsMetadataFile.readAsStringSync());

            for (var r = 1; r < fields.length; r++) {
              var title = fields[r][0].trim();
              var artist = fields[r][1].trim();
              var year = fields[r][2].toString().trim();
              var jam = fields[r][3].toString().trim();
              var genre = fields[r][4].toString().trim();
              var subgenre = fields[r][5].toString().trim();
              var status = fields[r][6].toString().trim();

              var songId = SongId.computeSongId(title, artist, null);

              logger.t('try $songId');

              Song song;
              try {
                song = allSongs.firstWhere((e) => e.songId == songId);
              } catch (e) {
                print('Not found: title: $title, artist: $artist');
                final songs = allSongs.map((e) => e.songId.toString()).toList(growable: false);
                BestMatch bestMatch = StringSimilarity.findBestMatch(songId.toString(), songs);
                var idString = songs[bestMatch.bestMatchIndex];
                song = allSongs.firstWhere((e) => e.songId.toString() == idString);
                print(
                  '   best match: title: "${song.title}", artist: "${song.artist}"'
                  ', coverArtist: "${song.coverArtist}"',
                );
              }
              if (genre.isNotEmpty || subgenre.isNotEmpty || jam.isNotEmpty || year.isNotEmpty) {
                logger.t('$song:  genre: $genre, subgenre: $subgenre, jam: $jam, year: $year');
                if (genre.isNotEmpty) {
                  SongMetadata.addSong(song, NameValue('genre', genre));
                }
                if (subgenre.isNotEmpty) {
                  SongMetadata.addSong(song, NameValue('subgenre', subgenre));
                }
                if (jam.isNotEmpty) {
                  SongMetadata.addSong(song, NameValue('jam', jam));
                }
                if (year.isNotEmpty) {
                  SongMetadata.addSong(song, NameValue('year', year));
                }
                if (status.isNotEmpty) {
                  SongMetadata.addSong(song, NameValue('status', status));
                }
              }
            }

            logger.d(SongMetadata.toJson());
            await File('allSongs_test.songmetadata').writeAsString(SongMetadata.toJson(), flush: true);
          }
          break;

        case '-cjgenrewrite': // {file}
          //  insist there is another arg
          if (argCount >= args.length - 1) {
            logger.e('missing directory path for -a');
            _help();
            exit(-1);
          }
          argCount++;
          {
            File outputFile = File(args[argCount]);

            if (await outputFile.exists() && !_force) {
              logger.e('"${outputFile.path}" already exists for -w without -f');
              exit(-1);
            }

            //  read all songs from the standard location
            _addAllSongsFromFile(_allSongsFile);
            assert(allSongs.isNotEmpty);
            SongMetadata.fromJson(_allSongsMetadataFile.readAsStringSync());

            var converter = const ListToCsvConverter();
            List<List> rows = [];
            rows.add(['Title', 'Artist', 'Cover Artist', 'Year', 'Jam', 'Genre', 'Subgenre', 'Status']);
            for (var song in allSongs) {
              var md = SongMetadata.songMetadata(song, 'Year');
              var year = md.isNotEmpty ? md.first.value : '';
              md = SongMetadata.songMetadata(song, 'Jam');
              var jam = md.isNotEmpty ? md.first.value : '';
              md = SongMetadata.songMetadata(song, 'Genre');
              var genre = md.isNotEmpty ? md.first.value : '';
              md = SongMetadata.songMetadata(song, 'Subgenre');
              var subgenre = md.isNotEmpty ? md.first.value : '';
              md = SongMetadata.songMetadata(song, 'Status');
              var status = md.isNotEmpty ? md.first.value : '';
              rows.add([song.title, song.artist, song.coverArtist, year, jam, genre, subgenre, status]);
            }
            await outputFile.writeAsString(converter.convert(rows), flush: true);

            print('-cjgenrewrite: $outputFile');
          }
          break;

        case '-complexity':
          var songs = Song.songListFromJson(File('${Util.homePath()}/$_allSongsFileLocation').readAsStringSync());

          SplayTreeSet<Song> songSet = SplayTreeSet(Song.getComparatorByType(SongComparatorType.complexity));
          songSet.addAll(songs);
          for (Song song in songSet) {
            print('${song.getComplexity().toString().padLeft(5)}: ${song.toString()}');
          }
          print('-complexity: ');
          break;

        case '-cover':
          {
            final RegExp coverRegex = RegExp(r'cover', caseSensitive: false);
            final RegExp coverByRegex = RegExp(r', cover by ', caseSensitive: false);
            final RegExp coverByArtistRegex = RegExp(r'(.*), cover by (.*)', caseSensitive: false);
            SplayTreeSet<Song> notCoverBySet = SplayTreeSet();

            //  load local performances
            _allSongPerformances.updateFromJsonString(
              File('${Util.homePath()}/$_allSongPerformancesGithubFileLocation').readAsStringSync(),
            );

            SongMetadata.fromJson(_allSongsMetadataFile.readAsStringSync());

            //  load local songs
            var songs = Song.songListFromJson(File('${Util.homePath()}/$_allSongsFileLocation').readAsStringSync());
            _allSongPerformances.loadSongs(songs);

            SplayTreeSet<Song> removeSongs = SplayTreeSet();
            SplayTreeSet<Song> addSongs = SplayTreeSet();
            for (Song song in allSongs) {
              if (!song.title.contains(coverRegex)) {
                continue;
              }
              if (!song.title.contains(coverByRegex)) {
                notCoverBySet.add(song);
                continue;
              }
              print('"${song.title}" by ${song.artist} cover by "${song.coverArtist}"');
              print('   ${song.songId.songIdAsString}');
              if (song.coverArtist.isNotEmpty) {
                print('   coverArtist.isNotEmpty:  "${song.coverArtist}"');
              }
              RegExpMatch? m = coverByArtistRegex.firstMatch(song.title);
              assert(m != null);
              m = m!;
              var title = m.group(1);
              var coverArtist = m.group(2);
              var song2 = song.copyWith(title: title, artist: song.artist, coverArtist: coverArtist);
              print('    "${song2.title}", by "${song2.artist}", cover by "${song2.coverArtist}"');
              print('   ${song2.songId.songIdAsString}');
              print(
                '   length:  ${_allSongPerformances.bySong(song).length}'
                '/${_allSongPerformances.length}',
              );
              for (var performance in _allSongPerformances.bySong(song)) {
                print('     $performance');
              }

              assert(_allSongPerformances.setOfRequestsBySong(song).isEmpty); //  fixme eventually
              print('');
              print('   requests:  ${_allSongPerformances.setOfRequestsBySong(song).length}');
              print('');

              //  replace the song, it's performances and metadata
              _allSongPerformances.songRepair.addSong(song2);
              for (var performance in _allSongPerformances.bySong(song)) {
                var performance2 = performance.copyWith(song: song2);
                print('    2: $performance2');
                if (_allSongPerformances.removeSongPerformance(performance)) {
                  _allSongPerformances.addSongPerformance(performance2);
                }
                SongIdMetadata? songIdMetadata = SongMetadata.songIdMetadata(song);
                if (songIdMetadata != null) {
                  var songIdMetadata2 = SongIdMetadata(
                    song2.songId.songIdAsString,
                    metadata: songIdMetadata.nameValues,
                  );
                  SongMetadata.removeSongIdMetadata(songIdMetadata);
                  SongMetadata.addSongIdMetadata(songIdMetadata2);
                }
              }
              _allSongPerformances.songRepair.removeSong(song);

              removeSongs.add(song);
              addSongs.add(song2);
            }
            allSongs.addAll(addSongs);
            allSongs.removeAll(removeSongs);

            {
              //  write songs to test location
              File outputFile = File('${Util.homePath()}/$_junkRelativeDirectory/allSongs.songlyrics');
              await outputFile.writeAsString(Song.listToJson(allSongs.toList()), flush: true);
            }

            {
              //  write performances to test location
              File localSongperformances = File(
                '${Util.homePath()}/$_junkRelativeDirectory/allSongPerformances${AllSongPerformances.fileExtension}',
              );

              try {
                localSongperformances.deleteSync();
              } catch (e) {
                logger.e(e.toString());
                //exit(-1);
              }
              await localSongperformances.writeAsString(_allSongPerformances.toJsonString(), flush: true);
            }

            //  wrte metadata with corrections
            {
              File localSongMetadata = File('${Util.homePath()}/$_junkRelativeDirectory/allSongs.songmetadata');
              {
                try {
                  localSongMetadata.deleteSync();
                } catch (e) {
                  logger.e(e.toString());
                  //exit(-1);
                }
                await localSongMetadata.writeAsString(SongMetadata.toJson(), flush: true);

                if (_verbose) {
                  print('allSongPerformances location: ${localSongMetadata.path}');
                }
              }
            }

            print('');
            print('not cover by:');
            for (var song in notCoverBySet) {
              print(
                '"${song.title}"'
                ' by ${song.artist}${song.coverArtist.isEmpty ? '' : ' cover by ${song.coverArtist}'}',
              );
              continue;
            }
          }
          break;

        case '-exp':
          for (Song song in allSongs) {
            if (song.lastModifiedTime == 0) {
              print(song.toString());
            }
          }
          // for (Song song in allSongs) {
          //   var first = true;
          //   var lines = song.rawLyrics.split('\n');
          //   for (var i = 0; i < lines.length; i++) {
          //     var line = lines[i];
          //     if (line.contains('|')) {
          //       if ( first == true) {
          //         first = false;
          //         print('${song.title} by ${song.title}, songId: ${song.songId}');
          //       }
          //       print('   $i: $line');
          //     }
          //   }
          // }
          break;

        case '-expand':
          //  insist there is another arg
          if (argCount >= args.length - 1) {
            logger.e('missing file path for -x');
            _help();
            exit(-1);
          }

          argCount++;
          _file = File(args[argCount]);
          if (_file != null) {
            if (_verbose) print('input file path: ${_file.toString()}');
            if (!(await _file!.exists())) {
              logger.d(
                'input file path: ${_file.toString()} is missing${_outputDirectory.isAbsolute ? '' : ' at ${Directory.current}'}',
              );

              exit(-1);
            }

            if (_verbose) {
              logger.d('input file: ${_file.toString()}, file size: ${await _file!.length()}');
            }

            List<Song>? songs;
            if (_file!.path.endsWith('.zip')) {
              // Read the Zip file from disk.
              final bytes = await _file!.readAsBytes();

              // Decode the Zip file
              final archive = ZipDecoder().decodeBytes(bytes);

              // Extract the contents of the Zip archive
              for (final file in archive) {
                if (file.isFile) {
                  final data = file.content as List<int>;
                  songs = Song.songListFromJson(utf8.decode(data));
                }
              }
            } else {
              songs = Song.songListFromJson(_file!.readAsStringSync());
            }

            if (songs == null || songs.isEmpty) {
              logger.e('didn\'t find songs in ${_file.toString()}');
              exit(-1);
            }

            for (Song song in songs) {
              DateTime fileTime = DateTime.fromMillisecondsSinceEpoch(song.lastModifiedTime);

              //  used to spread the songs thinner than the maximum 1000 files
              //  per directory limit in github.com
              Directory songDir;
              {
                String s = song.title.replaceAll(notWordOrSpaceRegExp, '').trim().substring(0, 1).toUpperCase();
                songDir = Directory('${_outputDirectory.path}/$s');
              }
              songDir.createSync();

              File writeTo = File('${songDir.path}/${song.songId}.songlyrics');
              if (_verbose) logger.d('\t${writeTo.path}');
              String fileAsJson = song.toJsonAsFile();
              if (writeTo.existsSync()) {
                String fileAsRead = writeTo.readAsStringSync();
                if (fileAsJson != fileAsRead) {
                  writeTo.writeAsStringSync(fileAsJson, flush: true);
                  if (_verbose) {
                    print('${song.title} by ${song.artist}:  ${song.songId.toString()} ${fileTime.toIso8601String()}');
                  }
                } else {
                  if (_veryVerbose) {
                    print('${song.title} by ${song.artist}:  ${song.songId.toString()} ${fileTime.toIso8601String()}');
                    print('\tidentical');
                  }
                }
              } else {
                if (_verbose) {
                  print('${song.title} by ${song.artist}:  ${song.songId.toString()} ${fileTime.toIso8601String()}');
                }
                writeTo.writeAsStringSync(fileAsJson, flush: true);
              }

              //  force the modification date
              await setLastModified(writeTo, fileTime.millisecondsSinceEpoch);
            }
          }
          break;

        case '-spreadsheet':
          var excel = Excel.createExcel();
          _addAllSongsFromFile(_allSongsFile);

          _allSongPerformances.updateFromJsonString(
            File('${Util.homePath()}/$_allSongPerformancesGithubFileLocation').readAsStringSync(),
          );
          _allSongPerformances.loadSongs(allSongs);

          {
            //  add all the songs
            Map<Song, int> singings = {};
            for (var song in allSongs) {
              singings[song] = 0;
            }

            //  sum them up
            for (var performance in _allSongPerformances.allSongPerformanceHistory) {
              if (performance.song != null) {
                var v = singings[performance.song!];
                singings[performance.song!] = (v ?? 0) + 1;
              }
            }

            {
              List<List<CellData>> data = [];
              for (var song in allSongs) {
                List<CellData> rowData = [];
                rowData.add(CellData.byColumnEnum(ColumnEnum.title, song.title));
                rowData.add(CellData.byColumnEnum(ColumnEnum.artist, song.artist));
                rowData.add(CellData.byColumnEnum(ColumnEnum.coverArtist, song.coverArtist));
                rowData.add(CellData('Performances', 15, singings[song]!));
                data.add(rowData);
              }
              _addExcelCellDataSheet(excel, 'By Song Title', data);

              {
                SplayTreeSet<List<CellData>> sortedData = SplayTreeSet((d1, d2) {
                  bool first = true;
                  for (int col in [3, 0, 1, 2]) {
                    int ret = d1[col].value.compareTo(d2[col].value);
                    if (first) {
                      first = false;
                      ret = -ret;
                    }
                    if (ret != 0) {
                      return ret;
                    }
                  }
                  return 0;
                });
                sortedData.addAll(data);
                _addExcelCellDataSheet(excel, 'By Performances', sortedData.toList(growable: false));
              }
            }

            //  measures sung
            {
              List<List<CellData>> data = [];
              int totalMeasureCount = 0;
              int totalShortMeasureCount = 0;
              int totalOddMeasureCount = 0;
              for (var song in allSongs) {
                List<CellData> rowData = [];
                rowData.add(CellData.byColumnEnum(ColumnEnum.title, song.title)); // 0
                rowData.add(CellData.byColumnEnum(ColumnEnum.artist, song.artist)); // 1
                rowData.add(CellData.byColumnEnum(ColumnEnum.coverArtist, song.coverArtist)); // 2
                var songSingings = singings[song] ?? 0;
                rowData.add(CellData('Performances', 15, songSingings)); // 3
                rowData.add(CellData('bpm', 8, song.beatsPerMinute)); // 4
                int measureCount = 0;
                int shortMeasureCount = 0;
                int oddMeasureCount = 0;
                SplayTreeSet<String> oddBarsSet = SplayTreeSet();
                for (var lyricSection in song.lyricSections) {
                  var chordSection = song.findChordSectionByLyricSection(lyricSection);
                  chordSection = chordSection!;
                  for (var phrase in chordSection.phrases) {
                    measureCount += phrase.repeatMeasureCount;
                    for (int repeat = 0; repeat < phrase.repeatRowCount; repeat++) {
                      for (int m = 0; m < phrase.phraseMeasureCount; m++) {
                        var measure = phrase.phraseMeasureAt(m);
                        measure = measure!;
                        if (measure.beatCount < song.beatsPerBar) {
                          if ((measure.beatCount / song.beatsPerBar - 0.5).abs() < 0.00001) {
                            shortMeasureCount++;
                          } else {
                            oddMeasureCount++;
                            oddBarsSet.add(
                              'odd bar: $song: ${chordSection.sectionVersion}: '
                              '"$measure"'
                              ', beats: ${measure.beatCount} of ${song.beatsPerBar}',
                            );
                          }
                        }
                      }
                    }
                  }
                }
                for (String s in oddBarsSet) {
                  print(s);
                }
                rowData.add(CellData('bars', 10, measureCount * songSingings)); // 5
                rowData.add(CellData('short', 10, shortMeasureCount * songSingings)); // 6
                rowData.add(CellData('odd', 10, oddMeasureCount * songSingings)); // 7
                data.add(rowData);
                totalMeasureCount += measureCount;
                totalShortMeasureCount += shortMeasureCount;
                totalOddMeasureCount += oddMeasureCount;
              }
              print('');
              print('Of all measures sung:');
              print('totalMeasureCount: $totalMeasureCount');
              print('totalShortMeasureCount: $totalShortMeasureCount   (typically 2 beats in a 4 beat song)');
              print(
                'totalShortMeasureCount/totalMeasureCount: ${to6(totalShortMeasureCount / totalMeasureCount)}'
                ' = ${to3(100 * totalShortMeasureCount / totalMeasureCount)} %',
              );
              print('totalOddMeasureCount: $totalOddMeasureCount   (typically 3 beats in a 4 beat song)');
              print(
                'totalOddMeasureCount/totalMeasureCount: ${to6(totalOddMeasureCount / totalMeasureCount)}'
                ' = ${to3(100 * totalOddMeasureCount / totalMeasureCount)} %',
              );

              SplayTreeSet<List<CellData>> sortedData = SplayTreeSet((d1, d2) {
                bool first = true;
                for (int col in [5, 0, 1, 2, 3, 4, 6, 7]) {
                  int ret = d1[col].value.compareTo(d2[col].value);
                  if (first) {
                    first = false;
                    ret = -ret;
                  }
                  if (ret != 0) {
                    return ret;
                  }
                }
                return 0;
              });
              sortedData.addAll(data);
              _addExcelCellDataSheet(excel, 'By Measures Sung', sortedData.toList(growable: false));
            }
          }

          {
            List<List<CellData>> data = [];

            //  add all the songs
            Map<String, int> singings = {};

            //  sum them up
            for (var performance in _allSongPerformances.allSongPerformanceHistory) {
              var v = singings[performance.singer];
              singings[performance.singer] = (v ?? 0) + 1;
            }

            for (var singer in singings.keys) {
              data.add([CellData('Singer', 40, singer), CellData('Performances', 15, singings[singer]!)]);
            }

            SplayTreeSet<List<CellData>> sortedData = SplayTreeSet((d1, d2) {
              bool first = true;
              for (int c in [1, 0]) {
                int ret = d1[c].value.compareTo(d2[c].value);
                if (first) {
                  first = false;
                  ret = -ret;
                }
                if (ret != 0) {
                  return ret;
                }
              }
              return 0;
            });
            sortedData.addAll(data);
            _addExcelCellDataSheet(excel, 'By Singer Performances', sortedData.toList(growable: false));
          }

          //  singers per jam
          {
            List<List<CellData>> data = [];

            //  add all the jams
            Map<DateTime, Map<String, int>> jams = {};

            //  sum them up
            for (var performance in _allSongPerformances.allSongPerformanceHistory) {
              var dateTime = performance.lastSungDateTime;
              var day = DateTime(dateTime.year, dateTime.month, dateTime.day);
              // print('performance.lastSungDateTime: ${performance.lastSungDateTime} $day');
              Map<String, int>? jam = jams[day];
              if (jam == null) {
                jam = {};
                jam[performance.singer] = 1;
                jams[day] = jam;
              } else {
                jam[performance.singer] = (jam[performance.singer] ?? 0) + 1;
              }
            }
            var dayFormat = DateFormat('yyyy/MM/dd');
            for (var day in jams.keys.sorted()) {
              var jam = jams[day]!;
              var singerSet = jam.keys.sorted();
              singerSet.removeWhere((e) => e == 'unknown');
              String singers = singerSet.toString().replaceAll('{', '').replaceAll('}', '').trim();
              // print('day: ${dayFormat.format(day)}, ${jam.length}, singers: $singers');
              data.add([
                CellData('Date', 15, dayFormat.format(day)),
                CellData('Count', 8, jam.length),
                CellData('Singers', 180, singers),
              ]);
            }
            _addExcelCellDataSheet(excel, 'Singers per Jam', data.toList(growable: false));
          }

          //  singers songs sung per jam

          excel.delete('Sheet1');
          excel.setDefaultSheet('By Song Title');

          var fileBytes = excel.save();

          File('/home/bob/junk/bsteeleMusicAppHistory_${Util.utcNow()}.xlsx')
            ..createSync(recursive: true)
            ..writeAsBytesSync(fileBytes!);
          break;

        case '-f':
          _force = true;
          break;

        case '-file':
          //  insist there is another arg
          if (argCount >= args.length - 1) {
            logger.e('missing file path for -file');
            _help();
            exit(-1);
          }
          argCount++;

          File inputFile = File(args[argCount]);
          print('file: ${(await inputFile.exists())}, ${inputFile is Directory}');

          if (!(await inputFile.exists()) || inputFile.runtimeType is Directory) {
            logger.e('missing input file for -file: ${inputFile.path}');
            exit(-1);
          }
          _addAllSongsFromFile(inputFile);
          break;

        case '-floatnotes':
          for (var pitch in Pitch.sharps) {
            print(
              ' ${pitch.frequency.toStringAsFixed(9).padLeft(4 + 1 + 9)}'
              ', // ${pitch.number.toString().padLeft(2)} $pitch ',
            );
          }
          for (var pitch in Pitch.sharps) {
            print('"$pitch", // ${pitch.number.toString().padLeft(2)}  ');
          }
          break;

        case '-h':
          _help();
          break;

        case '-html':
          {
            print('''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>CJ Songlist</title>
	<style>
            .title {
                font-weight: bold
			}
            .artist {
				font-style: italic;
			}
 			.coverArtist {
				font-style: italic;
			}

        </style>
</head>
<body>
<h1>Community Jams Songlist</h1>
<ul>
''');
            for (Song song in allSongs) {
              print(
                '<li><span class="title">${song.title}</span> by <span class="artist">${song.artist}</span>'
                '${song.coverArtist.isNotEmpty ? ' cover by <span class="coverArtist">${song.coverArtist}</span>' : ''}'
                '</li>',
              );
            }
            print('''</ul>
</body>
</html>
''');
          }
          break;

        case '-json':
          //  assert there is another arg
          if (argCount >= args.length - 1) {
            logger.e('missing other file path for -json');
            exit(-1);
          }
          argCount++;

          File jsonFile = File(args[argCount]);
          final fileName = args[argCount].replaceAllMapped(RegExp(r'.*/'), (match) => '');

          var json = _jsonDecoder.convert(jsonFile.readAsStringSync());
          // print(_jsonEncoder.convert(json));

          File outFile = File('${Util.homePath()}/$_junkRelativeDirectory/$fileName');
          print('outFile: $outFile');
          outFile.writeAsStringSync(_jsonEncoder.convert(json), flush: true);
          break;

        case '-list':
          for (Song song in allSongs) {
            print('${song.title} by ${song.title}, songId: ${song.songId}');
          }
          break;

        case '-longlyrics':
          {
            allSongs.clear();
            _addAllSongsFromFile(File('allSongs.songlyrics'));
            {
              Map<Song, int> longLyrics = {};
              for (Song song in allSongs) {
                int maxLength = 0;
                for (var lyricSection in song.lyricSections) {
                  for (var line in lyricSection.lyricsLines) {
                    maxLength = max(maxLength, line.length);
                  }
                }
                if (maxLength > 150) {
                  longLyrics[song] = maxLength;
                }
              }

              SplayTreeSet<Song> sortedValues = SplayTreeSet((song1, song2) {
                int ret;
                if ((ret = -longLyrics[song1]!.compareTo(longLyrics[song2]!)) != 0) return ret;
                return song1.compareTo(song2);
              });
              sortedValues.addAll(longLyrics.keys);
              print('');
              print('long lyrics:');
              for (Song song in sortedValues) {
                print(
                  '"${song.title}" by "${song.artist}"'
                  '${song.coverArtist.isNotEmpty ? ' cover by "${song.coverArtist}' : ''}'
                  ': maxLength: ${longLyrics[song]}',
                );
              }
            }

            {
              Map<Song, int> highRowCounts = {};
              for (Song song in allSongs) {
                int maxLength = 0;
                for (var lyricSection in song.lyricSections) {
                  maxLength = max(maxLength, lyricSection.lyricsLines.length);
                }
                if (maxLength > 10) {
                  highRowCounts[song] = maxLength;
                }
              }

              SplayTreeSet<Song> sortedValues = SplayTreeSet((song1, song2) {
                int ret;
                if ((ret = -highRowCounts[song1]!.compareTo(highRowCounts[song2]!)) != 0) return ret;
                return song1.compareTo(song2);
              });
              sortedValues.addAll(highRowCounts.keys);
              print('');
              print('high row counts:');
              for (Song song in sortedValues.toList(growable: false).reversed) {
                print(
                  '"${song.title}" by "${song.artist}"'
                  '${song.coverArtist.isNotEmpty ? ' cover by "${song.coverArtist}' : ''}'
                  ': rowCounts: ${highRowCounts[song]}',
                );
              }
            }
          }
          break;

        case '-longsections':
          {
            Map<Song, int> longSections = {};
            for (Song song in allSongs) {
              int maxLength = 0;
              for (var lyricSection in song.lyricSections) {
                maxLength = max(maxLength, lyricSection.lyricsLines.length);
                // maxLength =
                //     max(maxLength, song.findChordSectionByLyricSection(lyricSection)?.rowCount(expanded: true) ?? 0);
              }
              if (maxLength >= 10) {
                longSections[song] = maxLength;
              }
            }

            SplayTreeSet<int> sortedValues = SplayTreeSet();
            sortedValues.addAll(longSections.values);
            for (int i in sortedValues.toList(growable: false).reversed) {
              SplayTreeSet<Song> sortedSongs = SplayTreeSet();
              for (Song song in longSections.keys) {
                if (longSections[song] == i) {
                  sortedSongs.add(song);
                }
              }
              for (Song song in sortedSongs) {
                print(
                  '"${song.title}" by "${song.artist}"'
                  '${song.coverArtist.isNotEmpty ? ' cover by "${song.coverArtist}' : ''}'
                  ': maxLength: $i'
                  ', last modified:'
                  ' ${song.lastModifiedTime == 0 ? 'unknown' : DateTime.fromMillisecondsSinceEpoch(song.lastModifiedTime).toString()}',
                );
              }
            }
          }
          break;

        case '-missing':
          {
            var dateFormat = DateFormat('dd-MMM-yyyy HH:mm:ss.SSS');
            var dir = Directory('${Util.homePath()}/$_allSongPerformancesHistoricalDirectoryLocation');
            SplayTreeSet<Song> missingSongsSet = SplayTreeSet();
            for (var p in _allSongPerformances.missingSongsFromPerformanceHistory) {
              var lastSungDateTime = p.lastSungDateTime;
              File file = File(
                '${dir.path}/catalina.${lastSungDateTime.year}'
                '-${lastSungDateTime.month.toString().padLeft(2, '0')}'
                '-${lastSungDateTime.day.toString().padLeft(2, '0')}'
                '.log',
              );
              if (_verbose) {
                print('missing: ${p.lastSungDateTime}: ${file.path}  ${dateFormat.format(lastSungDateTime)}');
              }

              dynamic songJson;
              for (var m in _messagePattern.allMatches(file.readAsStringSync())) {
                //  fixme: somehow the last sung date is the first of the next song sung
                var dateTime = dateFormat.parse(m.group(1)!);
                if (dateTime == lastSungDateTime) {
                  break;
                }
                // print('${m.group(1)!}:  $dateTime');
                assert(dateFormat.format(dateTime) == m.group(1)!);
                Map<String, dynamic> decoded = json.decode(m.group(2)!) as Map<String, dynamic>;
                if (decoded['song'] != null) {
                  songJson = decoded['song']; //  the prior song
                }
              }
              if (songJson != null) {
                var song = Song.fromJson(songJson);
                song.chordSectionGrid; //  force the parse of chords
                assert(song.songId.toString() == p.songIdAsString);
                if (_verbose) {
                  print('   song: ${song.songId}  vs ${p.songIdAsString} ${p.song}');
                }

                //  validate the song
                {
                  var errors = SongBase.validateChords(song.chords, song.beatsPerBar);
                  if (errors != null) {
                    logger.w('invalid chords on $song: $errors');
                    songJson = null;
                    continue;
                  }
                }
                {
                  var errors = song.validateLyrics(song.lyricSectionsAsEntryString);
                  if (errors != null) {
                    logger.w('invalid lyrics on $song: $errors');
                    songJson = null;
                    continue;
                  }
                }

                missingSongsSet.add(song);
              } else {
                if (_verbose) {
                  print('song not found: ${p.songIdAsString}');
                }
              }
            }

            if (missingSongsSet.isNotEmpty) {
              StringBuffer sb = StringBuffer();
              //  note the sorted order by title
              for (var song in missingSongsSet) {
                sb.write(sb.isEmpty ? '[\n' : ',\n'); //  start or continue
                sb.write('{ "file": "", "lastModifiedDate": ${song.lastModifiedTime}, "song":\n');
                sb.write(song.toJsonString().trim());
                sb.write('\n}');
              }
              sb.write('\n]\n');

              // print(sb.toString());
              final outputFile = File(
                '$_missingSongsFileLocation'
                '${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}'
                '.songlyrics',
              );
              print(outputFile.path);
              outputFile.writeAsStringSync(sb.toString(), flush: true);

              for (var song in missingSongsSet) {
                print('$song');
                SongMetadata.addSong(song, NameValue('status', 'uncurated'));
              }
              // print(SongMetadata.toJson());
              print('fixme:  finish the implementation for missing metadata!!!!');
            } else {
              print('there are no missing songs.');
            }
          }
          break;

        case '-ninjam':
          {
            Map<Song, int> ninjams = {};
            Map<Song, ChordSection> ninjamSections = {};

            for (Song song in allSongs) {
              ChordSection? firstChordSection;
              bool allSignificantChordSectionsMatch = true;

              var chordSections = song.getChordSections();
              if (chordSections.length == 1) {
                firstChordSection = chordSections.first;
              }

              for (ChordSection chordSection in chordSections) {
                switch (chordSection.sectionVersion.section.sectionEnum) {
                  case .intro:
                  case .outro:
                  case .tag:
                  case .coda:
                  case .bridge:
                    break;
                  default:
                    if (firstChordSection == null) {
                      firstChordSection = chordSection;
                    } else {
                      if (!listsEqual(firstChordSection.phrases, chordSection.phrases)) {
                        allSignificantChordSectionsMatch = false;
                        break;
                      }
                    }
                    break;
                }
                if (!allSignificantChordSectionsMatch) {
                  break;
                }
              }
              if (firstChordSection != null && allSignificantChordSectionsMatch) {
                int bars = firstChordSection.getTotalMoments();
                if (firstChordSection.phrases.length == 1 && firstChordSection.phrases[0].isRepeat()) {
                  bars = firstChordSection.phrases[0].measures.length;
                }
                ninjams[song] = song.timeSignature.beatsPerBar * bars;
                ninjamSections[song] = firstChordSection;
              }
            }

            SplayTreeSet<int> sortedValues = SplayTreeSet();
            sortedValues.addAll(ninjams.values);
            for (int i in sortedValues) {
              if (i > 48) {
                break;
              }
              SplayTreeSet<Song> sortedSongs = SplayTreeSet();
              for (Song song in ninjams.keys) {
                if (ninjams[song] == i) {
                  sortedSongs.add(song);
                }
              }
              for (Song song in sortedSongs) {
                print(
                  '"${song.title}" by "${song.artist}"'
                  '${song.coverArtist.isNotEmpty ? ' cover by "${song.coverArtist}' : ''}'
                  ':  /bpi $i  /bpm ${song.beatsPerMinute}  ${ninjamSections[song]?.toMarkup()}',
                );
              }
            }
          }
          break;

        case '-o':
          //  assert there is another arg
          if (argCount < args.length - 1) {
            argCount++;
            _outputDirectory = Directory(args[argCount]);
            if (_verbose) {
              logger.d('output path: ${_outputDirectory.toString()}');
            }
            if (!(await _outputDirectory.exists())) {
              if (_verbose) {
                logger.d(
                  'output path: ${_outputDirectory.toString()}'
                  ' is missing${_outputDirectory.isAbsolute ? '' : ' at ${Directory.current}'}',
                );
              }

              Directory parent = _outputDirectory.parent;
              if (!(await parent.exists())) {
                logger.d(
                  'parent path: ${parent.toString()}'
                  ' is missing${_outputDirectory.isAbsolute ? '' : ' at ${Directory.current}'}',
                );
                return -2;
              }
              _outputDirectory.createSync();
            }
          } else {
            logger.e('missing output path for -o');
            _help();
            exit(-1);
          }
          break;

        case '-oddmeasures':
          for (var song in allSongs) {
            StringBuffer sb = StringBuffer();
            for (var chordSection in song.getChordSections()) {
              for (var phrase in chordSection.phrases) {
                for (var measure in phrase.measures) {
                  if (measure.beatCount != song.beatsPerBar && measure.toString().contains('.')) {
                    sb.writeln('    ${chordSection.sectionVersion}  $measure');
                  }
                }
              }
            }
            if (sb.isNotEmpty) {
              print('${song.title} by ${song.artist}, beats: ${song.beatsPerBar}:');
              print(sb.toString());
            }
          }
          break;

        case '-allSongPerformances':
          {
            if (_verbose) {
              print('verbose -allSongPerformances:');
            }

            //  read the local directory's list of song performance files
            _allSongPerformances.clear();
            assert(_allSongPerformances.allSongPerformanceHistory.isEmpty);
            assert(_allSongPerformances.allSongPerformances.isEmpty);
            assert(_allSongPerformances.allSongPerformanceRequests.isEmpty);
            assert(_allSongPerformances.missingSongsFromPerformanceHistory.isEmpty);

            //  add the github version
            var usTimer = UsTimer();
            _allSongPerformances.updateFromJsonString(
              File('${Util.homePath()}/$_allSongPerformancesGithubFileLocation').readAsStringSync(),
            );
            print(
              'preload: usTimer: ${usTimer.seconds} s'
              ', allSongPerformances.length: ${_allSongPerformances.length}',
            );

            //  read from server logs
            print('allSongPerformances.length: ${_allSongPerformances.length}');
            print('allSongPerformanceHistory.length: ${_allSongPerformances.allSongPerformanceHistory.length}');
            print('last sung: ${_allSongPerformances.allSongPerformanceHistory.last.lastSungDateString}');
            var lastSungDateTime = _allSongPerformances.allSongPerformanceHistory.last.lastSungDateTime;
            // truncate date time to day
            lastSungDateTime = DateTime(lastSungDateTime.year, lastSungDateTime.month, lastSungDateTime.day);
            print('lastSungDateTime: $lastSungDateTime');

            {
              //  collect all the files to be read
              var dir = Directory('${Util.homePath()}/$_allSongPerformancesDirectoryLocation');
              SplayTreeSet<File> files = SplayTreeSet((key1, key2) => key1.path.compareTo(key2.path));
              for (var file in dir.listSync()) {
                if (file is File) {
                  files.add(file);
                }
              }

              print('files: ${files.length}');

              //  update from the all local server song performance log files
              for (var file in files) {
                var name = file.path.split('/').last;

                logger.log(_logFiles, 'name: $name');
                var m = _allSongPerformancesRegExp.firstMatch(name);
                if (m != null) {
                  print(name);
                  var date = Util.yyyyMMdd_HHmmssStringToDate(name);
                  if (date.compareTo(lastSungDateTime) >= 0) {
                    print('');
                    if (_verbose) {
                      print('process: file: $name');
                    }

                    //  clear all the requests so only the most current set is used
                    _allSongPerformances.clearAllSongPerformanceRequests();

                    _allSongPerformances.updateFromJsonString(file.readAsStringSync());
                    print('allSongPerformances.length: ${_allSongPerformances.length}');
                    print('allSongPerformanceHistory.length: ${_allSongPerformances.allSongPerformanceHistory.length}');
                  } else {
                    if (_verbose) {
                      print('ignore:  file: $name');
                    }
                    logger.d('ignore:  file: $name');
                  }
                }
              }

              {
                //  most recent performances, less than the limit
                SplayTreeSet<SongPerformance> performanceDelete = SplayTreeSet<SongPerformance>(
                  SongPerformance.compareByLastSungSongIdAndSinger,
                );
                for (var songPerformance in _allSongPerformances.allSongPerformances) {
                  if (songPerformance.lastSung < lastSungLimitMs
                      //  workaround for early bad singer entries
                      ||
                      (!songPerformance.singer.contains(' ') && songPerformance.singer != unknownSinger)
                  // ||
                  // songPerformance.singer.contains('Vikki') ||
                  // songPerformance.singer.contains('Alicia C.') ||
                  // songPerformance.singer.contains('Bob S.')
                  ) {
                    performanceDelete.add(songPerformance);
                  }
                  assert(!songPerformance.singer.contains('Vikki'));
                  assert(!songPerformance.singer.contains('Alicia C.'));
                  //assert(!songPerformance.singer.contains('Bob S.'));
                }

                print('performanceDelete:  length: ${performanceDelete.length}');
                for (var performance in performanceDelete) {
                  logger.log(_logPerformanceDetails, 'delete: $performance');
                  _allSongPerformances.removeSingerSong(performance.singer, performance.songIdAsString);
                  assert(!_allSongPerformances.allSongPerformances.contains(performance));
                }

                //  history
                performanceDelete.clear();
                for (var songPerformance in _allSongPerformances.allSongPerformanceHistory) {
                  if (songPerformance.lastSung < lastSungLimitMs ||
                      (!songPerformance.singer.contains(' ') && songPerformance.singer != unknownSinger) ||
                      songPerformance.singer.contains('Vikki') ||
                      songPerformance.singer.contains('Alicia C.') ||
                      songPerformance.singer.contains('Bob S.')) {
                    performanceDelete.add(songPerformance);
                  }
                }
                print('history performanceDelete:  length: ${performanceDelete.length}');
                for (var performance in performanceDelete) {
                  logger.log(_logPerformanceDetails, 'delete history: $performance');
                  _allSongPerformances.removeSingerSongHistory(performance);
                  assert(!_allSongPerformances.allSongPerformanceHistory.contains(performance));
                }
              }

              print('allSongPerformances.length: ${_allSongPerformances.length}');
              print('allSongPerformanceHistory.length: ${_allSongPerformances.allSongPerformanceHistory.length}');

              if (_veryVerbose) {
                for (var performance in _allSongPerformances.allSongPerformanceHistory) {
                  print('history:  ${performance.toString()}');
                }
              }
            }

            var songs = Song.songListFromJson(File('${Util.homePath()}/$_allSongsFileLocation').readAsStringSync());

            var corrections = _allSongPerformances.loadSongs(songs);
            print('postLoad: usTimer: ${usTimer.seconds} s, delta: ${usTimer.deltaToString()}, songs: ${songs.length}');
            print('corrections: $corrections');

            //  count the sloppy matched songs in history
            {
              var matches = 0;
              for (var performance in _allSongPerformances.allSongPerformanceHistory) {
                if (performance.song == null) {
                  print('missing song: ${performance.lowerCaseSongIdAsString}');
                } else if (performance.lowerCaseSongIdAsString != performance.song!.songId.toString().toLowerCase()) {
                  print(
                    '${performance.lowerCaseSongIdAsString}'
                    ' vs ${performance.song!.songId.toString().toLowerCase()}',
                  );
                  exit(-1);
                } else {
                  matches++;
                }
              }
              print(
                'matches:  $matches/${_allSongPerformances.allSongPerformanceHistory.length}'
                ', corrections: ${_allSongPerformances.allSongPerformanceHistory.length - matches}',
              );
            }

            SongMetadata.fromJson(_allSongsMetadataFile.readAsStringSync());
            File localSongMetadata = File('${Util.homePath()}/$_junkRelativeDirectory/allSongs.songmetadata');
            {
              SongMetadata.repairSongs(_allSongPerformances.songRepair);
              try {
                localSongMetadata.deleteSync();
              } catch (e) {
                logger.e(e.toString());
                //exit(-1);
              }
              await localSongMetadata.writeAsString(SongMetadata.toJson(), flush: true);

              if (_verbose) {
                print('allSongPerformances location: ${localSongMetadata.path}');
              }
            }

            File localSongperformances = File(
              '${Util.homePath()}/$_junkRelativeDirectory/allSongPerformances${AllSongPerformances.fileExtension}',
            );
            {
              try {
                localSongperformances.deleteSync();
              } catch (e) {
                logger.e(e.toString());
                //exit(-1);
              }
              await localSongperformances.writeAsString(_allSongPerformances.toJsonString(), flush: true);
            }

            //  time the reload
            {
              // allSongPerformances.clear();
              // SongMetadata.clear();

              print('\nreload:');
              var usTimer = UsTimer();

              _allSongPerformances.updateFromJsonString(localSongperformances.readAsStringSync());
              print('performances: ${usTimer.deltaToString()}');

              var json = File('${Util.homePath()}/$_allSongsFileLocation').readAsStringSync();
              print('song data read: ${usTimer.deltaToString()}');
              var songs = Song.songListFromJson(json);
              print('song data parsed: ${usTimer.deltaToString()}');
              var corrections = _allSongPerformances.loadSongs(songs);
              print('loadSongs: ${usTimer.deltaToString()}');

              SongMetadata.fromJson(localSongMetadata.readAsStringSync());
              print('localSongMetadata: ${usTimer.deltaToString()}');

              double seconds = usTimer.seconds;
              print(
                'reload: usTimer: $seconds s'
                ', allSongPerformances.length: ${_allSongPerformances.length}'
                ', songs.length: ${songs.length}'
                ', idMetadata.length: ${SongMetadata.idMetadata.length}'
                ', corrections: $corrections',
              );
              assert(seconds < 0.75);
            }

            // if (_verbose) {
            //   print(allSongPerformances.toString());
            // }
          }
          break;

        case '-attendance':
          {
            _allSongPerformances.clear();

            //  add the github version
            _allSongPerformances.updateFromJsonString(
              File('${Util.homePath()}/$_allSongPerformancesGithubFileLocation').readAsStringSync(),
            );
            print('performances: ${_allSongPerformances.allSongPerformanceHistory.length}');
            SplayTreeMap<DateTime, SplayTreeSet<String>> dateSingersMap =
                SplayTreeMap<DateTime, SplayTreeSet<String>>();
            for (var perf in _allSongPerformances.allSongPerformanceHistory) {
              if (perf.singer == 'unknown') continue;
              var dateTime = DateTime(
                perf.lastSungDateTime.year,
                perf.lastSungDateTime.month,
                perf.lastSungDateTime.day,
              );
              var dateSingers = dateSingersMap[dateTime] ?? SplayTreeSet<String>();
              dateSingers.add(perf.singer);
              dateSingersMap[dateTime] = dateSingers;
            }
            var bracesRegex = RegExp(r'[{}]');
            print('Date, Count, Singers');
            for (var dateTime in SplayTreeSet<DateTime>()..addAll(dateSingersMap.keys)) {
              var singers = dateSingersMap[dateTime];
              print(
                '${DateFormat('yyyy-MM-dd').format(dateTime)}, ${singers?.length}'
                ', "${singers.toString().replaceAll(bracesRegex, '')}"',
              );
            }
          }
          break;

        case '-perfupdate':
          //  assert there is another arg
          if (argCount < args.length - 1) {
            argCount++;
            var file = File(args[argCount]);

            if (await file.exists()) {
              print('\'${file.path}\' exists.');

              print('allSongPerformances: ${_allSongPerformances.length}');
              _allSongPerformances.updateFromJsonString(file.readAsStringSync());
              print('allSongPerformances: ${_allSongPerformances.length}');
            } else {
              logger.e('\'${file.path}\' does not exist.');
            }
          } else {
            logger.e('missing input path for -perf');
            _help();
            exit(-1);
          }
          break;

        case '-perfread': // {file)     format the song meta data
          //  assert there is another arg
          if (argCount >= args.length - 1) {
            logger.e('missing directory path for -perfread');
            exit(-1);
          }
          argCount++;
          {
            File inputFile = File(args[argCount]);

            if (!(await inputFile.exists())) {
              logger.e('"${inputFile.path}" is missing');
              exit(-1);
            }
            _allSongPerformances.clear();
            //  add the input version
            _allSongPerformances.updateFromJsonString(inputFile.readAsStringSync());
            var json = _jsonDecoder.convert(inputFile.readAsStringSync());
            print(_jsonEncoder.convert(json));
          }
          break;

        case '-perfwrite': // {file)     format the song meta data
          //  assert there is another arg
          if (argCount >= args.length - 1) {
            logger.e('missing directory path for -perfwrite');
            exit(-1);
          }
          if (_allSongPerformances.isEmpty) {
            logger.e('_allSongPerformances is empty');
            exit(-1);
          }
          argCount++;
          {
            File outputFile = File(args[argCount]);

            if (await outputFile.exists() && !_force) {
              logger.e('"${outputFile.path}" already exists, won\'t overwrite without -f');
              exit(-1);
            }
            outputFile.writeAsStringSync(_jsonEncoder.convert(_allSongPerformances), flush: true);
          }
          break;

        case '-popSongs': //     list the most popular songs
          {
            //  read the local directory's list of song performance files
            AllSongPerformances allSongPerformances = AllSongPerformances();

            //  add the github version
            allSongPerformances.updateFromJsonString(
              File('${Util.homePath()}/$_allSongPerformancesGithubFileLocation').readAsStringSync(),
            );

            //  load local songs
            var songs = Song.songListFromJson(File('${Util.homePath()}/$_allSongsFileLocation').readAsStringSync());
            allSongPerformances.loadSongs(songs);

            Map<Song, int> songCounts = {};
            for (var performance in allSongPerformances.allSongPerformanceHistory) {
              var song = performance.song;
              if (song != null) {
                var count = songCounts[song];
                songCounts[song] = (count == null ? 1 : count + 1);
              }
            }

            var sortMapByValue = Map.fromEntries(
              songCounts.entries.toList()..sort((e1, e2) {
                int ret = -e1.value.compareTo(e2.value);
                if (ret != 0) {
                  return ret;
                }
                return e1.key.compareTo(e2.key);
              }),
            );

            {
              int count = 0;
              int? timesSung;
              for (var entry in sortMapByValue.entries) {
                count++;
                if (count >= 40) {
                  if (timesSung == null) {
                    timesSung = entry.value;
                  } else if (timesSung > entry.value) {
                    break;
                  }
                }
                print('$count: ${entry.key}: ${entry.value}');
              }
            }
          }
          break;

        case '-similar':
          {
            if (allSongs.isEmpty) {
              _addAllSongsFromFile(_allSongsFile);
            }
            Map<String, Song> map = {};
            for (Song song in allSongs) {
              map[song.songId.songIdAsString] = song;
            }
            List<String> keys = [];

            keys.addAll(map.keys);
            List<String> listed = [];
            for (Song song in allSongs) {
              if (listed.contains(song.songId.songIdAsString)) {
                continue;
              }
              BestMatch bestMatch = StringSimilarity.findBestMatch(song.songId.songIdAsString, keys);

              SplayTreeSet<Rating> ratingsOrdered = SplayTreeSet((Rating rating1, Rating rating2) {
                var r1 = rating1.rating ?? 0;
                var r2 = rating2.rating ?? 0;
                if (r1 == r2) {
                  return 0;
                }
                return r1 < r2 ? 1 : -1;
              });
              ratingsOrdered.addAll(bestMatch.ratings);

              for (Rating rating in ratingsOrdered) {
                var r = rating.rating ?? 0;
                if (r >= 1.0) {
                  continue;
                }
                const minSimilarRating = 0.8;
                if (r >= minSimilarRating) {
                  print('$song');
                  Song? similar = map[rating.target];
                  if (similar != null) {
                    //print('"${similar.title.toString()}" by ${similar.artist.toString()}');
                    print('$similar');
                    print(' ');
                  }
                  listed.add(rating.target ?? 'null');
                }
                break;
              }
            }
          }
          break;

        case '-stat':
          print('songs: ${allSongs.length}');
          print('updates: $_updateCount');
          {
            var covers = 0;
            for (var song in allSongs) {
              if (song.title.contains('cover')) {
                covers++;
              }
            }
            print('covers: $covers');
          }
          {
            var chordDescriptorUsageMap = <ChordDescriptor, int>{};
            for (var chordDescriptor in ChordDescriptor.values) {
              chordDescriptorUsageMap[chordDescriptor] = 0;
            }
            for (var song in allSongs) {
              for (var moment in song.songMoments) {
                for (var chord in moment.measure.chords) {
                  var chordDescriptor = chord.scaleChord.chordDescriptor;
                  var count = chordDescriptorUsageMap[chordDescriptor] ?? 0;
                  chordDescriptorUsageMap[chordDescriptor] = count + 1;
                }
              }
            }
            print('chordDescriptorUsageMap: ${chordDescriptorUsageMap.keys.length}');
            var sortedValues = SplayTreeSet<int>();
            sortedValues.addAll(chordDescriptorUsageMap.values);
            for (var usage in sortedValues.toList().reversed) {
              for (var key in chordDescriptorUsageMap.keys.where((e) => chordDescriptorUsageMap[e] == usage)) {
                print('   _${key.name}, //  ${chordDescriptorUsageMap[key]}');
              }
            }
          }
          break;

        case '-jamble':
          String original_transposition_string = '';
          print('');
          print('${DateTime.now()}');
          print('allSongs:');
          print('note: songs performed prior to $oldestSungDateTime have been removed.');

          allSongs.clear();
          _addAllSongsFromFile(_allSongsFile);
          var original_allSongs = SplayTreeSet<Song>()
            ..addAll(
              allSongs.map((song) {
                return song.copySong();
              }),
            );
          AllSongPerformances original_allSongPerformances = AllSongPerformances();
          {
            original_allSongPerformances.clear();
            original_allSongPerformances.updateFromJsonString(
              File('${Util.homePath()}/$_allSongPerformancesGithubFileLocation').readAsStringSync(),
            );
            original_allSongPerformances.loadSongs(original_allSongs);
            //  print the history, include the first chord in the song
            print('');
            print('original history:');

            original_transposition_string = performanceTranspositionsToString(
              original_allSongPerformances,
              id: 'bsteele',
            );
            print(original_transposition_string);
          }

          {
            //  look for missing songs
            final RegExp missingSongsRegexp = RegExp(
              r'.*/'
              '$_missingSongsFilePrefix'
              r'\d{8}_\d{6}.songlyrics$',
              caseSensitive: false,
            );

            File? missingSongListFile;
            for (var e in SplayTreeSet<FileSystemEntity>(
              (key1, key2) => -key1.path.compareTo(key2.path),
            )..addAll(Directory(_downloadsDirectory).listSync())) {
              if (e is File && e.existsSync() && missingSongsRegexp.firstMatch(e.path) != null) {
                missingSongListFile = e;
                break;
              }
            }

            if (missingSongListFile != null) {
              print('${missingSongListFile.path}');
              print('');
              print('add missing songs:');
              for (var song in SplayTreeSet()..addAll(_songsFromFile(missingSongListFile))) {
                if (!allSongs.contains(song)) {
                  print('  $song');
                  allSongs.add(song);
                }
              }
            } else {
              // print('missing song list file not found!');
            }
          }

          //  assert there is data in the existing song list
          if (allSongs.isEmpty) {
            logger.e('initial song list is empty.');
            exit(-1);
          }
          print('allSongs.length: ${allSongs.length}');

          {
            //  write the original allSongs file
            var json = _jsonDecoder.convert(Song.listToJson(allSongs.toList()));
            File outputFile = File('${Util.homePath()}/$_junkRelativeDirectory/allSongs.songlyrics');
            outputFile.writeAsStringSync(_jsonEncoder.convert(json), flush: true);
          }

          print('');
          print('jamble:');
          File? jambleSongListFile;
          {
            final RegExp jambleSongListRegexp = RegExp(
              r'.*/jamble_allSongs_\d{8}_\d{6}.songlyrics$',
              caseSensitive: false,
            );

            for (var e in SplayTreeSet<FileSystemEntity>(
              (key1, key2) => -key1.path.compareTo(key2.path),
            )..addAll(Directory(_downloadsDirectory).listSync())) {
              if (e is File && e.existsSync() && jambleSongListRegexp.firstMatch(e.path) != null) {
                jambleSongListFile = e;
                break;
              }
            }
          }
          if (jambleSongListFile == null) {
            print('Missing the jambleSongListFile');
            exit(-1);
          }
          // print('jambleSongListFile: ${jambleSongListFile.path}');

          SplayTreeSet<Song> jambleSongs = SplayTreeSet()..addAll(_songsFromFile(jambleSongListFile));
          print('jambleSongs.length: ${jambleSongs.length}');
          assert(jambleSongs.length > 0);

          print('');
          print('replaced or missing songs:');
          SplayTreeMap<Song, Song> renameMap = SplayTreeMap();
          {
            for (var song in allSongs) {
              if (!jambleSongs.contains(song)) {
                // print('$song');

                //  look for the best matching lyrics
                var lyrics = song.lyricsAsString();
                Song? best;
                double bestSimilarity = 0;
                for (var jambleSong in jambleSongs) {
                  double similarity = lyrics.similarityTo(jambleSong.lyricsAsString());
                  if (similarity >= bestSimilarity) {
                    best = jambleSong;
                    bestSimilarity = similarity;
                  }
                }
                // print('  best match: $best,  $bestSimilarity');
                if (bestSimilarity > 0.9) {
                  //  assume it's the same song
                  print('$song\n    replaced by: $best  ($bestSimilarity)');
                  renameMap[song] = best!;
                } else {
                  print('$song NOT replaced by:\n   $best  ($bestSimilarity)');
                  // exit(-1);  //  fixme?
                }
              }
            }
            allSongs.removeAll(renameMap.keys);
            allSongs.addAll(renameMap.values);
          }

          print('');
          print('added jamble songs:');
          for (var song in jambleSongs) {
            if (!allSongs.contains(song)) {
              print('  $song');
              allSongs.add(song);
            }
          }

          //  update selected song list data
          print('');
          print('changed fields:');
          const longVersion = true;
          for (var song in allSongs) {
            if (jambleSongs.contains(song)) {
              try {
                var otherSong = jambleSongs.firstWhere((otherSong) {
                  return otherSong.compareBySongId(song) == 0;
                });
                StringBuffer out = StringBuffer();
                //  note: title, artist and cover artist are part of the id so they will match

                if (song.user == 'Unknown' || song.user == 'Shari') {
                  song.user = 'Shari C.';
                }
                if (song.user != otherSong.user) {
                  if (longVersion) out.write('\n    user: was ${song.user}, is now: ${otherSong.user}');
                  song.user = otherSong.user;
                }

                song.fileName = otherSong.fileName;
                song.dateCreated = otherSong.dateCreated;
                song.lastModifiedTime = otherSong.lastModifiedTime;

                if (song.copyright.isEmpty) {
                  if (longVersion) {
                    out.write('\n    copyright: was "${song.copyright}", is now: "${otherSong.copyright}"');
                  }
                  song.copyright = otherSong.copyright;
                }

                if (song.key != otherSong.key) {
                  if (longVersion) {
                    out.write('\n    key: was ${song.key}, is now: ${otherSong.key}');
                  }
                  song.key = otherSong.key;
                }

                if (song.beatsPerMinute != otherSong.beatsPerMinute) {
                  if (longVersion) {
                    out.write('\n    beatsPerMinute: was ${song.beatsPerMinute}, is now: ${otherSong.beatsPerMinute}');
                  }
                  song.beatsPerMinute = otherSong.beatsPerMinute;
                }

                if (song.timeSignature != otherSong.timeSignature) {
                  if (longVersion) {
                    out.write('\n    timeSignature: was ${song.timeSignature}, is now: ${otherSong.timeSignature}');
                  }
                  song.timeSignature = otherSong.timeSignature;
                }

                //  as per Shari
                if (song.chords != otherSong.chords) {
                  out.write(
                    '\n    chords were changed '
                    '${to1(100 * (1 - StringSimilarity.compareTwoStrings(song.chords, otherSong.chords)))}%',
                  );
                  song.chords = otherSong.chords;
                }
                if (song.rawLyrics != otherSong.rawLyrics) {
                  double similarity = StringSimilarity.compareTwoStrings(song.rawLyrics, otherSong.rawLyrics);
                  if (similarity < 1.0) {
                    out.write('\n    lyrics were changed ${to1(100 * (1 - similarity))} %');
                  } else {
                    //  don't comment on white space changes
                  }
                  song.rawLyrics = otherSong.rawLyrics;
                }
                if (out.isNotEmpty) {
                  print('  $song:$out');
                }
              } catch (e) {
                print('missing song: $song');
                exit(-1);
              }
            } else {
              print('$song:  not found in new song list\n');
            }
          }

          //  debug only
          // for (var song in allSongs ){
          //   print( song.songId.songIdAsString );
          //
          // }
          // exit(-1);

          //  write the expected output allSongs file
          print('');
          {
            var json = _jsonDecoder.convert(Song.listToJson(allSongs.toList()));
            File outputFile = File('${Util.homePath()}/$_junkRelativeDirectory/updated_allSongs.songlyrics');
            print('updated output file:  ${outputFile.path}');
            print('     updated allSongs.length: ${allSongs.length}');
            outputFile.writeAsStringSync(_jsonEncoder.convert(json), flush: true);
          }

          //  rewrite the jamble input file sorted by song
          print('');
          {
            var json = _jsonDecoder.convert(Song.listToJson(jambleSongs.toList()));
            File outputFile = File('${Util.homePath()}/$_junkRelativeDirectory/jamble_allSongs.songlyrics');
            print('jamble allSongs reformatted file:  ${outputFile.path}');
            print('     jamble allSongs.length: ${allSongs.length}');
            outputFile.writeAsStringSync(_jsonEncoder.convert(json), flush: true);
          }

          //  read the local directory's list of song performance files
          _allSongPerformances.clear();
          _allSongPerformances.updateFromJsonString(
            File('${Util.homePath()}/$_allSongPerformancesGithubFileLocation').readAsStringSync(),
          );

          print('');
          print(
            '_allSongPerformances.allSongPerformanceHistory.length:'
            ' ${_allSongPerformances.allSongPerformanceHistory.length}',
          );

          //  pretty print the original performance file
          {
            //  write the corrected performances
            File localSongPerformances = File(
              '${Util.homePath()}/$_junkRelativeDirectory/allSongPerformances${AllSongPerformances.fileExtension}',
            );
            if (localSongPerformances.existsSync()) {
              try {
                localSongPerformances.deleteSync();
              } catch (e) {
                logger.e(e.toString());
                exit(-1);
              }
            }
            await localSongPerformances.writeAsString(
              _allSongPerformances.toJsonString(prettyPrint: true),
              flush: true,
            );
          }

          //  rename songs from the performance list
          print('');
          print('performance history renames:');
          for (var oldSong in renameMap.keys) {
            var newSong = renameMap[oldSong];

            print('oldName: ${oldSong.songId} to ${newSong?.songId}');

            List<SongPerformance> removePerformances = [];
            List<SongPerformance> newPerformances = [];
            for (var oldPerf in _allSongPerformances.allSongPerformanceHistory.where(
              (perf) => perf.songIdAsString == oldSong.songId.songIdAsString,
            )) {
              removePerformances.add(oldPerf);
              assert(newSong?.songId != null);
              var newPerf = oldPerf.copyWith(songId: newSong!.songId);
              newPerformances.add(newPerf);
            }
            for (var oldPerf in removePerformances) {
              _allSongPerformances.removeSongPerformance(oldPerf);
            }
            for (var newPerf in newPerformances) {
              _allSongPerformances.addSongPerformance(newPerf);
            }

            for (var newPerf in _allSongPerformances.allSongPerformanceHistory.where(
              (perf) => perf.songIdAsString == newSong?.songId.songIdAsString,
            )) {
              print('  now: ${newPerf.toShortString()}');
            }
          }

          //  find the most recent jamble performance file
          File? _jamblePerformanceHistoryFile;
          {
            // jambleallSongPerformances_20251117_010352.songperformances
            final RegExp jambleSonglistRegexp = RegExp(
              r'.*/jamble_allSongPerformances_\d{8}_\d{6}.songperformances$',
              caseSensitive: false,
            );

            for (var e in SplayTreeSet<FileSystemEntity>(
              (key1, key2) => -key1.path.compareTo(key2.path),
            )..addAll(Directory(_downloadsDirectory).listSync())) {
              if (e is File && e.existsSync() && jambleSonglistRegexp.firstMatch(e.path) != null) {
                _jamblePerformanceHistoryFile = e;
                break; //  only the most recent
              }
            }
          }
          if (_jamblePerformanceHistoryFile == null) {
            print('Missing the jamblePerformanceHistoryFile');
            exit(-1);
          }
          print('');
          print('_jamblePerformanceHistoryFile: $_jamblePerformanceHistoryFile');

          SplayTreeSet<SongPerformance> jamblePerformanceList = SplayTreeSet(_compareSongPerformanceLastSung);
          SplayTreeSet<SongPerformance> jamblePerformanceAdditions = SplayTreeSet();
          AllSongPerformances jambleAllPerformances = AllSongPerformances();
          int historyLength = 0;
          {
            int length = _allSongPerformances.allSongPerformanceHistory.length;
            print('_allSongPerformances.allSongPerformanceHistory.length: ${length}');
            {
              String json = _jamblePerformanceHistoryFile.readAsStringSync();

              //  fixme: correct for error in input from Jamble
              if (json.contains('allSongPerformances') && !json.contains('allSongPerformanceHistory')) {
                json = json.replaceFirst("allSongPerformances", "allSongPerformanceHistory");
              }

              //  singer update
              json = json.replaceAll(RegExp(r'"singer" *: *"Rob W."'), '"singer":"Rob \'Bodhi\' Wolff"');

              jambleAllPerformances.updateFromJsonString(json);
            }
            if (length != _allSongPerformances.allSongPerformanceHistory.length) {
              print('length change!');
              print(
                '_allSongPerformances.allSongPerformanceHistory.length:'
                ' ${_allSongPerformances.allSongPerformanceHistory.length}',
              );
              exit(-1);
            }
            jambleAllPerformances.loadSongs(allSongs);
            jamblePerformanceList.addAll(
              jambleAllPerformances.allSongPerformanceHistory.where((p) => p.lastSung > lastSungLimitMs),
            );

            //  show renames applied
            print('');
            print('song renames applied:');
            for (var songId in jambleAllPerformances.bestMatchesMap.keys.sorted()) {
              var best = jambleAllPerformances.bestMatchesMap[songId]!.songId.songIdAsString;
              if (songId != best && songId != best.toLowerCase()) {
                print(
                  '  "$songId" =>'
                  ' "${best}"',
                );
              }
            }

            //  see that all old names have been updated
            {
              print('');
              print('find old songs in allSongs: ');
              for (var song in allSongs) {
                var otherSong = jambleAllPerformances.bestMatchesMap[song.songId.songIdAsString.toLowerCase()];
                if (otherSong != null) {
                  print('   found old song: $song');
                }
              }
            }

            {
              //  fixme: missing bpm from jamble
              print('');
              print('missing Jamble BPM:');
              int count = 0;
              SplayTreeSet<SongPerformance> jambleBpmCorrectedPerformances = SplayTreeSet(
                (key1, key2) => -SongPerformance.compareByLastSungSongIdAndSinger(key1, key2),
              );
              for (var perf in jamblePerformanceList) {
                //  reject performances that are too old
                if (perf.lastSung < lastSungLimitMs) {
                  continue;
                }

                if (perf.bpm == 0 && perf.song != null) {
                  // print('$perf: bpm: ${perf.song?.beatsPerMinute}');
                  jambleBpmCorrectedPerformances.add(
                    perf.copyWith(bpm: (perf.bpm == 0 && perf.song != null) ? perf.song!.beatsPerMinute : perf.bpm),
                  );
                  count++;
                }
              }
              if (count > 0) {
                print('   zero Jamble BPM\'s update count: $count');
              }

              //  join the performance lists
              print('');
              print('added performances from Jamble:');
              print('    jambleBpmCorrectedPerformances:  ${jambleBpmCorrectedPerformances.length}');
              historyLength = _allSongPerformances.allSongPerformanceHistory.length;
              count = 0;
              int matchCount = 0;
              for (var jamblePerformance in jambleBpmCorrectedPerformances) {
                var matches = _allSongPerformances.allSongPerformanceHistory.where((p) {
                  return p.songIdAsString == jamblePerformance.songIdAsString &&
                      p.singer == jamblePerformance.singer &&
                      (p.lastSung == jamblePerformance.lastSung
                          // ||
                          // //  fixme: the jamble utc dates were double adjusted!
                          // p.lastSung + 8 * 60 * 60 * 1000 == jamblePerformance.lastSung ||
                          // p.lastSung + 7 * 60 * 60 * 1000 == jamblePerformance.lastSung
                          ||
                          //  fixme: the jamble dates were offset?
                          p.lastSung + 1 * 60 * 60 * 1000 == jamblePerformance.lastSung ||
                          p.lastSung + -1 * 60 * 60 * 1000 == jamblePerformance.lastSung);
                });

                if (matches.isEmpty) {
                  //  fixme: the jamble utc dates were double adjusted!
                  var adjustLastSung = jamblePerformance.lastSung; //  fixme: often wrong by an hour!!!!

                  //  add performance with adjustment
                  var adjustedJamblePerformance = jamblePerformance.copyWith(
                    firstSung: min(adjustLastSung, jamblePerformance.firstSung),
                    lastSung: adjustLastSung,
                  );
                  assert(adjustedJamblePerformance.lastSung == adjustLastSung);
                  _allSongPerformances.addSongPerformance(adjustedJamblePerformance);
                  jamblePerformanceAdditions.add(adjustedJamblePerformance);
                  print(
                    '   added: ${adjustedJamblePerformance.toShortString()}'
                    '\n       ${SongPerformance.yMdHmDateFormat.format(DateTime.fromMillisecondsSinceEpoch(adjustLastSung))}'
                    ', lastSung: ${adjustedJamblePerformance.lastSung}',
                  );
                  print(
                    '       from: ${jamblePerformance.toShortString()}'
                    ', ${jamblePerformance.lastSung}',
                  );
                  assert(_allSongPerformances.allSongPerformanceHistory.contains(adjustedJamblePerformance));
                  count++;
                } else if (matches.length == 1) {
                  var performance = matches.first;
                  if (performance.lastSung != jamblePerformance.lastSung) {
                    DateTime bsteeleTime = DateTime.fromMillisecondsSinceEpoch(performance.lastSung);
                    DateTime jambleTime = DateTime.fromMillisecondsSinceEpoch(jamblePerformance.lastSung);
                    print(
                      '   lastSung timing issue: ${performance.toShortString()}'
                      '\n     bsteele: ${SongPerformance.yMdHmDateFormat.format(bsteeleTime)} (${performance.lastSung})'
                      ' vs jamble: ${SongPerformance.yMdHmDateFormat.format(jambleTime)} (${jamblePerformance.lastSung})'
                      ', delta: ${jambleTime.difference(bsteeleTime)}',
                    );
                  }
                  matchCount++;
                } else {
                  if (jamblePerformance.lastSung != matches.first.lastSung) {
                    print(
                      '  match: $jamblePerformance'
                      '\n      jamble: ${jamblePerformance.lastSung} vs ${matches.first.lastSung},'
                      ' delta: ${jamblePerformance.lastSung - matches.first.lastSung}'
                      ' = ${DateTime.fromMillisecondsSinceEpoch(jamblePerformance.lastSung).toUtc()} utc'
                      ' = ${DateTime.fromMillisecondsSinceEpoch(jamblePerformance.lastSung)}',
                    );
                  }
                  print('too many matches for: $jamblePerformance,\n');
                  for (var m in matches) {
                    print('  $m');
                  }
                  exit(-1);
                }
              }
              print('performances added:  $count');
              print('performance matches found:  $matchCount');
              if (matchCount == 0) {
                print('likely a formatting error with no matches');
                exit(-1);
              }
              historyLength += count;
              assert(historyLength == _allSongPerformances.allSongPerformanceHistory.length);
            }
          }

          print('');
          print('missing Jamble songs from performance history:');
          for (var perf in jamblePerformanceList) {
            if (perf.song == null) {
              print('  $perf');
            }
          }

          print('');
          print(
            'jamblePerformances.length:'
            ' ${jamblePerformanceList.length}',
          );
          print(
            '_allSongPerformances.length:'
            ' ${_allSongPerformances.length}',
          );

          //  find songs in the performance list that are missing
          print('');
          print('allSong missing song check:');
          assert(historyLength == _allSongPerformances.allSongPerformanceHistory.length);
          // print( 'history.length: ${_allSongPerformances.allSongPerformanceHistory.length}');
          _allSongPerformances.loadSongs(allSongs);
          // print( 'history.length: ${_allSongPerformances.allSongPerformanceHistory.length}');

          {
            int missingCount = 0;
            for (final perf in _allSongPerformances.allSongPerformanceHistory) {
              var song = perf.song;
              if (song == null) {
                print('_allSongPerformances.lost song: ${perf.songIdAsString}');
                missingCount++;
              } else {
                // print(song.toString());
                assert(allSongs.contains(song));
                if (renameMap.keys.contains(song)) {
                  print('oldSong in allSongPerformanceHistory: $song');
                  missingCount++;
                }
              }
            }
            print(missingCount == 0 ? '  no errors.' : '   $missingCount errors!');
          }

          _allSongPerformances.rebuildAllPerformancesFromHistory(lastSungLimitMs: lastSungLimitMs);

          //  assure all performance additions were added
          for (final performance in jamblePerformanceAdditions) {
            if (!_allSongPerformances.allSongPerformanceHistory.contains(performance)) {
              print('_allSongPerformances.allSongPerformanceHistory missing: ${performance.toShortString()}');
              assert(false);
            }
          }

          print('');
          print('possible copyright issues:');
          {
            final RegExp yearRegexp = RegExp(r'(\d{4})');
            final RegExp publicDomainRegexp = RegExp(r'public domain', caseSensitive: false);
            final RegExp bluesRegexp = RegExp(r'blues', caseSensitive: false);
            for (var song in allSongs) {
              var copyright = song.copyright;

              //  exceptions:
              if (song.artist == 'Vicki' ||
                  song.artist == 'blues' ||
                  publicDomainRegexp.firstMatch(copyright) != null ||
                  bluesRegexp.firstMatch(copyright) != null ||
                  song.artist.contains('Shari Cheves') ||
                  song.artist.contains('Wolff')) {
                continue;
              }

              var m = yearRegexp.firstMatch(copyright);
              if (m == null) {
                print(
                  '  ${song.title}, ${song.artist} ${song.coverArtist.isEmpty ? '' : 'cover by: ${song.coverArtist}'}'
                  '\n     copyright: "$copyright"   (missing year)',
                );
              } else if (copyright.length < 4 + 3) {
                print(
                  '  ${song.title}, ${song.artist} ${song.coverArtist.isEmpty ? '' : 'cover by: ${song.coverArtist}'}'
                  '\n     copyright: "$copyright"   (likely too short)',
                );
              }
            }
          }

          //  odd measure durations
          {
            print('');
            print('odd measure durations: ');
            Song? lastSong;
            for (var song in allSongs) {
              SplayTreeSet<ChordSection> chordSections = SplayTreeSet()..addAll(song.getChordSections());
              for (ChordSection chordSection in chordSections) {
                for (var phrase in chordSection.phrases) {
                  for (int m = 0; m < phrase.phraseMeasureCount; m++) {
                    var measure = phrase.phraseMeasureAt(m);
                    measure = measure!;
                    if (measure.beatCount < song.beatsPerBar) {
                      if ((measure.beatCount / song.beatsPerBar - 0.5).abs() < 1e-6) {
                        //  even split
                      } else {
                        if (lastSong != song) {
                          print('  $song:');
                        }
                        lastSong = song;

                        print(
                          '    ${chordSection.sectionVersion}, phrase: ${phrase.phraseIndex}, measure: $m:  '
                          '"$measure"'
                          ', beats: ${measure.beatCount} of ${song.beatsPerBar}',
                        );
                      }
                    }
                  }
                }
              }
            }
          }

          //  long lyrics
          {
            print('');
            print('long lyric sections: ');
            Song? lastSong;
            for (var song in allSongs) {
              int maxLength = 0;
              for (var lyricSection in song.lyricSections) {
                maxLength = max(maxLength, lyricSection.lyricsLines.length);
              }
              if (maxLength >= 8) {
                print('    ${song}: max lyric length: $maxLength');
              }
            }
          }

          //  write the updated performance file
          {
            //  write the corrected performances
            File localSongPerformances = File(
              '${Util.homePath()}/$_junkRelativeDirectory/updated_allSongPerformances${AllSongPerformances.fileExtension}',
            );
            if (localSongPerformances.existsSync()) {
              try {
                localSongPerformances.deleteSync();
              } catch (e) {
                logger.e(e.toString());
                exit(-1);
              }
            }
            await localSongPerformances.writeAsString(
              _allSongPerformances.toJsonString(prettyPrint: true),
              flush: true,
            );
          }

          print('');
          SongMetadata.fromJson(_allSongsMetadataFile.readAsStringSync());
          //  write the original sorted and formatted
          {
            File metadataFile = File('${Util.homePath()}/$_junkRelativeDirectory/$_allSongMetadataFileName');
            print('original metadataFile: $metadataFile, entry count: ${SongMetadata.idMetadata.length}');
            metadataFile.writeAsStringSync(
              _jsonEncoder.convert(_jsonDecoder.convert(SongMetadata.toJson())),
              flush: true,
            );
          }

          //  update renamed songs in the metadata
          print('');
          print('song metadata renames:');
          for (var oldSong in renameMap.keys.sorted()) {
            var newSong = renameMap[oldSong];
            assert(newSong != null);

            print('  oldName: ${oldSong.songId} to ${newSong?.songId}');

            SongMetadata.renameSong(oldSong, newSong!);
          }
          {
            print('');
            print('song metadata corrections:');
            HashMap<String, Song> corrections = HashMap();
            for (var idMetadata in SongMetadata.idMetadata.sorted()) {
              var matchingSongs = allSongs
                  .where((song) => song.songId.songIdAsString == idMetadata.id)
                  .toList(growable: false);
              if (matchingSongs.length != 1) {
                var newSong = jambleAllPerformances.bestMatchesMap[idMetadata.id.toLowerCase()];
                print('  metadata: ${idMetadata.id}: ${matchingSongs.length}');
                print('    to: ${newSong?.songId.songIdAsString}');
                if (newSong == null) {
                  exit(-1);
                }
                corrections[idMetadata.id] = newSong;
              }
            }
            for (var key in corrections.keys) {
              SongMetadata.renameSongId(key, corrections[key]!);
            }
          }

          //  write the jamble all performances file
          {
            jambleAllPerformances.rebuildAllPerformancesFromHistory(lastSungLimitMs: lastSungLimitMs);

            //  write the corrected performances
            File allJambleSongPerformancesFile = File(
              '${Util.homePath()}/$_junkRelativeDirectory/jamble_allPerformances${AllSongPerformances.fileExtension}',
            );
            if (allJambleSongPerformancesFile.existsSync()) {
              try {
                allJambleSongPerformancesFile.deleteSync();
              } catch (e) {
                logger.e(e.toString());
                exit(-1);
              }
            }
            await allJambleSongPerformancesFile.writeAsString(
              jambleAllPerformances.toJsonString(prettyPrint: true),
              flush: true,
            );
          }

          // for (var songIdAsString in allJamblePerformances.bestMatchesMap.keys) {
          //   print(
          //     'old id: ${songIdAsString} '
          //     'to ${allJamblePerformances.bestMatchesMap[songIdAsString]?.songId.songIdAsString}',
          //   );
          // }

          print('');
          print('validate song metadata song ids:');
          {
            int lostCount = 0;
            for (var idMetadata in SongMetadata.idMetadata) {
              var matchingSongs = allSongs
                  .where((song) => song.songId.songIdAsString == idMetadata.id)
                  .toList(growable: false);
              if (matchingSongs.length != 1) {
                print('metadata lost: ${idMetadata.id}: ${matchingSongs.length}');
                lostCount++;
              }
            }
            if (lostCount > 0) {
              exit(-1);
            }
          }

          //  diagnostic test only for the following logic!
          // SongMetadata.add(
          //   SongIdMetadata(
          //     'Song_not_to_befound',
          //     metadata: <NameValue>[
          //       NameValue(
          //         'jam',
          //         'complete_garbage',
          //       ),
          //     ],
          //   ),
          // );

          //  find any metadata with missing songs
          print('');
          print('unknown songs in metadata:');
          for (SongIdMetadata songIdMetadata in SongMetadata.idMetadata) {
            var songMatches = allSongs.where((song) => song.songId.songIdAsString == songIdMetadata.id);
            if (songMatches.isEmpty) {
              print('   unknown id: ${songIdMetadata.id}');
            }
          }

          //  write the metadata file
          print('');
          {
            File metadataFile = File('${Util.homePath()}/$_junkRelativeDirectory/updated_$_allSongMetadataFileName');
            print('metadataFile: $metadataFile, entry count: ${SongMetadata.idMetadata.length}');
            metadataFile.writeAsStringSync(
              _jsonEncoder.convert(_jsonDecoder.convert(SongMetadata.toJson())),
              flush: true,
            );
          }

          {
            String s = performanceTranspositionsToString(jambleAllPerformances, id: 'jamble');
            File file = File('${Util.homePath()}/$_junkRelativeDirectory/jamble_transpositions.txt');
            file.writeAsStringSync(s, flush: true);
          }
          {
            String s = performanceTranspositionsToString(original_allSongPerformances, id: 'bsteele');
            assert(original_transposition_string == s);
            File file = File('${Util.homePath()}/$_junkRelativeDirectory/original_transpositions.txt');
            file.writeAsStringSync(s, flush: true);
          }

          // //  diagnostics
          // print('');
          // print('bsteele:');
          // for (var p in _allSongPerformances.allSongPerformanceHistory.where(
          //   (p) => (p.song?.title.startsWith('Brandy') ?? false) //&& p.singer == 'Rob \'Bodhi\' Wolff',
          // )) {
          //   print(p.toJsonString());
          // }
          //
          // print('');
          // print('jamble:');
          // for (var p in allJamblePerformances.allSongPerformanceHistory.where(
          //   (p) => (p.song?.title.startsWith('Brandy') ?? false) //&& p.singer == 'Rob \'Bodhi\' Wolff',
          // )) {
          //   print(p.toJsonString());
          // }

          break;

        case '-test':
          {
            DateTime t = DateTime.fromMillisecondsSinceEpoch(1570675021323);
            File file = File('/home/bob/junk/j');
            await setLastModified(file, t.millisecondsSinceEpoch);
          }
          break;

        case '-tempo':
          {
            print('tempo:');
            SplayTreeSet<TempoMoment> tempoMoments = SplayTreeSet();
            String tempoPath = '${Util.homePath()}/communityJams/cj/bsteele_music_tempo';
            const year = '2024';
            const month = '09';
            const day = '07';

            {
              DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
              var s = "2012-02-27 13:27:01.123";
              //  fixme: DateFormat won't parse microseconds
              var dateTime = dateFormat.parse(s);
              print('$s equals? $dateTime');
            }

            {
              File logFile = File('$tempoPath/catalina.$year-$month-$day.log');
              //  20-Jun-2024 21:10:56.732 INFO [http-nio-8080-exec-4] com.bsteele.bsteeleMusicApp.WebSocketServer.onMessage onMessage("{ "momentNumber": -3 }")
              DateFormat dateFormat = DateFormat('dd-MMM-yyyy HH:mm:ss.SSS');

              Song song = Song.theEmptySong;
              String stateName = 'unknown';
              int lastMomentNumber = 0;
              DateTime lastDateTime = DateTime.now();

              for (var m in _messagePattern.allMatches(logFile.readAsStringSync())) {
                var dateTime = dateFormat.parse(m.group(1)!);
                // print('${m.group(1)!}:  $dateTime');
                assert(dateFormat.format(dateTime) == m.group(1)!);
                Map<String, dynamic> decoded = json.decode(m.group(2)!) as Map<String, dynamic>;
                var momentNumber = max<int>((decoded['momentNumber'] ?? 0), 0);
                if (decoded['state'] != null) {
                  stateName = decoded['state'].toString();
                }
                if (decoded['song'] != null) {
                  song = Song.fromJson(decoded['song']);
                  lastMomentNumber = 0;
                }

                // print('$dateTime: $state: momentNumber: $momentNumber, song: ${song.toString()}');
                // print('   momentNumber from $lastMomentNumber to $momentNumber');
                if (lastMomentNumber >= 0 && momentNumber > lastMomentNumber) {
                  double deltaS =
                      (dateTime.microsecondsSinceEpoch - lastDateTime.microsecondsSinceEpoch) /
                      Duration.microsecondsPerSecond;
                  int beats =
                      song.songMoments[max(momentNumber, 0)].beatNumber - song.songMoments[lastMomentNumber].beatNumber;
                  var bpm = (60 * beats / (deltaS == 0 ? 1 : deltaS)).round();
                  // print('   beat from ${song.songMoments[lastMomentNumber].beatNumber}'
                  //     ' to ${song.songMoments[momentNumber].beatNumber} = $beats beats in $deltaS s'
                  //     ' = $bpm bpm');
                  tempoMoments.add(
                    TempoMoment(
                      dateTime,
                      SongUpdateState.fromName(stateName),
                      song,
                      momentNumber: momentNumber,
                      bpm: bpm,
                    ),
                  );
                }

                lastMomentNumber = momentNumber;
                lastDateTime = dateTime;
              }
            }

            {
              // const sampleRate = 48000;
              File tempoFile = File('$tempoPath/tempo_log_$year$month$day');
              DateFormat dateFormat = DateFormat(
                'yyyy-MM-dd HH:mm:ss.SSS',
              ); //  fixme: DateFormat won't parse microseconds
              // print(tempoFile.readAsStringSync());
              // 2024-06-20 19:20:06.654485: 63246 =  1.318s =  0.759 hz = 45.536 bpm @  7911, consistent: false
              final tempoPattern = RegExp(
                r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})'
                r'\d{3}' //  fixme: DateFormat won't parse microseconds
                r':\s+bestBpm:\s+(\d+)\s+@\s+(\d+), tpm:\s+(\d+)',
                //
              );
              DateTime? lastDateTime;
              for (var m in tempoPattern.allMatches(tempoFile.readAsStringSync())) {
                print(m.group(0)!);
                var dateTime = dateFormat.parse(m.group(1)!);
                //print('${m.group(1)!}:  $dateTime');
                assert(dateTime.toString() == m.group(1)!);
                var bpm = int.parse(m.group(2)!);
                // var amp = int.parse(m.group(3)!);
                var tpm = int.parse(m.group(4)!);
                // var deltaSamplesTs = samples / sampleRate;
                // var consistent = m.group(3)!;
                lastDateTime ??= dateTime;
                // var deltaTs = (dateTime.millisecondsSinceEpoch - lastDateTime.millisecondsSinceEpoch) /
                //     Duration.millisecondsPerSecond;
                // double bpm = deltaSamplesTs == 0 ? 0 : 60 / deltaSamplesTs;
                // print('$dateTime: deltaSamplesTs: ${deltaSamplesTs.toStringAsFixed(6)}'
                //     ', deltaTs: ${deltaTs.toStringAsFixed(6)}'
                //     ', bpm: ${bpm.toStringAsFixed(6)}'
                //     ', dt_bpm: ${(60 /deltaTs).toStringAsFixed(6)}');
                // print('${dateTime.toString()}:  $bpm, $consistent');
                tempoMoments.add(TempoMoment.fromBpm(dateTime, bpm, tpm: tpm));
                lastDateTime = dateTime;
              }
            }

            //  spread the reference tempo
            {
              int referenceBpm = 0;
              Song? lastSong;
              // int tempoBeatInitialOffset = 0;
              // DateTime tempoBeatInitialDateTime = DateTime(2024);
              for (TempoMoment tempoMoment in tempoMoments) {
                if (tempoMoment.song != null) {
                  Song song = tempoMoment.song!;
                  referenceBpm = song.beatsPerMinute;
                  if (lastSong?.songId != song.songId) {
                    // tempoBeatInitialOffset = song.songMoments[max(tempoMoment.momentNumber, 0)].beatNumber;
                    // tempoBeatInitialDateTime = tempoMoment.dateTime;
                    // final DateTime dateTime;
                    // final String state;
                    // final Song? song;
                    // final int momentNumber;
                    // final double bpm;
                    // final bool? consistent;
                    // int referenceBpm;
                    lastSong = tempoMoment.song;
                  }
                } else {
                  tempoMoment.referenceBpm = referenceBpm;
                }
              }
            }

            //  output
            for (TempoMoment tempoMoment in tempoMoments) {
              print('$tempoMoment');
            }
          }
          break;

        case '-tomcat':
          //  insist there is another arg
          if (argCount >= args.length - 1) {
            logger.e('missing catalina_base path for $arg');
            _help();
            exit(-1);
          }
          argCount++;
          processCatalinaLogs(Directory(args[argCount]));
          break;

        case '-w':
          //  assert there is another arg
          if (argCount >= args.length - 1) {
            logger.e('missing directory path for -w');
            exit(-1);
          }
          argCount++;
          {
            File outputFile = File(args[argCount]);

            if (await outputFile.exists() && !_force) {
              logger.e('"${outputFile.path}" already exists for -w without -f');
              exit(-1);
            }
            if (allSongs.isEmpty) {
              logger.e('allSongs is empty for -w');
              exit(-1);
            }
            await outputFile.writeAsString(Song.listToJson(allSongs.toList()), flush: true);
          }
          break;

        case '-words':
          for (var song in allSongs) {
            print('${song.title} by ${song.artist}:');

            for (var lyricSection in song.lyricSections) {
              print('    ${lyricSection.sectionVersion} ${lyricSection.lyricsLines.length}');
              var lineNumber = 0;

              for (var line in lyricSection.lyricsLines) {
                lineNumber++;
                var syllableCount = 0;
                for (var word in line.split(_spaceRegexp)) {
                  if (word.isNotEmpty) {
                    syllableCount += syllables(word);
                    print('            $lineNumber: $syllableCount: $line: <$word>');
                  }
                }
                print('       $lineNumber: $syllableCount: $line');
              }
            }
          }

          break;

        case '-v':
          _verbose = true;
          Logger.level = Level.info;
          break;

        case '-V':
          _verbose = true;
          _veryVerbose = true;
          Logger.level = Level.info;
          break;

        case '-url':
          //  assert there is another arg
          if (argCount >= args.length - 1) {
            logger.e('missing file path for -url');
            _help();
            exit(-1);
          }
          argCount++;
          String url = args[argCount];
          logger.d("url: '$url'");
          var authority = url.replaceAll(r'http://', '');
          var path = authority.replaceAll(RegExp(r'^[.\w]*/', caseSensitive: false), '');
          authority = authority.replaceAll(RegExp(r'/.*'), '');
          logger.d('authority: <$authority>, path: <$path>');
          List<Song> addSongs =
              Song.songListFromJson(
                utf8.decode(await http.readBytes(Uri.http(authority, path))).replaceAll('": null,', '": "",'),
              ) //  cheap repair
              ;
          allSongs.addAll(addSongs);

          // {
          //   var count = 0;
          //   for (var song in allSongs) {
          //     count += song.isLyricsParseRequired ? 1 : 0;
          //   }
          //   print('isLyricsParseRequired: $count');
          // }
          break;

        case '-users':
          {
            final Map<String, String> userCorrections = {
              'pillyweed': 'Shari',
              'Pillyweed': 'Shari',
              'shari': 'Shari',
              'Cassandra': 'Shari',
            };
            for (Song song in allSongs) {
              var newUser = userCorrections[song.user];
              if (newUser != null) {
                print('$song from ${song.user} to $newUser');
                song.user = newUser;
              }
            }
          }
          {
            Map<String, int> userMap = {};
            for (Song song in allSongs) {
              var count = userMap[song.user];
              userMap[song.user] = count == null ? 1 : count + 1;
            }
            for (var user in SplayTreeSet<String>((key1, key2) {
              return -(userMap[key1] ?? 0).compareTo(userMap[key2] ?? 0);
            })..addAll(userMap.keys)) {
              print('$user: ${userMap[user]}');
            }
          }
          break;

        case '-x':
          //  https://musictheorysite.com/namethatkey/
          int diffCount = 0;
          for (var song in allSongs) {
            Map<ScaleChord, int> scaleChordUseMap = {};
            for (var lyricSection in song.lyricSections) {
              // print('${lyricSection.sectionVersion.toString().replaceFirst(':', ':')} ');
              var chordSection = song.getChordSection(lyricSection.sectionVersion);
              if (chordSection != null) {
                // print('$chordSection: ');
                for (var phrase in chordSection.phrases) {
                  // if (phrase.repeats > 0) {
                  //   print('   repeats: ${phrase.repeats}');
                  //     }
                  for (var measure in phrase.measures) {
                    for (var chord in measure.chords) {
                      var scaleChord = chord.scaleChord;
                      if (!scaleChord.scaleNote.isSilent) {
                        scaleChordUseMap[scaleChord] =
                            ((scaleChordUseMap[scaleChord]) ?? 0) + phrase.repeats * chord.beats;
                      }
                    }
                  }
                }
              } else {
                exit(-1);
              }
            }
            {
              //  weigh the diatonic weights
              List<int> weights = List<int>.filled(MusicConstants.notesPerScale, 1);
              weights[MajorDiatonic.I.index] = 5;
              weights[MajorDiatonic.IV.index] = 2;
              weights[MajorDiatonic.V.index] = 2;

              Key bestKey = Key.A;
              int max = 0;
              for (var key in Key.keysByHalfStep()) {
                //print('$key: ${notes[key.halfStep]} ${key.getMajorScaleChord()}');
                int score = 0;
                for (int degree = 0; degree < MusicConstants.notesPerScale; degree++) {
                  var scaleChord = key.getMajorDiatonicByDegree(degree);
                  score += weights[degree] * ((scaleChordUseMap[scaleChord]) ?? 0);
                  // print( '    major key chord note: $note $score $weight');
                }
                // print( '    $key score: $score');
                if (score > max) {
                  max = score;
                  bestKey = key;
                }
              }
              if (bestKey.halfStep != song.key.halfStep) {
                diffCount++;
                print('${song.title}, ${song.artist}, key: ${song.key}');
                print('    bestKey: $bestKey,  chords used: ${scaleChordUseMap.keys.toString()}');
              }
            }
          }
          print('diffCount: $diffCount');
          // for (var song in allSongs) {
          //   SplayTreeSet<ScaleChord> scaleChords = SplayTreeSet();
          //   List<int> notes = List.filled(MusicConstants.halfStepsPerOctave, 0);
          //   for (var lyricSection in song.lyricSections) {
          //     // print('${lyricSection.sectionVersion.toString().replaceFirst(':', ':')} ');
          //     var chordSection = song.getChordSection(lyricSection.sectionVersion);
          //     if (chordSection != null) {
          //       // print('$chordSection: ');
          //       for (var phrase in chordSection.phrases) {
          //         // if (phrase.repeats > 0) {
          //         //   print('   repeats: ${phrase.repeats}');
          //         // }
          //         for (var measure in phrase.measures) {
          //           for (var chord in measure.chords) {
          //             var scaleChord = chord.scaleChord;
          //             scaleChords.add(scaleChord);
          //             // print('     ${scaleChord.scaleNote} ${scaleChord.chordDescriptor}'
          //             //     ' x ${chord.beats} ${chord.slashScaleNote ?? ''}');
          //
          //             for (var note in scaleChord.chordNotes(song.key)) {
          //               if (note.isSilent) {
          //                 continue;
          //               }
          //               // print('         $note  ${note.halfStep}: ${phrase.repeats} x ${chord.beats}');
          //               notes[note.halfStep] += phrase.repeats * chord.beats;
          //             }
          //             // if (chord.slashScaleNote != null) {
          //             //   notes[chord.slashScaleNote!.halfStep] += phrase.repeats * chord.beats;
          //             // }
          //           }
          //         }
          //       }
          //     } else {
          //       exit(-1);
          //     }
          //   }
          //   {
          //     //  weight the diatonics
          //     List<int> weights = List<int>.filled(MusicConstants.notesPerScale, 1);
          //     weights[MajorDiatonic.I.index] = 5;
          //     weights[MajorDiatonic.IV.index] = 2;
          //     weights[MajorDiatonic.V.index] = 2;
          //
          //     Key bestKey = Key.A;
          //     int max = 0;
          //     for (var key in Key.keysByHalfStep()) {
          //       //print('$key: ${notes[key.halfStep]} ${key.getMajorScaleChord()}');
          //       int score = 0;
          //       for (int degree = 0; degree < MusicConstants.notesPerScale; degree++) {
          //         var scaleChord = key.getMajorDiatonicByDegree(degree);
          //         score += weights[degree] * notes[scaleChord.scaleNote.halfStep];
          //         // print( '    major key chord note: $note $score $weight');
          //       }
          //       //  print( '    $key score: $score');
          //       if (score > max) {
          //         max = score;
          //         bestKey = key;
          //       }
          //     }
          //     if (bestKey.halfStep != song.key.halfStep) {
          //       print('${song.title}, ${song.artist}, key: ${song.key}');
          //       print('    bestKey: $bestKey,  chords used: ${scaleChords.toString()}');
          //     }
          //   }
          // }
          break;

        case '-xmas':
          final RegExp christmasRegExp = RegExp(r'.*christmas.*', caseSensitive: false);
          SongMetadata.clear();
          for (Song song in allSongs) {
            if (christmasRegExp.hasMatch(song.songId.songIdAsString)) {
              SongMetadata.set(SongIdMetadata(song.songId.songIdAsString, metadata: [NameValue('christmas', '')]));
            }
          }
          print(SongMetadata.toJson());
          break;

        case '-meta':
          {
            //  the ninjam list
            const List<String> list = [
              'All Along The Watchtower, cover by Jimi Hendrix',
              'Already Gone',
              'As Tears Go By',
              'Bad',
              'Bad Bad Leroy Brown',
              'Before You Accuse Me, cover by Eric Clapton',
              'Bittersweet Symphony',
              'Black Magic Woman',
              'Black Velvet Band',
              'Bohemian Like You',
              'California Stars',
              'Call Me The Breeze, cover by Lynyrd Skynyrd',
              "Can't You See",
              'Careless Whisper',
              'Closing Time',
              'Counting Stars',
              'Creep',
              'Crossroads',
              'Da Doo Ron Ron',
              'December',
              'Demons',
              'Fadeaway',
              "Fallin'",
              "Feelin' Alright, cover by Joe Cocker",
              'Fifteen Days Under the Hood',
              'Firework',
              'Fly Away',
              'Folsom Prison Blues',
              'Fooled Around and Fell in Love',
              "Free Fallin'",
              'Get Up Stand Up',
              'Give Me One Reason',
              'Head Like A Hole',
              'Heart-Shaped Box',
              'Helpless',
              'Hey Joe',
              'High And Dry',
              'Hit The Road Jack, cover by Ray Charles',
              'Horse With No Name',
              'I Know You Rider',
              'I Washed My Hands In Muddy Water',
              'I Will Follow',
              "I'll Fly Away",
              'Island in the Sun',
              "Isn't She Lovely",
              'Johnny B. Goode',
              'Keep Your Hands To Yourself',
              'Kids',
              "Kids Don't Stand A Chance",
              'Killing the Blues, cover by Robert Plant and Alison Krauss',
              "Knockin' on Heaven's Door",
              'Laid',
              'Late In The Evening',
              'Lean On Me',
              'Learning To Fly',
              'Let the Music Play',
              'Lodi',
              'Lonely Boy',
              'Louie Louie',
              'Mack The Knife',
              'Never Been To Spain',
              'New Orleans Is Sinking',
              'One Gun',
              'Paint It Black',
              'Payphone',
              'People Get Ready',
              'Place in the Sun',
              'Pride (In the Name of Love)',
              'Radioactive',
              'Rebel Yell',
              'Riptide',
              "Rock'n Me",
              'Rocky Raccoon',
              'Round Here',
              'Route 66',
              'Royals',
              'Sail (A.D.D.)',
              'Say',
              'Secrets',
              'Seminole Wind',
              'Shambala',
              'Shape of My Heart',
              'She Hates Me',
              'Simple Man',
              'Six Underground',
              'Smells Like Teen Spirit',
              'Someone You Loved',
              'St. James Infirmary Blues',
              'Stand By Me',
              'Steal My Sunshine',
              'Stir It Up',
              'Strange Brew',
              'Sunday Morning',
              'Sweet Home Alabama',
              'Sweet Jane',
              'Take the Money And Run',
              "Takin' Care Of Business",
              'Telling Stories',
              'Thank U',
              'General, The',
              'Middle, The',
              'Rose, The',
              'Thrill Is Gone, The',
              'Too Late for Goodbyes',
              'Tupelo Honey',
              'Twist and Shout, cover by The Beatles',
              'Uprising',
              'Wagon Wheel',
              'Waiting For My Man',
              'Waterfalls',
              'Werewolves Of London',
              'What I Got',
              'What I Like About You',
              "What It's Like",
              "What's Up",
              'When Doves Cry',
              'Where Did You Sleep Last Night, cover by Nirvana',
              'Who Will Save Your Soul',
              'With or Without You',
              "You Ain't Goin' Nowhere",
              'Your Love Keeps Lifting Me Higher',
              'Zombie',
            ];
            for (var title in list) {
              var songsFound = allSongs
                  .where((song) => song.title.toLowerCase() == title.toLowerCase())
                  .toList(growable: false);
              if (songsFound.isEmpty) {
                print('//  NOT FOUND: $title');
                continue;
              }
              if (songsFound.length > 1) {
                print('//  MULTIPLES FOUND: $title');
                for (var song in songsFound) {
                  print('//    ${song.title}');
                }
              }
              print('{"id":"${songsFound[0].songId}","metadata":[{"name":"cj","value":"ninjam"}]},');
            }
          }
          break;

        default:
          print('command not understood: "$arg"');
          print('error: command not understood: "$arg"');
          exit(-1);
      }
    }

    return 0;
  }

  void _addAllSongsFromDir(dynamic inputFile) {
    print('$inputFile');
    if (inputFile is! Directory) {
      return;
    }

    List contents = inputFile.listSync();
    for (var file in contents) {
      _addAllSongsFromFile(file);
    }
    return;
  }

  void _addAllSongsFromFile(File inputFile) {
    logger.d('_addAllSongsFromFile: $inputFile');

    if (!inputFile.path.endsWith('.songlyrics')) return;
    if (_verbose) print('$inputFile');

    //  fix for bad song lyric files
    String s = inputFile.readAsStringSync();
    s = s.replaceAll('": null,', '": "",');

    //  only add the most recent modification
    List<Song> addSongs = Song.songListFromJson(s);
    for (Song song in addSongs) {
      if (allSongs.contains(song)) {
        Song listSong = allSongs.firstWhere((value) => value.songId.compareTo(song.songId) == 0);
        if (song.lastModifiedTime > listSong.lastModifiedTime) {
          allSongs.remove(listSong);
          allSongs.add(song);
          _updateCount++;
        }
      } else {
        allSongs.add(song);
      }
    }
  }

  List<Song> _songsFromFile(File inputFile) {
    logger.d('_songsFromFile: $inputFile');

    if (!inputFile.path.endsWith('.songlyrics')) return [];
    if (_verbose) print('inputFile: $inputFile');

    //  fix for bad song lyric files
    String s = inputFile.readAsStringSync();
    s = s.replaceAll('": null,', '": "",');

    //  only add the most recent modification
    return Song.songListFromJson(s);
  }

  void _copyright() {
    Map<String, SplayTreeSet<Song>> copyrights = {};
    for (Song song in allSongs) {
      String? copyright = song.copyright.trim();
      if (copyright.isEmpty) {
        continue;
      }
      //print('${song.copyright} ${song.songId.toString()}');
      SplayTreeSet<Song>? set = copyrights[copyright];
      if (set == null) {
        set = SplayTreeSet();
        set.add(song);
        copyrights[copyright] = set;
      } else {
        set.add(song);
      }
    }

    SplayTreeSet<String> orderedKeys = SplayTreeSet();
    orderedKeys.addAll(copyrights.keys);
    for (String copyright in orderedKeys) {
      print('"$copyright"');
      for (Song song in copyrights[copyright] ?? {}) {
        print('\t${song.songId.toString()}');
      }
    }
  }

  String _cjCsvRanking() {
    StringBuffer sb = StringBuffer();
    sb.write(
      'Id'
      ',ranking'
      '\n',
    );
    for (Song song in allSongs) {
      var meta = SongMetadata.where(idIs: song.songId.songIdAsString, nameIs: 'jam');
      if (meta.isNotEmpty) {
        sb.write('"${song.songId.songIdAsString}","${meta.first.nameValues.first.value}"\n');
      }
    }
    return sb.toString();
  }

  void _cjCsvRead(String input) {
    int i = 0;
    for (String line in input.split('\n')) {
      if (i > 0) {
        List<String> ranking = line.split(_csvLineSplit);
        if (ranking[1].isNotEmpty) {
          logger.t('$i: ${ranking[0]}, ${ranking[1]}');
          SongMetadata.add(SongIdMetadata(ranking[0], metadata: <NameValue>[NameValue('jam', ranking[1])]));
        }
      }
      i++;
    }
    logger.d(SongMetadata.toJson());
  }

  processCatalinaLogs(Directory logs) async {
    if (_verbose) {
      print('verbose processCatalinaLogs:');
    }

    //  read the local directory's list of song performance files
    _allSongPerformances.clear();
    assert(_allSongPerformances.allSongPerformanceHistory.isEmpty);
    assert(_allSongPerformances.allSongPerformances.isEmpty);
    assert(_allSongPerformances.allSongPerformanceRequests.isEmpty);

    //  add the github version
    var usTimer = UsTimer();
    _allSongPerformances.updateFromJsonString(
      File('${Util.homePath()}/$_allSongPerformancesGithubFileLocation').readAsStringSync(),
    );
    print(
      'preload: usTimer: ${usTimer.seconds} s'
      ', allSongPerformances.length: ${_allSongPerformances.length}',
    );

    //  read from server logs
    print('allSongPerformances.length: ${_allSongPerformances.length}');
    print(
      '_allSongPerformances.allSongPerformanceHistory.length: ${_allSongPerformances.allSongPerformanceHistory.length}',
    );
    print('last sung: ${_allSongPerformances.allSongPerformanceHistory.last.lastSungDateString}');
    var lastSungDateTime = _allSongPerformances.allSongPerformanceHistory.last.lastSungDateTime;
    // truncate date time to day
    lastSungDateTime = DateTime(lastSungDateTime.year, lastSungDateTime.month, lastSungDateTime.day);
    print('lastSungDateTime: $lastSungDateTime');

    //  collect all the files to be read
    print('logs: $logs');
    SplayTreeSet<File> files = SplayTreeSet((f1, f2) {
      return f1.path.compareTo(f2.path);
    });
    //  most recent performances, less than the limit
    final DateTime lastSungLimitDate = DateTime.fromMillisecondsSinceEpoch(lastSungLimitMs);
    {
      for (var e in logs.listSync()) {
        var date = Util.yyyyMMddStringToDate(e.path);
        if (e is File && date != null && e.path.contains('/catalina.') && date.compareTo(lastSungLimitDate) >= 0) {
          files.add(e);
        }
      }
    }
    print('files: ${files.length}');

    //  update from the tomcat session logs
    for (var file in files) {
      final messagePattern = RegExp(r' onMessage\("(.*)"\)');
      String fileAsString;
      if (file.path.endsWith('.log')) {
        fileAsString = file.readAsStringSync();
      } else if (file.path.endsWith('.log.gz')) {
        fileAsString = utf8.decode(zlib.decode(file.readAsBytesSync()));
      } else {
        print('not a log file: $file');
        continue;
      }

      bool firstLine = true;
      for (var line in fileAsString.split('\n')) {
        RegExpMatch? m = messagePattern.firstMatch(line);
        if (m != null) {
          if (firstLine) {
            print('');
            print('$file:');
            firstLine = false;
          }
          print('json: ${m.group(1)}');
          SongUpdate? songUpdate = SongUpdate.fromJson(m.group(1)!);
          if (songUpdate != null) {
            songUpdate.song;
            print('songUpdate: $songUpdate');
          }
        }
      }
    }

    //  update from the all local server song performance log files
    for (var file in files) {
      var name = file.path.split('/').last;

      logger.log(_logFiles, 'name: $name');
      var m = _catalinaRegExp.firstMatch(name);
      if (m != null) {
        print(name);
        var date = Util.yyyyMMddStringToDate(name);
        if (date != null && date.compareTo(lastSungDateTime) >= 0) {
          print('');
          if (_verbose) {
            print('process: file: $name');
          }

          //  clear all the requests so only the most current set is used
          _allSongPerformances.clearAllSongPerformanceRequests();

          _allSongPerformances.updateFromJsonString(file.readAsStringSync());
          print('allSongPerformances.length: ${_allSongPerformances.length}');
          print('allSongPerformanceHistory.length: ${_allSongPerformances.allSongPerformanceHistory.length}');
        } else {
          if (_verbose) {
            print('ignore:  file: $name');
          }
          logger.d('ignore:  file: $name');
        }
      }

      {
        SplayTreeSet<SongPerformance> performanceDelete = SplayTreeSet<SongPerformance>(
          SongPerformance.compareByLastSungSongIdAndSinger,
        );
        for (var songPerformance in _allSongPerformances.allSongPerformances) {
          if (songPerformance.lastSung < lastSungLimitMs
              //  workaround for early bad singer entries
              ||
              (!songPerformance.singer.contains(' ') && songPerformance.singer != unknownSinger)
          // ||
          // songPerformance.singer.contains('Vikki') ||
          // songPerformance.singer.contains('Alicia C.') ||
          // songPerformance.singer.contains('Bob S.')
          ) {
            performanceDelete.add(songPerformance);
          }
          assert(!songPerformance.singer.contains('Vikki'));
          assert(!songPerformance.singer.contains('Alicia C.'));
          //assert(!songPerformance.singer.contains('Bob S.'));
        }

        print('performanceDelete:  length: ${performanceDelete.length}');
        for (var performance in performanceDelete) {
          logger.log(_logPerformanceDetails, 'delete: $performance');
          _allSongPerformances.removeSingerSong(performance.singer, performance.songIdAsString);
          assert(!_allSongPerformances.allSongPerformances.contains(performance));
        }

        //  history
        performanceDelete.clear();
        for (var songPerformance in _allSongPerformances.allSongPerformanceHistory) {
          if (songPerformance.lastSung < lastSungLimitMs ||
              (!songPerformance.singer.contains(' ') && songPerformance.singer != unknownSinger) ||
              songPerformance.singer.contains('Vikki') ||
              songPerformance.singer.contains('Alicia C.') ||
              songPerformance.singer.contains('Bob S.')) {
            performanceDelete.add(songPerformance);
          }
        }
        print('history performanceDelete:  length: ${performanceDelete.length}');
        for (var performance in performanceDelete) {
          logger.log(_logPerformanceDetails, 'delete history: $performance');
          _allSongPerformances.removeSingerSongHistory(performance);
          assert(!_allSongPerformances.allSongPerformanceHistory.contains(performance));
        }
      }

      print('allSongPerformances.length: ${_allSongPerformances.length}');
      print('allSongPerformanceHistory.length: ${_allSongPerformances.allSongPerformanceHistory.length}');

      if (_verbose) {
        for (var performance in _allSongPerformances.allSongPerformanceHistory) {
          print('history:  ${performance.toString()}');
        }
      }
    }

    var songs = Song.songListFromJson(File('${Util.homePath()}/$_allSongsFileLocation').readAsStringSync());

    var corrections = _allSongPerformances.loadSongs(songs);
    print('postLoad: usTimer: ${usTimer.seconds} s, delta: ${usTimer.deltaToString()}, songs: ${songs.length}');
    print('corrections: $corrections');

    //  count the sloppy matched songs in history
    {
      var matches = 0;
      for (var performance in _allSongPerformances.allSongPerformanceHistory) {
        if (performance.song == null) {
          print('missing song: ${performance.lowerCaseSongIdAsString}');
          exit(-1);
        } else if (performance.lowerCaseSongIdAsString != performance.song!.songId.toString().toLowerCase()) {
          print(
            '${performance.lowerCaseSongIdAsString}'
            ' vs ${performance.song!.songId.toString().toLowerCase()}',
          );
          exit(-1);
        } else {
          matches++;
        }
      }
      print(
        'matches:  $matches/${_allSongPerformances.allSongPerformanceHistory.length}'
        ', corrections: ${_allSongPerformances.allSongPerformanceHistory.length - matches}',
      );
    }

    //  repair metadata song changes
    SongMetadata.fromJson(_allSongsMetadataFile.readAsStringSync());
    File localSongMetadata = File('${Util.homePath()}/$_junkRelativeDirectory/allSongs.songmetadata');
    {
      SongMetadata.repairSongs(_allSongPerformances.songRepair);
      try {
        localSongMetadata.deleteSync();
      } catch (e) {
        logger.e(e.toString());
        //exit(-1);
      }
      await localSongMetadata.writeAsString(SongMetadata.toJson(), flush: true);

      if (_verbose) {
        print('allSongPerformances location: ${localSongMetadata.path}');
      }
    }

    //  write the corrected performances
    File localSongperformances = File(
      '${Util.homePath()}/$_junkRelativeDirectory/allSongPerformances${AllSongPerformances.fileExtension}',
    );
    {
      try {
        localSongperformances.deleteSync();
      } catch (e) {
        logger.e(e.toString());
        //exit(-1);
      }
      await localSongperformances.writeAsString(_allSongPerformances.toJsonString(), flush: true);
    }

    //  time the reload
    {
      // allSongPerformances.clear();
      // SongMetadata.clear();

      print('\nreload:');
      var usTimer = UsTimer();

      _allSongPerformances.updateFromJsonString(localSongperformances.readAsStringSync());
      print('performances: ${usTimer.deltaToString()}');

      var json = File('${Util.homePath()}/$_allSongsFileLocation').readAsStringSync();
      print('song data read: ${usTimer.deltaToString()}');
      var songs = Song.songListFromJson(json);
      print('song data parsed: ${usTimer.deltaToString()}');
      var corrections = _allSongPerformances.loadSongs(songs);
      print('loadSongs: ${usTimer.deltaToString()}');

      SongMetadata.fromJson(localSongMetadata.readAsStringSync());
      print('localSongMetadata: ${usTimer.deltaToString()}');

      double seconds = usTimer.seconds;
      print(
        'reload: usTimer: $seconds s'
        ', allSongPerformances.length: ${_allSongPerformances.length}'
        ', songs.length: ${songs.length}'
        ', idMetadata.length: ${SongMetadata.idMetadata.length}'
        ', corrections: $corrections',
      );
      assert(seconds < 0.25);
    }
  }

  _addExcelCellDataSheet(Excel excel, String sheetName, List<List<CellData>> data) {
    excel.copy(excel.getDefaultSheet() ?? 'Sheet1', sheetName);
    var sheet = excel.sheets[sheetName];
    if (sheet == null) {
      return;
    }
    if (data.isEmpty) {
      return;
    }

    //  title row
    CellStyle titleCellStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('FFFF0000')),
      bottomBorder: Border(borderStyle: BorderStyle.Medium, borderColorHex: ExcelColor.fromHexString('FF0000FF')),
      textWrapping: TextWrapping.WrapText,
    );
    CellStyle songCellStyle = CellStyle(horizontalAlign: HorizontalAlign.Left, textWrapping: TextWrapping.WrapText);
    List<CellData> first = data.first;
    List<CellValue?> colNames = [];
    for (int c = 0; c < first.length; c++) {
      var cellData = first[c];
      var data = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
      data.value = TextCellValue(cellData.name);
      data.cellStyle = titleCellStyle;
    }
    sheet.appendRow(colNames);
    for (int c = 0; c < first.length; c++) {
      sheet.setColumnWidth(c, first[c].width);
    }

    //  add all the data rows
    for (var r = 0; r < data.length; r++) {
      var row = data[r];
      for (var c = 0; c < row.length; c++) {
        var cellData = row[c];
        var data = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1));

        cellData.value.runtimeType;
        switch (cellData.value.runtimeType) {
          case const (String):
            data.value = TextCellValue(cellData.value as String);
            break;
          case const (int):
            data.value = IntCellValue(cellData.value as int);
            break;
          case const (double):
            data.value = DoubleCellValue(cellData.value as double);
            break;
          default:
            logger.t('type failure: ${cellData.value.runtimeType}');
            exit(-1);
        }

        data.cellStyle = songCellStyle;
      }
    }
  }

  // void _csv() {
  //   StringBuffer sb = StringBuffer();
  //   sb.write('Title, Artist, Cover Artist'
  //       ',User'
  //       // ',Modified'
  //       ',Copyright'
  //       ',Key'
  //       ',BPM'
  //       ',Time'
  //       '\n');
  //   for (Song song in allSongs) {
  //     sb.write('"${song.title}","${song.artist}","${song.coverArtist}"'
  //         ',"${song.user}"'
  //         //  ',"${song.lastModifiedTime??''}"'
  //         ',"${song.copyright.substring(0, min(song.copyright.length, 80))}"'
  //         ',"${song.key}"'
  //         ',"${song.defaultBpm}"'
  //         ',"${song.beatsPerBar}/${song.unitsPerMeasure}"'
  //         '\n');
  //   }
  //
  //   //print(sb.toString());
  //   File writeTo = File(Util.homePath() + '/allSongs.csv');
  //   writeTo.writeAsStringSync(sb.toString(), flush: true);
  // }

  Directory _outputDirectory = Directory.current;
  SplayTreeSet<Song> allSongs = SplayTreeSet();
  File? _file;
  bool _verbose = false;
  bool _veryVerbose = false;
  bool _force = false; //  force a file write, even if it already exists
  int _updateCount = 0;
  static RegExp notWordOrSpaceRegExp = RegExp(r'[^\w\s]');
}

final RegExp _catalinaRegExp = RegExp(r'^catalina\.(\d{8}-\d{2}-\d{2})\.log'); //  allow for compressed files
final RegExp _allSongPerformancesRegExp = RegExp(r'^allSongPerformances_(\d{8}_\d{6}).songperformances$');
final RegExp _csvLineSplit = RegExp(r'[,\r]');
final RegExp _spaceRegexp = RegExp(r'\W');

enum ColumnEnum {
  title(50),
  artist(35),
  coverArtist(35),
  singer(35),
  count(10);

  const ColumnEnum(this.columnWidth);

  final double columnWidth;
}

class CellData {
  CellData(this.name, this.width, this.value);

  CellData.byColumnEnum(ColumnEnum columnEnum, this.value)
    : name = Util.camelCaseToSpace(columnEnum.name),
      width = columnEnum.columnWidth;

  final String name;
  final double width;
  final Comparable value;
}

enum MonitorState { changeOfSong, starting, measured }

testAutoScrollAlgorithm() {
  final RegExp catalinaLog = RegExp(r'/catalina\..*\.log$');
  final RegExp webSocketServerMessage = RegExp(
    r'^(.*) INFO'
    r' .* com\.bsteele\.bsteeleMusicApp\.WebSocketServer\.onMessage'
    r' onMessage\(\"(.*)\"\)$',
  );
  final RegExp bsteeleMusicAppMessage = RegExp(r'^\s*({.*})\s*$');

  //  13-Apr-2024 15:52:55.993
  DateFormat format = DateFormat("dd-MMM-yyyy hh:mm:ss.SSS");

  //  collect all the files to be read
  var dir = Directory(
    '${Util.homePath()}/'
    // '$_allSongPerformancesDirectoryLocation'
    '$_allSongPerformancesHistoricalDirectoryLocation',
    //
  );
  SplayTreeSet<File> files = SplayTreeSet((key1, key2) => key1.path.compareTo(key2.path));
  for (var file in dir.listSync()) {
    if (file is File && catalinaLog.hasMatch(file.path)) {
      files.add(file);
    }
  }

  //  update from the all local server song performance log files
  MonitorState monitorState = MonitorState.changeOfSong;
  for (var file in files) {
    var name = file.path.split('/').last;
    print('name: $name');

    var data = file.readAsStringSync();
    double lastTimeS = 0.0;
    int lastMomentNumber = 0;
    double startTimeS = 0.0;
    int startMomentNumber = 0;
    const int defaultDelay = 3;
    int delay = 0;

    SongUpdate songUpdate = SongUpdate();
    for (var line in data.split('\n')) {
      var m = webSocketServerMessage.firstMatch(line);
      if (m != null) {
        logger.log(_logMessageLines, 'message: "$line"');
        if (m.groupCount > 0) {
          var dateString = m.group(1);
          //print('   dateString: $dateString');
          if (dateString != null) {
            var dateTime = format.parse(dateString);
            var deltaTimeS = lastTimeS;
            lastTimeS = dateTime.millisecondsSinceEpoch / Duration.millisecondsPerSecond;
            deltaTimeS = lastTimeS - deltaTimeS;
            //print('   dateTime: $dateTime, delta: $deltaTimeS s');
          }

          var content = m.group(2);

          if (content != null && bsteeleMusicAppMessage.firstMatch(content) != null) {
            //  print the song update on a change of song
            var nextSongUpdate = songUpdate.updateFromJson(content);
            if (nextSongUpdate.song.songId != songUpdate.song.songId) {
              songUpdate = nextSongUpdate;
              // print('$songUpdate, beats: ${songUpdate.song.beatsPerBar}'
              //     ', ${songUpdate.song.songMoments.length}');
              monitorState = MonitorState.changeOfSong;
            } else {
              songUpdate = nextSongUpdate;
            }
            var song = songUpdate.song; //  convenience variable

            //print(' monitorState: ${monitorState.name}');
            switch (monitorState) {
              case MonitorState.changeOfSong:
                //  skip looking at the data when the song has changed
                startTimeS = lastTimeS;
                startMomentNumber = 0;
                monitorState = MonitorState.starting;
                delay = 0;
                print(
                  '\n$dateString: ${song.title} by ${song.artist}'
                  '${song.coverArtist.isEmpty ? "" : " cover by ${song.coverArtist}"}'
                  ', song BPM: ${song.beatsPerMinute}:',
                );
                break;
              case MonitorState.starting:
                if (songUpdate.state != SongUpdateState.playing) {
                  delay = 0;
                  break;
                }
                //  reset on a backup
                if (songUpdate.momentNumber <= lastMomentNumber) {
                  delay = 0;
                  break;
                }
                //  count in will have negative moment numbers
                if (songUpdate.momentNumber > 0) {
                  delay++;
                  if (delay < defaultDelay) break;
                  //  use the second section played as a start for the measurement of the BPM
                  startTimeS = lastTimeS;
                  startMomentNumber = songUpdate.momentNumber;
                  monitorState = MonitorState.measured;
                }
                break;

              case MonitorState.measured:
                //  reset on a backup or restart
                if (songUpdate.momentNumber <= lastMomentNumber) {
                  monitorState = MonitorState.starting;
                  delay = 0;
                  break;
                }

                if (song.songMoments.isEmpty) {
                  print('bad song:  $song');
                } else {
                  // print('good song:  $song');
                  if (!(songUpdate.momentNumber >= 0 && songUpdate.momentNumber < song.songMoments.length)) {
                    print('songUpdate.momentNumber: ${songUpdate.momentNumber}/${song.songMoments.length}');
                    assert(songUpdate.momentNumber >= 0 && songUpdate.momentNumber < song.songMoments.length);
                  }
                  int beatCountFromStart =
                      song.songMoments[songUpdate.momentNumber].beatNumber -
                      song.songMoments[startMomentNumber].beatNumber;
                  double measuredBpm = Duration.secondsPerMinute * beatCountFromStart / (lastTimeS - startTimeS);
                  double songDt =
                      song.getSongTimeAtMoment(songUpdate.momentNumber) - song.getSongTimeAtMoment(startMomentNumber);
                  logger.log(
                    _logManualPushes,
                    '     moment: ${songUpdate.momentNumber.toString().padLeft(3)}:'
                    ', beatCountFromStart: ${beatCountFromStart.toString().padLeft(4)}'
                    ', t: ${songDt.toStringAsFixed(3).padLeft(7)}'
                    ' vs ${(lastTimeS - startTimeS).toStringAsFixed(3).padLeft(7)}'
                    ', bpm: ${measuredBpm.toStringAsFixed(3).padLeft(7)}',
                  );
                }
                break;
            }

            // print('$dateString: $content');
            // print('      since: ${(lastTimeS - startTimeS).toStringAsFixed(3)}'
            //     ', startMomentNumber: $startMomentNumber'
            //     ', startT: ${song.getSongTimeAtMoment(startMomentNumber).toStringAsFixed(3)}'
            //     // ', startTimeMs: $startTimeMs, lastTimeMs: $lastTimeMs
            //     '\n');

            lastMomentNumber = songUpdate.momentNumber;
          } else {
            print('no bsteeleMusicAppMessage match: "$content"');
          }
        }
      } else {
        print('   line: "$line"');
      }
    }
  }
}

class TempoMoment implements Comparable<TempoMoment> {
  TempoMoment(this.dateTime, this.state, this.song, {this.momentNumber = 0, int? bpm, int? tpm})
    : bpm = bpm ?? song?.beatsPerMinute.toInt() ?? 0,
      referenceBpm = song?.beatsPerMinute ?? bpm?.round() ?? 0,
      tpm = tpm ?? 0;

  TempoMoment.fromBpm(this.dateTime, this.bpm, {int? tpm})
    : state = SongUpdateState.drumTempo,
      song = null,
      momentNumber = 0,
      referenceBpm = bpm.round(),
      tpm = tpm ?? 0;

  TempoMoment copyWith({
    DateTime? dateTime,
    SongUpdateState? state,
    Song? song,
    int? momentNumber,
    int? bpm,
    int? tpm,
  }) {
    return TempoMoment(
      dateTime ?? this.dateTime,
      state ?? this.state,
      song ?? this.song,
      momentNumber: this.momentNumber,
      bpm: bpm ?? this.bpm,
      tpm: tpm ?? this.tpm,
    );
  }

  @override
  int compareTo(TempoMoment other) {
    int ret = dateTime.compareTo(other.dateTime);
    if (ret != 0) return ret;
    ret = state.index.compareTo(other.state.index);
    if (ret != 0) return ret;
    ret = momentNumber.compareTo(other.momentNumber);
    if (ret != 0) return ret;
    if (song != null) {
      if (other.song == null) {
        return -1;
      } else {
        ret = song!.compareTo(other.song!);
      }
    }
    if (ret != 0) return ret;
    return 0;
  }

  @override
  String toString() {
    int bpmFound = (song == null ? bpm : (song?.beatsPerMinute ?? 0));
    String songDataString = '';
    if (song != null) {
      var songMoment = song!.songMoments[momentNumber];
      songDataString =
          ', @${momentNumber.toString().padLeft(3)}, b#: ${songMoment.beatNumber}'
          ' $song, beatsPerBar: ${song!.beatsPerBar}';
    }
    return '$dateTime: ${state.name.padLeft(10)}'
        ', bpm: ${bpmFound.toString().padLeft(3)}'
        ', tpm: ${tpm.toString().padLeft(3)}'
        '$songDataString'
        '${song == null && referenceBpm > 0 && bpmFound > 0 ? ', x${(referenceBpm / bpmFound).toStringAsFixed(3)}' : ''}';
  }

  final DateTime dateTime;
  final SongUpdateState state;
  final Song? song;
  final int momentNumber;
  final int bpm;
  final int tpm;
  int referenceBpm;
}

int _compareSongPerformanceLastSung(final SongPerformance perf, final SongPerformance other) {
  if (identical(perf, other)) {
    return 0;
  }

  int ret = perf.songIdAsString.compareTo(other.songIdAsString); //  exact
  if (ret != 0) {
    return ret;
  }
  ret = perf.singer.compareTo(other.singer);
  if (ret != 0) {
    return ret;
  }
  ret = perf.lastSung.compareTo(other.lastSung);
  if (ret != 0) {
    if ((perf.lastSung - other.lastSung).abs() > 60 * Duration.millisecondsPerSecond) {
      return ret;
    }
  }

  // ret = key.compareTo(other.key);
  // if (ret != 0) {
  //   return ret;
  // }
  // ret = _bpm.compareTo(other._bpm);
  // if (ret != 0) {
  //   return ret;
  // }

  return 0;
}

String performanceTranspositionsToString(final AllSongPerformances allSongPerformances, {final String id = ''}) {
  StringBuffer sb = StringBuffer();
  DateFormat format = DateFormat('yyyy-MM-dd HH:mm:ss');
  for (var p in allSongPerformances.allSongPerformanceHistory) {
    if (p.song == null) {
      sb.writeln(
        '${format.format(DateTime.fromMillisecondsSinceEpoch(p.lastSung))}'
        ' singer: ${p.singer}: MISSING SONG!, singing key: ${p.key}',
      );
      continue;
    }

    var song = p.song!;
    sb.write(
      '${format.format(DateTime.fromMillisecondsSinceEpoch(p.lastSung))}'
      '${id.isEmpty ? '' : ', ${id.padLeft(7)}'}'
      ', singer: ${p.singer}: "${p.song.toString()}", song key: ${song.key}, singing key: ${p.key}',
    );
    var chords = song.songMoments.first.measure.chords;
    if (chords.isNotEmpty) {
      int transpositionOffset = p.key.getHalfStep() - song.key.getHalfStep();
      var chord = chords.first;
      var transposedChord = chord.transpose(song.key, transpositionOffset);
      sb.write(',  first chord: $chord, transposed: $transposedChord');
    } else {
      sb.write(',  first chord: empty');
    }
    sb.writeln('');
  }
  sb.writeln('');

  return sb.toString();
}
