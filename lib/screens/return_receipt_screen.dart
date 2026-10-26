import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/loan.dart';
import '../services/library_repository.dart';

class ReturnReceiptScreen extends StatelessWidget {
  final Loan loan;

  const ReturnReceiptScreen({super.key, required this.loan});

  static void show(BuildContext context, Loan loan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReturnReceiptScreen(loan: loan),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = LibraryRepository();
    final homeBranch = repo.getBranchById(loan.borrowedFromBranchId);
    final returnBranch = repo.getBranchById(loan.returnedToBranchId ?? '');
    final dateFormat = DateFormat('MMM d, yyyy · h:mm:ss a');

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Success Shield
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: AppColors.success,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Official Return Receipt',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Member liability discharged. Holds & penalties permanently cleared.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 24),

          // Receipt Certificate Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _receiptRow(
                  'Receipt Verification ID',
                  loan.returnReceiptCode ?? 'BF-REC-VERIFIED',
                  isBold: true,
                  color: AppColors.primary,
                ),
                const Divider(height: 20, color: AppColors.border),
                _receiptRow(
                  'Book Title',
                  loan.bookTitle,
                  isBold: true,
                ),
                const SizedBox(height: 10),
                _receiptRow(
                  'Barcode / Asset ID',
                  loan.bookBarcode,
                ),
                const SizedBox(height: 10),
                _receiptRow(
                  'Borrower',
                  '${loan.memberName} (${loan.memberId})',
                ),
                const Divider(height: 20, color: AppColors.border),
                _receiptRow(
                  'Checkout Branch (Home)',
                  homeBranch?.name ?? loan.borrowedFromBranchId,
                ),
                const SizedBox(height: 10),
                _receiptRow(
                  'Drop-Off Branch (Return)',
                  returnBranch?.name ?? (loan.returnedToBranchId ?? 'Network Branch'),
                  color: loan.isCrossBranchReturn ? AppColors.accent : null,
                  isBold: loan.isCrossBranchReturn,
                ),
                const SizedBox(height: 10),
                _receiptRow(
                  'Returned At',
                  loan.returnedAt != null
                      ? dateFormat.format(loan.returnedAt!)
                      : 'Verified at counter',
                ),
                const SizedBox(height: 10),
                _receiptRow(
                  'Received By Staff',
                  loan.receivedByStaff ?? 'Branch Librarian',
                ),
                if (loan.penaltyAvoided > 0) ...[
                  const Divider(height: 20, color: AppColors.border),
                  _receiptRow(
                    'Late Penalty Prevented',
                    '\$${loan.penaltyAvoided.toStringAsFixed(2)}',
                    color: AppColors.success,
                    isBold: true,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check, size: 20),
              label: const Text('Done / Dismiss'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
