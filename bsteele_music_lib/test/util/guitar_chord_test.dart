import 'dart:convert';
import 'dart:io';

import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/songs/chord.dart';
import 'package:bsteele_music_lib/util/guitar_chords.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

// ignore_for_file: avoid_print

void main() {
  Logger.level = Level.info;

  test('guitar chord test', () {
    var jsonString = '{"C":[{"positions":["x","3","2","0","1","0"],"fingerings":[["0","3","2","0","1","0"]]}]}';

    GuitarChord guitarChord = GuitarChord.fromJson(jsonDecode(jsonString));

    logger.i('$guitarChord');

    //  see that the json encode/decode functions
    var jsonGc = GuitarChord.fromJson(jsonDecode(jsonEncode(guitarChord)));
    expect(jsonGc, guitarChord);
  });

  test('all guitar chords test', () async {
    var directory = Directory.current;
    logger.i('path: ${directory.path}');
    var contents = await File('lib/assets/guitar_chords.json').readAsString();

    List<GuitarChord> list = GuitarChord.fromJsonList(jsonDecode(contents));

    print('chords list length: ${list.length}');

    //  validate the chords
    for (GuitarChord gc in list) {
      assert(Chord.parseString(gc.name, 4) != null);
    }
    expect(list.length, 1071); //  could change?

    // print(jsonEncode(list));
    for (GuitarChord gc in list) {
      print(jsonEncode(gc));

      //  see that the json encode/decode functions
      var jsonGc = GuitarChord.fromJson(jsonDecode(jsonEncode(gc)));
      expect(jsonGc, gc);
    }
  });
}
