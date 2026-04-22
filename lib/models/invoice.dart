class Invoice {
  final String? invoiceId;
  final String date;
  final double total;

  const Invoice({this.invoiceId, required this.date, required this.total});

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      invoiceId: map['invoiceId']?.toString(),
      date: map['date'] as String? ?? '',
      total: (map['total'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap({bool includeId = true}) {
    return {
      if (includeId) 'invoiceId': invoiceId,
      'date': date,
      'total': total,
    };
  }
}
