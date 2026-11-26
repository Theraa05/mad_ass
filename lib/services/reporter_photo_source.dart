import 'dart:typed_data';

import 'reporter_photo_source_stub.dart'
    if (dart.library.html) 'reporter_photo_source_web.dart'
    as source;

Future<Uint8List?> pickReporterPhoto() => source.pickReporterPhoto();

Future<Uint8List?> takeReporterPhoto() => source.takeReporterPhoto();
