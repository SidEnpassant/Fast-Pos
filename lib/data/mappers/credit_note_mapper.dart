import '../../domain/entities/credit_note.dart';

class CreditNoteMapper {
  static CreditNote fromSupabaseRow(Map<String, dynamic> row) {
    final lineItemsData = row['line_items'] as List<dynamic>? ?? [];
    final lineItems = lineItemsData.map((e) {
      final line = Map<String, dynamic>.from(e as Map);
      return CreditNoteLine(
        productId: line['product_id'] as String,
        productName: line['product_name'] as String? ?? 'Unknown Product',
        quantity: (line['quantity'] as num).toDouble(),
        unitPrice: (line['unit_price'] as num).toDouble(),
        lineTotal: (line['line_total'] as num? ?? (line['quantity'] as num) * (line['unit_price'] as num)).toDouble(),
        gstAmount: (line['gst_amount'] as num? ?? 0).toDouble(),
      );
    }).toList();

    return CreditNote(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      originalBillId: row['original_bill_id'] as String,
      creditNoteNumber: row['credit_note_number'] as String,
      customerId: row['customer_id'] as String?,
      customerName: row['customer_name'] as String? ?? '',
      returnDate: DateTime.parse(row['return_date'] as String),
      totalRefundAmount: (row['total_refund'] as num).toDouble(),
      refundMethod: row['refund_method'] as String,
      status: row['status'] as String,
      lineItems: lineItems,
      reason: row['reason'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  static Map<String, dynamic> toSupabaseRow(CreditNote note) {
    return {
      'user_id': note.userId,
      'original_bill_id': note.originalBillId,
      'credit_note_number': note.creditNoteNumber,
      'customer_id': note.customerId,
      'return_date': note.returnDate.toIso8601String(),
      'total_refund': note.totalRefundAmount,
      'refund_method': note.refundMethod,
      'status': note.status,
      'reason': note.reason,
      'line_items': note.lineItems
          .map((e) => {
                'product_id': e.productId,
                'product_name': e.productName,
                'quantity': e.quantity,
                'unit_price': e.unitPrice,
                'line_total': e.lineTotal,
                'gst_amount': e.gstAmount,
              })
          .toList(),
    };
  }
}
