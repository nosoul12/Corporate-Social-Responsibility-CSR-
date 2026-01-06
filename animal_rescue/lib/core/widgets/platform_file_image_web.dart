import 'dart:html' as html;

import 'package:flutter/material.dart';

class PlatformFileImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;

  const PlatformFileImage(
    this.path, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('blob:') || path.startsWith('data:')) {
      return Image.network(
        path,
        fit: fit,
        width: width,
        height: height,
      );
    }

    // ImagePicker on web can return a local path-like value; it isn't directly
    // readable. Fallback to placeholder.
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.image, size: 40, color: Colors.grey),
      ),
    );
  }
}

html.FileUploadInputElement createImagePickerInput() {
  final input = html.FileUploadInputElement();
  input.accept = 'image/*';
  return input;
}
