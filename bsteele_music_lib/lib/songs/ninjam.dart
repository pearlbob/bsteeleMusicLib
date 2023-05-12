import 'phrase.dart';
import 'section.dart';
import 'song.dart';
import 'package:quiver/collection.dart';

import 'chord_section.dart';
import 'key.dart';
import 'measure.dart';

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
      var phrases = ninJamChordSection.phrases;

      //  cheap minimization of the ninJam cycle
      if (ninJamChordSection.phrases.length == 1 && ninJamChordSection.phrases[0].isRepeat()) {
        bars = ninJamChordSection.phrases[0].measures.length;
        phrases = [Phrase(ninJamChordSection.phrases[0].measures, 0)];
      }

      for (var phrase in phrases) {
        for (var repeat = 0; repeat < phrase.repeats; repeat++) {
          for (var measure in phrase.measures) {
            var m = measure.deepCopy();
            //  put end of row on measures that are now the end of the row of measures, even if the were not previously
            if (!measure.endOfRow && identical(measure, phrase.measures.last) && !identical(phrase, phrases.last)) {
              m.endOfRow = true;
            }
            _measures.add(m);
          }
        }
      }
      int beatsPerInterval = song.timeSignature.beatsPerBar * bars;
      if (beatsPerInterval <= _maxCycle) {
        _bpi = beatsPerInterval;
      }
    }
  }

  String toMarkup() {
    var sb = StringBuffer();
    for (var measure in _measures) {
      sb.write(measure.transpose(key, keyOffset));
      sb.write(measure.endOfRow ? ', ' : ' ');
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

  final List<Measure> _measures = [];
}
