import 'dart:math';

import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/key.dart';
import 'package:bsteeleMusicLib/util/util.dart';
import 'package:test/test.dart';

void main() {
  test('test util limit', () {
    expect(Util.limit(0, 12, 15), 12);
    expect(Util.limit(0, 23, 15), 15);
    expect(Util.limit(-12, 23, 15), 15);
    expect(Util.limit(312, 23, 15), 23);
    expect(Util.limit(null, null, null), null);
    expect(Util.limit(13, null, null), 13);
    expect(Util.limit(13, 0, null), 13);
    expect(Util.limit(-13, 0, null), 0);
    expect(Util.limit(13, null, 23), 13);
    expect(Util.limit(123, null, 23), 23);
    expect(Util.limit(-123, null, 23), -123);
    expect(Util.limit(-123, null, null), -123);
    expect(Util.limit(3, e, pi), 3);
    expect(Util.limit(0, e, pi), e);
    expect(Util.limit(12, e, pi), pi);
    expect(Util.limit(12 * pi, e, pi), pi);
    expect(Util.limit(2.8, e, pi), 2.8);
    expect(Util.limit(double.infinity, e, pi), pi);
    expect(Util.limit(double.infinity, e, double.maxFinite), double.maxFinite);
    expect(Util.limit(0, e, double.maxFinite), e);
  });

  test('test util camelCaseToLowercaseSpace()', () {
    expect(Util.camelCaseToLowercaseSpace('AbcdefGhiJ'), 'abcdef ghi j');
    expect(Util.camelCaseToLowercaseSpace('abcdefGhij'), 'abcdef ghij');
    expect(Util.camelCaseToLowercaseSpace('abcdef ghij'), 'abcdef ghij');
    expect(Util.camelCaseToLowercaseSpace('a'), 'a');
    expect(Util.camelCaseToLowercaseSpace('A'), 'a');
    expect(Util.camelCaseToLowercaseSpace(''), '');
  });

  test('test util underScoresToCamelCase()', () {
    expect(Util.underScoresToCamelCase('A_bcdef_Ghi_J'), 'ABcdefGhiJ');
    expect(Util.underScoresToCamelCase('a_bcdef_ghi_j'), 'aBcdefGhiJ');
    expect(Util.underScoresToCamelCase('abcdef_ghij'), 'abcdefGhij');
    expect(Util.underScoresToCamelCase('a'), 'a');
    expect(Util.underScoresToCamelCase('A'), 'A');
    expect(Util.underScoresToCamelCase(''), '');
  });

  test('test util enum name', () {
    expect(Util.enumName(KeyEnum.F.toString()), 'F');
    expect(Util.enumFromString('G', KeyEnum.values), KeyEnum.G);
    expect(Util.enumFromString('Gkk', KeyEnum.values), null);
  });

  test('test util readableJson()', () {
    expect(
        Util.readableJson('{\n'
            '"title": "ive go the blanks",\n'
            '"artist": "bob",\n'
            '"coverArtist": "Bob Marley",\n'
            '"user": "pearl bob",\n'
            'lastModifiedDate was here\n'
            '"copyright": "bob",\n'
            '"key": "C",\n'
            '"defaultBpm": 106,\n'
            '"timeSignature": "4/4",\n'
            '"chords": \n'
            '    [\n'
            '\t"I:",\n'
            '\t"A B C D",\n'
            '\t"V:",\n'
            '\t"G G G G",\n'
            '\t"C C G G",\n'
            '\t"O:",\n'
            '\t"C C G G"\n'
            '    ],\n'
            '"lyrics": \n'
            '    [\n'
            '\t"i: (instrumental)",\n'
            '\t"v: line 1",\n'
            '\t"o:"\n'
            '    ]\n'
            '}\n'
            ''),
        '\n'
        'title: ive go the blanks\n'
        'artist: bob\n'
        'coverArtist: Bob Marley\n'
        'user: pearl bob\n'
        'lastModifiedDate was here\n'
        'copyright: bob\n'
        'key: C\n'
        'defaultBpm: 106\n'
        'timeSignature: 4/4\n'
        'chords:\n'
        '\tI:\n'
        '\tA B C D\n'
        '\tV:\n'
        '\tG G G G\n'
        '\tC C G G\n'
        '\tO:\n'
        '\tC C G G\n'
        '    \n'
        'lyrics:\n'
        '\ti: (instrumental)\n'
        '\tv: line 1\n'
        '\to:\n'
        '    \n'
        '\n');
  });

  test('test util DateTime', () async {
    var nowAsString = Util.utcNow();
    logger.i(nowAsString);
    expect(nowAsString.compareTo('20220409_233603'), 1);
    expect(nowAsString.compareTo('20520409_232804'), -1);

    await Future.delayed(Duration(seconds: 1));

    var laterAsString = Util.utcNow();
    logger.i(laterAsString);
    expect(laterAsString.compareTo(nowAsString), 1);

    {
      DateTime dateTime = DateTime.now().toUtc();
      DateTime dateTime2 = Util.yyyyMMdd_HHmmssStringToDate(Util.utcFormat(dateTime));
      expect(dateTime.year, dateTime2.year);
      expect(dateTime.month, dateTime2.month);
      expect(dateTime.day, dateTime2.day);
      expect(dateTime.hour, dateTime2.hour);
      expect(dateTime.minute, dateTime2.minute);
      expect(dateTime.second, dateTime2.second);
      //  milliseconds and microseconds will differ due to truncation
    }

    expect(Util.yyyyMMdd_HHmmssStringToDate('allSongPerformances_20220406_215907.songperformances'),
        DateTime(2022, 4, 6, 21, 59, 7));

    //  bad date:
    expect(
        Util.yyyyMMdd_HHmmssStringToDate('allSongPerformances_k0220406_215907.songperformances'), Util.firstDateTime);
    expect(Util.yyyyMMdd_HHmmssStringToDate('allSongPerformances_k0220406_215907.songperformances', isUtc: true),
        Util.firstUtcDateTime);

    int milliseconds = 1646518349000;
    String s = '20220305_141229';
    expect(Util.utcFormat(DateTime.fromMillisecondsSinceEpoch(milliseconds)), s);
    expect(Util.yyyyMMdd_HHmmssStringToDate(s), DateTime.fromMillisecondsSinceEpoch(milliseconds));
  });
}
