import 'dart:typed_data';
import 'device_image_picker_stub.dart'
    if (dart.library.html) 'device_image_picker_web.dart' as picker_impl;

class DeviceImagePicker {
  static Future<Uint8List?> pickImage() async {
    return await picker_impl.pickImageFromBrowser();
  }

  static Future<List<Uint8List>> pickMultipleImages() async {
    return await picker_impl.pickMultipleImagesFromBrowser();
  }
}
