import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class BurnCountdownBadge extends StatelessWidget {
  final String text;
  final bool isUrgent;
  final VoidCallback? onTap;

  const BurnCountdownBadge({
    super.key,
    required this.text,
    this.isUrgent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isUrgent
        ? AppColors.accentRed.withValues(alpha: 0.15)
        : AppColors.primaryOrange.withValues(alpha: 0.12);
    final borderColor = isUrgent
        ? AppColors.accentRed.withValues(alpha: 0.4)
        : AppColors.primaryOrange.withValues(alpha: 0.3);
    final iconColor = isUrgent ? AppColors.accentRed : AppColors.primaryOrange;
    final textColor = isUrgent ? AppColors.accentRed : Colors.white70;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              size: 13,
              color: iconColor,
            ),
            const SizedBox(width: 5),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
