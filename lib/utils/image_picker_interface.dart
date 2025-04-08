import 'dart:typed_data';

abstract class ImagePickerInterface {
  static Future<Map<String, dynamic>?> pickImage() async {
    throw UnimplementedError('pickImage() has not been implemented.');
  }
}
