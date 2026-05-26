import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Preview for a locally picked image. Uses [Image.memory] on all platforms
/// because [Image.file] is not supported on Flutter Web.
class PickedImagePreview extends StatelessWidget {
  const PickedImagePreview({
    super.key,
    required this.imageBytes,
    this.height = 120,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final Uint8List imageBytes;
  final double height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final image = Image.memory(
      imageBytes,
      height: height,
      width: width ?? double.infinity,
      fit: fit,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('PickedImagePreview error: $error');
        return _errorPlaceholder();
      },
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _errorPlaceholder() {
    return Container(
      height: height,
      width: width ?? double.infinity,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined, size: 48),
    );
  }
}

/// Reads bytes from an [XFile], with a web-safe fallback when path is a blob URL.
Future<Uint8List?> readImageBytes(XFile file) async {
  try {
    return await file.readAsBytes();
  } catch (e) {
    debugPrint('readImageBytes failed: $e');
    return null;
  }
}
