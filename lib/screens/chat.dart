import 'package:flutter/material.dart';
import 'chat/chat_list_screen.dart';
import 'navigation/main_navigation_shell.dart';

export 'chat/chat_list_screen.dart';
export 'chat/chat_thread_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainNavigationShell(initialIndex: 0);
  }
}

typedef ChatContent = ChatListScreen;
