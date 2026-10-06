import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';
import '../navigation/main_navigation_shell.dart';

class UsernameSetupScreen extends StatefulWidget {
  const UsernameSetupScreen({super.key});

  @override
  State<UsernameSetupScreen> createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends State<UsernameSetupScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _pool = [
    'quiet_fox42',
    'ghost_runner',
    'neon_drifter',
    'cipher_echo',
    'shadow_pulse',
    'silent_hawk',
    'zero_trace',
    'matrix_nomad',
    'cryptic_owl',
    'amber_spark',
  ];

  final List<String> _timerOptions = [
    '5 minutes',
    '15 minutes',
    '1 hour',
    '24 hours',
  ];

  late String _selectedTimer;

  @override
  void initState() {
    super.initState();
    _controller.text = _pool[Random().nextInt(_pool.length)];
    _selectedTimer = '15 minutes';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generateRandom() {
    final next = _pool[Random().nextInt(_pool.length)];
    setState(() {
      _controller.text = '$next${Random().nextInt(90) + 10}';
    });
  }

  void _confirmAndProceed() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;

    final appState = AppStateScope.of(context);
    appState.setUsername(raw);
    appState.setDefaultTimer(_selectedTimer);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const MainNavigationShell(initialIndex: 0),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = _controller.text.trim().isNotEmpty
        ? _controller.text.trim()[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EPHEMERAL IDENTITY',
                style: TextStyle(
                  color: AppColors.primaryOrange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pick your alias.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'No email, no phone, no identity attached. Generate a random pseudonym or customize your disposable handle.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Avatar preview card
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryOrange,
                              width: 2,
                            ),
                          ),
                        ),
                        Container(
                          width: 74,
                          height: 74,
                          decoration: const BoxDecoration(
                            color: AppColors.cardBg,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '@${_controller.text.trim().replaceAll('@', '')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Username input field
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderDark),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Text(
                      '@',
                      style: TextStyle(
                        color: AppColors.primaryOrange,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'handle',
                          hintStyle: TextStyle(color: AppColors.textDim),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Random handle',
                      icon: const Icon(
                        Icons.casino_outlined,
                        color: AppColors.primaryOrange,
                      ),
                      onPressed: _generateRandom,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Burn timer preference selection
              const Text(
                'DEFAULT MESSAGE BURN TIMER',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timerOptions.map((opt) {
                  final isSel = _selectedTimer == opt;
                  return ChoiceChip(
                    label: Text(opt),
                    selected: isSel,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedTimer = opt);
                    },
                    selectedColor: AppColors.primaryOrange,
                    backgroundColor: AppColors.cardBg,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : AppColors.textMuted,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: isSel
                          ? AppColors.primaryOrange
                          : AppColors.borderDark,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

              // Launch button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirmAndProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Start Private Session',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
