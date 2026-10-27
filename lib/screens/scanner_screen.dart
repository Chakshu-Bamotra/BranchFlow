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
      staffName: 'Self-Service Drop-Box (${_repo.activeBranch?.name ?? "Branch"})',
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
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Drop-Box Scanner'),
            actions: [
              IconButton(
                tooltip: _useLiveCamera ? 'Switch to Barcode Simulator' : 'Switch to Camera Scanner',
                icon: Icon(_useLiveCamera ? Icons.keyboard : Icons.camera_alt_outlined, color: AppColors.primary),
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.markunread_mailbox_outlined, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DROP-BOX LOCATION',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _repo.activeBranch?.name ?? 'Central Library',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Georgia',
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Cross-branch returns are instantly credited with 0 penalty delay.',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Scanner Viewport / Barcode Input Box
                if (_useLiveCamera)
                  Container(
                    height: 240,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        MobileScanner(
                          controller: _cameraController!,
                          onDetect: (capture) {
                            final barcodes = capture.barcodes;
                            if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                              _handleBarcode(barcodes.first.rawValue!);
                            }
                          },
                        ),
                        Container(
                          width: 200,
                          height: 140,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.accentLight, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        if (_isProcessing)
                          const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Drop-Box Barcode Scanner',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Georgia',
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Scan the book sticker or enter the barcode below to process instant clearance.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _barcodeController,
                                decoration: InputDecoration(
                                  hintText: 'e.g., BOOK-DDIA-001',
                                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                                  prefixIcon: const Icon(Icons.document_scanner_outlined, color: AppColors.primary),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                ),
                                onSubmitted: _handleBarcode,
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _isProcessing
                                  ? null
                                  : () => _handleBarcode(_barcodeController.text),
                              child: _isProcessing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Return'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 22),

                // Quick Scan Simulation Chips
                Row(
                  children: [
                    const Text(
                      'Ready for Return',
                      style: TextStyle(
                        fontSize: 17,
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${activeLoans.length}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select any active loan to simulate instant cross-branch scanning:',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),

                if (activeLoans.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Center(
                      child: Text(
                        'No books currently borrowed. Checkout from Catalog to test!',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ...activeLoans.map((loan) {
                    final isCrossBranch = loan.borrowBranchId != _repo.activeBranchId;
                    final borrowBranch = _repo.getBranchById(loan.borrowBranchId);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.menu_book, color: AppColors.primary, size: 22),
                        ),
                        title: Text(
                          loan.bookTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Georgia'),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${loan.bookAuthor} · ${loan.barcode}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              children: [
                                BranchChip(
                                  branchName: borrowBranch?.name ?? loan.borrowBranchId,
                                  isHome: true,
                                ),
                                if (isCrossBranch)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.warningLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'CROSS-BRANCH RETURN',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.warning),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _handleBarcode(loan.barcode),
                          child: const Text('Scan Return', style: TextStyle(fontSize: 12)),
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
