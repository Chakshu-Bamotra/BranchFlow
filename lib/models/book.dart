enum BookStatus {
  available,
  borrowed,
  inHolding, // Returned to a different branch, waiting in courier staging
  inTransit, // On the courier van heading back to home branch
}

extension BookStatusExtension on BookStatus {
  String get label {
    switch (this) {
      case BookStatus.available:
        return 'Available';
      case BookStatus.borrowed:
        return 'Checked Out';
      case BookStatus.inHolding:
        return 'In Holding (Awaiting Dispatch)';
      case BookStatus.inTransit:
        return 'In Transit';
    }
  }

  String get key {
    switch (this) {
      case BookStatus.available:
        return 'available';
      case BookStatus.borrowed:
        return 'borrowed';
      case BookStatus.inHolding:
        return 'in_holding';
      case BookStatus.inTransit:
        return 'in_transit';
    }
  }

  static BookStatus fromKey(String? key) {
    switch (key) {
      case 'borrowed':
        return BookStatus.borrowed;
      case 'in_holding':
        return BookStatus.inHolding;
      case 'in_transit':
        return BookStatus.inTransit;
      default:
        return BookStatus.available;
    }
  }
}

class Book {
  final String id;
  final String isbn;
  final String barcode;
  final String title;
  final String author;
  final String category;
  final String homeBranchId;
  final String currentBranchId;
  final BookStatus status;
  final String? coverUrl;
  final int publishedYear;

  const Book({
    required this.id,
    required this.isbn,
    required this.barcode,
    required this.title,
    required this.author,
    required this.category,
    required this.homeBranchId,
    required this.currentBranchId,
    required this.status,
    this.coverUrl,
    required this.publishedYear,
  });

  bool get isAtHomeBranch => homeBranchId == currentBranchId;

  Book copyWith({
    String? id,
    String? isbn,
    String? barcode,
    String? title,
    String? author,
    String? category,
    String? homeBranchId,
    String? currentBranchId,
    BookStatus? status,
    String? coverUrl,
    int? publishedYear,
  }) {
    return Book(
      id: id ?? this.id,
      isbn: isbn ?? this.isbn,
      barcode: barcode ?? this.barcode,
      title: title ?? this.title,
      author: author ?? this.author,
      category: category ?? this.category,
      homeBranchId: homeBranchId ?? this.homeBranchId,
      currentBranchId: currentBranchId ?? this.currentBranchId,
      status: status ?? this.status,
      coverUrl: coverUrl ?? this.coverUrl,
      publishedYear: publishedYear ?? this.publishedYear,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isbn': isbn,
      'barcode': barcode,
      'title': title,
      'author': author,
      'category': category,
      'homeBranchId': homeBranchId,
      'currentBranchId': currentBranchId,
      'status': status.key,
      'coverUrl': coverUrl,
      'publishedYear': publishedYear,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map, String docId) {
    return Book(
      id: docId,
      isbn: map['isbn'] ?? '',
      barcode: map['barcode'] ?? '',
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      category: map['category'] ?? 'General',
      homeBranchId: map['homeBranchId'] ?? '',
      currentBranchId: map['currentBranchId'] ?? '',
      status: BookStatusExtension.fromKey(map['status']),
      coverUrl: map['coverUrl'],
      publishedYear: (map['publishedYear'] as num?)?.toInt() ?? 2024,
    );
  }
}
