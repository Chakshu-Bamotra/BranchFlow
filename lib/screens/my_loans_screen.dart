import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../services/library_repository.dart';
import '../widgets/branch_chip.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/status_badge.dart';
import 'return_receipt_screen.dart';

class MyLoansScreen extends StatelessWidget {
  final VoidCallback onNavigateToScanner;

  const MyLoansScreen({super.key, required this.onNavigateToScanner});

  @override
  Widget build(BuildContext context) {
    final repo = LibraryRepository();
    final dateFormat = DateFormat('MMM d, yyyy');

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final activeLoans = repo.activeMemberLoans;
        final returnedLoans = repo.returnedMemberLoans;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('My Loans & Receipts'),
              bottom: TabBar(
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(text: 'Active (${activeLoans.length})'),
                  Tab(text: 'Return Receipts (${returnedLoans.length})'),
                ],
              ),
            ),
            body: Column(
              children: [
                // Member Card Header
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.accentLight.withValues(alpha: 0.2),
                        child: const Icon(Icons.person, color: AppColors.accentLight, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              repo.currentMemberName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Member ID: ${repo.currentMemberId} · All 4 Branches Access',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_outlined, color: AppColors.success, size: 14),
                            SizedBox(width: 4),
                            Text(
                              '0 Holds',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    children: [
                      // Active Loans Tab
                      activeLoans.isEmpty
                          ? EmptyStateCard(
                              title: 'No Active Loans',
                              message: 'You have returned all borrowed books. Browse the catalog to borrow new titles!',
                              icon: Icons.bookmark_border,
                              actionLabel: 'Browse Catalog',
                              onAction: onNavigateToScanner,
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: activeLoans.length,
                              itemBuilder: (context, idx) {
                                final loan = activeLoans[idx];
                                final homeBranch = repo.getBranchById(loan.borrowedFromBranchId);
                                final daysRemaining = loan.dueDate.difference(DateTime.now()).inDays;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                loan.bookTitle,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                            ),
                                            StatusBadge.warning(
                                              daysRemaining >= 0 ? '$daysRemaining days left' : 'Overdue',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text('Author: ${loan.bookAuthor}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            BranchChip(
                                              branchName: homeBranch?.name ?? 'Branch',
                                              branchCode: homeBranch?.code,
                                              isHome: true,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Due: ${dateFormat.format(loan.dueDate)}',
                                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            icon: const Icon(Icons.qr_code_scanner, size: 16),
                                            label: const Text('Return at Any Branch Now'),
                                            onPressed: onNavigateToScanner,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                      // Returned Loans & Official Proof of Return
                      returnedLoans.isEmpty
                          ? const EmptyStateCard(
                              title: 'No Return Receipts Yet',
                              message: 'When you drop off books at any branch, your official zero-liability receipts will appear here.',
                              icon: Icons.receipt_long_outlined,
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: returnedLoans.length,
                              itemBuilder: (context, idx) {
                                final loan = returnedLoans[idx];
                                final returnBranch = repo.getBranchById(loan.returnedToBranchId ?? '');

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                loan.bookTitle,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                            ),
                                            StatusBadge.success('Verified Return'),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Receipt Code: ${loan.returnReceiptCode ?? "BF-REC-VERIFIED"}',
                                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.primary),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            BranchChip(
                                              branchName: returnBranch?.name ?? 'Drop-off Branch',
                                              branchCode: returnBranch?.code,
                                              isCurrent: true,
                                            ),
                                            const SizedBox(width: 8),
                                            if (loan.isCrossBranchReturn)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.accentSoft,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'Cross-Branch Return',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.accent,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            icon: const Icon(Icons.verified, size: 16),
                                            label: const Text('View Official Return Certificate'),
                                            onPressed: () => ReturnReceiptScreen.show(context, loan),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
