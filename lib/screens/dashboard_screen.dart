import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/auth_service.dart';
import '../services/library_repository.dart';
import '../services/firestore_seeder.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_badge.dart';
import 'return_receipt_screen.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onNavigateToScanner;
  final VoidCallback onNavigateToTransit;

  const DashboardScreen({
    super.key,
    required this.onNavigateToScanner,
    required this.onNavigateToTransit,
  });

  @override
  Widget build(BuildContext context) {
    final repo = LibraryRepository();

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final recentLoans = repo.loans.take(5).toList();

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_stories, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'BranchFlow',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
                ),
              ],
            ),
            actions: [
              // Role Toggle Chip
              Container(
                margin: const EdgeInsets.only(right: 14),
                child: ChoiceChip(
                  label: Text(
                    repo.currentRole == UserRole.librarian ? 'Staff Mode' : 'Member Mode',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: repo.currentRole == UserRole.librarian
                          ? AppColors.primary
                          : AppColors.accent,
                    ),
                  ),
                  avatar: Icon(
                    repo.currentRole == UserRole.librarian
                        ? Icons.admin_panel_settings_outlined
                        : Icons.person_outline,
                    size: 16,
                    color: repo.currentRole == UserRole.librarian
                        ? AppColors.primary
                        : AppColors.accent,
                  ),
                  selected: true,
                  selectedColor: repo.currentRole == UserRole.librarian
                      ? const Color(0xFFEEF2FF)
                      : AppColors.accentSoft,
                  onSelected: (_) {
                    repo.setRole(
                      repo.currentRole == UserRole.librarian
                          ? UserRole.member
                          : UserRole.librarian,
                    );
                  },
                ),
              ),
              IconButton(
                tooltip: 'Sync / Seed Live Cloud Data',
                icon: const Icon(Icons.cloud_upload_outlined, size: 20, color: AppColors.primary),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 12),
                          Text('Checking Firebase connection and seeding...'),
                        ],
                      ),
                      duration: Duration(seconds: 1),
                    ),
                  );

                  final res = await FirestoreSeeder.seedInitialData();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(res.message),
                      backgroundColor: res.success ? AppColors.success : AppColors.danger,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Sign Out / Switch Account',
                icon: const Icon(Icons.logout_rounded, size: 20, color: AppColors.textSecondary),
                onPressed: () async {
                  await AuthService().signOut();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Problem Statement Solution Spotlight Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ZERO CATALOG SILOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.sync_problem, color: Colors.white70, size: 18),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Instant Cross-Branch Clearance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'When books are returned to any branch, borrowing records are instantly cleared, freezing unfair penalties and queuing courier transit.',
                        style: TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onPressed: onNavigateToScanner,
                            icon: const Icon(Icons.qr_code_scanner, size: 18),
                            label: const Text('Return Desk / Scan'),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white38),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onPressed: onNavigateToTransit,
                            icon: const Icon(Icons.local_shipping_outlined, size: 18),
                            label: const Text('Transit Hub'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Key Metric Cards
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'ACTIVE LOANS',
                        value: '${repo.activeLoansCount}',
                        subtitle: 'Across 4 branches',
                        icon: Icons.book_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'CROSS RETURNS',
                        value: '${repo.crossBranchReturnsCount}',
                        subtitle: 'Zero delay clearance',
                        icon: Icons.swap_horiz_rounded,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'IN COURIER TRANSIT',
                        value: '${repo.transitCount}',
                        subtitle: 'Returning to home',
                        icon: Icons.local_shipping_outlined,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'PENALTIES SAVED',
                        value: '\$${repo.totalPenaltiesSaved.toStringAsFixed(0)}',
                        subtitle: 'False holds prevented',
                        icon: Icons.shield_outlined,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Connected Library Branches
                const Text(
                  'Connected Network Branches',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                ...repo.branches.map((b) {
                  final isCurrentActive = b.id == repo.activeBranchId;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCurrentActive ? AppColors.primaryLight : AppColors.border,
                        width: isCurrentActive ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isCurrentActive ? const Color(0xFFEEF2FF) : AppColors.divider,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.account_balance_outlined,
                            size: 20,
                            color: isCurrentActive ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${b.code} · ${b.address}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isCurrentActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Active Desk',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 20),

                // Real-time Activity Ledger
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Live Synchronization Ledger',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${repo.loans.length} events',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                ...recentLoans.map((loan) {
                  final homeBranch = repo.getBranchById(loan.borrowedFromBranchId);
                  final returnBranch = repo.getBranchById(loan.returnedToBranchId ?? '');

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: loan.isReturned ? AppColors.successLight : AppColors.infoLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          loan.isReturned ? Icons.assignment_turned_in : Icons.assignment_outlined,
                          color: loan.isReturned ? AppColors.success : AppColors.info,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        loan.bookTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            loan.isReturned
                                ? 'Returned at ${returnBranch?.code ?? "Branch"} · Verified'
                                : 'Borrowed from ${homeBranch?.code ?? "Branch"}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          if (loan.penaltyAvoided > 0)
                            Text(
                              '🛡️ \$${loan.penaltyAvoided.toStringAsFixed(2)} fine prevented',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                        ],
                      ),
                      trailing: loan.isReturned
                          ? IconButton(
                              icon: const Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
                              tooltip: 'View Official Return Receipt',
                              onPressed: () => ReturnReceiptScreen.show(context, loan),
                            )
                          : StatusBadge.warning('Due soon'),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
