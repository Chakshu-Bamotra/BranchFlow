import 'package:flutter/foundation.dart';
import '../models/branch.dart';
import '../models/book.dart';
import '../models/loan.dart';
import '../models/transit_item.dart';
import 'mock_data.dart';
import 'firestore_service.dart';

enum UserRole {
  member,
  librarian,
}

class LibraryRepository extends ChangeNotifier {
  // Singleton pattern for accessible shared reactive state
  static final LibraryRepository _instance = LibraryRepository._internal();
  factory LibraryRepository() => _instance;

  LibraryRepository._internal() {
    _initData();
  }

  // Active Session State
  UserRole _currentRole = UserRole.librarian;
  String _activeBranchId = 'branch_westside'; // Default staff view at Westside
  final String _currentMemberId = 'MEM-4021';
  final String _currentMemberName = 'Library Member';

  // Data Stores
  List<Branch> _branches = [];
  List<Book> _books = [];
  List<Loan> _loans = [];
  List<TransitItem> _transitItems = [];

  // Getters
  UserRole get currentRole => _currentRole;
  String get activeBranchId => _activeBranchId;
  String get currentMemberId => _currentMemberId;
  String get currentMemberName => _currentMemberName;

  List<Branch> get branches => List.unmodifiable(_branches);
  List<Book> get books => List.unmodifiable(_books);
  List<Loan> get loans => List.unmodifiable(_loans);
  List<TransitItem> get transitItems => List.unmodifiable(_transitItems);

  Branch? get activeBranch =>
      _branches.firstWhere((b) => b.id == _activeBranchId, orElse: () => _branches.first);

  Branch? getBranchById(String id) {
    try {
      return _branches.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  Book? getBookById(String id) {
    try {
      return _books.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  Book? getBookByBarcode(String barcode) {
    try {
      return _books.firstWhere(
        (b) => b.barcode.trim().toLowerCase() == barcode.trim().toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  // Role & Branch Switching
  void setRole(UserRole role) {
    _currentRole = role;
    notifyListeners();
  }

  void setActiveBranch(String branchId) {
    _activeBranchId = branchId;
    notifyListeners();
  }

  void _initData() {
    _branches = List.from(MockData.branches);
    _books = List.from(MockData.books);
    _loans = List.from(MockData.initialLoans);
    _transitItems = List.from(MockData.initialTransit);
  }

  // Key Statistics
  int get activeLoansCount =>
      _loans.where((l) => l.status == LoanStatus.active).length;

  int get transitCount => _transitItems
      .where((t) => t.stage != TransitStage.restocked)
      .length;

  double get totalPenaltiesSaved => _loans.fold<double>(
        0.0,
        (sum, loan) => sum + loan.penaltyAvoided,
      );

  int get crossBranchReturnsCount =>
      _loans.where((l) => l.isCrossBranchReturn).length;

  List<Loan> get memberLoans =>
      _loans.where((l) => l.memberId == _currentMemberId).toList();

  List<Loan> get activeMemberLoans =>
      memberLoans.where((l) => l.status == LoanStatus.active).toList();

  List<Loan> get returnedMemberLoans =>
      memberLoans.where((l) => l.status == LoanStatus.returned).toList();

  // -------------------------------------------------------------
  // CORE PROBLEM STATEMENT RESOLVER: INSTANT CROSS-BRANCH RETURN
  // -------------------------------------------------------------
  ReturnResult processBookReturn({
    required String barcode,
    required String returnBranchId,
    String? staffName,
  }) {
    final cleanBarcode = barcode.trim();
    final book = getBookByBarcode(cleanBarcode);

    if (book == null) {
      return ReturnResult(
        success: false,
        message: 'No book found matching barcode: $cleanBarcode',
      );
    }

    // Look for active loan
    final loanIndex = _loans.indexWhere(
      (l) =>
          l.bookBarcode.trim().toLowerCase() == cleanBarcode.toLowerCase() &&
          l.status == LoanStatus.active,
    );

    final returnBranch = getBranchById(returnBranchId);
    final returnBranchName = returnBranch?.name ?? 'Community Branch';
    final staff = staffName ?? 'Staff Member ($returnBranchName)';
    final now = DateTime.now();

    Loan updatedLoan;
    double savedFine = 0.0;

    if (loanIndex != -1) {
      final existingLoan = _loans[loanIndex];

      // If returning on time or cross branch, calculate penalty avoided
      if (now.isBefore(existingLoan.dueDate) ||
          now.difference(existingLoan.dueDate).inDays <= 0) {
        // Prevented late fees ($2.50 per projected day of delay avoided)
        savedFine = 15.00;
      }

      final receiptCode =
          'BF-RTN-${now.millisecondsSinceEpoch.toString().substring(7)}-${returnBranch?.code ?? "BR"}';

      updatedLoan = existingLoan.copyWith(
        status: LoanStatus.returned,
        returnedAt: now,
        returnedToBranchId: returnBranchId,
        returnReceiptCode: receiptCode,
        receivedByStaff: staff,
        penaltyAvoided: savedFine,
      );

      _loans[loanIndex] = updatedLoan;
    } else {
      // Standalone return / manual check-in
      final receiptCode =
          'BF-RTN-${now.millisecondsSinceEpoch.toString().substring(7)}-${returnBranch?.code ?? "BR"}';
      updatedLoan = Loan(
        id: 'LOAN-MANUAL-${now.millisecondsSinceEpoch}',
        bookId: book.id,
        bookTitle: book.title,
        bookBarcode: book.barcode,
        bookAuthor: book.author,
        memberId: _currentMemberId,
        memberName: _currentMemberName,
        borrowedFromBranchId: book.homeBranchId,
        borrowedAt: now.subtract(const Duration(days: 7)),
        dueDate: now.add(const Duration(days: 7)),
        returnedAt: now,
        returnedToBranchId: returnBranchId,
        returnReceiptCode: receiptCode,
        receivedByStaff: staff,
        status: LoanStatus.returned,
        penaltyAvoided: 10.00,
      );
      _loans.insert(0, updatedLoan);
    }

    // Update Book and Inter-Branch Logistics
    final bookIndex = _books.indexWhere((b) => b.id == book.id);
    final isCrossBranch = book.homeBranchId != returnBranchId;

    if (isCrossBranch) {
      // Book is at return branch, but belongs to home branch
      _books[bookIndex] = book.copyWith(
        currentBranchId: returnBranchId,
        status: BookStatus.inHolding,
      );

      // Create Inter-Branch Transit Item
      final transitItem = TransitItem(
        id: 'TRN-${now.millisecondsSinceEpoch.toString().substring(5)}',
        bookId: book.id,
        bookTitle: book.title,
        bookBarcode: book.barcode,
        originBranchId: returnBranchId,
        destinationBranchId: book.homeBranchId,
        createdAt: now,
        stage: TransitStage.awaitingDispatch,
        courierBatchId: 'BATCH-${returnBranch?.code ?? "ORG"}-${book.homeBranchId.substring(7).toUpperCase()}',
      );
      _transitItems.insert(0, transitItem);
    } else {
      // Returned to its original home branch -> immediately available!
      _books[bookIndex] = book.copyWith(
        currentBranchId: returnBranchId,
        status: BookStatus.available,
      );
    }

    // Sync to Cloud Firestore if connected
    if (FirestoreService().isConnected) {
      FirestoreService().executeCrossBranchReturnBatch(
        loan: updatedLoan,
        book: book,
        returnBranchId: returnBranchId,
        staffName: staff,
        receiptCode: updatedLoan.returnReceiptCode ?? 'REC-AUTO',
      );
    }

    notifyListeners();

    return ReturnResult(
      success: true,
      message: isCrossBranch
          ? 'Book checked in at ${returnBranch?.name}. Member record cleared instantly! Transit item generated.'
          : 'Book checked in at home branch. Re-shelved and available.',
      loan: updatedLoan,
      isCrossBranch: isCrossBranch,
      penaltyAvoided: savedFine,
    );
  }

  // -------------------------------------------------------------
  // TRANSIT LOGISTICS DISPATCH & RECEIVING
  // -------------------------------------------------------------
  void dispatchTransitItem(String transitId) {
    final idx = _transitItems.indexWhere((t) => t.id == transitId);
    if (idx != -1) {
      final current = _transitItems[idx];
      _transitItems[idx] = current.copyWith(
        stage: TransitStage.inTransit,
        dispatchedAt: DateTime.now(),
      );

      final bookIdx = _books.indexWhere((b) => b.id == current.bookId);
      if (bookIdx != -1) {
        _books[bookIdx] = _books[bookIdx].copyWith(status: BookStatus.inTransit);
      }

      if (FirestoreService().isConnected) {
        FirestoreService().transitRef?.doc(transitId).update({
          'stage': TransitStage.inTransit.key,
          'dispatchedAt': DateTime.now(),
        });
        if (bookIdx != -1) {
          FirestoreService().updateBookStatus(current.bookId, BookStatus.inTransit);
        }
      }

      notifyListeners();
    }
  }

  void restockTransitItem(String transitId) {
    final idx = _transitItems.indexWhere((t) => t.id == transitId);
    if (idx != -1) {
      final current = _transitItems[idx];
      _transitItems[idx] = current.copyWith(
        stage: TransitStage.restocked,
        restockedAt: DateTime.now(),
      );

      final bookIdx = _books.indexWhere((b) => b.id == current.bookId);
      if (bookIdx != -1) {
        _books[bookIdx] = _books[bookIdx].copyWith(
          currentBranchId: current.destinationBranchId,
          status: BookStatus.available,
        );
      }

      if (FirestoreService().isConnected) {
        FirestoreService().transitRef?.doc(transitId).update({
          'stage': TransitStage.restocked.key,
          'restockedAt': DateTime.now(),
        });
        if (bookIdx != -1) {
          FirestoreService().updateBookStatus(
            current.bookId,
            BookStatus.available,
            currentBranchId: current.destinationBranchId,
          );
        }
      }

      notifyListeners();
    }
  }

  // -------------------------------------------------------------
  // BORROW WORKFLOW
  // -------------------------------------------------------------
  bool borrowBook({
    required String bookId,
    required String memberId,
    required String memberName,
    required String fromBranchId,
  }) {
    final bookIdx = _books.indexWhere((b) => b.id == bookId);
    if (bookIdx == -1) return false;
    final book = _books[bookIdx];
    if (book.status != BookStatus.available) return false;

    final now = DateTime.now();
    final newLoan = Loan(
      id: 'LOAN-BF-${now.millisecondsSinceEpoch.toString().substring(7)}',
      bookId: book.id,
      bookTitle: book.title,
      bookBarcode: book.barcode,
      bookAuthor: book.author,
      memberId: memberId,
      memberName: memberName,
      borrowedFromBranchId: fromBranchId,
      borrowedAt: now,
      dueDate: now.add(const Duration(days: 14)),
      status: LoanStatus.active,
    );

    _loans.insert(0, newLoan);
    _books[bookIdx] = book.copyWith(status: BookStatus.borrowed);

    if (FirestoreService().isConnected) {
      FirestoreService().loansRef?.doc(newLoan.id).set(newLoan);
      FirestoreService().updateBookStatus(book.id, BookStatus.borrowed);
    }

    notifyListeners();
    return true;
  }
}

class ReturnResult {
  final bool success;
  final String message;
  final Loan? loan;
  final bool isCrossBranch;
  final double penaltyAvoided;

  ReturnResult({
    required this.success,
    required this.message,
    this.loan,
    this.isCrossBranch = false,
    this.penaltyAvoided = 0.0,
  });
}
