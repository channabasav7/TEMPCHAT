import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/theme/app_theme.dart';

class CornerBracketsPainter extends CustomPainter {
  final Color color;
  final double cornerLength;
  final double strokeWidth;

  const CornerBracketsPainter({
    required this.color,
    this.cornerLength = 20.0,
    this.strokeWidth = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLength)
        ..lineTo(0, 0)
        ..lineTo(cornerLength, 0),
      paint,
    );

    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, cornerLength),
      paint,
    );

    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerLength)
        ..lineTo(0, size.height)
        ..lineTo(cornerLength, size.height),
      paint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CornerBracketsPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.cornerLength != cornerLength ||
      oldDelegate.strokeWidth != strokeWidth;
}

class QrDisplayCard extends StatelessWidget {
  final String username;
  final String qrData;
  final String burnText;
  final String? fingerprint;
  final double size;

  const QrDisplayCard({
    super.key,
    required this.username,
    required this.qrData,
    this.burnText = 'burns in 15:00',
    this.fingerprint,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  burnText,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Real Functional QR Code with Corner Brackets
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: size + 36,
                  height: size + 36,
                  child: const CustomPaint(
                    painter: CornerBracketsPainter(
                      color: AppColors.primaryOrange,
                      cornerLength: 24,
                      strokeWidth: 3.5,
                    ),
                  ),
                ),
                Container(
                  width: size,
                  height: size,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: qrData.isNotEmpty ? qrData : 'tempchat://placeholder',
                    version: QrVersions.auto,
                    size: size - 24,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (fingerprint != null && fingerprint!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.darkBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_user_outlined, size: 13, color: AppColors.accentGreen),
                  const SizedBox(width: 6),
                  Text(
                    'AES-256: $fingerprint',
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
