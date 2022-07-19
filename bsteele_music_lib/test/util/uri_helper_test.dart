import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/util/uri_helper.dart';
import 'package:test/test.dart';

//  test the dart Uri class properties

void main() {
  test('test util limit', () {
    const bs = 'bsteele.com';
    {
      final uri = Uri.parse('http://$bs:8080');

      logger.i('authority: "${uri.authority}", hasAuthority: ${uri.hasAuthority}');
      logger.i('path: "${uri.path}", origin: ${uri.origin}');
      logger.i('scheme: "${uri.scheme}", hasScheme: ${uri.hasScheme}');

      expect(uri.hasAuthority, isTrue);
      expect(uri.hasScheme, isTrue);
      expect(uri.host, bs);
      expect(uri.authority, '$bs:8080');
      expect(uri.port, 8080);
    }
    logger.i('');
    {
      var uriString = '$bs:8080';
      logger.i('uriString: "$uriString"');
      var uri = extractUri(uriString);
      expect(uri, isNotNull);
      uri = uri!;
      logger.i('"$uri"');
      logger.i('authority: "${uri.authority}", hasAuthority: ${uri.hasAuthority}');
      logger.i('path: "${uri.path}"');
      logger.i('scheme: "${uri.scheme}", hasScheme: ${uri.hasScheme}');

      expect(uri.hasAuthority, isTrue);
      expect(uri.hasScheme, isTrue);
      expect(uri.host, bs);
      expect(uri.port, 8080);
    }
    logger.i('');
    {
      var uriString = '';
      logger.i('uriString: "$uriString"');
      var uri = extractUri(uriString);
      expect(uri, isNotNull);
      uri = uri!;
      logger.i('"$uri"');
      logger.i('authority: "${uri.authority}", hasAuthority: ${uri.hasAuthority}');
      logger.i('path: "${uri.path}"');
      logger.i('scheme: "${uri.scheme}", hasScheme: ${uri.hasScheme}');

      expect(uri.hasAuthority, isTrue);
      expect(uri.authority, '');
      expect(uri.host, '');
      expect(uri.host.isEmpty, isTrue);
      expect(uri.port, 80); //  assumed!
    }
    logger.i('');
    {
      var uriString = 'bob64.local';
      logger.i('uriString: "$uriString"');
      var uri = extractUri(uriString);
      expect(uri, isNotNull);
      uri = uri!;
      logger.i('uri: "$uri"');
      logger.i('authority: "${uri.authority}", hasAuthority: ${uri.hasAuthority}');
      logger.i('path: "${uri.path}"');
      logger.i('scheme: "${uri.scheme}", hasScheme: ${uri.hasScheme}');

      expect(uri.hasAuthority, isTrue);
      expect(uri.authority, uriString);
      expect(uri.host, uriString);
      expect(uri.host.isEmpty, isFalse);
      expect(uri.port, 80); //  assumed!
    }
    logger.i('');
    {
      var uriString = 'bob64.local:8080';
      logger.i('uriString: "$uriString"');
      var uri = extractUri(uriString);
      expect(uri, isNotNull);
      uri = uri!;
      logger.i('uri: "$uri"');
      logger.i('authority: "${uri.authority}", hasAuthority: ${uri.hasAuthority}');
      logger.i('path: "${uri.path}"');
      logger.i('scheme: "${uri.scheme}", hasScheme: ${uri.hasScheme}');

      expect(uri.hasAuthority, isTrue);
      expect(uri.authority, 'bob64.local:8080'); //  why?  don't use authority!!!!!
      expect(uri.host, 'bob64.local');
      expect(uri.host.isEmpty, isFalse);
      expect(uri.port, 8080);
    }
    logger.i('');
    {
      var uriString = 'bob64.local:80';
      var uri = extractUri(uriString);
      expect(uri, isNotNull);
      uri = uri!;
      logger.i('uri: "$uri"');
      logger.i('authority: "${uri.authority}", hasAuthority: ${uri.hasAuthority}');
      logger.i('path: "${uri.path}"');
      logger.i('scheme: "${uri.scheme}", hasScheme: ${uri.hasScheme}');

      expect(uri.hasAuthority, isTrue);
      expect(uri.authority, 'bob64.local'); //  why is port 80 special?  don't use authority!!!!!
      expect(uri.host, 'bob64.local');
      expect(uri.host.isEmpty, isFalse);
      expect(uri.port, 80);
    }
    logger.i('');
    {
      var uriString = '192.168.0.200:80';
      var uri = extractUri(uriString);
      expect(uri, isNotNull);
      uri = uri!;
      logger.i('"$uri"');

      logger.i('uri: "$uri"');
      logger.i('authority: "${uri.authority}", hasAuthority: ${uri.hasAuthority}');
      logger.i('path: "${uri.path}"');
      logger.i('scheme: "${uri.scheme}", hasScheme: ${uri.hasScheme}');

      expect(uri.hasAuthority, isTrue);
      expect(uri.authority, '192.168.0.200'); //  why is port 80 special?  don't use authority!!!!!
      expect(uri.host, '192.168.0.200');
      expect(uri.host.isEmpty, isFalse);
      expect(uri.port, 80);
    }
    logger.i('');
    {
      var uriString = '192.168.0.200:8080';
      var uri = extractUri(uriString);
      expect(uri, isNotNull);
      uri = uri!;
      logger.i('"$uri"');

      logger.i('uri: "$uri"');
      logger.i('authority: "${uri.authority}", hasAuthority: ${uri.hasAuthority}');
      logger.i('path: "${uri.path}"');
      logger.i('scheme: "${uri.scheme}", hasScheme: ${uri.hasScheme}');

      expect(uri.hasAuthority, isTrue);
      expect(uri.authority, '192.168.0.200:8080'); //  why is port 80 special?  don't use authority!!!!!
      expect(uri.host, '192.168.0.200');
      expect(uri.host.isEmpty, isFalse);
      expect(uri.port, 8080);
    }
    logger.i('');
    {
      var uriString = '192.168.0.200:8080?query=where';
      var uri = extractUri(uriString);
      expect(uri, isNotNull);
      uri = uri!;
      logger.i('"$uri"');

      logger.i('uri: "$uri"');
      logger.i('authority: "${uri.authority}", hasAuthority: ${uri.hasAuthority}');
      logger.i('path: "${uri.path}"');
      logger.i('scheme: "${uri.scheme}", hasScheme: ${uri.hasScheme}');

      expect(uri.hasAuthority, isTrue);
      expect(uri.authority, '192.168.0.200:8080'); //  why is port 80 special?  don't use authority!!!!!
      expect(uri.host, '192.168.0.200');
      expect(uri.host.isEmpty, isFalse);
      expect(uri.port, 8080);
    }
    logger.i('');
    {
      //  damaged on entry
      var uriString = 'http192.168.0.200:8080?query=where';
      var uri = extractUri(uriString);
      expect(uri, isNotNull);
      uri = uri!;
      logger.i('"$uri"');

      logger.i('uri: "$uri"');
      logger.i('authority: "${uri.authority}", hasAuthority: ${uri.hasAuthority}');
      logger.i('path: "${uri.path}"');
      logger.i('scheme: "${uri.scheme}", hasScheme: ${uri.hasScheme}');

      expect(uri.hasAuthority, isTrue);
      expect(uri.authority, 'http192.168.0.200:8080'); //  don't use authority!!!!!
      expect(uri.host, 'http192.168.0.200'); //  helper can only do so much... this is still damaged goods
      expect(uri.host.isEmpty, isFalse);
      expect(uri.port, 8080);
    }
  });

  test('test uri domain', () {
    const String url = 'http://www.bsteele.com/bsteeleMusicApp/allSongs.songlyrics';
    Uri? uri = extractUri(url);
    expect(uri?.host, 'www.bsteele.com');
    uri = extractUri('http://192.168.0.200/public_html/bsteeleMusicApp/beta/index.html#/');
    expect(uri?.host, '192.168.0.200');
    uri = extractUri('http://192.168.1.205:8080/bsteeleMusicApp/#/');
    expect(uri?.host, '192.168.1.205');
    uri = extractUri('http://bob64.local/public_html/bsteeleMusicApp/beta/index.html#/');
    expect(uri?.host, 'bob64.local');
    uri = extractUri('http://localhost:36117/#/');
    expect(uri?.host, 'localhost');
    uri = extractUri('http://localhost:8080/bsteeleMusicApp/index.html#/');
    expect(uri?.host, 'localhost');
    expect(uri?.port, 8080);
  });
}
