import 'package:inventopos/domain/billing/bill_revenue.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/entities/customer.dart';

/// Per-customer rollup for analytics lists.
class CustomerRankEntry {
  const CustomerRankEntry({
    required this.key,
    required this.name,
    this.phone,
    this.customerId,
    required this.revenueThisMonth,
    required this.billsThisMonth,
    required this.lifetimeRevenue,
    required this.lifetimeBills,
    required this.outstandingCredit,
    required this.pendingOnBills,
    required this.isNewThisMonth,
  });

  final String key;
  final String name;
  final String? phone;
  final String? customerId;
  final double revenueThisMonth;
  final int billsThisMonth;
  final double lifetimeRevenue;
  final int lifetimeBills;
  final double outstandingCredit;
  final double pendingOnBills;
  final bool isNewThisMonth;
}

/// Aggregated customer metrics for the Analytics → Customers tab.
class CustomerAnalyticsSnapshot {
  const CustomerAnalyticsSnapshot({
    required this.totalCustomers,
    required this.activeThisMonth,
    required this.newCustomersThisMonth,
    required this.repeatCustomers,
    required this.totalOutstandingCredit,
    required this.pendingFromPartialBills,
    required this.partialBillsThisMonth,
    required this.completeBillsThisMonth,
    required this.topByRevenueThisMonth,
    required this.withOutstandingCredit,
    required this.withPendingBills,
  });

  final int totalCustomers;
  final int activeThisMonth;
  final int newCustomersThisMonth;
  final int repeatCustomers;
  final double totalOutstandingCredit;
  final double pendingFromPartialBills;
  final int partialBillsThisMonth;
  final int completeBillsThisMonth;
  final List<CustomerRankEntry> topByRevenueThisMonth;
  final List<CustomerRankEntry> withOutstandingCredit;
  final List<CustomerRankEntry> withPendingBills;

  static const empty = CustomerAnalyticsSnapshot(
    totalCustomers: 0,
    activeThisMonth: 0,
    newCustomersThisMonth: 0,
    repeatCustomers: 0,
    totalOutstandingCredit: 0,
    pendingFromPartialBills: 0,
    partialBillsThisMonth: 0,
    completeBillsThisMonth: 0,
    topByRevenueThisMonth: [],
    withOutstandingCredit: [],
    withPendingBills: [],
  );
}

abstract final class CustomerAnalytics {
  static String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) return digits.substring(digits.length - 10);
    return digits;
  }

  static String customerKey({
    String? customerId,
    String? phone,
    String? name,
  }) {
    if (customerId != null && customerId.isNotEmpty) {
      return 'id:$customerId';
    }
    final normalized = _normalizePhone(phone ?? '');
    if (normalized.isNotEmpty) return 'phone:$normalized';
    final trimmed = (name ?? '').trim().toLowerCase();
    if (trimmed.isNotEmpty) return 'name:$trimmed';
    return '';
  }

  static CustomerAnalyticsSnapshot compute({
    required List<Bill> bills,
    required List<Customer> customers,
    DateTime? reference,
  }) {
    final now = reference ?? DateTime.now();
    if (bills.isEmpty && customers.isEmpty) return CustomerAnalyticsSnapshot.empty;

    final byKey = <String, _MutableCustomerStats>{};

    void ensure(
      String key, {
      String? name,
      String? phone,
      String? customerId,
    }) {
      if (key.isEmpty) return;
      byKey.putIfAbsent(
        key,
        () => _MutableCustomerStats(
          key: key,
          name: name ?? 'Customer',
          phone: phone,
          customerId: customerId,
        ),
      );
      final s = byKey[key]!;
      if (name != null && name.trim().isNotEmpty) s.name = name.trim();
      if (phone != null && phone.trim().isNotEmpty) s.phone = phone.trim();
      if (customerId != null && customerId.isNotEmpty) {
        s.customerId = customerId;
      }
    }

    for (final c in customers) {
      final key = customerKey(
        customerId: c.id,
        phone: c.phone,
        name: c.name,
      );
      ensure(key, name: c.name, phone: c.phone, customerId: c.id);
      byKey[key]?.outstandingCredit = c.creditBalance;
    }

    for (final bill in bills) {
      final key = customerKey(
        customerId: bill.customerId,
        phone: bill.customerPhone,
        name: bill.customerName,
      );
      if (key.isEmpty) continue;
      ensure(
        key,
        name: bill.customerName,
        phone: bill.customerPhone,
        customerId: bill.customerId,
      );
      final s = byKey[key]!;
      final revenue = BillRevenue.recognizedAmount(bill);
      s.lifetimeRevenue += revenue;
      s.lifetimeBills += 1;
      final billMonth = bill.createdAt.toLocal();
      if (BillRevenue.isSameCalendarMonth(bill, now)) {
        s.revenueThisMonth += revenue;
        s.billsThisMonth += 1;
        s.monthBillDates.add(billMonth);
      } else if (billMonth.isBefore(DateTime(now.year, now.month, 1))) {
        s.hadBillBeforeThisMonth = true;
      }
      if (bill.paymentStatus == 'partial') {
        final pending = bill.totalAmount - bill.paidAmount;
        if (pending > 0) s.pendingOnBills += pending;
      }
    }

    final entries = byKey.values.map((s) => s.toEntry(now)).toList();
    final activeThisMonth = entries.where((e) => e.billsThisMonth > 0).length;
    final newThisMonth = entries.where((e) => e.isNewThisMonth).length;
    final repeat = entries
        .where((e) => e.billsThisMonth > 0 && e.lifetimeBills > 1)
        .length;

    final top = [...entries]
      ..sort((a, b) => b.revenueThisMonth.compareTo(a.revenueThisMonth));
    final creditList = entries.where((e) => e.outstandingCredit > 0).toList()
      ..sort((a, b) => b.outstandingCredit.compareTo(a.outstandingCredit));
    final pendingList = entries.where((e) => e.pendingOnBills > 0).toList()
      ..sort((a, b) => b.pendingOnBills.compareTo(a.pendingOnBills));

    final partialMonth = bills
        .where(
          (b) =>
              b.paymentStatus == 'partial' &&
              BillRevenue.isSameCalendarMonth(b, now),
        )
        .length;
    final completeMonth = bills
        .where(
          (b) =>
              b.paymentStatus == 'complete' &&
              BillRevenue.isSameCalendarMonth(b, now),
        )
        .length;
    final pendingPartial = bills
        .where((b) => b.paymentStatus == 'partial')
        .fold(0.0, (sum, b) => sum + (b.totalAmount - b.paidAmount).clamp(0, 1e12));

    return CustomerAnalyticsSnapshot(
      totalCustomers: byKey.length,
      activeThisMonth: activeThisMonth,
      newCustomersThisMonth: newThisMonth,
      repeatCustomers: repeat,
      totalOutstandingCredit: customers.fold(
        0.0,
        (s, c) => s + c.creditBalance,
      ),
      pendingFromPartialBills: pendingPartial,
      partialBillsThisMonth: partialMonth,
      completeBillsThisMonth: completeMonth,
      topByRevenueThisMonth: top.take(10).toList(),
      withOutstandingCredit: creditList.take(8).toList(),
      withPendingBills: pendingList.take(8).toList(),
    );
  }
}

class _MutableCustomerStats {
  _MutableCustomerStats({
    required this.key,
    required this.name,
    this.phone,
    this.customerId,
  });

  final String key;
  String name;
  String? phone;
  String? customerId;
  double revenueThisMonth = 0;
  int billsThisMonth = 0;
  double lifetimeRevenue = 0;
  int lifetimeBills = 0;
  double outstandingCredit = 0;
  double pendingOnBills = 0;
  bool hadBillBeforeThisMonth = false;
  final Set<DateTime> monthBillDates = {};

  CustomerRankEntry toEntry(DateTime now) {
    final isNew = billsThisMonth > 0 && !hadBillBeforeThisMonth;
    return CustomerRankEntry(
      key: key,
      name: name,
      phone: phone,
      customerId: customerId,
      revenueThisMonth: revenueThisMonth,
      billsThisMonth: billsThisMonth,
      lifetimeRevenue: lifetimeRevenue,
      lifetimeBills: lifetimeBills,
      outstandingCredit: outstandingCredit,
      pendingOnBills: pendingOnBills,
      isNewThisMonth: isNew,
    );
  }
}
