import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/transit_item.dart';
import '../services/library_repository.dart';
import '../widgets/branch_chip.dart';
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
            appBar: AppBar(
              title: const Text('Inter-Branch Transit Hub'),
              bottom: TabBar(
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
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
                  color: AppColors.accentSoft,
                  child: const Row(
                    children: [
                      Icon(Icons.hub_outlined, color: AppColors.accent, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Eliminates Catalog Vanishing: Books returned to foreign branches are tracked in this synchronized pipeline until safely restocked.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
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
                              backgroundColor: AppColors.info,
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
                        actionIcon: Icons.check_circle_outline,
                        onAction: (item) {
                          repo.restockTransitItem(item.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('"${item.bookTitle}" re-shelved and marked Available at home branch!'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        dateFormat: dateFormat,
                      ),

                      // 3. Restocked List
                      _buildTransitList(
                        context: context,
                        items: restocked,
                        emptyMessage: 'No completed transits yet.',
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
    String? actionLabel,
    IconData? actionIcon,
    ValueChanged<TransitItem>? onAction,
    required DateFormat dateFormat,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final repo = LibraryRepository();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, idx) {
        final item = items[idx];
        final origin = repo.getBranchById(item.originBranchId);
        final destination = repo.getBranchById(item.destinationBranchId);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.courierBatchId,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: AppColors.primary,
                      ),
                    ),
                    _buildStageBadge(item.stage),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.bookTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Barcode: ${item.bookBarcode}',
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 10),

                // Origin -> Destination Routing
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Drop-off Branch', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          const SizedBox(height: 2),
                          BranchChip(
                            branchName: origin?.name ?? item.originBranchId,
                            branchCode: origin?.code,
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward, size: 16, color: AppColors.textSecondary),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Home Branch', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          const SizedBox(height: 2),
                          BranchChip(
                            branchName: destination?.name ?? item.destinationBranchId,
                            branchCode: destination?.code,
                            isHome: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Text(
                  'Logged: ${dateFormat.format(item.createdAt)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),

                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(actionIcon, size: 16),
                      label: Text(actionLabel),
                      onPressed: () => onAction(item),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStageBadge(TransitStage stage) {
    switch (stage) {
      case TransitStage.awaitingDispatch:
        return StatusBadge.warning('Holding Staging');
      case TransitStage.inTransit:
        return StatusBadge.info('En Route');
      case TransitStage.restocked:
        return StatusBadge.success('Restocked');
    }
  }
}
