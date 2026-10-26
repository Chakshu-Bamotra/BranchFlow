import 'package:flutter_test/flutter_test.dart';
import 'package:branch_flow/models/book.dart';
import 'package:branch_flow/models/branch.dart';
import 'package:branch_flow/models/loan.dart';
import 'package:branch_flow/models/transit_item.dart';

void main() {
  group('Domain Models & Serialization Tests', () {
    test('Book toMap and fromMap serialization', () {
      final book = Book(
        id: 'book-99',
        isbn: '978-0134494166',
        barcode: '9780134494166',
        title: 'Clean Architecture',
        author: 'Robert C. Martin',
        category: 'Software Architecture',
        homeBranchId: 'branch_central',
        currentBranchId: 'branch_westside',
        status: BookStatus.inHolding,
        publishedYear: 2017,
      );

      final map = book.toMap();
      expect(map['title'], 'Clean Architecture');
      expect(map['status'], 'in_holding');
      expect(map['barcode'], '9780134494166');
      expect(map['category'], 'Software Architecture');

      final reconstructed = Book.fromMap(map, 'book-99');
      expect(reconstructed.id, 'book-99');
      expect(reconstructed.title, book.title);
      expect(reconstructed.status, BookStatus.inHolding);
      expect(reconstructed.currentBranchId, 'branch_westside');
      expect(reconstructed.category, 'Software Architecture');
    });

    test('Branch toMap and fromMap serialization', () {
      const branch = Branch(
        id: 'branch_east',
        code: 'EAS',
        name: 'East Community Library',
        address: '77 Sunrise Blvd',
        contactPhone: '+1-555-0199',
        totalInventory: 1500,
      );

      final map = branch.toMap();
      expect(map['name'], 'East Community Library');
      expect(map['code'], 'EAS');
      expect(map['contactPhone'], '+1-555-0199');

      final reconstructed = Branch.fromMap(map, 'branch_east');
      expect(reconstructed.id, 'branch_east');
      expect(reconstructed.code, 'EAS');
      expect(reconstructed.totalInventory, 1500);
    });

    test('Loan toMap and fromMap serialization with penalty freeze', () {
      final now = DateTime.now();
      final loan = Loan(
        id: 'loan-42',
        bookId: 'book-1',
        bookTitle: 'Clean Code',
        bookBarcode: '9780132350884',
        bookAuthor: 'Robert C. Martin',
        memberId: 'mem_1',
        memberName: 'Priya Sharma',
        borrowedFromBranchId: 'branch_central',
        borrowedAt: now.subtract(const Duration(days: 10)),
        dueDate: now.add(const Duration(days: 4)),
        returnedAt: now,
        returnedToBranchId: 'branch_westside',
        returnReceiptCode: 'REC-TEST-42',
        receivedByStaff: 'Desk Staff',
        penaltyAvoided: 15.00,
        status: LoanStatus.returned,
      );

      final map = loan.toMap();
      expect(map['returnReceiptCode'], 'REC-TEST-42');
      expect(map['penaltyAvoided'], 15.00);
      expect(map['status'], 'returned');

      final reconstructed = Loan.fromMap(map, 'loan-42');
      expect(reconstructed.id, 'loan-42');
      expect(reconstructed.returnReceiptCode, 'REC-TEST-42');
      expect(reconstructed.status, LoanStatus.returned);
      expect(reconstructed.penaltyAvoided, 15.00);
    });

    test('TransitItem stage state machine serialization', () {
      final now = DateTime.now();
      final transit = TransitItem(
        id: 'trn-101',
        bookId: 'book-1',
        bookTitle: 'Clean Code',
        bookBarcode: '9780132350884',
        originBranchId: 'branch_westside',
        destinationBranchId: 'branch_central',
        createdAt: now,
        stage: TransitStage.awaitingDispatch,
        courierBatchId: 'BATCH-WST-CEN',
      );

      final map = transit.toMap();
      expect(map['stage'], 'awaiting_dispatch');
      expect(map['courierBatchId'], 'BATCH-WST-CEN');

      final reconstructed = TransitItem.fromMap(map, 'trn-101');
      expect(reconstructed.id, 'trn-101');
      expect(reconstructed.stage, TransitStage.awaitingDispatch);

      final dispatched = reconstructed.copyWith(stage: TransitStage.inTransit);
      expect(dispatched.stage, TransitStage.inTransit);
    });
  });
}
