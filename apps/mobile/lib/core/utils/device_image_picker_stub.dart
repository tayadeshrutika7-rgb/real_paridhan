import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

Future<Uint8List?> pickImageFromBrowser() async {
  try {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (file != null) {
      return await file.readAsBytes();
    }
  } catch (_) {}
  return null;
}

Future<List<Uint8List>> pickMultipleImagesFromBrowser() async {
  try {
    final ImagePicker picker = ImagePicker();
    final List<XFile> files = await picker.pickMultiImage(
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    final List<Uint8List> results = [];
    for (final file in files) {
      results.add(await file.readAsBytes());
    }
    return results;
  } catch (_) {}
  return [];
}
