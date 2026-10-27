import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/transit_item.dart';
import '../services/library_repository.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/status_badge.dart';

class TransitScreen extends StatelessWidget {
  const TransitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = LibraryRepository();
    final dateFormat = DateFormat('MMM d, h:mm a');

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final awaiting = repo.transitItems
            .where((t) => t.stage == TransitStage.awaitingDispatch)
            .toList();
        final inTransit = repo.transitItems
            .where((t) => t.stage == TransitStage.inTransit)
            .toList();
        final restocked = repo.transitItems
            .where((t) => t.stage == TransitStage.restocked)
            .toList();

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Network Transit & Hub'),
              bottom: TabBar(
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(text: 'Holding (${awaiting.length})'),
                  Tab(text: 'In Transit (${inTransit.length})'),
                  Tab(text: 'Restocked (${restocked.length})'),
                ],
              ),
            ),
            body: Column(
              children: [
                // Educational Banner explaining the Problem Statement solution
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    border: Border(bottom: BorderSide(color: const Color(0xFFD4E8DA))),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hub_outlined, color: AppColors.primary, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Eliminates Catalog Vanishing: Books returned across branches are tracked in this unified pipeline until safely restocked at their home shelves.',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    children: [
                      // 1. Awaiting Dispatch List
                      _buildTransitList(
                        context: context,
                        items: awaiting,
                        emptyMessage: 'No books currently awaiting courier pickup.',
                        actionLabel: 'Dispatch with Courier Batch',
                        actionIcon: Icons.local_shipping_outlined,
                        onAction: (item) {
                          repo.dispatchTransitItem(item.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Dispatched "${item.bookTitle}" with courier batch.'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        dateFormat: dateFormat,
                      ),

                      // 2. In Transit List
                      _buildTransitList(
                        context: context,
                        items: inTransit,
                        emptyMessage: 'No courier batches currently in transit.',
                        actionLabel: 'Confirm Restock at Home Branch',
                        actionIcon: Icons.inventory_outlined,
                        onAction: (item) {
                          repo.restockTransitItem(item.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Safely restocked "${item.bookTitle}" at ${item.toBranchId}.'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        dateFormat: dateFormat,
                      ),

                      // 3. Restocked History List
                      _buildTransitList(
                        context: context,
                        items: restocked,
                        emptyMessage: 'No restocked transit logs yet.',
                        actionLabel: null,
                        actionIcon: null,
                        onAction: null,
                        dateFormat: dateFormat,
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

  Widget _buildTransitList({
    required BuildContext context,
    required List<TransitItem> items,
    required String emptyMessage,
    required String? actionLabel,
    required IconData? actionIcon,
    required ValueChanged<TransitItem>? onAction,
    required DateFormat dateFormat,
  }) {
    if (items.isEmpty) {
      return Center(
        child: EmptyStateCard(
          title: 'All Clear',
          message: emptyMessage,
          icon: Icons.check_circle_outline_rounded,
        ),
      );
    }

    final repo = LibraryRepository();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, idx) {
        final item = items[idx];
        final fromBranch = repo.getBranchById(item.fromBranchId);
        final toBranch = repo.getBranchById(item.toBranchId);

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
                  Container(
                    width: 44,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Center(
                      child: Icon(Icons.local_shipping_rounded, color: AppColors.primary, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                          'Tracking: ${item.trackingNumber} · Barcode: ${item.barcode}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  _buildStageBadge(item.stage),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),

              // Route & Courier Info
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.outbox_rounded, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'Returned to: ${fromBranch?.name ?? item.fromBranchId}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.move_to_inbox_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Home destination: ${toBranch?.name ?? item.toBranchId}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Action button (if librarian / staff action required)
              if (actionLabel != null && onAction != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(actionIcon, size: 16),
                    label: Text(actionLabel, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    onPressed: () => onAction(item),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStageBadge(TransitStage stage) {
    switch (stage) {
      case TransitStage.awaitingDispatch:
        return const StatusBadge(
          label: 'Awaiting Pickup',
          textColor: AppColors.warning,
          backgroundColor: AppColors.warningLight,
        );
      case TransitStage.inTransit:
        return const StatusBadge(
          label: 'In Transit',
          textColor: AppColors.info,
          backgroundColor: AppColors.infoLight,
        );
      case TransitStage.restocked:
        return const StatusBadge(
          label: 'Restocked',
          textColor: AppColors.success,
          backgroundColor: AppColors.successLight,
        );
    }
  }
}
