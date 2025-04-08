import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:html' as html;
import 'image_picker_interface.dart';

class ImagePickerWeb implements ImagePickerInterface {
  static Future<Map<String, dynamic>?> pickImage() async {
    try {
      final completer = Completer<Map<String, dynamic>?>();

      final input = html.FileUploadInputElement()..accept = 'image/*';
      input.click();

      input.onChange.listen((event) async {
        if (input.files?.isNotEmpty == true) {
          final file = input.files![0];
          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);

          reader.onLoad.listen((event) {
            final bytes = (reader.result as List<int>).cast<int>();
            final base64 = base64Encode(bytes);

            completer.complete({
              'bytes': Uint8List.fromList(bytes),
              'base64': 'data:image/jpeg;base64,$base64',
            });
          });

          reader.onError.listen((event) {
            completer.complete(null);
          });
        } else {
          completer.complete(null);
        }
      });

      return await completer.future;
    } catch (e) {
      return null;
    }
  }
}
