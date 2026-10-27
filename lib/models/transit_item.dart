enum TransitStage {
  awaitingDispatch,
  inTransit,
  restocked,
}

extension TransitStageExtension on TransitStage {
  String get label {
    switch (this) {
      case TransitStage.awaitingDispatch:
        return 'Holding at Drop-off';
      case TransitStage.inTransit:
        return 'In Transit (Courier)';
      case TransitStage.restocked:
        return 'Restocked at Home';
    }
  }

  String get key {
    switch (this) {
      case TransitStage.awaitingDispatch:
        return 'awaiting_dispatch';
      case TransitStage.inTransit:
        return 'in_transit';
      case TransitStage.restocked:
        return 'restocked';
    }
  }

  static TransitStage fromKey(String? key) {
    switch (key) {
      case 'in_transit':
        return TransitStage.inTransit;
      case 'restocked':
        return TransitStage.restocked;
      default:
        return TransitStage.awaitingDispatch;
    }
  }
}

class TransitItem {
  final String id;
  final String bookId;
  final String bookTitle;
  final String bookBarcode;
  final String originBranchId; // Drop-off branch
  final String destinationBranchId; // Home branch
  final DateTime createdAt;
  final DateTime? dispatchedAt;
  final DateTime? restockedAt;
  final TransitStage stage;
  final String courierBatchId;

  const TransitItem({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.bookBarcode,
    required this.originBranchId,
    required this.destinationBranchId,
    required this.createdAt,
    this.dispatchedAt,
    this.restockedAt,
    required this.stage,
    required this.courierBatchId,
  });

  String get fromBranchId => originBranchId;
  String get toBranchId => destinationBranchId;
  String get trackingNumber => courierBatchId;
  String get barcode => bookBarcode;

  TransitItem copyWith({
    String? id,
    String? bookId,
    String? bookTitle,
    String? bookBarcode,
    String? originBranchId,
    String? destinationBranchId,
    DateTime? createdAt,
    DateTime? dispatchedAt,
    DateTime? restockedAt,
    TransitStage? stage,
    String? courierBatchId,
  }) {
    return TransitItem(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      bookBarcode: bookBarcode ?? this.bookBarcode,
      originBranchId: originBranchId ?? this.originBranchId,
      destinationBranchId: destinationBranchId ?? this.destinationBranchId,
      createdAt: createdAt ?? this.createdAt,
      dispatchedAt: dispatchedAt ?? this.dispatchedAt,
      restockedAt: restockedAt ?? this.restockedAt,
      stage: stage ?? this.stage,
      courierBatchId: courierBatchId ?? this.courierBatchId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'bookBarcode': bookBarcode,
      'originBranchId': originBranchId,
      'destinationBranchId': destinationBranchId,
      'createdAt': createdAt.toIso8601String(),
      'dispatchedAt': dispatchedAt?.toIso8601String(),
      'restockedAt': restockedAt?.toIso8601String(),
      'stage': stage.key,
      'courierBatchId': courierBatchId,
    };
  }

  factory TransitItem.fromMap(Map<String, dynamic> map, String docId) {
    return TransitItem(
      id: docId,
      bookId: map['bookId'] ?? '',
      bookTitle: map['bookTitle'] ?? '',
      bookBarcode: map['bookBarcode'] ?? '',
      originBranchId: map['originBranchId'] ?? '',
      destinationBranchId: map['destinationBranchId'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      dispatchedAt: map['dispatchedAt'] != null
          ? DateTime.tryParse(map['dispatchedAt'])
          : null,
      restockedAt: map['restockedAt'] != null
          ? DateTime.tryParse(map['restockedAt'])
          : null,
      stage: TransitStageExtension.fromKey(map['stage']),
      courierBatchId: map['courierBatchId'] ?? '',
    );
  }
}
