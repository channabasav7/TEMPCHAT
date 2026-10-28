import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/connection.dart';
import '../../state/app_state.dart';
import '../chat/chat_thread_screen.dart';

class ConnectionsScreen extends StatelessWidget {
  const ConnectionsScreen({super.key});

  void _openChatWithConnection(BuildContext context, ConnectionItem conn) {
    final appState = AppStateScope.of(context);
    final chat = appState.addOrGetConversation(conn.username);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatThreadScreen(conversationId: chat.id),
      ),
    );
  }

  void _terminateConnection(BuildContext context, ConnectionItem conn) {
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Disconnect ${conn.username}?',
          style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will immediately revoke their access to your ephemeral channel.',
          style: TextStyle(color: mutedColor, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: mutedColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              AppStateScope.of(context).removeConnection(conn.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Revoked connection with ${conn.username}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }

  Color get _primaryOrange => AppColors.primaryOrange;
  Color get _accentGreen => AppColors.accentGreen;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final connections = appState.connections;

    final cardColor = Theme.of(context).cardColor;
    final borderColor = Theme.of(context).dividerColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final dimColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);
    final cardLightColor = cardColor.withValues(alpha: 0.8);

    return SafeArea(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PEER MESH',
              style: TextStyle(
                color: _primaryOrange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Connections',
              style: TextStyle(
                color: textColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Active ephemeral peers established via QR handshake. Links dissolve automatically.',
              style: TextStyle(
                color: mutedColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: connections.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Center(
                        child: Text(
                          'No active connections.\nScan a QR to connect with someone.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: mutedColor, fontSize: 14),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: connections.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: borderColor, height: 1),
                      itemBuilder: (context, index) {
                        final conn = connections[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: cardLightColor,
                                    child: Text(
                                      conn.avatarInitial,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  if (conn.isOnline)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: _accentGreen,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: cardColor, width: 2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      conn.username,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      conn.formattedRemaining,
                                      style: TextStyle(
                                        color: dimColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              IconButton(
                                tooltip: 'Chat',
                                icon: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: _primaryOrange,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    _openChatWithConnection(context, conn),
                              ),
                              IconButton(
                                tooltip: 'Revoke connection',
                                icon: Icon(
                                  Icons.link_off_rounded,
                                  color: mutedColor,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    _terminateConnection(context, conn),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}