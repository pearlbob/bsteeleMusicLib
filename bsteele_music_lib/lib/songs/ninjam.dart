import 'package:bsteeleMusicLib/songs/phrase.dart';
import 'package:bsteeleMusicLib/songs/section.dart';
import 'package:bsteeleMusicLib/songs/song.dart';
import 'package:quiver/collection.dart';

import 'chordSection.dart';

class NinJam {
  NinJam.empty() : bpm = 0;

  NinJam(Song song) : bpm = song.beatsPerMinute {
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
            if (!listsEqual(ninJamChordSection.phrases, chordSection.phrases)) {
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
      if (beatsPerInterval <= 48) {
        _bpi = beatsPerInterval;
      }
    }
  }

  String toMarkup() {
    var sb = StringBuffer();
    for (var phrase in phrases) {
      sb.write(phrase.toMarkup());
    }
    return sb.toString();
  }

  bool get isNinJamReady => _bpi > 0;

  int get beatsPerInterval => _bpi;

  int get bpi => _bpi;
  int _bpi = 0;

  final int bpm;

  List<Phrase> get phrases => _phrases;

  //  we're expecting that the measures will remain stable over the life of the ninjam on the song
  List<Phrase> _phrases = [];
}
