import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'mock_data.dart';

class FirestoreSeeder {
  static Future<SeedResult> seedInitialData() async {
    if (Firebase.apps.isEmpty) {
      return SeedResult(
        success: false,
        message: 'Firebase is not initialized. Please connect your Firebase project first.',
      );
    }

    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      // 1. Seed Branches
      for (final branch in MockData.branches) {
        final docRef = db.collection('branches').doc(branch.id);
        batch.set(docRef, branch.toMap());
      }

      // 2. Seed Books
      for (final book in MockData.books) {
        final docRef = db.collection('books').doc(book.id);
        batch.set(docRef, book.toMap());
      }

      // 3. Seed Initial Loans
      for (final loan in MockData.initialLoans) {
        final docRef = db.collection('loans').doc(loan.id);
        batch.set(docRef, loan.toMap());
      }

      // 4. Seed Initial Transit Items
      for (final transit in MockData.initialTransit) {
        final docRef = db.collection('transit_items').doc(transit.id);
        batch.set(docRef, transit.toMap());
      }

      await batch.commit();

      return SeedResult(
        success: true,
        message: 'Successfully seeded ${MockData.branches.length} branches, '
            '${MockData.books.length} books, and initial loan ledgers into Cloud Firestore!',
      );
    } catch (e) {
      return SeedResult(
        success: false,
        message: 'Failed to seed database: $e',
      );
    }
  }
}

class SeedResult {
  final bool success;
  final String message;

  const SeedResult({required this.success, required this.message});
}
