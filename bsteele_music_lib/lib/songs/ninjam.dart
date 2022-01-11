import 'package:bsteeleMusicLib/songs/phrase.dart';
import 'package:bsteeleMusicLib/songs/section.dart';
import 'package:bsteeleMusicLib/songs/song.dart';
import 'package:quiver/collection.dart';

import 'chordSection.dart';
import 'key.dart';

const int _maxCycle = 64;

class NinJam {
  NinJam.empty()
      : bpm = 0,
        key = Key.getDefault(),
        keyOffset = 0;

  NinJam(Song song, {Key? key, int? keyOffset})
      : bpm = song.beatsPerMinute,
        key = key ?? song.key,
        keyOffset = keyOffset ?? (song.key.halfStep - (key ?? song.key).halfStep) {
    ChordSection? ninJamChordSection;
    bool allSignificantChordSectionsMatch = true;

    var chordSections = song.getChordSections();
    if (chordSections.length == 1) {
      ninJamChordSection = chordSections.first;
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
          if (ninJamChordSection == null) {
            ninJamChordSection = chordSection;
          } else {
            if (ninJamChordSection.phrases.length == chordSection.phrases.length) {
              //  fixme: complications associated with repeats are not dealt with properly here
              //  repetition repeats are ignored!
              for (int phraseIndex = 0; phraseIndex < ninJamChordSection.phrases.length; phraseIndex++) {
                if (!listsEqual(
                    ninJamChordSection.phrases[phraseIndex].measures, chordSection.phrases[phraseIndex].measures)) {
                  allSignificantChordSectionsMatch = false;
                  break;
                }
              }
            } else {
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
    if (ninJamChordSection != null && allSignificantChordSectionsMatch) {
      int bars = ninJamChordSection.getTotalMoments();
      if (ninJamChordSection.phrases.length == 1 && ninJamChordSection.phrases[0].isRepeat()) {
        bars = ninJamChordSection.phrases[0].measures.length;
        _phrases = [Phrase(ninJamChordSection.phrases[0].measures, 0)];
      } else {
        _phrases = ninJamChordSection.phrases;
      }
      int beatsPerInterval = song.timeSignature.beatsPerBar * bars;
      if (beatsPerInterval <= _maxCycle) {
        _bpi = beatsPerInterval;
      }
    }
  }

  String toMarkup() {
    var sb = StringBuffer();
    for (var phrase in phrases) {
      sb.write(phrase.transpose(key, keyOffset));
    }
    return sb.toString();
  }

  bool get isNinJamReady => _bpi > 0;

  int get beatsPerInterval => _bpi;

  int get bpi => _bpi;
  int _bpi = 0;

  final int bpm;

  final Key key;
  final int keyOffset;

  List<Phrase> get phrases => _phrases;

  //  we're expecting that the measures will remain stable over the life of the ninjam on the song
  List<Phrase> _phrases = [];
}
