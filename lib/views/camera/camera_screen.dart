import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'widgets/camera_overlay.dart';
import '../review/review_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  FlashMode _currentFlashMode = FlashMode.off;
  Offset? _focusPoint;
  bool _showFocusIndicator = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() => _isCameraInitialized = false);
        }
        return;
      }

      // Chọn camera sau (back camera)
      final backCamera = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      await _controller!.setFlashMode(_currentFlashMode);

      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint('Lỗi khởi tạo camera: $e');
      if (mounted) {
        setState(() => _isCameraInitialized = false);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  /// Chạm để lấy nét (Tap-to-focus)
  Future<void> _onTapToFocus(TapDownDetails details, BoxConstraints constraints) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final Offset offset = details.localPosition;
    final double dx = offset.dx / constraints.maxWidth;
    final double dy = offset.dy / constraints.maxHeight;

    try {
      setState(() {
        _focusPoint = offset;
        _showFocusIndicator = true;
      });

      await _controller!.setFocusPoint(Offset(dx, dy));
      await _controller!.setExposurePoint(Offset(dx, dy));

      // Ẩn vòng tròn lấy nét sau 1.2 giây
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() => _showFocusIndicator = false);
        }
      });
    } catch (e) {
      debugPrint('Lỗi chạm lấy nét: $e');
    }
  }

  /// Bật / Tắt Flash
  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    FlashMode newMode;
    switch (_currentFlashMode) {
      case FlashMode.off:
        newMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        newMode = FlashMode.auto;
        break;
      case FlashMode.auto:
      default:
        newMode = FlashMode.off;
        break;
    }

    try {
      await _controller!.setFlashMode(newMode);
      setState(() => _currentFlashMode = newMode);
    } catch (e) {
      debugPrint('Lỗi thay đổi flash: $e');
    }
  }

  /// Chụp ảnh và chuyển sang màn hình Review Screen
  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

    try {
      setState(() => _isCapturing = true);

      final XFile photo = await _controller!.takePicture();

      if (!mounted) return;
      setState(() => _isCapturing = false);

      // Chuyển sang màn hình ReviewScreen để bóc tách OCR
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewScreen(imagePath: photo.path),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi chụp ảnh: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Tính toán khung căn chỉnh hóa đơn (chiếm 80% bề ngang, tỉ lệ 1.4:1)
    final cutoutWidth = size.width * 0.85;
    final cutoutHeight = cutoutWidth * 1.4;
    final cutoutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: cutoutWidth,
      height: cutoutHeight,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Viewfinder hoặc giao diện giả lập (Fallback)
          if (_isCameraInitialized && _controller != null)
            PositionExceptionHandlingView(
              controller: _controller!,
              onTap: (details, constraints) => _onTapToFocus(details, constraints),
            )
          else
            _buildNoCameraFallback(context),

          // 2. Lớp phủ viền bán trong suốt căn hóa đơn (Framing Overlay)
          CameraOverlay(cutoutRect: cutoutRect),

          // 3. Vòng tròn lấy nét tương tác (Focus indicator)
          if (_showFocusIndicator && _focusPoint != null)
            Positioned(
              left: _focusPoint!.dx - 30,
              top: _focusPoint!.dy - 30,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amberAccent, width: 2),
                  shape: BoxShape.circle,
                ),
              ),
            ),

          // 4. Header Bar (Nút quay lại, Flash Mode)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Text(
                  'Quét Hóa Đơn',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 4,
                      )
                    ],
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: Icon(
                      _currentFlashMode == FlashMode.off
                          ? Icons.flash_off
                          : _currentFlashMode == FlashMode.torch
                              ? Icons.flash_on
                              : Icons.flash_auto,
                      color: _currentFlashMode == FlashMode.off
                          ? Colors.white70
                          : Colors.amber,
                    ),
                    onPressed: _toggleFlash,
                  ),
                ),
              ],
            ),
          ),

          // 5. Dòng hướng dẫn căn lề
          Positioned(
            top: cutoutRect.bottom + 20,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Căn hóa đơn vừa khớp khung viền để nhận diện',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // 6. Thanh điều khiển phía dưới (Nút chụp ảnh)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: _isCapturing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : GestureDetector(
                      onTap: _takePicture,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: const Color(0xFF10B981),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 36),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCameraFallback(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 64),
          const SizedBox(height: 12),
          const Text(
            'Không tìm thấy Camera thực tế\n(Chế độ Emulator/Desktop)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.receipt_long),
            label: const Text('Thử nghiệm hóa đơn mẫu (Test Receipt)'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReviewScreen(imagePath: null),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class PositionExceptionHandlingView extends StatelessWidget {
  final CameraController controller;
  final Function(TapDownDetails, BoxConstraints) onTap;

  const PositionExceptionHandlingView({
    super.key,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (details) => onTap(details, constraints),
          child: SizedBox.expand(
            child: CameraPreview(controller),
          ),
        );
      },
    );
  }
}
