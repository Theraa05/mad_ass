import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/reporter_photo_source.dart';
import '../theme/app_theme.dart';

class ReporterPhotoInput extends StatefulWidget {
  const ReporterPhotoInput({
    super.key,
    required this.onChanged,
    this.requiredPhoto = false,
  });

  final ValueChanged<Uint8List?> onChanged;
  final bool requiredPhoto;

  @override
  State<ReporterPhotoInput> createState() => _ReporterPhotoInputState();
}

class _ReporterPhotoInputState extends State<ReporterPhotoInput> {
  Uint8List? _photo;
  bool _busy = false;

  Future<void> _run(Future<Uint8List?> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final photo = await action();
      if (photo != null && mounted) {
        setState(() => _photo = photo);
        widget.onChanged(photo);
      }
    } on UnsupportedError catch (error) {
      _message(error.message ?? 'This action is available in Chrome.');
    } catch (error) {
      _message('Unable to load the photo: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _remove() {
    setState(() => _photo = null);
    widget.onChanged(null);
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final photo = _photo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.requiredPhoto ? 'Photo *' : 'Photo (optional)',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (photo != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              photo,
              key: const ValueKey('reporter-photo-preview'),
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('replace-photo'),
                onPressed: _busy ? null : () => _run(pickReporterPhoto),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Replace'),
              ),
              TextButton.icon(
                key: const ValueKey('remove-photo'),
                onPressed: _busy ? null : _remove,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Remove'),
              ),
            ],
          ),
        ] else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('take-photo'),
                onPressed: _busy ? null : () => _run(takeReporterPhoto),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(_busy ? 'Opening camera…' : 'Take Photo'),
              ),
              OutlinedButton.icon(
                key: const ValueKey('upload-image'),
                onPressed: _busy ? null : () => _run(pickReporterPhoto),
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Upload Image'),
              ),
            ],
          ),
        const SizedBox(height: 5),
        const Text(
          'JPG or PNG · up to 5 MB',
          style: TextStyle(fontSize: 11, color: TarumtColors.muted),
        ),
      ],
    );
  }
}
