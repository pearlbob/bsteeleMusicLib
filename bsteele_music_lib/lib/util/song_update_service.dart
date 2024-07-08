import 'dart:async';

import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/songs/song.dart';
import 'package:bsteele_music_lib/songs/song_update.dart';
import 'package:change_notifier/change_notifier.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/status.dart' as web_socket_status;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'app_log_message.dart';

const Level _log = Level.debug;
const Level _logMessage = Level.info;
const Level _logJson = Level.debug;
const Level _logLeader = Level.debug;

typedef SongUpdateCallback = void Function(SongUpdate songUpdate);

class SongUpdateService extends ChangeNotifier {
  SongUpdateService.open() {
    _singleton._open();
  }

  SongUpdateService.close() {
    _singleton._close();
  }

  static final SongUpdateService _singleton = SongUpdateService._internal();

  factory SongUpdateService() {
    return _singleton;
  }

  SongUpdateService._internal();

  void _open() async {
    if (_isRunning) {
      return;
    }
    _isRunning = true; //  start only once!

    var lastHost = '';

    while (_isRunning) //  retry on a failure
    {
      _closeWebSocketChannel();

      //  look back to the server to possibly find a websocket
      host = _findTheHost();
      _ipAddress = '';

      if (host.isEmpty) {
        // do nothing
        logger.log(_log, 'webSocket: empty _host');
      } else {
        //  assume that the authority is good, or at least worth trying
        var url = 'ws://$host$_port/bsteeleMusicApp/bsteeleMusic';
        logger.log(_log, 'trying: $url');
        appLogMessage('webSocket try _host: "$host"');

        try {
          //  or re-try
          Uri uri = Uri.parse(url);
          _responseCount = 0;

          _webSocketChannel =
              WebSocketChannel.connect(uri); //  fixme: currently the package can throw an unhandled exception here!
          _webSocketSink = _webSocketChannel!.sink;
          notifyListeners();

          //  setup the song update service listening
          logger.log(_log, 'listen to: $_ipAddress, $uri');
          _subscription = _webSocketChannel!.stream.listen((message) {
            _responseCount++;
            if (_responseCount == 1) {
              notifyListeners(); //  notify on change of status
            }

            if (message is String) {
              if (message.startsWith(_timeRequest)) {
                //  time
                logger.i('time response: $message');
              } else {
                _songUpdate = SongUpdate.fromJson(message);
                if (_songUpdate != null) {
                  callback?.call(_songUpdate!); //  fixme:  exposure to UI internals
                  _delayMilliseconds = 0;
                  _songUpdateCount++;
                  logger.log(
                      _logMessage,
                      'received: song: ${_songUpdate?.song.title}'
                      ' at moment: ${_songUpdate?.momentNumber}');
                }
              }
            }
          }, onError: (Object error) {
            logger.log(_log, 'webSocketChannel error: "$error" at "$uri"'); //  fixme: retry later
            _closeWebSocketChannel();
            appLogMessage('webSocketChannel error: $error at $uri');
          }, onDone: () {
            logger.log(_log, 'webSocketChannel onDone: at $uri');
            _closeWebSocketChannel();
            appLogMessage('webSocketChannel onDone: at $uri');
          });

          //  See if the server is there, that is, force a response that
          //  confirms the connection
          _issueTimeRequest();

          if (lastHost != host) {
            notifyListeners();
          }
          lastHost = host;

          if (_webSocketChannel != null) {
            for (_idleCount = 0;; _idleCount++) {
              //  idle
              await Future.delayed(const Duration(milliseconds: _idleMilliseconds));

              //  check connection status
              if (lastHost != _findTheHost()) {
                logger.log(_log, 'lastHost != _findTheHost(): "$lastHost" vs "${_findTheHost()}"');
                appLogMessage('webSocketChannel new _host: $uri');
                _closeWebSocketChannel();
                _delayMilliseconds = 0;
                notifyListeners();
                break;
              }
              if (!_isOpen) {
                logger.log(_log, 'on close: $lastHost');
                _delayMilliseconds = 0;
                _idleCount = 0;
                notifyListeners();
                break;
              }
              if (isConnected != _wasConnected) {
                _wasConnected = isConnected;
                //  notify on first idle cycle
                notifyListeners();
              }
              logger.log(_log, 'webSocketChannel open: $_isOpen, idleCount: $_idleCount');
            }
          }
        } catch (e) {
          logger.log(_log, 'webSocketChannel exception: $e');
          _closeWebSocketChannel();
        }
      }

      if (_delayMilliseconds > 0) {
        //  wait a while
        if (_delayMilliseconds < maxDelayMilliseconds) {
          logger.log(_log, 'wait a while... before retrying websocket: $_delayMilliseconds ms');
        }
        await Future.delayed(Duration(milliseconds: _delayMilliseconds));
      }

      //  backoff bothering the server with repeated failures
      if (_delayMilliseconds < maxDelayMilliseconds) {
        _delayMilliseconds += _idleMilliseconds;
      }
    }
  }

  void _close() {
    _isRunning = false;
  }

  /// Override as necessary
  String _findTheHost() {
    return host;
  }

  void _closeWebSocketChannel() async {
    if (_webSocketSink != null) {
      _webSocketSink = null;
      _webSocketChannel?.sink.close(web_socket_status.normalClosure);
      _webSocketChannel = null;
      _idleCount = 0;
      _responseCount = 0;
      _wasConnected = false;
      await _subscription?.cancel();
      _subscription = null;
      //fixme: make sticky across retries:   _isLeader = false;
      _songUpdateCount = 0;
      notifyListeners();
    }
  }

  static const _timeRequest = 't:';

  void _issueTimeRequest() {
    _webSocketSink?.add(_timeRequest);
    logger.t('_issueTimeRequest()');
  }

  void issueSongUpdate(SongUpdate songUpdate, {bool force = false}) {
    if (_isLeader || force) {
      songUpdate.setUser(user);
      var jsonText = songUpdate.toJson();
      _webSocketSink?.add(jsonText);
      logger.log(_logJson, jsonText);
      _songUpdateCount++;
      logger.log(_logLeader, "leader ${songUpdate.getUser()} issueSongUpdate #$_songUpdateCount: $songUpdate");
    }
  }

  bool get _isOpen => _webSocketChannel != null;

  bool get isConnected => _isOpen && _responseCount > 0;

  bool _wasConnected = false;

  bool get isIdle => host.isEmpty;

  set isLeader(bool value) {
    if (value == _isLeader) {
      return;
    }
    _isLeader = value;
    notifyListeners();
  }

  bool _isRunning = false;

  bool get isFollowing => !_isLeader && !isIdle && isConnected;

  bool get isLeader => isConnected && _isLeader;
  bool _isLeader = false;

  SongUpdate? _songUpdate;

  SongUpdateCallback? callback;

  String get leaderName => (_songUpdate != null ? _songUpdate!.user : Song.defaultUser);
  WebSocketChannel? _webSocketChannel;

  String get ipAddress => _ipAddress;
  String _ipAddress = '';

  String host = '';
  String user = 'unknown';
  static const String _port = ':8080';
  int _songUpdateCount = 0;
  int _idleCount = 0;
  int _responseCount = 0;
  WebSocketSink? _webSocketSink;
  static const int _idleMilliseconds = Duration.millisecondsPerSecond ~/ 2;
  static const int maxDelayMilliseconds = 3 * Duration.millisecondsPerSecond;

  static int get delayMilliseconds => _singleton._delayMilliseconds;
  var _delayMilliseconds = 0;
  StreamSubscription<dynamic>? _subscription;
}
