import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../services/auth_service.dart';
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
    final user = AuthService().currentUser;
    final dateFormat = DateFormat('MMM d, yyyy');

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final activeLoans = repo.activeMemberLoans;
        final returnedLoans = repo.returnedMemberLoans;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Account & Loans'),
              bottom: TabBar(
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(text: 'Active Books (${activeLoans.length})'),
                  Tab(text: 'Clearance Receipts (${returnedLoans.length})'),
                ],
              ),
            ),
            body: Column(
              children: [
                // Athenaeum Member Card Header
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        child: const Icon(Icons.person, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? repo.currentMemberName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Georgia',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Member ID: ${user?.uid ?? repo.currentMemberId} • All 4 Branches',
                              style: const TextStyle(color: Color(0xFFC7D7CD), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_outlined, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              '0 Holds',
                              style: TextStyle(
                                color: Colors.white,
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
                          ? Center(
                              child: EmptyStateCard(
                                title: 'No Active Borrowed Books',
                                message: 'Explore the unified catalog to borrow books from any branch.',
                                icon: Icons.book_outlined,
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              itemCount: activeLoans.length,
                              itemBuilder: (context, idx) {
                                final loan = activeLoans[idx];
                                final borrowBranch = repo.getBranchById(loan.borrowBranchId);
                                final isDueSoon = loan.isOverdue || loan.dueDaysRemaining <= 3;
                                final dueFormatted = DateFormat('MMM d').format(loan.dueDate);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppColors.cardBorder),
                                            ),
                                            child: const Center(
                                              child: Icon(Icons.menu_book, color: AppColors.primary, size: 22),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  loan.bookTitle,
                                                  style: const TextStyle(
                                                    fontSize: 14.5,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Georgia',
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${loan.bookAuthor} · Barcode: ${loan.barcode}',
                                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 6,
                                        children: [
                                          BranchChip(
                                            branchName: borrowBranch?.name ?? loan.borrowBranchId,
                                            isHome: true,
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isDueSoon ? AppColors.duePillAmberBg : AppColors.duePillGreenBg,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: isDueSoon ? const Color(0xFFFCD34D) : const Color(0xFFC7E6D0),
                                              ),
                                            ),
                                            child: Text(
                                              'Due $dueFormatted (${loan.dueDaysRemaining} days)',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isDueSoon ? AppColors.duePillAmberText : AppColors.duePillGreenText,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          icon: const Icon(Icons.qr_code_scanner, size: 16),
                                          label: const Text('Return via Drop-Box Scanner'),
                                          onPressed: onNavigateToScanner,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                      // Clearance Receipts Tab
                      returnedLoans.isEmpty
                          ? Center(
                              child: EmptyStateCard(
                                title: 'No Return Receipts Yet',
                                message: 'When you return a book, your zero-delay clearance receipt will appear here.',
                                icon: Icons.receipt_long_outlined,
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              itemCount: returnedLoans.length,
                              itemBuilder: (context, idx) {
                                final loan = returnedLoans[idx];
                                final returnBranch = repo.getBranchById(loan.returnBranchId ?? '');
                                final isCrossBranch = loan.isCrossBranchReturn;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              loan.bookTitle,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.5,
                                                fontFamily: 'Georgia',
                                              ),
                                            ),
                                          ),
                                          const StatusBadge(
                                            label: 'CLEARED',
                                            textColor: AppColors.primary,
                                            backgroundColor: AppColors.accentSoft,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Returned to: ${returnBranch?.name ?? loan.returnBranchId} on ${loan.returnedDate != null ? dateFormat.format(loan.returnedDate!) : "Today"}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                      if (isCrossBranch) ...[
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.accentSoft,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            '✓ Cross-Branch Instant Clearance • Zero Penalty Applied',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 10),
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                          side: const BorderSide(color: AppColors.primary),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.receipt, size: 14),
                                        label: const Text('View Official Clearance Receipt', style: TextStyle(fontSize: 11)),
                                        onPressed: () => ReturnReceiptScreen.show(context, loan),
                                      ),
                                    ],
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
