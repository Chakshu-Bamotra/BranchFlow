import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/book.dart';
import '../models/branch.dart';
import '../models/loan.dart';
import '../models/transit_item.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;

  FirestoreService._internal();

  FirebaseFirestore? get _db {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseFirestore.instance;
  }

  bool get isConnected => _db != null;

  // -------------------------------------------------------------
  // WITHCONVERTER TYPED COLLECTION REFERENCES
  // -------------------------------------------------------------
  CollectionReference<Book>? get booksRef => _db?.collection('books').withConverter<Book>(
        fromFirestore: (snapshot, _) => Book.fromMap(snapshot.data()!, snapshot.id),
        toFirestore: (book, _) => book.toMap(),
      );

  CollectionReference<Branch>? get branchesRef => _db?.collection('branches').withConverter<Branch>(
        fromFirestore: (snapshot, _) => Branch.fromMap(snapshot.data()!, snapshot.id),
        toFirestore: (branch, _) => branch.toMap(),
      );

  CollectionReference<Loan>? get loansRef => _db?.collection('loans').withConverter<Loan>(
        fromFirestore: (snapshot, _) => Loan.fromMap(snapshot.data()!, snapshot.id),
        toFirestore: (loan, _) => loan.toMap(),
      );

  CollectionReference<TransitItem>? get transitRef =>
      _db?.collection('transit_items').withConverter<TransitItem>(
            fromFirestore: (snapshot, _) => TransitItem.fromMap(snapshot.data()!, snapshot.id),
            toFirestore: (item, _) => item.toMap(),
          );

  // -------------------------------------------------------------
  // REAL-TIME SNAPSHOTS() STREAMS
  // -------------------------------------------------------------
  Stream<List<Book>> streamBooks({String? branchId, BookStatus? status}) {
    if (_db == null) return const Stream.empty();
    Query<Book> query = booksRef!;

    if (branchId != null && branchId != 'all') {
      query = query.where('currentBranchId', isEqualTo: branchId);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status.key);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  Stream<List<Loan>> streamUserLoans(String memberId, {bool activeOnly = false}) {
    if (_db == null) return const Stream.empty();
    Query<Loan> query = loansRef!.where('memberId', isEqualTo: memberId);

    if (activeOnly) {
      query = query.where('status', isEqualTo: LoanStatus.active.key);
    }
    query = query.orderBy('borrowedAt', descending: true);

    return query.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  Stream<List<TransitItem>> streamTransitItems({TransitStage? stage}) {
    if (_db == null) return const Stream.empty();
    Query<TransitItem> query = transitRef!;

    if (stage != null) {
      query = query.where('stage', isEqualTo: stage.key);
    }
    query = query.orderBy('createdAt', descending: true);

    return query.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  // -------------------------------------------------------------
  // ATOMIC BATCH WRITE: CROSS-BRANCH RETURN DISCHARGE
  // -------------------------------------------------------------
  Future<bool> executeCrossBranchReturnBatch({
    required Loan loan,
    required Book book,
    required String returnBranchId,
    required String staffName,
    required String receiptCode,
  }) async {
    if (_db == null) return false;

    final batch = _db!.batch();
    final now = DateTime.now();
    final isCrossBranch = book.homeBranchId != returnBranchId;

    // 1. Update Loan document -> Returned with Receipt Code & Timestamp
    final updatedLoan = loan.copyWith(
      status: LoanStatus.returned,
      returnedAt: now,
      returnedToBranchId: returnBranchId,
      returnReceiptCode: receiptCode,
      receivedByStaff: staffName,
      penaltyAvoided: 15.00,
    );
    batch.set(loansRef!.doc(loan.id), updatedLoan);

    // 2. Update Book document -> In holding if cross branch, or available if home
    final updatedBook = book.copyWith(
      currentBranchId: returnBranchId,
      status: isCrossBranch ? BookStatus.inHolding : BookStatus.available,
    );
    batch.set(booksRef!.doc(book.id), updatedBook);

    // 3. Create Transit record if cross branch
    if (isCrossBranch) {
      final transitId = 'TRN-${now.millisecondsSinceEpoch.toString().substring(5)}';
      final transitItem = TransitItem(
        id: transitId,
        bookId: book.id,
        bookTitle: book.title,
        bookBarcode: book.barcode,
        originBranchId: returnBranchId,
        destinationBranchId: book.homeBranchId,
        createdAt: now,
        stage: TransitStage.awaitingDispatch,
        courierBatchId: 'BATCH-${returnBranchId.substring(7).toUpperCase()}-${book.homeBranchId.substring(7).toUpperCase()}',
      );
      batch.set(transitRef!.doc(transitId), transitItem);
    }

    await batch.commit();
    return true;
  }

  // -------------------------------------------------------------
  // CRUD OPERATIONS: CREATE, READ, UPDATE, DELETE
  // -------------------------------------------------------------

  /// C - Create: Add new record to collection
  Future<String?> addBook(Book book) async {
    if (_db == null) return null;
    final docRef = await booksRef!.add(book);
    return docRef.id;
  }

  /// R - Read (Single Document): Fetch one record by ID
  Future<Book?> getBookById(String id) async {
    if (_db == null) return null;
    final snapshot = await booksRef!.doc(id).get();
    return snapshot.data();
  }

  /// R - Read (Collection): Fetch all records once with get()
  Future<List<Book>> getAllBooks() async {
    if (_db == null) return [];
    final snapshot = await booksRef!.get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// U - Update: Modify specific fields by Document ID
  Future<bool> updateBookStatus(String id, BookStatus status, {String? currentBranchId}) async {
    if (_db == null) return false;
    final Map<String, dynamic> updates = {'status': status.key};
    if (currentBranchId != null) {
      updates['currentBranchId'] = currentBranchId;
    }
    await _db!.collection('books').doc(id).update(updates);
    return true;
  }

  /// D - Delete: Remove document by ID
  Future<bool> deleteBook(String id) async {
    if (_db == null) return false;
    await _db!.collection('books').doc(id).delete();
    return true;
  }
}
