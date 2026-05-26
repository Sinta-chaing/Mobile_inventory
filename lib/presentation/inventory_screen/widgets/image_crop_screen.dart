import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/app_theme.dart';

class ImageCropScreen extends StatefulWidget {
  final XFile imageFile;

  const ImageCropScreen({super.key, required this.imageFile});

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  Rect? _selectionRect;
  Offset? _dragStart;
  ui.Image? _image;
  Size _imageSize = Size.zero;
  double _displayScale = 1.0;
  Offset _displayOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _image = frame.image;
      _imageSize = Size(_image!.width.toDouble(), _image!.height.toDouble());
    });
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _dragStart = details.localPosition;
      _selectionRect = Rect.fromPoints(_dragStart!, _dragStart!);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragStart == null) return;
    setState(() {
      _selectionRect = Rect.fromPoints(_dragStart!, details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {}

  void _confirm() async {
    if (_selectionRect == null || _selectionRect!.size.width < 10 || _selectionRect!.size.height < 10) {
      Navigator.pop(context, null);
      return;
    }
    final cropRect = Rect.fromLTRB(
      ((_selectionRect!.left - _displayOffset.dx) / _displayScale).clamp(0, _imageSize.width),
      ((_selectionRect!.top - _displayOffset.dy) / _displayScale).clamp(0, _imageSize.height),
      ((_selectionRect!.right - _displayOffset.dx) / _displayScale).clamp(0, _imageSize.width),
      ((_selectionRect!.bottom - _displayOffset.dy) / _displayScale).clamp(0, _imageSize.height),
    );
    Navigator.pop(context, cropRect);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Select Object'),
        actions: [
          TextButton(
            onPressed: _confirm,
            child: const Text('Search', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _image == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : LayoutBuilder(
              builder: (context, constraints) {
                _displayScale = _fitScale(_imageSize, constraints.biggest);
                _displayOffset = Offset(
                  (constraints.maxWidth - _imageSize.width * _displayScale) / 2,
                  (constraints.maxHeight - _imageSize.height * _displayScale) / 2,
                );
                final fitted = Size(_imageSize.width * _displayScale, _imageSize.height * _displayScale);
                final offsetX = _displayOffset.dx;
                final offsetY = _displayOffset.dy;

                return GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: Stack(
                    children: [
                      Center(
                        child: SizedBox.fromSize(
                          size: fitted,
                          child: RawImage(
                            image: _image,
                            fit: BoxFit.fill,
                            width: fitted.width,
                            height: fitted.height,
                          ),
                        ),
                      ),
                      if (_selectionRect != null)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _CropPainter(
                              selectionRect: Rect.fromLTWH(
                                _selectionRect!.left,
                                _selectionRect!.top,
                                _selectionRect!.width,
                                _selectionRect!.height,
                              ),
                              imageRect: Rect.fromLTWH(offsetX, offsetY, fitted.width, fitted.height),
                            ),
                          ),
                        ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 40,
                        child: Text(
                          'Drag to draw a rectangle around the object',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  double _fitScale(Size src, Size dst) {
    final scaleX = dst.width / src.width;
    final scaleY = dst.height / src.height;
    return scaleX < scaleY ? scaleX : scaleY;
  }
}

class _CropPainter extends CustomPainter {
  final Rect selectionRect;
  final Rect imageRect;

  _CropPainter({required this.selectionRect, required this.imageRect});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withAlpha(100);

    // Draw four rectangles around the selection so the product is always visible
    // Top
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, selectionRect.top), overlayPaint);
    // Bottom
    canvas.drawRect(Rect.fromLTRB(0, selectionRect.bottom, size.width, size.height), overlayPaint);
    // Left
    canvas.drawRect(Rect.fromLTRB(0, selectionRect.top, selectionRect.left, selectionRect.bottom), overlayPaint);
    // Right
    canvas.drawRect(Rect.fromLTRB(selectionRect.right, selectionRect.top, size.width, selectionRect.bottom), overlayPaint);

    // Selection border
    final borderPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRect(selectionRect, borderPaint);

    // Corner handles
    final handlePaint = Paint()..color = Colors.white;
    const handleSize = 6.0;
    for (final corner in [
      selectionRect.topLeft,
      selectionRect.topRight,
      selectionRect.bottomLeft,
      selectionRect.bottomRight,
    ]) {
      canvas.drawCircle(corner, handleSize, handlePaint);
    }
  }

  @override
  bool shouldRepaint(_CropPainter oldDelegate) =>
      oldDelegate.selectionRect != selectionRect;
}
