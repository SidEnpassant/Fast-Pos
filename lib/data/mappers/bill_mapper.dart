import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/supabase_mappers.dart';

/// Maps Supabase `bills` rows to [Bill].
abstract final class BillMapper {
  static Bill fromSupabaseRow(Map<String, dynamic> r) {
    final m = SupabaseMappers.billFromRow(r);
    final items = SupabaseMappers.billProductsAsLineItems(m);
    final lineItems = items
        .map(
          (e) => BillLineItem(
            productName: e['productName'] as String? ?? '',
            quantity: e['quantity'] as int? ?? 0,
            totalPrice: (e['totalPrice'] as num?)?.toDouble() ?? 0,
          ),
        )
        .toList();

    return Bill(
      id: m['id'] as String,
      userId: m['userId'] as String?,
      businessName: m['businessName'] as String?,
      customerName: (m['customerName'] as String?) ?? '',
      customerPhone: (m['customerPhone'] as String?) ?? '',
      totalAmount: (m['totalAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (m['paidAmount'] as num?)?.toDouble() ?? 0,
      paymentMethod: (m['paymentMethod'] as String?) ?? 'cash',
      paymentStatus: ((m['paymentStatus'] as String?) ?? '').toLowerCase(),
      createdAt: m['createdAt'] as DateTime,
      lastUpdated: m['lastUpdated'] as DateTime?,
      signedBillUrl: m['signedBillUrl'] as String?,
      lastSignedBillUpdate: m['lastSignedBillUpdate'] as DateTime?,
      pdfUrl: m['pdfUrl'] as String?,
      pdfUpdatedAt: m['pdfUpdatedAt'] as DateTime?,
      displayBillNumber: (m['displayBillNumber'] as String?) ??
          (r['display_bill_number'] as String?),
      customerId: m['customerId'] as String?,
      lineItems: lineItems,
    );
  }
}
