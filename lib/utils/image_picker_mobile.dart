import 'dart:typed_data';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'image_picker_interface.dart';

class ImagePickerMobile implements ImagePickerInterface {
  static Future<Map<String, dynamic>?> pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 75,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64 = base64Encode(bytes);
        return {
          'bytes': bytes,
          'base64': 'data:image/${image.name.split('.').last};base64,$base64',
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
