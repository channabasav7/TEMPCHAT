import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/network/peer_connection_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/chat_conversation.dart';
import '../../models/chat_message.dart';
import '../../state/app_state.dart';
import '../../widgets/burn_countdown_badge.dart';
import '../navigation/main_navigation_shell.dart';

class ChatThreadScreen extends StatefulWidget {
  final String conversationId;

  const ChatThreadScreen({
    super.key,
    required this.conversationId,
  });

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    AppStateScope.of(context).sendMessage(widget.conversationId, text);
    _textController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Attachment picker bottom sheet ──────────────────────────────────────
  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _attachOption(
                icon: Icons.photo_library_outlined,
                label: 'Photo from Gallery',
                color: const Color(0xFF3B82F6),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              _attachOption(
                icon: Icons.camera_alt_outlined,
                label: 'Take Photo',
                color: AppColors.primaryOrange,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              _attachOption(
                icon: Icons.insert_drive_file_outlined,
                label: 'Send a File',
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        AppStateScope.of(context).sendAttachment(
          widget.conversationId,
          picked.path,
          MessageType.image,
        );
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: false,
      );
      if (result != null &&
          result.files.isNotEmpty &&
          result.files.single.path != null &&
          mounted) {
        AppStateScope.of(context).sendAttachment(
          widget.conversationId,
          result.files.single.path!,
          MessageType.file,
        );
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick file: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  // ── Encryption verification sheet ───────────────────────────────────────
  void _showEncryptionVerification(ChatConversation conv) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: AppColors.accentGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'End-to-End Encrypted',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Direct optical cipher with ${conv.username}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Safety Fingerprint
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SAFETY FINGERPRINT (SHA-256)',
                    style: TextStyle(
                      color: AppColors.primaryOrange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    conv.safetyFingerprint,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Compare this fingerprint with your peer to verify zero interception.',
                    style: TextStyle(color: AppColors.dim, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Cipher Specs
            Row(
              children: [
                _buildSpecPill('Cipher', 'AES-256-CBC'),
                const SizedBox(width: 8),
                _buildSpecPill('Key Exchange', 'Optical QR'),
                const SizedBox(width: 8),
                _buildSpecPill('Burn Timer', conv.burnTimer),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecPill(String title, String val) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(color: AppColors.dim, fontSize: 10),
            ),
            const SizedBox(height: 2),
            Text(
              val,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _burnAllNow(ChatConversation conv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.local_fire_department_rounded, color: AppColors.accentRed),
            SizedBox(width: 8),
            Text('Burn Entire Chat?', style: TextStyle(color: AppColors.text, fontSize: 18)),
          ],
        ),
        content: const Text(
          'All messages will be immediately obliterated from device memory and the peer connection closed.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              AppStateScope.of(context).burnAllMessages(widget.conversationId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chat burned completely.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Burn Now'),
          ),
        ],
      ),
    );
  }

  // ── Message bubble ───────────────────────────────────────────────────────
  Widget _buildMessageBubble(ChatMessage msg) {
    final isUrgent = msg.remainingTime.inSeconds < 60;
    final isMine = msg.isMine;

    Widget content;
    final hasImage = msg.type == MessageType.image &&
        (msg.attachmentBytes != null || msg.attachmentPath != null);
    final hasFile = msg.type == MessageType.file &&
        (msg.attachmentBytes != null || msg.attachmentPath != null);

    if (hasImage) {
      Widget imageWidget;
      if (msg.attachmentBytes != null && msg.attachmentBytes!.isNotEmpty) {
        imageWidget = Image.memory(
          Uint8List.fromList(msg.attachmentBytes!),
          width: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: AppColors.muted,
          ),
        );
      } else {
        imageWidget = Image.file(
          File(msg.attachmentPath!),
          width: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: AppColors.muted,
          ),
        );
      }

      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageWidget,
          ),
          const SizedBox(height: 6),
          BurnCountdownBadge(text: msg.remainingFormatted, isUrgent: isUrgent),
        ],
      );
    } else if (hasFile) {
      final fileName = msg.fileName ??
          (msg.attachmentPath != null
              ? msg.attachmentPath!.split('/').last.split('\\').last
              : 'Encrypted Document');
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insert_drive_file_outlined,
                size: 28,
                color: isMine ? Colors.white : AppColors.primaryOrange,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  fileName,
                  style: TextStyle(
                    color: isMine ? Colors.white : AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          BurnCountdownBadge(text: msg.remainingFormatted, isUrgent: isUrgent),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            msg.text,
            style: TextStyle(
              color: isMine ? Colors.white : AppColors.text,
              fontSize: 14,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              BurnCountdownBadge(text: msg.remainingFormatted, isUrgent: isUrgent),
            ],
          ),
        ],
      );
    }

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primaryOrange : AppColors.cardLight,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: Border.all(
            color: isMine ? Colors.transparent : AppColors.border,
          ),
        ),
        child: content,
      ),
    );
  }

  // ── 1-to-1 Peer Connection Status Bar ───────────────────────────────────
  Widget _buildConnectionStatusBar(PeerConnectionState peerState, ChatConversation conv) {
    final bool isLive = conv.isLiveConnected &&
        (peerState == PeerConnectionState.connected ||
            peerState == PeerConnectionState.hosting);

    late final Color barColor;
    late final Color dotColor;
    late final IconData statusIcon;
    late final String statusLabel;

    switch (peerState) {
      case PeerConnectionState.connected:
        barColor = AppColors.accentGreen.withValues(alpha: 0.08);
        dotColor = AppColors.accentGreen;
        statusIcon = Icons.wifi_rounded;
        statusLabel = 'Live 1-to-1 encrypted — ${conv.username} is connected';
        break;
      case PeerConnectionState.hosting:
        barColor = AppColors.primaryOrange.withValues(alpha: 0.08);
        dotColor = AppColors.primaryOrange;
        statusIcon = Icons.wifi_tethering_rounded;
        statusLabel = isLive
            ? 'Hosting session — peer linked'
            : 'Hosting — waiting for ${conv.username} to join';
        break;
      case PeerConnectionState.connecting:
        barColor = AppColors.primaryOrange.withValues(alpha: 0.06);
        dotColor = AppColors.primaryOrange;
        statusIcon = Icons.sync_rounded;
        statusLabel = 'Establishing encrypted channel…';
        break;
      case PeerConnectionState.disconnected:
      case PeerConnectionState.error:
        barColor = AppColors.accentRed.withValues(alpha: 0.07);
        dotColor = AppColors.accentRed;
        statusIcon = Icons.wifi_off_rounded;
        statusLabel = 'Peer disconnected — messages stored locally';
        break;
      case PeerConnectionState.idle:
        barColor = AppColors.cardLight.withValues(alpha: 0.5);
        dotColor = AppColors.dim;
        statusIcon = Icons.radio_button_unchecked;
        statusLabel = 'No active peer link — scan QR to connect';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      color: barColor,
      child: Row(
        children: [
          // Animated pulsing dot for live states
          if (peerState == PeerConnectionState.connected ||
              peerState == PeerConnectionState.hosting)
            _PulsingDot(color: dotColor)
          else
            Icon(statusIcon, size: 11, color: dotColor),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              statusLabel,
              style: TextStyle(
                color: dotColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (peerState == PeerConnectionState.connected)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(Icons.lock_rounded, size: 11, color: dotColor),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final conv = appState.getConversationById(widget.conversationId);

    if (conv == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(title: const Text('Chat not found')),
        body: const Center(
          child: Text(
            'This chat has already expired.',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }

    final activeMessages = conv.messages.where((m) => !m.isBurned).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainNavigationShell(initialIndex: 0),
                ),
              );
            }
          },
        ),
        titleSpacing: 0,
        title: InkWell(
          onTap: () => _showEncryptionVerification(conv),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.cardLight,
                      child: Text(
                        conv.avatarInitial,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (conv.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.bg, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              conv.username,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.lock_rounded, size: 13, color: AppColors.accentGreen),
                        ],
                      ),
                      Text(
                        'Burns after ${conv.burnTimer}',
                        style: const TextStyle(
                          color: AppColors.dim,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'View encryption & fingerprint',
            icon: const Icon(Icons.shield_outlined, color: AppColors.accentGreen),
            onPressed: () => _showEncryptionVerification(conv),
          ),
          IconButton(
            tooltip: 'Burn all messages now',
            icon: const Icon(Icons.local_fire_department_outlined, color: AppColors.accentRed),
            onPressed: () => _burnAllNow(conv),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Encryption notice banner
            InkWell(
              onTap: () => _showEncryptionVerification(conv),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.accentGreen.withValues(alpha: 0.08),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 12, color: AppColors.accentGreen),
                    SizedBox(width: 6),
                    Text(
                      'AES-256 Verified • Tap to view safety fingerprint',
                      style: TextStyle(
                        color: AppColors.accentGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 1-to-1 Peer Connection Status Bar ──────────────────────────
            _buildConnectionStatusBar(appState.peerConnectionState, conv),


            // Messages list
            Expanded(
              child: activeMessages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: AppColors.cardLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.local_fire_department_rounded,
                              size: 32,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'All messages burned',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Send an encrypted message to chat securely.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      itemCount: activeMessages.length,
                      itemBuilder: (context, index) =>
                          _buildMessageBubble(activeMessages[index]),
                    ),
            ),

            // Input bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  // Attach button
                  IconButton(
                    tooltip: 'Send image or file',
                    icon: const Icon(Icons.attach_file_rounded,
                        color: AppColors.muted, size: 22),
                    onPressed: _showAttachmentPicker,
                  ),

                  // Text field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardLight,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Type an encrypted message...',
                          hintStyle: TextStyle(
                              color: AppColors.dim, fontSize: 13),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward_rounded,
                          color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small animated pulsing dot to indicate a live P2P connection.
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: _anim.value),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _anim.value * 0.6),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
