import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../models/qr_handshake_payload.dart';
import '../../state/app_state.dart';
import '../../widgets/custom_qr_painter.dart';
import '../chat/chat_thread_screen.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _scannerController;
  late AnimationController _animController;
  late Animation<double> _scanAnimation;

  bool _isProcessing = false;
  bool _cameraFailed = false;
  bool _torchEnabled = false;
  bool _hasPermission = false;
  bool _checkingPermission = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
        _checkingPermission = false;
      });
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );
    } else {
      setState(() {
        _hasPermission = false;
        _checkingPermission = false;
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _handleScannedString(String rawData) async {
    if (_isProcessing) return;
    _isProcessing = true;

    final payload = QrHandshakePayload.tryParse(rawData);
    if (payload == null) {
      _isProcessing = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid QR: Missing TempChat cryptographic payload.'),
            backgroundColor: AppColors.accentRed,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final appState = AppStateScope.of(context);
    final conv = await appState.connectToScannedPayload(payload);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_rounded, color: AppColors.accentGreen, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Connected to ${conv.username}! AES-256 active.')),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatThreadScreen(conversationId: conv.id),
        ),
      ).then((_) => _isProcessing = false);
    }
  }

  void _onPastePayloadDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_open_rounded,
                color: AppColors.primaryOrange, size: 20),
            SizedBox(width: 8),
            Text(
              'Paste Optical Payload',
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste the tempchat:// payload copied from another device:',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: controller,
                maxLines: 2,
                style: const TextStyle(color: AppColors.text, fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'tempchat://...',
                  hintStyle: TextStyle(color: AppColors.dim),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Or test with a simulated peer:',
              style: TextStyle(
                  color: AppColors.dim,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: ['@echo_agent', '@valkyrie_9', '@matrix_zero']
                  .map((peer) {
                return ActionChip(
                  label: Text(peer),
                  backgroundColor: AppColors.cardLight,
                  labelStyle: const TextStyle(
                      color: AppColors.primaryOrange, fontSize: 11),
                  side: const BorderSide(color: AppColors.border),
                  onPressed: () {
                    final simulatedPayload =
                        QrHandshakePayload.createFresh(
                      hostAlias: peer,
                      burnSeconds: 900,
                    );
                    controller.text = simulatedPayload.toEncodedString();
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final raw = controller.text.trim();
              if (raw.isNotEmpty) {
                Navigator.pop(ctx);
                _handleScannedString(raw);
              }
            },
            child: const Text('Connect & Decrypt'),
          ),
        ],
      ),
    );
  }

  void _simulateScanSuccess() {
    final simulated = QrHandshakePayload.createFresh(
      hostAlias: '@cipher_agent',
      burnSeconds: 900,
    );
    _handleScannedString(simulated.toEncodedString());
  }

  @override
  Widget build(BuildContext context) {
    const scanBoxSize = 250.0;

    if (_checkingPermission) {
      return const SafeArea(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryOrange),
        ),
      );
    }

    if (!_hasPermission) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined,
                  size: 64, color: AppColors.muted),
              const SizedBox(height: 24),
              const Text(
                'Camera access required',
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please enable camera permission in Settings to scan QR codes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 14),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                ),
                onPressed: () async {
                  await openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OPTICAL HANDSHAKE',
              style: TextStyle(
                color: AppColors.primaryOrange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Scan QR',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Point your camera at a TempChat QR code to exchange the 256-bit AES encryption key.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Camera viewfinder
            Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        const SizedBox(
                          width: scanBoxSize,
                          height: scanBoxSize,
                          child: CustomPaint(
                            painter: CornerBracketsPainter(
                              color: AppColors.primaryOrange,
                              cornerLength: 26,
                              strokeWidth: 3.5,
                            ),
                          ),
                        ),
                        Container(
                          width: scanBoxSize - 20,
                          height: scanBoxSize - 20,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (!_cameraFailed &&
                                  _scannerController != null)
                                MobileScanner(
                                  controller: _scannerController!,
                                  onDetect: (capture) {
                                    for (final barcode
                                        in capture.barcodes) {
                                      final raw = barcode.rawValue;
                                      if (raw != null && raw.isNotEmpty) {
                                        _handleScannedString(raw);
                                        break;
                                      }
                                    }
                                  },
                                  errorBuilder: (context, error) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (mounted && !_cameraFailed) {
                                        setState(
                                            () => _cameraFailed = true);
                                      }
                                    });
                                    return _buildViewfinderMock();
                                  },
                                )
                              else
                                _buildViewfinderMock(),

                              // Scan laser
                              AnimatedBuilder(
                                animation: _scanAnimation,
                                builder: (context, child) {
                                  return Positioned(
                                    top: (scanBoxSize - 24) *
                                        _scanAnimation.value,
                                    left: 8,
                                    right: 8,
                                    child: Container(
                                      height: 2,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryOrange,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primaryOrange
                                                .withValues(alpha: 0.8),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_scannerController != null)
                          IconButton(
                            tooltip: 'Toggle Flashlight',
                            icon: Icon(
                              _torchEnabled
                                  ? Icons.flash_on
                                  : Icons.flash_off,
                              color: _torchEnabled
                                  ? AppColors.primaryOrange
                                  : AppColors.muted,
                            ),
                            onPressed: () {
                              setState(
                                  () => _torchEnabled = !_torchEnabled);
                              _scannerController!.toggleTorch();
                            },
                          ),
                        const SizedBox(width: 14),
                        ElevatedButton.icon(
                          onPressed: _simulateScanSuccess,
                          icon: const Icon(Icons.qr_code_2, size: 16),
                          label: const Text('Test Scan',
                              style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cardLight,
                            foregroundColor: AppColors.text,
                            side: const BorderSide(color: AppColors.border),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Paste payload
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _onPastePayloadDialog,
                icon: const Icon(Icons.paste_rounded, size: 18),
                label: const Text(
                  'Paste Encrypted Session Payload',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.card,
                  foregroundColor: AppColors.text,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildViewfinderMock() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined,
                size: 40, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text(
              'Align QR in Frame',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
