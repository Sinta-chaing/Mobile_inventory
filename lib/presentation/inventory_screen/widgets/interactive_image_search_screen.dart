import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/app_theme.dart';
import '../../../services/inventory_service.dart';
import '../inventory_screen.dart';
import './inventory_item_card_widget.dart';

class InteractiveImageSearchScreen extends StatefulWidget {
  final XFile imageFile;
  final List<StockItem> allItems;
  final double? initialThreshold;
  final int? initialTopK;

  const InteractiveImageSearchScreen({
    super.key,
    required this.imageFile,
    required this.allItems,
    this.initialThreshold = 0.3,
    this.initialTopK = 10,
  });

  @override
  State<InteractiveImageSearchScreen> createState() => _InteractiveImageSearchScreenState();
}

class _InteractiveImageSearchScreenState extends State<InteractiveImageSearchScreen> {
  bool _isLoading = false;
  String _loadingMessage = 'Analyzing image...';
  
  ui.Image? _image;
  Size _nativeImageSize = Size.zero;
  
  double _displayScale = 1.0;
  Offset _displayOffset = Offset.zero;
  
  String _detectionMode = 'auto'; // 'auto' (YOLO boxes) or 'manual' (draw rect)
  double _scoreThreshold = 0.3;
  int _topK = 10;
  
  List<Map<String, dynamic>> _detections = [];
  List<int> _imageSearchProductIds = [];
  Map<int, double> _productScores = {};
  List<StockItem> _matchedItems = [];
  
  // Selected box in native coordinates [x1, y1, x2, y2]
  List<int>? _selectedBox;
  
  // Drag selection state for manual mode (in display coordinates)
  Offset? _dragStart;
  Rect? _selectionRect;

  @override
  void initState() {
    super.initState();
    _scoreThreshold = widget.initialThreshold ?? 0.3;
    _topK = widget.initialTopK ?? 10;
    _initFlow();
  }

  Future<void> _initFlow() async {
    await _loadImageSize();
    if (_image != null) {
      // Run initial auto-detection + search with full image
      _triggerSearch(isInitial: true);
    }
  }

  Future<void> _loadImageSize() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _image = frame.image;
          _nativeImageSize = Size(_image!.width.toDouble(), _image!.height.toDouble());
        });
      }
    } catch (e) {
      print('Error loading image size: $e');
    }
  }

  Future<void> _triggerSearch({bool isInitial = false, List<int>? searchBox}) async {
    setState(() {
      _isLoading = true;
      _loadingMessage = isInitial ? 'Detecting objects...' : 'Searching similar products...';
    });

    Map<String, int>? cropCoords;
    if (searchBox != null) {
      cropCoords = {
        'x1': searchBox[0],
        'y1': searchBox[1],
        'x2': searchBox[2],
        'y2': searchBox[3],
      };
    }

    final result = await InventoryService.searchProductsByImage(
      widget.imageFile,
      cropRect: cropCoords,
      scoreThreshold: _scoreThreshold,
      topK: _topK,
    );

    if (!mounted) return;

    final ids = (result['productIds'] as List).cast<int>();
    final scores = (result['scores'] as List?)?.cast<double>() ?? <double>[];
    final detections = (result['detections'] as List).cast<Map<String, dynamic>>();

    final scoreMap = <int, double>{};
    for (int i = 0; i < ids.length && i < scores.length; i++) {
      scoreMap[ids[i]] = scores[i];
    }

    final newMatched = widget.allItems.where((item) {
      final itemId = int.tryParse(item.id) ?? -1;
      return scoreMap.containsKey(itemId);
    }).toList();

    newMatched.sort((a, b) {
      final scoreA = scoreMap[int.tryParse(a.id) ?? -1] ?? 0.0;
      final scoreB = scoreMap[int.tryParse(b.id) ?? -1] ?? 0.0;
      return scoreB.compareTo(scoreA);
    });

    setState(() {
      _isLoading = false;
      _imageSearchProductIds = ids;
      _productScores = scoreMap;
      _matchedItems = newMatched;
      
      // Update detections only on initial full-image search
      if (isInitial || _detections.isEmpty) {
        _detections = detections;
        // Auto-select the highest confidence detection if any
        if (_detectionMode == 'auto' && _detections.isNotEmpty) {
          final sortedDets = [..._detections];
          sortedDets.sort((a, b) => (b['confidence'] as num).compareTo(a['confidence'] as num));
          final bestDet = sortedDets.first;
          final bbox = (bestDet['bbox'] as List).cast<int>();
          _selectedBox = bbox;
          // Trigger search on the auto-selected box immediately
          _triggerSearch(searchBox: bbox);
        }
      }
    });
  }

  void _onPanStart(DragStartDetails details) {
    if (_detectionMode != 'manual') return;
    setState(() {
      _dragStart = details.localPosition;
      _selectionRect = Rect.fromPoints(_dragStart!, _dragStart!);
      _selectedBox = null;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_detectionMode != 'manual' || _dragStart == null) return;
    setState(() {
      _selectionRect = Rect.fromPoints(_dragStart!, details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_detectionMode != 'manual' || _selectionRect == null) return;
    
    if (_selectionRect!.width < 10 || _selectionRect!.height < 10) {
      setState(() {
        _selectionRect = null;
        _selectedBox = null;
      });
      return;
    }

    final cropRect = Rect.fromLTRB(
      ((_selectionRect!.left - _displayOffset.dx) / _displayScale).clamp(0, _nativeImageSize.width),
      ((_selectionRect!.top - _displayOffset.dy) / _displayScale).clamp(0, _nativeImageSize.height),
      ((_selectionRect!.right - _displayOffset.dx) / _displayScale).clamp(0, _nativeImageSize.width),
      ((_selectionRect!.bottom - _displayOffset.dy) / _displayScale).clamp(0, _nativeImageSize.height),
    );

    final bbox = [
      cropRect.left.toInt(),
      cropRect.top.toInt(),
      cropRect.right.toInt(),
      cropRect.bottom.toInt()
    ];

    setState(() {
      _selectedBox = bbox;
    });

    _triggerSearch(searchBox: bbox);
  }

  void _confirmSelectionAndClose() {
    Navigator.pop(context, {
      'productIds': _imageSearchProductIds,
      'scores': _imageSearchProductIds.map((id) => _productScores[id] ?? 0.0).toList(),
      'detections': _detections,
      'threshold': _scoreThreshold,
      'topK': _topK,
    });
  }

  double _fitScale(Size src, Size dst) {
    final scaleX = dst.width / src.width;
    final scaleY = dst.height / src.height;
    return scaleX < scaleY ? scaleX : scaleY;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F11),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _confirmSelectionAndClose,
        ),
        title: Text(
          'Interactive Search',
          style: GoogleFonts.ibmPlexSans(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, {'clear': true}),
            child: Text(
              'Clear',
              style: GoogleFonts.ibmPlexSans(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Segmented control mode selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF0F0F11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _detectionMode = 'auto';
                                _selectionRect = null;
                                _selectedBox = null;
                                if (_detections.isNotEmpty) {
                                  final sortedDets = [..._detections];
                                  sortedDets.sort((a, b) => (b['confidence'] as num).compareTo(a['confidence'] as num));
                                  _selectedBox = (sortedDets.first['bbox'] as List).cast<int>();
                                  _triggerSearch(searchBox: _selectedBox);
                                } else {
                                  _triggerSearch();
                                }
                              });
                            },
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _detectionMode == 'auto'
                                    ? Colors.white.withAlpha(40)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.auto_fix_high_rounded, size: 14, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    'AI Detection',
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _detectionMode = 'manual';
                                _selectedBox = null;
                                _selectionRect = null;
                              });
                            },
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _detectionMode == 'manual'
                                    ? Colors.white.withAlpha(40)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.crop_rounded, size: 14, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Manual Mode',
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Image canvas overlay
          Expanded(
            flex: 4,
            child: _image == null
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      _displayScale = _fitScale(_nativeImageSize, constraints.biggest);
                      _displayOffset = Offset(
                        (constraints.maxWidth - _nativeImageSize.width * _displayScale) / 2,
                        (constraints.maxHeight - _nativeImageSize.height * _displayScale) / 2,
                      );
                      
                      final fittedSize = Size(
                        _nativeImageSize.width * _displayScale,
                        _nativeImageSize.height * _displayScale,
                      );

                      return Center(
                        child: Container(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          color: const Color(0xFF0F0F11),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // 1. Raw image
                              Center(
                                child: SizedBox.fromSize(
                                  size: fittedSize,
                                  child: RawImage(
                                    image: _image,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                              
                              // 2. YOLO boxes (Auto mode)
                              if (_detectionMode == 'auto')
                                ..._detections.map((det) {
                                  final bbox = (det['bbox'] as List).cast<int>();
                                  final left = bbox[0] * _displayScale + _displayOffset.dx;
                                  final top = bbox[1] * _displayScale + _displayOffset.dy;
                                  final width = (bbox[2] - bbox[0]) * _displayScale;
                                  final height = (bbox[3] - bbox[1]) * _displayScale;

                                  final isSelected = _selectedBox != null &&
                                      _selectedBox![0] == bbox[0] &&
                                      _selectedBox![1] == bbox[1] &&
                                      _selectedBox![2] == bbox[2] &&
                                      _selectedBox![3] == bbox[3];

                                  return Positioned(
                                    left: left,
                                    top: top,
                                    width: width,
                                    height: height,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedBox = bbox;
                                        });
                                        _triggerSearch(searchBox: bbox);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.amber
                                                : Colors.white.withAlpha(120),
                                            width: isSelected ? 2.5 : 1.5,
                                          ),
                                          color: isSelected
                                              ? Colors.amber.withAlpha(30)
                                              : Colors.transparent,
                                        ),
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Positioned(
                                              top: -16,
                                              left: 0,
                                              child: Container(
                                                color: isSelected ? Colors.amber : Colors.black.withAlpha(180),
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                child: Text(
                                                  '${det['class_name']} (${((det['confidence'] as num) * 100).toStringAsFixed(0)}%)',
                                                  style: GoogleFonts.ibmPlexSans(
                                                    color: isSelected ? Colors.black : Colors.white,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              
                              // 3. Selection Rect & Crop painter (Manual Mode)
                              if (_detectionMode == 'manual')
                                Positioned.fill(
                                  child: GestureDetector(
                                    onPanStart: _onPanStart,
                                    onPanUpdate: _onPanUpdate,
                                    onPanEnd: _onPanEnd,
                                    child: CustomPaint(
                                      painter: _CropPainter(
                                        selectionRect: _selectionRect,
                                        imageRect: Rect.fromLTWH(
                                          _displayOffset.dx,
                                          _displayOffset.dy,
                                          fittedSize.width,
                                          fittedSize.height,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              
                              // 4. Instructions Overlay
                              Positioned(
                                bottom: 12,
                                left: 16,
                                right: 16,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(180),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _detectionMode == 'auto'
                                          ? 'Tap on a detected object to search'
                                          : 'Drag to draw custom area around the product',
                                      style: GoogleFonts.ibmPlexSans(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Results & controls container
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Aligned Threshold and Max Results sliders
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    child: Column(
                      children: [
                        // Threshold Row
                        Row(
                          children: [
                            SizedBox(
                              width: 85,
                              child: Text(
                                'Threshold',
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1C1B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Slider(
                                value: _scoreThreshold,
                                min: 0.0,
                                max: 1.0,
                                divisions: 20,
                                activeColor: AppTheme.primary,
                                label: _scoreThreshold.toStringAsFixed(2),
                                onChanged: (v) {
                                  setState(() {
                                    _scoreThreshold = v;
                                  });
                                },
                                onChangeEnd: (v) {
                                  _triggerSearch(searchBox: _selectedBox);
                                },
                              ),
                            ),
                            SizedBox(
                              width: 42,
                              child: Text(
                                _scoreThreshold.toStringAsFixed(2),
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ),
                          ],
                        ),
                        // Max Results Row
                        Row(
                          children: [
                            SizedBox(
                              width: 85,
                              child: Text(
                                'Max Results',
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1C1B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Slider(
                                value: _topK.toDouble(),
                                min: 1.0,
                                max: 10.0,
                                divisions: 9,
                                activeColor: AppTheme.primary,
                                label: _topK.toString(),
                                onChanged: (v) {
                                  setState(() {
                                    _topK = v.round();
                                  });
                                },
                                onChangeEnd: (v) {
                                  _triggerSearch(searchBox: _selectedBox);
                                },
                              ),
                            ),
                            SizedBox(
                              width: 42,
                              child: Text(
                                _topK.toString(),
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(),
                  
                  // Results list header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Search Matches (${_matchedItems.length})',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1C1B),
                          ),
                        ),
                        if (_selectedBox != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedBox = null;
                                _selectionRect = null;
                              });
                              _triggerSearch();
                            },
                            child: Text(
                              'Clear Crop',
                              style: GoogleFonts.ibmPlexSans(
                                color: AppTheme.outline,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Matches list
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _loadingMessage,
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 12,
                                    color: AppTheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _matchedItems.isEmpty
                            ? Center(
                                child: Text(
                                  'No matching products found',
                                  style: GoogleFonts.ibmPlexSans(
                                    color: AppTheme.outline,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemCount: _matchedItems.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final item = _matchedItems[index];
                                  final score = _productScores[int.tryParse(item.id) ?? -1];
                                  return InventoryItemCardWidget(
                                    item: item,
                                    onTap: () {
                                      // Close and select item
                                      Navigator.pop(context, {
                                        'productIds': _imageSearchProductIds,
                                        'scores': _imageSearchProductIds.map((id) => _productScores[id] ?? 0.0).toList(),
                                        'detections': _detections,
                                        'threshold': _scoreThreshold,
                                        'topK': _topK,
                                        'selectedProductId': int.tryParse(item.id),
                                      });
                                    },
                                    score: score,
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  final Rect? selectionRect;
  final Rect imageRect;

  _CropPainter({required this.selectionRect, required this.imageRect});

  @override
  void paint(Canvas canvas, Size size) {
    if (selectionRect == null) return;
    
    final overlayPaint = Paint()..color = Colors.black.withAlpha(120);

    // Draw overlay around selected rectangle
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, selectionRect!.top), overlayPaint);
    canvas.drawRect(Rect.fromLTRB(0, selectionRect!.bottom, size.width, size.height), overlayPaint);
    canvas.drawRect(Rect.fromLTRB(0, selectionRect!.top, selectionRect!.left, selectionRect!.bottom), overlayPaint);
    canvas.drawRect(Rect.fromLTRB(selectionRect!.right, selectionRect!.top, size.width, selectionRect!.bottom), overlayPaint);

    // Bounding border
    final borderPaint = Paint()
      ..color = AppTheme.primaryLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRect(selectionRect!, borderPaint);

    // Handle corner circles
    final handlePaint = Paint()..color = Colors.white;
    const handleSize = 6.0;
    for (final corner in [
      selectionRect!.topLeft,
      selectionRect!.topRight,
      selectionRect!.bottomLeft,
      selectionRect!.bottomRight,
    ]) {
      canvas.drawCircle(corner, handleSize, handlePaint);
    }
  }

  @override
  bool shouldRepaint(_CropPainter oldDelegate) =>
      oldDelegate.selectionRect != selectionRect;
}
