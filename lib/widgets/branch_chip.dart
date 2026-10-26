import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class BranchChip extends StatelessWidget {
  final String branchName;
  final String? branchCode;
  final bool isHome;
  final bool isCurrent;

  const BranchChip({
    super.key,
    required this.branchName,
    this.branchCode,
    this.isHome = false,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.background;
    Color border = AppColors.border;
    Color text = AppColors.textSecondary;
    IconData icon = Icons.location_on_outlined;

    if (isHome) {
      bg = const Color(0xFFEEF2FF);
      border = const Color(0xFFC7D2FE);
      text = AppColors.primary;
      icon = Icons.home_outlined;
    } else if (isCurrent) {
      bg = AppColors.accentSoft;
      border = AppColors.accentLight.withValues(alpha: 0.4);
      text = AppColors.accent;
      icon = Icons.place_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 4),
          Text(
            branchCode != null ? '$branchCode · $branchName' : branchName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}
