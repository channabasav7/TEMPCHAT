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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Disconnect ${conn.username}?',
          style: const TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This will immediately revoke their access to your ephemeral channel.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.muted)),
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

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final connections = appState.connections;

    return SafeArea(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PEER MESH',
              style: TextStyle(
                color: AppColors.primaryOrange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Connections',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Active ephemeral peers established via QR handshake. Links dissolve automatically.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: connections.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 36),
                      child: Center(
                        child: Text(
                          'No active connections.\nScan a QR to connect with someone.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.muted, fontSize: 14),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: connections.length,
                      separatorBuilder: (context, index) =>
                          const Divider(color: AppColors.border, height: 1),
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
                                    backgroundColor: AppColors.cardLight,
                                    child: Text(
                                      conn.avatarInitial,
                                      style: const TextStyle(
                                        color: AppColors.text,
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
                                          color: AppColors.accentGreen,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: AppColors.card,
                                              width: 2),
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
                                      style: const TextStyle(
                                        color: AppColors.text,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      conn.formattedRemaining,
                                      style: const TextStyle(
                                        color: AppColors.dim,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              IconButton(
                                tooltip: 'Chat',
                                icon: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: AppColors.primaryOrange,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    _openChatWithConnection(context, conn),
                              ),
                              IconButton(
                                tooltip: 'Revoke connection',
                                icon: const Icon(
                                  Icons.link_off_rounded,
                                  color: AppColors.muted,
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
