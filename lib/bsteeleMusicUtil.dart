//  -v -o songs -x allSongs.songlyrics -a songs -f -w allSongs2.songlyrics
//  -v -o songs -x allSongs.songlyrics -a songs -f -w allSongs2.songlyrics -o songs2 -x allSongs2.songlyrics
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:bsteeleMusicLib/songs/chordSection.dart';
import 'package:bsteeleMusicLib/songs/section.dart';
import 'package:bsteeleMusicLib/songs/song.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:quiver/collection.dart';
import 'package:string_similarity/string_similarity.dart';

import 'appLogger.dart';

void main(List<String> args) {
  Logger.level = Level.info;

  var util = BsteeleMusicUtil();
  util.runMain(args);
}

/// a command line utility to help manage song list maintenance
/// to and from tools like git and the bsteele Music App.
class BsteeleMusicUtil {
  /// help message to the user
  void _help() {
    print('''
bsteeleMusicUtil:
//  a utility for the bsteele Music App
arguments:
-a {file_or_dir}    add all the .songlyrics files to the utility's allSongs list 
-csv                format the song data, short of chords and lyrics, into a comma seperated values (CSV) file
-f                  force file writes over existing files
-h                  this help message
-o {output dir}     select the output directory, must be specified prior to -x
-similar            list similar titled/artist songs
-url {url}          read the given url into the utility's allSongs list
-v                  verbose output utility's allSongs list
-V                  very verbose output
-w {file}           write the utility's allSongs list to the given file
-x {file}           expand a songlyrics list file to the output directory

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
  void runMain(List<String> args) async {
    //  help if nothing to do
    if (args == null || args.isEmpty) {
      _help();
      return;
    }

    //  process the requests
    for (var i = 0; i < args.length; i++) {
      var arg = args[i];
      switch (arg) {
        case '-a':
          //  insist there is another arg
          if (i >= args.length - 1) {
            logger.e('missing directory path for -a');
            _help();
            exit(-1);
          }
          i++;
          {
            Directory inputDirectory = Directory(args[i]);

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
          File inputFile = File(args[i]);
          logger.i('a: ${(await inputFile.exists())}, ${(await inputFile is Directory)}');

          if (!(await inputFile.exists()) && !(await inputFile is Directory)) {
            logger.e('missing input file/directory for -a: ${inputFile.path}');
            exit(-1);
          }
          _addAllSongsFromDir(inputFile);
          break;

        case '-copyright':
          _copyright();
          break;

        case '-csv':
          _csv();
          break;

        case '-f':
          _force = true;
          break;

        case '-h':
          _help();
          break;

        case '-ninjam':
          {
            Map<Song, int> ninjams = {};
            for (Song song in allSongs) {
              ChordSection lastChordSection;
              bool allSignificantChordSectionsMatch = true;

              if (song.getChordSections().length == 1) {
                lastChordSection = song.getChordSections().first;
              }

              for (ChordSection chordSection in song.getChordSections()) {
                switch (chordSection.sectionVersion.section.sectionEnum) {
                  case SectionEnum.intro:
                  case SectionEnum.outro:
                  case SectionEnum.tag:
                  case SectionEnum.coda:
                    break;
                  default:
                    if (lastChordSection == null) {
                      lastChordSection = chordSection;
                    } else {
                      if (!listsEqual(lastChordSection.phrases, chordSection.phrases)) {
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
              if (lastChordSection != null && allSignificantChordSectionsMatch) {
                int bars = lastChordSection.getTotalMoments();
                if (lastChordSection.phrases.length == 1 && lastChordSection.phrases[0].isRepeat()) {
                  bars = lastChordSection.phrases[0].measures.length;
                }
                ninjams[song] = song.beatsPerBar * bars;
              }
            }

            SplayTreeSet<int> sortedValues = SplayTreeSet();
            sortedValues.addAll(ninjams.values);
            for (int i in sortedValues) {
              SplayTreeSet<Song> sortedSongs = SplayTreeSet();
              for (Song song in ninjams.keys) {
                if (ninjams[song] == i) {
                  sortedSongs.add(song);
                }
              }
              for (Song song in sortedSongs) {
                print('"${song.title}" by "${song.artist}"'
                    '${song.coverArtist != null ? ' cover by "${song.coverArtist}' : ''}'
                    ':  /bpi ${i}');
              }
            }
          }
          break;

        case '-o':
          //  assert there is another arg
          if (i < args.length - 1) {
            i++;
            _outputDirectory = Directory(args[i]);
            if (_verbose) {
              logger.d('output path: ${_outputDirectory.toString()}');
            }
            if (!(await _outputDirectory.exists())) {
              if (_verbose) {
                logger.d('output path: ${_outputDirectory.toString()}'
                        ' is missing' +
                    (_outputDirectory.isAbsolute ? '' : ' at ${Directory.current}'));
              }

              Directory parent = _outputDirectory.parent;
              if (!(await parent.exists())) {
                logger.d('parent path: ${parent.toString()}'
                        ' is missing' +
                    (_outputDirectory.isAbsolute ? '' : ' at ${Directory.current}'));
                return;
              }
              _outputDirectory.createSync();
            }
          } else {
            logger.e('missing output path for -o');
            _help();
            exit(-1);
          }
          break;

        case '-similar':
          {
            Map<String, Song> map = {};
            for (Song song in allSongs) {
              map[song.songId.songId] = song;
            }
            List<String> keys = [];

            keys.addAll(map.keys);
            List<String> listed =[];
            for (Song song in allSongs) {
              if ( listed.contains(song.songId.songId)){
                continue;
              }
              BestMatch bestMatch = StringSimilarity.findBestMatch(song.songId.songId, keys);

              SplayTreeSet<Rating> ratingsOrdered = SplayTreeSet((Rating rating1, Rating rating2) {
                if (rating1.rating == rating2.rating) {
                  return 0;
                }
                return rating1.rating < rating2.rating ? 1 : -1;
              });
              ratingsOrdered.addAll(bestMatch.ratings);

              for (Rating rating in ratingsOrdered) {
                if (rating.rating >= 1.0) {
                  continue;
                }
                if (rating.rating >= 0.8) {
                  print('"${song.title.toString()}" by ${song.artist.toString()}');
                  Song similar = map[rating.target];
                  print('"${similar.title.toString()}" by ${similar.artist.toString()}');
                  print(' ');
                  listed.add(rating.target);
                }
                break;
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

        case '-w':
          //  assert there is another arg
          if (i >= args.length - 1) {
            logger.e('missing directory path for -a');
            exit(-1);
          }
          i++;
          File outputFile = File(args[i]);

          if (await outputFile.exists() && !_force) {
            logger.e('"${outputFile.path}" alreday exists for -w without -f');
            exit(-1);
          }
          if (allSongs.isEmpty) {
            logger.e('allSongs is empty for -w');
            exit(-1);
          }
          await outputFile.writeAsString(Song.listToJson(allSongs.toList()), flush: true);
          break;

        case '-v':
          _verbose = true;
          break;

        case '-V':
          _verbose = true;
          _veryVerbose = true;
          break;

        case '-url':
          //  assert there is another arg
          if (i >= args.length - 1) {
            logger.e('missing file path for -url');
            _help();
            exit(-1);
          }
          i++;
          String url = args[i];
          logger.d("url: '$url'");
          List<Song> addSongs = Song.songListFromJson(
                  utf8.decode(await http.readBytes(url)).replaceAll('": null,', '": "",')) //  cheap repair
              ;
          allSongs.addAll(addSongs);
          break;

        case '-x':
          //  insist there is another arg
          if (i >= args.length - 1) {
            logger.e('missing file path for -x');
            _help();
            exit(-1);
          }

          i++;
          _file = File(args[i]);
          if (_verbose) print('input file path: ${_file.toString()}');
          if (!(await _file.exists())) {
            logger.d('input file path: ${_file.toString()}'
                    ' is missing' +
                (_outputDirectory.isAbsolute ? '' : ' at ${Directory.current}'));

            exit(-1);
            return;
          }

          if (_verbose) {
            logger.d('input file: ${_file.toString()}, file size: ${await _file.length()}');
          }

          List<Song> songs;
          if (_file.path.endsWith('.zip')) {
            // Read the Zip file from disk.
            final bytes = await _file.readAsBytes();

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
            songs = Song.songListFromJson(_file.readAsStringSync());
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
              String s = song.getTitle().replaceAll(notWordOrSpaceRegExp, '').trim().substring(0, 1).toUpperCase();
              songDir = Directory(_outputDirectory.path + '/' + s);
            }
            songDir.createSync();

            File writeTo = File(songDir.path + '/' + song.songId.toString() + '.songlyrics');
            if (_verbose) logger.d('\t' + writeTo.path);
            String fileAsJson = song.toJsonAsFile();
            if (writeTo.existsSync()) {
              String fileAsRead = writeTo.readAsStringSync();
              if (fileAsJson != fileAsRead) {
                writeTo.writeAsStringSync(fileAsJson, flush: true);
                if (_verbose) {
                  logger.i(
                      '${song.getTitle()} by ${song.getArtist()}:  ${song.songId.toString()} ${fileTime.toIso8601String()}');
                }
              } else {
                if (_veryVerbose) {
                  logger.i(
                      '${song.getTitle()} by ${song.getArtist()}:  ${song.songId.toString()} ${fileTime.toIso8601String()}');
                  logger.i('\tidentical');
                }
              }
            } else {
              if (_verbose) {
                logger.i(
                    '${song.getTitle()} by ${song.getArtist()}:  ${song.songId.toString()} ${fileTime.toIso8601String()}');
              }
              writeTo.writeAsStringSync(fileAsJson, flush: true);
            }

            //  force the modification date
            await setLastModified(writeTo, fileTime.millisecondsSinceEpoch);
          }
          break;

        default:
          logger.e('command not understood: "$arg"');
          exit(-1);
          break;
      }
    }
    print('songs: ${allSongs.length}');
    print('updates: $_updateCount');
    exit(0);
  }

  void _addAllSongsFromDir(dynamic inputFile) {
    logger.i('$inputFile');
    if (!(inputFile is Directory)) return;

    List contents = (inputFile as Directory).listSync();
    for (var file in contents) {
      _addAllSongsFromFile(file);
    }
    return;
  }

  void _addAllSongsFromFile(File inputFile) {
    logger.d('_addAllSongsFromFile: $inputFile');

    if (!(inputFile is File)) return;
    if (!inputFile.path.endsWith('.songlyrics')) return;
    if (_verbose) logger.i('$inputFile');

    //  fix for bad songlyric files
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
      String copyright = song.copyright.trim();
      //print('${song.copyright} ${song.songId.toString()}');
      SplayTreeSet<Song> set = copyrights[copyright];
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
      for (Song song in copyrights[copyright]) {
        print('\t${song.songId.toString()}');
      }
    }
  }

  void _csv() {
    StringBuffer sb = StringBuffer();
    sb.write('Title, Artist, Cover Artist'
        ',User'
        // ',Modified'
        ',Copyright'
        ',Key'
        ',BPM'
        ',Time'
        '\n');
    for (Song song in allSongs) {
      sb.write('"${song.title}","${song.artist ?? ''}","${song.coverArtist ?? ''}"'
          ',"${song.user ?? ''}"'
          //  ',"${song.lastModifiedTime??''}"'
          ',"${song.copyright?.substring(0, min(song.copyright?.length ?? 0, 80)) ?? ''}"'
          ',"${song.key ?? ''}"'
          ',"${song.defaultBpm ?? ''}"'
          ',"${song.beatsPerBar ?? '4'}/${song.unitsPerMeasure ?? '4'}"'
          '\n');
    }

    //print(sb.toString());
    File writeTo = File(homePath() + '/allSongs.csv');
    writeTo.writeAsStringSync(sb.toString(), flush: true);
  }

  Directory _outputDirectory = Directory.current;
  SplayTreeSet<Song> allSongs = SplayTreeSet();
  File _file;
  bool _verbose = false;
  bool _veryVerbose = false;
  bool _force = false; //  force a file write, even if it already exists
  int _updateCount = 0;
  static RegExp notWordOrSpaceRegExp = RegExp(r'[^\w\s]');
}

String homePath() {
  String home = '';
  Map<String, String> envVars = Platform.environment;
  if (Platform.isMacOS) {
    home = envVars['HOME'];
  } else if (Platform.isLinux) {
    home = envVars['HOME'];
  } else if (Platform.isWindows) {
    home = envVars['UserProfile'];
  }
  return home;
}
