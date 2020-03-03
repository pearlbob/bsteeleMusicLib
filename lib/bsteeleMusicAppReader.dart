import 'dart:convert';
import 'dart:typed_data';

import 'package:universal_html/prefer_universal/html.dart';

class BSteeleMusicAppReader {
  static void filePick() {
    InputElement uploadInput = FileUploadInputElement();
    //uploadInput.accept = '.songlyrics';  //  only accepts known types
    uploadInput.multiple = true;
    uploadInput.draggable = true;
    uploadInput.onChange.listen((e) {
      for (File file in uploadInput.files) {
        if (file.name.endsWith('.songlyrics')) {
          //logger.i('file: ${file.name}, ${file.toString()}, ${file.type}, ${file.runtimeType}');

          final reader = FileReader();
          reader.onLoadEnd.listen((e) {
            Uint8List data = Base64Decoder().convert(reader.result.toString().split(",").last);
            String s = utf8.decode(data);
            //logger.i('onLoadEnd: $s');
          });
          reader.readAsDataUrl(file);
        }
      }
    });
    uploadInput.click();
  }
}
