import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'PREFERENCES',
              style: TextStyle(
                color: AppColors.primaryOrange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Settings',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // IDENTITY
            _buildSectionHeader('IDENTITY'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.cardLight,
                    child: Text(
                      appState.username.replaceAll('@', '').isNotEmpty
                          ? appState.username.replaceAll('@', '')[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.username,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Temporary disposable handle',
                          style: TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _editAliasDialog(context, appState),
                    child: const Text(
                      'Change',
                      style: TextStyle(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // MESSAGES
            _buildSectionHeader('MESSAGES'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Default timer',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'New chats start with this burn time.',
                          style: TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cardLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: appState.selectedTimer,
                        dropdownColor: AppColors.card,
                        icon: const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.muted,
                            size: 18,
                          ),
                        ),
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        onChanged: (String? val) {
                          if (val != null) appState.setDefaultTimer(val);
                        },
                        items: <String>[
                          '1 minute',
                          '5 minutes',
                          '15 minutes',
                          '1 hour',
                          '6 hours',
                          '24 hours',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // PRIVACY
            _buildSectionHeader('PRIVACY'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: 'Allow new chats',
                    subtitle: 'Let people who scan your QR start a chat.',
                    value: appState.allowNewChats,
                    onChanged: appState.setAllowNewChats,
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _buildSwitchTile(
                    title: 'QR visible',
                    subtitle: 'Show your QR code on your profile.',
                    value: appState.qrVisible,
                    onChanged: appState.setQrVisible,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // NOTIFICATIONS
            _buildSectionHeader('NOTIFICATIONS'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: 'Message alerts',
                    subtitle: 'Show an alert for new messages.',
                    value: appState.messageAlerts,
                    onChanged: appState.setMessageAlerts,
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _buildSwitchTile(
                    title: 'Sound',
                    subtitle: 'Play a soft chime.',
                    value: appState.sound,
                    onChanged: appState.setSound,
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _buildSwitchTile(
                    title: 'Browser notifications',
                    subtitle: 'Notify even when the tab is hidden.',
                    value: appState.browserNotifications,
                    onChanged: appState.setBrowserNotifications,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Wipe
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _wipeSessionDialog(context, appState),
                icon: const Icon(Icons.delete_forever_rounded,
                    color: AppColors.accentRed, size: 20),
                label: const Text(
                  'Nuke All Session Data',
                  style: TextStyle(
                      color: AppColors.accentRed,
                      fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.accentRed),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _editAliasDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController(text: appState.username);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Alias',
            style: TextStyle(color: AppColors.text, fontSize: 18)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.text),
          decoration: const InputDecoration(
            hintText: '@new_alias',
            hintStyle: TextStyle(color: AppColors.dim),
          ),
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
              if (controller.text.trim().isNotEmpty) {
                appState.setUsername(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _wipeSessionDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nuke All Data?',
            style: TextStyle(color: AppColors.accentRed, fontSize: 18)),
        content: const Text(
          'This will purge all chats, connections, and reset your identity immediately.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              for (final c in appState.conversations) {
                appState.burnAllMessages(c.id);
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All local session memory shredded.'),
                ),
              );
            },
            child: const Text('Nuke Data'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primaryOrange,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
