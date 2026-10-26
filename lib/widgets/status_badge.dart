import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory StatusBadge.success(String label, {IconData? icon}) {
    return StatusBadge(
      label: label,
      backgroundColor: AppColors.successLight,
      textColor: AppColors.success,
      icon: icon ?? Icons.check_circle_outline,
    );
  }

  factory StatusBadge.warning(String label, {IconData? icon}) {
    return StatusBadge(
      label: label,
      backgroundColor: AppColors.warningLight,
      textColor: AppColors.warning,
      icon: icon ?? Icons.schedule,
    );
  }

  factory StatusBadge.danger(String label, {IconData? icon}) {
    return StatusBadge(
      label: label,
      backgroundColor: AppColors.dangerLight,
      textColor: AppColors.danger,
      icon: icon ?? Icons.error_outline,
    );
  }

  factory StatusBadge.info(String label, {IconData? icon}) {
    return StatusBadge(
      label: label,
      backgroundColor: AppColors.infoLight,
      textColor: AppColors.info,
      icon: icon ?? Icons.info_outline,
    );
  }

  factory StatusBadge.neutral(String label, {IconData? icon}) {
    return StatusBadge(
      label: label,
      backgroundColor: AppColors.divider,
      textColor: AppColors.textSecondary,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
