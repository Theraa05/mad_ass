// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:typed_data';

Future<Uint8List?> pickTechnicianPhoto() async {
  final input = html.FileUploadInputElement()..accept = 'image/*';
  final selected = input.onChange.first;
  final cancelled = input.on['cancel'].first;
  input.click();

  final file = await Future.any<html.File?>([
    selected.then((_) {
      final files = input.files;
      return files == null || files.isEmpty ? null : files.first;
    }),
    cancelled.then((_) => null),
  ]);

  if (file == null) return null;

  final reader = html.FileReader();
  final loaded = reader.onLoadEnd.first;
  reader.readAsArrayBuffer(file);
  await loaded;

  final result = reader.result;
  if (result is ByteBuffer) return result.asUint8List();
  if (result is Uint8List) return result;
  throw StateError('Could not read the selected photo.');
}