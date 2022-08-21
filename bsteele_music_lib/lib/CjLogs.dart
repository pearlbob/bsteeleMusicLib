import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import 'appLogger.dart';

String? _catalinaBase;

var _ageLimit = Duration(days: 30);

void main(List<String> args) {
  Logger.level = Level.info;

  logger.i('CjLogs:');

  runMain(args);
}

void _help() {
  logger.i('help!');
}

void runMain(List<String> args) async {
  var gZipDecoder = GZipCodec().decoder;
  Utf8Decoder utf8Decoder = Utf8Decoder();
  var dateFormat = DateFormat('dd-MMM-yyyy HH:mm:ss.SSS'); //  20-Aug-2022 06:08:20.127
  var dotEnv = DotEnv(includePlatformEnvironment: true)..load();

  _catalinaBase = dotEnv['CATALINA_BASE'];

  //  help if nothing to do
  if (args.isEmpty) {
    _help();
    //   return;
  }
  for (var arg in args) {
    switch (arg) {
      default:
        logger.i('arg: $arg');
        break;
    }
  }

  if (_catalinaBase == null || _catalinaBase!.isEmpty) {
    logger.i('Empty CATALINA_BASE environment variable');
    exit(-1);
  }
  logger.i('CATALINA_BASE: $_catalinaBase');

  var logs = Directory('$_catalinaBase/logs');
  logger.i('logs: $logs');

  var processedLogs = Directory('${dotEnv['HOME']}/communityJams/logs/${dotEnv['HOST']}');
  logger.i('processedLogs: $processedLogs');

  processedLogs.createSync();

  var now = DateTime.now();
  var list = logs.listSync();
  list.sort((a, b) {
    return a.path.compareTo(b.path);
  });
  for (var fileSystemEntity in list) {
    if (fileSystemEntity is! File) {
      continue;
    }
    var file = fileSystemEntity;
    DateTime date;
    {
      RegExpMatch? m = logRegExp.firstMatch(file.path);
      if (m == null) {
        continue;
      }
      date = DateTime(int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
    }
    var age = Duration(microseconds: now.microsecondsSinceEpoch - date.microsecondsSinceEpoch);

    if (age > _ageLimit) {
      continue;
    }
    logger.i('');
    logger.i('${file.path}:  $date');
    var log = utf8Decoder
        .convert(file.path.endsWith('.gz') ? gZipDecoder.convert(file.readAsBytesSync()) : file.readAsBytesSync());

    for (var line in log.split('\n')) {
      RegExpMatch? m = messageRegExp.firstMatch(line);
      if (m == null) {
        continue;
      }
      var dateTime = dateFormat.parse(m.group(1)!);
      logger.i('$dateTime: ${m.group(2)}');
      // logger.i('$line');
    }
  }
}

final RegExp logRegExp = RegExp(r'.*/catalina\.(\d{4})-(\d{2})-(\d{2})\.log'); //  note: no end for .log and .log.gz
final RegExp messageRegExp = RegExp(r'(\d{2}-\w{3}-\d{4} \d{2}:\d{2}:\d{2}\.\d{3}) INFO .*'
    r' com.bsteele.bsteeleMusicApp.WebSocketServer.onMessage'
    r' onMessage\("(.*)"\)\s*$');
