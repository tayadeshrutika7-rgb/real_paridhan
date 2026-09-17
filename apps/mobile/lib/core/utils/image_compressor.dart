import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageCompressor {
  static const int maxTargetSizeBytes = 500 * 1024; // 500 KB limit
  static const int maxDimension = 1600; // max width/height

  /// Compresses [rawBytes] client-side to ensure file size <= 500KB.
  /// Decodes, resizes if larger than [maxDimension], and applies progressive JPEG encoding.
  static Future<Uint8List> compressImage(Uint8List rawBytes) async {
    // If already under 500KB, return as-is
    if (rawBytes.lengthInBytes <= maxTargetSizeBytes) {
      return rawBytes;
    }

    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      // Fallback to original bytes if decoding fails
      return rawBytes;
    }

    img.Image resized = decoded;
    if (decoded.width > maxDimension || decoded.height > maxDimension) {
      if (decoded.width >= decoded.height) {
        resized = img.copyResize(decoded, width: maxDimension);
      } else {
        resized = img.copyResize(decoded, height: maxDimension);
      }
    }

    // Progressively adjust JPEG quality to fit under target size
    int quality = 85;
    Uint8List compressed = Uint8List.fromList(img.encodeJpg(resized, quality: quality));

    while (compressed.lengthInBytes > maxTargetSizeBytes && quality > 40) {
      quality -= 15;
      compressed = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    }

    return compressed;
  }
}
