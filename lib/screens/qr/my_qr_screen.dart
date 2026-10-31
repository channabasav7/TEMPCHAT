import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../widgets/custom_qr_painter.dart';

class MyQrScreen extends StatefulWidget {
  const MyQrScreen({super.key});

  @override
  State<MyQrScreen> createState() => _MyQrScreenState();
}

class _MyQrScreenState extends State<MyQrScreen> {
  bool _isRegenerating = false;

  Future<void> _regenerateQr() async {
    setState(() => _isRegenerating = true);
    final appState = AppStateScope.of(context);
    await appState.refreshHostingPayload();
    if (mounted) {
      setState(() => _isRegenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generated fresh AES-256 key and disposable QR code.'),
          backgroundColor: AppColors.card,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyPayload(String payloadString) {
    Clipboard.setData(ClipboardData(text: payloadString));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied encrypted session payload to clipboard!'),
        backgroundColor: AppColors.card,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Color get _cardColor => Theme.of(context).cardColor;
  Color get _borderColor => Theme.of(context).dividerColor;
  Color get _textColor => Theme.of(context).colorScheme.onSurface;
  Color get _mutedColor =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final payload = appState.hostingPayload;
    final encodedPayload = payload?.toEncodedString() ?? '';
    final fingerprint = payload?.safetyFingerprint ?? '';
    final remaining = payload?.remainingLifetime ?? Duration.zero;
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final lifetimeText = payload == null
        ? 'No active session'
        : payload.isExpired
        ? 'Expired - generate a new QR'
        : 'Expires in ${minutes.toString().padLeft(2, '0')}:$seconds';

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OPTICAL ENCRYPTED KEY',
                  style: TextStyle(
                    color: AppColors.primaryOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'My QR',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Scan this code to exchange the 256-bit AES encryption key physically from screen to camera. No server ever sees this key.',
                  style: TextStyle(
                    color: _mutedColor,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Functional Unique QR Display Card
                QrDisplayCard(
                  username: appState.username,
                  qrData: encodedPayload,
                  burnText: 'burns in ${appState.selectedTimer}',
                  fingerprint: fingerprint,
                  sessionId: payload?.sessionId,
                  size: 280,
                  diagnosticsText: payload == null
                      ? null
                      : '${encodedPayload.length} characters  |  $lifetimeText',
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isRegenerating ? null : _regenerateQr,
                        icon: _isRegenerating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('New Key & QR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _cardColor,
                          foregroundColor: _textColor,
                          side: BorderSide(color: _borderColor),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _copyPayload(encodedPayload),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copy Key'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primaryOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'For reliable scanning, keep the full QR visible at 100% browser zoom. '
                          'If the camera cannot read it, use Copy Key and paste the tempchat:// payload on the other device.',
                          style: TextStyle(
                            color: _mutedColor,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Security Specifications Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                    children: [
                      _buildSecurityRow(
                        icon: Icons.vpn_key_outlined,
                        title: 'Out-of-Band Key Exchange (OOB)',
                        subtitle:
                            'The AES-256 session key is transferred optically via light photons from screen to camera. Immune to remote MITM attacks.',
                      ),
                      Divider(color: _borderColor, height: 24),
                      _buildSecurityRow(
                        icon: Icons.lock_outline,
                        title: 'End-to-End Cryptography',
                        subtitle:
                            'Every single message is encrypted client-side with a fresh random IV. Relay nodes only see encrypted ciphertext.',
                      ),
                      Divider(color: _borderColor, height: 24),
                      _buildSecurityRow(
                        icon: Icons.local_fire_department_outlined,
                        title: 'Volatile Ephemeral RAM Storage',
                        subtitle:
                            'No database, disk storage, or cloud backups. When the timer expires, messages are zeroized in device memory.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(color: _mutedColor, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
