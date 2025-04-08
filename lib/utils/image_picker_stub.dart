import 'dart:typed_data';
import 'image_picker_interface.dart';

class ImagePickerWeb implements ImagePickerInterface {
  static Future<Map<String, dynamic>?> pickImage() async {
    throw UnsupportedError('Image picking is not supported on this platform.');
  }
}
