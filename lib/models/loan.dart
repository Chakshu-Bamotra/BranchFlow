enum LoanStatus {
  active,
  returned,
  overdue,
}

extension LoanStatusExtension on LoanStatus {
  String get label {
    switch (this) {
      case LoanStatus.active:
        return 'Active';
      case LoanStatus.returned:
        return 'Returned';
      case LoanStatus.overdue:
        return 'Overdue';
    }
  }

  String get key {
    switch (this) {
      case LoanStatus.active:
        return 'active';
      case LoanStatus.returned:
        return 'returned';
      case LoanStatus.overdue:
        return 'overdue';
    }
  }

  static LoanStatus fromKey(String? key) {
    switch (key) {
      case 'returned':
        return LoanStatus.returned;
      case 'overdue':
        return LoanStatus.overdue;
      default:
        return LoanStatus.active;
    }
  }
}

class Loan {
  final String id;
  final String bookId;
  final String bookTitle;
  final String bookBarcode;
  final String bookAuthor;
  final String memberId;
  final String memberName;
  final String borrowedFromBranchId;
  final DateTime borrowedAt;
  final DateTime dueDate;
  final DateTime? returnedAt;
  final String? returnedToBranchId;
  final String? returnReceiptCode;
  final String? receivedByStaff;
  final LoanStatus status;
  final double penaltyAvoided;

  const Loan({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.bookBarcode,
    required this.bookAuthor,
    required this.memberId,
    required this.memberName,
    required this.borrowedFromBranchId,
    required this.borrowedAt,
    required this.dueDate,
    this.returnedAt,
    this.returnedToBranchId,
    this.returnReceiptCode,
    this.receivedByStaff,
    required this.status,
    this.penaltyAvoided = 0.0,
  });

  bool get isCrossBranchReturn =>
      returnedToBranchId != null &&
      returnedToBranchId != borrowedFromBranchId;

  bool get isReturned => status == LoanStatus.returned;

  bool get isCurrentlyOverdue {
    if (isReturned) return false;
    return DateTime.now().isAfter(dueDate);
  }

  Loan copyWith({
    String? id,
    String? bookId,
    String? bookTitle,
    String? bookBarcode,
    String? bookAuthor,
    String? memberId,
    String? memberName,
    String? borrowedFromBranchId,
    DateTime? borrowedAt,
    DateTime? dueDate,
    DateTime? returnedAt,
    String? returnedToBranchId,
    String? returnReceiptCode,
    String? receivedByStaff,
    LoanStatus? status,
    double? penaltyAvoided,
  }) {
    return Loan(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      bookBarcode: bookBarcode ?? this.bookBarcode,
      bookAuthor: bookAuthor ?? this.bookAuthor,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      borrowedFromBranchId: borrowedFromBranchId ?? this.borrowedFromBranchId,
      borrowedAt: borrowedAt ?? this.borrowedAt,
      dueDate: dueDate ?? this.dueDate,
      returnedAt: returnedAt ?? this.returnedAt,
      returnedToBranchId: returnedToBranchId ?? this.returnedToBranchId,
      returnReceiptCode: returnReceiptCode ?? this.returnReceiptCode,
      receivedByStaff: receivedByStaff ?? this.receivedByStaff,
      status: status ?? this.status,
      penaltyAvoided: penaltyAvoided ?? this.penaltyAvoided,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'bookBarcode': bookBarcode,
      'bookAuthor': bookAuthor,
      'memberId': memberId,
      'memberName': memberName,
      'borrowedFromBranchId': borrowedFromBranchId,
      'borrowedAt': borrowedAt.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'returnedAt': returnedAt?.toIso8601String(),
      'returnedToBranchId': returnedToBranchId,
      'returnReceiptCode': returnReceiptCode,
      'receivedByStaff': receivedByStaff,
      'status': status.key,
      'penaltyAvoided': penaltyAvoided,
    };
  }

  factory Loan.fromMap(Map<String, dynamic> map, String docId) {
    return Loan(
      id: docId,
      bookId: map['bookId'] ?? '',
      bookTitle: map['bookTitle'] ?? '',
      bookBarcode: map['bookBarcode'] ?? '',
      bookAuthor: map['bookAuthor'] ?? '',
      memberId: map['memberId'] ?? '',
      memberName: map['memberName'] ?? '',
      borrowedFromBranchId: map['borrowedFromBranchId'] ?? '',
      borrowedAt: DateTime.tryParse(map['borrowedAt'] ?? '') ?? DateTime.now(),
      dueDate: DateTime.tryParse(map['dueDate'] ?? '') ??
          DateTime.now().add(const Duration(days: 14)),
      returnedAt: map['returnedAt'] != null
          ? DateTime.tryParse(map['returnedAt'])
          : null,
      returnedToBranchId: map['returnedToBranchId'],
      returnReceiptCode: map['returnReceiptCode'],
      receivedByStaff: map['receivedByStaff'],
      status: LoanStatusExtension.fromKey(map['status']),
      penaltyAvoided: (map['penaltyAvoided'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
