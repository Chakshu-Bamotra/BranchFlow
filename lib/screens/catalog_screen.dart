import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/book.dart';
import '../services/library_repository.dart';
import '../widgets/branch_chip.dart';
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
          title: const Text('Borrow Book'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.accent),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You can return this book to ANY branch in the network anytime!',
                        style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600),
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final success = repo.borrowBook(
                  bookId: book.id,
                  memberId: repo.currentMemberId,
                  memberName: repo.currentMemberName,
                  fromBranchId: book.currentBranchId,
                );
                Navigator.of(ctx).pop();
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully borrowed "${book.title}". Enjoy reading!'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
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
        final query = _searchController.text.toLowerCase().trim();

        final filteredBooks = repo.books.where((b) {
          // Branch filter
          if (_selectedBranchFilter != 'all') {
            if (b.homeBranchId != _selectedBranchFilter &&
                b.currentBranchId != _selectedBranchFilter) {
              return false;
            }
          }

          // Status filter
          if (_selectedStatusFilter != 'all') {
            if (b.status.key != _selectedStatusFilter) return false;
          }

          // Search query
          if (query.isNotEmpty) {
            final matchTitle = b.title.toLowerCase().contains(query);
            final matchAuthor = b.author.toLowerCase().contains(query);
            final matchBarcode = b.barcode.toLowerCase().contains(query);
            final matchIsbn = b.isbn.toLowerCase().contains(query);
            final matchCategory = b.category.toLowerCase().contains(query);
            return matchTitle || matchAuthor || matchBarcode || matchIsbn || matchCategory;
          }

          return true;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Network Catalog'),
          ),
          body: Column(
            children: [
              // Search & Filter Header
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by title, author, barcode...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    // Branch horizontal selector
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('all', 'All Branches', _selectedBranchFilter, (val) {
                            setState(() => _selectedBranchFilter = val);
                          }),
                          ...repo.branches.map((br) {
                            return _filterChip(br.id, br.name, _selectedBranchFilter, (val) {
                              setState(() => _selectedBranchFilter = val);
                            });
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Status horizontal selector
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('all', 'All Statuses', _selectedStatusFilter, (val) {
                            setState(() => _selectedStatusFilter = val);
                          }),
                          _filterChip('available', 'Available', _selectedStatusFilter, (val) {
                            setState(() => _selectedStatusFilter = val);
                          }),
                          _filterChip('borrowed', 'Checked Out', _selectedStatusFilter, (val) {
                            setState(() => _selectedStatusFilter = val);
                          }),
                          _filterChip('in_holding', 'Holding Staging', _selectedStatusFilter, (val) {
                            setState(() => _selectedStatusFilter = val);
                          }),
                          _filterChip('in_transit', 'In Transit', _selectedStatusFilter, (val) {
                            setState(() => _selectedStatusFilter = val);
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.border),

              // Results Count Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filteredBooks.length} books found',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Unified Cross-Catalog',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Book List
              Expanded(
                child: filteredBooks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.menu_book, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            const Text(
                              'No books match your criteria',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _selectedBranchFilter = 'all';
                                  _selectedStatusFilter = 'all';
                                });
                              },
                              child: const Text('Reset filters'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: filteredBooks.length,
                        itemBuilder: (context, idx) {
                          final book = filteredBooks[idx];
                          final homeBranch = repo.getBranchById(book.homeBranchId);
                          final currentBranch = repo.getBranchById(book.currentBranchId);

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
                                      Container(
                                        width: 44,
                                        height: 58,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.book, color: AppColors.primary, size: 24),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              book.title,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
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
                                              'Barcode: ${book.barcode} · ISBN: ${book.isbn}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontFamily: 'monospace',
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),
                                  const Divider(height: 1, color: AppColors.border),
                                  const SizedBox(height: 10),

                                  // Locations & Status
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Wrap(
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
                                      ),
                                      _buildStatusBadge(book.status),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Action Bar
                                  if (book.status == BookStatus.available)
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                                        label: const Text('Borrow Book'),
                                        onPressed: () => _showBorrowDialog(context, book),
                                      ),
                                    )
                                  else if (book.status == BookStatus.borrowed)
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.qr_code_scanner, size: 16),
                                        label: const Text('Return via Scanner Desk'),
                                        onPressed: widget.onNavigateToScanner,
                                      ),
                                    )
                                  else if (book.status == BookStatus.inHolding)
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.warningLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.warning),
                                          SizedBox(width: 6),
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
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        onSelected: (_) => onSelected(key),
      ),
    );
  }

  Widget _buildStatusBadge(BookStatus status) {
    switch (status) {
      case BookStatus.available:
        return StatusBadge.success('Available');
      case BookStatus.borrowed:
        return StatusBadge.danger('Checked Out');
      case BookStatus.inHolding:
        return StatusBadge.warning('Staging');
      case BookStatus.inTransit:
        return StatusBadge.info('In Transit');
    }
  }
}
