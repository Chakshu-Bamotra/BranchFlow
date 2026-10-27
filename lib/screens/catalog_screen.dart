import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/book.dart';
import '../services/library_repository.dart';
import '../widgets/branch_chip.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/status_badge.dart';

class CatalogScreen extends StatefulWidget {
  final VoidCallback onNavigateToScanner;

  const CatalogScreen({super.key, required this.onNavigateToScanner});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedBranchFilter = 'all';
  String _selectedStatusFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showBorrowDialog(BuildContext context, Book book) {
    final repo = LibraryRepository();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text(
            'Borrow Book',
            style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Georgia'),
              ),
              const SizedBox(height: 4),
              Text('Author: ${book.author}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              const Divider(color: AppColors.border),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Borrowing Member:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text(repo.currentMemberName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Checkout Branch:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text(
                    repo.getBranchById(book.currentBranchId)?.name ?? book.currentBranchId,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Loan Duration:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('14 Days', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD4E8DA)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_outlined, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Instant clearance guaranteed when returned to ANY branch in the network.',
                        style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                final success = repo.borrowBook(
                  bookId: book.id,
                  memberId: repo.currentMemberId,
                  memberName: repo.currentMemberName,
                  fromBranchId: book.currentBranchId,
                );
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Successfully checked out "${book.title}"!' : 'Could not check out this book.'),
                    backgroundColor: success ? AppColors.success : AppColors.danger,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Confirm Checkout'),
            ),
          ],
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
        final query = _searchController.text.trim().toLowerCase();
        final filteredBooks = repo.books.where((b) {
          final matchesQuery = query.isEmpty ||
              b.title.toLowerCase().contains(query) ||
              b.author.toLowerCase().contains(query) ||
              b.barcode.toLowerCase().contains(query) ||
              b.isbn.toLowerCase().contains(query);

          final matchesBranch = _selectedBranchFilter == 'all' ||
              b.currentBranchId == _selectedBranchFilter ||
              b.homeBranchId == _selectedBranchFilter;

          final matchesStatus = _selectedStatusFilter == 'all' ||
              b.status.name == _selectedStatusFilter;

          return matchesQuery && matchesBranch && matchesStatus;
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Search & Catalog'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by title, author, barcode or ISBN...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.card,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Row(
                  children: [
                    _filterChip('all', 'All Locations', _selectedBranchFilter, (v) {
                      setState(() => _selectedBranchFilter = v);
                    }),
                    ...repo.branches.map((b) => _filterChip(b.id, b.name, _selectedBranchFilter, (v) {
                          setState(() => _selectedBranchFilter = v);
                        })),
                  ],
                ),
              ),

              // Status Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    _filterChip('all', 'All Statuses', _selectedStatusFilter, (v) {
                      setState(() => _selectedStatusFilter = v);
                    }),
                    _filterChip('available', 'Available', _selectedStatusFilter, (v) {
                      setState(() => _selectedStatusFilter = v);
                    }),
                    _filterChip('borrowed', 'Borrowed', _selectedStatusFilter, (v) {
                      setState(() => _selectedStatusFilter = v);
                    }),
                    _filterChip('inTransit', 'In Transit', _selectedStatusFilter, (v) {
                      setState(() => _selectedStatusFilter = v);
                    }),
                    _filterChip('inHolding', 'In Holding', _selectedStatusFilter, (v) {
                      setState(() => _selectedStatusFilter = v);
                    }),
                  ],
                ),
              ),

              // Results Count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  '${filteredBooks.length} items found across community network',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 6),

              // Books List
              Expanded(
                child: filteredBooks.isEmpty
                    ? Center(
                        child: EmptyStateCard(
                          title: 'No Matching Books',
                          message: 'Try adjusting your search query or location filter.',
                          icon: Icons.search_off_rounded,
                          actionLabel: 'Reset Filters',
                          onAction: () {
                            setState(() {
                              _searchController.clear();
                              _selectedBranchFilter = 'all';
                              _selectedStatusFilter = 'all';
                            });
                          },
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: filteredBooks.length,
                        itemBuilder: (context, idx) {
                          final book = filteredBooks[idx];
                          final homeBranch = repo.getBranchById(book.homeBranchId);
                          final currentBranch = repo.getBranchById(book.currentBranchId);

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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Book Thumbnail Container
                                    Container(
                                      width: 48,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.cardBorder),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 22),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            book.title,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Georgia',
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${book.author} · ${book.publishedYear}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Barcode: ${book.barcode}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontFamily: 'monospace',
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _buildStatusBadge(book.status),
                                  ],
                                ),

                                const SizedBox(height: 12),
                                const Divider(height: 1, color: AppColors.border),
                                const SizedBox(height: 10),

                                // Locations
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    BranchChip(
                                      branchName: homeBranch?.name ?? 'Home Branch',
                                      branchCode: homeBranch?.code,
                                      isHome: true,
                                    ),
                                    if (!book.isAtHomeBranch)
                                      BranchChip(
                                        branchName: currentBranch?.name ?? 'Current Location',
                                        branchCode: currentBranch?.code,
                                        isCurrent: true,
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Action Bar
                                if (book.status == BookStatus.available)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                                      label: const Text('Borrow Book'),
                                      onPressed: () => _showBorrowDialog(context, book),
                                    ),
                                  )
                                else if (book.status == BookStatus.borrowed)
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: const BorderSide(color: AppColors.primary),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      icon: const Icon(Icons.qr_code_scanner, size: 16),
                                      label: const Text('Return via Drop-Box Scanner'),
                                      onPressed: widget.onNavigateToScanner,
                                    ),
                                  )
                                else if (book.status == BookStatus.inHolding)
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.warningLight,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.warning),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Returned cross-branch. Staged for courier to home branch.',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.warning,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterChip(
    String key,
    String label,
    String currentSelection,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = currentSelection == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
        backgroundColor: AppColors.card,
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        onSelected: (_) => onSelected(key),
      ),
    );
  }

  Widget _buildStatusBadge(BookStatus status) {
    switch (status) {
      case BookStatus.available:
        return const StatusBadge(
          label: 'Available',
          textColor: AppColors.success,
          backgroundColor: AppColors.successLight,
        );
      case BookStatus.borrowed:
        return const StatusBadge(
          label: 'Borrowed',
          textColor: AppColors.warning,
          backgroundColor: AppColors.warningLight,
        );
      case BookStatus.inTransit:
        return const StatusBadge(
          label: 'In Transit',
          textColor: AppColors.info,
          backgroundColor: AppColors.infoLight,
        );
      case BookStatus.inHolding:
        return const StatusBadge(
          label: 'In Holding',
          textColor: AppColors.accent,
          backgroundColor: AppColors.accentSoft,
        );
    }
  }
}
