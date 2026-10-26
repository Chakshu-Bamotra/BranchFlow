import 'package:flutter_test/flutter_test.dart';
import 'package:branch_flow/services/library_repository.dart';
import 'package:branch_flow/models/book.dart';
import 'package:branch_flow/models/loan.dart';
import 'package:branch_flow/models/transit_item.dart';

void main() {
  group('Cross-Branch Return & Transit State Machine', () {
    late LibraryRepository repo;

    setUp(() {
      repo = LibraryRepository();
    });

    test('Returning a book at a foreign branch instantly clears loan liability', () {
      // Find an active loan
      final activeLoan = repo.loans.firstWhere((l) => l.status == LoanStatus.active);
      final barcode = activeLoan.bookBarcode;
      final homeBranchId = activeLoan.borrowedFromBranchId;

      // Drop off at a DIFFERENT branch (Westside or Oakridge)
      final dropOffBranchId = homeBranchId == 'branch_westside'
          ? 'branch_central'
          : 'branch_westside';

      final initialTransitCount = repo.transitItems.length;

      // Execute instant check-in
      final result = repo.processBookReturn(
        barcode: barcode,
        returnBranchId: dropOffBranchId,
        staffName: 'Staff Member @ Drop-off',
      );

      // 1. Check success
      expect(result.success, isTrue);
      expect(result.isCrossBranch, isTrue);
      expect(result.loan, isNotNull);

      // 2. Member liability is immediately discharged
      expect(result.loan!.status, LoanStatus.returned);
      expect(result.loan!.returnedAt, isNotNull);
      expect(result.loan!.returnedToBranchId, dropOffBranchId);
      expect(result.loan!.returnReceiptCode, isNotNull);
      expect(result.penaltyAvoided, greaterThan(0));

      // 3. Book is staged in holding, NOT lost
      final book = repo.getBookByBarcode(barcode);
      expect(book, isNotNull);
      expect(book!.currentBranchId, dropOffBranchId);
      expect(book.status, BookStatus.inHolding);

      // 4. Inter-branch transit item created
      expect(repo.transitItems.length, initialTransitCount + 1);
      final newTransit = repo.transitItems.first;
      expect(newTransit.originBranchId, dropOffBranchId);
      expect(newTransit.destinationBranchId, homeBranchId);
      expect(newTransit.stage, TransitStage.awaitingDispatch);

      // 5. Courier accepts dispatch
      repo.dispatchTransitItem(newTransit.id);
      final dispatched = repo.transitItems.firstWhere((t) => t.id == newTransit.id);
      expect(dispatched.stage, TransitStage.inTransit);
      expect(repo.getBookById(book.id)!.status, BookStatus.inTransit);

      // 6. Home branch receives and re-shelves
      repo.restockTransitItem(newTransit.id);
      final restocked = repo.transitItems.firstWhere((t) => t.id == newTransit.id);
      expect(restocked.stage, TransitStage.restocked);
      final restockedBook = repo.getBookById(book.id)!;
      expect(restockedBook.status, BookStatus.available);
      expect(restockedBook.currentBranchId, homeBranchId);
    });
  });
}
