import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/chat_conversation.dart';
import '../../state/app_state.dart';
import 'chat_thread_screen.dart';

class ChatListScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;

  const ChatListScreen({super.key, this.onNavigateToTab});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Color get _cardColor => Theme.of(context).cardColor;
  Color get _cardLightColor => _cardColor.withValues(alpha: 0.8);
  Color get _borderColor => Theme.of(context).dividerColor;
  Color get _textColor => Theme.of(context).colorScheme.onSurface;
  Color get _mutedColor => Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
  Color get _dimColor => Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);
  Color get _primaryOrange => AppColors.primaryOrange;
  Color get _accentGreen => AppColors.accentGreen;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openNewChatDialog() {
    final handleController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Start Temporary Chat',
          style: TextStyle(
              color: _textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter handle to connect anonymously:',
              style: TextStyle(color: _mutedColor, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: _cardLightColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: handleController,
                style: TextStyle(color: _textColor, fontSize: 14),
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '@username',
                  hintStyle: TextStyle(color: _dimColor),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Cancel', style: TextStyle(color: _mutedColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryOrange,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final raw = handleController.text.trim();
              if (raw.isNotEmpty) {
                final appState = AppStateScope.of(context);
                final conv = appState.addOrGetConversation(raw);
                Navigator.pop(ctx);
                _openThread(conv);
              }
            },
            child: const Text('Chat'),
          ),
        ],
      ),
    );
  }

  void _openThread(ChatConversation conv) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatThreadScreen(conversationId: conv.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final userAlias = appState.username.toUpperCase();

    final filteredConversations =
        appState.conversations.where((conv) {
      if (_searchQuery.isEmpty) return true;
      return conv.username.toLowerCase().contains(_searchQuery) ||
          conv.lastMessageText.toLowerCase().contains(_searchQuery);
    }).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HI, $userAlias',
              style: TextStyle(
                color: _primaryOrange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Chats',
              style: TextStyle(
                color: _textColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Everything here is temporary. Messages burn on each chat's timer.",
              style: TextStyle(
                color: _mutedColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // New Chat Button
            ElevatedButton.icon(
              onPressed: _openNewChatDialog,
              icon: const Icon(Icons.add_box_outlined, size: 18),
              label: const Text(
                'New chat',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryOrange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick action cards
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickActionCard(
                    icon: Icons.qr_code_2_outlined,
                    label: 'Show my QR',
                    onTap: () => widget.onNavigateToTab?.call(1),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickActionCard(
                    icon: Icons.qr_code_scanner_outlined,
                    label: 'Scan a QR',
                    onTap: () => widget.onNavigateToTab?.call(2),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickActionCard(
                    icon: Icons.people_outline,
                    label: 'Connections',
                    onTap: () => widget.onNavigateToTab?.call(3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Search bar
            Container(
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _borderColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                    color: _textColor, fontSize: 14),
                decoration: InputDecoration(
                  icon: Icon(Icons.search,
                      color: _mutedColor, size: 20),
                  hintText: 'Search chats',
                  hintStyle: TextStyle(
                      color: _mutedColor, fontSize: 14),
                  border: InputBorder.none,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              color: _dimColor, size: 18),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Chat list
            Container(
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderColor),
              ),
              child: filteredConversations.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Center(
                        child: Text(
                          'No conversations found',
                          style: TextStyle(
                              color: _mutedColor, fontSize: 14),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredConversations.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: _borderColor, height: 1),
                      itemBuilder: (context, index) {
                        final item = filteredConversations[index];
                        return _buildChatItem(
                          conversation: item,
                          onTap: () => _openThread(item),
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

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 125,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _primaryOrange, size: 22),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                color: _textColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem({
    required ChatConversation conversation,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _cardLightColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      conversation.avatarInitial,
                      style: TextStyle(
                        color: _textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                if (conversation.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: _accentGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: _cardColor, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.username,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Burns after ${conversation.burnTimer}',
                    style: TextStyle(
                      color: _mutedColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Time & Unread Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  conversation.lastMessageTime.isNotEmpty
                      ? conversation.lastMessageTime
                      : conversation.burnTimer.split(' ').first,
                  style: TextStyle(
                    color: _mutedColor,
                    fontSize: 12,
                  ),
                ),
                if (conversation.unreadCount > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _primaryOrange,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${conversation.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
