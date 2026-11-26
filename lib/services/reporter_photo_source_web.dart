// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

Future<Uint8List?> pickReporterPhoto() async {
  final input = html.FileUploadInputElement()..accept = 'image/png,image/jpeg';
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

Future<Uint8List?> takeReporterPhoto() async {
  final devices = html.window.navigator.mediaDevices;
  if (devices == null) {
    throw UnsupportedError('This browser does not expose a camera.');
  }

  final stream = await devices.getUserMedia({'video': true});
  final video = html.VideoElement()
    ..autoplay = true
    ..muted = true
    ..style.display = 'none'
    ..srcObject = stream;
  html.document.body?.append(video);

  try {
    await video.onLoadedMetadata.first;
    await video.play();
    final width = video.videoWidth;
    final height = video.videoHeight;
    if (width == 0 || height == 0) {
      throw StateError('Camera did not provide an image.');
    }

    final canvas = html.CanvasElement(width: width, height: height);
    final context = canvas.context2D;
    context.drawImage(video, 0, 0);
    final data = canvas.toDataUrl('image/jpeg', 0.86);
    return Uint8List.fromList(base64.decode(data.split(',').last));
  } finally {
    for (final track in stream.getTracks()) {
      track.stop();
    }
    video.remove();
  }
}
