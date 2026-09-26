// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

Future<Uint8List?> pickImageFromBrowser() async {
  final completer = Completer<Uint8List?>();
  final input = html.FileUploadInputElement()..accept = 'image/*';
  input.click();

  input.onChange.listen((event) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }
    final file = files.first;
    final reader = html.FileReader();
    reader.onLoadEnd.listen((e) {
      if (reader.result != null) {
        final result = reader.result;
        if (result is Uint8List) {
          completer.complete(result);
        } else if (result is ByteBuffer) {
          completer.complete(result.asUint8List());
        } else if (result is List<int>) {
          completer.complete(Uint8List.fromList(result));
        } else {
          completer.complete(null);
        }
      } else {
        completer.complete(null);
      }
    });
    reader.onError.listen((_) => completer.complete(null));
    reader.readAsArrayBuffer(file);
  });

  return completer.future;
}

Future<List<Uint8List>> pickMultipleImagesFromBrowser() async {
  final completer = Completer<List<Uint8List>>();
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = true;
  input.click();

  input.onChange.listen((event) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete([]);
      return;
    }

    final List<Uint8List> results = [];
    int pending = files.length;

    for (final file in files) {
      final reader = html.FileReader();
      reader.onLoadEnd.listen((e) {
        if (reader.result != null) {
          final res = reader.result;
          if (res is Uint8List) {
            results.add(res);
          } else if (res is ByteBuffer) {
            results.add(res.asUint8List());
          } else if (res is List<int>) {
            results.add(Uint8List.fromList(res));
          }
        }
        pending--;
        if (pending == 0) {
          completer.complete(results);
        }
      });
      reader.onError.listen((_) {
        pending--;
        if (pending == 0) {
          completer.complete(results);
        }
      });
      reader.readAsArrayBuffer(file);
    }
  });

  return completer.future;
}
