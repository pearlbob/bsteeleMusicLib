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
import 'songs/chord_descriptor.dart';
import 'songs/chord_section.dart';
import 'songs/key.dart';
import 'songs/music_constants.dart';
import 'songs/scale_chord.dart';
import 'songs/section.dart';
import 'songs/song.dart';
import 'songs/song_id.dart';
import 'songs/song_metadata.dart';
import 'songs/song_performance.dart';
import 'songs/song_update.dart';
import 'util/us_timer.dart';
import 'util/util.dart';
import 'package:csv/csv.dart';
import 'package:english_words/english_words.dart';
import 'package:excel/excel.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:quiver/collection.dart';
import 'package:string_similarity/string_similarity.dart';

import 'app_logger.dart';

const String _allSongPerformancesDirectoryLocation = 'communityJams/cj/Downloads';
const String _junkRelativeDirectory = 'junk'; //  relative to user home
const String _allSongDirectory = 'github/allSongs.songlyrics';
const String _allSongPerformancesGithubFileLocation = '$_allSongDirectory/allSongPerformances.songperformances';
const String _allSongsFileLocation = '$_allSongDirectory/allSongs.songlyrics';
final _allSongsFile = File('${Util.homePath()}/$_allSongsFileLocation');
final _allSongsMetadataFile = File('${Util.homePath()}/$_allSongDirectory/allSongs.songmetadata');
AllSongPerformances allSongPerformances = AllSongPerformances();

const _logFiles = Level.debug;
const _logPerformanceDetails = Level.debug;

final int lastSungLimit = DateTime.now().millisecondsSinceEpoch - 2 * Duration.millisecondsPerDay * 365;

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
    logger.i('''
bsteeleMusicUtil:
//  a utility for the bsteele Music App
arguments:
-a {file_or_dir}    add all the .songlyrics files to the utility's allSongs list 
-allSongPerformances sync with CJ performances
-bpm                list the bpm's used
-cjwrite {file)     format the song metadata
-cjwritesongs {file)     write song list of cj songs
-cjread {file)      add song metadata
-cjcsvwrite {file}  format the song data as a CSV version of the CJ ranking metadata
-cjcsvread {file}   read a cj csv format the song metadata file
-cjgenre {file}     read the csv version of the CJ web genre file
-cjgenrewrite {file}     write the csv version of the CJ web genre file
-expand {file}      expand a songlyrics list file to the output directory
-floatnotes         list bass notes by float frequency
-f                  force file writes over existing files
-h                  this help message
-html               HTML song list
-list               list all songs
-longlyrics         select for songs  with long lyrics lines
-longsections       select for songs  with long sections
-ninjam             select for ninjam friendly songs
-o {output dir}     select the output directory, must be specified prior to -x
-oddmeasures        find the odd length measures in songs
-perfupdate {file}  update the song performances with a file
-perfwrite {file}   update the song performances to a file
-popSongs           list the most popular songs
-similar            list similar titled/artist/coverArtist songs
-spreadsheet        generate history spreadsheet in excel
-stat               statistics
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
          logger.i('a: ${(await inputFile.exists())}, ${inputFile is Directory}');

          if (!(await inputFile.exists()) && inputFile is! Directory) {
            logger.e('missing input file/directory for -a: ${inputFile.path}');
            exit(-1);
          }
          _addAllSongsFromDir(inputFile);
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
          logger.i('a: ${(await inputFile.exists())}, ${(inputFile is Directory)}');

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
              logger.i('"${song.songId.songId}", bpm: $bpm');
            }
            for (int n in SplayTreeSet<int>()
              ..addAll(bpms.keys)
              ..toList()) {
              logger.i('$n: ${bpms[n]}');
            }
            for (Song song in SplayTreeSet<Song>((song1, song2) {
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
                logger.i('${song.title} by ${song.artist}, bpm: $bpm, beats: ${song.beatsPerBar}');
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
              var meta = SongMetadata.where(idIs: song.songId.songId, nameIs: 'jam');
              if (meta.isNotEmpty) {
                cjSongs.add(song);
                logger.i('"${song.songId.songId}", cj:${meta.first.nameValues.first.value}');
              }
            }

            logger.i('cjSongs: ${cjSongs.length}');

            await outputFile.writeAsString(Song.listToJson(cjSongs.toList()), flush: true);
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
          logger.i('a: ${(await inputFile.exists())}, ${inputFile is Directory}');

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

            logger.i('-cjgenre: $inputFile');
            final input = inputFile.openRead();
            final fields = await input.transform(utf8.decoder).transform(const CsvToListConverter(eol: '\n')).toList();

            logger.i('${fields.runtimeType}');
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
            //     logger.i('$r: "$title", $artist, $year, $jam, $genre, $subgenre');
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
                logger.i('Not found: title: $title, artist: $artist');
                final songs = allSongs.map((e) => e.songId.toString()).toList(growable: false);
                BestMatch bestMatch = StringSimilarity.findBestMatch(songId.toString(), songs);
                var idString = songs[bestMatch.bestMatchIndex];
                song = allSongs.firstWhere((e) => e.songId.toString() == idString);
                logger.i('   best match: title: "${song.title}", artist: "${song.artist}"'
                    ', coverArtist: "${song.coverArtist}"');
              }
              if (genre.isNotEmpty || subgenre.isNotEmpty || jam.isNotEmpty || year.isNotEmpty) {
                logger.t('$song:  genre: $genre, subgenre: $subgenre, jam: $jam, year: $year');
                if (genre.isNotEmpty) SongMetadata.addSong(song, NameValue('genre', genre));
                if (subgenre.isNotEmpty) SongMetadata.addSong(song, NameValue('subgenre', subgenre));
                if (jam.isNotEmpty) SongMetadata.addSong(song, NameValue('jam', jam));
                if (year.isNotEmpty) SongMetadata.addSong(song, NameValue('year', year));
                if (status.isNotEmpty) SongMetadata.addSong(song, NameValue('status', status));
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
              rows.add([
                song.title,
                song.artist,
                song.coverArtist,
                year,
                jam,
                genre,
                subgenre,
                status,
              ]);
            }
            await outputFile.writeAsString(converter.convert(rows), flush: true);

            logger.i('-cjgenrewrite: $outputFile');
          }
          break;

        case '-exp':
          for (Song song in allSongs) {
            if (song.lastModifiedTime == 0) {
              logger.i(song.toString());
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
          //         logger.i('${song.title} by ${song.title}, songId: ${song.songId}');
          //       }
          //       logger.i('   $i: $line');
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
            if (_verbose) logger.i('input file path: ${_file.toString()}');
            if (!(await _file!.exists())) {
              logger.d(
                  'input file path: ${_file.toString()} is missing${_outputDirectory.isAbsolute ? '' : ' at ${Directory.current}'}');

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
                    logger
                        .i('${song.title} by ${song.artist}:  ${song.songId.toString()} ${fileTime.toIso8601String()}');
                  }
                } else {
                  if (_veryVerbose) {
                    logger
                        .i('${song.title} by ${song.artist}:  ${song.songId.toString()} ${fileTime.toIso8601String()}');
                    logger.i('\tidentical');
                  }
                }
              } else {
                if (_verbose) {
                  logger.i('${song.title} by ${song.artist}:  ${song.songId.toString()} ${fileTime.toIso8601String()}');
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

          allSongPerformances.updateFromJsonString(
              File('${Util.homePath()}/$_allSongPerformancesGithubFileLocation').readAsStringSync());
          allSongPerformances.loadSongs(allSongs);

          {
            List<List<CellData>> data = [];

            //  add all the songs
            Map<Song, int> singings = {};
            for (var song in allSongs) {
              singings[song] = 0;
            }

            //  sum them up
            for (var performance in allSongPerformances.allSongPerformanceHistory) {
              if (performance.song != null) {
                var v = singings[performance.song!];
                singings[performance.song!] = (v ?? 0) + 1;
              }
            }

            for (var song in allSongs) {
              List<CellData> rowData = [];
              rowData.add(CellData.byColumnEnum(ColumnEnum.title, song.title));
              rowData.add(CellData.byColumnEnum(ColumnEnum.artist, song.artist));
              rowData.add(CellData.byColumnEnum(ColumnEnum.coverArtist, song.coverArtist));
              rowData.add(CellData('Performances', 15, singings[song]!));
              data.add(rowData);
            }
            addExcelCellDataSheet(excel, 'By Song Title', data);

            {
              SplayTreeSet<List<CellData>> sortedData = SplayTreeSet((d1, d2) {
                bool first = true;
                for (int c in [3, 0, 1, 2]) {
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
              addExcelCellDataSheet(excel, 'By Performances', sortedData.toList(growable: false));
            }
          }

          {
            List<List<CellData>> data = [];

            //  add all the songs
            Map<String, int> singings = {};

            //  sum them up
            for (var performance in allSongPerformances.allSongPerformanceHistory) {
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
            addExcelCellDataSheet(excel, 'By Singer Performances', sortedData.toList(growable: false));
          }

          //  singers per jam
          {
            List<List<CellData>> data = [];

            //  add all the jams
            Map<DateTime, Map<String, int>> jams = {};

            //  sum them up
            for (var performance in allSongPerformances.allSongPerformanceHistory) {
              var dateTime = performance.lastSungDateTime;
              var day = DateTime(dateTime.year, dateTime.month, dateTime.day);
              // logger.i('performance.lastSungDateTime: ${performance.lastSungDateTime} $day');
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
            for (var day in SplayTreeSet<DateTime>()..addAll(jams.keys)) {
              var jam = jams[day]!;
              var singerSet = SplayTreeSet<String>()..addAll(jam.keys);
              singerSet.removeWhere((e) => e == 'unknown');
              String singers = singerSet.toString().replaceAll('{', '').replaceAll('}', '').trim();
              // logger.i('day: ${dayFormat.format(day)}, ${jam.length}, singers: $singers');
              data.add([
                CellData('Date', 15, dayFormat.format(day)),
                CellData('Count', 8, jam.length),
                CellData('Singers', 180, singers)
              ]);
            }
            addExcelCellDataSheet(excel, 'Singers per Jam', data.toList(growable: false));
          }

          //  singers songs sung per jam

          // fixme: the library won't do this:   excel.delete('Sheet1');
          excel.setDefaultSheet('By Song Title');

          var fileBytes = excel.save();

          File('/home/bob/junk/bsteeleMusicAppHistory_${Util.utcNow()}.xlsx')
            ..createSync(recursive: true)
            ..writeAsBytesSync(fileBytes!);
          break;

        case '-f':
          _force = true;
          break;

        case '-floatnotes':
          for (var pitch in Pitch.sharps) {
            logger.i(' ${pitch.frequency.toStringAsFixed(9).padLeft(4 + 1 + 9)}'
                ', // ${pitch.number.toString().padLeft(2)} $pitch ');
          }
          for (var pitch in Pitch.sharps) {
            logger.i('"$pitch", // ${pitch.number.toString().padLeft(2)}  ');
          }
          break;

        case '-h':
          _help();
          break;

        case '-html':
          {
            logger.i('''<!DOCTYPE html>
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
              logger.i('<li><span class="title">${song.title}</span> by <span class="artist">${song.artist}</span>'
                  '${song.coverArtist.isNotEmpty ? ' cover by <span class="coverArtist">${song.coverArtist}</span>' : ''}'
                  '</li>');
            }
            logger.i('''</ul>
</body>
</html>
''');
          }
          break;

        case '-list':
          for (Song song in allSongs) {
            logger.i('${song.title} by ${song.title}, songId: ${song.songId}');
          }
          break;

        case '-longlyrics':
          {
            Map<Song, int> longLyrics = {};
            for (Song song in allSongs) {
              int maxLength = 0;
              for (var lyricSection in song.lyricSections) {
                for (var line in lyricSection.lyricsLines) {
                  maxLength = max(maxLength, line.length);
                }
              }
              if (maxLength > 60) {
                longLyrics[song] = maxLength;
              }
            }

            SplayTreeSet<int> sortedValues = SplayTreeSet();
            sortedValues.addAll(longLyrics.values);
            for (int i in sortedValues.toList(growable: false).reversed) {
              SplayTreeSet<Song> sortedSongs = SplayTreeSet();
              for (Song song in longLyrics.keys) {
                if (longLyrics[song] == i) {
                  sortedSongs.add(song);
                }
              }
              for (Song song in sortedSongs) {
                logger.i('"${song.title}" by "${song.artist}"'
                    '${song.coverArtist.isNotEmpty ? ' cover by "${song.coverArtist}' : ''}'
                    ': maxLength: $i');
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
                logger.i('"${song.title}" by "${song.artist}"'
                    '${song.coverArtist.isNotEmpty ? ' cover by "${song.coverArtist}' : ''}'
                    ': maxLength: $i'
                    ', last modified:'
                    ' ${song.lastModifiedTime == 0 ? 'unknown' : DateTime.fromMillisecondsSinceEpoch(song.lastModifiedTime).toString()}');
              }
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
                  case SectionEnum.intro:
                  case SectionEnum.outro:
                  case SectionEnum.tag:
                  case SectionEnum.coda:
                  case SectionEnum.bridge:
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
                logger.i('"${song.title}" by "${song.artist}"'
                    '${song.coverArtist.isNotEmpty ? ' cover by "${song.coverArtist}' : ''}'
                    ':  /bpi $i  /bpm ${song.beatsPerMinute}  ${ninjamSections[song]?.toMarkup()}');
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
                logger.d('output path: ${_outputDirectory.toString()}'
                    ' is missing${_outputDirectory.isAbsolute ? '' : ' at ${Directory.current}'}');
              }

              Directory parent = _outputDirectory.parent;
              if (!(await parent.exists())) {
                logger.d('parent path: ${parent.toString()}'
                    ' is missing${_outputDirectory.isAbsolute ? '' : ' at ${Directory.current}'}');
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
              logger.i('${song.title} by ${song.artist}, beats: ${song.beatsPerBar}:');
              logger.i(sb.toString());
            }
          }
          break;

        case '-allSongPerformances':
          {
            if (_verbose) {
              logger.i('verbose -allSongPerformances:');
            }

            //  read the local directory's list of song performance files
            allSongPerformances.clear();
            assert(allSongPerformances.allSongPerformanceHistory.isEmpty);
            assert(allSongPerformances.allSongPerformances.isEmpty);
            assert(allSongPerformances.allSongPerformanceRequests.isEmpty);

            //  add the github version
            var usTimer = UsTimer();
            allSongPerformances.updateFromJsonString(
                File('${Util.homePath()}/$_allSongPerformancesGithubFileLocation').readAsStringSync());
            logger.i('preload: usTimer: ${usTimer.seconds} s'
                ', allSongPerformances.length: ${allSongPerformances.length}');

            //  read from server logs
            logger.i('allSongPerformances.length: ${allSongPerformances.length}');
            logger.i('allSongPerformanceHistory.length: ${allSongPerformances.allSongPerformanceHistory.length}');
            logger.i('last sung: ${allSongPerformances.allSongPerformanceHistory.last.lastSungDateString}');
            var lastSungDateTime = allSongPerformances.allSongPerformanceHistory.last.lastSungDateTime;
            // truncate date time to day
            lastSungDateTime = DateTime(lastSungDateTime.year, lastSungDateTime.month, lastSungDateTime.day);
            logger.i('lastSungDateTime: $lastSungDateTime');

            {
              //  collect all the files to be read
              var dir = Directory('${Util.homePath()}/$_allSongPerformancesDirectoryLocation');
              SplayTreeSet<File> files = SplayTreeSet((key1, key2) => key1.path.compareTo(key2.path));
              for (var file in dir.listSync()) {
                if (file is File) {
                  files.add(file);
                }
              }

              logger.i('files: ${files.length}');

              //  update from the all local server song performance log files
              for (var file in files) {
                var name = file.path.split('/').last;

                logger.log(_logFiles, 'name: $name');
                var m = _allSongPerformancesRegExp.firstMatch(name);
                if (m != null) {
                  logger.i(name);
                  var date = Util.yyyyMMdd_HHmmssStringToDate(name);
                  if (date.compareTo(lastSungDateTime) >= 0) {
                    logger.i('');
                    if (_verbose) {
                      logger.i('process: file: $name');
                    }

                    //  clear all the requests so only the most current set is used
                    allSongPerformances.clearAllSongPerformanceRequests();

                    allSongPerformances.updateFromJsonString(file.readAsStringSync());
                    logger.i('allSongPerformances.length: ${allSongPerformances.length}');
                    logger
                        .i('allSongPerformanceHistory.length: ${allSongPerformances.allSongPerformanceHistory.length}');
                  } else {
                    if (_verbose) {
                      logger.i('ignore:  file: $name');
                    }
                    logger.d('ignore:  file: $name');
                  }
                }
              }

              {
                //  most recent performances, less than the limit
                SplayTreeSet<SongPerformance> performanceDelete =
                    SplayTreeSet<SongPerformance>(SongPerformance.compareByLastSungSongIdAndSinger);
                for (var songPerformance in allSongPerformances.allSongPerformances) {
                  if (songPerformance.lastSung < lastSungLimit
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

                logger.i('performanceDelete:  length: ${performanceDelete.length}');
                for (var performance in performanceDelete) {
                  logger.log(_logPerformanceDetails, 'delete: $performance');
                  allSongPerformances.removeSingerSong(performance.singer, performance.songIdAsString);
                  assert(!allSongPerformances.allSongPerformances.contains(performance));
                }

                //  history
                performanceDelete.clear();
                for (var songPerformance in allSongPerformances.allSongPerformanceHistory) {
                  if (songPerformance.lastSung < lastSungLimit ||
                      (!songPerformance.singer.contains(' ') && songPerformance.singer != unknownSinger) ||
                      songPerformance.singer.contains('Vikki') ||
                      songPerformance.singer.contains('Alicia C.') ||
                      songPerformance.singer.contains('Bob S.')) {
                    performanceDelete.add(songPerformance);
                  }
                }
                logger.i('history performanceDelete:  length: ${performanceDelete.length}');
                for (var performance in performanceDelete) {
                  logger.log(_logPerformanceDetails, 'delete history: $performance');
                  allSongPerformances.removeSingerSongHistory(performance);
                  assert(!allSongPerformances.allSongPerformanceHistory.contains(performance));
                }
              }

              logger.i('allSongPerformances.length: ${allSongPerformances.length}');
              logger.i('allSongPerformanceHistory.length: ${allSongPerformances.allSongPerformanceHistory.length}');

              if (_verbose) {
                for (var performance in allSongPerformances.allSongPerformanceHistory) {
                  logger.i('history:  ${performance.toString()}');
                }
              }
            }

            var songs = Song.songListFromJson(File('${Util.homePath()}/$_allSongsFileLocation').readAsStringSync());

            var corrections = allSongPerformances.loadSongs(songs);
            logger.i(
                'postLoad: usTimer: ${usTimer.seconds} s, delta: ${usTimer.deltaToString()}, songs: ${songs.length}');
            logger.i('corrections: $corrections');

            //  count the sloppy matched songs in history
            {
              var matches = 0;
              for (var performance in allSongPerformances.allSongPerformanceHistory) {
                if (performance.song == null) {
                  logger.i('missing song: ${performance.lowerCaseSongIdAsString}');
                } else if (performance.lowerCaseSongIdAsString != performance.song!.songId.toString().toLowerCase()) {
                  logger.i('${performance.lowerCaseSongIdAsString}'
                      ' vs ${performance.song!.songId.toString().toLowerCase()}');
                  assert(false);
                } else {
                  matches++;
                }
              }
              logger.i('matches:  $matches/${allSongPerformances.allSongPerformanceHistory.length}'
                  ', corrections: ${allSongPerformances.allSongPerformanceHistory.length - matches}');
            }

            SongMetadata.fromJson(_allSongsMetadataFile.readAsStringSync());
            File localSongMetadata = File('${Util.homePath()}/$_junkRelativeDirectory/allSongs.songmetadata');
            {
              SongMetadata.repairSongs(allSongPerformances.songRepair);
              try {
                localSongMetadata.deleteSync();
              } catch (e) {
                logger.e(e.toString());
                //assert(false);
              }
              await localSongMetadata.writeAsString(SongMetadata.toJson(), flush: true);

              if (_verbose) {
                logger.i('allSongPerformances location: ${localSongMetadata.path}');
              }
            }

            File localSongperformances =
                File('${Util.homePath()}/$_junkRelativeDirectory/allSongPerformances.songperformances');
            {
              try {
                localSongperformances.deleteSync();
              } catch (e) {
                logger.e(e.toString());
                //assert(false);
              }
              await localSongperformances.writeAsString(allSongPerformances.toJsonString(), flush: true);
            }

            //  time the reload
            {
              // allSongPerformances.clear();
              // SongMetadata.clear();

              logger.i('\nreload:');
              var usTimer = UsTimer();

              allSongPerformances.updateFromJsonString(localSongperformances.readAsStringSync());
              logger.i('performances: ${usTimer.deltaToString()}');

              var json = File('${Util.homePath()}/$_allSongsFileLocation').readAsStringSync();
              logger.i('song data read: ${usTimer.deltaToString()}');
              var songs = Song.songListFromJson(json);
              logger.i('song data parsed: ${usTimer.deltaToString()}');
              var corrections = allSongPerformances.loadSongs(songs);
              logger.i('loadSongs: ${usTimer.deltaToString()}');

              SongMetadata.fromJson(localSongMetadata.readAsStringSync());
              logger.i('localSongMetadata: ${usTimer.deltaToString()}');

              double seconds = usTimer.seconds;
              logger.i('reload: usTimer: $seconds s'
                  ', allSongPerformances.length: ${allSongPerformances.length}'
                  ', songs.length: ${songs.length}'
                  ', idMetadata.length: ${SongMetadata.idMetadata.length}'
                  ', corrections: $corrections');
              assert(seconds < 0.25);
            }
            if (_verbose) {
              logger.i(allSongPerformances.toString());
            }
          }
          break;

        case '-perfupdate':
          //  assert there is another arg
          if (argCount < args.length - 1) {
            argCount++;
            var file = File(args[argCount]);

            if (await file.exists()) {
              logger.i('\'${file.path}\' exists.');

              logger.i('allSongPerformances: ${allSongPerformances.length}');
              allSongPerformances.updateFromJsonString(file.readAsStringSync());
              logger.i('allSongPerformances: ${allSongPerformances.length}');
            } else {
              logger.e('\'${file.path}\' does not exist.');
            }
          } else {
            logger.e('missing input path for -perf');
            _help();
            exit(-1);
          }
          break;

        case '-perfwrite': // {file)     format the song meta data
          //  assert there is another arg
          if (argCount >= args.length - 1) {
            logger.e('missing directory path for -perfwrite');
            exit(-1);
          }
          argCount++;
          {
            File outputFile = File(args[argCount]);

            if (await outputFile.exists() && !_force) {
              logger.e('"${outputFile.path}" already exists for -w without -f');
              exit(-1);
            }
            AllSongPerformances allSongPerformances = AllSongPerformances();
            await outputFile.writeAsString(allSongPerformances.toJsonString(), flush: true);
          }
          break;

        case '-popSongs': //     list the most popular songs
          {
            //  read the local directory's list of song performance files
            AllSongPerformances allSongPerformances = AllSongPerformances();

            //  add the github version
            allSongPerformances.updateFromJsonString(
                File('${Util.homePath()}/$_allSongPerformancesGithubFileLocation').readAsStringSync());

            //  load local songs
            var songs = Song.songListFromJson(File('${Util.homePath()}/$_allSongsFileLocation').readAsStringSync());
            allSongPerformances.loadSongs(songs);

            //  assure all songs are present
            for (var performance in allSongPerformances.allSongPerformanceHistory) {
              if (performance.song == null) {
                logger.e('missing song: ${performance.songIdAsString}');
                assert(false);
              }
            }

            Map<Song, int> songCounts = {};
            for (var performance in allSongPerformances.allSongPerformanceHistory) {
              var song = performance.song;
              if (song != null) {
                var count = songCounts[song];
                songCounts[song] = (count == null ? 1 : count + 1);
              }
            }

            var sortMapByValue = Map.fromEntries(songCounts.entries.toList()
              ..sort((e1, e2) {
                int ret = -e1.value.compareTo(e2.value);
                if (ret != 0) {
                  return ret;
                }
                return e1.key.compareTo(e2.key);
              }));

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
                logger.i('$count: ${entry.key}: ${entry.value}');
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
              map[song.songId.songId] = song;
            }
            List<String> keys = [];

            keys.addAll(map.keys);
            List<String> listed = [];
            for (Song song in allSongs) {
              if (listed.contains(song.songId.songId)) {
                continue;
              }
              BestMatch bestMatch = StringSimilarity.findBestMatch(song.songId.songId, keys);

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
                  logger.i('$song');
                  Song? similar = map[rating.target];
                  if (similar != null) {
                    //logger.i('"${similar.title.toString()}" by ${similar.artist.toString()}');
                    logger.i('$similar');
                    logger.i(' ');
                  }
                  listed.add(rating.target ?? 'null');
                }
                break;
              }
            }
          }
          break;

        case '-stat':
          logger.i('songs: ${allSongs.length}');
          logger.i('updates: $_updateCount');
          {
            var covers = 0;
            for (var song in allSongs) {
              if (song.title.contains('cover')) {
                covers++;
              }
            }
            logger.i('covers: $covers');
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
            logger.i('chordDescriptorUsageMap: ${chordDescriptorUsageMap.keys.length}');
            var sortedValues = SplayTreeSet<int>();
            sortedValues.addAll(chordDescriptorUsageMap.values);
            for (var usage in sortedValues.toList().reversed) {
              for (var key in chordDescriptorUsageMap.keys.where((e) => chordDescriptorUsageMap[e] == usage)) {
                logger.i('   _${key.name}, //  ${chordDescriptorUsageMap[key]}');
              }
            }
          }
          break;

        case '-test':
          {
            DateTime t = DateTime.fromMillisecondsSinceEpoch(1570675021323);
            File file = File('/home/bob/junk/j');
            await setLastModified(file, t.millisecondsSinceEpoch);
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
            logger.i('${song.title} by ${song.artist}:');

            for (var lyricSection in song.lyricSections) {
              logger.i('    ${lyricSection.sectionVersion} ${lyricSection.lyricsLines.length}');
              var lineNumber = 0;

              for (var line in lyricSection.lyricsLines) {
                lineNumber++;
                var syllableCount = 0;
                for (var word in line.split(_spaceRegexp)) {
                  if (word.isNotEmpty) {
                    syllableCount += syllables(word);
                    logger.i('            $lineNumber: $syllableCount: $line: <$word>');
                  }
                }
                logger.i('       $lineNumber: $syllableCount: $line');
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
          List<Song> addSongs = Song.songListFromJson(utf8
                  .decode(await http.readBytes(Uri.http(authority, path)))
                  .replaceAll('": null,', '": "",')) //  cheap repair
              ;
          allSongs.addAll(addSongs);

          // {
          //   var count = 0;
          //   for (var song in allSongs) {
          //     count += song.isLyricsParseRequired ? 1 : 0;
          //   }
          //   logger.i('isLyricsParseRequired: $count');
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
                logger.i('$song from ${song.user} to $newUser');
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
            })
              ..addAll(userMap.keys)) {
              logger.i('$user: ${userMap[user]}');
            }
          }
          break;

        case '-x':
          //  https://musictheorysite.com/namethatkey/
          int diffCount = 0;
          for (var song in allSongs) {
            Map<ScaleChord, int> scaleChordUseMap = {};
            for (var lyricSection in song.lyricSections) {
              // logger.i('${lyricSection.sectionVersion.toString().replaceFirst(':', ':')} ');
              var chordSection = song.getChordSection(lyricSection.sectionVersion);
              if (chordSection != null) {
                // logger.i('$chordSection: ');
                for (var phrase in chordSection.phrases) {
                  // if (phrase.repeats > 0) {
                  //   logger.i('   repeats: ${phrase.repeats}');
                  // }
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
                assert(false);
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
                //logger.i('$key: ${notes[key.halfStep]} ${key.getMajorScaleChord()}');
                int score = 0;
                for (int degree = 0; degree < MusicConstants.notesPerScale; degree++) {
                  var scaleChord = key.getMajorDiatonicByDegree(degree);
                  score += weights[degree] * ((scaleChordUseMap[scaleChord]) ?? 0);
                  // logger.i( '    major key chord note: $note $score $weight');
                }
                // logger.i( '    $key score: $score');
                if (score > max) {
                  max = score;
                  bestKey = key;
                }
              }
              if (bestKey.halfStep != song.key.halfStep) {
                diffCount++;
                logger.i('${song.title}, ${song.artist}, key: ${song.key}');
                logger.i('    bestKey: $bestKey,  chords used: ${scaleChordUseMap.keys.toString()}');
              }
            }
          }
          logger.i('diffCount: $diffCount');
          // for (var song in allSongs) {
          //   SplayTreeSet<ScaleChord> scaleChords = SplayTreeSet();
          //   List<int> notes = List.filled(MusicConstants.halfStepsPerOctave, 0);
          //   for (var lyricSection in song.lyricSections) {
          //     // logger.i('${lyricSection.sectionVersion.toString().replaceFirst(':', ':')} ');
          //     var chordSection = song.getChordSection(lyricSection.sectionVersion);
          //     if (chordSection != null) {
          //       // logger.i('$chordSection: ');
          //       for (var phrase in chordSection.phrases) {
          //         // if (phrase.repeats > 0) {
          //         //   logger.i('   repeats: ${phrase.repeats}');
          //         // }
          //         for (var measure in phrase.measures) {
          //           for (var chord in measure.chords) {
          //             var scaleChord = chord.scaleChord;
          //             scaleChords.add(scaleChord);
          //             // logger.i('     ${scaleChord.scaleNote} ${scaleChord.chordDescriptor}'
          //             //     ' x ${chord.beats} ${chord.slashScaleNote ?? ''}');
          //
          //             for (var note in scaleChord.chordNotes(song.key)) {
          //               if (note.isSilent) {
          //                 continue;
          //               }
          //               // logger.i('         $note  ${note.halfStep}: ${phrase.repeats} x ${chord.beats}');
          //               notes[note.halfStep] += phrase.repeats * chord.beats;
          //             }
          //             // if (chord.slashScaleNote != null) {
          //             //   notes[chord.slashScaleNote!.halfStep] += phrase.repeats * chord.beats;
          //             // }
          //           }
          //         }
          //       }
          //     } else {
          //       assert(false);
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
          //       //logger.i('$key: ${notes[key.halfStep]} ${key.getMajorScaleChord()}');
          //       int score = 0;
          //       for (int degree = 0; degree < MusicConstants.notesPerScale; degree++) {
          //         var scaleChord = key.getMajorDiatonicByDegree(degree);
          //         score += weights[degree] * notes[scaleChord.scaleNote.halfStep];
          //         // logger.i( '    major key chord note: $note $score $weight');
          //       }
          //       //  logger.i( '    $key score: $score');
          //       if (score > max) {
          //         max = score;
          //         bestKey = key;
          //       }
          //     }
          //     if (bestKey.halfStep != song.key.halfStep) {
          //       logger.i('${song.title}, ${song.artist}, key: ${song.key}');
          //       logger.i('    bestKey: $bestKey,  chords used: ${scaleChords.toString()}');
          //     }
          //   }
          // }
          break;

        case '-xmas':
          final RegExp christmasRegExp = RegExp(r'.*christmas.*', caseSensitive: false);
          SongMetadata.clear();
          for (Song song in allSongs) {
            if (christmasRegExp.hasMatch(song.songId.songId)) {
              SongMetadata.set(SongIdMetadata(song.songId.songId, metadata: [NameValue('christmas', '')]));
            }
          }
          logger.i(SongMetadata.toJson());
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
              var songsFound =
                  allSongs.where((song) => song.title.toLowerCase() == title.toLowerCase()).toList(growable: false);
              if (songsFound.isEmpty) {
                logger.i('//  NOT FOUND: $title');
                continue;
              }
              if (songsFound.length > 1) {
                logger.i('//  MULTIPLES FOUND: $title');
                for (var song in songsFound) {
                  logger.i('//    ${song.title}');
                }
              }
              logger.i('{"id":"${songsFound[0].songId}","metadata":[{"name":"cj","value":"ninjam"}]},');
            }
          }
          break;

        default:
          logger.e('command not understood: "$arg"');
          logger.i('error: command not understood: "$arg"');
          exit(-1);
      }
    }

    return 0;
  }

  void _addAllSongsFromDir(dynamic inputFile) {
    logger.i('$inputFile');
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
    if (_verbose) logger.i('$inputFile');

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

  void _copyright() {
    Map<String, SplayTreeSet<Song>> copyrights = {};
    for (Song song in allSongs) {
      String? copyright = song.copyright.trim();
      if (copyright.isEmpty) {
        continue;
      }
      //logger.i('${song.copyright} ${song.songId.toString()}');
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
      logger.i('"$copyright"');
      for (Song song in copyrights[copyright] ?? {}) {
        logger.i('\t${song.songId.toString()}');
      }
    }
  }

  String _cjCsvRanking() {
    StringBuffer sb = StringBuffer();
    sb.write('Id'
        ',ranking'
        '\n');
    for (Song song in allSongs) {
      var meta = SongMetadata.where(idIs: song.songId.songId, nameIs: 'jam');
      if (meta.isNotEmpty) {
        sb.write('"${song.songId.songId}","${meta.first.nameValues.first.value}"\n');
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
      logger.i('verbose processCatalinaLogs:');
    }

    //  read the local directory's list of song performance files
    allSongPerformances.clear();
    assert(allSongPerformances.allSongPerformanceHistory.isEmpty);
    assert(allSongPerformances.allSongPerformances.isEmpty);
    assert(allSongPerformances.allSongPerformanceRequests.isEmpty);

    //  add the github version
    var usTimer = UsTimer();
    allSongPerformances
        .updateFromJsonString(File('${Util.homePath()}/$_allSongPerformancesGithubFileLocation').readAsStringSync());
    logger.i('preload: usTimer: ${usTimer.seconds} s'
        ', allSongPerformances.length: ${allSongPerformances.length}');

    //  read from server logs
    logger.i('allSongPerformances.length: ${allSongPerformances.length}');
    logger.i('allSongPerformanceHistory.length: ${allSongPerformances.allSongPerformanceHistory.length}');
    logger.i('last sung: ${allSongPerformances.allSongPerformanceHistory.last.lastSungDateString}');
    var lastSungDateTime = allSongPerformances.allSongPerformanceHistory.last.lastSungDateTime;
    // truncate date time to day
    lastSungDateTime = DateTime(lastSungDateTime.year, lastSungDateTime.month, lastSungDateTime.day);
    logger.i('lastSungDateTime: $lastSungDateTime');

    //  collect all the files to be read
    logger.i('logs: $logs');
    SplayTreeSet<File> files = SplayTreeSet((f1, f2) {
      return f1.path.compareTo(f2.path);
    });
    //  most recent performances, less than the limit
    final DateTime lastSungLimitDate = DateTime.fromMillisecondsSinceEpoch(lastSungLimit);
    {
      for (var e in logs.listSync()) {
        var date = Util.yyyyMMddStringToDate(e.path);
        if (e is File && date != null && e.path.contains('/catalina.') && date.compareTo(lastSungLimitDate) >= 0) {
          files.add(e);
        }
      }
    }
    logger.i('files: ${files.length}');

    //  update from the tomcat session logs
    for (var file in files) {
      final messagePattern = RegExp(r' onMessage\("(.*)"\)');
      String fileAsString;
      if (file.path.endsWith('.log')) {
        fileAsString = file.readAsStringSync();
      } else if (file.path.endsWith('.log.gz')) {
        fileAsString = utf8.decode(zlib.decode(file.readAsBytesSync()));
      } else {
        logger.i('not a log file: $file');
        continue;
      }

      bool firstLine = true;
      for (var line in fileAsString.split('\n')) {
        RegExpMatch? m = messagePattern.firstMatch(line);
        if (m != null) {
          if (firstLine) {
            logger.i('');
            logger.i('$file:');
            firstLine = false;
          }
          logger.i('json: ${m.group(1)}');
          SongUpdate? songUpdate = SongUpdate.fromJson(m.group(1)!);
          if (songUpdate != null) {
            songUpdate.song;
            logger.i('songUpdate: $songUpdate');
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
        logger.i(name);
        var date = Util.yyyyMMddStringToDate(name);
        if (date != null && date.compareTo(lastSungDateTime) >= 0) {
          logger.i('');
          if (_verbose) {
            logger.i('process: file: $name');
          }

          //  clear all the requests so only the most current set is used
          allSongPerformances.clearAllSongPerformanceRequests();

          allSongPerformances.updateFromJsonString(file.readAsStringSync());
          logger.i('allSongPerformances.length: ${allSongPerformances.length}');
          logger.i('allSongPerformanceHistory.length: ${allSongPerformances.allSongPerformanceHistory.length}');
        } else {
          if (_verbose) {
            logger.i('ignore:  file: $name');
          }
          logger.d('ignore:  file: $name');
        }
      }

      {
        SplayTreeSet<SongPerformance> performanceDelete =
            SplayTreeSet<SongPerformance>(SongPerformance.compareByLastSungSongIdAndSinger);
        for (var songPerformance in allSongPerformances.allSongPerformances) {
          if (songPerformance.lastSung < lastSungLimit
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

        logger.i('performanceDelete:  length: ${performanceDelete.length}');
        for (var performance in performanceDelete) {
          logger.log(_logPerformanceDetails, 'delete: $performance');
          allSongPerformances.removeSingerSong(performance.singer, performance.songIdAsString);
          assert(!allSongPerformances.allSongPerformances.contains(performance));
        }

        //  history
        performanceDelete.clear();
        for (var songPerformance in allSongPerformances.allSongPerformanceHistory) {
          if (songPerformance.lastSung < lastSungLimit ||
              (!songPerformance.singer.contains(' ') && songPerformance.singer != unknownSinger) ||
              songPerformance.singer.contains('Vikki') ||
              songPerformance.singer.contains('Alicia C.') ||
              songPerformance.singer.contains('Bob S.')) {
            performanceDelete.add(songPerformance);
          }
        }
        logger.i('history performanceDelete:  length: ${performanceDelete.length}');
        for (var performance in performanceDelete) {
          logger.log(_logPerformanceDetails, 'delete history: $performance');
          allSongPerformances.removeSingerSongHistory(performance);
          assert(!allSongPerformances.allSongPerformanceHistory.contains(performance));
        }
      }

      logger.i('allSongPerformances.length: ${allSongPerformances.length}');
      logger.i('allSongPerformanceHistory.length: ${allSongPerformances.allSongPerformanceHistory.length}');

      if (_verbose) {
        for (var performance in allSongPerformances.allSongPerformanceHistory) {
          logger.i('history:  ${performance.toString()}');
        }
      }
    }

    var songs = Song.songListFromJson(File('${Util.homePath()}/$_allSongsFileLocation').readAsStringSync());

    var corrections = allSongPerformances.loadSongs(songs);
    logger.i('postLoad: usTimer: ${usTimer.seconds} s, delta: ${usTimer.deltaToString()}, songs: ${songs.length}');
    logger.i('corrections: $corrections');

    //  count the sloppy matched songs in history
    {
      var matches = 0;
      for (var performance in allSongPerformances.allSongPerformanceHistory) {
        if (performance.song == null) {
          logger.i('missing song: ${performance.lowerCaseSongIdAsString}');
          assert(false);
        } else if (performance.lowerCaseSongIdAsString != performance.song!.songId.toString().toLowerCase()) {
          logger.i('${performance.lowerCaseSongIdAsString}'
              ' vs ${performance.song!.songId.toString().toLowerCase()}');
          assert(false);
        } else {
          matches++;
        }
      }
      logger.i('matches:  $matches/${allSongPerformances.allSongPerformanceHistory.length}'
          ', corrections: ${allSongPerformances.allSongPerformanceHistory.length - matches}');
    }

    //  repair metadata song changes
    SongMetadata.fromJson(_allSongsMetadataFile.readAsStringSync());
    File localSongMetadata = File('${Util.homePath()}/$_junkRelativeDirectory/allSongs.songmetadata');
    {
      SongMetadata.repairSongs(allSongPerformances.songRepair);
      try {
        localSongMetadata.deleteSync();
      } catch (e) {
        logger.e(e.toString());
        //assert(false);
      }
      await localSongMetadata.writeAsString(SongMetadata.toJson(), flush: true);

      if (_verbose) {
        logger.i('allSongPerformances location: ${localSongMetadata.path}');
      }
    }

    //  write the corrected performances
    File localSongperformances =
        File('${Util.homePath()}/$_junkRelativeDirectory/allSongPerformances.songperformances');
    {
      try {
        localSongperformances.deleteSync();
      } catch (e) {
        logger.e(e.toString());
        //assert(false);
      }
      await localSongperformances.writeAsString(allSongPerformances.toJsonString(), flush: true);
    }

    //  time the reload
    {
      // allSongPerformances.clear();
      // SongMetadata.clear();

      logger.i('\nreload:');
      var usTimer = UsTimer();

      allSongPerformances.updateFromJsonString(localSongperformances.readAsStringSync());
      logger.i('performances: ${usTimer.deltaToString()}');

      var json = File('${Util.homePath()}/$_allSongsFileLocation').readAsStringSync();
      logger.i('song data read: ${usTimer.deltaToString()}');
      var songs = Song.songListFromJson(json);
      logger.i('song data parsed: ${usTimer.deltaToString()}');
      var corrections = allSongPerformances.loadSongs(songs);
      logger.i('loadSongs: ${usTimer.deltaToString()}');

      SongMetadata.fromJson(localSongMetadata.readAsStringSync());
      logger.i('localSongMetadata: ${usTimer.deltaToString()}');

      double seconds = usTimer.seconds;
      logger.i('reload: usTimer: $seconds s'
          ', allSongPerformances.length: ${allSongPerformances.length}'
          ', songs.length: ${songs.length}'
          ', idMetadata.length: ${SongMetadata.idMetadata.length}'
          ', corrections: $corrections');
      assert(seconds < 0.25);
    }
  }

  addExcelCellDataSheet(Excel excel, String sheetName, List<List<CellData>> data) {
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
      topBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: 'FFFF0000'),
      bottomBorder: Border(borderStyle: BorderStyle.Medium, borderColorHex: 'FF0000FF'),
      textWrapping: TextWrapping.WrapText,
    );
    CellStyle songCellStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Left,
      textWrapping: TextWrapping.WrapText,
    );
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
          default:
            logger.t('type failure: ${cellData.value.runtimeType}');
            assert(false);
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
//   //logger.i(sb.toString());
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
