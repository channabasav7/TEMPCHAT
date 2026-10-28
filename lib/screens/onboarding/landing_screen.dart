import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../widgets/custom_qr_painter.dart';
import '../navigation/main_navigation_shell.dart';
import '../qr/scan_qr_screen.dart';
import 'username_setup_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final borderColor = Theme.of(context).dividerColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: textColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'TempChat',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainNavigationShell(initialIndex: 0),
                  ),
                );
              },
              child: Text(
                'Open app',
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 14, color: AppColors.primaryOrange),
                    const SizedBox(width: 8),
                    Text(
                      'No phone. No email. No trace.',
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Hero Title
              Text(
                'Say it.',
                style: TextStyle(
                  color: textColor,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              Text(
                'Then let it go.',
                style: TextStyle(
                  color: AppColors.primaryOrange,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 20),

              // Subtitle
              Text(
                'TempChat is private messaging for moments, not archives. Pick a username, share your QR, and every message quietly burns away on your timer.',
                style: TextStyle(
                  color: mutedColor,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              // Action Buttons Row
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UsernameSetupScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Get a username',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScanQrScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: cardColor,
                      foregroundColor: textColor,
                      side: BorderSide(color: borderColor),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    ),
                    child: const Text(
                      'Scan a QR',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Step indicators
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStepItem(
                      context,
                      '1',
                      'Get username',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UsernameSetupScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildStepItem(
                      context,
                      '2',
                      'Get QR',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MainNavigationShell(initialIndex: 1),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildStepItem(
                      context,
                      '3',
                      'Scan',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ScanQrScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildStepItem(
                      context,
                      '4',
                      'Chat',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MainNavigationShell(initialIndex: 0),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // QR Card Preview
              Builder(
                builder: (context) {
                  final appState = AppStateScope.of(context);
                  final payload = appState.hostingPayload;
                  return QrDisplayCard(
                    username: appState.username,
                    qrData: payload?.toEncodedString() ?? 'tempchat://demo_landing',
                    burnText: 'burns in 15:00',
                    fingerprint: payload?.safetyFingerprint,
                    size: 200,
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(BuildContext context, String number, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}