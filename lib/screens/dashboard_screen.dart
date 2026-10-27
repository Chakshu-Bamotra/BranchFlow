import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/loan.dart';
import '../models/transit_item.dart';
import '../services/auth_service.dart';
import '../services/library_repository.dart';
import '../services/firestore_seeder.dart';
import 'return_receipt_screen.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onNavigateToScanner;
  final VoidCallback onNavigateToTransit;

  const DashboardScreen({
    super.key,
    required this.onNavigateToScanner,
    required this.onNavigateToTransit,
  });

  void _showBranchPicker(BuildContext context, LibraryRepository repo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Select Active Branch',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Georgia',
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'BranchFlow seamlessly synchronizes your catalog & loans across all library locations.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ...repo.branches.map((branch) {
                  final isSelected = branch.id == repo.activeBranchId;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accentSoft : AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.cardBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      title: Text(
                        branch.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${branch.address} • Code: ${branch.code}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                          : null,
                      onTap: () {
                        repo.setActiveBranch(branch.id);
                        Navigator.of(ctx).pop();
                      },
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

  @override
  Widget build(BuildContext context) {
    final repo = LibraryRepository();

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final activeLoans = repo.loans.where((l) => l.status == LoanStatus.active).toList();
        final transitItems = repo.transitItems;
        final activeBranch = repo.activeBranch;
        final currentMember = AuthService().currentUser;
        final initials = (currentMember?.displayName ?? currentMember?.email ?? 'AR')
            .trim()
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // Top Athenaeum Header (Branch Selector, Search, Bell, Monogram Avatar)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        // Location Branch Chip (Interactive)
                        GestureDetector(
                          onTap: () => _showBranchPicker(context, repo),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                                const SizedBox(width: 6),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 160),
                                  child: Text(
                                    activeBranch?.name ?? 'Downtown Central...',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),

                        // Notification Bell
                        IconButton(
                          icon: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Icons.notifications_none_rounded, size: 22, color: AppColors.textPrimary),
                              if (repo.transitCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.warning,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onPressed: onNavigateToTransit,
                        ),

                        // Monogram Avatar Circle
                        PopupMenuButton<String>(
                          offset: const Offset(0, 40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          icon: CircleAvatar(
                            radius: 17,
                            backgroundColor: AppColors.accentSoft,
                            child: Text(
                              initials.isNotEmpty ? initials : 'AR',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              enabled: false,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentMember?.displayName ?? 'Library Member',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  Text(
                                    currentMember?.email ?? 'member@branchflow.lib',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                  const Divider(height: 16),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'toggle_role',
                              child: Row(
                                children: [
                                  Icon(
                                    repo.currentRole == UserRole.librarian
                                        ? Icons.person_outline
                                        : Icons.admin_panel_settings_outlined,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    repo.currentRole == UserRole.librarian
                                        ? 'Switch to Member Mode'
                                        : 'Switch to Staff Mode',
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'seed_data',
                              child: Row(
                                children: [
                                  Icon(Icons.cloud_sync_outlined, size: 18, color: AppColors.accent),
                                  SizedBox(width: 10),
                                  Text('Sync / Seed Cloud Data'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'sign_out',
                              child: Row(
                                children: [
                                  Icon(Icons.logout_rounded, size: 18, color: AppColors.danger),
                                  SizedBox(width: 10),
                                  Text('Sign Out', style: TextStyle(color: AppColors.danger)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (val) async {
                            if (val == 'toggle_role') {
                              repo.setRole(
                                repo.currentRole == UserRole.librarian
                                    ? UserRole.member
                                    : UserRole.librarian,
                              );
                            } else if (val == 'seed_data') {
                              final messenger = ScaffoldMessenger.of(context);
                              final res = await FirestoreSeeder.seedInitialData();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(res.message),
                                  backgroundColor: res.success ? AppColors.success : AppColors.danger,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else if (val == 'sign_out') {
                              await AuthService().signOut();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // System Status Banner (Sage Green)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD4E8DA)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.shield_outlined, color: AppColors.primary, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'System Status: Fully Synchronized • 0 Outstanding Holds • All Returned Items Reconciled across ${repo.branches.length} Branches.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Instant Cross-Branch Clearance',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Section 1: "Currently Checked Out"
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text(
                          'Currently Checked Out',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Georgia',
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${activeLoans.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Active Loan Cards List
                if (activeLoans.isEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Center(
                        child: Text(
                          'No currently checked out books on your shelf.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final loan = activeLoans[index];
                        return _buildAthenaeumBookCard(context, loan, repo);
                      },
                      childCount: activeLoans.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // Section 2: "Network Transit & Clearances"
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text(
                          'Network Transit & Clearances',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Georgia',
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${transitItems.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Transit / Reconciled Cards List
                if (transitItems.isEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Center(
                        child: Text(
                          'All returned items are fully restocked at home branches.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = transitItems[index];
                        return _buildAthenaeumTransitCard(context, item, repo);
                      },
                      childCount: transitItems.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // Athenaeum "Currently Checked Out" Book Card
  // -------------------------------------------------------------
  Widget _buildAthenaeumBookCard(BuildContext context, Loan loan, LibraryRepository repo) {
    final borrowBranch = repo.getBranchById(loan.borrowBranchId);
    final isDueSoon = loan.isOverdue || loan.dueDaysRemaining <= 3;
    final dueFormatted = DateFormat('MMM d').format(loan.dueDate);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stylized Book Cover Art Thumbnail
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.menu_book_rounded, size: 24, color: AppColors.primary),
                    const SizedBox(height: 4),
                    Text(
                      loan.bookTitle.split(' ').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Title, Author, Origin Tag
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.bookTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Georgia',
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      loan.bookAuthor,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Origin Pill (White capsule)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2DAD0)),
                      ),
                      child: Text(
                        'BORROWED FROM: ${(borrowBranch?.name ?? loan.borrowBranchId).toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Due Date Badge Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDueSoon ? AppColors.duePillAmberBg : AppColors.duePillGreenBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDueSoon ? const Color(0xFFFCD34D) : const Color(0xFFC7E6D0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: isDueSoon ? AppColors.duePillAmberText : AppColors.duePillGreenText,
                ),
                const SizedBox(width: 6),
                Text(
                  isDueSoon
                      ? (loan.isOverdue ? 'Overdue ($dueFormatted)' : 'Due in ${loan.dueDaysRemaining} Days ($dueFormatted)')
                      : 'Due in ${loan.dueDaysRemaining} Days ($dueFormatted)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDueSoon ? AppColors.duePillAmberText : AppColors.duePillGreenText,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),
          const Text(
            'Returnable at ANY branch drop-slot',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 12),

          // Primary Dark Forest Green Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () {
                // Instantly populates return scanner or triggers drop-box return
                final result = repo.processBookReturn(
                  barcode: loan.barcode,
                  returnBranchId: repo.activeBranchId,
                  staffName: 'Self-Service Drop-Box (${repo.activeBranch?.name ?? "Branch"})',
                );
                if (result.success && result.loan != null) {
                  ReturnReceiptScreen.show(context, result.loan!);
                } else {
                  onNavigateToScanner();
                }
              },
              icon: const Icon(Icons.qr_code_scanner, size: 18),
              label: const Text(
                'Return via Drop-Box Scanner',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Athenaeum "Network Transit & Clearances" Card
  // -------------------------------------------------------------
  Widget _buildAthenaeumTransitCard(BuildContext context, TransitItem item, LibraryRepository repo) {
    final fromBranch = repo.getBranchById(item.fromBranchId);
    final toBranch = repo.getBranchById(item.toBranchId);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book Thumbnail
          Container(
            width: 50,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Center(
              child: Icon(Icons.code_rounded, size: 22, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.bookTitle,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Georgia',
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Barcode: ${item.barcode}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),

                // Syncing / Stage Pill
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD97706),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            item.stage == TransitStage.awaitingDispatch
                                ? 'SYNCING / STAGED'
                                : (item.stage == TransitStage.inTransit ? 'IN TRANSIT' : 'RESTOCKED'),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Accepted at ${fromBranch?.name ?? item.fromBranchId} • En route to ${toBranch?.name ?? item.toBranchId}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
