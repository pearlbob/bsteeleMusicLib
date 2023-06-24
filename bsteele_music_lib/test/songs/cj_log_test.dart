import 'package:bsteele_music_lib/app_logger.dart';
import 'package:test/test.dart';

void main() {
  test('test cj log processing', () {
    String input = '08-Jun-2023 21:30:30.754 INFO [http-nio-8080-exec-9] '
        'com.bsteele.bsteeleMusicApp.WebSocketServer.onMessage '
        'onMessage("{ "state": "idle", "currentKey": "C", "song": { '
        '"title": "Saturday Night\'s Alright (For Fighting)", '
        '"artist": "Elton John", '
        '"user": "Shari", "lastModifiedDate": 1672208465503, "copyright": "1973 MCA, DJM", '
        '"key": "C", "defaultBpm": 151, "timeSignature": "4/4", '
        '"chords":      [ 	"I:", 	"G G F GCGC x2", 	"I2:", 	"D5 D7sus4", 	"I3:", 	"G Cm/EbBb/D C C", 	"G G.D5F G G.D5F"'
        ', 	"I4:", 	"G EbBb C C", 	"I5:", 	"C C Bb Bb", 	"F F C C", 	"C C Bb Bb", 	"F F C CC/E"'
        ', 	"I6:", 	"C C Bb Bb", 	"F F C C", 	"V:", 	"G G F F", 	"C C G G", 	"C:", 	"C C Bb Bb"'
        ', 	"F F C C", 	"C C Bb Bb", 	"F F C CC/E", 	"C2:", 	"C C Bb Bb", 	"F F C C", 	"O:"'
        ', 	"C C Bb Bb |", 	"F F C C | x4"     ], '
        '"lyrics":      [ 	"I:", 	"(instrumental)", 	"", 	"V:", 	"It\'s getting late, have you seen my mates? Ma"'
        ', 	"Tell me when the boys get here, it\'s ", 	"Seven o\'clock and I wanna rock, wanna ",'
        ' 	"Get a belly full of beer", 	"", 	'
        '"V:", 	"(My) old man\'s drunker than a barrel full of monkeys and my ", 	"Old lady, she don\'t care'
        ', my", 	"Sister looks cute in her braces and boots, a", 	"Handful of grease in her hair", 	"", 	'
        '"I2:", 	"(instrumental)", 	"", 	'
        '"C:", 	"(Oh) don\'t give us none of your aggravation, we had it with your discipline, oh", 	'
        '"Saturday night\'s alright for fighting, get a little action in", 	'
        '"Get about as oiled as a diesel train, gonna set this dance alight, \'cause", 	'
        '"Saturday night\'s the night I like, Saturday night\'s alright, alright, alright", 	"", 	'
        '"I3:", 	"Ooh", 	"", 	"V:", 	"(Well they\'re) packed pretty tight in here tonight", 	'
        '"I\'m looking for a dolly who\'ll see me right, I may", 	"Use a little muscle to get what I need, I may", 	'
        '"Sink a little drink and shout out "She\'s with me!"", 	"", 	'
        '"V:", 	"A couple of the sounds that I really like are the", 	'
        '"Sounds of a switchblade and a motorbike, I\'m a", 	"Juvenile product of the working class, whose ", 	'
        '"Best friend floats in the bottom of a glass", 	"", 	"I2:", 	"Ooh", 	"", 	'
        '"C:", 	"(Oh) don\'t give us none of your aggravation, we had it with your discipline, oh", 	'
        '"Saturday night\'s alright for fighting, get a little action in", 	'
        '"Get about as oiled as a diesel train, gonna set this dance alight, \'cause", 	'
        '"Saturday night\'s the night I like, Saturday night\'s alright, alright, alright", 	"", 	'
        '"I4:", 	"Ooh", 	"", 	"I5:", 	"(instrumental solo)", 	"", 	"I2:", 	"Ooh", 	"", 	'
        '"C:", 	"(Oh) don\'t give us none of your aggravation, we had it with your discipline, oh", 	'
        '"Saturday night\'s alright for fighting, get a little action in", 	'
        '"Get about as oiled as a diesel train, gonna set this dance alight, \'cause", 	'
        '"Saturday night\'s the night I like, Saturday night\'s alright, alright, alright", 	"", 	'
        '"I4:", 	"Ooh", 	"", 	"I6:", 	"(instrumental)", 	"", 	"C2:", 	"Saturday, Saturday, Saturday", 	'
        '"Saturday, Saturday, Saturday", 	"Saturday, Saturday, Saturday ", 	"Night\'s alright", 	"", 	'
        '"C2:", 	"Saturday, Saturday, Saturday", 	"Saturday, Saturday, Saturday", 	"Saturday, Saturday, Saturday ", 	'
        '"Night\'s alright", 	"", 	"C2:", 	"Saturday, Saturday, Saturday", 	"Saturday, Saturday, Saturday", 	'
        '"Saturday, Saturday, Saturday ", 	"Night\'s alright", 	"", 	"O:", 	"(instrumental)"     ] } , '
        '"momentNumber": 104, '
        '"beat": 0, '
        '"user": "studio", '
        '"singer": "Shari C.", '
        '"beatsPerMeasure": 4, '
        '"currentBeatsPerMinute": 151 } ")'
        '''sectionRequest(2023-06-08 21:27:12.574, section: 3), assistant.error: -11.242999999999995
errorAmplitude:    11.2 at section  3/13: Song_Dont_Think_Twice_Its_All_Right_by_Bob_Dylan_coverBy_Bodhi, BPM: 92 (105)
08-Jun-2023 21:30:30.757 INFO [http-nio-8080-exec-4] com.bsteele.bsteeleMusicApp.WebSocketServer.onMessage onMessage("{ "momentNumber": -3 }")
08-Jun-2023 21:30:31.435 INFO [http-nio-8080-exec-2] com.bsteele.bsteeleMusicApp.WebSocketServer.onMessage onMessage("{ "momentNumber": 0 }")
08-Jun-2023 21:31:33.545 INFO [http-nio-8080-exec-5] com.bsteele.bsteeleMusicApp.WebSocketServer.onMessage onMessage("{ "momentNumber": 8, "state": "manualPlay" }")
08-Jun-2023 21:31:47.947 INFO [http-nio-8080-exec-7] com.bsteele.bsteeleMusicApp.WebSocketServer.onMessage onMessage("{ "momentNumber": 16 }")
08-Jun-2023 21:32:04.047 INFO [http-nio-8080-exec-3] com.bsteele.bsteeleMusicApp.WebSocketServer.onMessage onMessage("{ "momentNumber": 24 }")
08-Jun-2023 21:32:05.652 INFO [http-nio-8080-exec-6] com.bsteele.bsteeleMusicApp.WebSocketServer.onMessage onMessage("{ "momentNumber": 26 }")
08-Jun-2023 21:32:32.173 INFO [http-nio-8080-exec-8] com.bsteele.bsteeleMusicApp.WebSocketServer.onMessage onMessage("{ "momentNumber": 42 }")
08-Jun-2023 21:32:48.378 INFO [http-nio-8080-exec-10] com.bsteele.bsteeleMusicApp.WebSocketServer.onMessage onMessage("{ "momentNumber": 50 }")
08-Jun-2023 21:32:59.552 INFO [http-nio-8080-exec-1] com.bsteele.bsteeleMusicApp.WebSocketServer.onMessage onMessage("{ "momentNumber": 58 }")
08-Jun-2023 21:33:13.247 INFO [http-nio-8080-exec-9] com.bsteele.bsteeleMusicApp.WebSocketServer.onMessage onMessage("{ "momentNumber": 66 }")
08-Jun-2023 21:33:16.657 INFO [http-nio-8080-exec-4] com.bsteele.bsteeleMusicApp.WebSocketServer.onMessage onMessage("{ "momentNumber": 68 }")
08-Jun-2023 21:33:43.594 INFO [http-nio-8080-exec-2] com.bsteele.bsteeleMusicApp.WebSocketServer.onMessage onMessage("{ "momentNumber": 84 }")
08-Jun-2023 21:33:49.966 INFO [http-nio-8080-exec-5] com.bsteele.bsteeleMusicApp.WebSocketServer.onMessage onMessage("{ "momentNumber": 88 }")
08-Jun-2023 21:34:16.344 INFO [http-nio-8080-exec-7] com.bsteele.bsteeleMusicApp.WebSocketServer.onMessage onMessage("{ "momentNumber": 104 }")
08-Jun-2023 21:34:21.156 INFO [http-nio-8080-exec-3] com.bsteele.bsteeleMusicApp.WebSocketServer.onMessage onMessage("{ "momentNumber": 106 }")
08-Jun-2023 21:34:46.191 INFO [http-nio-8080-exec-6] com.bsteele.bsteeleMusicApp.WebSocketServer.onMessage onMessage("{ "momentNumber": 122 }")
08-Jun-2023 21:34:52.349 INFO [http-nio-8080-exec-8] com.bsteele.bsteeleMusicApp.WebSocketServer.onMessage onMessage("{ "momentNumber": 126 }")
08-Jun-2023 21:35:06.393 INFO [http-nio-8080-exec-10] com.bsteele.bsteeleMusicApp.WebSocketServer.onMessage onMessage("{ "momentNumber": 134 }")
08-Jun-2023 21:35:19.523 INFO [http-nio-8080-exec-1] com.bsteele.bsteeleMusicApp.WebSocketServer.onMessage onMessage("{ "momentNumber": 142 }")
08-Jun-2023 21:35:32.937 INFO [http-nio-8080-exec-9] com.bsteele.bsteeleMusicApp.WebSocketServer.onMessage onMessage("{ "momentNumber": 150 }")
08-Jun-2023 21:35:45.712 INFO [http-nio-8080-exec-4] com.bsteele.bsteeleMusicApp.WebSocketServer.onMessage onMessage("{ "momentNumber": 158 }")
''';

    logger.i(input);
  });
}
