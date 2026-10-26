import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/constants/app_colors.dart';
import '../models/loan.dart';
import '../services/library_repository.dart';
import '../widgets/branch_chip.dart';
import 'return_receipt_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final LibraryRepository _repo = LibraryRepository();
  bool _useLiveCamera = false;
  MobileScannerController? _cameraController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  void _handleBarcode(String rawBarcode) {
    if (_isProcessing) return;
    final barcode = rawBarcode.trim();
    if (barcode.isEmpty) return;

    setState(() => _isProcessing = true);

    final result = _repo.processBookReturn(
      barcode: barcode,
      returnBranchId: _repo.activeBranchId,
      staffName: 'Desk Staff (${_repo.activeBranch?.name ?? "Branch"})',
    );

    setState(() => _isProcessing = false);

    if (result.success && result.loan != null) {
      _barcodeController.clear();
      ReturnReceiptScreen.show(context, result.loan!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _repo,
      builder: (context, _) {
        final activeLoans = _repo.loans.where((l) => l.status == LoanStatus.active).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Cross-Branch Return Desk'),
            actions: [
              IconButton(
                tooltip: _useLiveCamera ? 'Switch to Barcode Simulator' : 'Switch to Camera Scanner',
                icon: Icon(_useLiveCamera ? Icons.keyboard : Icons.camera_alt_outlined),
                onPressed: () {
                  setState(() {
                    _useLiveCamera = !_useLiveCamera;
                  });
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Receiving Branch Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_outlined, color: AppColors.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Receiving Drop-off Branch:',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _repo.activeBranch?.name ?? 'Select Branch',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Change Receiving Branch',
                        initialValue: _repo.activeBranchId,
                        onSelected: (branchId) => _repo.setActiveBranch(branchId),
                        itemBuilder: (ctx) => _repo.branches.map((b) {
                          return PopupMenuItem(
                            value: b.id,
                            child: Text(b.name),
                          );
                        }).toList(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Change',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              Icon(Icons.arrow_drop_down, size: 16, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Camera Scanner or Barcode Input
                if (_useLiveCamera) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 240,
                      child: MobileScanner(
                        controller: _cameraController!,
                        onDetect: (capture) {
                          final barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            if (barcode.rawValue != null) {
                              _handleBarcode(barcode.rawValue!);
                              break;
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Manual Barcode Input Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scan or Enter Book Barcode / ISBN',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Instant discharge clears member liability, generates receipt, and queues cross-branch transit.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _barcodeController,
                              decoration: const InputDecoration(
                                hintText: 'e.g. BF-BAR-1001',
                                prefixIcon: Icon(Icons.qr_code_scanner, color: AppColors.primary),
                              ),
                              onSubmitted: _handleBarcode,
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => _handleBarcode(_barcodeController.text),
                            child: const Text('Check In'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Simulation: Currently Borrowed Books
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Currently Borrowed Books (Quick Return Test)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${activeLoans.length} active',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (activeLoans.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Text(
                        'No books currently checked out. Borrow books from the Catalog tab to test returns!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  )
                else
                  ...activeLoans.map((loan) {
                    final homeBranch = _repo.getBranchById(loan.borrowedFromBranchId);
                    final isCrossBranch = loan.borrowedFromBranchId != _repo.activeBranchId;

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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isCrossBranch ? AppColors.warningLight : AppColors.successLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isCrossBranch ? '⚡ Cross-Branch' : '🏠 Same Branch',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isCrossBranch ? AppColors.warning : AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Borrower: ${loan.memberName} (${loan.memberId})',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                BranchChip(
                                  branchName: homeBranch?.name ?? 'Home Branch',
                                  branchCode: homeBranch?.code,
                                  isHome: true,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Barcode: ${loan.bookBarcode}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.login, size: 16),
                                label: Text('Instant Return at ${_repo.activeBranch?.name ?? "this Branch"}'),
                                onPressed: () => _handleBarcode(loan.bookBarcode),
                              ),
                            ),
                          ],
                        ),
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
