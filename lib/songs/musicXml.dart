import 'package:xml/xml.dart';

class MusicXml {
  static XmlDocument parse(String musicXml) {
    return XmlDocument.parse(musicXml);
  }
}
