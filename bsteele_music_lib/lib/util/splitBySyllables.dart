// Copyright (c) 2017, filiph. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:bsteeleMusicLib/src/syllables/disyllabic.dart';
import 'package:bsteeleMusicLib/src/syllables/monosyllabic.dart';
import 'package:bsteeleMusicLib/src/syllables/problematic.dart';
import 'package:bsteeleMusicLib/src/syllables/trisyllabic.dart';
import 'package:string_scanner/string_scanner.dart';

import '../appLogger.dart';

final RegExp _allCaps = RegExp(r'^[A-Z]+$');

final RegExp _alpha = RegExp(r'\w');

final RegExp _vowel = RegExp(r'[aeiouy]', caseSensitive: false);

List<String> splitBySyllables(String words) {
  List<String> syllables = [];

  // TODO: deal with contractions

  String joinedWords = words.splitMapJoin(RegExp(r'\W'), onMatch: (m) {
    var nonAlpha = m.group(0) ?? '';
    syllables.add(nonAlpha);
    return nonAlpha;
  }, onNonMatch: (word) {
    if (word.isNotEmpty) {
      syllables.addAll(splitWordBySyllables(word));
    }
    return word;
  });
  assert(joinedWords == words);
  logger.i('joinedWords: $joinedWords');

  return syllables;
}

/// Count syllables in [word].
///
/// Heavily inspired by https://github.com/wooorm/syllable.
List<String> splitWordBySyllables(String word) {
  assert(
      RegExp(r'^\w+$').hasMatch(word),
      "Word '$word' contains non-alphabetic characters. "
      'Have you trimmed the word of whitespace?');

  if (word.length <= 3 && _allCaps.hasMatch(word)) {
    // USA, PC, TV, ...
    return [word];
  }

  if (word.length < 3) {
    return [word];
  }

  final problematicSyllablesList = problematicSyllables[word];
  if (problematicSyllablesList != null) {
    return problematicSyllablesList;
  }
  // TODO: if this is plural, make it singular and try again with problematic

  int count = 0;
  List<String> syllables = [];

  /// Adjusts [count] and returns string without the pattern.
  String adjust(String string, Pattern pattern, int adjustment) {
    return string.replaceAllMapped(pattern, (_) {
      count += adjustment;
      return '';
    });
  }

  // We have to chop off prefixes (like 'afore' or 'hyper') and suffixes
  // (like 'ment' or 'ology') so that we can than scan only the "root"
  // of the word. For example, "abatement" becomes "abate" (-ment), which
  // ends with "-ate", which looks like 2 syllables but actually is just one
  // (which is covered by [monosyllabic2] below).
  String wordRoot = adjust(word, trisyllabicPrefixSuffix, 3);
  wordRoot = adjust(wordRoot, disyllabicPrefixSuffix, 2);
  wordRoot = adjust(wordRoot, monosyllabicPrefixSuffix, 1);

  var scanner = StringScanner(wordRoot);

  bool precedingVowel = false;

  while (!scanner.isDone) {
    var lastCount = count;
    if (scanner.matches(monosyllabic1) || scanner.matches(monosyllabic2)) {
      // The following should count for one less than what it looks like
      // from vowels and consonants alone.
      count -= 1;
      logger.i('monosyllabic: head: \'${scannerHead(scanner)}\', rest: \'${scanner.rest}\'');
    }

    if (scanner.matches(disyllabic1) ||
        scanner.matches(disyllabic2) ||
        scanner.matches(disyllabic3) ||
        scanner.matches(disyllabic4)) {
      // The following should count for one more than what it looks like
      // from vowels and consonants alone.
      count += 1;
      logger.i('disyllabic: head: \'${scannerHead(scanner)}\', rest: \'${scanner.rest}\'');
    }

    if (scanner.scan(_vowel)) {
      if (!precedingVowel) {
        count += 1;
        logger.i('precedingVowel match: head: \'${scannerHead(scanner)}\', rest: \'${scanner.rest}\'');
        syllables.add(scannerHead(scanner));
        scanner = StringScanner(scanner.rest);
      } else {
        logger.i('_vowel match: head: \'${scannerHead(scanner)}\', rest: \'${scanner.rest}\'');
      }
      precedingVowel = true;
      continue;
    }

    if ( lastCount == count ){
      logger.i('no match: head: \'${scannerHead(scanner)}\', rest: \'${scanner.rest}\'');
    }

    scanner.expect(_alpha);
    precedingVowel = false;
  }

  if (count == 0) {
    return [word];
  }
  return syllables;
}

String scannerHead(StringScanner scanner) {
  return scanner.string.substring(0, scanner.position);
}
