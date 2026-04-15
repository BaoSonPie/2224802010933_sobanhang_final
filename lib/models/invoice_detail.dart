class InvoiceDetail {
  final int? detailId;
  final int invoiceId;
  final int productId;
  final String productName;
  final int quantity;
  final double price;

  const InvoiceDetail({
    this.detailId,
    required this.invoiceId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  double get lineTotal => price * quantity;

  factory InvoiceDetail.fromMap(Map<String, dynamic> map) {
    return InvoiceDetail(
      detailId: map['detailId'] as int?,
      invoiceId: map['invoiceId'] as int? ?? 0,
      productId: map['productId'] as int? ?? 0,
      productName: map['productName'] as String? ?? '',
      quantity: map['quantity'] as int? ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap({bool includeId = true}) {
    return {
      if (includeId) 'detailId': detailId,
      'invoiceId': invoiceId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
    };
  }
}
